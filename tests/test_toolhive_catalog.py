#!/usr/bin/env python3
"""latte-toolhive-catalog waits until every source of the Registry Server synced or failed in this run. On an empty
database (the first run of a new install) the server calls a source it never tried "failed", "No previous sync status
found", with its own start as the last attempt: that is no failure yet (24. 11.: the first run gave up after 5 s).
Run: python3 tests/test_toolhive_catalog.py"""
import importlib.machinery, importlib.util, os, sys, time
from datetime import datetime

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("catalog", os.path.join(ROOT, "bin", "latte-toolhive-catalog"))
c = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(c)

start = time.time()
now = datetime.fromtimestamp(start).astimezone().isoformat()
before = datetime.fromtimestamp(start - 3600).astimezone().isoformat()
# the server's own words at its start on an empty database (seen on the main PC, 24. 11.)
never = {"phase": "failed", "lastAttempt": now, "attemptCount": 0, "serverCount": 0, "message": "No previous sync status found"}
assert not c.now_done(never, start)
assert c.now_done({"phase": "complete", "serverCount": 922, "message": "Sync completed successfully"}, start)
assert c.now_done({"phase": "failed", "lastAttempt": now, "attemptCount": 1, "message": "failed to fetch"}, start)
assert not c.now_done({"phase": "failed", "lastAttempt": before, "attemptCount": 1, "message": "failed to fetch"}, start)
assert not c.now_done({"phase": "syncing"}, start)
print("toolhive catalog: ok")
