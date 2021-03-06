-- First, we create a namespace for our addon by declaring a top-level table that will hold everything else.
local IE = InventoryExtensions
local EM = EVENT_MANAGER
local LibFilters = LibFilters3

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
local function OnAddOnLoaded(eventCode, addonName)
    -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName ~= IE.name then return end
	EM:UnregisterForEvent(IE.name.."_Event", EVENT_ADD_ON_LOADED)

    -- Load saved variables
    IE.SavedVars = ZO_SavedVars:NewAccountWide(IE.name.."_Vars", IE.varsVersion, nil, IE.DefaultVars, GetWorldName())

    -- Initialize addons
    LibFilters:InitializeLibFilters()

    local numChars = GetNumCharacters()
    for index = 1, numChars do
        local name, _, _, _, _, _, id, _ = GetCharacterInfo(index)
        if id == GetCurrentCharacterId() then
            IE.CurrentCharacterName = name
            break
        end
    end

    -- Initialize stuff
    IE.Junk.Init()
    IE.Bind.Init()
    IE.MoneyTracker.Init()
    IE.SettingsMenu.Init()
    IE.HighTradeValue.Init()
    IE.Containers.Init()
    IE.Deposit.Init()
    -- IE.MarkItem.Init()
    IE.Events.Init()
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
EM:RegisterForEvent(IE.name.."_Event", EVENT_ADD_ON_LOADED, OnAddOnLoaded)