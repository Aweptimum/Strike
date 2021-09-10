-- Base collider object
local push, pop = table.insert, table.remove
local Vec = require "Slap.DeWallua.vector-light"
local Object = require 'Slap.classic.classic'

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

-- Iterate over collider shapes
local function iter_shapes(col, i)
    i = i+1
    local shape = col.shapes[i]
    if shape then
        return i, shape
    end
end

local function iter_method(method, col, i)
    i = i+1
    local shape = col.shapes[i]
    if shape then
        return i, shape[method](shape)
    end
end

local function shapes(collider)
    for i, shape in ipairs(collider.shapes) do
        if shape.type == 'shape' then
            coroutine.yield(collider, shape)
        elseif shape.type == 'collider' then
            print(shape.name)
            shapes(shape)
        end
    end
end

function Collider:ipairs()
    return iter_shapes, self, 0
end

function Collider:ipairs()
    return coroutine.wrap( function() shapes(self) end )
end

function Collider:calc_area()
    self.area = 0
    for _, shape in self:ipairs() do
        self.area = self.area + shape.area
    end
end

function Collider:calc_centroid()
    self.centroid.x, self.centroid.y = 0,0
    local area = 0
    for _, shape in self:ipairs() do
        area = area + shape.area
        self.centroid.x = self.centroid.x + shape.centroid.x * shape.area
        self.centroid.y = self.centroid.y + shape.centroid.y * shape.area
    end
    self.centroid.x, self.centroid.y = self.centroid.x/area, self.centroid.y/area
end

function Collider:calc_area_centroid()
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
function Collider:calc_radius()
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
    self:calc_area_centroid()
    self:calc_radius()
end

function Collider:unpack()
    return unpack(self.shapes)
end
-- Turn this into a recursive copy - each shape in the new collider still references the old one.
function Collider:copy(x, y, angle_rads)
    local copy = self:_copy()
	-- if origin specified, then translate
	if x and y then
		copy:translate_to(x, y)
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

function Collider:translate_to(x, y)
	local dx, dy = x - self.centroid.x, y - self.centroid.y
	return self:translate(dx,dy)
end

-- Rotate collider
function Collider:rotate(angle, ref_x, ref_y)
    angle = angle or 0
    ref_x, ref_y = ref_x or self.centroid.x, ref_y or self.centroid.y
    for _, shape in self:ipairs() do
        -- Rotate about ref wrt the collider; per shape would rotate each in-place
        shape:rotate(angle, ref_x, ref_y)
    end
    self.centroid.x, self.centroid.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, self.centroid.x-ref_x, self.centroid.y - ref_y))
    --self:calc_centroid()
end

function Collider:scale(sf, ref_x, ref_y)
    for _, shape in self:ipairs() do
        shape:scale(sf, ref_x, ref_y)
    end
	self.centroid.x, self.centroid.y = Vec.add(ref_x, ref_y, Vec.mul(sf, self.centroid.x-ref_x, self.centroid.y - ref_y))
    -- Recalculate area, and radius
    self:calc_area()
    --self.radius = self.radius * sf
end

-- Remove shape(s) from collider
function Collider:remove(index, ...)
    pop(self.shapes, index) -- hopefully no one makes a collider with 1000's of shapes
    return self:remove(...)
end

-- Draw Collider
function Collider:draw()
    for _, shape in self:ipairs() do
        --love.graphics.setColor(love.math.random(), love.math.random(), love.math.random())
        shape:draw()
        love.graphics.points(shape.centroid.x, shape.centroid.y)
        love.graphics.print(_,shape.centroid.x, shape.centroid.y)
    end
end

return Collider