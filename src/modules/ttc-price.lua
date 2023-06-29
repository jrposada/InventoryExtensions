IE_TTC_PRICE = {}

local currencyOptions = {
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
    color = ZO_ColorDef:New(1,0.84,0,1),
}

local function OverridePrice(control, slot)
    local link = GetItemLink(slot.bagId, slot.slotIndex)
    local isBound = IsItemLinkBound(link)
    local priceInfo = TamrielTradeCentrePrice:GetPriceInfo(link)
    local itemValue = priceInfo and (priceInfo.SuggestedPrice or priceInfo.Avg)

    if not isBound and itemValue then
        local sellPriceControl = control:GetNamedChild("SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, math.floor(itemValue), currencyOptions)
    end
end

local function InitInventory(listView)
    if listView and listView.dataTypes and listView.dataTypes[1] then
        ZO_PostHook(
            listView.dataTypes[1],
            "setupCallback",
            function (control, slot)
                OverridePrice(control, slot)
            end
        )
    end
end

local function Init()
    local savedVars = INVENTORY_EXTENSIONS.SavedVars

    if savedVars.ttcPrice.enabled then
        InitInventory(ZO_PlayerInventoryList)
        InitInventory(ZO_PlayerBankBackpack)
        InitInventory(ZO_CraftBagList)
    end
end

function IE_TTC_PRICE.Init()
    Init()
end

function IE_TTC_PRICE.Enable(enable)
    local savedVars = INVENTORY_EXTENSIONS.SavedVars

    savedVars.ttcPrice.enabled = enable
end
