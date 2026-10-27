#!/usr/bin/env python3
"""Generate the talent definition ID table in Flavors/Forever/Flavor.lua.

The wowsims Forever sim reads talents as a positional string: digit i of tree t is
talents[i] of tree t in ui/sim/talents/trees/<class>.json. The client exposes talents
through C_Traits, so the addon maps each purchased node's TraitDefinition ID back to that
position. This script copies the definitionId order out of a wowsims/forever checkout.

Usage: python3 tools/gen_forever_talents.py <path to wowsims/forever checkout>
Rewrites the block between the GENERATED markers in Flavors/Forever/Flavor.lua. The block is
left untouched when the table itself is unchanged, so a newer checkout with the same trees
doesn't only bump the source commit.
"""

import json
import pathlib
import re
import subprocess
import sys

CLASSES = ["druid", "hunter", "mage", "paladin", "priest", "rogue", "shaman", "warlock", "warrior"]
BEGIN = "-- BEGIN GENERATED TALENTS"
END = "-- END GENERATED TALENTS"
SOURCE_PREFIX = "-- Source: wowsims/forever@"


def source_ref(checkout: pathlib.Path) -> str:
    try:
        result = subprocess.run(
            ["git", "-C", str(checkout), "rev-parse", "--short=12", "HEAD"],
            capture_output=True, text=True, check=True,
        )
        return result.stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def render_table(trees_dir: pathlib.Path) -> str:
    lines = ["local talentDefinitionIds = {"]
    for cls in CLASSES:
        trees = json.loads((trees_dir / f"{cls}.json").read_text(encoding="utf-8"))
        # Spec detection in Flavors/Forever/Flavor.lua counts points in exactly three trees.
        if len(trees) != 3:
            sys.exit(f"{cls}.json has {len(trees)} trees, expected 3")
        lines.append(f"    {cls.upper()} = {{")
        for tree in trees:
            ids = ", ".join(str(int(t["definitionId"])) for t in tree["talents"])
            lines.append(f"        {{ {ids} }}, -- {tree['name']}")
        lines.append("    },")
    lines.append("}")
    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    checkout = pathlib.Path(sys.argv[1])
    target = pathlib.Path(__file__).resolve().parent.parent / "Flavors/Forever/Flavor.lua"
    source = target.read_text(encoding="utf-8")
    pattern = re.compile(re.escape(BEGIN) + r"\n(.*?)" + re.escape(END), re.DOTALL)
    match = pattern.search(source)
    if not match:
        sys.exit(f"Generated markers not found in {target}")

    table = render_table(checkout / "ui" / "sim" / "talents" / "trees")
    current_table = "\n".join(
        line for line in match.group(1).rstrip("\n").split("\n") if not line.startswith(SOURCE_PREFIX)
    )
    if current_table == table:
        print("Talent table unchanged")
        return

    block = f"{BEGIN}\n{SOURCE_PREFIX}{source_ref(checkout)}\n{table}\n{END}"
    target.write_text(source[:match.start()] + block + source[match.end():], encoding="utf-8")
    print(f"Updated {target.name}")


if __name__ == "__main__":
    main()
