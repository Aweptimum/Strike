local Vec = require "Slap.DeWallua.vector-light"
local pi, cos, sin, tan = math.pi, math.cos, math.sin, math.tan

local Polygon = require 'Slap.shapes.ConvexPolygon'

local RegularPolygon = Polygon:extend()

function RegularPolygon:calc_area()
    local n, r = self.n, self.radius*cos(pi/self.n)
    self.area = n*r*r*tan(pi/n)
end

function RegularPolygon:new(x_pos, y_pos, n, radius, angle_rads)
    -- Initialize our polygon's origin and rotation
    n = n or 3
    self.angle 	    = angle_rads or 0
    -- Initalize our dummy point vars to put into the vertices list
    local x, y
    local vertices = {}

    -- Print easter-egg warning
    --if n == 1000 then print("OH NO, NOT A CHILIAGON! YOU MANIAC! HOW COULD YOU!?\n") end
    -- Calculate the points
    for i = n, 1, -1 do -- i = 1, n calculates vertices in clockwise order, so go backwards
        x = ( sin( i / n * 2 * pi - self.angle) * radius) + x_pos
        y = ( cos( i / n * 2 * pi - self.angle) * radius) + y_pos
        vertices[#vertices+1] = {x = x, y = y}
    end

    -- Put everything into polygon table and then return it
    self.n, self.radius = n, radius
    self.vertices 		= vertices     	    -- list of {x,y} coords
    self.convex      	= true      		-- boolean
    self.centroid       = {x = x_pos, y = y_pos}	-- {x, y} coordinate pair
    -- Calculate the area of our polygon.
    self:calc_area()
end

function RegularPolygon:unpack()
    return self.centroid.x, self.centroid.y, self.n, self.radius, self.angle
end

function RegularPolygon:_get_verts()
	local v = {}
	for i = 1,#self.vertices do
		v[2*i-1] = self.vertices[i].x
		v[2*i]   = self.vertices[i].y
	end
	return unpack(v)
end

return RegularPolygon