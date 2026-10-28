local Env = select(2, ...)

Env.RegisterLocale("zhCN", {
    -- Main window
    ["Click 'Generate Data' to generate exportable data"] = "点击“生成数据”以生成可导出的数据",
    ["Main"] = "主页",
    ["Saved Data"] = "已保存数据",
    ["Your character's class is currently unsupported. The supported classes are currently:"] = "当前角色的职业暂不支持。目前支持的职业有：",
    ["MAIN_INSTRUCTIONS"] = [[

要将角色上传到模拟器，请点击下方的链接前往模拟器网站。

在模拟器页面右上角找到“Import”（导入）按钮，点击后选择“Addon”标签页，将数据粘贴
到输入框中，然后点击“Import”。

]],
    ["Click to copy: %s"] = "点击复制：%s",
    ["International site - click to copy: %s"] = "国际版（点击复制）：%s",
    ["China site - click to copy: %s"] = "中国版（点击复制）：%s",
    ["Generate Data (Equipped Only)"] = "生成数据（仅已装备）",
    ["Batch: Export Bag Items"] = "批量：导出背包物品",
    ["Copy and paste into the websites importer!"] = "复制并粘贴到网站的导入器中！",
    ["Data Generated!"] = "数据已生成！",

    -- Copy dialog
    ["WSE Copy Dialog"] = "WSE 复制窗口",
    ["Use CTRL+C to copy link"] = "按 CTRL+C 复制链接",

    -- Saved data tab
    ["Saved Character Data Management"] = "已保存角色数据管理",
    ["Auto-Save Settings"] = "自动保存设置",
    ["Enable Auto-Save"] = "启用自动保存",
    ["Show Auto-Save Messages"] = "显示自动保存消息",
    ["Saved Characters"] = "已保存的角色",
    ["No saved characters found."] = "没有找到已保存的角色。",
    ["Saved: %s"] = "保存于：%s",
    ["Export"] = "导出",
    ["Delete"] = "删除",

    -- Character panel button
    ["Open WowSimsExporter"] = "打开 WowSimsExporter",

    -- Options
    ["Open Exporter Window"] = "打开导出窗口",
    ["Opens the exporter window"] = "打开导出器窗口",
    ["Show Character Pane Button"] = "显示角色面板按钮",
    ["Show or hide the WowSims icon button on the character sheet."] = "在角色面板上显示或隐藏 WowSims 图标按钮。",
    ["Profiles"] = "配置文件",

    -- Chat messages
    ["%s %s Initialized. Commands:"] = "%s %s 已加载。命令：",
    ["/wse - Open window"] = "/wse - 打开窗口",
    ["/wse export - Export character (auto-saves)"] = "/wse export - 导出角色（会自动保存）",
    ["Auto-save: %s"] = "自动保存：%s",
    ["ENABLED"] = "已启用",
    ["DISABLED"] = "已禁用",
    ["Credits go to %s"] = "作者：%s",
    ["WARNING: Sim does not support your game version! Supported versions are:"] = "警告：模拟器不支持你的游戏版本！支持的版本有：",
    ["Exported %d items from bags."] = "已从背包导出 %d 件物品。",
    ["Auto-save enabled."] = "自动保存已启用。",
    ["Auto-save disabled."] = "自动保存已禁用。",
    ["Auto-save messages enabled."] = "自动保存消息已启用。",
    ["Auto-save messages disabled."] = "自动保存消息已禁用。",
    ["Auto-save enabled. Character will be saved automatically on equipment, talent, level, and other changes."] = "自动保存已启用。装备、天赋、等级等发生变化时将自动保存角色。",
    ["Auto-save disabled. Use /wse export to manually save character data."] = "自动保存已禁用。请使用 /wse export 手动保存角色数据。",
    ["Usage: /wseautosave [on|off|messages]"] = "用法：/wseautosave [on|off|messages]",
    ["Usage: /wsedelete <number> - Use /wselist to see available characters"] = "用法：/wsedelete <编号> - 使用 /wselist 查看可用角色",
    ["Updated saved character data for %s"] = "已更新 %s 的角色数据",
    ["Character data saved for %s"] = "已保存 %s 的角色数据",
    ["Deleted saved character: %s"] = "已删除保存的角色：%s",
    ["Saved Characters:"] = "已保存的角色：",
    ["%d. %s (saved: %s)"] = "%d. %s（保存于：%s）",
    ["No saved character found at index %d"] = "编号 %d 处没有已保存的角色",
    ["Character auto-saved due to %s"] = "角色已自动保存（触发事件：%s）",

    -- Supported client names
    ["Classic: Mists of Pandaria"] = "经典怀旧服：熊猫人之谜",
    ["Classic: Cataclysm"] = "经典怀旧服：大地的裂变",
    ["Classic: WotLK"] = "经典怀旧服：巫妖王之怒",
    ["Classic: TBC"] = "经典怀旧服：燃烧的远征",
    ["Classic: SoD"] = "经典怀旧服：探索赛季",
    ["Classic: Era/Anniversary"] = "经典怀旧服：永久/周年服",
})
