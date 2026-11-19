// LatteOS (the user, 19. 11.: as Claude Projects): a category as a project, a subcategory as its subproject, its
// channels as the chats; the agents of a chat keep to the project's instructions and see its Context and other chats.
import { afterEach, beforeEach, expect, test } from "bun:test";
import { eq, schema } from "@agenteschat/db";
import {
  addToProjectMemory,
  chatFolder,
  createChannel,
  createChannelCategory,
  deleteChannelCategory,
  listChannelCategories,
  projectBrief,
  projectFiles,
  renameChannelCategory,
  saveProjectFile,
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

test("a chat of a subproject gets its project's instructions first, then its own, and the other chats of both", async () => {
  const axel = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Axel", projectType: "music" });
  const album = await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Album 1", parentId: axel.id });
  await renameChannelCategory(f.db, f.owner.id, f.org.id, axel.id, { instructions: "Lyrics in Slovak." });
  await renameChannelCategory(f.db, f.owner.id, f.org.id, album.id, { instructions: "Garage metal, short songs." });
  const here = await createChannel(f.db, f.owner.id, f.org.id, { name: "texty", categoryId: album.id });
  await createChannel(f.db, f.owner.id, f.org.id, { name: "obal", categoryId: album.id });
  await createChannel(f.db, f.owner.id, f.org.id, { name: "kapela", categoryId: axel.id });
  const text = await projectBrief(f.db, f.org.id, await row(here.id));
  expect(text.indexOf("Lyrics in Slovak.")).toBeLessThan(text.indexOf("Garage metal"));
  for (const word of ["#obal", "#kapela"]) expect(text).toContain(word);
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

test("a project's folder is made with it, a subproject's inside it; what is in it is the chats' Context", async () => {
  const { mkdtempSync, writeFileSync, existsSync, rmSync } = await import("node:fs");
  const { tmpdir } = await import("node:os");
  const root = mkdtempSync(`${tmpdir()}/latteos-projects-`);
  const before = process.env.LATTEOS_PROJECTS_DIR;
  process.env.LATTEOS_PROJECTS_DIR = root;
  try {
    const magna = await createChannelCategory(f.db, f.owner.id, f.org.id, {
      name: "Magna Moravia",
      projectType: "book",
    });
    const kniha = await createChannelCategory(f.db, f.owner.id, f.org.id, {
      name: "Kniha očí vlka",
      parentId: magna.id,
    });
    expect(magna.folder).toBe(`${root}/magna_moravia`);
    expect(kniha.folder).toBe(`${root}/magna_moravia/kniha_oci_vlka`);
    expect(existsSync(kniha.folder as string)).toBe(true);
    // a plain category has none
    expect((await createChannelCategory(f.db, f.owner.id, f.org.id, { name: "Marketing" })).folder).toBeNull();
    writeFileSync(`${magna.folder}/svet.md`, "Great Moravia, 2300");
    expect(saveProjectFile(kniha.folder as string, "../../escape/kapitola.md", new TextEncoder().encode("x"))).toBe(
      "kapitola.md",
    );
    expect(projectFiles(kniha.folder).map((x) => x.path)).toEqual(["kapitola.md"]);
    const chat = await createChannel(f.db, f.owner.id, f.org.id, { name: "prolog", categoryId: kniha.id });
    expect(await chatFolder(f.db, f.org.id, chat.id)).toBe("~/LensAI/agentgram/magna_moravia/kniha_oci_vlka");
    // a chat in no project works in the main folder of the chats
    const loose = await createChannel(f.db, f.owner.id, f.org.id, { name: "pokec" });
    expect(await chatFolder(f.db, f.org.id, loose.id)).toBe("~/LensAI/agentgram/channels");
    const text = await projectBrief(f.db, f.org.id, await row(chat.id));
    expect(text).toContain("~/LensAI/agentgram/magna_moravia/kniha_oci_vlka (yours to read and write)");
    expect(text).toContain("~/LensAI/agentgram/magna_moravia (only to read)");
    expect(text).toContain("svet.md");
    expect(text).toContain("kapitola.md");
    // renamed, the project's folder goes with it, its subprojects' inside it too
    await renameChannelCategory(f.db, f.owner.id, f.org.id, magna.id, { name: "Veľká Morava" });
    const [moved] = await f.db.select().from(schema.channelCategories).where(eq(schema.channelCategories.id, kniha.id));
    expect(moved?.folder).toBe(`${root}/velka_morava/kniha_oci_vlka`);
    expect(existsSync(`${root}/velka_morava/kniha_oci_vlka/kapitola.md`)).toBe(true);
    expect(existsSync(`${root}/magna_moravia`)).toBe(false);
  } finally {
    if (before === undefined) delete process.env.LATTEOS_PROJECTS_DIR;
    else process.env.LATTEOS_PROJECTS_DIR = before;
    rmSync(root, { recursive: true, force: true });
  }
});
