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
print("local models: ok")
