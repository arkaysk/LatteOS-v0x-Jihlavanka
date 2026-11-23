#!/usr/bin/env python3
"""The models folder in latte-ai: a model put there by hand, also in LM Studio's author/model/ folders, is listed with its
picture reader; the readers, the index's and speech's models are not models to chat with.
Run: python3 tests/test_local_models.py"""
import importlib.machinery, importlib.util, os, sys, tempfile

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("latte_ai", os.path.join(ROOT, "bin", "latte-ai"))
ai = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(ai)

with tempfile.TemporaryDirectory() as d:
    root = os.path.join(d, "models")
    for f in ["Own-Q4_K_M.gguf", "mmproj-Own-F16.gguf", "lmstudio-community/Foo-GGUF/Foo-Q8_0.gguf",
              "lmstudio-community/Foo-GGUF/mmproj-model-f16.gguf", "embed/e5.gguf", "asr/w.gguf", "Bar.gguf.part"]:
        os.makedirs(os.path.dirname(os.path.join(root, f)), exist_ok=True)
        open(os.path.join(root, f), "w").close()
    ai.LOCAL_DIRS = [d]
    found = sorted(os.path.relpath(m["id"], root) for m in ai.local_models_all())
    assert found == ["Own-Q4_K_M.gguf", "lmstudio-community/Foo-GGUF/Foo-Q8_0.gguf"], found
    assert ai.local_mmproj(os.path.join(root, "lmstudio-community/Foo-GGUF/Foo-Q8_0.gguf")).endswith("mmproj-model-f16.gguf")
    assert ai.local_mmproj(os.path.join(root, "Own-Q4_K_M.gguf")).endswith("mmproj-Own-F16.gguf")

# llama-fit-params said something that is not UTF-8 (a model's own name or notes): measuring a model must not throw, or the
# whole list of models is empty in LensAI (23. 11.: the newest model, not yet measured, took every other one with it)
with tempfile.TemporaryDirectory() as d:
    tool = os.path.join(d, "llama-fit-params")
    with open(tool, "w") as f:
        f.write("#!/bin/sh\nprintf 'name \\304 broken\\n'\n")
    os.chmod(tool, 0o755)
    model = os.path.join(d, "M-Q4_K_M.gguf")
    open(model, "wb").write(b"x" * 64)
    ai.local_server = lambda: os.path.join(d, "llama-server")
    ai.gguf = lambda m: {"layers": 10, "context": 4096}
    ai.MEASURED, ai.ROOM = os.path.join(d, "measured.json"), d
    sets = {"ctx": 4096, "ngl": 99, "batch": 512, "ubatch": 512, "parallel": 1}
    got = ai.estimate(model, sets, {"gpus": [], "ram": 1 << 36}, quick=False)
    assert got, got
print("local models: ok")

# a model My Models marks "too-big" is not in the router's presets nor in agentgram's picker, so no agent loads it; asking
# for it does not restart the router (bughunt 23. 11.). Everything in a temporary folder: the user's own models.ini, the
# running llama-server and local-ai.json are not touched.
with tempfile.TemporaryDirectory() as d:
    os.makedirs(os.path.join(d, "models"))
    small, big = os.path.join(d, "models", "Small-Q4_K_M.gguf"), os.path.join(d, "models", "Huge-Q4_K_M.gguf")
    open(small, "wb").write(b"x" * 10)
    open(big, "wb").write(b"x" * 20)
    ai.LOCAL_DIRS, ai.ROOM = [d], d
    ai.ROUTER_PRESET, ai.LOCAL_SETTINGS, ai.MEASURED = os.path.join(d, "models.ini"), os.path.join(d, "local-ai.json"), os.path.join(d, "m.json")
    ai.hardware = lambda: {"gpus": [], "ram": 1 << 30}
    ai.estimate = lambda m, sets, hw, quick=False: {"fit": "too-big" if m == big else "cpu"}
    ai.embedder = lambda: None
    ai.gguf = lambda m: {}
    ran = []
    ai.subprocess = type("S", (), {"run": staticmethod(lambda *a, **k: ran.append(a)), "Popen": staticmethod(lambda *a, **k: ran.append(a))})
    assert ai.too_big() == {big}
    ai.local_preset()
    ini = open(ai.ROUTER_PRESET).read()
    assert "[Small-Q4_K_M]" in ini and "Huge" not in ini, ini
    assert [m["id"] for m in ai.local_catalog()] == ["Small-Q4_K_M"]
    assert ai.local_start(big) is False and not ran, ran
print("too-big models: ok")
