// LatteOS (lensAIplan2.md F1-F3): a channel as a project — the project it is a subproject of, what kind of work it is,
// where it stands. In a channel's settings and in a new channel; the server keeps one level (a subproject has none).
import { type Channel, type ProjectState, type ProjectType, useChannels } from "@agenteschat/client";
import { Field, Icon, Select } from "@agenteschat/ui";
import { useTranslation } from "react-i18next";
import { useOrg } from "./org-context";

const NONE = "__none";
export const PROJECT_TYPES: ProjectType[] = ["code", "drawing", "book", "3d", "music", "comic", "other"];
const STATES: ProjectState[] = ["active", "paused", "done"];
const TYPE_ICONS = {
  code: "code",
  drawing: "pen",
  book: "book",
  "3d": "layers",
  music: "sound",
  comic: "image",
  other: "channel",
} as const;

export function ProjectFields({
  channel,
  parentId,
  projectType,
  projectState,
  onChange,
  disabled,
}: {
  /** The channel being changed (it can't be its own project, nor go under one if it has subprojects); none: a new one. */
  channel?: Channel;
  parentId: string | null;
  projectType: ProjectType | null;
  /** Only for a channel that exists (a new one starts active). */
  projectState?: ProjectState;
  onChange: (next: { parentId?: string | null; projectType?: ProjectType | null; projectState?: ProjectState }) => void;
  disabled?: boolean;
}) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const channels = useChannels(org.id).data ?? [];
  const hasSubs = !!channel && channels.some((c) => c.parentId === channel.id);
  // A project is a channel of its own, not this one, and not a subproject itself
  const projects = channels.filter((c) => c.id !== channel?.id && !c.parentId && !c.seenAsAdmin);
  return (
    <>
      <Field label={t("project.parent")} id="project-parent">
        <Select
          id="project-parent"
          value={parentId ?? NONE}
          disabled={disabled || hasSubs}
          onValueChange={(v) => onChange({ parentId: v === NONE ? null : v })}
          options={[
            {
              value: NONE,
              label: t("project.noParent"),
              description: hasSubs ? t("project.hasSubprojects") : undefined,
            },
            ...projects.map((c) => ({ value: c.id, label: `#${c.name}` })),
          ]}
        />
      </Field>
      <Field label={t("project.type")} id="project-type">
        <Select
          id="project-type"
          value={projectType ?? NONE}
          disabled={disabled}
          onValueChange={(v) => onChange({ projectType: v === NONE ? null : (v as ProjectType) })}
          options={[
            { value: NONE, label: t("project.notAProject") },
            ...PROJECT_TYPES.map((k) => ({
              value: k,
              label: t(`project.types.${k}`),
              leading: <Icon name={TYPE_ICONS[k]} size={16} />,
            })),
          ]}
        />
      </Field>
      {projectState !== undefined && projectType && (
        <Field label={t("project.state")} id="project-state">
          <Select
            id="project-state"
            value={projectState}
            disabled={disabled}
            onValueChange={(v) => onChange({ projectState: v as ProjectState })}
            options={STATES.map((k) => ({ value: k, label: t(`project.states.${k}`) }))}
          />
        </Field>
      )}
    </>
  );
}
