#!/bin/sh
# ai-stack.sh USER: agentgram and ToolHive for USER (ROADMAP 10B.86, 10B.77), run by install as root when the component
# "Agentgram and ToolHive" was chosen, or by USER alone (what needs root is then said, not done). Everything is pinned:
# a program by its version and the sha256 of its release, agentgram by one commit of the user's fork (branch agent-chats).
#   bun 1.4.5            ~/.bun/bin/bun            runs and builds agentgram
#   thv-registry-api     ~/.local/bin              ToolHive's Registry Server (latte-toolhive-catalog starts it for a sync)
#   ToolHive Studio .rpm /usr (root)               its own thv comes with it (~/.toolhive/bin/thv); a second thv is refused
#   agentgram            ~/src/agentes-chat        built; ~/.local/share/agentgram = its data and env; user unit agentgram.service
#   podman.socket        user unit, enabled        what ToolHive runs MCP servers with
# Safe to run again: what is there as pinned is left; a stamp says the build matches the commit.
# To move to a newer one: change the version and the sha256 below (from the release's checksum file), or AG_COMMIT.
set -eu
user="${1:?usage: ai-stack.sh USER}"
home="$(getent passwd "$user" | cut -d: -f6)"
[ -n "$home" ] && [ -d "$home" ] || { echo "ai-stack: no home for $user" >&2; exit 1; }

BUN_VERSION=1.4.5;      BUN_SHA=94559b3b528995a49452f9f2404cec74f2efd7d06e0a000a8cd214b02c3666eb
REG_VERSION=1.5.4;      REG_SHA=81337595fa34d15aa99eed0313ccc79035ebde42e6a1deb855b2ad6c66b0b053
STUDIO_VERSION=0.41.0;  STUDIO_SHA=85069b2bccaa6d91aaab6f63893e3d46f92587a0f82466e9bc128e4ee12e5bc6      # GitHub's digest of the asset
AG_REPO=https://github.com/arkaysk/LatteOS-v0x-Jihlavanka.git
AG_COMMIT=df4d0b915f47163d6f064d0d9d293e69249e9ebd              # branch agent-chats, 22. 11. 2026

am_root=0; [ "$(id -u)" = 0 ] && am_root=1
say() { printf 'ai-stack: %s\n' "$*"; }
# bun starts bun again (its scripts), so ~/.bun/bin is in the PATH of everything run as the user
as_user() { if [ "$am_root" = 1 ]; then runuser -u "$user" -- env HOME="$home" PATH="$home/.bun/bin:$home/.local/bin:/usr/local/bin:/usr/bin:/bin" "$@"; else env PATH="$home/.bun/bin:$home/.local/bin:$PATH" "$@"; fi; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
chmod 755 "$tmp"

# fetch URL SHA256 FILE: a download counts only when its sha256 is the pinned one
fetch() {
    curl -fsSL --retry 3 --max-time 600 -o "$3" "$1"
    [ "$(sha256sum "$3" | cut -d' ' -f1)" = "$2" ] || { echo "ai-stack: $1 is not the release this installer was made for (sha256)" >&2; exit 1; }
}

# ── bun ─────────────────────────────────────────────────────────────────────────────────────────────────────────
bun="$home/.bun/bin/bun"
if [ "$(as_user "$bun" --version 2>/dev/null || true)" != "$BUN_VERSION" ]; then
    say "bun $BUN_VERSION"
    fetch "https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64.zip" "$BUN_SHA" "$tmp/bun.zip"
    python3 -I -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extract("bun-linux-x64/bun", sys.argv[2])' "$tmp/bun.zip" "$tmp/bun-x"
    as_user mkdir -p "$home/.bun/bin"
    install -m 755 -o "$user" "$tmp/bun-x/bun-linux-x64/bun" "$bun"
fi

# ── ToolHive's Registry Server ──────────────────────────────────────────────────────────────────────────────────
reg="$home/.local/bin/thv-registry-api"
if ! as_user "$reg" version 2>&1 | grep -q "\"v$REG_VERSION\""; then
    say "thv-registry-api $REG_VERSION"
    fetch "https://github.com/stacklok/toolhive-registry-server/releases/download/v$REG_VERSION/toolhive-registry-server_${REG_VERSION}_linux_amd64.tar.gz" "$REG_SHA" "$tmp/reg.tgz"
    mkdir "$tmp/reg-x"; tar -xzf "$tmp/reg.tgz" -C "$tmp/reg-x" thv-registry-api
    as_user mkdir -p "$home/.local/bin"
    install -m 755 -o "$user" "$tmp/reg-x/thv-registry-api" "$reg"
fi

# ── ToolHive Studio (root: dnf) ─────────────────────────────────────────────────────────────────────────────────
if rpm -q ToolHive 2>/dev/null | grep -q "ToolHive-$STUDIO_VERSION"; then
    :
elif [ "$am_root" = 1 ]; then
    say "ToolHive Studio $STUDIO_VERSION"
    fetch "https://github.com/stacklok/toolhive-studio/releases/download/v$STUDIO_VERSION/ToolHive-$STUDIO_VERSION-1.x86_64.rpm" "$STUDIO_SHA" "$tmp/ToolHive.rpm"
    dnf install -y "$tmp/ToolHive.rpm"
else
    say "ToolHive Studio $STUDIO_VERSION needs root: sudo dnf install the rpm of github.com/stacklok/toolhive-studio/releases/tag/v$STUDIO_VERSION (sha256 $STUDIO_SHA)"
fi

# ── agentgram: the user's fork, one commit, built ───────────────────────────────────────────────────────────────
src="$home/src/agentes-chat"
if [ ! -d "$src/.git" ]; then
    say "agentgram: fetching $AG_COMMIT"
    as_user mkdir -p "$src"
    as_user git -C "$src" init -q
    as_user git -C "$src" remote add origin "$AG_REPO"
fi
if [ "$(as_user git -C "$src" rev-parse HEAD 2>/dev/null || true)" != "$AG_COMMIT" ]; then
    if [ -n "$(as_user git -C "$src" status --porcelain 2>/dev/null || true)" ]; then
        say "agentgram: $src has changes of its own: left as it is (the pinned commit is $AG_COMMIT)"
    else
        as_user git -C "$src" fetch -q --depth 1 origin "$AG_COMMIT"
        as_user git -C "$src" checkout -q -f FETCH_HEAD
    fi
fi
stamp="$src/.built-$(as_user git -C "$src" rev-parse HEAD 2>/dev/null || echo none)"
if [ ! -e "$stamp" ] && [ -d "$src/apps" ]; then
    say "agentgram: bun install and build (a few minutes, ~2.2 GB of node_modules)"
    as_user sh -c 'cd "$1" && "$2" install --frozen-lockfile && "$2" run build' sh "$src" "$bun"
    as_user touch "$stamp"
fi

# ── its data, its settings, its unit; podman's socket ──────────────────────────────────────────────────────────
data="$home/.local/share/agentgram"
as_user mkdir -p "$data/files" "$home/LensAI/agentgram" "$home/.agents/skills" "$home/.config/systemd/user"
as_user chmod 700 "$data"
if [ ! -e "$data/env" ]; then
    secret="$(head -c 48 /dev/urandom | base64 | tr -d '=+/\n')"
    as_user sh -c 'umask 077; cat > "$1/env"' sh "$data" <<ENV
AGENTES_SECRET=$secret
PORT=5173
HOST=127.0.0.1
PUBLIC_URL=http://localhost:5173
NODE_ENV=production
INSTALL_MODE=native
TELEMETRY=off
DATABASE_URL=pglite://$data/db
FILES_DIR=$data/files
WEB_DIR=$src/apps/web/dist
LATTEOS_MCP_URL=http://127.0.0.1:8791/mcp
LATTEOS_MCP_TOKEN_FILE=$home/.config/latteos/mcp-token
LATTEOS_LOCAL_LLM_URL=http://127.0.0.1:8790/v1
LATTEOS_SKILLS_DIR=$home/.agents/skills
LATTEOS_PROJECTS_DIR=$home/LensAI/agentgram
ENV
fi
unit="$home/.config/systemd/user/agentgram.service"
as_user sh -c 'cat > "$1"' sh "$unit" <<'UNIT'
[Unit]
Description=agentgram, LatteOS's fork of agentes.chat (the server, with its database built in)
After=network-online.target

[Service]
WorkingDirectory=%h/src/agentes-chat
EnvironmentFile=%h/.local/share/agentgram/env
ExecStart=%h/.bun/bin/bun apps/server/src/main.ts
Restart=on-failure
RestartSec=5
MemoryHigh=4G
MemoryMax=6G

[Install]
WantedBy=default.target
UNIT

# a user unit turned on: through the user's systemd when it is there, else the link it would make (the user may not have logged in yet)
enable() {   # enable WANTS_DIR UNIT_FILE
    if [ "$am_root" = 0 ] && systemctl --user is-system-running >/dev/null 2>&1; then
        systemctl --user enable "$(basename "$2")" >/dev/null 2>&1 && return 0
    fi
    as_user mkdir -p "$home/.config/systemd/user/$1"
    as_user ln -sfn "$2" "$home/.config/systemd/user/$1/$(basename "$2")"
}
enable default.target.wants "$unit"
enable sockets.target.wants /usr/lib/systemd/user/podman.socket
enable timers.target.wants /usr/lib/systemd/user/latte-toolhive-catalog.timer
say "done: agentgram http://localhost:5173 (its unit starts at the next login), ToolHive after its Studio is opened once"
