--- @class (exact) juh_math2d.XyBoundingBox
--- @field left_top MapPosition.0
--- @field right_bottom MapPosition.0

--- @class (exact) juh_math2d.ChunkPos: MapPosition.0

--- @class juh_math2d
local juh_math2d = {}

---@param pos MapPosition
---@return MapPosition.0
juh_math2d.ensure_pos_xy = function(pos)
	if pos.x ~= nil then
		return { x = pos.x, y = pos.y }
	else
		return { x = pos[1], y = pos[2] }
	end
end

---@param bb BoundingBox
---@return juh_math2d.XyBoundingBox
juh_math2d.ensure_bb_xy = function(bb)
	if bb.left_top ~= nil then
		return {
			left_top = juh_math2d.ensure_pos_xy(bb.left_top),
			right_bottom = juh_math2d.ensure_pos_xy(bb.right_bottom),
		}
	else
		return { left_top = juh_math2d.ensure_pos_xy(bb[0]), right_bottom = juh_math2d.ensure_pos_xy(bb[1]) }
	end
end

--- Checks whenever two bounding boxes overlap
--- @param box1 juh_math2d.XyBoundingBox
--- @param box2 juh_math2d.XyBoundingBox
--- @return boolean
juh_math2d.collides_with = function(box1, box2)
	return box1.left_top.x < box2.right_bottom.x
		and box2.left_top.x < box1.right_bottom.x
		and box1.left_top.y < box2.right_bottom.y
		and box2.left_top.y < box1.right_bottom.y
end

--- converts map position to chunk position
--- @param pos MapPosition.0
--- @return juh_math2d.ChunkPos
juh_math2d.chunk_pos = function(pos)
	return { x = math.floor(pos.x / 32), y = math.floor(pos.y / 32) }
end

--- EXpands the bounding box by a specified amount
--- @param bb juh_math2d.XyBoundingBox
--- @param amount integer
--- @return juh_math2d.XyBoundingBox
juh_math2d.expand_bb = function(bb, amount)
	return {
		left_top = { x = bb.left_top.x - amount, y = bb.left_top.y - amount },
		right_bottom = { x = bb.right_bottom.x + amount, y = bb.right_bottom.y + amount },
	}
end
--- @param a MapPosition.0
--- @param b MapPosition.0
--- @return number
juh_math2d.distance2 = function(a, b)
	return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2
end

return juh_math2d
