#!/usr/bin/env python3
"""latte-ai import / import-memory on tiny fake exports (tests/fixtures/import): ChatGPT's tree read as it was shown,
Claude's conversations and memories, Gemini's Takeout activity, the same export twice, and agentgram's anonymous
projects kept out. Everything in a temporary home: the real index and memory are never touched.   python3 tests/test_import.py"""
import importlib.machinery
import importlib.util
import json
import os
import shutil
import sys
import tempfile
import zipfile

sys.dont_write_bytecode = True          # bin/ holds commands, not a place for __pycache__

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIX = os.path.join(ROOT, "tests", "fixtures", "import")

with tempfile.TemporaryDirectory() as home:
    for v in ("XDG_STATE_HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME"):
        os.environ[v] = os.path.join(home, v.lower())
    os.environ["HOME"] = home                                  # agentgram's projects (~/LensAI/agentgram) and ~/.claude here too
    os.environ.pop("CLAUDE_CONFIG_DIR", None)                  # the index reads Claude Code's sessions from there
    loader = importlib.machinery.SourceFileLoader("latte_ai", os.path.join(ROOT, "bin", "latte-ai"))
    ai = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
    loader.exec_module(ai)
    assert ai.ROOM.startswith(home) and ai.PROJECTS_DIR.startswith(home) and ai.ai_folder().startswith(home)
    ai.embedder = lambda: None                                 # no meanings: a search would start the local model behind
    os.chdir(home)

    def zipped(name):
        path = os.path.join(home, name + ".zip")
        with zipfile.ZipFile(path, "w") as z:
            for d, _, files in os.walk(os.path.join(FIX, name)):
                for f in files:
                    z.write(os.path.join(d, f), os.path.relpath(os.path.join(d, f), os.path.join(FIX, name)))
        return path

    # ChatGPT: the branch shown last, from its root; not the system's, the tool's, the thoughts, nor the answer asked again
    r = ai.import_export(os.path.join(FIX, "chatgpt", "conversations.json"), dry=True)
    assert r["kind"] == "chatgpt" and r["new"] == 2 and not os.path.exists(ai.CHATS), r          # dry: nothing written
    r = ai.import_export(zipped("chatgpt"))
    assert (r["new"], r["updated"], r["same"]) == (2, 0, 0), r
    chats = {c["title"]: c for c in ai.chats()}
    latte = ai.load(chats["Latte basics"]["id"])
    assert [m["content"] for m in latte["messages"]] == ["What is a latte?", "A latte is espresso with steamed milk.",
                                                          "And a cortado?", "Espresso cut with a little warm milk."], latte["messages"]
    assert latte["provider"] == "chatgpt" and latte["imported"] == "chatgpt" and latte["from"] == "import" and latte["model"] == "gpt-4o"
    assert latte["messages"][0]["at"] == ai.import_at(1714557600.0) and latte["updated"] == ai.import_at(1714561200.5)
    # no current_node: the branch that ends last
    assert [m["content"] for m in ai.load(chats["No current node"]["id"])["messages"]] == ["Pick a bean", "Arabica"]
    # the same export again: nothing twice
    r = ai.import_export(zipped("chatgpt"))
    assert (r["new"], r["updated"], r["same"]) == (0, 0, 2) and len(ai.chats()) == 2, r
    # searchable at once, and read only
    assert any(h["ref"] == latte["id"] for h in ai.search("cortado")), ai.search("cortado")
    s = ai.send(latte["id"], "nobody", "", "go on")
    assert not s["ok"] and len(ai.load(latte["id"])["messages"]) == 4, s

    # Claude: text blocks without the tool's, an empty conversation left; memories, the project's under its name
    r = ai.import_export(zipped("claude"))
    assert r["kind"] == "claude" and r["new"] == 1 and r["notes"] == 3, r
    grind = next(c for c in ai.chats() if c["provider"] == "claude")
    msgs = ai.load(grind["id"])["messages"]
    assert [m["role"] for m in msgs] == ["user", "assistant", "user"] and msgs[1]["content"] == "Fine, like table salt.\nAdjust by taste.", msgs
    note = open(r["note"], encoding="utf-8").read()
    assert r["note"].endswith("imported/claude-memory.md") and "source: claude" in note, r["note"]
    for line in ("- [work-context] The user builds a Linux desktop called LatteOS.", "- [personal-context] The user likes strong espresso.",
                 "- [project-coffee-notes] The project keeps its notes in Markdown."):
        assert line in note, (line, note)
    r = ai.import_export(zipped("claude"))
    assert r["same"] == 1 and r["notes"] == 0 and open(r["note"], encoding="utf-8").read() == note, r      # additive: never a line twice

    # Gemini: a day's questions one conversation, the answers' HTML as text, an entry without an answer left
    r = ai.import_export(zipped("gemini"))
    assert r["kind"] == "gemini" and r["new"] == 2, r
    days = sorted((c for c in ai.chats() if c["provider"] == "gemini"), key=lambda c: c["updated"])
    first = ai.load(days[0]["id"])
    assert first["title"] == "Which milk foams best?" and len(first["messages"]) == 4, first
    assert first["messages"][1]["content"] == "Whole milk foams best.\nOat milk & barista blends too." and first["messages"][3]["content"].startswith("About 60°C.\nNot boiling")

    # a pasted memory: only its code block, a fact a line under its heading, the date kept; again adds nothing
    text = open(os.path.join(FIX, "memory.txt"), encoding="utf-8").read()
    r = ai.import_memory(text, "chatgpt")
    lines = open(r["note"], encoding="utf-8").read()
    assert r["notes"] == 4 and "- [projects] LatteOS: a Linux desktop, in progress. (2024-05-03)" in lines and "complete set" not in lines, (r, lines)
    assert "- [identity] Name: Ark." in lines and "- [projects] Coffee Notes: a notebook of brews. (2024-06-01)" in lines, lines
    assert ai.import_memory(text, "chatgpt")["notes"] == 0
    # the memory switched off: nothing written, and said so
    os.makedirs(os.path.dirname(ai.MEMORY_WORD), exist_ok=True)
    open(ai.MEMORY_WORD, "w").write("off\n")
    assert ai.import_memory("## Career\nBarista.", "gemini")["error"] == "memory-off" and not os.path.exists(os.path.join(ai.ai_folder(), "imported", "gemini-memory.md"))
    os.remove(ai.MEMORY_WORD)

    # agentgram's anonymous project: nothing of it imported, nothing imported for it
    anon = os.path.join(ai.PROJECTS_DIR, "secret", "sub")
    os.makedirs(anon)
    open(os.path.join(ai.PROJECTS_DIR, "secret", ".agentgram-anonymous"), "w").close()
    inside = shutil.copy(os.path.join(FIX, "claude", "conversations.json"), anon)
    before = sorted(os.listdir(ai.CHATS))
    assert ai.import_export(inside)["error"] == "anonymous"
    os.chdir(anon)
    assert ai.import_export(zipped("claude"))["error"] == "anonymous"
    os.chdir(home)
    assert sorted(os.listdir(ai.CHATS)) == before
    # nor the command from there
    import subprocess
    out = subprocess.run([os.path.join(ROOT, "bin", "latte-ai"), "import-memory", "## Career\nBarista.", "--from", "claude"], cwd=anon,
                         capture_output=True, text=True, env=dict(os.environ))
    assert out.returncode == 1 and json.loads(out.stdout)["error"] == "anonymous", out
    # what is not an export
    junk = os.path.join(home, "junk.json")
    open(junk, "w").write('{"hello": 1}')
    assert ai.import_export(junk)["error"] == "unknown"
print("test_import: ok")
