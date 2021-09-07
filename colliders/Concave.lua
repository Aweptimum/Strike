local Dewall = require "DeWallua"
local pop = table.remove
local cos, sin = math.cos, math.sin
local Collider = require 'Slap.colliders.Collider'
local Convex = require 'Slap.shapes.ConvexPolygon'

-- A concave shape must be decomposed into a collection of convex shapes
local Concave = Collider:extend()

local function to_vertices(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_vertices(vertices, ...)
end

function Concave:new(...)
	if type(...) == "table" then return self:new(unpack(...)) end
    local vertices = to_vertices({}, ...)
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")
    -- Triangulation!
    local triangles = Dewall.constrained(vertices)
	-- Convert triangles to polygons and add to self.shapes
	for i = #triangles, 1, -1 do
		self:add(Convex(unpack(pop(triangles))))
	end
    self.centroid = {x=0, y=0}
    -- Need to merge triangles into the largest concave polygons possible
    -- Then, for each polygon, calc area/centroid
    -- Figure out how to store several sub-polygons in a consistent way
    self:calc_area_centroid()
end

return Concave