local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local pi = math.pi
local push = table.insert
local Shape = _Require_relative(..., "shape")

---@class Circle : Shape
Circle = Shape:extend()

Circle.name = 'circle'

---Circle cotr
---@param x number x coordinate
---@param y number y coordinate
---@param radius number
---@param angle number angle offset
---@return boolean
function Circle:new(x, y, radius, angle)
	if not ( radius ) then return false end
	local x_offset = x or 0
	local y_offset = y or 0
	-- Put everything into circle table and then return it
	self.convex   = true                          -- boolean
    self.centroid = {x = x_offset, y = y_offset}  -- {x, y} coordinate pair
    self.radius   = radius				        -- radius of circumscribed circle
    self.area     = pi*radius^2				    -- absolute/unsigned area of polygon
    self.angle    = angle or 0
end

---Calculate area
---@return number area
function Circle:calcArea()
    self.area = pi*self.radius^2
    return self.area
end

---comment
---@return number x minimum x
---@return number y minimum y
---@return number dx width
---@return number dy height
function Circle:getBbox()
    return self.centroid.x - self.radius, self.centroid.y - self.radius, self.radius, self.radius
end

-- We can't actually iterate over circle geometry, but we can return a single edge
-- from the circle centroid to closest point of test shape
local function get_closest_point(shape, p)
    local dist, min_dist, min_p
    for i, v in ipairs(shape.vertices) do
        dist = Vec.dist2(p.x,p.y, v.x,v.y)
        if not min_dist or dist < min_dist then
            min_dist = dist
            min_p = v
        end
    end
    return min_p
end

local function iter_edges(state)
    local endx, endy
	state.i = state.i + 1
    local c = state.self.centroid
    local shape = state.shape
    local sc = shape.centroid
	if state.i <= 1 then
        if shape.name == 'circle' then
            endx, endy = sc.x, sc.y
        else
            local mp = get_closest_point(shape, c)
            endx, endy = mp.x, mp.y
        end
        local normx, normy = Vec.perpendicular(Vec.sub(endx,endy, c.x,c.y))
        return state.i, {c.x,c.y, c.x+normx,c.y+normy}
    end
end

function Circle:ipairs(shape)
    local state = {self=self, shape=shape, i=0}
    return iter_edges, state, nil
end

---Translate by displacement vector
---@param dx number
---@param dy number
---@return Circle self
function Circle:translate(dx, dy)
    self.centroid.x, self.centroid.y = self.centroid.x + dx, self.centroid.y + dy
	return self
end

---Rotate by specified radians
---@param angle number radians
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return Circle self
function Circle:rotate(angle, refx, refy)
    local c = self.centroid
    c.x, c.y = Vec.add(refx, refy, Vec.rotate(angle, c.x-refx, c.y - refy))
	return self
end

---Scale circle
---@param sf number scale factor
---@return Circle self
function Circle:scale(sf)
    self.radius = self.radius * sf
    self:calcArea()
	return self
end

---Project circle along normalized vector
---@param nx number normalized x-component
---@param ny number normalized y-component
---@return number minimum, number maximumum smallest, largest projection
function Circle:project(nx, ny)
    local proj = Vec.dot(self.centroid.x, self.centroid.y, nx, ny)
    return proj - self.radius, proj + self.radius
end

function Circle:getEdge(i)
    local c, r = self.centroid, self.radius
    return i == 1 and {c.x, c.y, c.x + r, c.y + r} or false
end

---Test if point inside circle
---@param point Point
function Circle:containsPoint(point)
    return Vec.len2(Vec.sub(point.x,point.y, self.centroid.x, self.centroid.y)) <= self.radius*self.radius
end

---Test of normalized ray hits circle
---@param x number ray origin
---@param y number ray origin
---@param dx number normalized x component
---@param dy number normalized y component
---@return boolean hit
function Circle:rayIntersects(x,y, dx,dy)
    dx, dy = Vec.perpendicular(dx, dy)
    local cmin, cmax = self:project(dx, dy)
    local d = Vec.dot(x,y, dx, dy)
    return cmax >= d and d >= cmin
end

-- Returns actual intersection point, from:
-- https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection
---Return all intersections as distances along ray
---@param x number ray origin
---@param y number ray origin
---@param dx number normalized x component
---@param dy number normalized y component
---@param ts table
---@return table | nil intersections
function Circle:rayIntersections(x,y, dx,dy, ts)
    if not self:rayIntersects(x,y, dx,dy) then return nil end
    ts = ts or {}
    dx, dy = Vec.normalize(dx, dy)
    local lx, ly = Vec.sub(self.centroid.x, self.centroid.y, x, y)
    local h = Vec.dot(lx,ly, dx, dy)
    local d = Vec.len(Vec.reject(lx,ly, dx,dy))
    local r = math.sqrt(self.radius*self.radius - d*d)
    local i = h - r
    local j = r > 0.0001 and h + r or nil
    push(ts, i) push (ts, j)
    return #ts > 0 and ts or nil
end

---Return ctor args
---@return number x
---@return number y
---@return number radius
function Circle:unpack()
    return self.centroid.x, self.centroid.y, self.radius
end

function Circle:merge()
    return false -- Can't merge circles :/
end

if love and love.graphics then
    ---Draw Circle w/ LOVE
    ---@param mode string fill/line
    function Circle:draw(mode)
        -- default fill to "line"
        mode = mode or "line"
        love.graphics.circle(mode, self:unpack())
    end
end

return Circle