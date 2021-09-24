local Vec = require "Strike.lib.DeWallua.vector-light"
local pi = math.pi
local Shape = require "Strike.shapes.shape"

Circle = Shape:extend()

Circle.name = 'circle'

function Circle:new(x_pos, y_pos, radius,  angle_rads)
    print('constructing circle')
	if not ( radius ) then return false end
	local x_offset = x_pos or 0
	local y_offset = y_pos or 0
	-- Put everything into circle table and then return it
	self.convex   = true                          -- boolean
    self.centroid = {x = x_offset, y = y_offset}  -- {x, y} coordinate pair
    self.radius   = radius				        -- radius of circumscribed circle
    self.area     = pi*radius^2				    -- absolute/unsigned area of polygon
    self.angle    = angle_rads or 0
end

function Circle:calc_area()
    self.area = pi*self.radius^2
end

function Circle:get_bbox()
    return self.centroid.x - self.radius, self.centroid.y - self.radius, self.radius, self.radius
end

-- We can't actually iterate over circle geometry, but we can return a single edge
-- from the circle centroid to its radius for consistency and quick iteration.
local function iter_edges(circle, i)
	i = i + 1
    local c, r = circle.centroid, circle.radius
	if i <= 1 then
		return i, {c.x, c.y, c.x + r, c.y + r}
	end
end

function Circle:ipairs()
    return iter_edges, self, 0
end

function Circle:translate(dx, dy)
    self.centroid.x, self.centroid.y = self.centroid.x + dx, self.centroid.y + dy
end

function Circle:rotate(angle, ref_x, ref_y)
    local c = self.centroid
    c.x, c.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, c.x-ref_x, c.y - ref_y))
end

function Circle:scale(sf)
    self.radius = self.radius * sf
    self:calc_area()
end

function Circle:project(nx, ny)
    local proj = Vec.dot(self.centroid.x, self.centroid.y, nx, ny)
    return proj - self.radius, proj + self.radius
end

function Circle:getEdge(i)
    local c, r = self.centroid, self.radius
    return i == 1 and {c.x, c.y, c.x + r, c.y + r} or false
end

function Circle:containsPoint(point)
    return Vec.len2(Vec.sub(point.x,point.y, self.centroid.x, self.centroid.y)) <= self.radius*self.radius
end

function Circle:rayIntersects(x,y, dx,dy)
    dx, dy = Vec.perpendicular(dx, dy)
    local cmin, cmax = self:project(dx, dy)
    local d = Vec.dot(x,y, dx, dy)
    return cmax >= d and d >= cmin
end
-- Returns actual intersection point, from:
-- https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection
function Circle:rayIntersections(x,y, dx,dy)
    if not self:rayIntersects(x,y, dx,dy) then return false end
    dx, dy = Vec.normalize(dx, dy)
    local lx, ly = Vec.sub(self.centroid.x, self.centroid.y, x, y)
    local h = Vec.dot(lx,ly, dx, dy)
    local d = Vec.len(Vec.reject(lx,ly, dx,dy))
    local r = math.sqrt(self.radius*self.radius - d*d)
    local i = h - r
    local j = r > 0.0001 and h + r or nil
    return {i, j}
end

function Circle:unpack()
    return self.centroid.x, self.centroid.y, self.radius
end

function Circle:merge()
    return false -- Can't merge circles :/
end

function Circle:draw(mode)
	-- default fill to "line"
	mode = mode or "line"
	love.graphics.circle("line", self:unpack())
end

return Circle