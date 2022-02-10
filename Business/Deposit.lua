local IE = InventoryExtensions
local LR = LibResearch
local UT = UnknownTracker
local CurrencyTypes = IE.Constants.CurrencyTypes

IE.Deposit = {}

local INTRINCATE_TYPES = {
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = true,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = true,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = true,
}

function IE.Deposit.Init()
    local function TryPlaceItemInEmptySlot(sourceBag, sourceSlot, targetBag, stackCount, usedEmptySlots)
        local function FindEmptySlotInBag(targetBag)
            for slotIndex = 0, (GetBagSize(targetBag) - 1) do
                if not SHARED_INVENTORY.bagCache[targetBag][slotIndex] and not usedEmptySlots[targetBag][slotIndex] then
                    usedEmptySlots[targetBag][slotIndex] = true
                    return slotIndex
                end
            end
            return nil
        end

        local function MoveItem(sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
            -- This call is not inmediate. Hence the need to keep track of used slots.
            CallSecureProtected("RequestMoveItem", sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
        end

        local emptySlot = FindEmptySlotInBag(targetBag)

        -- Special case handling ESO+ members because they actually have access to two separate different bank bags!
        if not emptySlot and IsESOPlusSubscriber() then
            if targetBag == BAG_BANK then
                targetBag = BAG_SUBSCRIBER_BANK
                emptySlot = FindEmptySlotInBag(targetBag)
            elseif targetBag == BAG_SUBSCRIBER_BANK then
                targetBag = BAG_BANK
                emptySlot = FindEmptySlotInBag(targetBag)
            end
        end

        if emptySlot ~= nil then
            MoveItem(sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
            return true
        else
            local errorStringId = SI_INVENTORY_ERROR_BANK_FULL
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, errorStringId)
            return false
        end
    end

    local function FilterUnwantedItems(itemData)
        local isStolen = itemData.stolen
        local isJunk = itemData.isJunk
        local isProtected = itemData.isPlayerLocked
        if isStolen or isJunk or isProtected then
          return false
        else
          return true
        end
    end

    local function RefreshDepositButton(isInventoryHidden)
        local depositButton = IE.UI.Controls.DepositButton
        if IE.Events.isBankOpen then
            depositButton:SetHidden(isInventoryHidden)
        else
            depositButton:SetHidden(true)
        end
    end

    local function RefreshWithdrawButton(isBankHidden)
        local withdrawButton = IE.UI.Controls.WithdrawButton
        withdrawButton:SetHidden(isBankHidden)
    end

    local function AutoDeposit()
        local usedEmptySlots = {
            [BAG_BANK] = {},
            [BAG_SUBSCRIBER_BANK] = {}
        }

        local function ItemShouldBeDeposit(bagId, slotId)
            local function IsIntricateType(traitType)
                local intricateTypes = INTRINCATE_TYPES
                return intricateTypes[traitType]
            end

            local function IsResearchable(itemLink)
                -- Other research addon compatibiliy here

                local _, isResearchable = LR:GetItemTraitResearchabilityInfo(itemLink)
                return isResearchable
            end

            local function IsKnown(itemLink)
                local isKnown = true
                if UT then
                    local isValid, knownByNameList, isGear = UT:IsValidAndWhoKnowsIt(itemLink)
                    return isValid and knownByNameList[IE.CurrentCharacterName] or true
                end
                return isKnown
            end

            local _, stackCount, sellPrice, _, _, equipType, itemStyle, quality = GetItemInfo(bagId, slotId)
            if stackCount < 1 then return false end
            local itemLink = GetItemLink(bagId, slotId)
            local itemType, specializedItemType = GetItemLinkItemType(itemLink)

            if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
                --exclude crafted items
                if IsItemLinkCrafted(itemLink) then return false end

                local trait = GetItemTrait(bagId, slotId)
                local isResearchable = IsResearchable(itemLink)
                local isIntrincate = IsIntricateType(trait)

                if isResearchable and IE.SavedVars.deposit.researchable then return true -- Researchable
                elseif isIntrincate and IE.SavedVars.deposit.intrincate then return true -- Intrincate
                end
            elseif itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT and IE.SavedVars.deposit.surveyMaps then return true -- Survey maps
            elseif (itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON) and IE.SavedVars.deposit.glyphs then return true -- Glyphs
            elseif itemType == ITEMTYPE_RECIPE and IE.SavedVars.deposit.recipes then return IsKnown(itemLink) -- Recipes
            end

            return false
        end

        local bagCache = SHARED_INVENTORY:GenerateFullSlotData(FilterUnwantedItems, BAG_BACKPACK)
        local messagePrefix = "[IE:"..IE.Loc("Deposit")..")"
        local message = ""
        for index, data in pairs(bagCache) do
            if ItemShouldBeDeposit(data.bagId, data.slotIndex) then
                if TryPlaceItemInEmptySlot(data.bagId, data.slotIndex, BAG_BANK, data.stackCount, usedEmptySlots) then
                    local link = GetItemLink(data.bagId, data.slotIndex)
                    local texture = GetItemLinkIcon(link)
                    message = message..zo_strformat(" |t18:18:<<2>>|t <<t:1>>", link, texture)
                    if data.stackCount ~=1 then
                        message = message..zo_strformat(" x <<1>>",data.stackCount)
                    end
                else
                    IE.LogLater(IE.Loc("StoreError"))
                    break
                end
            end
        end
        local currentGold = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
        if IE.SavedVars.deposit.gold.enabled and currentGold > IE.SavedVars.deposit.gold.keep then
            local goldToDeposit = currentGold - IE.SavedVars.deposit.gold.keep
            TransferCurrency(CURT_MONEY, goldToDeposit, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_BANK)
            message = message..zo_strformat(" |t18:18:<<2>>|t <<t:1>>", goldToDeposit, CurrencyTypes[CURT_MONEY])
        end

        if message ~= "" then
            CHAT_SYSTEM:AddMessage(messagePrefix..message)
        else
            CHAT_SYSTEM:AddMessage(messagePrefix..IE.Loc("AllDone"))
        end
    end

    local function AutoWithdraw()
        local usedEmptySlots = {
            [BAG_BACKPACK] = {}
        }

        local function ItemShouldBeWithdraw(bagId, slotId)
            local _, stackCount, sellPrice, _, _, equipType, itemStyle, quality = GetItemInfo(bagId, slotId)
            if stackCount < 1 then return false end
            local itemLink = GetItemLink(bagId, slotId)
            local itemType, specializedItemType = GetItemLinkItemType(itemLink)

            if itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT and IE.SavedVars.withdraw.surveyMaps then return true -- Survey maps
            end

            return false
        end

        local bagCache = SHARED_INVENTORY:GenerateFullSlotData(function () return true end, BAG_BANK, BAG_SUBSCRIBER_BANK)
        local messagePrefix = "[IE:"..IE.Loc("Withdraw").."]"
        local message = ""
        for index, data in pairs(bagCache) do
            if ItemShouldBeWithdraw(data.bagId, data.slotIndex) then
                IE.LogLater(GetItemLink(data.bagId, data.slotIndex))
                if TryPlaceItemInEmptySlot(data.bagId, data.slotIndex, BAG_BACKPACK, data.stackCount, usedEmptySlots) then
                    local link = GetItemLink(data.bagId, data.slotIndex)
                    local texture = GetItemLinkIcon(link)
                    message = message..zo_strformat(" |t18:18:<<2>>|t <<t:1>>", link, texture)
                    if data.stackCount ~=1 then
                        message = message..zo_strformat(" x <<1>>",data.stackCount)
                    end
                else
                    IE.LogLater(IE.Loc("WithdrawError"))
                    break
                end
            end
        end

        if message ~= "" then
            CHAT_SYSTEM:AddMessage(messagePrefix..message)
        else
            CHAT_SYSTEM:AddMessage(messagePrefix..IE.Loc("AllDone"))
        end
    end

    -- Initialize UI
    local depositParent = ZO_PlayerInventory
    local depositButton = WINDOW_MANAGER:CreateControlFromVirtual("BE_Deposit", depositParent, "ZO_DefaultButton")
    depositButton:SetWidth(110, 28)
    depositButton:SetText(IE.Loc("DepositButtonText"))
    depositButton:ClearAnchors()
    depositButton:SetAnchor(BOTTOMLEFT,depositParent,TOPLEFT,0,-5)
    depositButton:SetClickSound("Click")
    depositButton:SetHandler("OnClicked", function()AutoDeposit()end)
    depositButton:SetState(BSTATE_NORMAL)
    depositButton:SetHidden(true)
    depositButton:SetDrawTier(2)

    local withdrawParent = ZO_PlayerBank
    local withdrawButton = WINDOW_MANAGER:CreateControlFromVirtual("BE_Withdraw", withdrawParent, "ZO_DefaultButton")
    withdrawButton:SetWidth(110, 28)
    withdrawButton:SetText(IE.Loc("WithdrawButtonText"))
    withdrawButton:ClearAnchors()
    withdrawButton:SetAnchor(BOTTOMLEFT,withdrawParent,TOPLEFT,0,-5)
    withdrawButton:SetClickSound("Click")
    withdrawButton:SetHandler("OnClicked", function()AutoWithdraw()end)
    withdrawButton:SetState(BSTATE_NORMAL)
    withdrawButton:SetHidden(true)
    withdrawButton:SetDrawTier(2)

    local controls = IE.UI.Controls
    controls.DepositButton = depositButton
    controls.WithdrawButton = withdrawButton

    -- Register for events
    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyShown', function() RefreshDepositButton(false) end)
    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyHidden', function() RefreshDepositButton(true) end)
    ZO_PreHookHandler(ZO_PlayerBank, 'OnEffectivelyShown', function() RefreshWithdrawButton(false) end)
    ZO_PreHookHandler(ZO_PlayerBank, 'OnEffectivelyHidden', function() RefreshWithdrawButton(true) end)
end
