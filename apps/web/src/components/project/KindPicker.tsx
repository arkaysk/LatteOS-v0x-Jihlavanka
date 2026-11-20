// LatteOS: the project kinds as a grid of coloured tiles, and the three ways a project lives (ADR 0201).
import type { ProjectType } from "@agenteschat/client";
import { Icon, PROJECT_GLYPHS } from "@agenteschat/ui";
import { useId } from "react";
import { useTranslation } from "react-i18next";
import { kindStyle, PROJECT_TYPES } from "./kinds";

/** A kind's icon in its own colour on a softly tinted rounded tile. */
export function KindTile({ type, size = 28 }: { type: ProjectType | null | undefined; size?: number }) {
  const Glyph = PROJECT_GLYPHS[type ?? "other"];
  return (
    <span className="kind-tile" style={{ ...kindStyle(type), "--kind-size": `${size}px` } as React.CSSProperties}>
      <Glyph weight="duotone" size={Math.round(size * 0.62)} aria-hidden />
    </span>
  );
}

/** The kinds as radio tiles (arrow keys move between them); `none` adds "a plain category" first. */
export function KindPicker({
  value,
  onChange,
  none,
}: {
  value: ProjectType | null;
  onChange: (type: ProjectType | null) => void;
  none?: string;
}) {
  const { t } = useTranslation();
  const name = useId();
  const options: { id: ProjectType | null; label: string }[] = [
    ...(none ? [{ id: null, label: none }] : []),
    ...PROJECT_TYPES.map((k) => ({ id: k, label: t(`projectPage.types.${k}`) })),
  ];
  return (
    <div className="kind-grid" role="radiogroup" aria-label={t("projectPage.kind")}>
      {options.map((o) => (
        <label key={o.id ?? "none"} className="kind-pick">
          <input
            type="radio"
            name={name}
            checked={value === o.id}
            onChange={() => onChange(o.id)}
            className="kind-pick__input"
          />
          <span className="kind-pick__face">
            {o.id ? <KindTile type={o.id} /> : <Icon name="channel" size={16} />}
            <span className="kind-pick__label">{o.label}</span>
          </span>
        </label>
      ))}
    </div>
  );
}

export type ProjectMode = "offline" | "online" | "anonymous";

const MODE_ICONS = { offline: "computer", online: "cloud", anonymous: "lock" } as const;

/** Offline, Online or Anonymous, each with what it means. `off`: modes that can't be chosen here. */
export function ModePicker({
  value,
  onChange,
  off = [],
}: {
  value: ProjectMode;
  onChange: (mode: ProjectMode) => void;
  off?: ProjectMode[];
}) {
  const { t } = useTranslation();
  const name = useId();
  return (
    <div className="mode-list" role="radiogroup" aria-label={t("projectPage.where")}>
      {(["offline", "online", "anonymous"] as const).map((m) => (
        <label key={m} className="mode-pick">
          <input
            type="radio"
            name={name}
            checked={value === m}
            disabled={off.includes(m)}
            onChange={() => onChange(m)}
            className="kind-pick__input"
          />
          <span className="mode-pick__face">
            <Icon name={MODE_ICONS[m]} size={16} />
            <span className="mode-pick__text">
              <strong>{t(`projectPage.modes.${m}`)}</strong>
              <span>{t(`projectPage.modeHelp.${m}`)}</span>
            </span>
          </span>
        </label>
      ))}
    </div>
  );
}
