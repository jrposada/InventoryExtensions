local AGS = AwesomeGuildStore
local TTC = TamrielTradeCentre
local TTCPrice = TamrielTradeCentrePrice

IE_TTC_PRICE = {}

local currencyOptions = {
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
    color = ZO_ColorDef:New(1, 0.84, 0, 1),
}

local function SetPriceControl(link, control)
    local isBound = IsItemLinkBound(link)
    local priceInfo = TTCPrice:GetPriceInfo(link)

    if priceInfo then
        local ttcPriceSaleAvg = priceInfo.SaleAvg or priceInfo.Avg
        local ttcPriceSuggestedPrice = priceInfo.SuggestedPrice or priceInfo.Avg

        -- Use suggested
        local ttcUnitItemPrice = ttcPriceSuggestedPrice
        if ttcPriceSaleAvg < ttcPriceSuggestedPrice then
            -- unless sale avg is less
            ttcUnitItemPrice = ttcPriceSaleAvg
        end
        if isBound or not ttcUnitItemPrice then
            return
        end


        if not isBound and ttcUnitItemPrice then
            local sellPriceControl = control:GetNamedChild("SellPrice")
            ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, math.floor(ttcUnitItemPrice),
                currencyOptions)
        end
    end

    -- TODO: move
    local isCrafted = IsItemLinkCrafted(link)
    local isConsumable = IsItemLinkConsumable(link)

    if isConsumable and isCrafted then
        local traitInfoControl = control:GetNamedChild("TraitInfo")
        traitInfoControl:ClearIcons()

        traitInfoControl:AddIcon("esoui/art/icons/poi/poi_crafting_complete.dds")
        traitInfoControl:Show()
    end
end


local function SetSearchPriceControl(link, control, result)
    local isBound = IsItemLinkBound(link)
    local ttcPriceInfo = TTCPrice:GetPriceInfo(link)

    if not ttcPriceInfo then
        return
    end

    local ttcPriceSaleAvg = ttcPriceInfo.SaleAvg or ttcPriceInfo.Avg
    local ttcPriceSuggestedPrice = ttcPriceInfo.SuggestedPrice or ttcPriceInfo.Avg

    -- Use suggested
    local ttcUnitItemPrice = ttcPriceSuggestedPrice
    if ttcPriceSaleAvg < ttcPriceSuggestedPrice then
        -- unless sale avg is less
        ttcUnitItemPrice = ttcPriceSaleAvg
    end
    if isBound or not ttcUnitItemPrice then
        return
    end

    local perItemPriceControl = control.perItemPrice
    local sellPriceControl = control.sellPriceControl
    local stackCount = result:GetStackCount()
    local purchasePrice = result.purchasePrice
    local profit = ttcUnitItemPrice * stackCount - purchasePrice
    local unitProfit = ttcUnitItemPrice - purchasePrice / stackCount
    local profitMargin = (profit) * 100 / ttcUnitItemPrice -- in %

    local formattedProfit = ZO_CurrencyControl_FormatAndLocalizeCurrency(
        zo_roundToNearest(profit, 0.01),
        profit >= 100000
    )
    local formattedUnitProfit = ZO_CurrencyControl_FormatAndLocalizeCurrency(
        zo_roundToNearest(unitProfit, 0.01),
        unitProfit >= 100000
    )

    if (profitMargin <= 15 or profit <= 3000) then
        return
    elseif profitMargin <= 30 then
        formattedProfit = "|c32CD32+" .. formattedProfit .. "|r"         -- green
        formattedUnitProfit = "|c32CD32+" .. formattedUnitProfit .. "|r" -- green
    elseif profitMargin <= 40 then
        formattedProfit = "|c398df7+" .. formattedProfit .. "|r"         -- blue
        formattedUnitProfit = "|c398df7+" .. formattedUnitProfit .. "|r" -- blue
    elseif profitMargin <= 50 then
        formattedProfit = "|c9e2df4+" .. formattedProfit .. "|r"         -- purple
        formattedUnitProfit = "|c9e2df4+" .. formattedUnitProfit .. "|r" -- purple
    else
        formattedProfit = "|cFFD700+" .. formattedProfit .. "|r"         -- gold
        formattedUnitProfit = "|cFFD700+" .. formattedUnitProfit .. "|r" -- gold
    end

    -- FIXME: fix writs prices. Stacks are counted per writ instead per item. So prices are inflated.

    sellPriceControl:SetText(formattedProfit ..
        " - " .. sellPriceControl:GetText():gsub("|t.-:.-:", "|t14:14:"))

    if stackCount > 1 then
        perItemPriceControl:SetText("@" ..
            formattedUnitProfit .. " - " .. perItemPriceControl:GetText():gsub("|t.-:.-:", "|t14:14:"):gsub("@", ""))
    end
end

local function OverrideInventoryPrice(control, slot)
    local link = GetItemLink(slot.bagId, slot.slotIndex)
    if link == nil or not TTC:IsItemLink(link) then
        return
    end

    SetPriceControl(link, control)
end

local function OverrideStoreSearchPrice(control, result)
    local inventorySlot = ZO_InventorySlot_GetInventorySlotComponents(control)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    if slotType ~= SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT then
        return
    end

    local tradingHouseIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
    local link = GetTradingHouseSearchResultItemLink(tradingHouseIndex)
    if link == nil or not TTC:IsItemLink(link) then
        return
    end

    SetSearchPriceControl(link, control, result)
end


local function InitInventory(dataType)
    if dataType then
        ZO_PostHook(
            dataType,
            "setupCallback",
            function(control, slot)
                OverrideInventoryPrice(control, slot)
            end
        )
    end
end

local function InitStoreSearch(dataType)
    if dataType then
        ZO_PostHook(
            dataType,
            "setupCallback",
            function(control, slot)
                OverrideStoreSearchPrice(control, slot)
            end
        )
    end
end

local function Init()
    local savedVars = INVENTORY_EXTENSIONS.SavedVars

    if savedVars.ttcPrice.enabled then
        InitInventory(ZO_PlayerInventoryList.dataTypes[1])
        InitInventory(ZO_PlayerBankBackpack.dataTypes[1])
        InitInventory(ZO_CraftBagList.dataTypes[1])

        local originalAgsInitializeResultList = AGS.class.SearchResultListWrapper.InitializeResultList
        AGS.class.SearchResultListWrapper.InitializeResultList = function(self, tradingHouseWrapper, searchManager)
            originalAgsInitializeResultList(self, tradingHouseWrapper, searchManager)
            local searchResultDataType = ZO_ScrollList_GetDataTypeTable(self.list.list, 1)
            InitStoreSearch(searchResultDataType)
        end

        -- local searchResultDataType = ZO_ScrollList_GetDataTypeTable(list.list, SEARCH_RESULTS_DATA_TYPE)
        -- local originalSearchResultSetupCallback = searchResultDataType.setupCallback

        -- IE.LogLater('p[acooo]')
        -- IE.LogLater(AwesomeGuildStore.internal.tradingHouse.searchResultList)
    end
end

function IE_TTC_PRICE.Init()
    Init()
end

function IE_TTC_PRICE.Enable(enable)
    local savedVars = INVENTORY_EXTENSIONS.SavedVars

    savedVars.ttcPrice.enabled = enable
end
