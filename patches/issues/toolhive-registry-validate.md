# stacklok/toolhive: a registry API of ~1 000 servers is refused as "not reachable"

*Draft for the authors — not sent (send only when the user says so).*

**Version:** thv v0.64.0 (ToolHive Desktop 0.41.0) and `main` of 20 Nov 2026.

**What happens:** `thv config set-registry --allow-private-ip http://127.0.0.1:8794/registry/default` (a ToolHive Registry
Server 1.5.4 joining ToolHive's catalog and GitHub's MCP registry, 1 005 servers) is accepted, but every later command fails:

```
custom registry API at http://127.0.0.1:8794/registry/default is not reachable: ... failed to fetch servers:
Get ".../v0.1/servers?cursor=...&limit=1&version=latest": context deadline exceeded
```

The same with `https://registry.modelcontextprotocol.io`.

**Why:** `NewAPIRegistryProvider` checks the API with `client.ListServers(ctx, &api.ListOptions{Limit: 1})`
(`pkg/registry/provider_api.go`), but `ListServers` follows `nextCursor` to the end, so the check makes one request per
server (1 005 requests, ~10.7 ms each locally) and runs out of its 10 s.

**Suggestion:** let the check read one page only (a `MaxPages`/single-page option, or a plain GET of the first page).

**Workaround we use:** the Registry Server's list written to a local file in the upstream format, `thv config set-registry
<file>` (reads in 0.3 s).
