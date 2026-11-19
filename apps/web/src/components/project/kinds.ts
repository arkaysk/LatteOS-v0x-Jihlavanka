// LatteOS (the user, 19. 11.: as Claude Projects): a category as a project — its kinds, their icons, its states.
import type { ChannelCategory, ProjectState, ProjectType } from "@agenteschat/client";
import type { IconName } from "@agenteschat/ui";

export const PROJECT_TYPES: ProjectType[] = ["code", "drawing", "book", "3d", "music", "comic", "other"];
export const PROJECT_STATES: ProjectState[] = ["active", "paused", "done"];
export const PROJECT_ICONS: Record<ProjectType, IconName> = {
  code: "code",
  drawing: "pen",
  book: "book",
  "3d": "layers",
  music: "sound",
  comic: "image",
  other: "drive",
};

/** A project or a subproject: a category with a kind, or under a project. */
export const isProject = (c: ChannelCategory) => Boolean(c.projectType || c.parentId);
