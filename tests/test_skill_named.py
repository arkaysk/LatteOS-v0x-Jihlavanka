#!/usr/bin/env python3
"""latte-skill picks a device by its name only when one alone answers to it (GPT's review, 21. 11.).
Run: python3 tests/test_skill_named.py"""
import importlib.machinery, importlib.util, os, sys

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("latte_skill", os.path.join(ROOT, "bin", "latte-skill"))
sk = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(sk)

find = sk.named("paired", "device")
now = {"paired": [{"label": "Sony WH-1000XM5"}, {"label": "Sony WF-1000XM4"}, {"label": "Keyboard K380"}]}
assert find({"device": "sony"}, now) is None                                   # two alike: not guessed
assert find({"device": "Sony WH-1000XM5"}, now)["label"] == "Sony WH-1000XM5"   # its own name
assert find({"device": "wf-1000"}, now)["label"] == "Sony WF-1000XM4"           # one alone holds it
assert find({"device": "my keyboard k380 please"}, now)["label"] == "Keyboard K380"   # held by what was asked, one alone
assert find({"device": ""}, now) is None and find({}, now) is None
print("latte-skill named: ok")
