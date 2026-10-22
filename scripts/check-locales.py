#!/usr/bin/env python3
"""Checks the interface translations in data/core/locale.

Every language file must have the same keys as ja.lua, and each translation
must keep the placeholders (%s, %d, ...) of its English key in the same
order: a missing or extra one would raise an error when the string is shown.
"""
import pathlib
import re
import sys

LOCALE_DIR = pathlib.Path(__file__).resolve().parent.parent / "data" / "core" / "locale"
ENTRY = re.compile(r'\[("(?:[^"\\]|\\.)*")\]\s*=\s*("(?:[^"\\]|\\.)*")', re.S)
PLACEHOLDER = re.compile(r"%[-+ #0-9.]*[a-zA-Z%]")


def unquote(text):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text[1:-1])


def entries(path):
    return [(unquote(k), unquote(v)) for k, v in ENTRY.findall(path.read_text(encoding="utf-8"))]


def main():
    reference = [k for k, _ in entries(LOCALE_DIR / "ja.lua")]
    problems = 0
    for path in sorted(LOCALE_DIR.glob("*.lua")):
        items = entries(path)
        keys = [k for k, _ in items]
        for key in sorted(set(reference) - set(keys)):
            print(f"{path.name}: missing {key!r}")
            problems += 1
        for key in sorted(set(keys) - set(reference)):
            print(f"{path.name}: unknown key {key!r}")
            problems += 1
        for key, value in items:
            if PLACEHOLDER.findall(key) != PLACEHOLDER.findall(value):
                print(f"{path.name}: placeholders differ in {key!r} -> {value!r}")
                problems += 1
        print(f"{path.name}: {len(items)} strings")
    if problems:
        print(f"{problems} problem(s)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
