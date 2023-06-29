INVENTORY_EXTENSIONS = {
    name = "InventoryExtensions",
    version = 2,
    varsVersion = 1,
    Localization = {},
    Loc = function(var) return INVENTORY_EXTENSIONS.Localization.en[var] or var end,
    DefaultVars = {
        day = true,
        currencyTracker = {
        },
        autoBind = {
            enabled = true
        },
        ttcPrice = {
            enabled = true
        }
    },
    SavedVars = {}
}