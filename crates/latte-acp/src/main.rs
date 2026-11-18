//! latte-acp: LatteOS's client of the Agent Client Protocol (ROADMAP 10B.71). One task of LensAI's Helper: it starts the
//! agent (Gemini `--acp`, Claude Code through `claude-agent-acp`, Codex through `codex-acp`), in the sandbox `latte-ai do`
//! puts around its command, gives it LatteOS's tools (`latte-mcp`), sends the task, and writes what happens as JSON lines
//! on stdout — the Helper's conversation reads them. What the agent asks to be allowed goes to the person in LensAI
//! (`latte-skill allow agent … --once`, the card "Waits for you"); nothing is allowed here by itself. At the end what it
//! changed goes to the journal (`latte-ai journal add`). Written after the SDK's `yolo_one_shot_client` example
//! (Apache-2.0), which allows everything; this one asks.
//!
//!   latte-acp DIR NAME TASK -- COMMAND ARGS…
//!
//! Lines: {"t":"start"} · {"t":"update","u":SessionUpdate} · {"t":"ask","title","answer"} · {"t":"turn","stop"} (an answer
//! done: the person may go on) · {"t":"you","text"} (they did) · {"t":"end","stop"|"error"}

use agent_client_protocol::schema::ProtocolVersion;
use agent_client_protocol::v1::ConnectionTo;
use agent_client_protocol::v1::schema::{
    AuthenticateRequest, ContentBlock, InitializeRequest, McpServer, McpServerStdio, NewSessionRequest, PermissionOptionKind, PromptRequest,
    RequestPermissionOutcome, RequestPermissionRequest, RequestPermissionResponse, SelectedPermissionOutcome,
    SessionNotification, SetSessionModeRequest, TextContent,
};
use agent_client_protocol::{AcpAgent, Agent};
use serde_json::{json, Value};
use std::io::Write;
use std::process::Command;
use std::sync::{Arc, Mutex};

fn say(v: Value) {
    let mut out = std::io::stdout().lock();
    let _ = writeln!(out, "{v}");
    let _ = out.flush();
}

/// What a task left behind: the agent's words, and the files its tools touched (edit, move, delete).
#[derive(Default)]
struct Kept {
    text: String,
    files: Vec<String>,
}

fn keep(kept: &Mutex<Kept>, u: &Value) {
    let mut k = kept.lock().unwrap();
    match u.get("sessionUpdate").and_then(Value::as_str) {
        Some("agent_message_chunk") => {
            if let Some(t) = u.pointer("/content/text").and_then(Value::as_str) {
                k.text.push_str(t);
            }
        }
        Some("tool_call") | Some("tool_call_update") => {
            let kind = u.get("kind").and_then(Value::as_str).unwrap_or("");
            if matches!(kind, "edit" | "delete" | "move") {
                for l in u.get("locations").and_then(Value::as_array).into_iter().flatten() {
                    if let Some(p) = l.get("path").and_then(Value::as_str) {
                        if !k.files.iter().any(|f| f == p) {
                            k.files.push(p.to_string());
                        }
                    }
                }
            }
        }
        _ => {}
    }
}

/// What the person writes next to this task: the lines added to LATTE_ACP_IN since the last read; None after half an
/// hour of nothing, or when the line is the end (`latte-ai helper end`).
async fn next_words() -> Option<String> {
    let path = std::env::var("LATTE_ACP_IN").ok()?;
    static READ: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
    for _ in 0..3600 {
        if let Ok(all) = std::fs::read_to_string(&path) {
            let from = READ.load(std::sync::atomic::Ordering::Relaxed);
            if all.len() > from && all.ends_with('\n') {
                READ.store(all.len(), std::sync::atomic::Ordering::Relaxed);
                let w = all[from..].trim().to_string();
                return if w == "\u{4}" || w.is_empty() { None } else { Some(w) };
            }
        }
        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
    }
    None
}

/// The person's word in LensAI, in a thread of its own: it waits up to two minutes.
fn ask_person(title: &str, name: &str) -> bool {
    Command::new("latte-skill")
        .args(["allow", "agent", title, "--by", name, "--once"])
        .output()
        .ok()
        .and_then(|o| serde_json::from_slice::<Value>(&o.stdout).ok())
        .and_then(|v| v.get("ok").and_then(Value::as_bool))
        .unwrap_or(false)
}

#[tokio::main]
async fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    let cut = a.iter().position(|w| w == "--");
    let (dir, name, task, cmd) = match cut {
        Some(3) if a.len() > 4 => (a[0].clone(), a[1].clone(), a[2].clone(), a[4..].to_vec()),
        _ => {
            eprintln!("latte-acp DIR NAME TASK -- COMMAND ARGS…");
            std::process::exit(2);
        }
    };
    let kept = Arc::new(Mutex::new(Kept::default()));
    let agent = match AcpAgent::from_args(cmd.iter().map(String::as_str)) {
        Ok(a) => a,
        Err(e) => {
            say(json!({"t": "end", "error": e.to_string()}));
            std::process::exit(1);
        }
    };
    say(json!({"t": "start", "agent": name, "dir": dir, "task": task}));
    let (k1, who, d2, t2) = (kept.clone(), name.clone(), dir.clone(), task.clone());
    let done = agent_client_protocol::Client
        .v1()
        .on_receive_notification(
            async move |n: SessionNotification, _cx| {
                let u = serde_json::to_value(&n.update).unwrap_or(Value::Null);
                keep(&k1, &u);
                // what the conversation shows; the agent's command list and token counts would only fill the log
                if !matches!(u.get("sessionUpdate").and_then(Value::as_str), Some("available_commands_update" | "usage_update")) {
                    say(json!({"t": "update", "u": u}));
                }
                Ok(())
            },
            agent_client_protocol::on_receive_notification!(),
        )
        .on_receive_request(
            async move |r: RequestPermissionRequest, responder, _c| {
                let title = r.tool_call.fields.title.clone().unwrap_or_else(|| "a step of its work".into());
                let (t, n) = (title.clone(), who.clone());
                let yes = tokio::task::spawn_blocking(move || ask_person(&t, &n)).await.unwrap_or(false);
                say(json!({"t": "ask", "title": title, "answer": if yes { "yes" } else { "no" }}));
                // once, never "always": the next step is asked again
                let want = if yes { PermissionOptionKind::AllowOnce } else { PermissionOptionKind::RejectOnce };
                let pick = r.options.iter().find(|o| o.kind == want).map(|o| o.option_id.clone());
                responder.respond(RequestPermissionResponse::new(match pick {
                    Some(id) => RequestPermissionOutcome::Selected(SelectedPermissionOutcome::new(id)),
                    None => RequestPermissionOutcome::Cancelled,
                }))
            },
            agent_client_protocol::on_receive_request!(),
        )
        .connect_with(agent, |c: ConnectionTo<Agent>| async move {
            c.send_request(InitializeRequest::new(ProtocolVersion::V1)).block_task().await?;
            // the sign-in the agent's own tool already has (Gemini: the kind its settings name, LATTE_ACP_AUTH from
            // latte-ai); none given, the agent uses what it has, and asks for nothing that opens a browser here
            if let Ok(m) = std::env::var("LATTE_ACP_AUTH") {
                if !m.is_empty() {
                    c.send_request(AuthenticateRequest::new(m)).block_task().await?;
                }
            }
            let tools = McpServer::Stdio(McpServerStdio::new("latteos", "latte-mcp"));
            let s = c
                .send_request(NewSessionRequest::new(std::path::PathBuf::from(&d2)).mcp_servers(vec![tools]))
                .block_task()
                .await?;
            // the mode that asks before every change ("default": Claude Code's adapter starts in "auto", where its own
            // classifier allows edits without the person) — LatteOS's rule: nothing changed before their yes
            if let Some(m) = &s.modes {
                if m.current_mode_id.to_string() != "default" && m.available_modes.iter().any(|x| x.id.to_string() == "default") {
                    c.send_request(SetSessionModeRequest::new(s.session_id.clone(), "default")).block_task().await?;
                    say(json!({"t": "mode", "mode": "default"}));
                }
            }
            // one conversation: after each answer the person may go on (their words come through LATTE_ACP_IN,
            // `latte-ai helper say`); half an hour without a word ends it
            let mut words = t2;
            loop {
                let r = c
                    .send_request(PromptRequest::new(s.session_id.clone(), vec![ContentBlock::Text(TextContent::new(words))]))
                    .block_task()
                    .await?;
                say(json!({"t": "turn", "stop": serde_json::to_value(r.stop_reason).unwrap_or(Value::Null)}));
                match next_words().await {
                    Some(w) => {
                        say(json!({"t": "you", "text": w}));
                        words = w;
                    }
                    None => break,
                }
            }
            say(json!({"t": "end", "stop": "done"}));
            Ok(())
        })
        .await;
    if let Err(e) = &done {
        say(json!({"t": "end", "error": e.to_string()}));
    }
    // what it changed, into the journal of the AI (the Helper's "What changed")
    let k = kept.lock().unwrap();
    let said: String = k.text.trim().chars().take(160).collect();
    let entry = json!({"app": std::env::var("LATTE_APP_NAME").unwrap_or_else(|_| "LensAI".into()), "ai": name, "task": task, "where": dir,
                       "log": std::env::var("LATTE_ACP_LOG").unwrap_or_default(),
                       "did": if said.is_empty() { "—".to_string() } else { said },
                       "items": k.files.iter().map(|f| json!([f])).collect::<Vec<_>>()});
    let _ = Command::new("latte-ai").args(["journal", "add", &entry.to_string()]).output();
    std::process::exit(if done.is_ok() { 0 } else { 1 });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_words_and_touched_files() {
        let k = Mutex::new(Kept::default());
        keep(&k, &json!({"sessionUpdate": "agent_message_chunk", "content": {"type": "text", "text": "Hotovo"}}));
        keep(&k, &json!({"sessionUpdate": "tool_call", "kind": "edit", "locations": [{"path": "/a"}, {"path": "/a"}]}));
        keep(&k, &json!({"sessionUpdate": "tool_call", "kind": "read", "locations": [{"path": "/b"}]}));
        let k = k.lock().unwrap();
        assert_eq!(k.text, "Hotovo");
        assert_eq!(k.files, vec!["/a"]);
    }
}
