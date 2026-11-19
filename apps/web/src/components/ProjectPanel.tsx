// LatteOS (lensAIplan2.md F4, the user's 19. 11.: as Claude Projects): a project's side, beside its conversations — its
// Instructions (what every agent working here keeps to), its Context (the files its agents read: this channel's Drive
// files, and its project's for a subproject, read only here) and what is Scheduled in it. The agents get the
// instructions and the files' names with every turn (engine context.ts `projectBrief`).
import { type Channel, useArtifacts, useChannels, useRoutines, useUpdateChannel } from "@agenteschat/client";
import { KIND_ICON } from "@agenteschat/client/lib/artifacts";
import { fileIcon } from "@agenteschat/client/lib/files";
import { relativeTime } from "@agenteschat/client/lib/format";
import { Button, Icon, type IconName, Textarea } from "@agenteschat/ui";
import { Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { UploadButton, useDriveUpload } from "@/components/artifacts/Upload";
import { useOrg } from "@/components/org-context";
import { SidePanel } from "@/components/SidePanel";
import { useEscClose } from "@/hooks/useEscClose";
import { useToast } from "@/lib/toast";
import "@/components/threads/threads.css";
import "./project-panel.css";

/** A project or a subproject: a channel with a kind, or under a project. */
export const isProject = (c: Channel) => Boolean(c.projectType || c.parentId);

export function ProjectPanel({ channel, onClose }: { channel: Channel; onClose: () => void }) {
  const { t, i18n } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  useEscClose(onClose);
  const channels = useChannels(org.id).data ?? [];
  const parent = channel.parentId ? channels.find((c) => c.id === channel.parentId) : undefined;
  const update = useUpdateChannel(org.id, channel.id);
  const [text, setText] = useState(channel.instructions ?? "");
  useEffect(() => setText(channel.instructions ?? ""), [channel.instructions]);
  const saveText = () => {
    if (text === (channel.instructions ?? "")) return;
    update.mutate({ instructions: text }, { onError: () => toast.show(t("projectPanel.notSaved"), "error") });
  };
  const places = [channel.id, ...(parent ? [parent.id] : [])];
  const files = useArtifacts(org.id, { channelIds: places, sort: "recent" }).artifacts ?? [];
  const scheduled = (useRoutines(org.id).data ?? []).filter(
    (r) => "channelId" in r.target && places.includes(r.target.channelId),
  );
  const title = parent
    ? t("projectPanel.subprojectTitle", { name: channel.name })
    : t("projectPanel.title", { name: channel.name });

  return (
    <SidePanel className="project-panel" label={title} onClose={onClose}>
      <header className="channel__header thread-head thread-head--panel">
        <div className="thread-head__text">
          <h2 className="channel__title thread-title">
            <Icon name="drive" />
            <span className="thread-title__text">{title}</span>
          </h2>
          {parent && (
            <span className="channel__topic thread-head__meta">
              {t("projectPanel.inProject", { name: parent.name })}
            </span>
          )}
        </div>
        <Button size="sm" variant="ghost" iconOnly icon="close" aria-label={t("common.close")} onClick={onClose} />
      </header>
      <div className="thread-panel__page project-panel__body">
        <section className="project-panel__part">
          <h3 className="project-panel__head">
            <Icon name="document" /> {t("projectPanel.instructions")}
          </h3>
          <p className="project-panel__hint">{t("projectPanel.instructionsHint")}</p>
          <Textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            onBlur={saveText}
            rows={6}
            maxLength={20000}
            placeholder={t("projectPanel.instructionsPlaceholder")}
          />
          {parent?.instructions?.trim() && (
            <details className="project-panel__from">
              <summary>{t("projectPanel.projectInstructions", { name: parent.name })}</summary>
              <p>{parent.instructions}</p>
            </details>
          )}
        </section>

        <section className="project-panel__part">
          <h3 className="project-panel__head">
            <Icon name="attach" /> {t("projectPanel.context")}
            <span className="project-panel__count">{files.length}</span>
            <ChannelUpload channelId={channel.id} label={t("projectPanel.add")} />
          </h3>
          <p className="project-panel__hint">{t("projectPanel.contextHint")}</p>
          {files.length === 0 ? (
            <p className="project-panel__empty">{t("projectPanel.noFiles")}</p>
          ) : (
            <ul className="project-panel__files">
              {files.map((a) => (
                <li key={a.id}>
                  <Link
                    to="/org/$orgId/drive"
                    params={{ orgId: org.id }}
                    search={{ artifact: a.id }}
                    className="project-panel__file"
                  >
                    <Icon name={(a.kind === "file" ? fileIcon(a.title) : (KIND_ICON[a.kind] ?? "file")) as IconName} />
                    <span className="project-panel__file-name">{a.title}</span>
                    {a.channelId !== channel.id && parent && (
                      <span className="project-panel__tag">{t("projectPanel.fromProject", { name: parent.name })}</span>
                    )}
                    <span className="project-panel__when">{relativeTime(t, i18n.language, a.updatedAt)}</span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="project-panel__part">
          <h3 className="project-panel__head">
            <Icon name="routines" /> {t("projectPanel.scheduled")}
            <span className="project-panel__count">{scheduled.length}</span>
          </h3>
          {scheduled.length === 0 ? (
            <p className="project-panel__empty">{t("projectPanel.noScheduled")}</p>
          ) : (
            <ul className="project-panel__files">
              {scheduled.map((r) => (
                <li key={r.id} className="project-panel__file">
                  <Icon name="clock" />
                  <span className="project-panel__file-name">{r.name}</span>
                  {r.nextRunAt && (
                    <span className="project-panel__when">{new Date(r.nextRunAt).toLocaleString(i18n.language)}</span>
                  )}
                </li>
              ))}
            </ul>
          )}
          <Link to="/org/$orgId/routines" params={{ orgId: org.id }} className="project-panel__more">
            {t("projectPanel.allScheduled")}
          </Link>
        </section>
      </div>
    </SidePanel>
  );
}

/** "Add": files from this computer into the channel's Drive (the upload names the channel). */
function ChannelUpload({ channelId, label }: { channelId: string; label: string }) {
  const { upload, busy } = useDriveUpload(undefined, channelId);
  return (
    <UploadButton
      label={label}
      onFiles={(f) => void upload(f)}
      busy={busy}
      multiple
      variant="ghost"
      className="project-panel__add"
    />
  );
}
