IE = InventoryExtensions
EM = EVENT_MANAGER

IE.Events = {
    isBankOpen = false
}

function IE.Events.Init()
    EM:RegisterForEvent(IE.name.."_BankOpened", EVENT_OPEN_BANK, function() IE.Events.isBankOpen = true end)
    EM:RegisterForEvent(IE.name .. "_BankClosed", EVENT_CLOSE_BANK, function() IE.Events.isBankOpen = false end)
    EM:RegisterForEvent(IE.name.."_GuildBankOpened", EVENT_OPEN_GUILD_BANK, function() IE.Events.isBankOpen = true end)
    EM:RegisterForEvent(IE.name .. "_GuildBankClosed", EVENT_CLOSE_GUILD_BANK, function() IE.Events.isBankOpen = false end)
    EM:RegisterForEvent(IE.name.."_TradingHouseOpened", EVENT_OPEN_TRADING_HOUSE, function() IE.Events.isBankOpen = true end)
    EM:RegisterForEvent(IE.name .. "_TradingHouseClosed", EVENT_CLOSE_TRADING_HOUSE, function() IE.Events.isBankOpen = false end)
end