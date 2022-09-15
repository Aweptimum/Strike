local Shape = _Require_relative(..., "Shape")

local VertexShape = Shape:extend()

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