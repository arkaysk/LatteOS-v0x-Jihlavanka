#!/usr/bin/env python3
"""latte-ai invite goes with the login: the notice it waits on is let go when the session ends, instead of staying
with its shell after logging out (bughunt 89). Nothing is shown and nothing of the user's is written: the notice,
loginctl and the folder of flags are stand-ins.
Run: python3 tests/test_ai_invite.py"""
import importlib.machinery, importlib.util, os, shutil, subprocess, sys, tempfile

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("latte_ai", os.path.join(ROOT, "bin", "latte-ai"))
ai = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(ai)


class Notice:
    """notify-send --wait that nobody answers."""
    killed = False

    def __init__(self, *a, **k):
        Notice.last = self
        self.stdout = open(os.devnull)

    def wait(self, timeout=None):
        if self.killed:
            return -9
        raise subprocess.TimeoutExpired("notify-send", timeout)

    def poll(self):
        return -9 if self.killed else None

    def kill(self):
        self.killed = True


with tempfile.TemporaryDirectory() as d:
    ai.TOGGLES = os.path.join(d, "toggles")
    ai.turned_off, ai.chosen, ai.doers = lambda: False, lambda w: "", lambda: ["claude"]
    ai.shutil = type("Sh", (), {"which": staticmethod(lambda *a, **k: "/bin/true")})
    opened, looks = [], []
    real = ai.subprocess
    ai.subprocess = type("S", (), {"Popen": staticmethod(lambda argv, **k: opened.append(argv) or Notice()),
                                   "TimeoutExpired": real.TimeoutExpired, "PIPE": real.PIPE, "DEVNULL": real.DEVNULL})
    alive = ai.session_alive
    ai.session_alive = lambda: looks.append(1) or len(looks) < 3          # the login ends at the third look
    ai.INVITE_POLL = 0.01
    ai.invite()
    assert Notice.last.killed and len(looks) == 3, looks
    assert [a[0] for a in opened] == ["notify-send"], opened                 # not "pick": LensAI was not opened
    assert os.path.exists(os.path.join(d, "done", "agent-invitation"))       # asked once, as before
    # logged out before the minute was up: no notice, and asked at the next login
    os.remove(os.path.join(d, "done", "agent-invitation"))
    opened.clear()
    ai.session_alive = lambda: False
    ai.invite()
    assert opened == [] and not os.path.exists(os.path.join(d, "done", "agent-invitation"))

# whether the login is there: logind's word on XDG_SESSION_ID; without one, the process that started latte-session's shell
ai.subprocess, ai.session_alive = subprocess, alive
assert ai.session_alive(sid="", leader=os.getpid())
assert not ai.session_alive(sid="", leader=2 ** 22 + 1)
assert ai.session_alive(sid="", leader=0)                                   # nothing to watch: it waits for the answer
if shutil.which("loginctl"):
    assert not ai.session_alive(sid="no-such-session")                      # logged out: logind no longer knows it
print("invite: ok")
