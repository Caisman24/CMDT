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
    -- Add more professions if needed
}

-- Utility to get a full character key
local function GetCharKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- Save character info on login
function CMDT:OnInitialize()
    -- Initialize saved variables if needed

    CMDT_CharactersDB = CMDT_CharactersDB or {}
end

function CMDT:OnEnable()
    -- Register event

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
        -- Create a horizontal container for the whole character row
        local charRow = AceGUI:Create("SimpleGroup")
        charRow:SetLayout("Flow")
        charRow:SetFullWidth(true)

        -- Group 1: Character Name (left)
        local nameGroup = AceGUI:Create("SimpleGroup")
        nameGroup:SetLayout("Flow")
        nameGroup:SetFullHeight(true)
        nameGroup:SetWidth(200) -- fixed width for name column

        local lbl = AceGUI:Create("Label")
        local c = RAID_CLASS_COLORS[data.class] or { r = 1, g = 1, b = 1 }
        local colorCode = format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        lbl:SetText(colorCode .. data.name .. "-" .. data.realm .. "|r")
        lbl:SetFullWidth(true)
        nameGroup:AddChild(lbl)

        charRow:AddChild(nameGroup)

        -- Group 2: Professions (center)
        local profGroup = AceGUI:Create("SimpleGroup")
        profGroup:SetLayout("Flow")
        profGroup:SetFullHeight(true)
        profGroup:SetWidth(400) -- adjust width as needed

        for profName, skill in pairs(data.professions or {}) do
            local spellID = ProfessionSpellIDs and ProfessionSpellIDs[profName]
            local iconPath
            if spellID then
                iconPath = select(3, GetSpellInfo(spellID))
            end

            local iconW = AceGUI:Create("Icon")
            if iconPath then
                iconW:SetImage(iconPath)
            else
                iconW:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            iconW:SetImageSize(16, 16)
            iconW:SetWidth(20)
            profGroup:AddChild(iconW)

            local profLabel = AceGUI:Create("Label")
            profLabel:SetText(profName .. " (" .. skill .. ")")
            profLabel:SetWidth(100)
            profGroup:AddChild(profLabel)
        end

        charRow:AddChild(profGroup)

        -- Group 3: Delete button (right)
        local buttonGroup = AceGUI:Create("SimpleGroup")
        buttonGroup:SetLayout("Flow")
        buttonGroup:SetFullHeight(true)
        buttonGroup:SetWidth(160) -- small width for button column

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
        buttonGroup:AddChild(deleteBtn)

        charRow:AddChild(buttonGroup)

        -- Add the full row to the frame
        frame:AddChild(charRow)
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
