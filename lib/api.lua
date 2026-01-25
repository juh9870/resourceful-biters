--- @class(exact) ResourcefulBitersApi.ModData
---
--- Blacklisted entities will not place resources upon death
--- @field entity_blacklist {[string]: boolean}
---
--- Overrides for force types
--- 
--- Forces that have players in them are player force by default. All other forces are enemy forces by default
--- @field force_overrides {[string]: ResourcefulBitersApi.ForceType}
---
--- Entities on blacklisted surfaces will not place resources upon death
--- Resource will still be removed from generation, use resource_blacklist to make your resources unaffected
--- @field surface_blacklist {[string]: boolean}
---
--- Only resources with whitelisted resource category will be affected by this mod
--- @field resource_categories_whitelist {[string]: boolean}
---
--- Mapping from the autoplace control name to the resource it actually controls
--- @field autoplace_control_mapping {[string]: string}
---
--- Drop overrides for individual resources
--- @field resource_overrides {[string]: ResourcefulBitersApi.ExtOreOverride}

--- Overrides for the placed resources
--- @class(exact) ResourcefulBitersApi.OreOverride
---
--- Whenever this resource is blacklisted and should not be placed or be removed by the mod
--- @field blacklisted? boolean
---
--- Modifies the weight of the resource. Defaults to 1
--- Resources with higher weight have better chances of being placed upon entity death
--- @field weight? number
---
--- Multiplier to the richness of placed resources. Defaults to 1
--- @field richness? number
---
--- Threshold for entity max health at which it will drop the resource upon being defeated. Defaults to 0 (no thrreshold)
--- This only applied to newly placed resources. Entities of any max health amount can spread or enrich existing patches
--- @field hp_threshold? number

--- @alias ResourcefulBitersApi.ForceType "player"|"enemy"|"neutral"|"blacklist"

--- @class(exact) ResourcefulBitersApi.ExtOreOverride:ResourcefulBitersApi.OreOverride
--- @field surface_overrides? {[string]: ResourcefulBitersApi.OreOverride}

--- @class(exact) ResourcefulBitersApi.ComputedOreOverride
--- @field name string
--- @field blacklisted boolean
--- @field weight number
--- @field richness number
--- @field hp_threshold number

--- @class(exact) ResourcefulBitersApi.ComputedExtOreOverride
--- @field base ResourcefulBitersApi.ComputedOreOverride
--- @field surfaces {[string]: ResourcefulBitersApi.ComputedOreOverride}

--- @generic T : table
--- @param target T
--- @param source T
--- @param skip {[string]: boolean}
function mergeTable(target, source, skip)
	for k, v in pairs(source) do
		if not skip[k] then
			if v ~= nil then
				target[k] = v
			end
		end
	end
end

--- @class ResourcefulBitersApi
--- @field data ResourcefulBitersApi.ModData
--- @field computed_resource_overries {[string]: ResourcefulBitersApi.ComputedExtOreOverride}
local api = {}
if script ~= nil then
	api.data = prototypes.mod_data["resourceful-biters-data"].data

	api.computed_resource_overries = {}
	for name, res in pairs(api.data.resource_overrides) do
		--- @type ResourcefulBitersApi.ComputedOreOverride
		local base = {
			name = name,
			blacklisted = false,
			weight = 1,
			richness = 1,
			hp_threshold = 0,
		}

		local surface_overrides = {}

		mergeTable(base, res, { ["surface_overrides"] = true })

		if res.surface_overrides ~= nil then
			for surface, over in pairs(res.surface_overrides) do
				local surface_base = {
                    name = base.name,
                    blacklisted = base.blacklisted,
                    weight = base.weight,
                    richness = base.richness,
                    hp_threshold = base.hp_threshold,
                }
				mergeTable(surface_base, over, {})
				surface_overrides[surface] = surface_base
			end
		end

		api.computed_resource_overries[name] = {
			base = base,
			surfaces = surface_overrides,
		}
	end

	--- @param surface LuaSurface
	--- @param res LuaEntityPrototype
	api.is_resource_allowed = function(surface, res)
		if res.type ~= "resource" or not api.is_resource_category_allowed(res.resource_category) then
			return nil
		end

		local over = api.overrides_for(surface.name, res.name)

		return not (over ~= nil and over.blacklisted)
	end

	--- @param surface_name string
	--- @param resource_name string
	--- @return ResourcefulBitersApi.ComputedOreOverride | nil
	api.overrides_for = function(surface_name, resource_name)
		local data = api.computed_resource_overries[resource_name]
		if data == nil then
			return nil
		end

		local surface_data = data.surfaces[surface_name]
		if surface_data ~= nil then
			return surface_data
		end

		return data.base
	end

	--- @param force LuaForce
	--- @return ResourcefulBitersApi.ForceType
	api.force_type = function(force)
		-- Overrides
		local over = api.data.force_overrides[force.name]
		if over ~= nil then
			return over
		end
		-- Forces with player in them are considered player forces
		if next(force.players) ~= nil then
			return "player"
		end
		-- Every other force is enemy
		return "enemy"
	end
else
	api.data = data.raw["mod-data"]["resourceful-biters-data"].data

	--- @param surface LuaSurface
	--- @param res LuaEntityPrototype
	api.is_resource_allowed = function(surface, res)
		error("`is_resource_allowed` is not available at data stage")
	end

	--- @param surface_name string
	--- @param resource_name string
	--- @return ResourcefulBitersApi.ComputedOreOverride | nil
	api.overrides_for = function(surface_name, resource_name)
		error("`overrides_for` is not available at data stage")
	end

	--- @param force LuaForce
	--- @return ResourcefulBitersApi.ForceType
	api.force_type = function(force)
		error("`force_type` is not available at data stage")
	end
end

--- Returns whenever this resource is blacklisted
---
--- Note that non-blacklisted resources may still not be affected due to their category not being in the resource_categories_whitelist
---
--- If surface_name is nil, it will only check if resource is blacklisted at base
--- @param surface_name string | nil
--- @param resource_name string
--- @return boolean
api.is_resource_blacklisted = function(surface_name, resource_name)
	local over = api.data.resource_overrides[resource_name]
	if over == nil then
		return false
	end
	if over.blacklisted == true then
		return true
	end
	if surface_name == nil or over.surface_overrides == nil then
		return false
	end
	local surface_over = over.surface_overrides[surface_name]
	return surface_over ~= nil and surface_over.blacklisted == true
end

--- Returns whenever this entity is blacklisted
--- @param entity_name string
--- @return boolean
api.is_entity_blacklisted = function(entity_name)
	return api.data.entity_blacklist[entity_name] or false
end

--- Returns whenever entities on this surface is blacklisted
--- @param surface_name string
--- @return boolean
api.is_surface_blacklisted = function(surface_name)
	return api.data.surface_blacklist[surface_name] or false
end

--- Returns whenever resources of this category can be processed
---
--- nil category defaults to checking for `basic-solid` category
--- @param resource_category string | nil
--- @return boolean
api.is_resource_category_allowed = function(resource_category)
	return (resource_category == nil and api.data.resource_categories_whitelist["basic-solid"])
		or api.data.resource_categories_whitelist[resource_category]
end

--- Returns the mapped name of the control if one is available
--- @param control_name string
--- @return string
api.autoplace_control_mapping_for = function (control_name)
	return api.data.autoplace_control_mapping[control_name] or control_name
end

return api
