IE_CURRENCY_TRACKER = {}

function IE_CURRENCY_TRACKER.Init()
    local savedVars = INVENTORY_EXTENSIONS.SavedVars

    local function OnCurrencyUpdate(_, _currencyType_, _currencyLocation_, _newAmount_, _oldAmount_, _reason_, _reasonSupplementaryInfo_)
        local currencyType, newAmount, oldAmount, reason = _currencyType_, _newAmount_, _oldAmount_, _reason_
        local netIncome = newAmount - oldAmount

        if netIncome <= 0
            or reason == CURRENCY_CHANGE_REASON_PLAYER_INIT
            or reason == CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL
            or reason == CURRENCY_CHANGE_REASON_BANK_DEPOSIT
        then return end

        savedVars.currencyTracker[currencyType] = (savedVars.currencyTracker[currencyType] or 0) + netIncome
    end

    -- Check if we need to reset
	local day=math.floor(GetDiffBetweenTimeStamps(GetTimeStamp(),1517464800)/86400)
    if (savedVars.day ~= day) then
        savedVars.day = day
        savedVars.currencyTracker = {}
    end

    -- Override default list setup
    -- esoui\ingame\inventory\inventorywallet.lua
    local baseSetUpEntry = INVENTORY_WALLET.SetUpEntry
    local SetUpEntry = function(self, control, data)
        baseSetUpEntry(self, control, data)

        local value = savedVars.currencyTracker[data.currencyType] or 0
        local text = ZO_CurrencyControl_FormatAndLocalizeCurrency(
            value
        )
        if value > 0 then text = "|c32CD32"..text.."|r"
        elseif value < 0 then text = "|cB21818"..text.."|r" end

        local controls = LibPanicida.Controls
        controls.Label({
            name = control:GetName()..INVENTORY_EXTENSIONS.name..data.currencyType,
            parent = control,
            dims = {70, 20},
            anchor = {RIGHT,control,RIGHT,-6,17},
            font = "ZoFontGameSmall",
            align ={2,2},
             text = text
        })
    end
    INVENTORY_WALLET.SetUpEntry = SetUpEntry

    EVENT_MANAGER:RegisterForEvent(INVENTORY_EXTENSIONS.name .. "CurrencyTraker", EVENT_CURRENCY_UPDATE, OnCurrencyUpdate)
end

-- local function DebugCurrencyChangeReasonName(reason)
--     local reasonName = ''
--     if reason == CURRENCY_CHANGE_REASON_ABILITY_UPGRADE_PURCHASE then
--         reasonName = "* CURRENCY_CHANGE_REASON_ABILITY_UPGRADE_PURCHASE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_ACHIEVEMENT then
--         reasonName = "* CURRENCY_CHANGE_REASON_ACHIEVEMENT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_ACTION then
--         reasonName = "* CURRENCY_CHANGE_REASON_ACTION"
--     end
--     if reason == CURRENCY_CHANGE_REASON_ANTIQUITY_REWARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_ANTIQUITY_REWARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BAGSPACE then
--         reasonName = "* CURRENCY_CHANGE_REASON_BAGSPACE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BANKSPACE then
--         reasonName = "* CURRENCY_CHANGE_REASON_BANKSPACE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BANK_DEPOSIT then
--         reasonName = "* CURRENCY_CHANGE_REASON_BANK_DEPOSIT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BANK_FEE then
--         reasonName = "* CURRENCY_CHANGE_REASON_BANK_FEE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL then
--         reasonName = "* CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BATTLEGROUND then
--         reasonName = "* CURRENCY_CHANGE_REASON_BATTLEGROUND"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BOUNTY_CONFISCATED then
--         reasonName = "* CURRENCY_CHANGE_REASON_BOUNTY_CONFISCATED"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BOUNTY_PAID_FENCE then
--         reasonName = "* CURRENCY_CHANGE_REASON_BOUNTY_PAID_FENCE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BOUNTY_PAID_GUARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_BOUNTY_PAID_GUARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_BUYBACK then
--         reasonName = "* CURRENCY_CHANGE_REASON_BUYBACK"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CASH_ON_DELIVERY then
--         reasonName = "* CURRENCY_CHANGE_REASON_CASH_ON_DELIVERY"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CHARACTER_UPGRADE then
--         reasonName = "* CURRENCY_CHANGE_REASON_CHARACTER_UPGRADE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_COMMAND then
--         reasonName = "* CURRENCY_CHANGE_REASON_COMMAND"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CONSUME_FOOD_DRINK then
--         reasonName = "* CURRENCY_CHANGE_REASON_CONSUME_FOOD_DRINK"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CONSUME_POTION then
--         reasonName = "* CURRENCY_CHANGE_REASON_CONSUME_POTION"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CONVERSATION then
--         reasonName = "* CURRENCY_CHANGE_REASON_CONVERSATION"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CRAFT then
--         reasonName = "* CURRENCY_CHANGE_REASON_CRAFT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CROWNS_PURCHASED then
--         reasonName = "* CURRENCY_CHANGE_REASON_CROWNS_PURCHASED"
--     end
--     if reason == CURRENCY_CHANGE_REASON_CROWN_CRATE_DUPLICATE then
--         reasonName = "* CURRENCY_CHANGE_REASON_CROWN_CRATE_DUPLICATE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_DEATH then
--         reasonName = "* CURRENCY_CHANGE_REASON_DEATH"
--     end
--     if reason == CURRENCY_CHANGE_REASON_DECONSTRUCT then
--         reasonName = "* CURRENCY_CHANGE_REASON_DECONSTRUCT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_DEFENSIVE_KEEP_REWARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_DEFENSIVE_KEEP_REWARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_DEPRECATED_0 then
--         reasonName = "* CURRENCY_CHANGE_REASON_DEPRECATED_0"
--     end
--     if reason == CURRENCY_CHANGE_REASON_DEPRECATED_1 then
--         reasonName = "* CURRENCY_CHANGE_REASON_DEPRECATED_1"
--     end
--     if reason == CURRENCY_CHANGE_REASON_DEPRECATED_2 then
--         reasonName = "* CURRENCY_CHANGE_REASON_DEPRECATED_2"
--     end
--     if reason == CURRENCY_CHANGE_REASON_EDIT_GUILD_HERALDRY then
--         reasonName = "* CURRENCY_CHANGE_REASON_EDIT_GUILD_HERALDRY"
--     end
--     if reason == CURRENCY_CHANGE_REASON_FEED_MOUNT then
--         reasonName = "* CURRENCY_CHANGE_REASON_FEED_MOUNT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_GUILD_BANK_DEPOSIT then
--         reasonName = "* CURRENCY_CHANGE_REASON_GUILD_BANK_DEPOSIT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_GUILD_BANK_WITHDRAWAL then
--         reasonName = "* CURRENCY_CHANGE_REASON_GUILD_BANK_WITHDRAWAL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_GUILD_FORWARD_CAMP then
--         reasonName = "* CURRENCY_CHANGE_REASON_GUILD_FORWARD_CAMP"
--     end
--     if reason == CURRENCY_CHANGE_REASON_GUILD_STANDARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_GUILD_STANDARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_GUILD_TABARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_GUILD_TABARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_HARVEST_REAGENT then
--         reasonName = "* CURRENCY_CHANGE_REASON_HARVEST_REAGENT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_ITEM_CONVERTED_TO_GEMS then
--         reasonName = "* CURRENCY_CHANGE_REASON_ITEM_CONVERTED_TO_GEMS"
--     end
--     if reason == CURRENCY_CHANGE_REASON_JUMP_FAILURE_REFUND then
--         reasonName = "* CURRENCY_CHANGE_REASON_JUMP_FAILURE_REFUND"
--     end
--     if reason == CURRENCY_CHANGE_REASON_KEEP_REPAIR then
--         reasonName = "* CURRENCY_CHANGE_REASON_KEEP_REPAIR"
--     end
--     if reason == CURRENCY_CHANGE_REASON_KEEP_UPGRADE then
--         reasonName = "* CURRENCY_CHANGE_REASON_KEEP_UPGRADE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_KILL then
--         reasonName = "* CURRENCY_CHANGE_REASON_KILL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_LOOT then
--         reasonName = "* CURRENCY_CHANGE_REASON_LOOT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_LOOT_CURRENCY_CONTAINER then
--         reasonName = "* CURRENCY_CHANGE_REASON_LOOT_CURRENCY_CONTAINER"
--     end
--     if reason == CURRENCY_CHANGE_REASON_LOOT_STOLEN then
--         reasonName = "* CURRENCY_CHANGE_REASON_LOOT_STOLEN"
--     end
--     if reason == CURRENCY_CHANGE_REASON_MAIL then
--         reasonName = "* CURRENCY_CHANGE_REASON_MAIL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_MEDAL then
--         reasonName = "* CURRENCY_CHANGE_REASON_MEDAL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_OFFENSIVE_KEEP_REWARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_OFFENSIVE_KEEP_REWARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PICKPOCKET then
--         reasonName = "* CURRENCY_CHANGE_REASON_PICKPOCKET"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PLAYER_INIT then
--         reasonName = "* CURRENCY_CHANGE_REASON_PLAYER_INIT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PURCHASED_WITH_CROWNS then
--         reasonName = "* CURRENCY_CHANGE_REASON_PURCHASED_WITH_CROWNS"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PURCHASED_WITH_ENDEAVOR_SEALS then
--         reasonName = "* CURRENCY_CHANGE_REASON_PURCHASED_WITH_ENDEAVOR_SEALS"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PURCHASED_WITH_GEMS then
--         reasonName = "* CURRENCY_CHANGE_REASON_PURCHASED_WITH_GEMS"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PVP_KILL_TRANSFER then
--         reasonName = "* CURRENCY_CHANGE_REASON_PVP_KILL_TRANSFER"
--     end
--     if reason == CURRENCY_CHANGE_REASON_PVP_RESURRECT then
--         reasonName = "* CURRENCY_CHANGE_REASON_PVP_RESURRECT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_QUESTREWARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_QUESTREWARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RECIPE then
--         reasonName = "* CURRENCY_CHANGE_REASON_RECIPE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RECONSTRUCTION then
--         reasonName = "* CURRENCY_CHANGE_REASON_RECONSTRUCTION"
--     end
--     if reason == CURRENCY_CHANGE_REASON_REFORGE then
--         reasonName = "* CURRENCY_CHANGE_REASON_REFORGE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RESEARCH_TRAIT then
--         reasonName = "* CURRENCY_CHANGE_REASON_RESEARCH_TRAIT"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RESPEC_ATTRIBUTES then
--         reasonName = "* CURRENCY_CHANGE_REASON_RESPEC_ATTRIBUTES"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RESPEC_CHAMPION then
--         reasonName = "* CURRENCY_CHANGE_REASON_RESPEC_CHAMPION"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RESPEC_MORPHS then
--         reasonName = "* CURRENCY_CHANGE_REASON_RESPEC_MORPHS"
--     end
--     if reason == CURRENCY_CHANGE_REASON_RESPEC_SKILLS then
--         reasonName = "* CURRENCY_CHANGE_REASON_RESPEC_SKILLS"
--     end
--     if reason == CURRENCY_CHANGE_REASON_REWARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_REWARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_SELL_STOLEN then
--         reasonName = "* CURRENCY_CHANGE_REASON_SELL_STOLEN"
--     end
--     if reason == CURRENCY_CHANGE_REASON_SOULWEARY then
--         reasonName = "* CURRENCY_CHANGE_REASON_SOULWEARY"
--     end
--     if reason == CURRENCY_CHANGE_REASON_SOUL_HEAL then
--         reasonName = "* CURRENCY_CHANGE_REASON_SOUL_HEAL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_STABLESPACE then
--         reasonName = "* CURRENCY_CHANGE_REASON_STABLESPACE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_STUCK then
--         reasonName = "* CURRENCY_CHANGE_REASON_STUCK"
--     end
--     if reason == CURRENCY_CHANGE_REASON_TRADE then
--         reasonName = "* CURRENCY_CHANGE_REASON_TRADE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_TRADINGHOUSE_LISTING then
--         reasonName = "* CURRENCY_CHANGE_REASON_TRADINGHOUSE_LISTING"
--     end
--     if reason == CURRENCY_CHANGE_REASON_TRADINGHOUSE_PURCHASE then
--         reasonName = "* CURRENCY_CHANGE_REASON_TRADINGHOUSE_PURCHASE"
--     end
--     if reason == CURRENCY_CHANGE_REASON_TRADINGHOUSE_REFUND then
--         reasonName = "* CURRENCY_CHANGE_REASON_TRADINGHOUSE_REFUND"
--     end
--     if reason == CURRENCY_CHANGE_REASON_TRAIT_REVEAL then
--         reasonName = "* CURRENCY_CHANGE_REASON_TRAIT_REVEAL"
--     end
--     if reason == CURRENCY_CHANGE_REASON_TRAVEL_GRAVEYARD then
--         reasonName = "* CURRENCY_CHANGE_REASON_TRAVEL_GRAVEYARD"
--     end
--     if reason == CURRENCY_CHANGE_REASON_UNKNOWN then
--         reasonName = "* CURRENCY_CHANGE_REASON_UNKNOWN"
--     end
--     if reason == CURRENCY_CHANGE_REASON_VENDOR then
--         reasonName = "* CURRENCY_CHANGE_REASON_VENDOR"
--     end
--     if reason == CURRENCY_CHANGE_REASON_VENDOR_LAUNDER then
--         reasonName = "* CURRENCY_CHANGE_REASON_VENDOR_LAUNDER"
--     end
--     if reason == CURRENCY_CHANGE_REASON_VENDOR_REPAIR then
--         reasonName = "* CURRENCY_CHANGE_REASON_VENDOR_REPAIR"
--     end
--     IE.LogLater('reason: '..reasonName)
-- end