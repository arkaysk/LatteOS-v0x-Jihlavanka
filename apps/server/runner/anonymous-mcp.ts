import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

/**
 * Anonymous projects (ADR 0201): what runs on this computer may, what goes out may not. A turn in an anonymous project's
 * folder gets only the owner's MCP servers that run on this computer, never a remote one that would see the chat.
 */

/** The marker the server puts in an anonymous project's folder. */
export const ANONYMOUS_MARKER = ".agentgram-anonymous";

/** Whether `cwd` is in an anonymous project: the marker in it or in a folder above it, up to the projects' folder. */
export function isAnonymousFolder(cwd: string, projects = process.env.LATTEOS_PROJECTS_DIR?.trim()): boolean {
  if (!projects) return false;
  const root = path.resolve(projects);
  for (let dir = path.resolve(cwd); dir === root || dir.startsWith(`${root}${path.sep}`); dir = path.dirname(dir)) {
    if (existsSync(path.join(dir, ANONYMOUS_MARKER))) return true;
    if (dir === root) break;
  }
  return false;
}

/** Whether an address is on this computer: localhost, 127.0.0.0/8 or ::1 (the name only; no DNS is asked). */
export function isLoopbackUrl(address: string): boolean {
  try {
    const host = new URL(address).hostname.toLowerCase().replace(/^\[|\]$/g, "");
    return host === "localhost" || host === "::1" || /^127(\.\d{1,3}){3}$/.test(host);
  } catch {
    return false;
  }
}

/** The servers of an MCP config that run on this computer: started here (stdio) or at a loopback address. */
export function localMcpServers(servers: unknown): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (!servers || typeof servers !== "object") return out;
  for (const [name, def] of Object.entries(servers as Record<string, unknown>)) {
    const s = def as { type?: unknown; command?: unknown; url?: unknown } | null;
    if (!s || typeof s !== "object") continue;
    const stdio = (s.type === undefined || s.type === "stdio") && typeof s.command === "string" && s.url === undefined;
    const loopback = (s.type === "http" || s.type === "sse") && typeof s.url === "string" && isLoopbackUrl(s.url);
    if (stdio || loopback) out[name] = def;
  }
  return out;
}

/** The owner's own MCP servers in Claude Code's user config (`<config dir or home>/.claude.json`) that run here. */
export function ownerLocalMcpServers(home: string): Record<string, unknown> {
  try {
    const file = path.join(home, ".claude.json");
    return localMcpServers((JSON.parse(readFileSync(file, "utf8")) as { mcpServers?: unknown }).mcpServers);
  } catch {
    return {};
  }
}
