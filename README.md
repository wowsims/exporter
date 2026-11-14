# WowSims Exporter
An exporter addon for World Of Warcraft: Classic Sims at https://www.wowsims.com/

On **WoW Forever** it's the full **WowSims** addon (4.0, in beta): exporting plus gear sets, stat weights, upgrades, inspecting and more. See [WowSims for WoW Forever](#wowsims-for-wow-forever) below. Every other game version keeps the original exporter, unchanged.

Supports Classic Era/Anniversary, Season of Discovery, TBC, WotLK, Cataclysm and Mists of Pandaria Classic, and WoW Forever (https://www.wowsims.com/forever/).

The WoW Forever talent table in `Flavors/Forever/Talents.lua` is generated from the sim's talent trees. Regenerate it with `python3 tools/gen_forever_talents.py <path to a wowsims/forever checkout>` when they change, and check it with `npm ci --prefix tools/test && node tools/test/forever_talents.js <same path>`, which replays every talent string from the sim's presets through the export. The Forever talents workflow does both daily, and opens and merges a PR when the table changes.

The Interface versions workflow checks Blizzard's version service daily and opens a PR (for review) adding the interface number of any new client build to the TOC. Run it locally with `python3 tools/update_interface_versions.py`.

There is a channel on the wowsims discord call integrations to talking real time to people, please don't use the discord for support if it can be avoided please use the issue tracker. we may request to talk to you in the integrations channel involving a pull request or an issue though that's fine.

Invite is located here https://discord.gg/N9ZgAMXQ3p

**Getting the addon**

If anyone would like to test it, you can just download it from the releases page and you can also find it on Curseforge!

The WoW Forever 4.0 version is released as a **beta** first. To get betas from CurseForge, set the addon's release type to Beta in the CurseForge app.

please use curseforge if you can as it helps support my programming endeavors!


**To use the addon**

    /wse - will open up the options window - *wip* changes do nothing atm
    /wse open - will open the exporter window.
    /wse export will open the exporter window, generate the data, and have the data ready and highlighted for you to CTRL+C

If you change your gear, talents, enchants, glyphs or runes, you can either rerun `/wse export` if you closed the window and the data will be updated. or just click the `Generate Data` button.


# WowSims for WoW Forever
On WoW Forever the window is called **WowSims** and has a tab for each feature. A short tour shows them the first time you open it (replay it from Settings or with `/wowsims tour`).

| Tab | What it does |
| --- | --- |
| **Export** | Generate your character's data and paste it into the sim (Import > Addon). |
| **Saved Data** | Characters saved automatically, ready to export again. |
| **Gear Sets** | Save what you're wearing under a name; equip it again, compare it with your current gear, or send all sets to the sim at once. |
| **Stat Weights** | Paste the sim's Pawn export (Stat Weights > Export > Pawn). Item tooltips then show a WowSims score and how much of an upgrade an item is. |
| **Upgrades** | Items in your bags that beat what you're wearing, with an Equip button, plus your gear that's missing enchants or gems. |
| **Inspect** | Export another player's gear, talents and professions. Recent exports are kept with Copy, Gear and Talents buttons. |
| **Group** | Ask your whole group or guild for their exports at once, from anywhere: everyone with WowSims sends theirs back. You can turn sharing off. |
| **Import** | Paste the sim's JSON export or saved data. See the gear on your character, how it scores against what you wear, its talents and professions, and save it as a gear set. |
| **Settings** | Minimap button, tooltips, what exports include, and the tour. |

Also on Forever:
- A talent viewer for any class, with prerequisite arrows, from the Import, Gear Sets and Inspect tabs.
- **Apply talents** from an imported build. It never resets your talents: visit a class trainer to reset first if needed.
- Right-click a player's portrait and choose **WowSims Export to sim**.
- WowSims users in your guild and group tell each other their version, and you get one message when a newer one is out.
- English, Simplified Chinese and Traditional Chinese.

**Forever commands**

    /wowsims or /wse      open the window
    /wse export           export your character
    /wse inspect          export your target
    /wowsims tour         replay the tour
    /wowsims version      show who in your guild or group has WowSims, and their versions


# INFO
The aim for this project is to have an addon to export your characters gear, enchants, talents, and runes to wowsims.github.io.

On WoW Forever it goes further: a companion to the sim for gear, upgrades and your group.


# CONTRIBUTING
If you would like to contribute, please feel free!

**Code structure**

    Core/            Shared by every game version: flavor detection and registration, professions,
                     spec lookup, tooltips, the bag export filter
    Talents/         Talent and glyph readers shared by several game versions
    Flavors/<Name>/  One folder per game version. Flavor.lua calls Env.RegisterFlavor{...} with
                     everything that differs for that version (sim URL, classes, item fields,
                     events, talents, glyphs, item extras); other files hold its data and helpers
    ExportStructures/, UI.lua, WowSimsExporter.lua
                     Version independent: they only read Env.Flavor
    Features/        WowSims (Forever only): one file per feature, each registered with
                     Env.RegisterFeature (a tab and/or Initialize). Every file starts with
                     `if not Env.IS_FOREVER then return end`, so other game versions never run them

See the field list at the top of `Core/Flavor.lua`. To support a new game version, add a
`Flavors/<Name>/` folder, list its files in the TOC with `[AllowLoadGameType ...]`, and add a fake
client for it in `tools/test/wow_mock.lua`.

**Tests**

`npm ci --prefix tools/test && node tools/test/snapshots.js` runs every game version's export against
a fake client and compares it with `tools/test/snapshots/`. After an intended change, rerun it with
`--update` and commit the new snapshots. CI runs it on every pull request, and the release workflow
runs it before packaging a tag.

**Releases**

Pushing a tag releases it through the BigWigs packager to CurseForge and Wago. The tag name sets the
release type: a tag with `beta` in it (`v4.0.0-beta1`) is uploaded as a Beta, `alpha` as an Alpha,
anything else (`v4.0.0`) as a Release.

It was created using World of Warcraft Addon Creator 2015, its a very good IDE based on visual studio, its not required to be used, but if new files are added, please adjust the project file to match if not using WoWAC2015.

**Translations**

User-facing strings live in `Locales/`. Strings are keyed by their English text in `Locales/enUS.lua`; to add a language, copy `Locales/zhCN.lua`, change the locale code passed to `Env.RegisterLocale`, translate the values and add the file to `WowSimsExporter.toc`. Missing keys fall back to English.

#Contributors
generalwrex
zku
namreeb
coolmodi(FelixPflaum)
riotdog 
polynomix
