// LatteOS (the user, 19. 11.: as Claude Projects): a project's page. A project is a category, a subproject its
// subcategory, and its chats are their channels. On the left: a new chat (it starts a channel here with the chosen
// agent answering) and the chats, newest first, with the subprojects of a project; on the right: its Instructions (what
// every agent in its chats keeps to), its Context (the files they read; a subproject's agents also read its project's)
// and what is Scheduled in its chats. The agents get all of it with every turn (engine context.ts `projectBrief`).
import {
  type Channel,
  type ChannelCategory,
  keys,
  type ProjectState,
  type ProjectType,
  useApi,
  useArtifacts,
  useChannelCategories,
  useChannels,
  useRoutines,
  useUpdateProject,
} from "@agenteschat/client";
import { KIND_ICON } from "@agenteschat/client/lib/artifacts";
import { errorText } from "@agenteschat/client/lib/errors";
import { fileIcon } from "@agenteschat/client/lib/files";
import { relativeTime } from "@agenteschat/client/lib/format";
import { can } from "@agenteschat/client/lib/permissions";
import { Button, EmptyState, Icon, type IconName, Select, Textarea } from "@agenteschat/ui";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { UploadButton, useDriveUpload } from "@/components/artifacts/Upload";
import { NewCategoryDialog } from "@/components/ChannelCategoryDialogs";
import { toChannelName } from "@/components/NewChannelDialog";
import { useOrg } from "@/components/org-context";
import { isProject, PROJECT_ICONS, PROJECT_STATES, PROJECT_TYPES } from "@/components/project/kinds";
import { useDirectory } from "@/hooks/useDirectory";
import { useToast } from "@/lib/toast";
import "@/components/project/project.css";

const lastAt = (c: Channel) => c.lastMessage?.createdAt ?? c.createdAt;

/**
 * The project's folder on this computer (~/Projects/project[/subproject]): LensAI opens it in Files (WebTabs.qml,
 * `latte-ai agentgram folder`); a plain browser has nothing to open it with.
 */
const folderLink = (names: string[]) =>
  `latteos://agentgram/folder?${names.map((n, i) => `${i ? "s" : "p"}=${encodeURIComponent(n)}`).join("&")}`;

/** A chat's channel name from its first words, made free of the names already taken ("kapitola-3", "kapitola-3-2"). */
function chatName(text: string, taken: Set<string>) {
  const base =
    toChannelName(text.split(/\s+/).slice(0, 6).join(" "))
      .replace(/^[-_]+/, "")
      .slice(0, 60) || "chat";
  let name = base;
  for (let n = 2; taken.has(name); n++) name = `${base}-${n}`;
  return name;
}

export function ProjectPage({ categoryId }: { categoryId: string }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const categories = useChannelCategories(org.id);
  const project = categories.data?.find((c) => c.id === categoryId);
  if (categories.isLoading) return null;
  if (!project || !isProject(project))
    return (
      <div className="project-page project-page--missing">
        <EmptyState size="page">{t("projectPage.missing")}</EmptyState>
      </div>
    );
  const parent = project.parentId ? categories.data?.find((c) => c.id === project.parentId) : undefined;
  const subs = (categories.data ?? []).filter((c) => c.parentId === project.id);
  return (
    <div className="project-page">
      <header className="project-page__head">
        {parent && (
          <Link
            to="/org/$orgId/projects/$categoryId"
            params={{ orgId: org.id, categoryId: parent.id }}
            className="project-page__up"
          >
            <Icon name="chevronLeft" size={14} /> {parent.name}
          </Link>
        )}
        <h1 className="project-page__title">
          <Icon name={PROJECT_ICONS[(parent ?? project).projectType ?? "other"]} />
          {project.name}
        </h1>
        <ProjectSettings project={project} />
        <a
          className="ac-btn ac-btn--sm project-page__folder"
          href={folderLink(parent ? [parent.name, project.name] : [project.name])}
          target="_blank"
          rel="noopener"
          title={t("projectPage.folderHint")}
        >
          <Icon name="drive" size={16} /> {t("projectPage.folder")}
        </a>
      </header>
      <div className="project-page__cols">
        <div className="project-page__main">
          <NewChat project={project} />
          {!parent && <Subprojects project={project} subs={subs} />}
          <Chats project={project} />
        </div>
        <aside className="project-page__side" aria-label={t("projectPage.about")}>
          <Instructions project={project} parent={parent} />
          <Context project={project} parent={parent} />
          <Memory project={project} parent={parent} />
          <Scheduled project={project} />
        </aside>
      </div>
    </div>
  );
}

/** Kind (a project) and state, for who manages channels. */
function ProjectSettings({ project }: { project: ChannelCategory }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const update = useUpdateProject(org.id, project.id);
  if (!can(org, "manage_channels")) return null;
  const change = (input: { projectType?: ProjectType; projectState?: ProjectState }) =>
    update.mutate(input, { onError: (e) => toast.show(errorText(t, e), "error") });
  return (
    <div className="project-page__settings">
      {!project.parentId && (
        <Select
          aria-label={t("projectPage.kind")}
          value={project.projectType ?? "other"}
          onValueChange={(v) => change({ projectType: v as ProjectType })}
          options={PROJECT_TYPES.map((k) => ({
            value: k,
            label: t(`projectPage.types.${k}`),
            leading: <Icon name={PROJECT_ICONS[k]} size={16} />,
          }))}
        />
      )}
      <Select
        aria-label={t("projectPage.state")}
        value={project.projectState ?? "active"}
        onValueChange={(v) => change({ projectState: v as ProjectState })}
        options={PROJECT_STATES.map((k) => ({ value: k, label: t(`projectPage.states.${k}`) }))}
      />
    </div>
  );
}

/** A new chat: a channel in the project, named from its first words, with the chosen agent answering every message. */
function NewChat({ project }: { project: ChannelCategory }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const api = useApi();
  const qc = useQueryClient();
  const navigate = useNavigate();
  const toast = useToast();
  const channels = useChannels(org.id).data ?? [];
  const agents = useDirectory(org.id).agents;
  const [text, setText] = useState("");
  const [agentId, setAgentId] = useState("");
  // ponytail: the first agent; remembering the project's last one can come when people ask for it
  useEffect(() => {
    if (agentId || agents.length === 0) return;
    setAgentId(agents[0]?.id ?? "");
  }, [agents, agentId]);
  const start = useMutation({
    mutationFn: async (body: string) => {
      const name = chatName(body, new Set(channels.map((c) => c.name)));
      const channel = await api.chat.createChannel(org.id, {
        name,
        topic: body.replace(/\s+/g, " ").slice(0, 200),
        categoryId: project.id,
      });
      if (agentId) {
        await api.chat.addMember(org.id, channel.id, { agentId });
        await api.chat.setAutoReply(org.id, channel.id, agentId, true);
      }
      await api.chat.post(org.id, channel.id, { body, clientId: crypto.randomUUID() });
      return channel;
    },
    onSuccess: async (channel) => {
      await qc.invalidateQueries({ queryKey: keys.channels(org.id) });
      setText("");
      await navigate({ to: "/org/$orgId/c/$channelId", params: { orgId: org.id, channelId: channel.id } });
    },
    onError: (e) => toast.show(errorText(t, e), "error"),
  });
  const send = () => {
    if (text.trim() && !start.isPending) start.mutate(text.trim());
  };
  if (!can(org, "create_channels")) return null;
  return (
    <form
      className="project-page__new"
      onSubmit={(e) => {
        e.preventDefault();
        send();
      }}
    >
      <Textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            send();
          }
        }}
        rows={3}
        placeholder={t("projectPage.newChat")}
        aria-label={t("projectPage.newChat")}
      />
      <div className="project-page__new-bar">
        {agents.length > 0 && (
          <Select
            aria-label={t("projectPage.agent")}
            value={agentId}
            onValueChange={setAgentId}
            options={agents.map((a) => ({ value: a.id, label: a.name }))}
          />
        )}
        <Button type="submit" variant="primary" icon="send" loading={start.isPending} disabled={!text.trim()}>
          {t("projectPage.start")}
        </Button>
      </div>
    </form>
  );
}

function Subprojects({ project, subs }: { project: ChannelCategory; subs: ChannelCategory[] }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const [adding, setAdding] = useState(false);
  const manages = can(org, "manage_channels");
  if (!subs.length && !manages) return null;
  return (
    <section className="project-page__part">
      <h2 className="project-page__part-head">
        {t("projectPage.subprojects")}
        {manages && (
          <Button size="sm" variant="ghost" icon="plus" className="project-page__add" onClick={() => setAdding(true)}>
            {t("projectPage.newSubproject")}
          </Button>
        )}
      </h2>
      {subs.length === 0 ? (
        <p className="project-page__empty">{t("projectPage.noSubprojects")}</p>
      ) : (
        <ul className="project-page__subs">
          {subs.map((s) => (
            <li key={s.id}>
              <Link
                to="/org/$orgId/projects/$categoryId"
                params={{ orgId: org.id, categoryId: s.id }}
                className="project-page__sub"
              >
                <Icon name="layers" size={16} />
                <span>{s.name}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
      <NewCategoryDialog open={adding} onOpenChange={setAdding} parentId={project.id} />
    </section>
  );
}

function Chats({ project }: { project: ChannelCategory }) {
  const { t, i18n } = useTranslation();
  const { org } = useOrg();
  const chats = (useChannels(org.id).data ?? [])
    .filter((c) => c.categoryId === project.id && !c.seenAsAdmin)
    .sort((a, b) => lastAt(b).localeCompare(lastAt(a)));
  return (
    <section className="project-page__part">
      <h2 className="project-page__part-head">{t("projectPage.chats")}</h2>
      {chats.length === 0 ? (
        <p className="project-page__empty">{t("projectPage.noChats")}</p>
      ) : (
        <ul className="project-page__chats">
          {chats.map((c) => (
            <li key={c.id}>
              <Link
                to="/org/$orgId/c/$channelId"
                params={{ orgId: org.id, channelId: c.id }}
                className="project-page__chat"
              >
                <span className="project-page__chat-name">{c.topic || c.name}</span>
                <span className="project-page__when">{relativeTime(t, i18n.language, lastAt(c))}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Instructions({ project, parent }: { project: ChannelCategory; parent?: ChannelCategory }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const update = useUpdateProject(org.id, project.id);
  const [text, setText] = useState(project.instructions ?? "");
  useEffect(() => setText(project.instructions ?? ""), [project.instructions]);
  const save = () => {
    if (text === (project.instructions ?? "")) return;
    update.mutate({ instructions: text }, { onError: (e) => toast.show(errorText(t, e), "error") });
  };
  return (
    <section className="project-page__card">
      <h2 className="project-page__part-head">
        <Icon name="document" size={16} /> {t("projectPage.instructions")}
      </h2>
      <p className="project-page__hint">{t("projectPage.instructionsHint")}</p>
      <Textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        onBlur={save}
        rows={5}
        maxLength={20000}
        readOnly={!can(org, "manage_channels")}
        placeholder={t("projectPage.instructionsPlaceholder")}
        aria-label={t("projectPage.instructions")}
      />
      {parent?.instructions?.trim() && (
        <details className="project-page__from">
          <summary>{t("projectPage.projectInstructions", { name: parent.name })}</summary>
          <p>{parent.instructions}</p>
        </details>
      )}
    </section>
  );
}

/** What its chats' agents learnt and keep for the next ones (they add a line; the person edits it as a whole). */
function Memory({ project, parent }: { project: ChannelCategory; parent?: ChannelCategory }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const update = useUpdateProject(org.id, project.id);
  const [text, setText] = useState(project.memory ?? "");
  useEffect(() => setText(project.memory ?? ""), [project.memory]);
  const save = () => {
    if (text === (project.memory ?? "")) return;
    update.mutate({ memory: text }, { onError: (e) => toast.show(errorText(t, e), "error") });
  };
  return (
    <section className="project-page__card">
      <h2 className="project-page__part-head">
        <Icon name="bulb" size={16} /> {t("projectPage.memory")}
      </h2>
      <p className="project-page__hint">{t("projectPage.memoryHint")}</p>
      <Textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        onBlur={save}
        rows={5}
        maxLength={20000}
        readOnly={!can(org, "manage_channels")}
        placeholder={t("projectPage.memoryEmpty")}
        aria-label={t("projectPage.memory")}
      />
      {parent?.memory?.trim() && (
        <details className="project-page__from">
          <summary>{t("projectPage.projectMemory", { name: parent.name })}</summary>
          <p>{parent.memory}</p>
        </details>
      )}
    </section>
  );
}

function Context({ project, parent }: { project: ChannelCategory; parent?: ChannelCategory }) {
  const { t, i18n } = useTranslation();
  const { org } = useOrg();
  const own = useArtifacts(org.id, { categoryIds: [project.id], sort: "recent" }).artifacts ?? [];
  // a subproject's agents read its project's files too: shown after its own, marked
  // (with no project, the same query as `own`: one request, from the cache)
  const above = useArtifacts(org.id, { categoryIds: [parent?.id ?? project.id], sort: "recent" }).artifacts ?? [];
  const files = [...own, ...(parent ? above.map((a) => ({ ...a, fromProject: true })) : [])];
  const { upload, busy } = useDriveUpload(undefined, { categoryId: project.id });
  return (
    <section className="project-page__card">
      <h2 className="project-page__part-head">
        <Icon name="attach" size={16} /> {t("projectPage.context")}
        <span className="project-page__count">{files.length}</span>
        <UploadButton
          label={t("projectPage.add")}
          onFiles={(f) => void upload(f)}
          busy={busy}
          multiple
          variant="ghost"
          className="project-page__add"
        />
      </h2>
      <p className="project-page__hint">{t(parent ? "projectPage.contextHintSub" : "projectPage.contextHint")}</p>
      {files.length === 0 ? (
        <p className="project-page__empty">{t("projectPage.noFiles")}</p>
      ) : (
        <ul className="project-page__files">
          {files.map((a) => (
            <li key={a.id}>
              <Link
                to="/org/$orgId/drive"
                params={{ orgId: org.id }}
                search={{ artifact: a.id }}
                className="project-page__file"
              >
                <Icon
                  name={(a.kind === "file" ? fileIcon(a.title) : (KIND_ICON[a.kind] ?? "file")) as IconName}
                  size={16}
                />
                <span className="project-page__chat-name">{a.title}</span>
                {"fromProject" in a && parent && (
                  <span className="project-page__when">{t("projectPage.fromProject", { name: parent.name })}</span>
                )}
                <span className="project-page__when">{relativeTime(t, i18n.language, a.updatedAt)}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Scheduled({ project }: { project: ChannelCategory }) {
  const { t, i18n } = useTranslation();
  const { org } = useOrg();
  const chats = new Set((useChannels(org.id).data ?? []).filter((c) => c.categoryId === project.id).map((c) => c.id));
  const routines = (useRoutines(org.id).data ?? []).filter(
    (r) => "channelId" in r.target && chats.has(r.target.channelId),
  );
  return (
    <section className="project-page__card">
      <h2 className="project-page__part-head">
        <Icon name="routines" size={16} /> {t("projectPage.scheduled")}
        <span className="project-page__count">{routines.length}</span>
      </h2>
      {routines.length === 0 ? (
        <p className="project-page__empty">{t("projectPage.noScheduled")}</p>
      ) : (
        <ul className="project-page__files">
          {routines.map((r) => (
            <li key={r.id} className="project-page__file">
              <Icon name="clock" size={16} />
              <span className="project-page__chat-name">{r.name}</span>
              {r.nextRunAt && (
                <span className="project-page__when">{new Date(r.nextRunAt).toLocaleString(i18n.language)}</span>
              )}
            </li>
          ))}
        </ul>
      )}
      <Link to="/org/$orgId/routines" params={{ orgId: org.id }} className="project-page__more">
        {t("projectPage.allScheduled")}
      </Link>
    </section>
  );
}
