// LatteOS (lensAIplan2.md F1-F4): a channel as a project with its subprojects, its state, its kind and its instructions.
import { afterEach, beforeEach, expect, test } from "bun:test";
import { eq, schema } from "@agenteschat/db";
import { createChannel, listChannels, projectBrief, updateChannel, ValidationError } from "../src";
import { type Fixture, setup } from "./fixtures";

let f: Fixture;
beforeEach(async () => {
  f = await setup();
});
afterEach(() => f.close());

test("a subproject goes under its project, one level deep, and the list says so", async () => {
  const magna = await createChannel(f.db, f.owner.id, f.org.id, { name: "magna_moravia", projectType: "book" });
  const kniha = await createChannel(f.db, f.owner.id, f.org.id, { name: "kniha-1", parentId: magna.id });
  const list = await listChannels(f.db, f.owner.id, f.org.id);
  const got = (name: string) => list.find((c) => c.name === name);
  expect(got("magna_moravia")).toMatchObject({ parentId: null, projectType: "book", projectState: "active" });
  expect(got("kniha-1")).toMatchObject({ parentId: magna.id, projectType: null });
  expect(got("general")?.parentId).toBeNull();
  // one level: nothing under a subproject, and a project with subprojects goes under no one
  await expect(createChannel(f.db, f.owner.id, f.org.id, { name: "kapitola", parentId: kniha.id })).rejects.toThrow(
    ValidationError,
  );
  const other = await createChannel(f.db, f.owner.id, f.org.id, { name: "other" });
  await expect(updateChannel(f.db, f.owner.id, f.org.id, magna.id, { parentId: other.id })).rejects.toThrow(
    ValidationError,
  );
  await expect(updateChannel(f.db, f.owner.id, f.org.id, other.id, { parentId: other.id })).rejects.toThrow(
    ValidationError,
  );
});

test("a project's state and kind change, and a subproject leaves its project", async () => {
  const magna = await createChannel(f.db, f.owner.id, f.org.id, { name: "magna_moravia" });
  const kniha = await createChannel(f.db, f.owner.id, f.org.id, { name: "kniha-1", parentId: magna.id });
  await updateChannel(f.db, f.owner.id, f.org.id, magna.id, { projectState: "paused", projectType: "comic" });
  await updateChannel(f.db, f.owner.id, f.org.id, kniha.id, { parentId: null });
  const list = await listChannels(f.db, f.owner.id, f.org.id);
  expect(list.find((c) => c.name === "magna_moravia")).toMatchObject({ projectState: "paused", projectType: "comic" });
  expect(list.find((c) => c.name === "kniha-1")?.parentId).toBeNull();
});

test("a subproject's agents get its project's instructions, then its own, and both Contexts' files", async () => {
  const axel = await createChannel(f.db, f.owner.id, f.org.id, { name: "axel", projectType: "music" });
  const album = await createChannel(f.db, f.owner.id, f.org.id, { name: "album-1", parentId: axel.id });
  await updateChannel(f.db, f.owner.id, f.org.id, axel.id, { instructions: "Lyrics in Slovak." });
  await updateChannel(f.db, f.owner.id, f.org.id, album.id, { instructions: "Garage metal, short songs." });
  const file = (title: string, channelId: string) => ({
    orgId: f.org.id,
    kind: "file" as const,
    title,
    channelId,
    createdByType: "user",
    createdById: f.owner.id,
    updatedByType: "user",
    updatedById: f.owner.id,
  });
  await f.db.insert(schema.artifacts).values([file("band.md", axel.id), file("riffs.txt", album.id)]);
  const [row] = await f.db.select().from(schema.channels).where(eq(schema.channels.id, album.id));
  const text = await projectBrief(f.db, f.org.id, row as typeof schema.channels.$inferSelect);
  expect(text.indexOf("Lyrics in Slovak.")).toBeLessThan(text.indexOf("Garage metal"));
  expect(text).toContain('"band.md"');
  expect(text).toContain('"riffs.txt"');
  // a plain channel has nothing to say
  const [general] = await f.db.select().from(schema.channels).where(eq(schema.channels.name, "general"));
  expect(await projectBrief(f.db, f.org.id, general as typeof schema.channels.$inferSelect)).toBe("");
});
