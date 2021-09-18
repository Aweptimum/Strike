local Dewall    = require "Strike.lib.DeWallua.init"
local Collider  = require 'Strike.colliders.Collider'
local Convex    = require 'Strike.shapes.ConvexPolygon'
local pop = table.remove

tprint(Dewall)

-- A concave shape must be decomposed into a collection of convex shapes
local Concave = Collider:extend()

local function to_vertices(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_vertices(vertices, ...)
end

function Concave:new(...)
	if ... and type(...) == "table" then return self:new(unpack(...)) end
    local vertices = to_vertices({}, ...)
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")
    self.shapes = {}
    self.centroid = {x=0, y=0}
    self.radius = 0
    -- Triangulation!
    local triangles = Dewall.constrained(vertices)
	-- Convert triangles to polygons and add to self.shapes
	for i = #triangles, 1, -1 do
		self:add(Convex(unpack(pop(triangles))))
	end
    -- Need to merge triangles into the largest concave polygons possible
    -- Then, for each polygon, calc area/centroid
    -- Figure out how to store several sub-polygons in a consistent way
    self:calc_area_centroid()
    self:calc_radius()
end

return Concave