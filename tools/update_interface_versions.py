#!/usr/bin/env python3
"""Add the current interface number of each supported game flavor to WowSimsExporter.toc.

Reads each product's live version from Blizzard's version service (the highest across all
regions, since some flavors only run in one region), turns it into an interface number
(1.60.1 -> 16001), and adds it to the TOC's "## Interface:" list when it's missing. Existing
numbers are kept, so players on a client that hasn't updated yet still load the addon.

Usage: python3 tools/update_interface_versions.py
"""

import pathlib
import re
import sys
import urllib.request

VERSIONS_URL = "https://us.version.battle.net/v2/products/{product}/versions"

# Blizzard product code -> flavor, for every flavor the addon supports.
PRODUCTS = {
    "wow_classic_era": "Classic Era / SoD",
    "wow_anniversary": "TBC Anniversary",
    "wow_classic_titan": "Titan Reforged",
    "wow_classic": "Mists of Pandaria Classic",
    "wowf": "WoW Forever",
}

TOC = pathlib.Path(__file__).resolve().parent.parent / "WowSimsExporter.toc"
INTERFACE_LINE = re.compile(r"^## Interface:(.*)$", re.MULTILINE)


def live_version(product: str) -> tuple:
    with urllib.request.urlopen(VERSIONS_URL.format(product=product), timeout=30) as response:
        text = response.read().decode("utf-8")
    lines = [line for line in text.splitlines() if line and not line.startswith("##")]
    header = [column.split("!")[0] for column in lines[0].split("|")]
    name_column = header.index("VersionsName")
    versions = [tuple(int(part) for part in line.split("|")[name_column].split(".")) for line in lines[1:]]
    if not versions:
        sys.exit(f"No versions listed for {product}")
    return max(versions)


def interface_number(version: tuple) -> int:
    major, minor, patch = version[:3]
    return major * 10000 + minor * 100 + patch


def main() -> None:
    toc = TOC.read_text(encoding="utf-8")
    match = INTERFACE_LINE.search(toc)
    if not match:
        sys.exit(f"No ## Interface line in {TOC.name}")
    interfaces = [int(value) for value in match.group(1).split(",")]

    added = []
    for product, flavor in PRODUCTS.items():
        version = live_version(product)
        interface = interface_number(version)
        if interface in interfaces:
            continue
        # Put it before the older numbers of the same flavor (same major.minor), else at the end.
        same_flavor = [i for i, value in enumerate(interfaces) if value // 100 == interface // 100]
        interfaces.insert(same_flavor[0] if same_flavor else len(interfaces), interface)
        added.append(f"{interface} ({flavor}, {'.'.join(map(str, version))})")

    if not added:
        print("Interface numbers up to date")
        return

    line = "## Interface: " + ", ".join(str(value) for value in interfaces)
    TOC.write_text(toc[:match.start()] + line + toc[match.end():], encoding="utf-8")
    print("Added interface numbers:\n" + "\n".join(f"- {entry}" for entry in added))


if __name__ == "__main__":
    main()
