local Dewall    = Libs.DeWallua
local Collider  = _Require_relative(..., 'Collider')
local Convex    = _Require_relative(..., 'shapes.ConvexPolygon', 1)
local pop = table.remove

-- A concave shape must be decomposed into a collection of convex shapes
---@class Concave : Collider
local Concave = Collider:extend()

-- Recursive function that returns a list of {x=#,y=#} coordinates given a list of procedural, ccw coordinate pairs
local function to_verts(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_verts(vertices, ...)
end

local function to_vertices(vertices, x, ...)
	return type(x) == 'table'and to_verts(vertices, unpack(x)) or to_verts(vertices, x,...)
end

---Concave ctor
---@vararg number x,y tuples
---@param x number
---@param y number
function Concave:new(x,y, ...)
    local vertices = to_vertices({}, x,y, ...)
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")
    self.shapes = {}
    self.area = 0
    self.centroid = {x=0, y=0}
    self.radius = 0
    self.angle = 0
    -- Triangulation!
    local triangles = Dewall.constrained(vertices)
	-- Convert triangles to polygons and add to self.shapes
	for i = #triangles, 1, -1 do
		self:add(Convex(unpack(pop(triangles))))
	end
    -- Need to merge triangles into the largest concave polygons possible
    -- Then, for each polygon, calc area/centroid
    -- Figure out how to store several sub-polygons in a consistent way
    self:consolidate()
    self:calcAreaCentroid()
    self:calcRadius()
end

return Concave