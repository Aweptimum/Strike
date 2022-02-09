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
	for i, vec in shape1:vecs(shape2) do
		-- get the normal
		dx, dy = Vec.normalize( vec.x, vec.y )
		dx, dy = dy, -dx
		-- Project both shapes 1 and 2 onto this normal to get their shadows
		shape1_min_dot, shape1_max_dot = shape1:project(dx, dy)
		shape2_min_dot, shape2_max_dot = shape2:project(dx, dy)
		-- We've now reduced it to ranges intersecting on a number line,
		-- Test for bounding overlap
		if not ( shape1_max_dot > shape2_min_dot and shape2_max_dot > shape1_min_dot ) then
			-- Separating Axis, return
            local mtv = MTV:fetch(dx, dy, shape1, shape2, true)
            return mtv
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
	local mx, my = Vec.mul(s*minimum, mtv_dx, mtv_dy)
	local mtv = MTV:fetch(mx, my, shape1, shape2, false)
	return mtv
end

local function SAT(shape1, shape2)
	local mtv1, mtv2
	mtv1 = project(shape1, shape2)
	if mtv1.separating then -- don't bother calculating mtv2
		return mtv1
	end
	mtv2 = project(shape2, shape1)
	if mtv2.separating then
		return mtv2
	end
	-- Else, return the min
	local mintv = mtv1:mag2() < mtv2:mag2() and mtv1 or mtv2
	return mintv
end

return SAT