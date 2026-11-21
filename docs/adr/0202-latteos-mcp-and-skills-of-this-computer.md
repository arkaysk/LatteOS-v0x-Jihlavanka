# 0202. LatteOS: the MCP servers and skills of this computer

- Status: Accepted (built)
- Date: 2026-11-20
- Extends: 0020 (skills), 0186 (request headers), 0201 (anonymous projects: a loopback connector is allowed there)
- Code: `packages/engine/src/latteos.ts`, `latteos-skills.ts`, `net-guard.ts` (`setLocalGatewayOrigin`), `skills.ts`
  (`repositorySkill` exported); `packages/config/src/schema.ts` (`LATTEOS_MCP_URL`, `LATTEOS_MCP_TOKEN_FILE`,
  `LATTEOS_SKILLS_DIR`); server `routes/app/connectors-custom.ts` and `skills.ts` (`/latteos/mcp`, `/latteos/skills`);
  web `components/LatteosMcp.tsx`, `Skills.tsx`; tests `packages/engine/test/latteos-offer.test.ts`

## Decision

The server's own connector store and skill installers stay as they are. Three variables, all optional, add LatteOS's
offer; unset, nothing of it shows and nothing changes.

1. **MCP.** With `LATTEOS_MCP_URL` and `LATTEOS_MCP_TOKEN_FILE`, Settings > Connectors has a card "MCP LatteOS" between
   the connectors and the GitHub app, with "Add MCP from LatteOS": a store (search, tiles) of the servers the gateway
   `latte-mcp` runs on this computer. The list is `GET {url}/servers` with the master token (the file is read each time);
   each entry's `path` must stay under `/mcp/` on the gateway. The apps never receive a server's token. Choosing one
   makes an ordinary custom MCP connection at `{url}{path}` with that server's own token as the key (sealed like any),
   named as the server: it follows the usual flow (tool classification, every agent may use it until changed, per-agent
   assignment), an unforked client sees it in its MCP list, and the card lists the connections on the gateway's origin.
2. **The address guard.** Custom connectors name public https addresses only. One exception, exactly one origin: the
   origin of `LATTEOS_MCP_URL` (scheme, host and port) passes `assertPublicHttpsUrl` and is fetched directly; another port or
   host on the same computer is refused as before. Being a loopback address, these connectors are also the ones an
   anonymous project's chat may use (ADR 0201).
3. **Skills.** With `LATTEOS_SKILLS_DIR`, the Install skill dialog has a tab "Skill from LensAI": each folder with a
   SKILL.md (name and description from its frontmatter) with Install. Installing reads all the files of the folder on the
   server and saves them as the team's skill through `saveSkill`, the path an uploaded zip takes, with its sizes capped by
   the same limits; the folder's name is kept in the skill's metadata and a signature of its files (names, sizes,
   times) in `source_hash`, so the row says Installed and offers Update when the folder changed. Only who manages agents
   installs. A link or folder that resolves outside the skills folder (or, inside a skill, outside that skill) is never
   followed.

## Addendum: the gateway lists ToolHive's groups

LatteOS manages its MCP servers with ToolHive (Stacklok, Apache-2.0) instead of a store of its own. The gateway's `GET /servers`
now returns ToolHive's groups that hold servers (`what` names their servers), and `/mcp/{group}` reaches the group as one MCP
server (ToolHive's virtual MCP server, started on first use, with its tool search). The card's texts say "groups"; the API,
the connection and the per-agent assignment are unchanged.

Also each server alone (21. 11.): an agent that should have one server need not get a group. `GET /servers` lists every
ToolHive server that speaks streamable HTTP as well, id and path `one.<name>` (a dot is never in a ToolHive group's name),
forwarded to that server's own proxy with a token of its own. The add dialog is laid out as the Connectors catalog (kinds
beside the grid: All, Connected, Groups, Servers). The card no longer repeats what is connected: those are ordinary custom
connections, listed under MCP with their agents and Disconnect, and the card says so.

## Addendum: this computer's own models in Other provider (21. 11.)

With `LATTEOS_LOCAL_LLM_URL` (LatteOS's llama.cpp router, `http://127.0.0.1:8790/v1`), Connect AI › Other provider shows
"Use this computer's models": one click fills the name, the OpenAI style and the address and lists the models; the user
switches on those agents may use. The address comes in `GET …/latteos/mcp` as `localModels` (null when unset). An endpoint on
loopback has its models tested one after another with 120 s each (`onThisComputer` in endpoints.ts): run together, each test
made the router evict the model the previous one loaded and they all failed at 60 s, which is why local models could not be
given to agents. Bun's `idleTimeout` is 255 s (its most) so the saving request outlives a couple of such tests.
