// LatteOS (10B.79): online projects as on GitHub — two computers, git's own merge, a conflict resolved on the server.
import { afterAll, expect, test } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import {
  conflictSides,
  ensureProjectRepo,
  projectConflicts,
  projectHistory,
  resolveConflict,
} from "@agenteschat/engine";
import { syncOnlineProjects } from "../../runner/latteos-project-sync";

const root = mkdtempSync(`${tmpdir()}/latteos-git-`);
afterAll(() => rmSync(root, { recursive: true, force: true }));

test("two computers keep a project in step; a conflict waits for the person's resolution", async () => {
  const before = process.env.LATTEOS_PROJECTS_DIR;
  process.env.LATTEOS_PROJECTS_DIR = `${root}/server`;
  try {
    const id = "11111111-2222-3333-4444-555555555555";
    const repo = (await ensureProjectRepo(id)) as string;
    const server = "https://agentgram.example";
    const http = `${server}/api/machines/projects/${id}/git`;
    // the computers reach the bare repository straight, where they would over HTTP
    const git = async (args: string[], cwd: string) => {
      const proc = Bun.spawn(["git", ...args.map((a) => (a === http ? repo : a))], {
        cwd,
        stdout: "pipe",
        stderr: "pipe",
      });
      const [out, err, code] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
      ]);
      return { code, out: out + err };
    };
    const fetch = async () => Response.json({ projects: [{ id, path: "magna" }] });
    const round = (name: string) =>
      syncOnlineProjects({
        server,
        token: "agm_x",
        projects: `${root}/${name}`,
        stateFile: `${root}/${name}.json`,
        name,
        fetch,
        git,
      });
    await round("a");
    writeFileSync(`${root}/a/magna/kapitola.md`, "Line one\nLine two\nLine three\n");
    await round("a");
    await round("b");
    expect(readFileSync(`${root}/b/magna/kapitola.md`, "utf8")).toBe("Line one\nLine two\nLine three\n");
    // different lines: git merges them itself
    writeFileSync(`${root}/a/magna/kapitola.md`, "Line ONE\nLine two\nLine three\n");
    writeFileSync(`${root}/b/magna/kapitola.md`, "Line one\nLine two\nLine THREE\n");
    await round("a");
    await round("b");
    await round("a");
    expect(readFileSync(`${root}/a/magna/kapitola.md`, "utf8")).toBe("Line ONE\nLine two\nLine THREE\n");
    // the same line: b's side waits on the server
    writeFileSync(`${root}/a/magna/kapitola.md`, "Line ONE\nLine 2 from a\nLine THREE\n");
    writeFileSync(`${root}/b/magna/kapitola.md`, "Line ONE\nLine 2 from b\nLine THREE\n");
    await round("a");
    await round("b");
    expect(await projectConflicts(id)).toEqual([{ computer: "b", files: ["kapitola.md"] }]);
    const sides = await conflictSides(id, "b", "kapitola.md");
    expect(sides.server).toContain("from a");
    expect(sides.computer).toContain("from b");
    expect(sides.merged).toContain("<<<<<<<");
    await resolveConflict(id, "b", { "kapitola.md": "Line ONE\nLine 2 from a and b\nLine THREE\n" }, "Latte Test");
    expect(await projectConflicts(id)).toEqual([]);
    await round("b");
    await round("a");
    for (const c of ["a", "b"])
      expect(readFileSync(`${root}/${c}/magna/kapitola.md`, "utf8")).toBe(
        "Line ONE\nLine 2 from a and b\nLine THREE\n",
      );
    const history = await projectHistory(id);
    expect(history[0]?.message).toContain("Resolved b's conflict");
    expect(history.some((h) => h.author === "a")).toBe(true);
  } finally {
    if (before === undefined) delete process.env.LATTEOS_PROJECTS_DIR;
    else process.env.LATTEOS_PROJECTS_DIR = before;
  }
});
