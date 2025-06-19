local modal = CreateFrame("Frame", "MyModalFrame", UIParent, "BackdropTemplate")
local overlay = CreateFrame("Frame", nil, UIParent)

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local myLDB = LDB:NewDataObject("CMDT", {
    type = "data source",
    text = "CMDT",
    icon = "Interface\\AddOns\\CMDT\\minimap-icon.tga",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if modal:IsShown() then
                modal:Hide()
                overlay:Hide()
            else
                overlay:Show()
                modal:Show()
            end
        elseif button == "RightButton" then
            print("Right-clicked minimap icon")
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("CMDT")
        tt:AddLine("Click to open", 1, 1, 1)
    end,
})

MyAddonDB = MyAddonDB or {}
LDBIcon:Register("CMDT", myLDB, MyAddonDB)

-- Overlay
overlay:SetAllPoints(UIParent)
overlay:SetFrameStrata("FULLSCREEN_DIALOG")
overlay:EnableMouse(true)
overlay:Hide()

-- Modal
modal:SetSize(400, 200)
modal:SetPoint("CENTER")
modal:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
modal:SetBackdropColor(0, 0, 0, 0.9)
modal:SetFrameStrata("DIALOG")
modal:SetFrameLevel(overlay:GetFrameLevel() + 1)
modal:EnableMouse(true)
modal:Hide()

-- Title
local header = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", modal, "TOP", 0, -10)
header:SetText("CMDT Modal")

-- Close Button
local closeBtn = CreateFrame("Button", nil, modal, "UIPanelButtonTemplate")
closeBtn:SetFrameLevel(modal:GetFrameLevel() + 1)
closeBtn:SetSize(80, 24)
closeBtn:SetPoint("BOTTOM", modal, "BOTTOM", 0, 10)
closeBtn:SetText("Close")
closeBtn:EnableMouse(true)
closeBtn:SetScript("OnClick", function()
    print("Close button clicked!")
    modal:Hide()
    overlay:Hide()
end)

-- Slash command toggling modal
SLASH_CMDT1 = "/cmdt"
SlashCmdList["CMDT"] = function()
    if modal:IsShown() then
        modal:Hide()
        overlay:Hide()
    else
        overlay:Show()
        modal:Show()
    end
end
