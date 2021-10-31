local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local Polygon = _Require_relative(..., 'ConvexPolygon')

---@class Rectangle : ConvexPolygon
Rect = Polygon:extend()

Rect.name = 'rect'

---Rect cotr
---@param x number x position (center)
---@param y number y position (center)
---@param dx number width
---@param dy number height
---@param angle number radian offset
function Rect:new(x, y, dx, dy, angle)
	if not ( dx and dy ) then return false end
	local x_offset, y_offset = x or 0, y or 0
    self.dx, self.dy = dx, dy
	self.angle = angle or 0
	local hx, hy = dx/2, dy/2 -- halfsize
	self.vertices = {
		{x = x_offset - hx, y = y_offset - hy},
		{x = x_offset + hx, y = y_offset - hy},
		{x = x_offset + hx, y = y_offset + hy},
		{x = x_offset - hx, y = y_offset + hy}
	}
	self.centroid  	= {x = x_offset, y = y_offset}
	self.area 		= dx*dy
	self.radius		= Vec.len(hx, hy)
	self:rotate(self.angle)
end

---Return ctor args
---@return number x
---@return number y
---@return number dx
---@return number dy
---@return number angle
function Rect:unpack()
	return self.centroid.x, self.centroid.y, self.dx, self.dy, self.angle
end

return Rect