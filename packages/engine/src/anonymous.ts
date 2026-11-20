import { appendFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { and, type Executor, eq, inArray, type SQL, schema, sql } from "@agenteschat/db";

/**
 * Anonymous projects (ADR 0201): a project that only its creator sees, whose memory is a Markdown file in its own
 * folder and nothing else. This file holds what the other modules ask about it: where a chat stands, the memory
 * file, the marker, and which of the server's own tools never run in such a chat.
 */

/** The marker a folder carries while its project is anonymous, so programs that index the folders skip it. */
export const ANONYMOUS_MARKER = ".agentgram-anonymous";

/** An anonymous project's memory, in its own folder. */
export const MEMORY_FILE = "MEMORY.md";

/** A project's memory stays short enough to read whole in every chat. */
export const PROJECT_MEMORY_MAX = 20_000;

/**
 * SQL: the `channels` row of this query sits in an anonymous project (its direct category is anonymous: a subproject
 * carries its project's value). Used wherever an administrator's reach is decided and in the lists.
 */
export const inAnonymousProjectSql = (channelCategoryId: unknown = schema.channels.categoryId): SQL =>
  sql`exists (select 1 from channel_categories anon_k where anon_k.id = ${channelCategoryId} and anon_k.anonymous)`;

/**
 * SQL: the chat `channelId` is in an anonymous project that `userId` did not create: it does not exist for them (ADR
 * 0201). For the lists of what happens in chats (approvals, questions), where administrators see every channel's.
 */
export const hiddenFromSql = (channelId: unknown, userId: unknown): SQL =>
  sql`exists (select 1 from channels hc join channel_categories hk on hk.id = hc.category_id
    where hc.id = ${channelId} and hk.anonymous and hk.created_by_user_id is distinct from ${userId})`;

export interface AnonymousPlace {
  categoryId: string;
  /** The only person who sees it; null when that account is gone (nobody does). */
  creatorId: string | null;
  /** Its own folder (null: none), where its MEMORY.md is. */
  folder: string | null;
  /** Its project's folder, for a subproject: its MEMORY.md is only read. */
  parentFolder: string | null;
}

/** Where a chat's project stands when it is anonymous; null for any other chat. */
export async function anonymousPlaceOf(db: Executor, orgId: string, channelId: string): Promise<AnonymousPlace | null> {
  const cats = schema.channelCategories;
  const [here] = await db
    .select({ id: cats.id, creator: cats.createdByUserId, folder: cats.folder, parentId: cats.parentId })
    .from(cats)
    .innerJoin(schema.channels, eq(schema.channels.categoryId, cats.id))
    .where(and(eq(schema.channels.orgId, orgId), eq(schema.channels.id, channelId), eq(cats.anonymous, true)));
  if (!here) return null;
  const [parent] = here.parentId
    ? await db.select({ folder: cats.folder }).from(cats).where(eq(cats.id, here.parentId))
    : [];
  return { categoryId: here.id, creatorId: here.creator, folder: here.folder, parentFolder: parent?.folder ?? null };
}

/** An anonymous project's memory, as written in its folder ("" when there is none yet). */
export function readMemoryFile(folder: string | null): string {
  if (!folder) return "";
  try {
    return readFileSync(path.join(folder, MEMORY_FILE), "utf8");
  } catch {
    return "";
  }
}

/** Replaces the memory file as a whole (the person edits it on the project's page). */
export function writeMemoryFile(folder: string, text: string) {
  mkdirSync(folder, { recursive: true });
  writeFileSync(path.join(folder, MEMORY_FILE), text);
}

/** One line at the end of the memory file; false when the file would pass its limit. */
export function appendMemoryLine(folder: string, line: string): boolean {
  const text = `- ${line.replace(/\s+/g, " ").trim()}\n`;
  const now = readMemoryFile(folder);
  if (now.length + text.length > PROJECT_MEMORY_MAX) return false;
  mkdirSync(folder, { recursive: true });
  appendFileSync(path.join(folder, MEMORY_FILE), now && !now.endsWith("\n") ? `\n${text}` : text);
  return true;
}

/** Puts the marker in a folder, or takes it out (the memory file stays where it is). */
export function setAnonymousMarker(folder: string | null, on: boolean) {
  if (!folder) return;
  const marker = path.join(folder, ANONYMOUS_MARKER);
  if (on) {
    mkdirSync(folder, { recursive: true });
    if (!existsSync(marker)) writeFileSync(marker, "");
  } else rmSync(marker, { force: true });
}

/** Whether an address is on this computer: localhost, 127.0.0.0/8 or ::1 (the name only; no DNS is asked). */
export function isLocalMcpUrl(address: string): boolean {
  try {
    const host = new URL(address).hostname.toLowerCase().replace(/^\[|\]$/g, "");
    return host === "localhost" || host === "::1" || /^127(\.\d{1,3}){3}$/.test(host);
  } catch {
    return false;
  }
}

/** Which of these connections' MCP servers run on this computer (their address is a loopback one). */
export async function loopbackConnections(db: Executor, orgId: string, ids: readonly string[]): Promise<Set<string>> {
  const wanted = [...new Set(ids)];
  if (wanted.length === 0) return new Set();
  const rows = await db
    .select({ id: schema.connectorConnections.id, url: schema.connectorConnections.serverUrl })
    .from(schema.connectorConnections)
    .where(and(eq(schema.connectorConnections.orgId, orgId), inArray(schema.connectorConnections.id, wanted)));
  return new Set(rows.filter((r) => isLocalMcpUrl(r.url)).map((r) => r.id));
}

/** What a tool says when it is refused in an anonymous chat. */
export const ANONYMOUS_REFUSAL =
  "Refused: this chat is in an anonymous project. Connected apps on other computers are not used here. Nothing in it is shared with the workspace, its wiki, its search, its Drive or its other conversations, and nothing from there comes in. Work in this chat and in the project's folder; what is worth keeping goes to MEMORY.md with `remember`.";

/** The built-in tools that read or write the workspace's shared content, by what they are granted for. */
const SHARED_SCOPES = /^(context:read|wiki:|drive:|issues:|calendar:|schedule:|vault:|setup:)/;

/** The ones with no scope that speak to others, keep a shared record or tell the platform something. */
const OUTWARD = new Set([
  "post_message",
  "send_dm",
  "post_update",
  "add_agent_to_channel",
  "ask_agent",
  "tell_agent",
  "hand_off",
  "find_agent",
  "set_status",
  "team_status",
  "send_feedback",
  "offer_feedback",
  "create_dashboard",
  "create_widget",
  "update_widget",
  "list_dashboards",
  "share_dashboard",
  "save_how_to",
  "propose_instruction_change",
]);

/** Whether one of the server's own tools never runs in an anonymous chat (a connected app's tools never do: the gateway). */
export function refusedInAnonymous(tool: { name: string; scope: string; connectionId?: string | null }): boolean {
  return OUTWARD.has(tool.name) || SHARED_SCOPES.test(tool.scope);
}
