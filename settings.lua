data:extend({
    {
        type = "double-setting",
        name = "resourceful-biters-enemy-resources-per-hp",
        setting_type = "runtime-global",
        default_value = 1.0,
        minimum_value = 0.0,
    },
    {
        type = "double-setting",
        name = "resourceful-biters-neutral-resources-per-hp",
        setting_type = "runtime-global",
        default_value = 1.0,
        minimum_value = 0.0,
    },
    {
        type = "double-setting",
        name = "resourceful-biters-player-resources-per-hp",
        setting_type = "runtime-global",
        default_value = 0.01,
        minimum_value = 0.0,
    },
    {
        type = "bool-setting",
        name = "resourceful-biters-enemy-drops-resources",
        setting_type = "runtime-global",
        default_value = true,
    },
    {
        type = "bool-setting",
        name = "resourceful-biters-neutral-drops-resources",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "resourceful-biters-player-drops-resources",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "resourceful-biters-remove-resource-generation",
        setting_type = "startup",
        default_value = true,
    }
})