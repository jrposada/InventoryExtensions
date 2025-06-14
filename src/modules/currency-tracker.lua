IE_CURRENCY_TRACKER = {}

function IE_CURRENCY_TRACKER.Init()
    local savedVars = INVENTORY_EXTENSIONS.SavedVars
    local namePrefix = INVENTORY_EXTENSIONS.name
    local floor = math.floor
    local controls = LibPanicida.Controls

    local function OnCurrencyUpdate(_, currencyType, _, newAmount, oldAmount, reason)
        local netIncome = newAmount - oldAmount
        if netIncome <= 0
            or reason == CURRENCY_CHANGE_REASON_PLAYER_INIT
            or reason == CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL
            or reason == CURRENCY_CHANGE_REASON_BANK_DEPOSIT
        then return end

        local tracker = savedVars.currencyTracker
        tracker[currencyType] = (tracker[currencyType] or 0) + netIncome
    end

    -- Reset currency tracker once per day
    local today = floor(GetDiffBetweenTimeStamps(GetTimeStamp(), 1517464800) / 86400)
    if savedVars.day ~= today then
        savedVars.day = today
        savedVars.currencyTracker = {}
    end

    -- Override default inventory wallet entry setup @see esoui\ingame\inventory\inventorywallet.lua
    local baseSetUpEntry = INVENTORY_WALLET.SetUpEntry
    INVENTORY_WALLET.SetUpEntry = function(self, control, data)
        baseSetUpEntry(self, control, data)

        local value = savedVars.currencyTracker[data.currencyType] or 0
        local text = ZO_CurrencyControl_FormatAndLocalizeCurrency(value)
        if value > 0 then
            text = "|c32CD32" .. text .. "|r"
        elseif value < 0 then
            text = "|cB21818" .. text .. "|r"
        end

        local labelName = control:GetName() .. namePrefix .. data.currencyType
        controls.Label(
            labelName,
            control,
            {70, 20},
            {RIGHT, control, RIGHT, -6, 17},
            "ZoFontGameSmall",
            nil,
            {2, 2},
            text,
            false
        )

    end

    EVENT_MANAGER:RegisterForEvent(namePrefix .. "CurrencyTracker", EVENT_CURRENCY_UPDATE, OnCurrencyUpdate)
end
