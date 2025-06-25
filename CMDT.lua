-- Initialize the Libraries
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local addonName = "CMDT"
local CMDT = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

-- Setup saved variables
CMDT_CharactersDB = CMDT_CharactersDB or {}
MyAddonDB = MyAddonDB or {}
local modalFrame = nil

local ProfessionSpellIDs = {
    ["Alchemy"] = 2259,
    ["Blacksmithing"] = 2018,
    ["Cooking"] = 2550,
    ["Enchanting"] = 7411,
    ["Engineering"] = 4036,
    ["First Aid"] = 3273,
    ["Herbalism"] = 2366,
    ["Inscription"] = 45357,
    ["Jewelcrafting"] = 25229,
    ["Leatherworking"] = 2108,
    ["Mining"] = 2580,
    ["Skinning"] = 8613,
    ["Tailoring"] = 3908,
}

local professionCDs = {
    ["Alchemy"] = {
        { id = 114852, name = "Transmute: Living Steel" },
        { id = 114780, name = "Transmute: Trillium Bar" },
        { id = 122668, name = "Transmute: Primal Diamond" },
        { id = 114783, name = "Transmute: Imperial Amethyst" },
        { id = 114781, name = "Transmute: Vermilion Onyx" },
        { id = 114784, name = "Transmute: Sun's Radiance" },
        { id = 114786, name = "Transmute: Wild Jade" },
        { id = 114785, name = "Transmute: River's Heart" },
        { id = 114787, name = "Transmute: Serpent's Eye" },
        { id = 114789, name = "Transmute: Primordial Ruby" },
        { id = 114790, name = "Transmute: Blue Quality Gems" },
    },

    ["Enchanting"] = {
        { id = 116499, name = "Sha Crystal" },
    },

    ["Inscription"] = {
        { id = 112996, name = "Scroll of Wisdom" },
    },

    ["Tailoring"] = {
        { id = 125557, name = "Imperial Silk" },
    },

    ["Engineering"] = {
        { id = 139176, name = "Jard's Peculiar Energy Source" },
    },

    ["Leatherworking"] = {
        { id = 142976, name = "Magnificence of Leather" },
        { id = 142958, name = "Magnificence of Scales" },
    },
}

local function FormatTime(seconds)
    if seconds <= 0 then
        return "Ready"
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function GetCooldownStatus(spellID)
    local start, duration, enabled = GetSpellCooldown(spellID)
    if enabled == 1 and duration > 1 then
        local cdLeft = start + duration - GetTime()
        if cdLeft > 0 then
            return "Next in: " .. FormatTime(cdLeft)
        end
    end
    return "Ready"
end

-- Utility to get a full character key
local function GetCharKey()
    local name, _ = UnitNameUnmodified("player")
    local realm   = GetRealmName()
    return name .. "-" .. realm
end

-- Save character info on login
function CMDT:OnInitialize()
    CMDT_CharactersDB = CMDT_CharactersDB or {}
end

function CMDT:OnEnable()
    self:RegisterEvent("PLAYER_ALIVE", "SaveCharacterData")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "SaveCharacterData")
end

function CMDT:SaveCharacterData()
    local key = GetCharKey()

    CMDT_CharactersDB = CMDT_CharactersDB or {}
    CMDT_CharactersDB[key] = CMDT_CharactersDB[key] or {
        name = UnitName("player"),
        class = select(2, UnitClass("player")),
        realm = GetRealmName(),
        professions = {},
        professionsSaved = false, -- initialize flag
    }

    local charData = CMDT_CharactersDB[key]

    -- Avoid duplicate saves
    if charData.professionsSaved then return end

    -- Save general info
    charData.name = UnitName("player")
    charData.class = select(2, UnitClass("player"))
    charData.realm = GetRealmName()
    charData.professions = {}

    -- Save professions
    local profs = { GetProfessions() }
    for _, profID in ipairs(profs) do
        if profID then
            local name, _, _, skillLevel = GetProfessionInfo(profID)
            if name then
                charData.professions[name] = skillLevel
            end
        end
    end

    -- Mark as saved
    charData.professionsSaved = true
end

-- Create Ace Modal
local function CreateAceModal()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Character Stats Panel")
    frame:SetStatusText(" ")
    frame:SetLayout("Flow")
    frame:SetWidth(800)
    frame:SetHeight(400)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        modalFrame = nil
    end)

    for key, data in pairs(CMDT_CharactersDB) do
        -- First Row: Name + Professions + Delete button
        local topRow = AceGUI:Create("SimpleGroup")
        topRow:SetLayout("Flow")
        topRow:SetFullWidth(true)

        -- Character Name
        local nameLbl = AceGUI:Create("Label")
        local c = RAID_CLASS_COLORS[data.class] or { r = 1, g = 1, b = 1 }
        local colorCode = format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        nameLbl:SetText(colorCode .. data.name .. "-" .. data.realm .. "|r")
        nameLbl:SetWidth(150)
        topRow:AddChild(nameLbl)

        -- Professions (icons + skill)
        for profName, skill in pairs(data.professions or {}) do
            local spellID = ProfessionSpellIDs[profName]
            local iconPath = spellID and select(3, GetSpellInfo(spellID)) or nil

            local iconW = AceGUI:Create("Icon")
            iconW:SetImage(iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconW:SetImageSize(16, 16)
            iconW:SetWidth(20)
            topRow:AddChild(iconW)

            local profLabel = AceGUI:Create("Label")
            profLabel:SetText(profName .. " (" .. skill .. ")")
            profLabel:SetWidth(110)
            topRow:AddChild(profLabel)
        end

        -- Delete button
        local deleteBtn = AceGUI:Create("Button")
        deleteBtn:SetText("Delete")
        deleteBtn:SetWidth(100)
        deleteBtn:SetCallback("OnClick", function()
            CMDT_CharactersDB[key] = nil
            print("Deleted character:", data.name .. "-" .. data.realm)
            if modalFrame then
                modalFrame:Hide()
                modalFrame = CreateAceModal()
            end
        end)
        topRow:AddChild(deleteBtn)

        frame:AddChild(topRow)

        -- Second Row: Cooldowns
        local cdRow = AceGUI:Create("SimpleGroup")
        cdRow:SetLayout("Flow")
        cdRow:SetFullWidth(true)

        for profName, _ in pairs(data.professions or {}) do
            local list = professionCDs[profName]
            if list then
                for _, entry in ipairs(list) do
                    local status = GetCooldownStatus(entry.id)
                    local cdLabel = AceGUI:Create("Label")
                    cdLabel:SetText(entry.name .. ": " .. status)
                    cdLabel:SetWidth(250)
                    cdRow:AddChild(cdLabel)
                end
            end
        end

        frame:AddChild(cdRow)
        local spacer = AceGUI:Create("Label")
        spacer:SetText(" ")
        spacer:SetFullWidth(true)
        spacer:SetHeight(10)
        frame:AddChild(spacer)
    end


    return frame
end

-- Function to toggle modal visibility
local function ToggleModal()
    if modalFrame and modalFrame.frame:IsShown() then
        modalFrame:Hide()
    else
        modalFrame = CreateAceModal()
    end
end

-- Slash command toggling modal
SLASH_CMDT1 = "/cmdt"
SlashCmdList["CMDT"] = function()
    ToggleModal()
end

-- Create Object for Minimap
local myLDB = LDB:NewDataObject("CMDT", {
    type = "data source",
    text = "CMDT",
    icon = "Interface\\AddOns\\CMDT\\minimap-icon.tga",
    OnClick = function(_, button)
        if button == "LeftButton" then
            ToggleModal()
        elseif button == "RightButton" then
            print("Right-clicked minimap icon")
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("CMDT")
        tt:AddLine("Click to open", 1, 1, 1)
    end,
})


LDBIcon:Register("CMDT", myLDB, MyAddonDB)
