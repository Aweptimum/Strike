local Vec = _Require_relative( ... , 'lib.DeWallua.vector-light', 1)
local MTV = _Require_relative(..., 'classes.MTV',1)
local min = math.min
local inf = math.huge

-- Get sign of number
local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

-- SAT
local function project(shape1, shape2)
	local minimum, mtv_dx, mtv_dy, edge_index = inf, 0, 0, 0
	local overlap, dx, dy
	local shape1_min_dot, shape1_max_dot, shape2_min_dot, shape2_max_dot
	-- loop through shape1 geometry
	for i, edge in shape1:ipairs(shape2) do
		-- get the normal
		dx, dy = Vec.normalize( Vec.sub(edge[3],edge[4], edge[1], edge[2]) )
		dx, dy = dy, -dx
		-- Project both shapes 1 and 2 onto this normal to get their shadows
		shape1_min_dot, shape1_max_dot = shape1:project(dx, dy)
		shape2_min_dot, shape2_max_dot = shape2:project(dx, dy)
		-- We've now reduced it to ranges intersecting on a number line,
		-- Test for bounding overlap
		if not ( shape1_max_dot > shape2_min_dot and shape2_max_dot > shape1_min_dot ) then
			-- Separating Axis, return
            local mtv = MTV:fetch(dx, dy)
            mtv:setColliderShape(shape1)
            mtv:setEdgeIndex(edge_index)
            mtv:setCollidedShape(shape2)
			return false, mtv
		else
			-- Find the overlap (minimum difference of bounds), which is equal to the magnitude of the MTV
			overlap = min(shape1_max_dot-shape2_min_dot, shape2_max_dot-shape1_min_dot)
			if overlap < minimum then
				-- Set our MTV to the smol vector
				minimum = overlap
				mtv_dx, mtv_dy = dx, dy
				edge_index = i
			end
		end
	end
	-- Flip it?
	local ccx, ccy = shape2.centroid.x - shape1.centroid.x, shape2.centroid.y - shape1.centroid.y
	local s = sign( Vec.dot(mtv_dx, mtv_dy, ccx, ccy) )
	-- Welp. We made it here. So they're colliding, I guess. Hope it's consensual :(
	local mtv = MTV:fetch( Vec.mul(s*minimum, mtv_dx, mtv_dy) )
	mtv:setColliderShape(shape1)
	mtv:setEdgeIndex(edge_index)
	mtv:setCollidedShape(shape2)
	return true, mtv
end

local function SAT(shape1, shape2)
	local overlap, mtv1, mtv2
	overlap, mtv1 = project(shape1, shape2)
	if not overlap then -- don't bother calculating mtv2
		return false, mtv1
	end
	overlap, mtv2 = project(shape2, shape1)
	if not overlap then
		return false, mtv2
	end
	-- Else, return the min
	if mtv1:mag() < mtv2:mag() then
		MTV:stow(mtv2)
		return 1, mtv1
	else
		MTV:stow(mtv1)
		return 2, mtv2
	end
end

return SAT