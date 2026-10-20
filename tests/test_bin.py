#!/usr/bin/env python3
"""Checks of the commands in bin/ that need no system around them. Run: python3 tests/test_bin.py"""
import contextlib, importlib.machinery, importlib.util, io, json, os, shutil, socket, struct, sys, tempfile, threading

sys.dont_write_bytecode = True          # bin/ holds commands, not a place for __pycache__

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(name, folder="bin"):
    loader = importlib.machinery.SourceFileLoader(name.replace("-", "_"), os.path.join(ROOT, folder, name))
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
assert ai.claude("q", "haiku")[:3] == ["claude", "-p", "q"] and ai.claude("q", "haiku")[-2:] == ["--tools", ""]      # the question first: --tools takes all that follows
with tempfile.TemporaryDirectory() as d:
    config, os.environ["XDG_CONFIG_HOME"] = os.environ.get("XDG_CONFIG_HOME"), d
    os.makedirs(os.path.join(d, "latteos"))
    ai.PROVIDERS = {"sh": {"name": "Shell", "local": True, "style": "own", "tool": "sh", "models": [{"id": "m", "name": "M"}],
                           "command": lambda prompt, model: ["sh", "-c", "echo answer from $0", model]}}
    assert not ai.turned_off() and len(ai.providers()) == 1
    open(os.path.join(d, "latteos", "ai"), "w").write("off\n")
    assert ai.turned_off() and ai.providers() == [] and len(ai.providers(True)) == 1            # turned off, it is still there to be turned on
    os.environ.pop("XDG_CONFIG_HOME") if config is None else os.environ.__setitem__("XDG_CONFIG_HOME", config)
    # a conversation is kept: its question and answer, and it goes on under the same id
    ai.CHATS, ai.ROOM = os.path.join(d, "chats"), d
    r = ai.send("new", "sh", "m", "Hello there")
    assert r["ok"] and r["answer"] == "answer from m", r
    assert ai.send(r["chat"], "sh", "m", "Again")["chat"] == r["chat"]
    c = ai.load(r["chat"])
    assert [m["role"] for m in c["messages"]] == ["user", "assistant", "user", "assistant"] and c["title"] == "Hello there", c
    assert [x["id"] for x in ai.chats()] == [r["chat"]] and not ai.send("new", "nobody", "m", "x")["ok"]
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
settings = load("latte-settings")
with tempfile.TemporaryDirectory() as d:
    home, os.environ["HOME"] = os.environ.get("HOME"), d
    os.makedirs(os.path.join(d, ".local/share/applications"))
    for name, more in (("zz-test-view", "MimeType=image/png;x-test/thing;\n"), ("zz-test-hidden", "MimeType=x-test/thing;\nNoDisplay=true\n"), ("zz-test-plain", "")):
        open(os.path.join(d, ".local/share/applications", name + ".desktop"), "w").write("[Desktop Entry]\nName=View\nIcon=view\nExec=view\n" + more)
    found = settings.launchers()
    os.environ["HOME"] = home
    assert found["zz-test-view.desktop"] == ("View", "view", {"image/png", "x-test/thing"}), found.get("zz-test-view.desktop")
    assert "zz-test-hidden.desktop" not in found and "zz-test-plain.desktop" not in found
    settings.CONFIG, said = os.path.join(d, "config"), []
    settings.layouts = lambda: [{"id": i, "name": i} for i in ("us", "sk", "sk:qwerty")]
    settings.out = lambda *argv, **env: said.append(argv) or ""
    assert settings.set_keyboard(["sk:qwerty", "us"]) == 0 and "kb_variant = \"qwerty,\"" in said[-1][-1]
    assert settings.kept("keyboard") == {"XKB_DEFAULT_LAYOUT": "sk,us", "XKB_DEFAULT_VARIANT": "qwerty,", "XKB_DEFAULT_OPTIONS": "grp:alt_shift_toggle"}
    assert settings.set_keyboard(["us"]) == 0 and settings.kept("keyboard")["XKB_DEFAULT_OPTIONS"] == ""       # one layout: nothing to switch to
    assert settings.set_keyboard(["us", "us"]) == 2 and settings.set_keyboard([]) == 2 and settings.set_keyboard(['us";os.exit()--']) == 2 and len(said) == 2
    settings.out = lambda *argv, **env: "Filesystem Type 1B-blocks Used Mounted on\n/dev/sda3 btrfs 1000 400 /\n/dev/sda3 btrfs 1000 400 /home\n/dev/sda1 vfat 10 1 /boot/efi\n/dev/sdb1 ext4 500 5 /run/media/me/My disk\n"
    assert settings.storage()["disks"] == [{"mount": "/", "device": "/dev/sda3", "kind": "btrfs", "size": 1000, "used": 400},
                                           {"mount": "/run/media/me/My disk", "device": "/dev/sdb1", "kind": "ext4", "size": 500, "used": 5}]
    settings.region = lambda: {"locales": [{"id": "sk_SK.UTF-8"}, {"id": "en_GB.UTF-8"}]}
    assert settings.set_locale("xx_XX.UTF-8", "") == 2 and settings.set_locale("sk_SK.UTF-8", "$(reboot)") == 2 and not os.path.exists(os.path.join(settings.CONFIG, "locale"))
    assert settings.set_locale("en_GB.UTF-8", "sk_SK.UTF-8") == 0 and settings.kept("locale")["LC_PAPER"] == "sk_SK.UTF-8"
    assert settings.set_locale("sk_SK.UTF-8", "sk_SK.UTF-8") == 0 and settings.kept("locale") == {"LANG": "sk_SK.UTF-8"}
with contextlib.redirect_stdout(io.StringIO()):
    assert settings.main(["default", "nonsense", "a.desktop"]) == 2 and settings.main(["default", "browser", "../a.desktop"]) == 2      # nothing is run for these
net = load("latte-net")
mine = net.MINE
assert net.own(mine + "app.slice/app-flatpak-org.x.Y-123.scope") and net.own(mine + "app.slice/app-latte-net-9.scope")
assert not net.own(mine + "app.slice/latte-goo.service") and not net.own("user.slice/user-%d.slice/session-4.scope" % net.UID)      # many apps share these
assert not net.own("user.slice/user-0.slice/user@0.service/app.slice/app-x-1.scope") or net.UID == 0
assert os.getpid() in net.family(os.getppid()) and net.family(os.getpid()) == [os.getpid()]
netd = load("latte-netd", "system/libexec")
ok = "user.slice/user-1000.slice/user@1000.service/app.slice/app-latte-net-7.scope"
asked = {1000: "\n".join([ok, "user.slice/user-1001.slice/user@1001.service/app.slice/app-theirs-1.scope",        # someone else's app
                          "user.slice/user-1000.slice/user@1000.service/../../../system.slice", ok + '" drop\n', "system.slice/sshd.service",
                          "user.slice/user-1000.slice/user@1000.service/app.slice/app-x\\x2dy-1.scope", ""])}
assert netd.wanted(asked, exists=lambda p: True) == {ok, "user.slice/user-1000.slice/user@1000.service/app.slice/app-x\\x2dy-1.scope"}
assert netd.wanted(asked, exists=lambda p: False) == set()                       # an app that ended has no group to cut
assert netd.table({ok}).count('socket cgroupv2 level 5 "%s" drop' % ok) == 2 and "drop" not in netd.table(set())
inst = load("install", ".")
with tempfile.TemporaryDirectory() as d:
    open(os.path.join(d, "FILES"), "w").write("# a comment\n[files]\n/usr/bin/x   <- bin/x      # why\n/usr/share/t/   <- system:/nowhere/*.png\n/usr/bin/b <- build:b\n"
                                              "[needs]\npackage: here gone   # why\noptional: maybe\n/usr/bin/tool: built elsewhere\noptional /usr/lib64/latteos/p.so: a plugin\n"
                                              "[steps]\nusermod -aG latte USER\nhook add VERSION\nplain   # said why\n")
    sec = inst.read(os.path.join(d, "FILES"))
    assert sec["steps"] == ["usermod -aG latte USER", "hook add VERSION", "plain"] and inst.pairs(sec["files"])[0] == ("/usr/bin/x", "bin/x")
    assert inst.copies(sec, "files") == [(os.path.join(ROOT, "bin/x"), "/usr/bin/x"), (os.path.join(ROOT, "target/release/b"), "/usr/bin/b")]     # nothing matched the pictures
    lent = {"files": ["/t/own.png <- assets/own.png", "/t/ <- system:" + d + "/*.png"]}
    open(os.path.join(d, "own.png"), "w").close(); open(os.path.join(d, "other.png"), "w").close()
    assert dict((t, s) for s, t in inst.copies(lent, "files")) == {"/t/own.png": os.path.join(ROOT, "assets/own.png"), "/t/other.png": os.path.join(d, "other.png")}
    assert inst.needs(sec, have=lambda p: p == "here", there=lambda p: False) == (["gone"], ["maybe"], ["/usr/bin/tool: built elsewhere"], ["optional /usr/lib64/latteos/p.so: a plugin"])
    assert inst.commands(sec["steps"], ["ann", "bob"], ["6.1", "6.2"]) == ["usermod -aG latte ann", "usermod -aG latte bob", "hook add 6.1", "hook add 6.2", "plain"]
    os.makedirs(os.path.join(d, "usr/lib64/latteos")); os.makedirs(os.path.join(d, "usr/share/latteos"))
    for f in ("usr/lib64/latteos/p.so", "usr/share/latteos/old.qml", "usr/share/latteos/kept"): open(os.path.join(d, f), "w").close()
    assert inst.leftovers(d, ["/usr/share/latteos/kept"], sec) == [os.path.join(d, "usr/share/latteos/old.qml")]      # the plugin FILES asks for is not a leftover
print("bin: ok")

# Barista: a recipe is found by the files that tell a program apart, and a missing disc is said, not guessed at.
barista = load("latte-barista")
with tempfile.TemporaryDirectory() as t:
    disc1, disc2 = os.path.join(t, "one"), os.path.join(t, "two")
    os.makedirs(disc1), os.makedirs(disc2)
    for name in ("AVP2.exe", "ALIEN.REZ", "MARINE.REZ", "PREDATOR.REZ", "data1.cab"):
        open(os.path.join(disc1, name), "w").close()
    barista.SHARE, barista.GAMES = ROOT, os.path.join(t, "games")
    a = barista.analyze([disc1])
    assert (a["recipe"], a["verdict"], a["missing"]) == ("avp2", "no", ["data3.cab"]), a
    open(os.path.join(disc2, "data3.cab"), "w").close()
    a = barista.analyze([disc1, disc2])
    assert a["recipe"] == "avp2" and a["missing"] == [] and a["verdict"] in ("works", "no"), a      # "no" only where Wine is not installed
    assert barista.analyze([disc2])["recipe"] == ""
    assert "--unshare-net" in barista.fence("/x", False) and "--unshare-net" not in barista.fence("/x", True)

    # Branch B, no recipe: the header tells year, bitness and graphics; the rules pick Wine or Proton and the Windows
    def pe(year, magic=b"\x0b\x01", imports=b""):
        stamp = int(barista.datetime.datetime(year, 6, 1, tzinfo=barista.datetime.timezone.utc).timestamp())
        return b"MZ" + bytes(0x3A) + (0x40).to_bytes(4, "little") + b"PE\0\0" + bytes(4) + stamp.to_bytes(4, "little") + bytes(12) + magic + imports
    old = barista.program(pe(2001, imports=b"\0d3d8.dll\0DDRAW.dll\0"))
    assert old == {"arch": "pe32", "year": 2001, "graphics": ["d3d8", "ddraw"]}, old
    assert barista.runner_for(old) == ("wine", "winxp")
    assert barista.runner_for(barista.program(pe(2015, b"\x0b\x02"))) == ("proton", "win10")
    assert barista.runner_for(barista.program(pe(2010, imports=b"\0d3d11.dll\0"))) == ("proton", "win7")
    assert barista.program(b"MZ" + bytes(0x3A) + (0x40).to_bytes(4, "little") + b"NE")["arch"] == "ne16"
    src = os.path.join(t, "src")
    for name, body, packed in (("setup.exe", pe(2005) + b"Inno Setup Setup Data", "inno"), ("setup.exe", pe(2005) + b"Nullsoft Install System", "nsis"),
                               ("setup.exe", pe(2005), "setup"), ("game.exe", pe(2005, imports=b"\0d3d9.dll\0"), "")):
        shutil.rmtree(src, ignore_errors=True)
        os.makedirs(os.path.join(src, "redist"))
        open(os.path.join(src, name), "wb").write(body)
        open(os.path.join(src, "redist", "vcredist_x86.exe"), "wb").write(pe(2005) * 99)     # bigger, but a helper
        r, why = barista.guess([src])
        assert (r["packaging"], why, r["id"]) == (packed, "", "src"), (name, r, why)
    assert r["install"] == [{"copy": "*"}] and r["runner"] == "wine" and barista.main_exe(src).endswith("game.exe"), r
    lone = os.path.join(t, "Some Game.exe")
    open(lone, "wb").write(pe(2005))
    assert barista.guess([lone])[0]["install"] == [{"copy": ["some game.exe"]}]          # a program that needs no installing
    assert barista.guess([os.path.join(t, "x.apk")]) == (None, "kind")
    a = barista.analyze([lone])
    assert (a["made"], a["id"], a["verdict"] in ("may", "no")) == (True, "some-game", True), a

# GuardDog says whose a process is: the kernel's and the system's, LatteOS's (only what the list names, with its hash), or the user's
dog = load("latte-guarddog")
me = os.getuid()
with tempfile.TemporaryDirectory() as d:
    tool, script, other = (os.path.join(d, n) for n in ("latte-tool", "latte-monitor", "latteosminer"))
    for path, body in ((tool, "binary"), (script, "script"), (other, "miner")):
        open(path, "w").write(body)
    files = {tool: dog.sha(tool), script: dog.sha(script)}
    asked = lambda **kw: dog.owner(kw.pop("pid", 4000), kw.pop("comm", "x"), kw.pop("ppid", 1000), kw.pop("uid", me),
                                   kw.pop("cgroup", "/user.slice/user-1000.slice/session-3.scope"), kw.pop("cmdline", ""), kw.pop("exe", ""), files)
    assert asked(pid=2) == "linux" and asked(ppid=2, comm="kworker") == "linux"                   # the kernel's threads
    assert asked(uid=0, cgroup="/system.slice/chronyd.service", comm="chronyd") == "linux"
    assert asked(cgroup="/user.slice/user-1000.slice/user@1000.service/session.slice/pipewire.service", comm="pipewire") == "linux"
    assert asked(comm="latte-tool", exe=tool, cmdline=tool) == "latteos"                          # on the list, and what it says
    assert asked(comm="latte-monitor", exe="/usr/bin/python3", cmdline="python3 " + script) == "latteos"      # an interpreter carrying a listed script
    assert asked(comm="latte-tool", exe=other, cmdline=other) == "user"                           # the name is nobody's: the list is
    assert asked(comm="python3", exe="/usr/bin/python3", cmdline="python3 %s %s" % (other, script)) == "user"       # a listed file as an argument is not a listed script
    assert asked(comm="python3", exe=os.path.join(d, "python3"), cmdline="python3 " + script) == "user"          # a carrier that is not the distribution's
    open(tool, "w").write("changed")                                                              # the file is no longer what the list says
    assert asked(comm="latte-tool", exe=tool, cmdline=tool) == "user"
    assert asked(comm="firefox", cgroup="/user.slice/user-1000.slice/user@1000.service/app.slice/app-firefox-123.scope", exe="/usr/bin/firefox", cmdline="/usr/bin/firefox") == "user"
    # the list itself counts only if it is the root's and nobody else can write it
    mine_list = os.path.join(d, "guarddog.manifest")
    open(mine_list, "w").write(json.dumps({"files": files, "components": ["goo"]}))
    assert dog.listed(mine_list)["state"] == "invalid"
    os.chmod(mine_list, 0o666)
    assert dog.listed(mine_list)["state"] == "invalid"
    assert dog.listed(os.path.join(d, "nothing"))["state"] == "missing"
    # what the user switched off stays off
    dog.CHOICES = os.path.join(d, "guarddog.json")
    dog.choose("clipboard", False)
    dog.choose("icons", False)
    dog.choose("icons", True)
    assert dog.switched_off() == {"clipboard"}
