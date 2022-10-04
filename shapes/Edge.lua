local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local VertexShape = _Require_relative(..., 'VertexShape')

---@class Edge : VertexShape
local Edge = VertexShape:extend()
Edge.name = 'edge'

---"Calculate" edge area
---@return Edge self
function Edge:calcArea()
	self.area = 1
	return self
end

---Calculate midpoint of edge
---@return Edge self
function Edge:calcCentroid()
	local x1, y1 = self:getVertex(1)
	local x2, y2 = self:getVertex(2)
	self.centroid.x = (x1+x2) / 2
	self.centroid.y = (y1+y2) / 2
	return self
end

---Calculate both area and centroidreturn Edge self
function Edge:calcAreaCentroid()
	self:calcArea()
	self:calcCentroid()
	return self
end

---Calculate radius of circumscribed circle
---@return Edge self
function Edge:calcRadius()
	local x1, y1 = self:getVertex(1)
	local x2, y2 = self:getVertex(2)
	self.radius = 0.5 * Vec.len(Vec.sub(x1, y1, x2, y2) )
	return self
end

---comment
---@param x1 number x coordinate of first point
---@param y1 number y coordinate of first point
---@param x2 number x coordinate of second point
---@param y2 number y coordinate of second point
function Edge:new(x1,y1, x2,y2)

	Edge.super.new(self, x1,y1, x2,y2)

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
		local ix, iy = shape:getVertex(i)
		local jx, jy = shape:getVertex(j)
		return i, {ix, iy, jx, jy}
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
	local x1, y1 = self:getVertex(1)
	local x2, y2 = self:getVertex(2)
    return x1, y1, x2, y2
end

if love and love.graphics then
	---Draw Edge w/ LOVE
	function Edge:draw()
		love.graphics.line(self:unpack())
		love.graphics.setColor(0,1,1)
		love.graphics.points(self:getCentroid())
		love.graphics.setColor(1,1,1)
	end
end

return Edge