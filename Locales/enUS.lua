local Env = select(2, ...)

-- Base locale. Keys are the English text; `true` means the value equals the key.
-- Long multi-line texts use an UPPER_CASE key instead.
Env.RegisterLocale("enUS", {
    -- Main window
    ["Click 'Generate Data' to generate exportable data"] = true,
    ["Main"] = true,
    ["Saved Data"] = true,
    ["Your character's class is currently unsupported. The supported classes are currently:"] = true,
    ["MAIN_INSTRUCTIONS"] = [[

To upload your character to the simulator, click on the url below that leads to the simulator website.

You will find an Import button on the top right of the simulator named "Import". Click that and select the "Addon" tab, paste the data
into the provided box and click "Import"

]],
    ["Click to copy: %s"] = true,
    ["International site - click to copy: %s"] = true,
    ["China site - click to copy: %s"] = true,
    ["Generate Data (Equipped Only)"] = true,
    ["Batch: Export Bag Items"] = true,
    ["Copy and paste into the websites importer!"] = true,
    ["Data Generated!"] = true,

    -- Copy dialog
    ["WSE Copy Dialog"] = true,
    ["Use CTRL+C to copy link"] = true,

    -- Saved data tab
    ["Saved Character Data Management"] = true,
    ["Auto-Save Settings"] = true,
    ["Enable Auto-Save"] = true,
    ["Show Auto-Save Messages"] = true,
    ["Saved Characters"] = true,
    ["No saved characters found."] = true,
    ["Saved: %s"] = true,
    ["Export"] = true,
    ["Delete"] = true,

    -- Character panel button
    ["Open WowSimsExporter"] = true,

    -- Options
    ["Open Exporter Window"] = true,
    ["Opens the exporter window"] = true,
    ["Show Character Pane Button"] = true,
    ["Show or hide the WowSims icon button on the character sheet."] = true,

    -- Chat messages
    ["%s %s Initialized. Commands:"] = true,
    ["/wse - Open window"] = true,
    ["/wse export - Export character (auto-saves)"] = true,
    ["Auto-save: %s"] = true,
    ["ENABLED"] = true,
    ["DISABLED"] = true,
    ["Credits go to %s"] = true,
    ["WARNING: Sim does not support your game version! Supported versions are:"] = true,
    ["Exported %d items from bags."] = true,
    ["Auto-save enabled."] = true,
    ["Auto-save disabled."] = true,
    ["Auto-save messages enabled."] = true,
    ["Auto-save messages disabled."] = true,
    ["Auto-save enabled. Character will be saved automatically on equipment, talent, level, and other changes."] = true,
    ["Auto-save disabled. Use /wse export to manually save character data."] = true,
    ["Usage: /wseautosave [on|off|messages]"] = true,
    ["Usage: /wsedelete <number> - Use /wselist to see available characters"] = true,
    ["Updated saved character data for %s"] = true,
    ["Character data saved for %s"] = true,
    ["Deleted saved character: %s"] = true,
    ["Saved Characters:"] = true,
    ["%d. %s (saved: %s)"] = true,
    ["No saved character found at index %d"] = true,
    ["Character auto-saved due to %s"] = true,

    -- Supported client names
    ["Classic: Mists of Pandaria"] = true,
    ["Classic: Cataclysm"] = true,
    ["Classic: WotLK"] = true,
    ["Classic: TBC"] = true,
    ["Classic: SoD"] = true,
    ["Classic: Era/Anniversary"] = true,
    ["WoW Forever"] = true,
})
