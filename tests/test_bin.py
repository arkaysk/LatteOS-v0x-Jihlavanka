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
    # the session's note for the login screen: where the power drop is, and the user's coffee
    login.CONFIG = os.path.join(d, "config")
    os.makedirs(login.CONFIG)
    open(os.path.join(login.CONFIG, "coffee"), "w").write("flatwhite\n")
    assert login.remember(0.31) == 0 and login.hint(login.who()) == {"coffee": "flatwhite", "power_x": 0.31}
    assert login.remember(7) == 0 and "power_x" not in login.hint(login.who())      # not on the bottom edge: no place
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        assert login.main(["coffee"]) == 0
    assert json.loads(out.getvalue()) == [0.05, 0.5]
    with contextlib.redirect_stdout(io.StringIO()):
        assert login.main(["coffee", "latte"]) == 0 and login.own_coffee() == "latte"
        assert login.main(["coffee", "tea"]) == 2 and login.own_coffee() == "latte"
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

cal = load("latte-cal")
dt = cal.dt
ICS = """BEGIN:VCALENDAR\r
BEGIN:VEVENT\r
DTSTART:20250305T093000\r
SUMMARY:Meeting\\, the long\r
  one\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART;VALUE=DATE:20250310\r
DTEND;VALUE=DATE:20250312\r
SUMMARY:Trip\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART:20250303T180000\r
RRULE:FREQ=WEEKLY;BYDAY=MO,TH;COUNT=4\r
EXDATE:20250306T180000\r
SUMMARY:Training\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART;VALUE=DATE:20240131\r
RRULE:FREQ=MONTHLY\r
SUMMARY:Rent\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART:20250320T100000\r
STATUS:CANCELLED\r
SUMMARY:Gone\r
END:VEVENT\r
END:VCALENDAR\r
"""
got = cal.events(ICS, dt.datetime(2025, 3, 1), dt.datetime(2025, 3, 31, 23, 59))
have = sorted((e["date"], e["time"], e["title"]) for e in got)
assert have == [("2025-03-03", "18:00", "Training"), ("2025-03-05", "09:30", "Meeting, the long one"),
                ("2025-03-10", "", "Trip"), ("2025-03-10", "18:00", "Training"), ("2025-03-11", "", "Trip"),
                ("2025-03-13", "18:00", "Training"), ("2025-03-31", "", "Rent")], have
# a time in another zone is told in this one: 12:00 UTC is the same moment everywhere
t, whole = cal.when("", "20250305T120000Z")
assert not whole and t == dt.datetime(2025, 3, 5, 12, tzinfo=dt.timezone.utc).astimezone().replace(tzinfo=None)
assert cal.times(dt.datetime(2025, 1, 1), "FREQ=DAILY", dt.datetime(2026, 1, 1), dt.datetime(2026, 1, 3)) == [
    dt.datetime(2026, 1, 1), dt.datetime(2026, 1, 2), dt.datetime(2026, 1, 3)]
ai = load("latte-ai")
assert ai.as_prompt([{"role": "user", "content": "Hi"}]) == "Hi" and ai.as_prompt([]) == ""
p = ai.as_prompt([{"role": "user", "content": "A"}, {"role": "assistant", "content": "B"}, {"role": "user", "content": "C"}])
assert "User: A\nAssistant: B" in p and p.endswith("C"), p
assert ai.claude("q")[:3] == ["claude", "-p", "q"] and ai.claude("q")[-2:] == ["--tools", ""]      # the question first: --tools takes all that follows
apps = load("latte-apps")
with tempfile.TemporaryDirectory() as d:
    f = os.path.join(d, "org.example.App.desktop")
    open(f, "w").write("[Desktop Entry]\nType=Application\nName=App\nName[sk]=Aplikacia\nComment=Does things\nIcon=org.example.App\nX-Flatpak=org.example.App\n")
    e = apps.entry(f, "sk")
    assert (e["id"], e["name"], e["summary"], e["flatpak"]) == ("org.example.App", "Aplikacia", "Does things", "org.example.App"), e
    open(f, "w").write("[Desktop Entry]\nName=Hidden\nNoDisplay=true\n")
    assert apps.entry(f) is None and apps.entry(os.path.join(d, "none.desktop")) is None
assert apps.plain("<p>One &amp; two</p><ul><li>a</li><li>b</li></ul>") == "One & two\n\n• a\n• b"
hit = {"app_id": "org.a.B", "name": "B", "summary": "s", "icon": "i", "verification_verified": True, "installs_last_month": 5, "type": "desktop-application"}
assert apps.cards({"hits": [hit, dict(hit, type="addon")]}, {"org.a.B"}) == [
    {"id": "org.a.B", "name": "B", "summary": "s", "icon": "i", "developer": "", "verified": True, "installs": 5, "installed": True}]
assert apps.shots({"screenshots": [{"sizes": [{"src": "small", "width": "300"}, {"src": "right", "width": "752"}, {"src": "big", "width": "1600"}]}]}) == ["right"]
devices = load("latte-devices")
blob = bytearray(128)
blob[:8] = b"\x00\xff\xff\xff\xff\xff\xff\x00"
blob[21], blob[22] = 53, 30                                    # cm across and down
blob[54:72] = bytes([0x02, 0x3A, 0x80, 0x18, 0x71, 0x38, 0x2D, 0x40]) + bytes(10)      # 148.5 MHz, 1920+280 × 1080+45
blob[72:90] = b"\x00\x00\x00\xfc\x00" + b"Test Screen\n "
assert devices.edid(bytes(blob)) == ("Test Screen", "1920×1080", 60, 24), devices.edid(bytes(blob))
assert devices.edid(b"junk") == ("", "", 0, 0)
assert devices.device("  A   B ", "x")["name"] == "A B"
monitor = load("latte-monitor")
assert monitor.cores("cpu  1 2 3 4 5 6 7 8\ncpu0 10 0 10 70 10 0 0 0 0 0\ncpu1 5 0 5 80 10 0 0 0\nintr 1") == [(100, 80), (100, 90)]
assert monitor.origin(monitor.HOME + "/.config/systemd/user/x.service") == "yours" and monitor.origin("/usr/lib/systemd/user/latte-goo.service") == "LatteOS"
with tempfile.TemporaryDirectory() as d:
    mine, theirs = os.path.join(d, "mine"), os.path.join(d, "theirs")
    os.makedirs(theirs)
    monitor.AUTOSTART = [mine, theirs]
    open(os.path.join(theirs, "a.desktop"), "w").write("[Desktop Entry]\nName=A\nExec=a\n")
    assert monitor.startup_set("app:a.desktop", False) == 0 and "Hidden=true" in open(os.path.join(mine, "a.desktop")).read()
    assert monitor.startup_set("app:a.desktop", True) == 0 and not os.path.exists(os.path.join(mine, "a.desktop"))     # back as it was
    assert monitor.startup_set("app:../x.desktop", False) == 2 and monitor.startup_set("system:x.service", False) == 2
network = load("latte-network")
packet = b"\x00" * 12 + b"\x03foo\x05local\x00" + b"\x03bar\xc0\x0c"
assert network.name_at(packet, 12) == ("foo.local", 23) and network.name_at(packet, 23) == ("bar.foo.local", 29)
assert network.maker("a2:00:00:00:00:01") == ""                    # an address a phone made up names nobody
assert network.kind_of({"printer", "pc"}, "", "") == "printer" and network.kind_of(set(), "Espressif Inc.", "") == "home" and network.kind_of(set(), "", "") == "device"
print("bin: ok")
