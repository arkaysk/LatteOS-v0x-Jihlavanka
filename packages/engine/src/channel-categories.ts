import { mkdirSync, readdirSync, renameSync, statSync, writeFileSync } from "node:fs";
import path from "node:path";
import type { PubSub } from "@agenteschat/adapters";
import { and, asc, type Database, type Executor, eq, inArray, isNull, schema, sql } from "@agenteschat/db";
import { managesChannel } from "./channels";
import { ConflictError, ForbiddenError, isUniqueViolation, NotFoundError, ValidationError } from "./errors";
import { publishOrgEvent } from "./events";
import { requireActiveMembership, requirePermission } from "./organizations";

const { channelCategories, channels } = schema;

export type ChannelCategory = typeof channelCategories.$inferSelect;

/** LatteOS: a category as a project (Claude Projects): its kind (null: a plain category) and where it stands. */
export type ProjectType = "code" | "drawing" | "book" | "3d" | "music" | "comic" | "other";
export type ProjectState = "active" | "paused" | "done";

/** A category's name as people see it in the sidebar. */
export const CATEGORY_NAME_MAX = 40;

interface Options {
  pubsub?: PubSub;
}

/** Everyone in the org refetches the sidebar's layout (no names in the event: private channels stay private). */
async function layoutChanged(orgId: string, options: Options) {
  await publishOrgEvent(options.pubsub, { type: "org.broadcast", orgId, event: { type: "channels.layout" } });
}

function cleanName(name: string) {
  const clean = name.trim().replace(/\s+/g, " ");
  if (!clean) throw new ValidationError("category name is empty");
  if (clean.length > CATEGORY_NAME_MAX)
    throw new ValidationError(`category name: at most ${CATEGORY_NAME_MAX} characters`);
  return clean;
}

/**
 * Names are unique per place ignoring case ("Marketing" and "marketing" are the same category); LatteOS: a place is the
 * top of the sidebar or one project, so two projects may each have an "Album 1".
 */
async function requireFreeName(
  db: Executor,
  orgId: string,
  name: string,
  except?: string,
  parentId: string | null = null,
) {
  const [row] = await db
    .select({ id: channelCategories.id })
    .from(channelCategories)
    .where(
      and(
        eq(channelCategories.orgId, orgId),
        parentId ? eq(channelCategories.parentId, parentId) : isNull(channelCategories.parentId),
        sql`lower(${channelCategories.name}) = lower(${name})`,
      ),
    );
  if (row && row.id !== except) throw new ConflictError(`The category ${name} already exists`);
}

async function requireCategory(db: Executor, orgId: string, categoryId: string) {
  const [row] = await db
    .select()
    .from(channelCategories)
    .where(and(eq(channelCategories.orgId, orgId), eq(channelCategories.id, categoryId)));
  if (!row) throw new NotFoundError("Category not found");
  return row;
}

/** The org's categories, in sidebar order. */
export async function listChannelCategories(db: Database, actorId: string, orgId: string): Promise<ChannelCategory[]> {
  await requirePermission(db, actorId, orgId, "read");
  return db
    .select()
    .from(channelCategories)
    .where(eq(channelCategories.orgId, orgId))
    .orderBy(asc(channelCategories.position), asc(channelCategories.name));
}

/**
 * The channels of one category (null: those with none), in sidebar order. Only named channels that aren't
 * archived: DMs never sit in the sidebar's categories.
 */
async function channelsIn(db: Executor, orgId: string, categoryId: string | null) {
  const rows = await db
    .select({ id: channels.id })
    .from(channels)
    .where(
      and(
        eq(channels.orgId, orgId),
        eq(channels.kind, "channel"),
        isNull(channels.archivedAt),
        categoryId ? eq(channels.categoryId, categoryId) : isNull(channels.categoryId),
      ),
    )
    .orderBy(asc(channels.position), asc(channels.name));
  return rows.map((r) => r.id);
}

/** Writes `ids` into `categoryId` at positions 0..n (moving any of them there from elsewhere). */
async function writeOrder(db: Executor, orgId: string, categoryId: string | null, ids: string[]) {
  for (const [position, id] of ids.entries()) {
    await db
      .update(channels)
      .set({ categoryId, position })
      .where(and(eq(channels.orgId, orgId), eq(channels.id, id)));
  }
}

/**
 * Where a new channel goes in a category (null: the channels with none). A group nobody arranged by hand has
 * every position at 0 and reads by name, so the new one joins at 0 and keeps that order; once someone
 * arranged it (positions 0..n), the new one goes to its end.
 */
export async function endOfCategory(db: Executor, orgId: string, categoryId: string | null) {
  const [row] = await db
    .select({ n: sql<number | null>`max(${channels.position})::int` })
    .from(channels)
    .where(
      and(
        eq(channels.orgId, orgId),
        eq(channels.kind, "channel"),
        isNull(channels.archivedAt),
        categoryId ? eq(channels.categoryId, categoryId) : isNull(channels.categoryId),
      ),
    );
  const max = Number(row?.n ?? 0);
  return max > 0 ? max + 1 : 0;
}

/**
 * LatteOS: where projects keep their folders on the computer the agents work on (the server and the agents on one
 * computer, LatteOS's own: LATTEOS_PROJECTS_DIR, ~/Projects). Unset: no folders are made (a server elsewhere).
 */
// ponytail: the server makes the folders; a server on another computer than the agents' needs the runner to
export const projectsDir = () => process.env.LATTEOS_PROJECTS_DIR?.trim() || null;

/** A folder's name from a project's: no accents, small letters, words joined by "_" (the user, 18. 11.). */
export const folderName = (name: string) =>
  name
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "") || "project";

/** Its folder, made now: a project's in the projects' folder, a subproject's in its project's; a free name. */
function makeFolder(name: string, parent: ChannelCategory | null): string | null {
  const root = parent ? parent.folder : projectsDir();
  if (!root) return null;
  const base = path.join(root, folderName(name));
  let folder = base;
  for (let n = 2; existsDir(folder); n++) folder = `${base}_${n}`;
  mkdirSync(folder, { recursive: true });
  return folder;
}

/**
 * A project's folder renamed with it, or moved into its new project's: its new place (a free name), what was in it
 * kept. Where nothing makes folders it stays.
 */
function moveFolder(folder: string, name: string, parent: ChannelCategory | null): string {
  const root = parent ? parent.folder : projectsDir();
  if (!root || !existsDir(folder)) return folder;
  const base = path.join(root, folderName(name));
  if (base === folder) return folder;
  let target = base;
  for (let n = 2; existsDir(target); n++) target = `${base}_${n}`;
  mkdirSync(root, { recursive: true });
  renameSync(folder, target);
  return target;
}

const existsDir = (p: string) => {
  try {
    return statSync(p).isDirectory();
  } catch {
    return false;
  }
};

/** A file of a project's folder, as its Context lists it: its path in the folder, size and last change. */
export interface ProjectFile {
  path: string;
  size: number;
  modifiedAt: string;
}

/** The files in a project's folder, the newest first: hidden ones left out, three folders deep, 300 at most. */
export function projectFiles(folder: string | null): ProjectFile[] {
  if (!folder || !existsDir(folder)) return [];
  const out: ProjectFile[] = [];
  const walk = (dir: string, depth: number) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.name.startsWith(".") || out.length >= 300) continue;
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (depth < 3) walk(full, depth + 1);
      } else if (e.isFile()) {
        const st = statSync(full);
        out.push({ path: path.relative(folder, full), size: st.size, modifiedAt: st.mtime.toISOString() });
      }
    }
  };
  walk(folder, 1);
  return out.sort((a, b) => b.modifiedAt.localeCompare(a.modifiedAt));
}

/** A file put in a project's folder ("Add" on its page): its own name, nothing that leaves the folder. */
export function saveProjectFile(folder: string, name: string, bytes: Uint8Array) {
  const clean = path.basename(name).replace(/^\.+/, "").trim();
  if (!clean) throw new ValidationError("The file has no name");
  const target = path.join(folder, clean);
  writeFileSync(target, bytes);
  return path.relative(folder, target);
}

/** A project's folder for its page (who reads the workspace). */
export async function projectFolderOf(db: Database, actorId: string, orgId: string, categoryId: string) {
  await requirePermission(db, actorId, orgId, "read");
  const category = await requireCategory(db, orgId, categoryId);
  return category.folder;
}

/**
 * LatteOS: a subproject goes under a project one level deep: the parent is a category of the org that is not a
 * subproject itself, and a category that has subprojects goes under no one.
 */
async function requireProjectParent(db: Executor, orgId: string, parentId: string, childId: string | null) {
  if (childId && parentId === childId) throw new ValidationError("A project can't be its own subproject");
  const parent = await requireCategory(db, orgId, parentId);
  if (parent.parentId) throw new ValidationError("A subproject can't have subprojects of its own");
  if (childId) {
    const [sub] = await db
      .select({ id: channelCategories.id })
      .from(channelCategories)
      .where(eq(channelCategories.parentId, childId))
      .limit(1);
    if (sub) throw new ValidationError("A project with subprojects can't become a subproject");
  }
}

/** A category a channel may be put in: it belongs to the org. */
export async function requireCategoryInOrg(db: Executor, orgId: string, categoryId: string) {
  return requireCategory(db, orgId, categoryId);
}

/**
 * A new category at the end of the sidebar (admins: it's the org's layout), optionally taking `channelIds`
 * along, in the order given.
 */
export async function createChannelCategory(
  db: Database,
  actorId: string,
  orgId: string,
  input: { name: string; channelIds?: string[]; parentId?: string | null; projectType?: ProjectType | null },
  options: Options = {},
): Promise<ChannelCategory> {
  await requirePermission(db, actorId, orgId, "manage_channels");
  const name = cleanName(input.name);
  const parentId = input.parentId ?? null;
  if (parentId) await requireProjectParent(db, orgId, parentId, null);
  await requireFreeName(db, orgId, name, undefined, parentId);
  try {
    const category = await db.transaction(async (tx) => {
      const [last] = await tx
        .select({ n: sql<number>`coalesce(max(${channelCategories.position}) + 1, 0)::int` })
        .from(channelCategories)
        .where(eq(channelCategories.orgId, orgId));
      const [row] = await tx
        .insert(channelCategories)
        .values({
          orgId,
          name,
          position: Number(last?.n ?? 0),
          createdByUserId: actorId,
          parentId,
          projectType: input.projectType ?? null,
          // a project's folder is made with it (the user, 19. 11.)
          folder:
            parentId || input.projectType
              ? makeFolder(name, parentId ? await requireCategory(tx, orgId, parentId) : null)
              : null,
        })
        .returning();
      if (!row) throw new Error("category insert returned nothing");
      const wanted = [...new Set(input.channelIds ?? [])];
      if (wanted.length) {
        const found = await tx
          .select({ id: channels.id })
          .from(channels)
          .where(
            and(
              eq(channels.orgId, orgId),
              eq(channels.kind, "channel"),
              isNull(channels.archivedAt),
              inArray(channels.id, wanted),
            ),
          );
        if (found.length !== wanted.length) throw new NotFoundError("Channel not found");
        await writeOrder(tx, orgId, row.id, wanted);
      }
      return row;
    });
    await layoutChanged(orgId, options);
    return category;
  } catch (error) {
    if (isUniqueViolation(error)) throw new ConflictError(`The category ${name} already exists`);
    throw error;
  }
}

/**
 * Renames a category (admins); LatteOS: also what makes it a project — its project (one level), kind, state and the
 * instructions its chats' agents keep to. Only what is given changes.
 */
export async function renameChannelCategory(
  db: Database,
  actorId: string,
  orgId: string,
  categoryId: string,
  input: {
    name?: string;
    parentId?: string | null;
    projectType?: ProjectType | null;
    projectState?: ProjectState;
    instructions?: string;
    /** What its agents keep for the next chats (the person edits it as a whole). */
    memory?: string;
  },
  options: Options = {},
): Promise<ChannelCategory> {
  await requirePermission(db, actorId, orgId, "manage_channels");
  const now = await requireCategory(db, orgId, categoryId);
  if (input.parentId) await requireProjectParent(db, orgId, input.parentId, categoryId);
  const name = input.name !== undefined ? cleanName(input.name) : now.name;
  const parentId = input.parentId !== undefined ? input.parentId : now.parentId;
  if (name !== now.name || parentId !== now.parentId) await requireFreeName(db, orgId, name, categoryId, parentId);
  try {
    const [row] = await db
      .update(channelCategories)
      .set({
        name,
        parentId,
        ...(input.projectType !== undefined ? { projectType: input.projectType } : {}),
        ...(input.projectState !== undefined ? { projectState: input.projectState } : {}),
        ...(input.instructions !== undefined ? { instructions: input.instructions } : {}),
        ...(input.memory !== undefined ? { memory: input.memory } : {}),
        // a plain category made a project gets its folder then; renamed or moved, its folder goes with it (the user)
        ...(!now.folder && (input.projectType || parentId)
          ? { folder: makeFolder(name, parentId ? await requireCategory(db, orgId, parentId) : null) }
          : now.folder && (name !== now.name || parentId !== now.parentId)
            ? { folder: moveFolder(now.folder, name, parentId ? await requireCategory(db, orgId, parentId) : null) }
            : {}),
      })
      .where(and(eq(channelCategories.orgId, orgId), eq(channelCategories.id, categoryId)))
      .returning();
    if (!row) throw new NotFoundError("Category not found");
    // its subprojects' folders were inside the one that moved
    if (now.folder && row.folder && row.folder !== now.folder)
      await db
        .update(channelCategories)
        .set({ folder: sql`${row.folder} || substr(${channelCategories.folder}, ${now.folder.length + 1})` })
        .where(and(eq(channelCategories.orgId, orgId), eq(channelCategories.parentId, categoryId)));
    await layoutChanged(orgId, options);
    return row;
  } catch (error) {
    if (isUniqueViolation(error)) throw new ConflictError(`The category ${name} already exists`);
    throw error;
  }
}

/** Deletes a category (admins); its channels go to the end of the ones with no category, in their order. */
export async function deleteChannelCategory(
  db: Database,
  actorId: string,
  orgId: string,
  categoryId: string,
  options: Options = {},
) {
  await requirePermission(db, actorId, orgId, "manage_channels");
  await requireCategory(db, orgId, categoryId);
  await db.transaction(async (tx) => {
    // LatteOS: a project's subprojects go with it (cascade); their chats join the loose ones too
    const subs = await tx
      .select({ id: channelCategories.id })
      .from(channelCategories)
      .where(and(eq(channelCategories.orgId, orgId), eq(channelCategories.parentId, categoryId)));
    const moving = await channelsIn(tx, orgId, categoryId);
    for (const sub of subs) moving.push(...(await channelsIn(tx, orgId, sub.id)));
    const loose = await channelsIn(tx, orgId, null);
    await writeOrder(tx, orgId, null, [...loose, ...moving]);
    await tx
      .delete(channelCategories)
      .where(and(eq(channelCategories.orgId, orgId), eq(channelCategories.id, categoryId)));
  });
  await layoutChanged(orgId, options);
}

/** Moves a category before another one (null: to the end), renumbering them all (admins). */
export async function placeChannelCategory(
  db: Database,
  actorId: string,
  orgId: string,
  categoryId: string,
  input: { beforeCategoryId: string | null },
  options: Options = {},
) {
  await requirePermission(db, actorId, orgId, "manage_channels");
  await requireCategory(db, orgId, categoryId);
  if (input.beforeCategoryId === categoryId) return;
  if (input.beforeCategoryId) await requireCategory(db, orgId, input.beforeCategoryId);
  await db.transaction(async (tx) => {
    const ordered = (
      await tx
        .select({ id: channelCategories.id })
        .from(channelCategories)
        .where(eq(channelCategories.orgId, orgId))
        .orderBy(asc(channelCategories.position), asc(channelCategories.name))
    )
      .map((r) => r.id)
      .filter((id) => id !== categoryId);
    const at = input.beforeCategoryId ? ordered.indexOf(input.beforeCategoryId) : -1;
    ordered.splice(at >= 0 ? at : ordered.length, 0, categoryId);
    for (const [position, id] of ordered.entries()) {
      await tx
        .update(channelCategories)
        .set({ position })
        .where(and(eq(channelCategories.orgId, orgId), eq(channelCategories.id, id)));
    }
  });
  await layoutChanged(orgId, options);
}

/**
 * Puts a channel in a category (null: on top, with none), before `beforeChannelId` of that category or at its
 * end. The channel's creator or an admin, as for renaming it.
 */
export async function placeChannel(
  db: Database,
  actorId: string,
  orgId: string,
  channelId: string,
  input: { categoryId: string | null; beforeChannelId?: string | null },
  options: Options = {},
) {
  const membership = await requireActiveMembership(db, actorId, orgId);
  const [channel] = await db
    .select()
    .from(channels)
    .where(
      and(
        eq(channels.orgId, orgId),
        eq(channels.id, channelId),
        eq(channels.kind, "channel"),
        isNull(channels.archivedAt),
      ),
    );
  if (!channel) throw new NotFoundError("Channel not found");
  if (!(await managesChannel(db, membership, actorId, channel))) {
    throw new ForbiddenError("Only the channel's creator or an admin can move it");
  }
  if (input.categoryId) await requireCategory(db, orgId, input.categoryId);
  if (input.beforeChannelId === channelId) return;
  await db.transaction(async (tx) => {
    const ids = (await channelsIn(tx, orgId, input.categoryId)).filter((id) => id !== channelId);
    const at = input.beforeChannelId ? ids.indexOf(input.beforeChannelId) : -1;
    ids.splice(at >= 0 ? at : ids.length, 0, channelId);
    await writeOrder(tx, orgId, input.categoryId, ids);
  });
  await layoutChanged(orgId, options);
}

/** A project's memory stays short enough to read whole in every chat. */
export const PROJECT_MEMORY_MAX = 20_000;

/**
 * LatteOS: an agent keeps what it learnt in its chat's project (the subproject it is in, never the project above it):
 * one line at the memory's end. False when the chat is in no project or the memory is full.
 */
export async function addToProjectMemory(db: Database, orgId: string, channelId: string, line: string) {
  const [here] = await db
    .select({
      id: channelCategories.id,
      memory: channelCategories.memory,
      projectType: channelCategories.projectType,
      parentId: channelCategories.parentId,
    })
    .from(channelCategories)
    .innerJoin(channels, eq(channels.categoryId, channelCategories.id))
    .where(and(eq(channels.orgId, orgId), eq(channels.id, channelId)));
  if (!here || (!here.projectType && !here.parentId)) return false;
  const text = `- ${line.replace(/\s+/g, " ").trim()}`;
  const memory = here.memory.trim() ? `${here.memory.trimEnd()}\n${text}` : text;
  if (memory.length > PROJECT_MEMORY_MAX) return false;
  await db.update(channelCategories).set({ memory }).where(eq(channelCategories.id, here.id));
  return true;
}

/**
 * LatteOS: the folder a chat's turns start in: its project's (or subproject's), where the person put what the agents
 * work with. Null: the agent's own folder, as before (a chat in no project, or a project with no folder).
 */
export async function chatFolder(db: Executor, orgId: string, channelId: string): Promise<string | null> {
  const [row] = await db
    .select({ folder: channelCategories.folder })
    .from(channelCategories)
    .innerJoin(channels, eq(channels.categoryId, channelCategories.id))
    .where(and(eq(channels.orgId, orgId), eq(channels.id, channelId)));
  return row?.folder ?? null;
}
