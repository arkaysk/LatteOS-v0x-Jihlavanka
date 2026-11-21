#!/usr/bin/env python3
"""latte-mcp's HTTP door (engineering audit 2, 13; security S12): the master token and a group's token are needed, a name
nobody listed gets 401 and no token is made for it, an empty "Bearer " is refused; the caller of a lazy call is the
request's own (GPT's review). Runs latte-mcp on a free port with its own config folder.
Run: python3 tests/test_mcp.py"""
import asyncio, importlib.machinery, importlib.util, json, os, socket, subprocess, sys, tempfile, time, urllib.error, urllib.request

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIN = os.path.join(ROOT, "bin", "latte-mcp")
loader = importlib.machinery.SourceFileLoader("latte_mcp", BIN)
mcp = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(mcp)

# the caller is one per request: two at once never see each other's
async def one(name, out):
    t = mcp.CALLER.set(name)
    await asyncio.sleep(0.01)
    out.append((name, mcp.CALLER.get()))
    mcp.CALLER.reset(t)
got = []
async def both():
    await asyncio.gather(one("A", got), one("B", got))
asyncio.run(both())
assert sorted(got) == [("A", "A"), ("B", "B")], got

with tempfile.TemporaryDirectory() as d:
    mcp.TOKENS = os.path.join(d, "mcp-groups.json")
    assert mcp.group_tokens(["x"], make=False) == {} and not os.path.exists(mcp.TOKENS)      # a check makes nothing
    made = mcp.group_tokens(["design"])["design"]
    assert len(made) > 20 and mcp.group_tokens(["design"], make=False)["design"] == made

    try:
        import uvicorn, mcp as _sdk  # noqa: F401  the server's own modules; without them the door cannot be tried
    except ImportError:
        print("latte-mcp: ok (HTTP not tried: uvicorn or the MCP SDK is missing)")
        sys.exit(0)
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    env = dict(os.environ, XDG_CONFIG_HOME=d, HOME=d)
    os.makedirs(os.path.join(d, "latteos"), exist_ok=True)
    with open(os.path.join(d, "latteos", "mcp-groups.json"), "w") as f:
        json.dump({"design": made}, f)
    p = subprocess.Popen([sys.executable, BIN, "http", str(port)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        def code(path, auth=None):
            req = urllib.request.Request("http://127.0.0.1:%d%s" % (port, path), headers={"Authorization": auth} if auth else {})
            try:
                return urllib.request.urlopen(req, timeout=5).status
            except urllib.error.HTTPError as e:
                return e.code
        for _ in range(60):
            try:
                code("/servers")
                break
            except OSError:
                time.sleep(0.25)
        master = open(os.path.join(d, "latteos", "mcp-token")).read().strip()
        assert code("/servers") == 401 and code("/servers", "Bearer ") == 401 and code("/servers", "Bearer wrong") == 401
        assert code("/servers", "Bearer " + master) == 200
        assert code("/mcp/nobody", "Bearer ") == 401 and code("/mcp/nobody", "Bearer x") == 401
        assert "nobody" not in json.load(open(os.path.join(d, "latteos", "mcp-groups.json")))      # nothing made for it
        assert code("/mcp/design", "Bearer wrong") == 401
        assert code("/mcp/one.x", "Bearer ") == 401
    finally:
        p.terminate()
        p.wait(5)
print("latte-mcp: ok")
