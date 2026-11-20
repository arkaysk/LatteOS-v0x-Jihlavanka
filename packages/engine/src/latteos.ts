import { readFileSync } from "node:fs";
import { and, type Database, eq, isNull, schema } from "@agenteschat/db";
import { type CustomConnectStart, type CustomDeps, connectCustomServer } from "./connectors/custom";
import { NotFoundError, ValidationError } from "./errors";
import { setLocalGatewayOrigin } from "./net-guard";

/**
 * LatteOS's own additions on this computer (ADR 0202): the MCP servers its gateway `latte-mcp` offers, and the skills
 * folder. Unset, none of it exists and the server behaves as an unforked one.
 */
export interface LatteosConfig {
  /** Where `latte-mcp` listens (`LATTEOS_MCP_URL`), e.g. http://127.0.0.1:8791. */
  mcpUrl?: string;
  /** The file holding its master token (`LATTEOS_MCP_TOKEN_FILE`). */
  mcpTokenFile?: string;
  /** The folder of this computer's skills (`LATTEOS_SKILLS_DIR`). */
  skillsDir?: string;
}

let config: LatteosConfig = {};

export function setLatteosConfig(next: LatteosConfig) {
  config = next;
  setLocalGatewayOrigin(next.mcpUrl && next.mcpTokenFile ? next.mcpUrl : undefined);
}

export const latteosMcpEnabled = () => Boolean(config.mcpUrl && config.mcpTokenFile);
export const latteosSkillsDir = () => config.skillsDir ?? null;

/** One MCP server of LatteOS's gateway, running on this computer. */
export interface LatteosMcpServer {
  id: string;
  name: string;
  what: string;
  /** Its address on the gateway: `/mcp/<id>`. */
  path: string;
  token: string;
}

export interface LatteosMcpDeps {
  fetch?: typeof fetch;
  /** The master token (read from its file when absent). */
  token?: () => string;
}

const origin = () => (config.mcpUrl ? new URL(config.mcpUrl).origin : null);

/** What `GET /servers` of the gateway says, checked: only well-formed entries whose path stays on the gateway. */
export async function listLatteosMcp(deps: LatteosMcpDeps = {}): Promise<LatteosMcpServer[]> {
  if (!latteosMcpEnabled() || !config.mcpUrl) return [];
  const master = deps.token ? deps.token() : readFileSync(config.mcpTokenFile as string, "utf8").trim();
  let answer: unknown;
  try {
    const res = await (deps.fetch ?? fetch)(new URL("/servers", config.mcpUrl), {
      headers: { authorization: `Bearer ${master}` },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return [];
    answer = await res.json();
  } catch {
    return [];
  }
  if (!Array.isArray(answer)) return [];
  const out: LatteosMcpServer[] = [];
  for (const e of answer as Record<string, unknown>[]) {
    if (!e || typeof e !== "object") continue;
    const { id, name, what, path, token } = e;
    if (typeof id !== "string" || typeof name !== "string" || typeof path !== "string" || typeof token !== "string")
      continue;
    if (!/^\/mcp\/[\w.-]+$/.test(path) || !token) continue;
    out.push({ id, name: name.slice(0, 80), what: typeof what === "string" ? what.slice(0, 300) : "", path, token });
  }
  return out;
}

/** The address a gateway server is connected at. */
export const latteosMcpUrl = (server: Pick<LatteosMcpServer, "path">) => new URL(server.path, config.mcpUrl).toString();

/** What the apps see of a server on offer: never its token. */
export const latteosMcpView = (s: LatteosMcpServer) => ({ id: s.id, name: s.name, what: s.what });

/** The connections of the workspace made at the gateway (their address is on its origin). */
export async function latteosMcpConnections(db: Database, orgId: string) {
  const here = origin();
  if (!here) return [];
  const rows = await db
    .select({
      id: schema.connectorConnections.id,
      label: schema.connectorConnections.label,
      url: schema.connectorConnections.serverUrl,
    })
    .from(schema.connectorConnections)
    .where(and(eq(schema.connectorConnections.orgId, orgId), isNull(schema.connectorConnections.revokedAt)));
  return rows
    .filter((r) => {
      try {
        return new URL(r.url).origin === here;
      } catch {
        return false;
      }
    })
    .map((r) => ({ id: r.id, label: r.label, url: r.url }));
}

/**
 * Connects one of the gateway's servers as an ordinary custom MCP connection, with its own token as the key (sealed like
 * any). The list is asked again here: the app names only the id.
 */
export async function connectLatteosMcp(
  deps: CustomDeps,
  actorId: string,
  orgId: string,
  serverId: string,
  gateway: LatteosMcpDeps = {},
): Promise<CustomConnectStart> {
  const server = (await listLatteosMcp(gateway)).find((s) => s.id === serverId);
  if (!server) throw new NotFoundError("That MCP server is not installed in LatteOS on this computer");
  const url = latteosMcpUrl(server);
  if ((await latteosMcpConnections(deps.db, orgId)).some((c) => c.url === url))
    throw new ValidationError("This MCP server is connected already", "latteos.mcp_connected");
  return connectCustomServer(deps, actorId, orgId, { serverUrl: url, apiKey: server.token, label: server.name });
}
