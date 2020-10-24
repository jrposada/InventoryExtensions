local IE = InventoryExtensions
local LF = LibFilters3

IE.HighTradeValue = {}

local SECONDS_IN_DAY = 60 * 60 * 24

local function IsAnySalesAddonLoaded()
    local atts = (ArkadiusTradeTools or nil) and ArkadiusTradeTools.Modules.Sales
    local mm = MasterMerchant

    return atts ~= nil or mm ~= nil
end

function IE.HighTradeValue.IsHighTradeValue(itemLink)
    local atts = (ArkadiusTradeTools or nil) and ArkadiusTradeTools.Modules.Sales
    local mm = MasterMerchant

    local function GetMMSalesInfo()
        local salesInfo = mm:itemStats(itemLink, false)
        return (salesInfo.avgPrice or 0) * (salesInfo.numItems or 0)
    end

    local function GetATTSSalesInfo()
        local fromTimeStamp = GetTimeStamp() - IE.SavedVars.highTradeValue.days * SECONDS_IN_DAY
        local salesInfo = atts:GetItemSalesInformation(itemLink, fromTimeStamp)[itemLink]

        if not salesInfo then return false end

        local averagePrice = atts:GetAveragePricePerItem(itemLink, fromTimeStamp)
        local quantity = 0
        for _, sale in pairs(salesInfo) do
            quantity = quantity + sale.quantity
        end

        return averagePrice * quantity
    end

    local overallTransactionValue = 0
    if atts then
        overallTransactionValue = GetATTSSalesInfo()
    elseif mm then
        overallTransactionValue = GetMMSalesInfo()
    else
        return false
    end

    if overallTransactionValue >= IE.SavedVars.highTradeValue.minPotentialMarketValue then
        return true
    else
        return false
    end
end

local function FilterByHighTradeValue()
    local isFilterEnable = false

    local function Filter(control)
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

    local IsHighTradeValue = IE.HighTradeValue.IsHighTradeValue
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
        isFilterEnable = false
    else
        LF:RegisterFilter("IE_HighTradeValue", LF_INVENTORY, Filter)
        LF:RegisterFilter("IE_HighTradeValue", LF_CRAFTBAG, Filter)
        isFilterEnable = true
    end

    LF:RequestUpdate(LF_INVENTORY)
    LF:RequestUpdate(LF_CRAFTBAG)

    return isFilterEnable
end

local function RefreshFilterByHighTradeValueButton(isFilterEnable)
    local buttons = {
        IE.UI.Controls.InventoryButton,
        IE.UI.Controls.CraftBagButton
    }

    for _, button in pairs(buttons) do
        local texture = button:GetNamedChild("Texture")

        if isFilterEnable then
            texture:SetTexture(button.filterEnabled)
        else
            texture:SetTexture(button.filterDisabled)
        end
    end
end

local function CreateFilterButton(parent)
    local parent = parent
    local button = WINDOW_MANAGER:CreateControlFromVirtual(parent:GetName().."IE_HighTradeValue_Button", parent, "IE_Button")
    local texture = button:GetNamedChild("Texture")
    local highlight = button:GetNamedChild("Highlight")

    texture:SetTexture("esoui/art/tradinghouse/tradinghouse_sell_tabicon_up.dds")
    highlight:SetTexture("esoui/art/tradinghouse/tradinghouse_sell_tabicon_down.dds")

    button:SetDimensions(28, 28)
    button:ClearAnchors()
    button:SetAnchor(BOTTOMLEFT,parent,TOPLEFT,110,-5)
    button:SetClickSound("Click")
    button:SetHidden(true)

    local function OnClicked(thisButton)
        local isFilterEnable = FilterByHighTradeValue()
        RefreshFilterByHighTradeValueButton(isFilterEnable)
    end

    local function OnMouseEnter(thisButton)
        highlight:SetHidden(false)
    end

    local function OnMouseExit()
        highlight:SetHidden(true)
    end

    button:SetHandler("OnClicked", OnClicked)
    button:SetHandler("OnMouseEnter", OnMouseEnter)
    button:SetHandler("OnMouseExit", OnMouseExit)

    button.filterEnabled = "esoui/art/tradinghouse/tradinghouse_sell_tabicon_down.dds"
    button.filterDisabled = "esoui/art/tradinghouse/tradinghouse_sell_tabicon_up.dds"

    return button
end

function IE.HighTradeValue.Init()
    local function IsFeatureEnabled()
        local isFeatureEnabled = IE.SavedVars.highTradeValue.enabled and IsAnySalesAddonLoaded()
        return isFeatureEnabled
    end

    -- Create filter button
    local inventoryButton = CreateFilterButton(ZO_PlayerInventory)
    local craftBagButton = CreateFilterButton(ZO_CraftBag)
    IE.UI.Controls.InventoryButton = inventoryButton
    IE.UI.Controls.CraftBagButton = craftBagButton

    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyShown', function() if IsFeatureEnabled() then inventoryButton:SetHidden(false) else inventoryButton:SetHidden(true) end end)
    ZO_PreHookHandler(ZO_CraftBag, 'OnEffectivelyShown', function() if IsFeatureEnabled() then craftBagButton:SetHidden(false) else craftBagButton:SetHidden(true) end end)
end
