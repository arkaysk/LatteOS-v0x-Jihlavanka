// LatteOS (F6): a subproject's chat writes in its own folder, only reads its project's, and sees no sibling.
import { expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { BWRAP, projectSandbox } from "../../runner/latteos-sandbox";

test("a chat in no project is not boxed; a subproject's box hides its siblings and keeps its project to read", () => {
  const root = mkdtempSync(`${tmpdir()}/latteos-box-`);
  try {
    for (const d of ["magna/kniha", "magna/postavy", "iwf/book_1"]) mkdirSync(`${root}/${d}`, { recursive: true });
    writeFileSync(`${root}/magna/svet.md`, "world");
    writeFileSync(`${root}/magna/postavy/vlk.md`, "wolf");
    expect(projectSandbox("/home/someone/elsewhere", root)).toBeNull();
    expect(projectSandbox(root, root)).toBeNull();
    const box = projectSandbox(`${root}/magna/kniha`, root) as string[];
    expect(box).toContain("--ro-bind");
    if (!existsSync(BWRAP)) return;
    const sh = (script: string) =>
      spawnSync(BWRAP, [...box, "--", "/bin/sh", "-c", script], { cwd: `${root}/magna/kniha`, encoding: "utf8" });
    expect(sh("echo x > kapitola.md && cat kapitola.md").stdout.trim()).toBe("x");
    expect(sh("cat ../svet.md").stdout.trim()).toBe("world");
    expect(sh("echo y > ../svet.md").status).not.toBe(0);
    expect(sh("ls ../postavy | wc -l").stdout.trim()).toBe("0");
    expect(sh(`ls ${root}/iwf 2>/dev/null | wc -l`).stdout.trim()).toBe("0");
    // the project's own chat writes in all of it
    const top = projectSandbox(`${root}/magna`, root) as string[];
    const r = spawnSync(BWRAP, [...top, "--", "/bin/sh", "-c", "echo z > svet.md && cat postavy/vlk.md"], {
      cwd: `${root}/magna`,
      encoding: "utf8",
    });
    expect(r.stdout.trim()).toBe("wolf");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("LatteOS's own sandbox goes first, the projects' folders after it (security S7)", () => {
  const base = ["--ro-bind", "/", "/", "--tmpfs", "/run/user/1000"];
  const args = projectSandbox("/home/u/LensAI/agentgram/kniha", "/home/u/LensAI/agentgram", base) as string[];
  expect(args.slice(0, base.length)).toEqual(base);
  expect(args).not.toContain("--dev-bind");
  expect(args.slice(base.length, base.length + 2)).toEqual(["--tmpfs", "/home/u/LensAI/agentgram"]);
});
