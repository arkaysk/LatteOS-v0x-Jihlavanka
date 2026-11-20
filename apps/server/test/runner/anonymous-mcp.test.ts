// ADR 0201: in an anonymous project's folder the owner's MCP servers are only those on this computer.
import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { isAnonymousFolder, localMcpServers } from "../../runner/anonymous-mcp";

test("the filter keeps a stdio and a loopback server and drops a remote one", () => {
  const kept = localMcpServers({
    comfy: { type: "stdio", command: "comfy-mcp", args: [] },
    plain: { command: "latte-mcp" },
    local: { type: "http", url: "http://127.0.0.1:8188/mcp" },
    sse: { type: "sse", url: "http://localhost:9000/sse" },
    cloud: { type: "http", url: "https://mcp.example.com/mcp" },
    tricky: { type: "http", url: "http://127.0.0.1.evil.example/mcp" },
    odd: { type: "websocket", url: "ws://127.0.0.1/x" },
  });
  expect(Object.keys(kept).sort()).toEqual(["comfy", "local", "plain", "sse"]);
  expect(localMcpServers(undefined)).toEqual({});
});

test("a folder is anonymous with the marker in it or above it, inside the projects' folder only", () => {
  const root = mkdtempSync(`${tmpdir()}/anon-mcp-`);
  try {
    mkdirSync(`${root}/diary/year_1/deep`, { recursive: true });
    mkdirSync(`${root}/open/part`, { recursive: true });
    writeFileSync(`${root}/diary/.agentgram-anonymous`, "");
    expect(isAnonymousFolder(`${root}/diary/year_1/deep`, root)).toBe(true);
    expect(isAnonymousFolder(`${root}/diary`, root)).toBe(true);
    expect(isAnonymousFolder(`${root}/open/part`, root)).toBe(false);
    expect(isAnonymousFolder(`${root}/diary`, undefined)).toBe(false);
    // a marker outside the projects' folder is nobody's
    writeFileSync(`${tmpdir()}/.agentgram-anonymous`, "");
    expect(isAnonymousFolder(`${root}/open`, root)).toBe(false);
    rmSync(`${tmpdir()}/.agentgram-anonymous`, { force: true });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
