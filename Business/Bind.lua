local IE = InventoryExtensions

IE.Bind = {}

local function InitAutoBind()
    local function RefreshAutoBindUi()
        if not IE.Events.isBankOpen then
            local button = IE.UI.Controls.AutoBindButton
            button:SetHidden(false)
        end
    end

    local function AutoBindItems()
        local function FilterUnwantedItems(itemData)
            return true
        end

        local function ItemShouldBeBind(bagId, slotId)
            local _, stackCount, sellPrice, _, _, equipType, itemStyle, quality = GetItemInfo(bagId, slotId)
            if stackCount < 1 then return false end
            local itemLink = GetItemLink(bagId, slotId)
            local itemId = GetItemLinkItemId(itemLink)
            local itemType, specializedItemType = GetItemLinkItemType(itemLink)

            if (itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON) then
                local isSetCollectionPiece = IsItemLinkSetCollectionPiece(itemLink)
                local isUnlocked = IsItemSetCollectionPieceUnlocked(itemId)
                local isBound = IsItemLinkBound(itemLink)

                if not isBound and isSetCollectionPiece  and not isUnlocked then return true end
            end

            return false
        end

        local bagCache = SHARED_INVENTORY:GenerateFullSlotData(FilterUnwantedItems, BAG_BACKPACK)
        local chatMessage = ChatMessage:New("[IE:Bind] ")
        local didSomething = false
        for index, data in pairs(bagCache) do
            if ItemShouldBeBind(data.bagId, data.slotIndex) then
                didSomething = true
                BindItem(data.bagId, data.slotIndex)
                local link = GetItemLink(data.bagId, data.slotIndex)
                local texture = GetItemLinkIcon(link)
                local message = zo_strformat(" |t18:18:<<2>>|t <<t:1>>", link, texture)
                if data.stackCount ~=1 then
                    message = message..zo_strformat(" x <<1>>",data.stackCount)
                end
                chatMessage:AddMessage(message)
            end
        end

        if not didSomething then
            chatMessage:AddMessage(IE.Loc("AllDone"))
        end

        chatMessage:Submit()
    end

    -- Initialize UI
    local parent = ZO_PlayerInventory
    local button = WINDOW_MANAGER:CreateControlFromVirtual("IE_AutoBind", parent, "ZO_DefaultButton")
    button:SetWidth(110, 32)
    button:SetText(IE.Loc("AutoBind"))
    button:ClearAnchors()
    button:SetAnchor(BOTTOMLEFT,parent,TOPLEFT,0,-40)
    button:SetClickSound("Click")
    button:SetHandler("OnClicked", function()AutoBindItems()end)
    button:SetState(BSTATE_NORMAL)
    button:SetHidden(true)
    button:SetDrawTier(2)
    local controls = IE.UI.Controls
    controls.AutoBindButton = button

    -- Register for events
    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyShown', function() RefreshAutoBindUi() end)
    ZO_PreHookHandler(ZO_PlayerInventory, 'OnEffectivelyHidden', function() button:SetHidden(true) end)
end

function IE.Bind.Init()
    InitAutoBind()
end