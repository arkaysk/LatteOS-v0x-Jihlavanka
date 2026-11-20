// LatteOS (ADR 0201): an anonymous project is only its creator's, its memory a Markdown file in its folder, and what its
// chats hold never reaches the wiki, the search, the memory items or another conversation.
import { afterEach, beforeEach, expect, test } from "bun:test";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { eq, schema } from "@agenteschat/db";
import {
  ANONYMOUS_MARKER,
  addChannelMember,
  buildRunContext,
  createChannel,
  createChannelCategory,
  indexSource,
  listChannelCategories,
  listChannels,
  NotFoundError,
  notify,
  postPersonMessage,
  projectFolderOf,
  refusedInAnonymous,
  renameChannelCategory,
  requireChannelAccess,
  ValidationError,
} from "../src";
import { addMember, type Fixture, setup } from "./fixtures";

let f: Fixture;
let root: string;
let before: string | undefined;
beforeEach(async () => {
  f = await setup({ contextTools: true, wikiTools: true });
  root = mkdtempSync(`${tmpdir()}/latteos-anon-`);
  before = process.env.LATTEOS_PROJECTS_DIR;
  process.env.LATTEOS_PROJECTS_DIR = root;
});
afterEach(async () => {
  if (before === undefined) delete process.env.LATTEOS_PROJECTS_DIR;
  else process.env.LATTEOS_PROJECTS_DIR = before;
  rmSync(root, { recursive: true, force: true });
  await f.close();
});

async function world() {
  const admin = await addMember(f.db, f.org.id, "admin", "boss");
  const project = await createChannelCategory(f.db, f.owner.id, f.org.id, {
    name: "Diary",
    projectType: "book",
    anonymous: true,
  });
  const sub = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Year 1", parentId: project.id });
  const chat = await createChannel(f.db, f.owner.id, f.org.id, { name: "monday", categoryId: sub.id });
  await addChannelMember(f.db, f.owner.id, f.org.id, chat.id, { agentId: f.agent.id });
  return { admin, project, sub, chat };
}

/** A running run of the agent in `channelId`, and the call context of its tools. */
async function runIn(channelId: string, body: string) {
  const asked = await postPersonMessage({ db: f.db, pubsub: f.pubsub }, f.owner.id, f.org.id, channelId, { body });
  const [run] = await f.db
    .insert(schema.agentRuns)
    .values({
      orgId: f.org.id,
      agentId: f.agent.id,
      channelId,
      threadRootId: asked.id,
      triggerMessageId: asked.id,
      trigger: "mention",
      hop: 1,
      status: "running",
      brain: "model",
    })
    .returning();
  if (!run) throw new Error("no run");
  const ctx = {
    db: f.db,
    orgId: f.org.id,
    agentId: f.agent.id,
    runId: run.id,
    channelId,
    threadRootId: asked.id,
    triggerMessageId: asked.id,
  };
  return { asked, run, ctx };
}

test("the project is marked, a subproject inherits it, and nobody else finds it, not even an admin", async () => {
  const { admin, project, sub, chat } = await world();
  expect(sub.anonymous).toBe(true);
  for (const folder of [project.folder, sub.folder]) expect(existsSync(`${folder}/${ANONYMOUS_MARKER}`)).toBe(true);
  expect((await listChannelCategories(f.db, f.owner.id, f.org.id)).map((c) => c.id)).toContain(project.id);
  expect(await listChannelCategories(f.db, admin.id, f.org.id)).toEqual([]);
  await expect(projectFolderOf(f.db, admin.id, f.org.id, project.id)).rejects.toThrow(NotFoundError);
  await expect(renameChannelCategory(f.db, admin.id, f.org.id, sub.id, { name: "x" })).rejects.toThrow(NotFoundError);
  // its chat is private, with only its creator in it, and an administrator neither lists it nor reads it
  const row = (await f.db.select().from(schema.channels).where(eq(schema.channels.id, chat.id)))[0];
  expect(row?.visibility).toBe("private");
  expect((await listChannels(f.db, admin.id, f.org.id)).map((c) => c.id)).not.toContain(chat.id);
  expect((await listChannels(f.db, f.owner.id, f.org.id)).map((c) => c.id)).toContain(chat.id);
  await expect(requireChannelAccess(f.db, admin.id, f.org.id, chat.id)).rejects.toThrow(NotFoundError);
  await expect(addChannelMember(f.db, admin.id, f.org.id, chat.id, { userId: admin.id })).rejects.toThrow();
  // a subproject can't be made non-anonymous under it, and only its creator switches the project
  await expect(renameChannelCategory(f.db, f.owner.id, f.org.id, sub.id, { anonymous: false })).rejects.toThrow(
    ValidationError,
  );
  await expect(renameChannelCategory(f.db, f.owner.id, f.org.id, project.id, { online: true })).rejects.toThrow(
    ValidationError,
  );
});

test("switching to anonymous is the creator's, makes the chats private and applies to subprojects; switching back keeps MEMORY.md", async () => {
  const project = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Notes", projectType: "other" });
  const sub = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Part", parentId: project.id });
  const other = await addMember(f.db, f.org.id, "admin", "second");
  const chat = await createChannel(f.db, f.owner.id, f.org.id, { name: "open", categoryId: sub.id });
  await addChannelMember(f.db, f.owner.id, f.org.id, chat.id, { userId: other.id });
  const made = await renameChannelCategory(f.db, f.owner.id, f.org.id, project.id, { anonymous: true });
  expect(made.anonymous).toBe(true);
  const [subRow] = await f.db.select().from(schema.channelCategories).where(eq(schema.channelCategories.id, sub.id));
  expect(subRow?.anonymous).toBe(true);
  const members = await f.db.select().from(schema.channelMembers).where(eq(schema.channelMembers.channelId, chat.id));
  expect(members.map((m) => m.userId)).toEqual([f.owner.id]);
  // the memory page writes the file, not the column
  const edited = await renameChannelCategory(f.db, f.owner.id, f.org.id, project.id, { memory: "- keep this" });
  expect(readFileSync(`${project.folder}/MEMORY.md`, "utf8")).toBe("- keep this");
  expect(edited.memory).toBe("- keep this");
  const [stored] = await f.db
    .select()
    .from(schema.channelCategories)
    .where(eq(schema.channelCategories.id, project.id));
  expect(stored?.memory).toBe("");
  const back = await renameChannelCategory(f.db, f.owner.id, f.org.id, project.id, { anonymous: false });
  expect(back.anonymous).toBe(false);
  expect(existsSync(`${project.folder}/${ANONYMOUS_MARKER}`)).toBe(false);
  expect(existsSync(`${sub.folder}/${ANONYMOUS_MARKER}`)).toBe(false);
  expect(readFileSync(`${project.folder}/MEMORY.md`, "utf8")).toBe("- keep this");
  // not the creator: refused
  const mine = await createChannelCategory(f.db, other.id, f.org.id, { name: "Mine", projectType: "other" });
  await expect(renameChannelCategory(f.db, f.owner.id, f.org.id, mine.id, { anonymous: true })).rejects.toThrow();
});

test("without the server's own folder an anonymous project is refused", async () => {
  delete process.env.LATTEOS_PROJECTS_DIR;
  const files = process.env.FILES_DIR;
  delete process.env.FILES_DIR;
  try {
    await expect(
      createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Nope", projectType: "other", anonymous: true }),
    ).rejects.toThrow(ValidationError);
  } finally {
    if (files !== undefined) process.env.FILES_DIR = files;
  }
});

test("remember in an anonymous chat is a line of its folder's MEMORY.md and nothing in the database; the wiki is refused", async () => {
  const { sub, chat } = await world();
  const { ctx } = await runIn(chat.id, "remember this");
  if (!f.tools) throw new Error("no tools");
  for (const forWhom of ["me", "team", "project"]) {
    const done = await f.tools.invoke(ctx, {
      toolUseId: `r-${forWhom}`,
      name: "remember",
      input: { content: `The wolf speaks softly (${forWhom})`, for: forWhom },
    });
    expect(done.type === "result" && done.output.isError).toBeFalsy();
  }
  const file = readFileSync(`${sub.folder}/MEMORY.md`, "utf8");
  expect(file.split("\n").filter(Boolean)).toHaveLength(3);
  expect(file).toContain("The wolf speaks softly (team)");
  expect(await f.db.select().from(schema.contextItems)).toEqual([]);
  const wiki = await f.tools.invoke(ctx, {
    toolUseId: "w1",
    name: "create_wiki_page",
    input: { title: "Diary", content: "Monday" },
  });
  expect(wiki.type === "result" && wiki.output.isError).toBe(true);
  expect(wiki.type === "result" && wiki.output.content).toContain("anonymous project");
  expect(await f.db.select().from(schema.wikiPages)).toEqual([]);
  // nor are the memory items it could change, or its other tools that read the workspace, there to use
  const listed = (await f.tools.granted(ctx)).map((t) => t.name);
  for (const name of ["search_context", "search_wiki", "create_wiki_page", "post_message", "send_dm"])
    expect(listed).not.toContain(name);
  expect(listed).toContain("remember");
});

test("its messages are not in the search index", async () => {
  const { chat } = await world();
  const { asked } = await runIn(chat.id, "a secret diary line");
  await indexSource(f.context, { orgId: f.org.id, kind: "message", sourceId: asked.id });
  expect(await f.db.select().from(schema.searchDocuments)).toEqual([]);
  // a message of an ordinary channel still is
  const open = await postPersonMessage({ db: f.db, pubsub: f.pubsub }, f.owner.id, f.org.id, f.general.id, {
    body: "an ordinary line",
  });
  await indexSource(f.context, { orgId: f.org.id, kind: "message", sourceId: open.id });
  expect(await f.db.select().from(schema.searchDocuments)).toHaveLength(1);
});

test("a run there reads its own MEMORY.md and its project's, never the team's memory", async () => {
  const { project, sub, chat } = await world();
  writeFileSync(`${project.folder}/MEMORY.md`, "- the project line\n");
  writeFileSync(`${sub.folder}/MEMORY.md`, "- the subproject line\n");
  await f.db.insert(schema.contextItems).values({
    orgId: f.org.id,
    kind: "rule",
    scopeType: "org",
    content: "Always greet in Latin.",
    createdByKind: "person",
    createdById: f.owner.id,
    channelIds: [],
  });
  const { run } = await runIn(chat.id, "hello");
  const text = (await buildRunContext(f.db, run, f.agent, { maxMessages: 30 })).system.map((b) => b.text).join("\n");
  expect(text).toContain("the project line");
  expect(text).toContain("the subproject line");
  expect(text).toContain("Acme builds rockets.");
  expect(text).not.toContain("Always greet in Latin.");
  // the same rule is the prompt of a run in an ordinary channel
  const { run: plain } = await runIn(f.general.id, "hello");
  const other = (await buildRunContext(f.db, plain, f.agent, { maxMessages: 30 })).system.map((b) => b.text).join("\n");
  expect(other).toContain("Always greet in Latin.");
});

test("connected apps' tools are not offered or run there, an online project goes Offline first, and no push is queued", async () => {
  const { chat } = await world();
  const { ctx } = await runIn(chat.id, "use the app");
  if (!f.tools) throw new Error("no tools");
  const app = { name: "crm_search", scope: "custom:x:read", connectionId: "5f0e0f9e-0000-4000-8000-000000000001" };
  expect(refusedInAnonymous(app)).toBe(false);
  const listed = (await f.tools.granted(ctx)).filter((t) => t.connectionId);
  expect(listed).toEqual([]);
  // online first: refused with its own code
  const online = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Shared", projectType: "other" });
  await renameChannelCategory(f.db, f.owner.id, f.org.id, online.id, { online: true });
  await expect(renameChannelCategory(f.db, f.owner.id, f.org.id, online.id, { anonymous: true })).rejects.toThrow(
    ValidationError,
  );
  // the inbox gets the notification, the push queue nothing
  const me = await addMember(f.db, f.org.id, "member", "friend");
  await notify({ db: f.db, pubsub: f.pubsub }, {
    orgId: f.org.id,
    userIds: [me.id],
    kind: "mention",
    groupKey: "g1",
    source: { channelId: chat.id },
    latest: { text: "" },
  } as never);
  expect(await f.db.select().from(schema.notifications)).toHaveLength(1);
  expect((await f.db.select().from(schema.outbox)).filter((j) => j.kind === "push.send")).toEqual([]);
});
