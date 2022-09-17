local Shape = _Require_relative(..., "Shape")

local VertexShape = Shape:extend()

-- Recursive function that returns a list of {x=#,y=#} coordinates given a list of procedural, ccw coordinate pairs
local function to_verts(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_verts(vertices, ...)
end

local function to_vertices(x, ...)
	return type(x) == 'table'and to_verts({}, unpack(x)) or to_verts({}, x,...)
end

-- Create new Polygon object
---@vararg number x,y tuples
---@param x number
---@param y number
function VertexShape:new(x,y, ...)
    VertexShape.super.new(self)
	self.centroid = {x=0, y=0}
	self.vertices = to_vertices(x,y, ...)
end

---Get a vertex by its offset
---@param i number
---@return number|false v.x or false if beyond range
---@return number|false v.y
function VertexShape:getVertex(i)
	if i > #self.vertices then return false, false end
	local v = self.vertices[i]
	return v.x, v.y
end

return VertexShape