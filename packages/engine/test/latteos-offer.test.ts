// LatteOS (ADR 0202): the MCP servers and skills this computer offers, and the one address besides public https ones.
import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { eq, schema } from "@agenteschat/db";
import {
  assertPublicHttpsUrl,
  connectLatteosMcp,
  installLatteosSkill,
  latteosMcpConnections,
  listLatteosMcp,
  listLatteosSkills,
  setLatteosConfig,
} from "../src";
import { fakeGithubMcp } from "./fake-mcp";
import { type Fixture, setup } from "./fixtures";

let f: Fixture;
let dir: string;
beforeEach(async () => {
  f = await setup();
  dir = mkdtempSync(`${tmpdir()}/latteos-offer-`);
});
afterEach(async () => {
  setLatteosConfig({});
  rmSync(dir, { recursive: true, force: true });
  await f.close();
});

const gateway = (entries: unknown) => ({
  token: () => "master-token",
  fetch: (async (url: URL | string, init?: RequestInit) => {
    expect(String(url)).toBe("http://127.0.0.1:8791/servers");
    expect(((init?.headers ?? {}) as Record<string, string>).authorization).toBe("Bearer master-token");
    return Response.json(entries);
  }) as unknown as typeof fetch,
});

test("only the gateway's exact origin passes the public-https guard", async () => {
  setLatteosConfig({ mcpUrl: "http://127.0.0.1:8791", mcpTokenFile: "/x" });
  expect((await assertPublicHttpsUrl("http://127.0.0.1:8791/mcp/zz-echo")).pathname).toBe("/mcp/zz-echo");
  for (const other of [
    "http://127.0.0.1:8792/mcp/x",
    "http://localhost:8791/mcp/x",
    "https://127.0.0.1:8791/mcp/x",
    "http://10.0.0.5:8791/mcp/x",
  ])
    await expect(assertPublicHttpsUrl(other)).rejects.toThrow();
  setLatteosConfig({});
  await expect(assertPublicHttpsUrl("http://127.0.0.1:8791/mcp/x")).rejects.toThrow();
});

test("the gateway's list is read with the master token, and connecting makes an ordinary custom connection", async () => {
  setLatteosConfig({ mcpUrl: "http://127.0.0.1:8791", mcpTokenFile: "/x" });
  const entries = [
    { id: "zz-echo", name: "Echo test", what: "test", path: "/mcp/zz-echo", token: "echo-token-123456" },
    { id: "bad", name: "Bad", what: "", path: "https://evil.example.com/mcp", token: "t" },
    { id: "short", name: "No token", path: "/mcp/short" },
  ];
  const listed = await listLatteosMcp(gateway(entries));
  expect(listed.map((s) => s.id)).toEqual(["zz-echo"]);
  const mcp = fakeGithubMcp();
  const deps = { db: f.db, keyWrappers: [f.keyWrapper], publicUrl: "https://chat.example.com", connect: mcp.connect };
  const started = await connectLatteosMcp(deps, f.owner.id, f.org.id, "zz-echo", gateway(entries));
  if (started.status !== "connected") throw new Error("expected connected");
  expect(started.server.label).toBe("Echo test");
  expect((await latteosMcpConnections(f.db, f.org.id)).map((c) => c.url)).toEqual([
    "http://127.0.0.1:8791/mcp/zz-echo",
  ]);
  // its own token went as the key
  expect(mcp.sessions.some((s) => s.headers.authorization === "Bearer echo-token-123456")).toBe(true);
  await expect(connectLatteosMcp(deps, f.owner.id, f.org.id, "zz-echo", gateway(entries))).rejects.toThrow();
  await expect(connectLatteosMcp(deps, f.owner.id, f.org.id, "nope", gateway(entries))).rejects.toThrow();
  // unset: nothing is offered
  setLatteosConfig({});
  expect(await listLatteosMcp(gateway(entries))).toEqual([]);
});

const skill = (folder: string, name: string, description: string) => {
  mkdirSync(`${dir}/${folder}/refs`, { recursive: true });
  writeFileSync(`${dir}/${folder}/SKILL.md`, `---\nname: ${name}\ndescription: ${description}\n---\nDo the thing.\n`);
  writeFileSync(`${dir}/${folder}/refs/notes.md`, "notes");
};

test("the skills folder: frontmatter listed, installed with its files, Update when it changed, links outside refused", async () => {
  setLatteosConfig({ skillsDir: dir });
  skill("alpha", "alpha", "Does alpha");
  skill("beta", "beta", "Does beta");
  mkdirSync(`${dir}/outside`);
  const secret = mkdtempSync(`${tmpdir()}/latteos-secret-`);
  skill("leak", "leak", "Reads a link");
  writeFileSync(`${secret}/passwd`, "root:secret");
  symlinkSync(`${secret}/passwd`, `${dir}/leak/refs/stolen.md`);
  symlinkSync(secret, `${dir}/linked`);
  try {
    let listed = await listLatteosSkills(f, f.owner.id, f.org.id);
    expect(listed.skills.map((s) => [s.folder, s.name, s.description, s.state])).toEqual([
      ["alpha", "alpha", "Does alpha", "new"],
      ["beta", "beta", "Does beta", "new"],
      ["leak", "leak", "Reads a link", "new"],
    ]);
    const deps = { db: f.db, blobs: f.artifactDeps.blobs };
    const saved = await installLatteosSkill(deps, f.owner.id, f.org.id, "alpha");
    expect(saved.name).toBe("alpha");
    const files = await f.db.select().from(schema.skillFiles).where(eq(schema.skillFiles.skillId, saved.id));
    expect(files.map((x) => x.path)).toContain("refs/notes.md");
    listed = await listLatteosSkills(f, f.owner.id, f.org.id);
    expect(listed.skills.find((s) => s.folder === "alpha")?.state).toBe("installed");
    const later = new Date(Date.now() + 5000);
    utimesSync(`${dir}/alpha/refs/notes.md`, later, later);
    expect((await listLatteosSkills(f, f.owner.id, f.org.id)).skills.find((s) => s.folder === "alpha")?.state).toBe(
      "update",
    );
    // a link out of the folder is never followed, a folder that is one is not offered
    await installLatteosSkill(deps, f.owner.id, f.org.id, "leak");
    const [leak] = await f.db.select().from(schema.skills).where(eq(schema.skills.slug, "leak"));
    const leaked = await f.db
      .select()
      .from(schema.skillFiles)
      .where(eq(schema.skillFiles.skillId, leak?.id ?? ""));
    expect(leaked.map((x) => x.path)).not.toContain("refs/stolen.md");
    await expect(installLatteosSkill(deps, f.owner.id, f.org.id, "linked")).rejects.toThrow();
    await expect(installLatteosSkill(deps, f.owner.id, f.org.id, "../etc")).rejects.toThrow();
  } finally {
    rmSync(secret, { recursive: true, force: true });
  }
  setLatteosConfig({});
  expect((await listLatteosSkills(f, f.owner.id, f.org.id)).enabled).toBe(false);
});
