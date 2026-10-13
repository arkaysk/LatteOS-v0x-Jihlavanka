#!/usr/bin/env python3
"""fake-player.py [SECONDS]: a music player that plays nothing, for trying MediaGoo in tests/screen.sh.

It is on the session bus as an MPRIS player with two songs; play/pause, next and previous work and are
printed, so a test can tell they arrived."""
import sys
from gi.repository import Gio, GLib

SONGS = [("Black Coffee", "Ella Fitzgerald"), ("One More Cup of Coffee", "Bob Dylan")]
XML = """<node>
<interface name="org.mpris.MediaPlayer2"><property name="Identity" type="s" access="read"/></interface>
<interface name="org.mpris.MediaPlayer2.Player">
  <method name="PlayPause"/><method name="Play"/><method name="Pause"/><method name="Next"/><method name="Previous"/>
  <property name="PlaybackStatus" type="s" access="read"/><property name="Metadata" type="a{sv}" access="read"/>
  <property name="CanGoNext" type="b" access="read"/><property name="CanGoPrevious" type="b" access="read"/>
  <property name="CanPlay" type="b" access="read"/><property name="CanPause" type="b" access="read"/><property name="CanControl" type="b" access="read"/>
</interface></node>"""
state = {"playing": True, "song": 0}


def prop(name):
    if name == "Identity": return GLib.Variant("s", "Fake player")
    if name == "PlaybackStatus": return GLib.Variant("s", "Playing" if state["playing"] else "Paused")
    if name == "Metadata":
        title, artist = SONGS[state["song"]]
        return GLib.Variant("a{sv}", {"mpris:trackid": GLib.Variant("o", "/song/%d" % state["song"]),
                                      "xesam:title": GLib.Variant("s", title), "xesam:artist": GLib.Variant("as", [artist])})
    return GLib.Variant("b", True)


def called(bus, sender, path, iface, method, args, invocation):
    if method in ("PlayPause", "Play", "Pause"): state["playing"] = method == "Play" or (method == "PlayPause" and not state["playing"])
    if method in ("Next", "Previous"): state["song"] = (state["song"] + (1 if method == "Next" else -1)) % len(SONGS)
    print(method, "→", "playing" if state["playing"] else "paused", SONGS[state["song"]][0], flush=True)
    invocation.return_value(None)
    bus.emit_signal(None, path, "org.freedesktop.DBus.Properties", "PropertiesChanged", GLib.Variant(
        "(sa{sv}as)", ("org.mpris.MediaPlayer2.Player", {"PlaybackStatus": prop("PlaybackStatus"), "Metadata": prop("Metadata")}, [])))


def on_bus(bus, name):
    for iface in Gio.DBusNodeInfo.new_for_xml(XML).interfaces:
        bus.register_object("/org/mpris/MediaPlayer2", iface, called, lambda b, s, p, i, n: prop(n), None)


loop = GLib.MainLoop()
Gio.bus_own_name(Gio.BusType.SESSION, "org.mpris.MediaPlayer2.lattefake", Gio.BusNameOwnerFlags.NONE, on_bus, None, None)
GLib.timeout_add_seconds(int(sys.argv[1]) if len(sys.argv) > 1 else 30, loop.quit)
loop.run()
