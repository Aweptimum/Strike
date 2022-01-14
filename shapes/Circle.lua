local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local pi = math.pi
local push = table.insert
local Shape = _Require_relative(..., "Shape")

---@class Circle : Shape
Circle = Shape:extend()

Circle.name = 'circle'

---Circle ctor
---@param x number x coordinate
---@param y number y coordinate
---@param radius number
---@param angle number angle offset
function Circle:new(x, y, radius, angle)
	if not ( radius ) then return false end
    Circle.super.new(self)
	-- Put everything into circle table and then return it
	self.convex   = true        -- boolean
    self.radius   = radius		-- radius of circumscribed circle
    self.area     = pi*radius^2	-- absolute/unsigned area of polygon
    self.angle    = angle or 0
    self:translateTo(x,y)
end

---Calculate area
---@return Shape self
function Circle:calcArea()
    self.area = pi*self.radius^2
    return self
end

function Circle:getVertexCount()
    return 1
end

---comment
---@return number x minimum x
---@return number y minimum y
---@return number dx width
---@return number dy height
function Circle:getBbox()
    local cx, cy = self:getCentroid()
    return cx - self.radius, cy - self.radius, self.radius, self.radius
end

-- We can't actually iterate over circle geometry, but we can return a single edge
-- from the circle centroid to closest point of test shape
local function get_closest_point(shape, x,y)
    local dist, min_dist, min_x, min_y
    local len = #shape.vertices
    for i = 1, len do
        local vx, vy = shape:getVertex(i)
        dist = Vec.dist2(x,y, vx,vy)
        if not min_dist or dist < min_dist then
            min_dist = dist
            min_x, min_y = vx, vy
        end
    end
    return min_x, min_y
end

local function iter_edges(state)
    local endx, endy
	state.i = state.i + 1
    local cx, cy = state.self:getCentroid()
    local shape = state.shape
    local sx, sy = shape:getCentroid()
	if state.i <= 1 then
        if shape.name == 'circle' then
            endx, endy = sx, sy
        else
            local mpx, mpy = get_closest_point(shape, cx, cy)
            endx, endy = mpx, mpy
        end
        local normx, normy = Vec.perpendicular(Vec.sub(endx,endy, cx,cy))
        return state.i, {cx, cy, cx+normx, cy+normy}
    end
end

function Circle:ipairs(shape)
    local state = {self=self, shape=shape, i=0}
    return iter_edges, state, nil
end

local function iter_vecs(state)
    local endx, endy
	state.i = state.i + 1
    local cx, cy = state.self:getCentroid()
    local shape = state.shape
    local sx, sy = shape:getCentroid()
	if state.i <= 1 then
        if shape.name == 'circle' then
            endx, endy = sx, sy
        else
            endx, endy = get_closest_point(shape, cx, cy)
        end
        local normx, normy = Vec.perpendicular(Vec.sub(endx,endy, cx,cy))
        return state.i, {x = normx, y = normy}
    end
end

---Iterate over edge vectors
---@param shape Shape
---@return function
---@return number i
---@return Vector vec
function Circle:vecs(shape)
    local state = {self=self, shape=shape, i=0}
    return iter_vecs, state, nil
end

---Project circle along normalized vector
---@param nx number normalized x-component
---@param ny number normalized y-component
---@return number minimum, number maximumum smallest, largest projection
function Circle:project(nx, ny)
    local cx, cy = self:getCentroid()
    local proj = Vec.dot(cx, cy, nx, ny)
    return proj - self.radius, proj + self.radius
end

---Get an edge given an index, returns the vertex at i and the vertex at i+1
---@param i number edge index (has to be 1)
---@return table|nil edge of form {x1,y1, x2,y2} or nil if index beyond bounds
function Circle:getEdge(i)
    local cx, cy = self:getCentroid()
    local r = self.radius
    return i == 1 and {cx, cy, cx + r, cy + r} or nil
end

---Test if point inside circle
---@param point Point
function Circle:containsPoint(point)
    local cx, cy = self:getCentroid()
    return Vec.len2(Vec.sub(point.x,point.y, cx, cy)) <= self.radius*self.radius
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
    local cx, cy = self:getCentroid()
    local lx, ly = Vec.sub(cx, cy, x, y)
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
    local cx, cy = self:getCentroid()
    local r = self:getRadius()
    return cx, cy, r
end

function Circle:merge()
    return false -- Can't merge circles :/
end

--Get the point on the circle in the furthest direction of the given vector
---@param nx number normalized x dir
---@param ny number normalized y dir
---@return table Max-Point
function Circle:getSupport(nx,ny)
    local cx, cy = self:getCentroid()
    local px,py = Vec.mul(self.radius, nx,ny)
    return {x = cx+px, y = cy+py}
end

---Get the point involved in a collision
---@param nx number normalized x dir
---@param ny number normalized y dir
---@return table Max-Point
Circle.getFeature = Circle.getSupport

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