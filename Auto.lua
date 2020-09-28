local IE = InventoryExtensions
local LR = LibResearch
local LS = LibSets

IE.Auto = {}

----------------------
-- START Auto mark --
----------------------

local function InitAutoJunk()
    local isBankOpen = false

    local function RefreshAutoJunkUi()
        if not isBankOpen then
            local button = IE.UI.Controls.AutoStoreButton
            button:SetHidden(false)
        end
    end

    local function AutoJunkItems()
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

        local function IsResearchable(itemLink)
            -- Other research addon compatibiliy here

            local _, isResearchable = LR:GetItemTraitResearchabilityInfo(itemLink)
            return isResearchable
        end

        local function ItemShouldBeJunk(bagId, slotId)
            local _, stackCount, sellPrice, _, _, equipType, itemStyle, quality = GetItemInfo(bagId, slotId)
            if stackCount < 1 then return false end
            local itemLink = GetItemLink(bagId, slotId)
            local itemType, specializedItemType = GetItemLinkItemType(itemLink)

            if IE.SavedVars.autoJunk.miscellaneous.trash and itemType == ITEMTYPE_TRASH then return true -- Trash
            elseif IE.SavedVars.autoJunk.miscellaneous.treasures and itemType == ITEMTYPE_TREASURE then return true -- Treasures
            elseif IE.SavedVars.autoJunk.weaponsArmorJewelry.enabled and (itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON) then
                --exclude crafted items
                if IsItemLinkCrafted(itemLink) then return false end

                local trait = GetItemTrait(bagId, slotId)
                local isResearchable = IsResearchable(itemLink)
        		local isSet, _, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)

                if (isResearchable and IE.SavedVars.autoJunk.weaponsArmorJewelry.excludeResearchable)
                or (isSet and IE.SavedVars.autoJunk.weaponsArmorJewelry.excludedSets[setId] and not LS.IsMythicSet(setId)) then
                    return false
                end

                if not IE.SavedVars.autoJunk.weaponsArmorJewelry.excludeTrait[trait] then
                    if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
                        -- Jewerly
                        if quality <= IE.SavedVars.autoJunk.weaponsArmorJewelry.jewelryQuality then return true end
                    else
                        -- Armor and weapons
                        if quality <= IE.SavedVars.autoJunk.weaponsArmorJewelry.armorWeaponQuality then return true end
                    end
                end
            end

            return false
        end

        local bagCache = SHARED_INVENTORY:GenerateFullSlotData(FilterUnwantedItems, BAG_BACKPACK)
        local message = "IE junk: "
        for index, data in pairs(bagCache) do
            if ItemShouldBeJunk(data.bagId, data.slotIndex) then
                SetItemIsJunk(data.bagId, data.slotIndex, true)
                message = message..zo_strformat("[<<2>>x <<t:1>>]", GetItemLink(data.bagId, data.slotIndex), data.stackCount)
            end
        end

        if message ~= "IE junk: " then CHAT_SYSTEM:AddMessage(message) end
    end

    -- Initialize UI
    local parent = ZO_PlayerInventory
    local button = WINDOW_MANAGER:CreateControlFromVirtual("IE_AutoJunk", parent, "ZO_DefaultButton")
    button:SetWidth(110, 28)
    button:SetText(IE.Loc("AutoJunk"))
    button:ClearAnchors()
    button:SetAnchor(BOTTOMLEFT,parent,TOPLEFT,0,-5)
    button:SetClickSound("Click")
    button:SetHandler("OnClicked", function()AutoJunkItems()end)
    button:SetState(BSTATE_NORMAL)
    button:SetHidden(true)
    button:SetDrawTier(2)
    local controls = IE.UI.Controls
    controls.AutoStoreButton = button

    -- Register for events
    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyShown', function() RefreshAutoJunkUi() end)
    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyHidden', function() button:SetHidden(true) end)
    EVENT_MANAGER:RegisterForEvent(IE.name.."_BankOpened", EVENT_OPEN_BANK, function() isBankOpen = true end)
    EVENT_MANAGER:RegisterForEvent(IE.name .. "_BankClosed", EVENT_CLOSE_BANK, function() isBankOpen = false end)
end

--------------------
-- END Auto mark --
--------------------

-------------------------
-- START Money tracker --
-------------------------

local function UpdateMoneyControlText()
    local incomeControl = IE.UI.Controls.IncomeLabel
    local value = IE.SavedVars.dialyGoldIncome
    incomeControl:SetText("|c008000"..value.."|r |t19:19:esoui/art/currency/currency_gold_32.dds|t")
end

local function OnMoneyUpdate(eventCode, newMoney, oldMoney, reason)
    -- Only record incomes
    if reason ~= CURRENCY_CHANGE_REASON_BUYBACK and (newMoney < oldMoney) or reason == CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL or reason == CURRENCY_CHANGE_REASON_GUILD_BANK_WITHDRAWAL then return end

    local newIncome = newMoney - oldMoney

    IE.SavedVars.dialyGoldIncome = newIncome + IE.SavedVars.dialyGoldIncome
    UpdateMoneyControlText()
end

local function InitDialyGoldIncome()
    -- Check if we need to reset
    local vars = IE.SavedVars
	local day=math.floor(GetDiffBetweenTimeStamps(GetTimeStamp(),1517464800)/86400)
    if (vars.lastDialyGoldIncomeDay ~= day) then
        IE.SavedVars.lastDialyGoldIncomeDay = day
        IE.SavedVars.dialyGoldIncome = 0
    end

    -- Initialize the UI
    -- name, parent, dims, anchor, font, color, align, text, hidden
    local money = ZO_PlayerInventoryInfoBarMoney
    local width = money:GetWidth()
    local height = money:GetHeight()
    local va = money:GetVerticalAlignment()
    local ha = money:GetHorizontalAlignment()

    IE.UI.Controls.IncomeLabel = IE.UI.Label(IE.name.."_PlayerInventoryInfoBarIncome", ZO_PlayerInventoryInfoBarMoney, {width, height}, {TOPRIGHT,BOTTOMRIGHT,0,0}, "ZoFontGameLarge", nil, {ha,va}, "0")
    UpdateMoneyControlText()

    -- Register for gold income event
    EVENT_MANAGER:RegisterForEvent(IE.name .. "MoneyUpdate_Event", EVENT_MONEY_UPDATE, OnMoneyUpdate)
end

-----------------------
-- END Money tracker --
-----------------------

function IE.Auto.Init()
    local vars = IE.SavedVars

    -- Enable only user selected funcitonality
    InitAutoJunk()
    if (vars.dialyGoldIncomeTracker) then InitDialyGoldIncome() end
end
