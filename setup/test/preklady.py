#!/usr/bin/env python3
"""
Script to find untranslated strings in QML files.
It loads the Slovak translations from session/i18n/sk.json and reports any string passed to tr("...") or i18n.tr("...") that is not a key in that JSON.
At the end it prints a line 'chýba: N' where N is the number of missing strings.
The script always exits with code 0.
"""
import json
import re
import pathlib
import sys

def main() -> int:
    sk_path = pathlib.Path("session/i18n/sk.json")
    if not sk_path.is_file():
        print(f"Missing {sk_path}", file=sys.stderr)
        return 0
    try:
        with sk_path.open(encoding="utf-8") as f:
            sk_map = json.load(f)
    except Exception as e:  # pragma: no cover - defensive
        print(f"Error loading JSON {sk_path}: {e}", file=sys.stderr)
        return 0
    keys = set(sk_map.keys())

    qml_dir = pathlib.Path("session/apps")
    if not qml_dir.is_dir():
        print(f"No apps directory at {qml_dir}", file=sys.stderr)
        return 0

    missing: set[str] = set()
    pattern = re.compile(r'(?<![\w.])(?:i18n\.)?tr\(\s*"([^"]*)"\s*\)')   # nie str("…") ani x.tr("…")

    for path in qml_dir.rglob("*.qml"):
        try:
            content = path.read_text(encoding="utf-8")
        except Exception as e:  # pragma: no cover - defensive
            print(f"Error reading {path}: {e}", file=sys.stderr)
            continue
        for match in pattern.finditer(content):
            s = match.group(1)
            if s not in keys:
                missing.add(s)

    for s in sorted(missing):
        print(s)
    print(f"chýba: {len(missing)}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
