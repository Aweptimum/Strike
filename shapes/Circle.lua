local Vec = require "Strike.DeWallua.vector-light"
local pi = math.pi
local Shape = require "Strike.shapes.shape"

Circle = Shape:extend()

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
    self.centroid.x, self.centroid.y = self.x + dx, self.y + dy
end

function Circle:rotate(angle, ref_x, ref_y)
    local c = self.centroid
    c.x, c.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, c.x-ref_x, c.y - ref_y))
end

function Circle:scale(sf)
    self.radius = self.radius * sf
    self:calc_area()
end

function Circle:unpack()
    return self.centroid.x, self.centroid.y, self.radius
end

function Circle:draw(mode)
	-- default fill to "line"
	mode = mode or "line"
	love.graphics.circle("line", self:unpack())
end

return Circle