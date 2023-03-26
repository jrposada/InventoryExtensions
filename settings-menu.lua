local IE = InventoryExtensions
local LAM = LibAddonMenu2

IE_SETTINGS_MENU = {}

function IE_SETTINGS_MENU.Init()
    local saveData = IE.SavedVars -- TODO this should be a reference to your actual saved variables table
    local panelName = IE.name.."_SettingsPanel" -- TODO the name will be used to create a global variable, pick something unique or you may overwrite an existing variable!

    local panelData = {
        type = "panel",
        name = "Inventory Extensions",
        author = "Panicida"
    }

    local optionsData = {
        {
            type = "description",
            text = IE.Loc("Settings_GlobalSettings")
        },
        {
            type = "divider"
        },
    }

    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, optionsData)
end