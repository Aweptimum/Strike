local pi, cos, sin = math.pi, math.cos, math.sin
local floor, max = math.floor, math.max
local Polygon = require 'Strike.shapes.ConvexPolygon'

local Ellipse = Polygon:extend()

Ellipse.name = 'ellipse'
function Ellipse:new(x_pos, y_pos, a, b, segments, angle_rads)
	if not ( a or b ) then return false end -- We need both to make an ellipse!
	-- Default to a ratio of major/minor axes = # of segments per quadrant - multiply by 4 to get total segments
	local segs = segments or max( floor(a/b)*4, 8)
	-- Set ellipse coords
	local x_offset 	= x_pos or 0
	local y_offset 	= y_pos or 0
	-- Set angle offset
	local angle 	= angle_rads or 0

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
    self.segments   = segments
	self.vertices   = vertices			            -- list of {x,y} coords
	self.convex     = true   					    -- boolean
	self.centroid   = {x = x_offset, y = y_offset}	-- {x, y} coordinate pair
	self.radius		= a							    -- radius of circumscribed circle
	self.area		= pi*a*b						-- absolute/unsigned area of approx ellipse
    self.angle      = angle
end

function Ellipse:unpack()
    return self.centroid.x, self.centroid.y, self.a, self.b, self.segments
end

function Ellipse:draw(mode)
	-- default fill to "line"
	mode = mode or "line"
	love.graphics.ellipse(mode, self:unpack())
end

return Ellipse