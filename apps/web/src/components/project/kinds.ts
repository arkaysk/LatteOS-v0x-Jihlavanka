// LatteOS (the user, 19. 11.: as Claude Projects): a category as a project — its kinds, their icons and colours, its states.
import type { ChannelCategory, ProjectState, ProjectType } from "@agenteschat/client";
import { accentPalette } from "@agenteschat/ui";
import type { CSSProperties } from "react";

export const PROJECT_TYPES: ProjectType[] = [
  "code",
  "drawing",
  "book",
  "3d",
  "music",
  "comic",
  "writing",
  "research",
  "study",
  "video",
  "photo",
  "animation",
  "game",
  "web",
  "app",
  "design",
  "podcast",
  "data",
  "business",
  "marketing",
  "finance",
  "home",
  "travel",
  "event",
  "health",
  "other",
];
export const PROJECT_STATES: ProjectState[] = ["active", "paused", "done"];
/**
 * Each kind's own colour, spread round the hue wheel. The tile derives its two themes from it with the design system's
 * accent rule (`accentPalette`: the ink reads at 4.5:1 on the page and on its soft tile, in light and in dark).
 */
export const PROJECT_COLORS: Record<ProjectType, string> = {
  code: "#246ddb",
  drawing: "#24db99",
  book: "#db24a8",
  "3d": "#32db24",
  music: "#8b24db",
  comic: "#b7db24",
  writing: "#2441db",
  research: "#db7c24",
  study: "#24c5db",
  video: "#db2450",
  photo: "#24db6d",
  animation: "#db24d4",
  game: "#5edb24",
  web: "#5e24db",
  app: "#dbd424",
  design: "#db2424",
  podcast: "#db5024",
  data: "#24dbc5",
  business: "#db247c",
  marketing: "#24db41",
  finance: "#b724db",
  home: "#8bdb24",
  travel: "#3224db",
  event: "#dba824",
  health: "#2499db",
  other: "#6b6f76",
};

const styles = new Map<ProjectType, CSSProperties>();

/** The custom properties of a kind's tile (`.kind-tile` in project.css reads the ones of the theme in use). */
export function kindStyle(type: ProjectType | null | undefined): CSSProperties {
  const kind = type ?? "other";
  let style = styles.get(kind);
  if (!style) {
    const { light, dark } = accentPalette(PROJECT_COLORS[kind]);
    style = {
      "--kind-fg-light": light.agent,
      "--kind-bg-light": light.agentSoft,
      "--kind-fg-dark": dark.agent,
      "--kind-bg-dark": dark.agentSoft,
    } as CSSProperties;
    styles.set(kind, style);
  }
  return style;
}

/** A project or a subproject: a category with a kind, or under a project. */
export const isProject = (c: ChannelCategory) => Boolean(c.projectType || c.parentId);
