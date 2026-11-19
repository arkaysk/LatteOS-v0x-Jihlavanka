// LatteOS (10B.79): an online project's folder kept in step between this computer and the server's.
import { expect, test } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { localSums, plan, syncOnlineProjects } from "../../runner/latteos-project-sync";

test("each side's change goes to the other; a change on both keeps both", () => {
  expect(plan({ a: "1" }, {}, {})).toEqual([{ do: "upload", path: "a" }]);
  expect(plan({}, { a: "1" }, {})).toEqual([{ do: "download", path: "a" }]);
  expect(plan({}, { a: "1" }, { a: "1" })).toEqual([{ do: "delete-remote", path: "a" }]);
  expect(plan({ a: "1" }, {}, { a: "1" })).toEqual([{ do: "delete-local", path: "a" }]);
  expect(plan({ a: "2" }, { a: "3" }, { a: "1" })).toEqual([{ do: "conflict", path: "a" }]);
  expect(plan({ a: "2" }, { a: "2" }, { a: "1" })).toEqual([]);
});

/** The server's side of an online project over a folder, as machines.ts answers. */
function fakeServer(serverFolder: string): (url: string, init?: RequestInit) => Promise<Response> {
  return async (url, init) => {
    const u = new URL(url);
    const method = init?.method ?? "GET";
    if (u.pathname === "/api/machines/projects")
      return Response.json({ projects: [{ id: "p1", path: "magna/kniha" }] });
    if (u.pathname.endsWith("/files"))
      return Response.json({
        files: Object.entries(localSums(serverFolder)).map(([p, sha256]) => ({ path: p, sha256 })),
      });
    const target = path.join(serverFolder, u.searchParams.get("path") ?? "");
    if (method === "PUT") {
      mkdirSync(path.dirname(target), { recursive: true });
      writeFileSync(target, new Uint8Array(await new Response(init?.body).arrayBuffer()));
      return new Response(null, { status: 204 });
    }
    if (method === "DELETE") {
      rmSync(target, { force: true });
      return new Response(null, { status: 204 });
    }
    return existsSync(target) ? new Response(readFileSync(target)) : new Response(null, { status: 404 });
  };
}

test("two rounds: new files both ways, a removal, a conflict", async () => {
  const root = mkdtempSync(`${tmpdir()}/latteos-sync-`);
  try {
    const server = `${root}/server`;
    const projects = `${root}/home`;
    const here = `${projects}/magna/kniha`;
    mkdirSync(server, { recursive: true });
    writeFileSync(`${server}/prolog.md`, "from the server");
    const o = {
      server: "https://agentgram.example",
      token: "agm_x",
      projects,
      stateFile: `${root}/state.json`,
      name: "latte-lab",
      fetch: fakeServer(server),
    };
    await syncOnlineProjects(o);
    expect(readFileSync(`${here}/prolog.md`, "utf8")).toBe("from the server");
    mkdirSync(`${here}/postavy`, { recursive: true });
    writeFileSync(`${here}/postavy/vlk.md`, "wolf");
    rmSync(`${here}/prolog.md`);
    await syncOnlineProjects(o);
    expect(readFileSync(`${server}/postavy/vlk.md`, "utf8")).toBe("wolf");
    expect(existsSync(`${server}/prolog.md`)).toBe(false);
    // both change the same file
    writeFileSync(`${here}/postavy/vlk.md`, "wolf, mine");
    writeFileSync(`${server}/postavy/vlk.md`, "wolf, theirs");
    await syncOnlineProjects(o);
    expect(readFileSync(`${here}/postavy/vlk.md`, "utf8")).toBe("wolf, theirs");
    expect(readFileSync(`${here}/postavy/vlk (conflict latte-lab).md`, "utf8")).toBe("wolf, mine");
    expect(readFileSync(`${server}/postavy/vlk (conflict latte-lab).md`, "utf8")).toBe("wolf, mine");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
