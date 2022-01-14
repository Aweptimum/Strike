-- Base collider object
local push, pop = table.insert, table.remove
local tbl = Libs.tbl
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local Object = Libs.classic

---@class Collider : Object
---@field shapes table
---@field centroid Point
---@field area number
---@field radius number
---@field angle number
local Collider = Object:extend()

Collider.type = 'collider'

-- A collider is an object composed of one or more shapes (or colliders!)
Collider.shapes = {}

-- Add shape(s) to collider
---@vararg Shape
---@param shape Shape
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

---Calculate area
---@return number area
function Collider:calcArea()
    self.area = 0
    for _, shape in self:ipairs() do
        self.area = self.area + shape.area
    end
    return self.area
end

---Calculate centroid
---@return Point
function Collider:calcCentroid()
    self.centroid.x, self.centroid.y = 0,0
    local area = 0
    for _, shape in self:ipairs() do
        area = area + shape.area
        self.centroid.x = self.centroid.x + shape.centroid.x * shape.area
        self.centroid.y = self.centroid.y + shape.centroid.y * shape.area
    end
    self.centroid.x, self.centroid.y = self.centroid.x/area, self.centroid.y/area
    return self.centroid
end

---Calculate area & centroid
---@return number
---@return Point
function Collider:calcAreaCentroid()
    self.centroid.x, self.centroid.y = 0,0
    self.area = 0
    for _, shape in self:ipairs() do
        self.area = self.area + shape.area
        self.centroid.x = self.centroid.x + shape.centroid.x * shape.area
        self.centroid.y = self.centroid.y + shape.centroid.y * shape.area
    end
    self.centroid.x, self.centroid.y = self.centroid.x/self.area, self.centroid.y/self.area
    return self.area, self.centroid
end

---Calc radius by finding shape with: largest sum of centroidal difference + radius
---@return number radius
function Collider:calcRadius()
    self.radius = 0
    local cx,cy = self.centroid.x, self.centroid.y
    for _, shape in self:ipairs() do
        local r = Vec.len(cx - shape.centroid.x, cy - shape.centroid.y) + shape.radius
        self.radius = self.radius > r and self.radius or r
    end
    return self.radius
end

function Collider:getRadius()
    return self.radius
end

---Collider constructor; takes variadic list of Shapes/Colliders
---@vararg Shape
---@param shape Shape | Collider
function Collider:new(shape, ...)
    self.shapes = {}
    self:add(shape, ...)
    self.centroid  = {x = 0, y = 0}
    self.area = 0
    self.radius = 0
    self.angle = 0
    self:calcAreaCentroid()
    self:calcRadius()
end

---Return unpacked list of shapes
---@return Shape | Collider shapes
function Collider:unpack()
    return unpack(self.shapes)
end

---Copy Collider
---@param x number optional x-coordinate to place copy
---@param y number optional y-coordinate to place copy
---@param angle number optional angle to offset to
---@return Collider copy
function Collider:copy(x, y, angle)
    local copy = tbl.deep_copy(self)
	-- if origin specified, then translate
	if x and y then
		copy:translateTo(x, y)
	end
	-- If rotation specified, then rotate_polygon
	if angle then
		copy:rotateTo(angle)
    end
	-- Return copy
	return copy
end

---Translate by displacement vector
---@param dx number
---@param dy number
---@return Collider self
function Collider:translate(dx, dy)
    for _, shape in self:ipairs() do
        shape:translate(dx, dy)
    end
    self.centroid.x, self.centroid.y = self.centroid.x + dx, self.centroid.y + dy
    return self
end

---Translate to coordinate
---@param x number
---@param y number
---@return Collider self
function Collider:translateTo(x, y)
	local dx, dy = x - self.centroid.x, y - self.centroid.y
	return self:translate(dx,dy)
end

---Rotate by specified radians
---@param angle number radians
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return Collider self
function Collider:rotate(angle, refx, refy)
    angle = angle or 0
    refx, refy = refx or self.centroid.x, refy or self.centroid.y
    for _, shape in self:ipairs() do
        -- Rotate about ref wrt the collider; per shape would rotate each in-place
        shape:rotate(angle, refx, refy)
    end
    self.centroid.x, self.centroid.y = Vec.add(refx, refy, Vec.rotate(angle, self.centroid.x-refx, self.centroid.y - refy))
    self.angle = self.angle + angle
    return self
end

---Rotate to specified radians
---@param angle number radians
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return Collider self
function Collider:rotateTo(angle, refx, refy)
	local aoffset = angle - self.angle
	return self:rotate(aoffset, refx, refy)
end

---Scale Collider
---@param sf number scale factor
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return Collider self
function Collider:scale(sf, refx, refy)
    refx, refy = refx or self.centroid.x, refy or self.centroid.y
    for _, shape in self:ipairs() do
        shape:scale(sf, refx, refy)
    end
	self.centroid.x, self.centroid.y = Vec.add(refx, refy, Vec.mul(sf, self.centroid.x-refx, self.centroid.y - refy))
    -- Recalculate area, and radius
    self:calcArea()
    self.radius = self.radius * sf
    return self
end

---Project Collider along normalized vector (not so useful for concave colliders)
---@param nx number normalized x-component
---@param ny number normalized y-component
---@return number minimum, number maximumum smallest, largest projection
function Collider:project(nx, ny)
    local minp, maxp = math.huge, -math.huge
    for _, shape in self:ipairs() do
        local smin, smax = shape:project(nx, ny)
        minp = smin < minp and smin or minp
        maxp = smax > maxp and smax or maxp
    end
    return minp, maxp
end

---Test if given ray hits any Shapes in the Collider
---@param x number
---@param y number
---@param nx number normalized x component
---@param ny number normalized y component
---@return boolean hit
function Collider:rayIntersects(x,y, nx,ny)
    for _, shape in self:ipairs() do
        if shape:rayIntersects(x,y, nx,ny) then return true end
    end
    return false
end

---Return all intersections with Shapes in Collider
---@param x number
---@param y number
---@param nx number normalized x component
---@param ny number normalized y component
---@return Shape[] | nil intersections
function Collider:rayIntersections(x,y, nx,ny)
    local ts = {}
    for _, shape in self:ipairs() do
        ts[shape] = shape:rayIntersections(x,y, nx,ny)
    end
    return next(ts) and ts or nil
end

---Get Collider bounding box
---@return number x, number y, number dx, number dy minimum x/y, width, and height
function Collider:getBbox()
	local min_x, min_y, dx, dy = self.shapes[1]:getBbox()
    local max_x, max_y = min_x+dx, min_y+dy
	for __, shape in self:ipairs() do
		local mix, miy, x, y = shape:getBbox()
        local max, may = mix+x, miy+y
		if mix < min_x then min_x = mix end
		if max > max_x then max_x = max end
		if miy < min_y then min_y = miy end
		if may > max_y then max_y = may end
	end
    -- Return rect info as separate values (don't create a table (aka garbage)!)
	return min_x, min_y, max_x-min_x, max_y-min_y
end

-- Remove shape(s) from collider
---@param index number
---@return nil
function Collider:remove(index, ...)
    if not index then return end
    pop(self.shapes, index) -- hopefully no one makes a collider with 1000's of shapes
    return self:remove(...)
end

---Simplifies collider by merging convex, incident shapes
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

---Draw Collider
---@param mode string fill/line/rainbow
function Collider:draw(mode)
    mode = mode or 'line'
    for _, shape in self:ipairs() do
        if mode == 'rainbow' then love.graphics.setColor(love.math.random(), love.math.random(), love.math.random()) end
        shape:draw(mode)
        love.graphics.points(shape.centroid.x, shape.centroid.y)
        love.graphics.print(_,shape.centroid.x, shape.centroid.y)
    end
end

return Collider