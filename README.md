# WowSims Exporter
An exporter addon for World Of Warcraft: Classic Sims at https://www.wowsims.com/

Supports Classic Era/Anniversary, Season of Discovery, TBC, WotLK, Cataclysm and Mists of Pandaria Classic, and WoW Forever (https://www.wowsims.com/forever/).

The WoW Forever talent table in `Flavors/Forever/Flavor.lua` is generated from the sim's talent trees. Regenerate it with `python3 tools/gen_forever_talents.py <path to a wowsims/forever checkout>` when they change, and check it with `npm ci --prefix tools/test && node tools/test/forever_talents.js <same path>`, which replays every talent string from the sim's presets through the export. The Forever talents workflow does both daily, and opens and merges a PR when the table changes.

The Interface versions workflow checks Blizzard's version service daily and opens a PR (for review) adding the interface number of any new client build to the TOC. Run it locally with `python3 tools/update_interface_versions.py`.

There is a channel on the wowsims discord call integrations to talking real time to people, please don't use the discord for support if it can be avoided please use the issue tracker. we may request to talk to you in the integrations channel involving a pull request or an issue though that's fine.

Invite is located here https://discord.gg/N9ZgAMXQ3p

**Getting the addon**

If anyone would like to test it, you can just download it from the releases page and you can also find it on Curseforge!

please use curseforge if you can as it helps support my programming endeavors!


**To use the addon**

    /wse - will open up the options window - *wip* changes do nothing atm
    /wse open - will open the exporter window.
    /wse export will open the exporter window, generate the data, and have the data ready and highlighted for you to CTRL+C

If you change your gear, talents, enchants, glyphs or runes, you can either rerun `/wse export` if you closed the window and the data will be updated. or just click the `Generate Data` button.


# INFO
The aim for this project is to have an addon to export your characters gear, enchants, talents, and runes to wowsims.github.io.


# CONTRIBUTING
If you would like to contribute, please feel free!

It was created using World of Warcraft Addon Creator 2015, its a very good IDE based on visual studio, its not required to be used, but if new files are added, please adjust the project file to match if not using WoWAC2015.

#Contributors
generalwrex
zku
namreeb
coolmodi(FelixPflaum)
riotdog 
polynomix
