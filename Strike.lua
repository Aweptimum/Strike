local Vec		= _Require_relative( ... , 'lib.DeWallua.vector-light')
local Shapes 	= _Require_relative( ... , 'shapes')
local Colliders	= _Require_relative( ... , 'colliders')
local Collider	= _Require_relative( ... , 'colliders.Collider')
---@type MTV
local MTV = _Require_relative(..., 'classes.MTV')

local contact = _Require_relative(..., 'algs.contact')
local SAT = _Require_relative(..., 'algs.SAT')

-- [[--- Broadphase Functions ---]] --

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

---Check if two colliders are intersecting
---@param collider1 Collider
---@param collider2 Collider
---@return number | boolean
---@return MTV | nil
local function striking(collider1, collider2)
	local collision, max_mtv = false, MTV(0, 0)
	local c, mtv
	for shape1 in collider1:sshapes() do
		--local shape1 = state1.shape
		for shape2 in collider2:sshapes() do
			--local shape2 = state2.shape
			c, mtv = SAT(shape1, shape2)
			if c and mtv:mag2() > max_mtv:mag2() then
				max_mtv = mtv
				collision = true
			end
		end
	end
	return collision and max_mtv or not true
end

---Translate both colliders (contained in MTV) equally away from each other
---@param mtv MTV
local function settle(mtv)
	local collider, collided = mtv.colliderShape:getRoot(), mtv.collidedShape:getRoot()
	collider:translate( Vec.mul(-.5, mtv.x, mtv.y))
	collided:translate( Vec.mul(0.5, mtv.x, mtv.y))
end

---Translate mtv.collided by full mtv (good for edge collision)
---@param mtv MTV
local function shove(mtv)
	local collided = mtv.collidedShape:getRoot()
	collided:translate( mtv.x, mtv.y )
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
S.AT = SAT
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