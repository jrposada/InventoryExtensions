local IE = InventoryExtensions
local LR = LibResearch
local LS = LibSets

IE.Junk = {}

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

        local counter = 1
        local function ItemShouldBeJunk(bagId, slotId)
            local _, stackCount, sellPrice, _, _, equipType, itemStyle, quality = GetItemInfo(bagId, slotId)
            if stackCount < 1 then return false end
            local itemLink = GetItemLink(bagId, slotId)
            local itemType, specializedItemType = GetItemLinkItemType(itemLink)

            if IE.SavedVars.autoJunk.miscellaneous.trash and itemType == ITEMTYPE_TRASH then return true -- Trash
            elseif IE.SavedVars.autoJunk.miscellaneous.treasures and itemType == ITEMTYPE_TREASURE then return true -- Treasures
            elseif IE.SavedVars.autoJunk.miscellaneous.monsterTropies and itemType == ITEMTYPE_COLLECTIBLE and specializedItemType == SPECIALIZED_ITEMTYPE_COLLECTIBLE_MONSTER_TROPHY then return true -- Monster trophy
            elseif IE.SavedVars.autoJunk.miscellaneous.treasureMaps and itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP then return true -- Treasures map
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
        local messagePrefix = "[IE:Junk]"
        local message = ""
        for index, data in pairs(bagCache) do
            if ItemShouldBeJunk(data.bagId, data.slotIndex) then
                SetItemIsJunk(data.bagId, data.slotIndex, true)
                local link = GetItemLink(data.bagId, data.slotIndex)
                local texture = GetItemLinkIcon(link)
                message = message..zo_strformat(" |t18:18:<<2>>|t <<t:1>>", link, texture)
                if data.stackCount ~=1 then
                    message = message..zo_strformat(" x <<1>>",data.stackCount)
                end
            end
        end

        if message ~= "" then CHAT_SYSTEM:AddMessage(messagePrefix..message) end
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
    EVENT_MANAGER:RegisterForEvent(IE.name.."_GuildBankOpened", EVENT_OPEN_GUILD_BANK, function() isBankOpen = true end)
    EVENT_MANAGER:RegisterForEvent(IE.name .. "_GuildBankClosed", EVENT_CLOSE_GUILD_BANK, function() isBankOpen = false end)
    EVENT_MANAGER:RegisterForEvent(IE.name.."_TradingHouseOpened", EVENT_OPEN_TRADING_HOUSE, function() isBankOpen = true end)
    EVENT_MANAGER:RegisterForEvent(IE.name .. "_TradingHouseClosed", EVENT_CLOSE_TRADING_HOUSE, function() isBankOpen = false end)
end

function IE.Junk.Init()
    InitAutoJunk()
end