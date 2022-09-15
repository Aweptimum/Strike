local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local VertexShape = _Require_relative(..., 'VertexShape')

---@class Edge : Shape
local Edge = VertexShape:extend()
Edge.name = 'edge'

---"Calculate" edge area
---@return number area
function Edge:calcArea()
	self.area = 1
	return self.area
end

---Calculate midpoint of edge
---@return Point centroid
function Edge:calcCentroid()
	self.centroid.x = (self.vertices[1].x+self.vertices[2].x) / 2
	self.centroid.y = (self.vertices[1].y+self.vertices[2].y) / 2
	return self.centroid
end

---Calculate both area and centroid
---@return number area
---@return Point centroid
function Edge:calcAreaCentroid()
	return self:calcArea(), self:calcCentroid()
end

---Calculate radius of circumscribed circle
---@return number radius
function Edge:calcRadius()
	self.radius = 0.5 * Vec.len(Vec.sub(self.vertices[1].x, self.vertices[1].y, self.vertices[2].x, self.vertices[2].y) )
	return self.radius
end

---comment
---@param x1 number x coordinate of first point
---@param y1 number y coordinate of first point
---@param x2 number x coordinate of second point
---@param y2 number y coordinate of second point
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
	self.angle = 0
	self:calcAreaCentroid()
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

---Edge iterator
---@return function
---@return Edge
---@return number
function Edge:ipairs()
    return edge_iter, self, 0
end

---Return ctor arguments
---@return number x1
---@return number y1
---@return number x2
---@return number y2
function Edge:unpack()
    return self.vertices[1].x, self.vertices[1].y, self.vertices[2].x, self.vertices[2].y
end

if love and love.graphics then
	---Draw Edge w/ LOVE
	function Edge:draw()
		love.graphics.line(self:unpack())
		love.graphics.setColor(0,1,1)
		love.graphics.points(self.centroid.x, self.centroid.y)
		love.graphics.setColor(1,1,1)
	end
end

return Edge