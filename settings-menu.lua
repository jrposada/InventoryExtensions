local IE = INVENTORY_EXTENSIONS
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
        {
            type = "checkbox",
            name = IE.Loc("Settings_AutoBind"),
            getFunc = function() return saveData.autoBind.enabled end,
            setFunc = function(value) IE_AUTO_BIND.Enable(value) end
        },
        {
            type = "checkbox",
            name = IE.Loc("Settings_TtcPrice"),
            getFunc = function() return saveData.ttcPrice.enabled end,
            setFunc = function(value) IE_TTC_PRICE.Enable(value) end,
            requiresReload = true
        },
         
    }

    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, optionsData)
end