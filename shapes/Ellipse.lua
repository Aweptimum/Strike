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
	-- Default to a ratio of major/minor axes = # of n per quadrant - multiply by 4 to get total n
	local segs = n or max( floor(a/b)*4, 8)
	-- Set ellipse coords
	local x_offset 	= x or 0
	local y_offset 	= y or 0
	-- Set angle offset
	angle = angle or 0

	-- Init vertices list
	local vertices = {}

	-- Init delta-angle between vertices lying on ellipse hull
	local d_rads = 2*pi / segs
	-- For # of segs, compute vertex coordinates using
	-- parametric eqns for an ellipse:
	-- 		x = a * cos(theta)
	-- 		y = b * sin(theta)
	-- where a is the major axis and b is the minor axis
	for i = 1, segs do
		-- Increment our angle offset
		angle = angle + d_rads
		-- Add to vertices list
		vertices[i] = {
			x = x_offset + a * cos(angle),
			y = y_offset + b * sin(angle)
		}
	end
	-- Put everything into poly table and then return it
    self.a, self.b  = a, b
    self.n   		= n
	self.vertices   = vertices			            -- list of {x,y} coords
	self.convex     = true   					    -- boolean
	self.centroid   = {x = x_offset, y = y_offset}	-- {x, y} coordinate pair
	self.radius		= a							    -- radius of circumscribed circle
	self.area		= pi*a*b						-- absolute/unsigned area of approx ellipse
    self.angle      = angle
end

---Return ctor args
---@return number x
---@return number y
---@return number a
---@return number b
---@return number n
function Ellipse:unpack()
    return self.centroid.x, self.centroid.y, self.a, self.b, self.n
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