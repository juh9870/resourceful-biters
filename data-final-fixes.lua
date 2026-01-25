local api = require("__resourceful_biters__/lib/api") --[[@as ResourcefulBitersApi]]

local disable_resources = settings.startup["resourceful-biters-remove-resource-generation"].value --[[@as boolean]]

if not disable_resources then
	return
end

for _, res in pairs(data.raw["resource"]) do
	if api.is_resource_category_allowed(res.category) and not api.is_resource_blacklisted(nil, res.name) then
		if res.autoplace ~= nil then
			res.autoplace.placement_density = 0
		end
	end
end
