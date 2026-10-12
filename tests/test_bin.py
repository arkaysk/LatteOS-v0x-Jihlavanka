#!/usr/bin/env python3
"""Checks of the commands in bin/ that need no system around them. Run: python3 tests/test_bin.py"""
import contextlib, importlib.machinery, importlib.util, io, json, os, socket, struct, sys, tempfile, threading

sys.dont_write_bytecode = True          # bin/ holds commands, not a place for __pycache__

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(name):
    loader = importlib.machinery.SourceFileLoader(name.replace("-", "_"), os.path.join(ROOT, "bin", name))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
    loader.exec_module(module)
    return module


sky = load("latte-sky")
# 20 March 2025 12:00 UTC, the equinox: over the equator at Greenwich the sun is nearly overhead and mid-way.
s = sky.sky(0, 0, 1742472000)["sun"]
assert s["alt"] > 85 and abs(s["t"] - 0.5) < 0.03, s
# The same moment on the other side of the Earth is night.
assert sky.sky(0, 180, 1742472000)["sun"]["t"] == -1
# 29 March 2025 was a new moon, 12 April 2025 a full one.
assert sky.sky(48, 19, 1743246000)["moon"]["lit"] < 0.03
assert sky.sky(48, 19, 1744503600)["moon"]["lit"] > 0.97
assert sky.kind(0) == (1, "sun") and sky.kind(61)[0] == 5 and sky.kind(73)[0] == 6 and sky.kind(96)[0] == 7
r = sky.report({"lat": "48.74", "lon": "19.15", "place": "Here, There"},
               {"now": {"temp": 3, "code": 3}, "wind": 9, "hours": [{"time": "15:00", "temp": 2, "code": 71}], "days": []})
assert (r["rain"], r["snow"], r["place"], r["now"]["icon"]) == (1, True, "Here", "cloud"), r
assert sky.report({}, {})["now"] is None            # no place set: no sky, no weather, no error

login = load("latte-login")
with tempfile.TemporaryDirectory() as d:
    login.STATE = login.SESSIONS = d
    open(os.path.join(d, "login.conf"), "w").write('# a comment\npanel = "none"\nnews_url = "http://x/y"\n')
    assert login.conf() == {"panel": "none", "news_url": "http://x/y"}
    for name, body in (("latteos", "Name=LatteOS GOO\nName[sk]=Goo po slovensky\nExec=/usr/bin/latte-session %U\n"),
                       ("latteos-safe", "Name=LatteOS SAFE\nExec=/usr/bin/latte-session safe\n"),
                       ("latteos-hidden", "Name=X\nExec=x\nNoDisplay=true\n"), ("other", "Name=Other\nExec=other\n")):
        open(os.path.join(d, name + ".desktop"), "w").write("[Desktop Entry]\n" + body)
    found = login.sessions("sk_SK")
    assert [s["file"] for s in found] == ["latteos", "latteos-safe"], found
    assert found[0]["name"] == "Goo po slovensky" and found[0]["cmd"] == ["/usr/bin/latte-session"]
    json.dump({"power_x": 0.2, "coffee": "latte"}, open(os.path.join(d, "user-ann.json"), "w"))
    assert login.hint("ann")["power_x"] == 0.2 and login.hint("../etc/passwd") == {}
with contextlib.redirect_stderr(io.StringIO()):
    assert login.main(["nonsense"]) == 2


def fake_greetd(path, right_password, seen):
    """greetd as far as a login goes: asks for a secret, accepts the right one, starts the session."""
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(path)
    server.listen(1)

    def serve():
        conn, _ = server.accept()
        with conn:
            while True:
                head = conn.recv(4)
                if len(head) < 4:
                    return
                msg = json.loads(conn.recv(struct.unpack("=I", head)[0]))
                seen.append(msg)
                if msg["type"] == "create_session":
                    answer = {"type": "auth_message", "auth_message_type": "secret", "auth_message": "Password:"}
                elif msg["type"] == "post_auth_message_response":
                    answer = {"type": "success"} if msg["response"] == right_password else {"type": "error", "error_type": "auth_error", "description": "no"}
                else:
                    answer = {"type": "success"}
                raw = json.dumps(answer).encode()
                conn.sendall(struct.pack("=I", len(raw)) + raw)

    threading.Thread(target=serve, daemon=True).start()


def try_auth(password):
    with tempfile.TemporaryDirectory() as d:
        seen = []
        os.environ["GREETD_SOCK"] = os.path.join(d, "sock")
        fake_greetd(os.environ["GREETD_SOCK"], "right horse", seen)
        login.GREETD = d
        out, stdin = io.StringIO(), sys.stdin
        sys.stdin = io.StringIO(password + "\n")
        try:
            with contextlib.redirect_stdout(out):
                code = login.main(["auth", "ann", "latteos", "--", "/usr/bin/latte-session", "safe"])
        finally:
            sys.stdin = stdin
        return code, json.loads(out.getvalue()), seen, os.path.exists(os.path.join(d, "latte-last-user"))


code, answer, seen, remembered = try_auth("right horse")
assert code == 0 and answer == {"ok": True, "error": ""} and remembered, answer
assert seen[0] == {"type": "create_session", "username": "ann"}
assert seen[-1]["type"] == "start_session" and seen[-1]["cmd"] == ["/usr/bin/latte-session", "safe"], seen[-1]
code, answer, seen, remembered = try_auth("wrong")
assert code == 1 and answer["error"] == "auth" and not remembered, answer
assert seen[-1]["type"] == "cancel_session"             # a refused login leaves nothing half-open in greetd
print("bin: ok")
