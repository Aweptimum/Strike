local Vec = require "Strike.DeWallua.vector-light"
local Polygon = require 'Strike.shapes.ConvexPolygon'

Rect = Polygon:extend()

Rect.name = 'rect'

function Rect:new(x_pos, y_pos, dx, dy, angle_rads)
	if not ( dx and dy ) then return false end
	local x_offset, y_offset = x_pos or 0, y_pos or 0
    self.dx, self.dy = dx, dy
	self.angle = angle_rads or 0
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

function Rect:unpack()
	return self.centroid.x, self.centroid.y, self.dx, self.dy, self.angle
end

return Rect