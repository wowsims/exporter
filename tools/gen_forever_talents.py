#!/usr/bin/env python3
"""Generate the talent definition ID table in Conditional_Forever.lua.

The wowsims Forever sim reads talents as a positional string: digit i of tree t is
talents[i] of tree t in ui/sim/talents/trees/<class>.json. The client exposes talents
through C_Traits, so the addon maps each purchased node's TraitDefinition ID back to that
position. This script copies the definitionId order out of a wowsims/forever checkout.

Usage: python3 tools/gen_forever_talents.py <path to wowsims/forever checkout>
Rewrites the block between the GENERATED markers in Conditional_Forever.lua.
"""

import json
import pathlib
import re
import sys

CLASSES = ["druid", "hunter", "mage", "paladin", "priest", "rogue", "shaman", "warlock", "warrior"]
BEGIN = "-- BEGIN GENERATED TALENTS"
END = "-- END GENERATED TALENTS"


def render(trees_dir: pathlib.Path) -> str:
    lines = [BEGIN, "local talentDefinitionIds = {"]
    for cls in CLASSES:
        trees = json.loads((trees_dir / f"{cls}.json").read_text(encoding="utf-8"))
        # Spec detection in Conditional_Forever.lua counts points in exactly three trees.
        if len(trees) != 3:
            sys.exit(f"{cls}.json has {len(trees)} trees, expected 3")
        lines.append(f"    {cls.upper()} = {{")
        for tree in trees:
            ids = ", ".join(str(int(t["definitionId"])) for t in tree["talents"])
            lines.append(f"        {{ {ids} }}, -- {tree['name']}")
        lines.append("    },")
    lines.append("}")
    lines.append(END)
    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    trees_dir = pathlib.Path(sys.argv[1]) / "ui" / "sim" / "talents" / "trees"
    target = pathlib.Path(__file__).resolve().parent.parent / "Conditional_Forever.lua"
    source = target.read_text(encoding="utf-8")
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.DOTALL)
    if not pattern.search(source):
        sys.exit(f"Generated markers not found in {target}")
    target.write_text(pattern.sub(lambda _: render(trees_dir), source), encoding="utf-8")


if __name__ == "__main__":
    main()
