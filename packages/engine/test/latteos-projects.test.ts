// LatteOS (the user, 19. 11.: as Claude Projects): a category as a project, a subcategory as its subproject, its
// channels as the chats; the agents of a chat keep to the project's instructions and see its Context and other chats.
import { afterEach, beforeEach, expect, test } from "bun:test";
import { eq, schema } from "@agenteschat/db";
import {
  addToProjectMemory,
  createChannel,
  createChannelCategory,
  deleteChannelCategory,
  listChannelCategories,
  projectBrief,
  renameChannelCategory,
  ValidationError,
} from "../src";
import { type Fixture, setup } from "./fixtures";

let f: Fixture;
beforeEach(async () => {
  f = await setup();
});
afterEach(() => f.close());

const row = async (id: string) =>
  (
    await f.db.select().from(schema.channels).where(eq(schema.channels.id, id))
  )[0] as typeof schema.channels.$inferSelect;

test("a subproject goes under its project, one level deep; two projects may each have an Album 1", async () => {
  const axel = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Axel ReV.On", projectType: "music" });
  const magna = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Magna Moravia", projectType: "book" });
  const album = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Album 1", parentId: axel.id });
  await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Album 1", parentId: magna.id });
  const list = await listChannelCategories(f.db, f.owner.id, f.org.id);
  expect(list.find((c) => c.id === album.id)).toMatchObject({ parentId: axel.id, projectState: "active" });
  await expect(createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Song", parentId: album.id })).rejects.toThrow(
    ValidationError,
  );
  await expect(renameChannelCategory(f.db, f.owner.id, f.org.id, axel.id, { parentId: magna.id })).rejects.toThrow(
    ValidationError,
  );
  // a project goes with its subprojects; their chats stay, with no category
  const chat = await createChannel(f.db, f.owner.id, f.org.id, { name: "riffs", categoryId: album.id });
  await deleteChannelCategory(f.db, f.owner.id, f.org.id, axel.id);
  expect((await row(chat.id)).categoryId).toBeNull();
});

test("a chat of a subproject gets its project's instructions first, then its own, both Contexts and other chats", async () => {
  const axel = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Axel", projectType: "music" });
  const album = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Album 1", parentId: axel.id });
  await renameChannelCategory(f.db, f.owner.id, f.org.id, axel.id, { instructions: "Lyrics in Slovak." });
  await renameChannelCategory(f.db, f.owner.id, f.org.id, album.id, { instructions: "Garage metal, short songs." });
  const here = await createChannel(f.db, f.owner.id, f.org.id, { name: "texty", categoryId: album.id });
  await createChannel(f.db, f.owner.id, f.org.id, { name: "obal", categoryId: album.id });
  await createChannel(f.db, f.owner.id, f.org.id, { name: "kapela", categoryId: axel.id });
  const file = (title: string, categoryId: string) => ({
    orgId: f.org.id,
    kind: "file" as const,
    title,
    categoryId,
    createdByType: "user",
    createdById: f.owner.id,
    updatedByType: "user",
    updatedById: f.owner.id,
  });
  await f.db.insert(schema.artifacts).values([file("band.md", axel.id), file("riffs.txt", album.id)]);
  const text = await projectBrief(f.db, f.org.id, await row(here.id));
  expect(text.indexOf("Lyrics in Slovak.")).toBeLessThan(text.indexOf("Garage metal"));
  for (const word of ['"band.md"', '"riffs.txt"', "#obal", "#kapela"]) expect(text).toContain(word);
  expect(text).not.toContain("#texty");
  // a chat in a plain category, or in none, hears nothing of projects
  const plain = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Marketing" });
  const loose = await createChannel(f.db, f.owner.id, f.org.id, { name: "news", categoryId: plain.id });
  expect(await projectBrief(f.db, f.org.id, await row(loose.id))).toBe("");
});

test("an agent keeps a line in its subproject's memory, never in the project above; the next chats read both", async () => {
  const magna = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Magna", projectType: "book" });
  const kniha = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Kniha", parentId: magna.id });
  await renameChannelCategory(f.db, f.owner.id, f.org.id, magna.id, { memory: "- The world is Great Moravia, 2300." });
  const chat = await createChannel(f.db, f.owner.id, f.org.id, { name: "prolog", categoryId: kniha.id });
  expect(await addToProjectMemory(f.db, f.org.id, chat.id, "The wolf speaks in short sentences.")).toBe(true);
  const [sub] = await f.db.select().from(schema.channelCategories).where(eq(schema.channelCategories.id, kniha.id));
  const [top] = await f.db.select().from(schema.channelCategories).where(eq(schema.channelCategories.id, magna.id));
  expect(sub?.memory).toBe("- The wolf speaks in short sentences.");
  expect(top?.memory).toBe("- The world is Great Moravia, 2300.");
  const next = await createChannel(f.db, f.owner.id, f.org.id, { name: "kapitola-1", categoryId: kniha.id });
  const text = await projectBrief(f.db, f.org.id, await row(next.id));
  expect(text).toContain("Great Moravia");
  expect(text).toContain("short sentences");
  // a chat in no project keeps nothing there
  const loose = await createChannel(f.db, f.owner.id, f.org.id, { name: "loose" });
  expect(await addToProjectMemory(f.db, f.org.id, loose.id, "anything")).toBe(false);
});
