#!/usr/bin/env python3
"""The agents of the ACP Registry in latte-ai (ROADMAP 10B.87), without the network: a registry of the registry's own
format, a binary installed from an archive checked against its sha256, an npm package by a stand-in npm, removed.
Run: python3 tests/test_acp.py"""
import contextlib, hashlib, importlib.machinery, importlib.util, io, json, os, stat, sys, tarfile, tempfile

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("latte_ai", os.path.join(ROOT, "bin", "latte-ai"))
ai = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(ai)


def tarball(members):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as t:
        for name, data in members:
            i = tarfile.TarInfo(name)
            i.size, i.mode = len(data), 0o755
            t.addfile(i, io.BytesIO(data))
    return buf.getvalue()


good = tarball([("agent/run", b"#!/bin/sh\necho hi\n")])
evil = tarball([("../evil", b"x")])
plat = ai.acp_platform()
assert plat in ("linux-x86_64", "linux-aarch64"), plat


def binary(url, data, sha=None):
    return {"binary": {plat: {"archive": url, "cmd": "./agent/run", "args": ["acp"], "env": {"A": "1"},
                              "sha256": hashlib.sha256(data).hexdigest() if sha is None else sha}}}


registry = {"version": "1.0.0", "extensions": [], "agents": [
    {"id": "bin-agent", "name": "Bin", "version": "1.0", "description": "d", "license": "MIT", "icon": "", "distribution": binary("https://x.invalid/a.tar.gz", good)},
    {"id": "bad-sum", "name": "Bad", "version": "1", "distribution": binary("https://x.invalid/a.tar.gz", good, "0" * 64)},
    {"id": "evil", "name": "Evil", "version": "1", "distribution": binary("https://x.invalid/e.tar.gz", evil)},
    {"id": "npm-agent", "name": "Npm", "version": "2.0", "distribution": {"npx": {"package": "@s/npm-agent@2.0", "args": ["--acp"]}}},
    {"id": "py-agent", "name": "Py", "version": "3", "distribution": {"uvx": {"package": "py-agent==3"}}},
    {"id": "mac-only", "name": "Mac", "version": "1", "distribution": {"binary": {"darwin-aarch64": {"archive": "https://x.invalid/m.zip", "cmd": "./m"}}}},
    {"id": "../escape", "name": "No", "version": "1", "distribution": {"npx": {"package": "x"}}}]}

with tempfile.TemporaryDirectory() as d:
    ai.ACP_CACHE, ai.ACP_HOME = os.path.join(d, "cache"), os.path.join(d, "home")
    os.makedirs(ai.ACP_CACHE)
    json.dump(registry, open(os.path.join(ai.ACP_CACHE, "registry.json"), "w"))      # fresh: nothing is fetched
    served = {"https://x.invalid/a.tar.gz": good, "https://x.invalid/e.tar.gz": evil}
    ai.acp_get = lambda url, timeout=30: io.BytesIO(served[url])
    # a stand-in npm: it puts the package where npm would, with its bin; node is there too
    tools = os.path.join(d, "bin")
    os.makedirs(tools)
    open(os.path.join(tools, "npm"), "w").write('#!/bin/sh\nwhile [ "$1" != --prefix ]; do shift; done\np="$2/node_modules/@s/npm-agent"\n'
                                                'mkdir -p "$p/dist" && echo \'{"bin": {"npm-agent": "dist/index.js"}}\' > "$p/package.json" && : > "$p/dist/index.js"\n')
    open(os.path.join(tools, "node"), "w").write("#!/bin/sh\n")
    for t in ("npm", "node"):
        os.chmod(os.path.join(tools, t), 0o755)
    ai.SEARCH = tools + os.pathsep + "/usr/bin:/bin"

    # parsing: the registry's own fields, the kind for this computer, ids that are not folder names left out
    rows = {r["id"]: r for r in ai.acp_list()}
    assert "../escape" not in rows and len(rows) == 6, rows.keys()
    assert (rows["bin-agent"]["kind"], rows["npm-agent"]["kind"], rows["py-agent"]["kind"], rows["mac-only"]["kind"]) == ("binary", "npx", "uvx", "")
    assert rows["npm-agent"]["needs"] == ["node", "npm"] and rows["npm-agent"]["missing"] == [] and rows["bin-agent"]["needs"] == []
    assert rows["bin-agent"]["installed"] == "" and rows["bin-agent"]["doer"] == "acp:bin-agent" and not rows["bin-agent"]["usable"]
    assert ai.acp_install("mac-only") and ai.acp_install("nobody") and not os.path.exists(os.path.join(ai.ACP_HOME, "mac-only"))

    # a binary: checked, unpacked, its command executable; agent.json tells how it starts
    assert ai.acp_install("bin-agent") == "", ai.acp_install("bin-agent")
    have = ai.acp_installed()
    assert list(have) == ["bin-agent"] and have["bin-agent"]["version"] == "1.0", have
    run = os.path.join(ai.ACP_HOME, "bin-agent", "agent", "run")
    assert have["bin-agent"]["argv"] == [run, "acp"] and os.stat(run).st_mode & stat.S_IXUSR
    assert ai.acp_argv("acp:bin-agent") == ([run, "acp"], {"A": "1"})
    assert not os.path.exists(os.path.join(ai.ACP_HOME, "bin-agent", ".download"))
    assert "acp:bin-agent" in ai.doers() and ai.doer_name("acp:bin-agent") == "Bin"
    assert {r["id"]: r for r in ai.acp_list()}["bin-agent"]["installed"] == "1.0"

    # a download that is not what the registry says, or an archive reaching outside its folder: nothing is left
    assert "sha256" in ai.acp_install("bad-sum") and not os.path.exists(os.path.join(ai.ACP_HOME, "bad-sum"))
    assert ai.acp_install("evil") and not os.path.exists(os.path.join(ai.ACP_HOME, "evil")) and not os.path.exists(os.path.join(d, "evil"))

    # an npm package: started with node, its command from package.json (Zed's read_package_executable)
    assert ai.acp_install("npm-agent") == ""
    m = ai.acp_installed()["npm-agent"]
    assert m["argv"] == ["node", os.path.join(os.path.realpath(ai.ACP_HOME), "npm-agent", "node_modules", "@s", "npm-agent", "dist", "index.js"), "--acp"], m

    # removed: its folder gone, the others stay; what is not there, or not an id, is not removed
    assert ai.acp_remove("bin-agent") and not os.path.exists(os.path.join(ai.ACP_HOME, "bin-agent"))
    assert list(ai.acp_installed()) == ["npm-agent"] and "acp:bin-agent" not in ai.doers()
    assert not ai.acp_remove("bin-agent") and not ai.acp_remove("..") and not ai.acp_remove("../home")
    with contextlib.redirect_stdout(io.StringIO()) as said:
        assert ai.main(["acp", "remove", "nobody"]) == 1 and ai.main(["acp", "install", "../x"]) == 1
    assert json.loads(said.getvalue().splitlines()[0]) == {"ok": False, "error": "not installed"}
print("acp: ok")
