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
    local itemValue = priceInfo and (priceInfo.SuggestedPrice or priceInfo.Avg)

    if not isBound and itemValue then
        local sellPriceControl = control:GetNamedChild("SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, math.floor(itemValue), currencyOptions)
    end
end


local function SetSearchPriceControl(link, control, result)
    local isBound = IsItemLinkBound(link)
    local priceInfo = TTCPrice:GetPriceInfo(link)
    local itemValue = priceInfo and (priceInfo.SuggestedPrice or priceInfo.Avg)

    if not isBound and itemValue then
        local perItemPrice = control.perItemPrice
        local sellPriceControl = control.sellPriceControl
        local stackCount = result:GetStackCount()
        local stackValue = ZO_CurrencyControl_FormatAndLocalizeCurrency(itemValue * stackCount, true)

        -- TODO: fix writs prices. Stacks are counted per writ instead per item. So prices are inflated.

        sellPriceControl:SetText(stackValue .. " - " .. sellPriceControl:GetText():gsub("|t.-:.-:", "|t14:14:"))

        if stackCount > 1 then
            perItemPrice:SetText("@" .. itemValue .. " - " .. perItemPrice:GetText():gsub("|t.-:.-:", "|t14:14:"):gsub("@",""))
        end
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
