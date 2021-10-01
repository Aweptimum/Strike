local Dewall    = Libs.DeWallua
local Collider  = _Require_relative(..., 'Collider')
local Convex    = _Require_relative(..., 'shapes.ConvexPolygon', 1)
local pop = table.remove

-- A concave shape must be decomposed into a collection of convex shapes
local Concave = Collider:extend()

local function to_vertices(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_vertices(vertices, ...)
end

function Concave:new(x, ...)
	if x and type(x) == "table" then return self:new(unpack(x)) end
    local vertices = to_vertices({}, x,...)
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")
    self.shapes = {}
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