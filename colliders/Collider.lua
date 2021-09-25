-- Base collider object
local push, pop = table.insert, table.remove
local tbl = Libs.tbl
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local Object = Libs.classic

local Collider = Object:extend()

Collider.type = 'collider'

-- A collider is an object composed of one or more shapes (or colliders!)
Collider.shapes = {}

-- Add shape(s) to collider
function Collider:add(shape, ...)
    if not shape then return end
    push(self.shapes, shape)
    self:add(...)
end

-- Iter method
local function shapes(collider)
    for i, shape in ipairs(collider.shapes) do
        if shape.type == 'shape' then
            coroutine.yield(collider, shape, i) -- return reference to parent, shape, and shape's index in parent
        elseif shape.type == 'collider' then
            shapes(shape)
        end
    end
end
-- Actual iterator
function Collider:ipairs()
    return coroutine.wrap( function() shapes(self) end )
end

function Collider:calcArea()
    self.area = 0
    for _, shape in self:ipairs() do
        self.area = self.area + shape.area
    end
end

function Collider:calcCentroid()
    self.centroid.x, self.centroid.y = 0,0
    local area = 0
    for _, shape in self:ipairs() do
        area = area + shape.area
        self.centroid.x = self.centroid.x + shape.centroid.x * shape.area
        self.centroid.y = self.centroid.y + shape.centroid.y * shape.area
    end
    self.centroid.x, self.centroid.y = self.centroid.x/area, self.centroid.y/area
end

function Collider:calcAreaCentroid()
    self.centroid.x, self.centroid.y = 0,0
    self.area = 0
    for _, shape in self:ipairs() do
        self.area = self.area + shape.area
        self.centroid.x = self.centroid.x + shape.centroid.x * shape.area
        self.centroid.y = self.centroid.y + shape.centroid.y * shape.area
    end
    self.centroid.x, self.centroid.y = self.centroid.x/self.area, self.centroid.y/self.area
end
-- Calc radius by finding shape with: largest sum of centroidal difference + radius
function Collider:calcRadius()
    self.radius = 0
    local cx,cy = self.centroid.x, self.centroid.y
    for _, shape in self:ipairs() do
        local r = Vec.len(cx - shape.centroid.x, cy - shape.centroid.y) + shape.radius
        self.radius = self.radius > r and self.radius or r
    end
    return self.radius
end

function Collider:new(...)
    self.shapes = {}
    self:add(...)
    self.centroid  = {x = 0, y = 0}
    self.area = 0
    self.radius = 0
    self:calcAreaCentroid()
    self:calcRadius()
end

function Collider:unpack()
    return unpack(self.shapes)
end
-- Turn this into a recursive copy - each shape in the new collider still references the old one.
function Collider:copy(x, y, angle_rads)
    local copy = tbl.deep_copy(self)
	-- if origin specified, then translate
	if x and y then
		copy:translateTo(x, y)
	end
	-- If rotation specified, then rotate_polygon
	if angle_rads then
		copy:rotate(angle_rads)
    end
	-- Return copy
	return copy
end

-- Translate collider
function Collider:translate(dx, dy)
    for _, shape in self:ipairs() do
        shape:translate(dx, dy)
    end
    self.centroid.x, self.centroid.y = self.centroid.x + dx, self.centroid.y + dy
end

function Collider:translateTo(x, y)
	local dx, dy = x - self.centroid.x, y - self.centroid.y
	return self:translate(dx,dy)
end

-- Rotate collider
function Collider:rotate(angle, refx, refy)
    angle = angle or 0
    refx, refy = refx or self.centroid.x, refy or self.centroid.y
    for _, shape in self:ipairs() do
        -- Rotate about ref wrt the collider; per shape would rotate each in-place
        shape:rotate(angle, refx, refy)
    end
    self.centroid.x, self.centroid.y = Vec.add(refx, refy, Vec.rotate(angle, self.centroid.x-refx, self.centroid.y - refy))
end

function Collider:scale(sf, refx, refy)
    refx, refy = refx or self.centroid.x, refy or self.centroid.y
    for _, shape in self:ipairs() do
        shape:scale(sf, refx, refy)
    end
	self.centroid.x, self.centroid.y = Vec.add(refx, refy, Vec.mul(sf, self.centroid.x-refx, self.centroid.y - refy))
    -- Recalculate area, and radius
    self:calcArea()
    self.radius = self.radius * sf
end

function Collider:project(dx, dy)
    local minp, maxp = math.huge, -math.huge
    for _, shape in self:ipairs() do
        local smin, smax = shape:project(dx, dy)
        minp = smin < minp and smin or minp
        maxp = smax > maxp and smax or maxp
    end
    return minp, maxp
end

function Collider:rayIntersects(x,y, dx,dy)
    for _, shape in self:ipairs() do
        if shape:rayIntersects(x,y, dx,dy) then return true end
    end
    return false
end

function Collider:rayIntersections(x,y, dx,dy)
    local ts = {}
    for _, shape in self:ipairs() do
        ts[shape] = shape:rayIntersections(x,y, dx,dy)
    end
    return next(ts) and ts or nil
end

-- Remove shape(s) from collider
function Collider:remove(index, ...)
    if not index then return end
    table.remove(self.shapes, index) -- hopefully no one makes a collider with 1000's of shapes
    return self:remove(...)
end

function Collider:consolidate()
    for i = #self.shapes, 2, -1 do
        local s1 = self.shapes[i]
        for j = i-1, 1, -1 do
            if s1.type == 'collider' then s1:consolidate() break end
            local s2 = self.shapes[j]
            local s = s1:merge(s2)
            if s then
                self:remove(i)
                self.shapes[j] = s
                break
            end
        end
    end
end

-- Draw Collider
function Collider:draw(mode)
    mode = mode or 'line'
    for _, shape in self:ipairs() do
        --love.graphics.setColor(love.math.random(), love.math.random(), love.math.random())
        shape:draw(mode)
        love.graphics.points(shape.centroid.x, shape.centroid.y)
        love.graphics.print(_,shape.centroid.x, shape.centroid.y)
    end
end

return Collider