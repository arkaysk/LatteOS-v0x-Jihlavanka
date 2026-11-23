#!/usr/bin/env python3
"""bughunt 23. 11.: `latte-apps install --all` passed "--all" to flatpak as an option, and SAFE could not be locked.
Nothing is installed and nothing is locked: flatpak and pleamar are stand-ins.
Run: python3 tests/test_apps_lock.py"""
import contextlib, importlib.machinery, importlib.util, io, os, subprocess, sys, tempfile

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("latte_apps", os.path.join(ROOT, "bin", "latte-apps"))
apps = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(apps)

# an id that looks like an option is no id: the usage, code 2, and flatpak never asked
calls = []
apps.work = lambda *a: calls.append(a) or 0
apps.out = lambda *a, **k: "flathub"
with contextlib.redirect_stdout(io.StringIO()):
    for a in (["install", "--all"], ["remove", "-y"], ["update", "--all"], ["install", "-"]):
        assert apps.main(a) == 2, a
assert calls == [], calls
apps.main(["install", "org.gnome.Calculator"])
apps.main(["update"])
assert calls == [("flatpak", "install", "--user", "--noninteractive", "-y", "flathub", "org.gnome.Calculator"),
                 ("flatpak", "update", "--noninteractive", "-y")], calls

# latte-lock in SAFE asks the SAFE bar, and nothing else; --scene (Goo's own question) gets no
with tempfile.TemporaryDirectory() as d:
    said = os.path.join(d, "said")
    with open(os.path.join(d, "pleamar"), "w") as f:
        f.write('#!/bin/sh\necho "$@" >> %s\n' % said)
    os.chmod(os.path.join(d, "pleamar"), 0o755)
    env = dict(os.environ, PATH=d + ":" + os.environ["PATH"], LATTE_MODE="safe", XDG_RUNTIME_DIR=d)
    lock = os.path.join(ROOT, "bin", "latte-lock")
    assert subprocess.run(["sh", lock], env=env).returncode == 0
    assert subprocess.run(["sh", lock, "--scene"], env=env).returncode == 1
    assert open(said).read() == "--say safe emit lock_now\n", open(said).read()

print("ok")
