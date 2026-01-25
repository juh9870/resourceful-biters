--- @type ResourcefulBitersApi.ModData
local mod_data = {
	resource_blacklist = {
		-- ["blacklisted-ore2"] = true,
		-- ["blacklisted-ore2"] = true,
	},
	entity_blacklist = {
		-- ["blackisted-entity"] = true,
	},
	force_overrides = {
		-- ["blackisted-force"] = "blacklist",
		-- ["custom-enemy-force"] = "enemy",
		-- ["custom-player-force"] = "player",
		["neutral"] = "neutral",
	},
	surface_blacklist = {
		-- ["narnia"] = true,
	},
	resource_categories_whitelist = {
		["basic-solid"] = true,
		["hard-solid"] = true,
	},
	autoplace_control_mapping = {
		["gleba_stone"] = "stone",
		["vulcanus_coal"] = "coal",
	},
	resource_overrides = {
		["uranium-ore"] = {
			weight = 0.25,
			hp_threshold = 100,
		},
		["scrap"] = {
			richness = 4,
		},
		["calcite"] = {
			weight = 2,
		},
		["stone"] = {
			weight = 0.666666,
		},
		["coal"] = {
			weight = 0.8,
			surface_overrides = {
				["vulcanus"] = {
					weight = 2,
				},
			},
		},
		["kr-rare-metal-ore"] = {
			weight = 0.5,
			hp_threshold = 100,
		},
		["rubia-ferric-scrap"] = {
			richness = 4,
		},
		["rubia-cupric-scrap"] = {
			weight = 0.5,
			richness = 4,
		},
	},
}

data:extend({
	{
		type = "mod-data",
		name = "resourceful-biters-data",
		data = mod_data,
	},
})
