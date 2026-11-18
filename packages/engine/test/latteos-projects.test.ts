// LatteOS (lensAIplan2.md F1-F3): a channel as a project with its subprojects, its state and its kind.
import { afterEach, beforeEach, expect, test } from "bun:test";
import { createChannel, listChannels, updateChannel, ValidationError } from "../src";
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
