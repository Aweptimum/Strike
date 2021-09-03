local Vec = require "Slap.DeWallua.vector-light"
local Polygon = require 'Slap.shapes.ConvexPolygon'

local Edge = Polygon:extend()

function Edge:new(x1,y1, x2,y2)

	self.vertices = {
		{x = x1, y = y1},
		{x = x2, y = y2}
	}

	self.centroid = {
		x = (x1 + x2) / 2,
		y = (y1 + y2) / 2
	}

	self.area = 0

	self.norm = 0
end

function Edge:calc_area()
	return 0
end

function Edge:calc_centroid()
	return {
		self.vertices[1].x+self.vertices[2].x / 2,
		self.vertices[1].y+self.vertices[2].y / 2
	}
end

function Edge:calc_area_centroid()
	return 0, self:calc_centroid()
end

function Edge:unpack()
    return self.vertices[1].x, self.vertices[1].y, self.vertices[2].x, self.vertices[2].y
end

function Edge:draw(fill)
	-- default fill to "line"
	fill = fill or "line"
	love.graphics.line(self:unpack())
end

return Edge