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
  useAddProjectFile,
  useApi,
  useChannelCategories,
  useChannels,
  useProjectFiles,
  useRoutines,
  useUpdateProject,
} from "@agenteschat/client";
import { errorText } from "@agenteschat/client/lib/errors";
import { fileIcon } from "@agenteschat/client/lib/files";
import { relativeTime } from "@agenteschat/client/lib/format";
import { can } from "@agenteschat/client/lib/permissions";
import { Button, EmptyState, Icon, type IconName, Popover, Select, Textarea } from "@agenteschat/ui";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { UploadButton } from "@/components/artifacts/Upload";
import { NewCategoryDialog } from "@/components/ChannelCategoryDialogs";
import { toChannelName } from "@/components/NewChannelDialog";
import { useOrg } from "@/components/org-context";
import { KindPicker, KindTile, ModePicker, type ProjectMode } from "@/components/project/KindPicker";
import { isProject, PROJECT_STATES } from "@/components/project/kinds";
import { ProjectConflicts, ProjectHistory } from "@/components/project/ProjectGit";
import { useDirectory } from "@/hooks/useDirectory";
import { useToast } from "@/lib/toast";
import "@/components/project/project.css";

const lastAt = (c: Channel) => c.lastMessage?.createdAt ?? c.createdAt;

/**
 * The project's folder on this computer (~/Projects/project[/subproject]): LensAI opens it in Files (WebTabs.qml,
 * `latte-ai agentgram folder`); a plain browser has nothing to open it with.
 */
const folderLink = (folder: string) => `latteos://agentgram/folder?path=${encodeURIComponent(folder)}`;

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
          <KindTile type={(parent ?? project).projectType} size={40} />
          {project.name}
          {project.anonymous && (
            <span className="project-page__anon" title={t("projectPage.modeHelp.anonymous")}>
              <Icon name="lock" size={14} /> {t("projectPage.modes.anonymous")}
            </span>
          )}
        </h1>
        <ProjectSettings project={project} />
        {project.folder && (
          <a
            className="ac-btn ac-btn--sm project-page__folder"
            href={folderLink(project.folder)}
            target="_blank"
            rel="noopener"
            title={t("projectPage.folderHint")}
          >
            <Icon name="drive" size={16} /> {t("projectPage.folder")}
          </a>
        )}
      </header>
      <div className="project-page__cols">
        <div className="project-page__main">
          <NewChat project={project} />
          {!parent && <Subprojects project={project} subs={subs} />}
          <Chats project={project} />
          {project.online && !project.parentId && (
            <>
              <ProjectConflicts categoryId={project.id} />
              <ProjectHistory categoryId={project.id} />
            </>
          )}
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
  const change = (input: {
    projectType?: ProjectType;
    projectState?: ProjectState;
    online?: boolean;
    anonymous?: boolean;
  }) => update.mutate(input, { onError: (e) => toast.show(errorText(t, e), "error") });
  const mode: ProjectMode = project.anonymous ? "anonymous" : project.online ? "online" : "offline";
  return (
    <div className="project-page__settings">
      {!project.parentId && (
        <Popover
          label={t("projectPage.kind")}
          side="bottom"
          align="end"
          trigger={
            <Button size="sm" type="button" aria-label={t("projectPage.kind")}>
              <KindTile type={project.projectType} size={20} />{" "}
              {t(`projectPage.types.${project.projectType ?? "other"}`)}
            </Button>
          }
        >
          <div className="project-page__pop">
            <KindPicker value={project.projectType ?? "other"} onChange={(k) => k && change({ projectType: k })} />
          </div>
        </Popover>
      )}
      {!project.parentId && (
        <Popover
          label={t("projectPage.where")}
          side="bottom"
          align="end"
          trigger={
            <Button size="sm" type="button" aria-label={t("projectPage.where")}>
              <Icon name={mode === "anonymous" ? "lock" : mode === "online" ? "cloud" : "computer"} size={16} />{" "}
              {t(`projectPage.modes.${mode}`)}
            </Button>
          }
        >
          <div className="project-page__pop">
            <ModePicker
              value={mode}
              onChange={(m) =>
                change(m === "anonymous" ? { anonymous: true } : { online: m === "online", anonymous: false })
              }
            />
            <p className="project-page__hint">{t("projectPage.anonymousModels")}</p>
          </div>
        </Popover>
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
      <p className="project-page__hint">
        {project.anonymous ? t("projectPage.memoryHintAnonymous") : t("projectPage.memoryHint")}
      </p>
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

/** Its Context: the files in its folder, what the person put there and what the agents made; a subproject's also lists its project's. */
function Context({ project, parent }: { project: ChannelCategory; parent?: ChannelCategory }) {
  const { t, i18n } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const own = useProjectFiles(org.id, project.id).data?.files ?? [];
  const above = useProjectFiles(org.id, parent?.id).data?.files ?? [];
  const add = useAddProjectFile(org.id, project.id);
  const files = [
    ...own.map((f) => ({ ...f, from: "" })),
    ...(parent ? above.map((f) => ({ ...f, from: parent.name })) : []),
  ];
  const upload = async (list: File[]) => {
    for (const f of list) await add.mutateAsync(f).catch((e) => toast.show(errorText(t, e), "error"));
  };
  return (
    <section className="project-page__card">
      <h2 className="project-page__part-head">
        <Icon name="attach" size={16} /> {t("projectPage.context")}
        <span className="project-page__count">{files.length}</span>
        {project.folder && (
          <UploadButton
            label={t("projectPage.add")}
            onFiles={(f) => void upload(f)}
            busy={add.isPending}
            multiple
            variant="ghost"
            className="project-page__add"
          />
        )}
      </h2>
      <p className="project-page__hint">
        {project.folder
          ? t(parent ? "projectPage.contextHintSub" : "projectPage.contextHint")
          : t("projectPage.noFolder")}
      </p>
      {files.length === 0 ? (
        <p className="project-page__empty">{t("projectPage.noFiles")}</p>
      ) : (
        <ul className="project-page__files">
          {files.map((f) => (
            <li key={`${f.from}/${f.path}`} className="project-page__file" title={f.path}>
              <Icon name={fileIcon(f.path) as IconName} size={16} />
              <span className="project-page__chat-name">{f.path}</span>
              {f.from && <span className="project-page__when">{t("projectPage.fromProject", { name: f.from })}</span>}
              <span className="project-page__when">{relativeTime(t, i18n.language, f.modifiedAt)}</span>
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
