local bit 		= require'bit' --https://luajit.org/extensions.html
local Vec		= _Require_relative( ... , "lib.DeWallua.vector-light")
local Object	= _Require_relative( ... , "lib.classic")
local Shapes 	= _Require_relative( ... , "shapes")
local Collider	= _Require_relative( ... , "colliders.Collider")
local Colliders	= _Require_relative( ... , "colliders")

local pi, cos, sin, atan2 = math.pi, math.cos, math.sin, math.atan2
-- atan(y, 0) returns 0, not undefined
local floor, ceil, sqrt, abs, max, min   = math.floor, math.ceil, math.sqrt, math.abs, math.max, math.min
local inf = math.huge
-- Push/pop
local push, pop = table.insert, table.remove

--local _PACKAGE = (...):match("^(.+)%.[^%.]+")

-- Polygon module for creating shapes to strike each other

-- [[---------------------]] Declaration of Spelling Collinear [[---------------------]] --

-- [[ IT IS TO BE DECLARED HEREIN THIS DOCUMENT THAT THE "LL" SPELLING OF COLLINEAR ]] --
-- [[ SHALL BE ADOPTED THROUGHOUT, AS IT'S SPELLED ON WIKIPEDIA. "WHY?" YOU MAY ASK ]] --
-- [[ Well, it's because that's how my vector calculus prof spelled it. Using 1 "L" ]] --
-- [[ just feels a bit wrong, y'know? So accept it. Or change it in your fork, idk. ]] --

-- [[---------------------]]        Utility Functions        [[---------------------]] --

-- Get signs of numbers
local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

-- Create MTV object
local MTV = Object:extend()

function MTV:new(dx, dy, collider, collided)
	self.x, self.y = dx or 0, dy or 0
	self.collider = collider or 'none'
	self.collided = collided or 'none'
	self.colliderShape = 'none'
	self.collidedShape = 'none'
	self.edgeIndex = 0
end

function MTV:mag()
	return Vec.len(self.x, self.y)
end

function MTV:setCollider(collider)
	self.collider = collider
end

function MTV:setColliderShape(shape)
	self.colliderShape = shape
end
-- Index of edge that generated mtv
function MTV:setEdgeIndex(index)
	self.edgeIndex = index
end

function MTV:setCollided(collider)
	self.collided = collider
end

function MTV:setCollidedShape(shape)
	self.collidedShape = shape
end

-- [[--- Collision Functions ---]] --

-- Broadphase

-- Determine if two circles are colliding using their coordinates and radii
local function circle_circle(collider1, collider2)
	local x1,y1 = collider1.centroid.x, collider1.centroid.y
	local x2,y2 = collider2.centroid.x, collider2.centroid.y
	local r1,r2 = collider1.radius,	  collider2.radius
	return (x2 - x1)^2 + (y2 - y1)^2 <= (r1 + r2)^2
end

-- Returns true if two bounding boxes overlap
local function aabb_aabb(collider1, collider2)
	local rect_1_x, rect_1_y, rect_1_w, rect_1_h = collider1:get_bbox()
	local rect_2_x, rect_2_y, rect_2_w, rect_2_h = collider2:get_bbox()
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
	for i, edge in shape1:ipairs() do
		-- get the normal
		dx, dy = Vec.normalize( Vec.sub(edge[3],edge[4], edge[1], edge[2]) )
		dx, dy = dy, -dx
		-- Project both shapes 1 and 2 onto this normal to get their shadows
		shape1_min_dot, shape1_max_dot = shape1:project(dx, dy)
		shape2_min_dot, shape2_max_dot = shape2:project(dx, dy)
		-- We've now reduced it to ranges intersecting on a number line,
		-- Test for bounding overlap
		if not ( shape1_max_dot > shape2_min_dot and shape2_max_dot > shape1_min_dot ) then
			-- WE FOUND IT BOIS, TIME TO GO HOME
			return MTV(0,0)
		else
			-- Find the overlap, which is equal to the magnitude of the MTV
			-- Overlap = minimum difference of bounds
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
	local mtv = MTV( Vec.mul(s*minimum, mtv_dx, mtv_dy) )
	mtv:setColliderShape(shape1)
	mtv:setEdgeIndex(edge_index)
	mtv:setCollidedShape(shape2)
	return mtv
end

local function SAT(shape1, shape2)
	local mtv1 = project(shape1, shape2)
	if mtv1:mag() == 0 then -- don't bother calculating mtv2
		return false, nil
	end
	local mtv2 = project(shape2, shape1)
	if mtv2:mag() == 0 then
		return false, nil
	end
	-- Else, return the min
	if mtv1:mag() < mtv2:mag() then
		return 1, mtv1
	else
		return 2, mtv2
	end
end

local function striking(collider1, collider2)
	local max_mtv, c = MTV(0, 0), 0
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
-- Translate both colliders equally away from each other
local function settle(mtv)
	mtv.collider:translate( Vec.mul(-.5, mtv.x, mtv.y))
	mtv.collided:translate( Vec.mul(0.5, mtv.x, mtv.y))
end
-- Translate collided by full mtv (good for edge collision)
local function shove(mtv)
	mtv.collided:translate( mtv.x, mtv.y )
end

local function show_mtv(mtv)
	local c = mtv.collider.centroid
	love.graphics.line(c.x, c.y, c.x+mtv.x, c.y+mtv.y)
end

local function show_norms(collider)
	for _, shape in collider:ipairs() do
        for _, edge in shape:ipairs() do
            local  x,  y = Vec.div(2, Vec.add(edge[1], edge[2], edge[3], edge[4]) )
            local nx, ny = Vec.sub(edge[3], edge[4], edge[1], edge[2])
			nx, ny = ny, -nx
	        love.graphics.line(x, y, x+nx, y+ny)
        end
    end
end

local function show_proj(mtv)
	local c = mtv.collided.centroid
	for _, shape in mtv.collided:ipairs() do
		local nmx, nmy = Vec.normalize(mtv.x, mtv.y)
		local smin, smax = shape:project(nmx, nmy)
		love.graphics.setColor(.5,.5,.1)
	   	love.graphics.line(16+nmx*smin, nmy*smin, 16+nmx*smax, nmy*smax)
		love.graphics.setColor(1,1,1)
    end
end

-- [[---------------------]] Strike API Table [[---------------------]] --
-- Strike table
local S = {}

-- Config table
S.ettings = {}

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

-- Functions to draw collision info
S.howMTV = show_mtv
S.howNorms = show_norms
S.howProj = show_proj

-- Actually return Strike!
return S