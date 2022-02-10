local IE = InventoryExtensions
local WM = WINDOW_MANAGER

IE.Containers = {}

local currencyTypes = IE.Constants.CurrencyTypes

local pvpContainers = {
    items = {
        [2385654930] = true, -- Rewards for the Worthy (blue)
        [1300143049] = true, -- Battlemaster Rivyn's Reward Box (purple)
        [4109939254] = true, -- Transmutation Geode (white)
        [3395908003] = true, -- Transmutation Geode (purple)
        [1976142150] = true, -- Uncracked Transmutation Geode (gold)
    },
    en = {
        ["Rewards for the Worthy"] = true,
        ["Battlemaster Rivyn's Reward Box"] = true,
        ["Transmutation Geode"] = true,
        ["Uncracked Transmutation Geode"] = true,
    }
}

local function OpenContainer(bagId, slotId)
    if IsProtectedFunction("UseItem") then
        CallSecureProtected("UseItem", bagId, slotId)
    else
        UseItem(bagId, slotId)
    end

	-- EM:RegisterForUpdate(IE.name.."_LootRescan", 100, scanBagForUnopenedContainers)
end

local function OnLootUpdated(event)
    local lootInfo = GetLootTargetInfo()

    if pvpContainers.en[lootInfo] then
        local chatMessage = ChatMessage:New("[IE:LootContainer] ")
        local didSomething = false

        -- Get currencies
        for currencyType, currencyTexure in pairs(currencyTypes) do
            didSomething = true
            local currency = GetLootCurrency(currencyType)
            -- TODO: check currency cap
            if currency ~= 0 then
                chatMessage:AddMessage(zo_strformat(" |t18:18:<<2>>|t <<t:1>>", currency, currencyTexure))
            end
        end

        -- Get items
        local numItems=GetNumLootItems()
        for i = 1, numItems do
            didSomething = true
            local lootId, name, texture, count, quality, value, isQuest, stolen, lootType = GetLootItemInfo(i)
            local link = GetLootItemLink(lootId)
            chatMessage:AddMessage(zo_strformat(" |t18:18:<<2>>|t <<t:1>>", link, texture))
        end

        if not didSomething then
            chatMessage:AddMessage(IE.Loc("AllDone"))
        end

        -- Actually loot
        LootAll()

        -- Close loot window
        return true
    end
end

local function OpenContainers()
    local function IsPvpContainer(bagId, slotIndex)
        local itemId = GetItemInstanceId(bagId, slotIndex)
        return pvpContainers.items[itemId] or false
    end

    local function FilterUnwantedItems(itemData)
        -- Other protect addon compatibility here

        local isStolen = itemData.stolen
        local isJunk = itemData.isJunk
        local isProtected = itemData.isPlayerLocked
        if isStolen or isJunk or isProtected then
          return false
        else
          return true
        end
    end

    local function ItemShouldBeOpened(bagId, slotId)
        local savedVars = IE.SavedVars

        if savedVars.containers.pvp and IsPvpContainer(bagId, slotId) then
            return true
        end

        return false
    end

    local bagCache = SHARED_INVENTORY:GenerateFullSlotData(FilterUnwantedItems, BAG_BACKPACK)
    local messagePrefix = "[IE:OpenContainers]"
    local message = ""
    for index, data in pairs(bagCache) do
        if ItemShouldBeOpened(data.bagId, data.slotIndex) then
            OpenContainer(data.bagId, data.slotIndex)
            local link = GetItemLink(data.bagId, data.slotIndex)
            local texture = GetItemLinkIcon(link)
            message = message..zo_strformat(" |t18:18:<<2>>|t <<t:1>>", link, texture)
            if data.stackCount ~=1 then
                message = message..zo_strformat(" x <<1>>",data.stackCount)
            end
        end
    end

    if message ~= "" then
        CHAT_SYSTEM:AddMessage(messagePrefix..message)
    else
        CHAT_SYSTEM:AddMessage(messagePrefix.." "..IE.Loc("AllDone"))
    end
end

local function Debug()
    local function DebugLog(control)
        local itemLink = GetItemLink(control.bagId, control.slotIndex)
        local itemId = GetItemInstanceId(control.bagId, control.slotIndex)
        IE.LogLater(itemLink.." "..itemId)

        -- OnInventoryUpdate(nil, control.bagId, control.slotIndex)
    end

    ZO_PreHook("ZO_InventorySlot_ShowContextMenu", function(control) DebugLog(control) end)
end

function IE.Containers.Init()
    -- Create button
    local parent = ZO_PlayerInventory
    local button = WM:CreateControlFromVirtual("IE_OpenContainers", parent, "IE_Button")
    local texture = button:GetNamedChild("Texture")
    local highlight = button:GetNamedChild("Highlight")

    texture:SetTexture("esoui/art/tutorial/vendor_tabicon_buyback_up.dds")
    highlight:SetTexture("esoui/art/tutorial/vendor_tabicon_buyback_up.dds")

    button:SetDimensions(32, 32)
    button:ClearAnchors()
    button:SetAnchor(BOTTOMLEFT,parent,TOPLEFT,135,-5)
    button:SetClickSound("Click")
    button:SetHandler("OnClicked", function() OpenContainers() end)
    button:SetHandler("OnMouseEnter", function() highlight:SetHidden(false) end)
    button:SetHandler("OnMouseExit", function() highlight:SetHidden(true) end)
    button:SetHidden(false)

    -- Hook to loot window
	ZO_PreHook(SYSTEMS:GetObject("loot"), "UpdateLootWindow", OnLootUpdated)
    Debug()
end