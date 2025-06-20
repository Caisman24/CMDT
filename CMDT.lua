-- Initialize the Libraries
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

MyAddonDB = MyAddonDB or {}
local modalFrame = nil

-- Create Ace Modal
local function CreateAceModal()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("CMDT")
    frame:SetStatusText(" ")
    frame:SetLayout("Flow")
    frame:SetWidth(400)
    frame:SetHeight(200)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        modalFrame = nil
    end)

    -- Create a horizontal group for icon + text
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetLayout("Flow")
    headerGroup:SetFullWidth(true)

    -- Add the icon
    local icon = AceGUI:Create("Icon")
    icon:SetImage("Interface\\AddOns\\CMDT\\minimap-icon.tga")
    icon:SetImageSize(24, 24)
    icon:SetWidth(28) -- padding around icon
    headerGroup:AddChild(icon)

    -- Add the label
    local headerLabel = AceGUI:Create("Label")
    headerLabel:SetText("|cffffff00CMDT Modal|r")
    headerLabel:SetFontObject(GameFontNormalLarge)
    headerLabel:SetFullWidth(true)
    headerLabel:SetJustifyH("LEFT")
    headerGroup:AddChild(headerLabel)

    -- Add the group to the modal
    frame:AddChild(headerGroup)

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
