local ConvexPolygon = _Require_relative(..., 'ConvexPolygon')

local pi, cos, sin, tan = math.pi, math.cos, math.sin, math.tan

---@class RegularPolygon : ConvexPolygon
local RegularPolygon = ConvexPolygon:extend()

RegularPolygon.name = 'RegularPolygon'

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
    angle = angle or 0

    -- Calculate the points
    local vertices = {}

    for i = 1, n do
        local vx = ( sin(-i / n * 2 * pi) * radius) + x
        local vy = ( cos(-i / n * 2 * pi) * radius) + y
        table.insert(vertices, vx)
        table.insert(vertices, vy)
    end

    -- Set fields
    self.n, self.radius = n, radius
    RegularPolygon.super.new(self, vertices)
    self:rotate(angle)
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