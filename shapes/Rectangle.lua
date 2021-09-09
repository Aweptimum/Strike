local Vec = require "Slap.DeWallua.vector-light"
local cos, sin = math.cos, math.sin
local Polygon = require 'Slap.shapes.ConvexPolygon'

local Rect = {
    vertices 		= {},              -- list of {x,y} coords
    convex      	= true,             -- boolean
    centroid   		= {x = 0, y = 0},	-- {x, y} coordinate pair
    radius			= 0,				-- radius of circumscribed circle
    area			= 0					-- absolute/unsigned area of polygon
}
-- Set metatable so we can override polygon methods
--Rect.__index = Rect
Rect = Polygon:extend()

Rect.name = 'rect'
function Rect:new(x_pos, y_pos, dx, dy, angle_rads)
	print('constructing rect')
	if not ( dx and dy ) then return false end
	local x_offset, y_offset = x_pos or 0, y_pos or 0
    self.dx, self.dy = dx, dy
	self.angle = angle_rads or 0
	self.vertices = {
		{x = x_offset						, y = y_offset					},
		{x = x_offset + dx*cos(self.angle)	, y = y_offset					},
		{x = x_offset + dx*cos(self.angle)	, y = y_offset + dy*sin(self.angle)	},
		{x = x_offset						, y = y_offset + dy*sin(self.angle)	}
	}
	self.centroid  	= {x = x_offset+dx/2, y = y_offset+dy/2}
	self.area 		= dx*dy
	self.radius		= Vec.len(dx, dy)/2
end

function Rect:unpack()
	return self.centroid.x, self.centroid.y, self.dx, self.dy, self.angle
end

return Rect