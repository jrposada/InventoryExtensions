local IE = InventoryExtensions
local LIBLA = LibLoadedAddons
local ATTS = ArkadiusTradeTools.Modules.Sales
local LF = LibFilters3

IE.HighTradeValue = {}

local SECONDS_IN_DAY = 60 * 60 * 24

local function IsHighTradeValue(itemLink)
    local fromTimeStamp = GetTimeStamp() - IE.SavedVars.highTradeValue.days * SECONDS_IN_DAY
    local salesInfo = ATTS:GetItemSalesInformation(itemLink, fromTimeStamp)[itemLink]

    if not salesInfo then return false end

    local averagePrice = ATTS:GetAveragePricePerItem(itemLink, fromTimeStamp)
    local quantity = 0
    for _, sale in pairs(salesInfo) do
        quantity = quantity + sale.quantity
    end

    if averagePrice * quantity >= IE.SavedVars.highTradeValue.minIncome then
        return true
    else
        return false
    end
end

-- local function ScrollListCommit(list)
--     local isATTSLoaded = LIBLA:IsAddonLoaded(ATTS.NAME)
--     counter = counter + 1
--     IE.LogLater("Scoll list commit"..counter)
--     if not isATTSLoaded then return end

--     if (IE.PlayerInventoryLists[list]) then
--         local scrollData = ZO_ScrollList_GetDataList(list)
--         for i = 1, #scrollData do
--             local data = scrollData[i].data
--             local bagId = data.bagId
--             local slotIndex = data.slotIndex
--             local itemLink = bagId and GetItemLink(bagId, slotIndex) or GetItemLink(slotIndex)
--             if itemLink then
--                 local isHighTradeValue = IsHighTradeValue(itemLink)
--                 data.isHighTradeValue = isHighTradeValue
--             end
--         end
--     end
-- end

local function FilterByHighTradeValue(control)
    local function Filter(control)
        -- IE.LogLater(args1)
        -- IE.LogLater(args2)
        return control.isHighTradeValue
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

    local bagCache = SHARED_INVENTORY:GenerateFullSlotData(FilterUnwantedItems, BAG_BACKPACK, BAG_VIRTUAL)
    for index, data in pairs(bagCache) do
        local bagId = data.bagId
        local slotIndex = data.slotIndex
        local itemLink = bagId and GetItemLink(bagId, slotIndex) or GetItemLink(slotIndex)
        if itemLink then
            local isHighTradeValue = IsHighTradeValue(itemLink)
            data.isHighTradeValue = isHighTradeValue
        end
    end

    if LF:IsFilterRegistered("IE_HighTradeValue", LF_INVENTORY) then
        LF:UnregisterFilter("IE_HighTradeValue", LF_INVENTORY)
        LF:UnregisterFilter("IE_HighTradeValue", LF_CRAFTBAG)
    else
        LF:RegisterFilter("IE_HighTradeValue", LF_INVENTORY, Filter)
        LF:RegisterFilter("IE_HighTradeValue", LF_CRAFTBAG, Filter)
    end

    LF:RequestUpdate(LF_INVENTORY)
end

function IE.HighTradeValue.Init()
    -- Create filter button
    local parent = ZO_PlayerInventory
    local button = WINDOW_MANAGER:CreateControlFromVirtual("IE_HighTradeValue", parent, "ZO_DefaultButton")
    button:SetWidth(110, 28)
    button:SetText(IE.Loc("Test"))
    button:ClearAnchors()
    button:SetAnchor(BOTTOMLEFT,parent,TOPLEFT,0,-40)
    button:SetClickSound("Click")
    button:SetHandler("OnClicked", function() FilterByHighTradeValue() end)
    button:SetState(BSTATE_NORMAL)
    button:SetHidden(false)
    button:SetDrawTier(2)
end
