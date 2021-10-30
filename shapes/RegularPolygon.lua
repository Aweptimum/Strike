local Polygon = _Require_relative(..., 'ConvexPolygon')

local pi, cos, sin, tan = math.pi, math.cos, math.sin, math.tan

---@class RegularPolygon : ConvexPolygon
local RegularPolygon = Polygon:extend()

---Calculate area using regular area formula
---@return number area
function RegularPolygon:calcArea()
    local n, r = self.n, self.radius*cos(pi/self.n)
    self.area = n*r*r*tan(pi/n)
    return self.area
end

---Regular Polygon ctor
---@param x number x position
---@param y number y position
---@param n number of sides
---@param radius number radius of circumscribed circle
---@param angle number radian offset
function RegularPolygon:new(x, y, n, radius, angle)
    -- Initialize our polygon's origin and rotation
    n = n or 3
    self.angle = angle or 0
    -- Initalize our dummy point vars to put into the vertices list
    local vertices = {}

    -- Calculate the points
    for i = n, 1, -1 do -- i = 1, n calculates vertices in clockwise order, so go backwards
        x = ( sin( i / n * 2 * pi - self.angle) * radius) + x
        y = ( cos( i / n * 2 * pi - self.angle) * radius) + y
        vertices[#vertices+1] = {x = x, y = y}
    end

    -- Put everything into polygon table and then return it
    self.n, self.radius = n, radius
    self.vertices 		= vertices     	    -- list of {x,y} coords
    self.convex      	= true      		-- boolean
    self.centroid       = {x = x, y = y}	-- {x, y} coordinate pair
    -- Calculate the area of our polygon.
    self:calcArea()
end

---Return ctor args
---@return number x
---@return number y
---@return number n
---@return number radius
---@return number angle
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