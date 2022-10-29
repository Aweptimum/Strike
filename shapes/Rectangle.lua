local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local ConvexPolygon = _Require_relative(..., 'ConvexPolygon')

---@class Rectangle : ConvexPolygon
Rect = ConvexPolygon:extend()

Rect.name = 'rect'

---Rect ctor
---@param x number x position (center)
---@param y number y position (center)
---@param dx number width
---@param dy ?number height defaults to dx
---@param angle ?number radian offset defaults to 0
function Rect:new(x, y, dx, dy, angle)
	assert(dx, 'Rectangle constructor missing width/height')
	dy = dy or dx
    self.dx, self.dy = dx, dy
	self.angle = angle or 0
	local hx, hy = dx/2, dy/2 -- halfsize
	Rect.super.new(self,
		x - hx, y - hy,
		x + hx, y - hy,
		x + hx, y + hy,
		x - hx, y + hy
	)
	self:rotate(self.angle)
end

---Return ctor args
---@return number x
---@return number y
---@return number dx
---@return number dy
---@return number angle
function Rect:unpack()
	local cx, cy = self:getCentroid()
	return cx, cy, self.dx, self.dy, self.angle
end

return Rect