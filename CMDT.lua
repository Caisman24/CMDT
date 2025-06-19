local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local myLDB = LDB:NewDataObject("CMDT", {
    type = "data source",
    text = "CMDT",
    icon = "Interface\\AddOns\\CMDT\\minimap-icon.tga",
    OnClick = function(_, button)
        print("Minimap button clicked: " .. button)
        -- Toggle your UI here
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("CMDT")
        tt:AddLine("Click to open", 1, 1, 1)
    end,
})

MyAddonDB = MyAddonDB or {}
LDBIcon:Register("CMDT", myLDB, MyAddonDB)

function CMDT_OnLoad(self)
    print("Loading CMDT!")
end