local Vec = _Require_relative( ... , 'lib.DeWallua.vector-light', 1)
local Cache = _Require_relative(..., 'classes.Cache',1)
local MTV = _Require_relative(..., 'classes.MTV',1)
local min = math.min
local inf = math.huge

-- Get sign of number
local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

---Calculate if the mtv is along or against the reference frame
---@param mtv MTV
---@param shape1 Shape
---@param shape2 Shape
---@return integer sign
local function reference_frame(mtv, shape1, shape2)
	local c1x, c1y = shape1:getCentroid()
	local c2x, c2y = shape2:getCentroid()
	local ccx, ccy = c2x - c1x, c2y - c1y
	return sign( Vec.dot(mtv.x, mtv.y, ccx, ccy) )
end

-- Cache:
local acache = Cache()

local function test_axis(shape1, shape2, dx,dy, mtv)
	local shape1_min_dot, shape1_max_dot = shape1:project(dx,dy)
	local shape2_min_dot, shape2_max_dot = shape2:project(dx,dy)
	-- We've now reduced it to ranges intersecting on a number line,
	-- Test for bounding overlap
	if not ( shape1_max_dot > shape2_min_dot and shape2_max_dot > shape1_min_dot ) then
		-- Separating Axis, return
		mtv:new(dx, dy, shape1, shape2, true)
		-- Add to cache
		acache:set({shape1, shape2}, mtv)
	else
		-- Find the overlap (minimum difference of bounds), which is equal to the magnitude of the MTV
		local overlap = min(shape1_max_dot-shape2_min_dot, shape2_max_dot-shape1_min_dot)
		if overlap*overlap < mtv:mag2() then
			-- Set our MTV to the smol vector
			mtv.x, mtv.y = Vec.mul(overlap, dx, dy)
		end
	end
	return mtv
end


-- SAT
local function project(shape1, shape2)
	local mtv = MTV(inf,inf)
	-- Test cache
	local v = acache:get({shape1, shape2})
	if v then
		mtv = test_axis(shape1, shape2, v.x,v.y, mtv)
		if mtv.separating then
			return mtv
		end
	end
	-- Cached axis failed :(
	local dx, dy
	mtv:new(inf,inf)

	-- loop through shape1 geometry
	for i, vec in shape1:vecs(shape2) do
		-- get the normal
		dx, dy = Vec.normalize( vec.x, vec.y )
		dx, dy = dy, -dx
		mtv = test_axis(shape1,shape2,dx,dy,mtv)
		mtv:setEdgeIndex(i)
		if mtv.separating then
			return mtv
		end
	end
	-- Welp. We made it here. So they're colliding, I guess. Hope it's consensual :(
	-- Flip it?
	local s = reference_frame(mtv, shape1, shape2)
	mtv:scale(s):setColliderShape(shape1):setCollidedShape(shape2):setSeparating(false)
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