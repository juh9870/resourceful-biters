local math2d = require("__resourceful_biters__/lib/math2d")
local api = require("__resourceful_biters__/lib/api") --[[@as ResourcefulBitersApi]]

if script.active_mods["gvv"] then
	require("__gvv__.gvv")()
end

local do_drop = {
	["enemy"] = true,
	["neutral"] = false,
	["player"] = false,
	["blacklist"] = false,
}

local resource_per_hp = {
	["enemy"] = 1,
	["neutral"] = 1,
	["player"] = 0.01,
}

function update_settings()
	do_drop["enemy"] = settings.global["resourceful-biters-enemy-drops-resources"].value --[[@as boolean]]
	do_drop["neutral"] = settings.global["resourceful-biters-neutral-drops-resources"].value --[[@as boolean]]
	do_drop["player"] = settings.global["resourceful-biters-player-drops-resources"].value --[[@as boolean]]
	resource_per_hp["enemy"] = settings.global["resourceful-biters-enemy-resources-per-hp"].value --[[@as number]]
	resource_per_hp["player"] = settings.global["resourceful-biters-player-resources-per-hp"].value --[[@as number]]
	resource_per_hp["neutral"] = settings.global["resourceful-biters-neutral-resources-per-hp"].value --[[@as number]]
end

update_settings()

local RESOURCE_DETECTION_RADIUS = 5

---@class ResourceInfo
---@field name string
---@field weight number
---@field richness_mult number
---@field hp_threshold number

---@class SurfaceResourceInfo
---@field resources ResourceInfo[]
---@field resources_map {[string]: ResourceInfo}
---@field weight_sum number

---@param surface LuaSurface
---@return SurfaceResourceInfo
local function resource_data_for_surface(surface)
	---@type {[integer]: SurfaceResourceInfo}
	local resource_data = storage.resource_data
	if resource_data == nil then
		resource_data = {}
		storage.resource_data = resource_data
	end
	local surface_data = resource_data[surface.index]
	if surface_data ~= nil then
		return surface_data
	end
	surface_data = {
		resources = {},
		resources_map = {},
		weight_sum = 0,
	}
	storage.resource_data[surface.index] = surface_data
	local controls = surface.map_gen_settings.autoplace_controls
	local settings = surface.map_gen_settings.autoplace_settings["entity"]
	if not settings then
		return surface_data
	end

	--- @type {[string]: {weight: number, richness: number}}
	local values = {}
	for name, control in pairs(settings.settings) do
		values[name] = {
			weight = control.frequency, --[[@as number]]
			richness = control.richness * control.size, --[[@as number]]
		}
	end

	for name, control in pairs(controls) do
		local resource = api.autoplace_control_mapping_for(name)
		local vals = values[resource]
		if vals ~= nil then
			vals.weight = vals.weight * control.frequency --[[@as number]]
			vals.richness = vals.weight * control.richness * control.size --[[@as number]]
		end
	end

	for name, control in pairs(values) do
		local ent_proto = prototypes.entity[name]

		if ent_proto ~= nil and api.is_resource_allowed(surface, ent_proto) then
			local weight = control.weight
			local richness = control.richness
			local override = api.overrides_for(surface.name, ent_proto.name)
			local hp_threshold = 0
			if override ~= nil then
				weight = weight * override.weight
				richness = richness * override.richness
				hp_threshold = override.hp_threshold
			end

			if richness ~= 0 and weight ~= 0 then
				---@type ResourceInfo
				local res = {
					name = name,
					weight = weight,
					richness_mult = richness,
					hp_threshold = hp_threshold,
				}

				surface_data.resources[#surface_data.resources + 1] = res
				surface_data.resources_map[res.name] = res
				surface_data.weight_sum = surface_data.weight_sum + weight
			end
		end
	end
	return surface_data
end

---@param surface LuaSurface
---@param factor number
---@param max_health number
---@return string | nil
---@return number
local function random_resource(surface, factor, max_health)
	local surface_data = resource_data_for_surface(surface)
	if #surface_data.resources == 0 then
		return nil, 0
	end
	local v
	local gen
	for i = 10, 1, -1 do
		gen = math.random() * surface_data.weight_sum
		v = gen
		for _, res in ipairs(surface_data.resources) do
			if v < res.weight then
				if res.hp_threshold > max_health then
					goto skip
				end
				return res.name, res.richness_mult
			end
			v = v - res.weight
		end
		error("Weighted random algorithm failed. Rolled value: `" .. gen .. "`; Data: " .. serpent.line(surface_data))
		::skip::
	end

	return nil, 0
end

---@param surface LuaSurface
---@param resource string | nil
---@return number
local function richness_mult_for_resource(surface, resource)
	local surface_data = resource_data_for_surface(surface)
	local res = surface_data.resources_map[resource]
	if res ~= nil then
		return res.richness_mult
	end
	return 1
end

---@param factor number
---@param mult number
---@param force_type ResourcefulBitersApi.ForceType
---@return integer
local function resource_amount(factor, mult, force_type)
	return math.max(math.floor(factor * mult * resource_per_hp[force_type] * (0.75 + math.random() * 0.5) + 0.5), 1)
end

---@param surface LuaSurface
---@param force LuaForce
---@param pos MapPosition.0
---@param factor number
---@param max_health number
local function place_resource(surface, force, pos, factor, max_health)
	pos = { x = math.floor(pos.x), y = math.floor(pos.y) }
	local pos_linear = 1e7 * math.floor(pos.x) + math.floor(pos.y)
	local force_type = api.force_type(force)

	---@type {[integer]: {[integer]: LuaEntity}}
	local existing_resources = storage.existing_resources
	if existing_resources == nil then
		existing_resources = {}
		storage.existing_resources = existing_resources
	end
	local surface_resources = existing_resources[surface.index]
	if surface_resources == nil then
		surface_resources = {}
		existing_resources[surface.index] = surface_resources
	end

	local existing = surface_resources[pos_linear]
	if existing ~= nil and existing.valid then
		existing.amount = existing.amount
			+ resource_amount(factor, richness_mult_for_resource(surface, existing.name), force_type)
		return
	end

	local found_existing = surface.find_entities_filtered({
		position = pos,
		type = "resource",
	})
	for _, ent in pairs(found_existing) do
		if ent.valid then
			ent.amount = ent.amount + resource_amount(factor, richness_mult_for_resource(surface, ent.name), force_type)
			surface_resources[pos_linear] = ent
			return
		end
	end

	---@type LuaEntity[]
	local nearby_resources = surface.find_entities_filtered({
		position = pos,
		radius = RESOURCE_DETECTION_RADIUS,
		type = "resource",
	})
	local scores = {}
	for _, ent in pairs(nearby_resources) do
		if ent.valid and api.is_resource_allowed(ent.surface, ent.prototype) then
			local score = scores[ent.name]
			if score == nil then
				score = 0
			end
			local ent_pos = math2d.ensure_pos_xy(ent.position)
			scores[ent.name] = score + 1 / math2d.distance2(pos, ent_pos) * math.random()
		end
	end

	local resource_to_spawn = nil
	local resource_mult = 1
	if next(scores) == nil then
		resource_to_spawn, resource_mult = random_resource(surface, factor, max_health)
		if resource_to_spawn == nil then
			return
		end
	else
		local highest_score = 0
		for name, score in pairs(scores) do
			if score > highest_score then
				highest_score = score
				resource_to_spawn = name
			end
		end
		resource_mult = richness_mult_for_resource(surface, resource_to_spawn)
	end

	local ent = surface.create_entity({
		position = pos,
		name = resource_to_spawn --[[@as string]],
		amount = resource_amount(factor, resource_mult, force_type),
		enable_cliff_removal = false,
		snap_to_tile_center = true,
	})
	if ent == nil or not ent.valid then
		return
	end

	surface_resources[pos_linear] = ent
end

---@param force LuaForce
---@return boolean
local function is_force_allowed(force)
	return do_drop[api.force_type(force)]
end

-- Clear cache every minute
script.on_nth_tick(3600, function()
	storage.existing_resources = {}
	storage.resource_data = {}
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	update_settings()
end)

---@param ent LuaEntity
local function place_resources_for_entity(ent)
	if not ent.valid or api.is_entity_blacklisted(ent.name) then
		return
	end

	local surface = ent.surface
	local force = ent.force --[[@as LuaForce]]
	if api.is_surface_blacklisted(surface.name) or not is_force_allowed(force) then
		return
	end

	local max_health = ent.max_health
	local pos = math2d.ensure_pos_xy(ent.position)
	local bb = math2d.ensure_bb_xy(ent.bounding_box)

	local w = bb.right_bottom.x - bb.left_top.x
	local h = bb.right_bottom.y - bb.left_top.y

	local area = w * h
	if area <= 1 then
		local x = pos.x + math.random(-1, 1)
		local y = pos.y + math.random(-1, 1)
		place_resource(surface, force, { x = x, y = y }, max_health, max_health)
	else
		local positions = {}
		for x = bb.left_top.x, bb.right_bottom.x do
			for y = bb.left_top.y, bb.right_bottom.y do
				positions[#positions + 1] = { x = x + math.random(-1, 1), y = y + math.random(-1, 1) }
			end
		end

		for i = #positions, 1, -1 do
			local j = math.random(i)
			local tmp = positions[i]
			positions[i] = positions[j]
			positions[j] = tmp
		end

		for _, p in pairs(positions) do
			place_resource(surface, force, p, max_health / #positions, max_health)
		end
	end
end

script.on_event(defines.events.on_entity_died, function(event)
	place_resources_for_entity(event.entity)
end)
