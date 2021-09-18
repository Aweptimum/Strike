local Vec = require "Strike.lib.DeWallua.vector-light"
local Polygon = require 'Strike.shapes.ConvexPolygon'

local Edge = Polygon:extend()
Edge.name = 'edge'

function Edge:calc_area()
	self.area = 1
	return self.area
end

function Edge:calc_centroid()
	self.centroid.x = (self.vertices[1].x+self.vertices[2].x) / 2
	self.centroid.y = (self.vertices[1].y+self.vertices[2].y) / 2
	return self.centroid
end

function Edge:calc_area_centroid()
	return self:calc_area(), self:calc_centroid()
end

function Edge:calc_radius()
	self.radius = 0.5 * Vec.len(Vec.sub(self.vertices[1].x, self.vertices[1].y, self.vertices[2].x, self.vertices[2].y) )
	return self.radius
end

function Edge:new(x1,y1, x2,y2)

	self.vertices = {
		{x = x1, y = y1},
		{x = x2, y = y2}
	}

	self.centroid = {
		x = (x1 + x2) / 2,
		y = (y1 + y2) / 2
	}
	self.radius = 0.5 * Vec.len(Vec.sub(x1,y1, x2,y2))
	self.area = 1
	self.norm = 0
	self:calc_area_centroid()
end
-- Only iterate once
local function edge_iter(shape, i)
	i = i + 1
	local v = shape.vertices
	if i < #v then
		local j = i < #v and i+1
		return i, {v[i].x, v[i].y, v[j].x, v[j].y}
	end
end

function Edge:ipairs()
    return edge_iter, self, 0
end

function Edge:unpack()
    return self.vertices[1].x, self.vertices[1].y, self.vertices[2].x, self.vertices[2].y
end

function Edge:draw(fill)
	-- default fill to "line"
	fill = fill or "line"
	love.graphics.line(self:unpack())
	love.graphics.setColor(0,1,1)
	love.graphics.points(self.centroid.x, self.centroid.y)
	love.graphics.setColor(1,1,1)
end

return Edge