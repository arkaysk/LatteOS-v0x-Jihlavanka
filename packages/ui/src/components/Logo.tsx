import { type CSSProperties, useId } from "react";
import { bodyPath, eyeShapes, type SkyPair } from "../agent/engine.js";
import { cx } from "../cx";
import { ditherUrl } from "../sky/dither";

/** The domain in the expanded logo: a brand name, never translated. */

/**
 * The mark is the agent from the engine — body at (4, 9), side 23, and its eyes — in agentgram's fedora, with a coffee to go
 * (LatteOS, the user's 19. 11.: its own mark, not agentes.chat's).
 */
const X = 4;
const Y = 9;
const SIDE = 23;
const BODY = bodyPath(X, Y, SIDE);
const EYES = eyeShapes("round").map((e) => ({ x: X + e.x * SIDE, y: Y + e.y * SIDE, w: e.w * SIDE, h: e.h * SIDE }));
const HAT = "#2b2f36";
const BAND = "#c8a15a";
// its coffee to go: a paper cup, its lid and sleeve
const CUP = "#f7f3ec";
const LID = "#3b2a20";
const SLEEVE = "#a8743f";
const SEAL = "#f2d39a";

/**
 * The agent mark: the square with the cut corner in the sky's dither (solid
 * `agent` under it, and alone in the mono logo) and the engine's white eyes.
 * `sky`: a given workspace's pair (`workspaceSky`) in place of the active one's.
 */
export function LogoMark({
  size,
  className,
  label,
  sky,
}: {
  size?: number;
  className?: string;
  label?: string;
  sky?: SkyPair;
}) {
  const clip = `ac-logo-${useId().replace(/[^\w-]/g, "")}`;
  return (
    <svg
      viewBox="0 0 32 32"
      className={cx("ac-logo__mark", className)}
      style={size ? { width: size, height: size } : undefined}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <defs>
        <clipPath id={clip}>
          <path d={BODY} />
        </clipPath>
      </defs>
      <path className="ac-logo__body" d={BODY} style={sky ? { fill: sky[1] } : undefined} />
      <image
        className="ac-logo__dither"
        href={ditherUrl(sky ?? "sky", 12)}
        x={X}
        y={Y}
        width={SIDE}
        height={SIDE}
        preserveAspectRatio="none"
        clipPath={`url(#${clip})`}
      />
      <g className="ac-logo__eyes">
        {EYES.map((e) => (
          <rect key={e.x} x={e.x} y={e.y} width={e.w} height={e.h} rx={e.w / 2} />
        ))}
      </g>
      <g className="ac-logo__dress">
        <g transform="translate(8.1 9.1) scale(.72)">
          <path
            d="M20.4 18.6h9.2l-1.2 12.4c-.05.55-.5.98-1.05.98h-4.7c-.55 0-1-.43-1.05-.98z"
            fill={CUP}
            stroke={LID}
            strokeWidth=".5"
          />
          <path d="M20.75 22.2h8.5l-.45 4.6h-7.6z" fill={SLEEVE} />
          <circle cx="25" cy="24.5" r="1.25" fill={SEAL} />
          <path d="M19.9 17.2c0-.5.4-.9.9-.9h8.4c.5 0 .9.4.9.9v1.6h-10.2z" fill={LID} />
          <path d="M21.2 16.3l.5-1.1h6.6l.5 1.1z" fill={LID} />
        </g>
        <path d="M9 9.2 10.2 3.2c.2-.9 1-1.4 1.9-1.2l3.9 1 3.9-1c.9-.2 1.7.3 1.9 1.2L23 9.2z" fill={HAT} />
        <path d="M9.4 7.4h13.2l.4 1.8H9z" fill={BAND} />
        <path
          d="M2 9.6c0-.9.7-1.4 1.6-1.4h24.8c.9 0 1.6.5 1.6 1.4 0 .6-.5 1-1.1 1H3.1c-.6 0-1.1-.4-1.1-1z"
          fill={HAT}
        />
      </g>
    </svg>
  );
}

export interface LogoProps {
  /** `main` (app) or `expanded` (+ ".chat" in dot matrix, where the domain matters). */
  variant?: "main" | "expanded";
  /** One-color version. */
  mono?: boolean;
  /** Font size in px; the mark scales with it. Below 18px use `LogoMark` alone. */
  size?: number;
  className?: string;
  style?: CSSProperties;
}

/** LatteOS: "agentgram", the fork of agentes.chat (the user, 18. 11.): the mark + the wordmark in Funnel Display light. */
export function Logo({ variant = "main", mono, size = 24, className, style }: LogoProps) {
  const expanded = variant === "expanded";
  return (
    <span
      className={cx("ac-logo", mono && "ac-logo--mono", className)}
      style={{ fontSize: size, ...style }}
      role="img"
      aria-label="agentgram"
    >
      <LogoMark />
      {expanded ? (
        <span className="ac-logo__word" aria-hidden="true">
          <span>agentgram</span>
        </span>
      ) : (
        <span aria-hidden="true">agentgram</span>
      )}
    </span>
  );
}
