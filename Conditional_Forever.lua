local addonName, Env = ...
if not Env.IS_FOREVER then return end

local WSE = Env

Env.prelink = "https://www.wowsims.com/forever/"

Env.supportedClasses = {
    "hunter",
    "mage",
    "shaman",
    "priest",
    "rogue",
    "druid",
    "warrior",
    "warlock",
    "paladin",
}

-- Utility helpers
local function TblSum(tbl)
    local sum = 0
    if not tbl then return sum end
    for _, v in pairs(tbl) do
        sum = sum + (v or 0)
    end
    return sum
end

local function TblCountNonZero(tbl)
    local count = 0
    if not tbl then return count end
    for _, v in pairs(tbl) do
        if (v or 0) > 0 then
            count = count + 1
        end
    end
    return count
end

local function TblMaxValIdx(tbl)
    if not tbl or #tbl == 0 then return 1 end
    local maxIdx = 1
    local maxVal = tbl[1] or 0
    for i = 2, #tbl do
        local val = tbl[i] or 0
        if val > maxVal then
            maxVal = val
            maxIdx = i
        end
    end
    return maxIdx
end

local function StatBiggerThanStat(stat1, stat2)
    local statMap = {
        str = 1,
        agi = 2,
        sta = 3,
        int = 4,
        spi = 5,
    }
    local s1Idx = statMap[stat1]
    local s2Idx = statMap[stat2]
    if not s1Idx or not s2Idx then return false end
    local _, s1Val = UnitStat("player", s1Idx)
    local _, s2Val = UnitStat("player", s2Idx)
    return (s1Val or 0) > (s2Val or 0)
end

Env.TblMaxValIdx = TblMaxValIdx
Env.TblSum = TblSum
Env.TblCountNonZero = TblCountNonZero
Env.StatBiggerThanStat = StatBiggerThanStat

-- Spec Registrations
Env.AddSpec("shaman", "elemental", "elemental_shaman", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", "enhancement_shaman", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("hunter", "beast_mastery", "hunter", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", "hunter", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", "hunter", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", "balance_druid", function(t)
    return TblMaxValIdx(t) == 1 and StatBiggerThanStat("int", "agi")
end)
Env.AddSpec("druid", "feral", "feral_druid", function(t)
    return (TblMaxValIdx(t) == 2)
        or StatBiggerThanStat("agi", "int")
        or StatBiggerThanStat("str", "int")
end)

local function HasMetamorphRune()
    if Env.GetEngravedRuneSpell then
        return Env.GetEngravedRuneSpell(10) == 403789
    end
    return false
end

Env.AddSpec("warlock", "affliction", "warlock", function(t) return not HasMetamorphRune() and TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", "warlock", function(t) return not HasMetamorphRune() and TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", "warlock", function(t) return not HasMetamorphRune() and TblMaxValIdx(t) == 3 end)
Env.AddSpec("warlock", "warlocktank", "tank_warlock", function(t) return HasMetamorphRune() end)

Env.AddSpec("rogue", "assassination", "rogue", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", "rogue", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", "rogue", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", "mage", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", "mage", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", "mage", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", "warrior", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", "warrior", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("paladin", "retribution", "retribution_paladin", function(t) return true end)
Env.AddSpec("priest", "shadow", "shadow_priest", function(t) return true end)

local SoulEngravingEnchantIDs = {
    [7668] = 1219955,
    [7669] = 1219958,
    [7670] = 1219960,
    [7671] = 1219962,
    [7672] = 1219964,
    [7673] = 1219966,
    [7674] = 1219968,
    [7675] = 1219970,
    [7676] = 1219972,
    [7677] = 1219974,
    [7678] = 1219976,
    [7679] = 1219978,
    [7680] = 1219980,
    [7681] = 1219982,
    [7682] = 1219984,
    [7683] = 1219986,
    [7685] = 1219988,
    [7686] = 1219990,
    [7687] = 1219992,
    [7688] = 1219994,
    [7689] = 1219996,
    [7690] = 1219998,
    [7691] = 1220000,
    [7692] = 1220002,
    [7693] = 1220004,
    [7694] = 1220006,
    [7695] = 1220008,
    [7696] = 1220010,
    [7697] = 1220012,
    [7698] = 1220014,
    [7699] = 1220016,
    [7700] = 1220018,
    [7701] = 1220020,
    [7702] = 1220023,
    [7703] = 1220024,
    [7704] = 1220026,
    [7705] = 1220028,
    [7706] = 1220030,
    [7707] = 1220032,
    [7708] = 1220035,
    [7709] = 1220036,
    [7710] = 1220038,
    [7711] = 1220040,
    [7712] = 1220042,
    [7713] = 1220044,
    [7714] = 1220046,
    [7715] = 1220048,
    [7716] = 1220050,
    [7717] = 1220052,
    [7718] = 1220054,
    [7719] = 1220056,
    [7720] = 1220058,
    [7721] = 1220060,
    [7722] = 1220062,
    [7723] = 1220064,
    [7724] = 1220066,
    [7725] = 1220068,
    [7726] = 1220070,
    [7727] = 1220072,
    [7738] = 1220072,
    [7728] = 1220074,
    [7729] = 1220076,
    [7730] = 1220078,
    [7731] = 1220080,
    [7732] = 1220082,
    [7733] = 1220084,
    [7734] = 1220086,
    [7735] = 1220088,
    [7736] = 1220090,
    [7737] = 1220092,
    [7739] = 1220094,
    [7740] = 1220096,
    [7741] = 1220098,
    [7742] = 1220100,
    [7743] = 1220102,
    [7744] = 1220104,
    [7745] = 1220106,
    [7746] = 1220108,
    [7747] = 1220110,
    [7748] = 1220112,
    [7749] = 1220114,
    [7750] = 1220116,
    [7751] = 1220118,
    [7752] = 1220120,
    [7753] = 1220122,
    [7754] = 1220124,
    [7755] = 1220126,
    [7756] = 1220128,
    [7757] = 1220130,
    [7758] = 1220132,
    [7759] = 1220134,
    [7760] = 1220136,
    [7761] = 1220138,
    [7762] = 1220140,
    [7763] = 1220142,
    [7764] = 1220144,
    [7765] = 1220146,
    [7766] = 1220148,
    [7767] = 1220150,
    [7768] = 1220152,
    [7769] = 1220154,
    [7770] = 1220156,
    [7771] = 1220158,
    [7772] = 1220160,
    [7773] = 1220162,
    [7774] = 1220164,
    [7775] = 1220166,
    [7776] = 1220168,
    [7777] = 1220170,
    [7778] = 1220172,
    [7779] = 1220174,
    [7780] = 1220176,
    [7781] = 1220178,
    [7782] = 1220180,
    [7783] = 1220182,
    [7784] = 1220184,
    [7785] = 1220186,
    [7786] = 1220188,
    [7787] = 1220190,
    [7788] = 1220192,
    [7789] = 1220194,
    [7790] = 1220196,
    [7791] = 1220198,
    [7792] = 1220200,
    [7793] = 1220202,
    [7794] = 1220204,
    [7795] = 1220206,
    [7796] = 1220208,
    [7797] = 1220210,
    [7798] = 1220212,
    [7799] = 1220214,
    [7800] = 1220216,
    [7801] = 1220218,
    [7802] = 1220220,
    [7803] = 1220222,
    [7804] = 1220224,
    [7805] = 1220226,
    [7806] = 1220228,
    [7807] = 1220230,
    [7808] = 1220232,
    [7809] = 1220234,
    [7810] = 1220236,
    [7811] = 1220238,
    [7812] = 1220240,
    [7813] = 1220242,
    [7814] = 1220244,
    [7815] = 1220246,
    [7816] = 1220248,
    [7817] = 1220250,
    [7818] = 1220252,
    [7819] = 1220254,
    [7820] = 1220256,
    [7821] = 1220258,
    [7822] = 1220260,
    [7823] = 1220262,
    [7824] = 1220264,
    [7825] = 1220266,
    [7826] = 1220268,
    [7827] = 1220270,
    [7828] = 1220272,
    [7829] = 1220274,
    [7830] = 1220276,
    [7831] = 1220279,
    [7832] = 1220280,
    [7833] = 1220282,
    [7834] = 1220284,
    [7835] = 1220286,
    [7836] = 1220288,
    [7837] = 1220291,
    [7838] = 1220293,
    [7839] = 1220295,
    [7840] = 1220297,
    [7841] = 1220299,
    [7842] = 1220301,
    [7843] = 1220303,
    [7844] = 1220305,
    [7845] = 1220307,
    [7846] = 1220310,
    [7847] = 1220312,
    [7848] = 1220314,
    [7849] = 1220316,
    [7850] = 1220318,
    [7851] = 1220320,
    [7852] = 1220322,
    [7853] = 1220324,
    [7854] = 1220326,
    [7855] = 1220328,
    [7856] = 1220330,
    [7857] = 1220332,
    [7858] = 1220334,
    [7859] = 1220336,
    [7860] = 1220338,
    [7861] = 1220340,
    [7862] = 1220342,
    [7863] = 1220344,
    [7864] = 1220346,
    [7865] = 1220348,
    [7866] = 1220350,
    [7867] = 1220353,
    [7868] = 1220353,
    [7869] = 1220356,
    [7870] = 1220358,
    [7871] = 1220360,
    [7872] = 1220362,
    [7873] = 1220364,
    [7874] = 1220366,
    [7875] = 1220368,
}

local function GenerateSoulEngravingEnchantText()
    local soulEngravingEnchantText = {}
    if not Env.GetEnchantText then return soulEngravingEnchantText end
    for enchantID, spellID in pairs(SoulEngravingEnchantIDs) do
        local enchantText = Env.GetEnchantText(enchantID)
        if enchantText then
            soulEngravingEnchantText[enchantText] = spellID
        end
    end
    return soulEngravingEnchantText
end

local SoulEngravingEnchantText

function Env.GetSoulEngravingSpellID(slotID, bagID)
    if not SoulEngravingEnchantText then
        SoulEngravingEnchantText = GenerateSoulEngravingEnchantText()
    end

    if not WSEScanningTooltip then return nil end

    WSEScanningTooltip:ClearLines()
    WSEScanningTooltip:SetBagItem(bagID, slotID)
    local regions = { WSEScanningTooltip:GetRegions() }

    for i = 1, #regions do
        local region = regions[i]
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and SoulEngravingEnchantText[text] then
                return SoulEngravingEnchantText[text]
            end
        end
    end

    return nil
end