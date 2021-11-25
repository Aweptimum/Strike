local Vec		= _Require_relative( ... , 'lib.DeWallua.vector-light')
local Shapes 	= _Require_relative( ... , 'shapes')
local Colliders	= _Require_relative( ... , 'colliders')
local Collider	= _Require_relative( ... , 'colliders.Collider')
---@type MTV
local MTV = _Require_relative(..., 'classes.MTV')

local contact = _Require_relative(..., 'contact')
local min = math.min
local inf = math.huge

-- Get sign of number
local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

-- [[--- Collision Functions ---]] --

-- Broadphase

---Determine if two circles are colliding using their coordinates and radii
---@param collider1 Collider
---@param collider2 Collider
---@return boolean
local function circle_circle(collider1, collider2)
	local x1,y1 = collider1.centroid.x, collider1.centroid.y
	local x2,y2 = collider2.centroid.x, collider2.centroid.y
	local r1,r2 = collider1.radius,	  collider2.radius
	return (x2 - x1)^2 + (y2 - y1)^2 <= (r1 + r2)^2
end

---Returns true if two bounding boxes overlap
---@param collider1 Collider
---@param collider2 Collider
---@return boolean
local function aabb_aabb(collider1, collider2)
	local rect_1_x, rect_1_y, rect_1_w, rect_1_h = collider1:getBbox()
	local rect_2_x, rect_2_y, rect_2_w, rect_2_h = collider2:getBbox()
	return (
		rect_1_x < rect_2_x + rect_2_w and
		rect_1_x + rect_1_w > rect_2_x and
		rect_1_y < rect_2_y + rect_2_h and
		rect_1_y + rect_1_h > rect_2_y
	)
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
			return MTV:fetch(0,0)
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
	return mtv
end

local function SAT(shape1, shape2)
	local mtv1 = project(shape1, shape2)
	if mtv1:mag() == 0 then -- don't bother calculating mtv2
		MTV:stow(mtv1)
		return false, nil
	end
	local mtv2 = project(shape2, shape1)
	if mtv2:mag() == 0 then
		MTV:stow(mtv1, mtv2)
		return false, nil
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

---Check if two colliders are intersecting
---@param collider1 Collider
---@param collider2 Collider
---@return number | boolean
---@return MTV | nil
local function striking(collider1, collider2)
	local max_mtv, c = MTV:fetch(0, 0), 0
	local from, mtv
	for _, shape1 in collider1:ipairs() do
		for _, shape2 in collider2:ipairs() do
			c, mtv = SAT(shape1, shape2)
			if c and mtv:mag() > max_mtv:mag() then
				from = c
				max_mtv = mtv
			end
		end
	end
	if from == 1 then
		max_mtv:setCollider(collider1)
		max_mtv:setCollided(collider2)
	elseif from == 2 then
		max_mtv:setCollider(collider2)
		max_mtv:setCollided(collider1)
	end
	return max_mtv:mag() ~= 0 and from, max_mtv or false
end

---Translate both colliders (contained in MTV) equally away from each other
---@param mtv MTV
local function settle(mtv)
	mtv.collider:translate( Vec.mul(-.5, mtv.x, mtv.y))
	mtv.collided:translate( Vec.mul(0.5, mtv.x, mtv.y))
end

---Translate mtv.collided by full mtv (good for edge collision)
---@param mtv MTV
local function shove(mtv)
	mtv.collided:translate( mtv.x, mtv.y )
end

---Draw an mtv w/ LOVE
---@param mtv MTV
local function show_mtv(mtv)
	local c = mtv.collider.centroid
	local edge = mtv.colliderShape:getEdge(mtv.edgeIndex)
	love.graphics.setColor(1,.5,.5)
	love.graphics.line(c.x, c.y, c.x+mtv.x, c.y+mtv.y)
	love.graphics.setColor(1,0,.5)
	love.graphics.line(unpack(edge))
	love.graphics.setColor(1,1,1)
end

---Draw Collider normals
---@param collider Collider
---@param len number length of lines to draw @ normals
local function show_norms(collider, len)
	len = len or 15
	for _, shape in collider:ipairs() do
        for _, edge in shape:ipairs() do
            local  x,  y = Vec.div(2, Vec.add(edge[1], edge[2], edge[3], edge[4]) )
            local nx, ny = Vec.mul(len, Vec.normalize(Vec.sub(edge[3], edge[4], edge[1], edge[2])))
			nx, ny = ny, -nx
	        love.graphics.line(x, y, x+nx, y+ny)
        end
    end
end

---Project mtv's collided field on normal
---@param mtv MTV
local function show_proj(mtv)
	for _, shape in mtv.collided:ipairs() do
		local c = shape.centroid
		local nmx, nmy = Vec.normalize(mtv.x, mtv.y)
		local smin, smax = shape:project(nmx, nmy)
		love.graphics.setColor(.5,.5,.1)
	   	love.graphics.line(c.x+nmx*smin, c.y+nmy*smin, c.x+nmx*smax, c.y+nmy*smax)
		love.graphics.setColor(1,1,1)
    end
end

-- [[---------------------]] Strike API Table [[---------------------]] --
-- Strike table
local S = {}

-- Add shapes
S.hapes = Shapes

-- Add collider definition for each shape to Colliders
for name, shape in pairs(Shapes) do
	Colliders[name] = function(...)
		return Collider( shape(...) )
	end
end
-- Add colliders
S.trikers = Colliders

-- Broadphase functions
S.aabb = aabb_aabb
S.ircle = circle_circle

-- Add collison functions
S.triking = striking
S.ettle = settle
S.hove	= shove
S.ite = contact

-- Functions to draw collision info
S.howMTV = show_mtv
S.howNorms = show_norms
S.howProj = show_proj

-- Config
function S.eePoolSize()
	return MTV:getPoolSize()
end

function S.etPoolSize(limit)
	MTV:setPoolSize(limit)
end

-- Actually return Strike!
return S