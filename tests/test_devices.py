#!/usr/bin/env python3
"""latte-devices says when the drivers did not come out right (bughunt 23. 11.): NVIDIA's installed but the card on
nouveau, NVIDIA's never installed, sound hardware without a card, sound cards without a profile, devices without a
driver. What the system says is a stand-in: nothing is asked of this computer.
Run: python3 tests/test_devices.py"""
import importlib.machinery, importlib.util, json, os, sys

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("latte_devices", os.path.join(ROOT, "bin", "latte-devices"))
dev = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(dev)


def ids(groups, rpm="", cards="", pactl="[]", gpus=({"driver": "akmod-nvidia (595+, open modules)"},)):
    said = {"rpm": rpm, "pactl": pactl}
    dev.out = lambda *argv, timeout=10: said.get(argv[0], "")
    dev.read = lambda path, default="": cards if path == "/proc/asound/cards" else default
    return [f["id"] for f in dev.driver_findings(groups, gpus)]


gpu = lambda driver: {"graphics": [dev.device("NVIDIA GA104 [GeForce RTX 3060]", "VGA", driver, "ok" if driver else "no-driver")]}
sound = {"sound": [dev.device("Intel HD Audio", "Audio", "snd_hda_intel")]}
asound = " 0 [PCH            ]: HDA-Intel - HDA Intel PCH\n"
on = json.dumps([{"name": "alsa_card.pci", "active_profile": "output:analog-stereo"}, {"name": "hdmi", "active_profile": "off"}])
off = json.dumps([{"name": "alsa_card.pci", "active_profile": "off"}])

assert ids(gpu("nvidia")) == []
assert ids(gpu("nouveau"), rpm="akmod-nvidia") == ["nvidia-not-loaded"]
assert ids(gpu("nouveau")) == ["nvidia-missing"]
assert ids(gpu("nouveau"), gpus=[{"driver": "nouveau (NVK)"}]) == []         # an older card is on nouveau on purpose
assert ids(gpu(""), rpm="akmod-nvidia") == ["nvidia-not-loaded", "no-driver"]
assert ids(sound, cards=asound, pactl=on) == []                     # an HDMI output off is how it is without a monitor's sound
assert ids(sound, cards=asound, pactl=off) == ["sound-no-profile"]
assert ids(sound, cards="--- no soundcards ---") == ["sound-no-card"]
assert ids(sound, cards=asound, pactl="") == []                     # no PipeWire to ask: nothing is claimed
f = dev.driver_findings(gpu("nouveau"), [{"driver": "akmod-nvidia"}])[0]
assert "{driver}" in f["text"] and f["args"] == {"driver": "nouveau"}        # translated whole, the driver put in after
print("devices: ok")
