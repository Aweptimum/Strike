local pi, cos, sin = math.pi, math.cos, math.sin
local floor, max = math.floor, math.max
local Polygon = _Require_relative(..., 'ConvexPolygon')

---@class Ellipse : ConvexPolygon
local Ellipse = Polygon:extend()

Ellipse.name = 'ellipse'

---Ellipse ctor
---@param x number x position
---@param y number y position
---@param a number major radius
---@param b number minor radius
---@param n number number of edges to approx w/
---@param angle number radian offset
function Ellipse:new(x, y, a, b, n, angle)
	if not ( a or b ) then return false end -- We need both to make an ellipse!
	x = x or 0
	y = y or 0
	angle = angle or 0
	n = n or max(8, floor(a/b)*4) -- a/b = n per quadrant -> multiply by 4 to get total n

	-- Init vertices list
	local vertices = {}

	-- Init delta-angle between vertices lying on ellipse hull
	local d_rads = 2*pi / n
	-- For # of segs, compute vertex coordinates using
	-- parametric eqns for an ellipse:
	-- 		x = a * cos(theta)
	-- 		y = b * sin(theta)
	-- where a is the major axis and b is the minor axis
	local a_offset = d_rads
	for i = 1, n do
		-- Increment our angle offset
		a_offset = a_offset + d_rads
		-- Add to vertices list
		table.insert(vertices, x + a * cos(a_offset))
		table.insert(vertices, y + b * sin(a_offset))
	end

	-- Set ellipse vars
    self.a, self.b, self.n = a, b, n
	Ellipse.super.new(self, vertices)
	self:rotate(angle) -- set angle here because convex constructor defaults to 0
end

---Return ctor args
---@return number x
---@return number y
---@return number a
---@return number b
---@return number n
function Ellipse:unpack()
	local cx, cy = self:getCentroid()
    return cx, cy, self.a, self.b, self.n
end

if love and love.graphics then
	---Draw Ellipse w/ LOVE
	---@param mode string fill/line
	function Ellipse:draw(mode)
		-- default fill to "line"
		mode = mode or "line"
		love.graphics.ellipse(mode, self:unpack())
	end
end

return Ellipse