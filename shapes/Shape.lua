-- "Abstract" base object, provides some generic methods.
local Object = Libs.classic

---@class Shape
---@field public centroid Point
---@field public area number
---@field public radius number
local Shape = Object:extend()

Shape.type = 'shape'

---@return number area
function Shape:getArea()
    return self.area
end

---@return Point self.centroid
function Shape:getCentroid()
    return self.centroid
end

---@return number area, table centroid
function Shape:getAreaCentroid()
    return self.area, self.centroid
end

function Shape:getRadius()
	return self.radius
end

function Shape:getBbox()
end

function Shape:project()
end

function Shape:unpack()
end

function Shape:translate()
end

---@param x number
---@param y number
---@return Shape self
function Shape:translateTo(x, y)
	local dx, dy = x - self.centroid.x, y - self.centroid.y
	return self:translate(dx,dy)
end

function Shape:rotate()
end

---@param angle_rads number
---@param ref_x number x coordinate to rotate about
---@param ref_y number y coordinate to rotate about
---@return Shape self
function Shape:rotateTo(angle_rads, ref_x, ref_y)
	local aoffset = angle_rads - self.angle
	return self:rotate(aoffset, ref_x, ref_y)
end

function Shape:scale()
end

---@param x number x coordinate to place copy at
---@param y number y coordinate to place copy at
---@param angle_rads number radian offset of copy
---@return Shape copy
function Shape:copy(x, y, angle_rads)
    local copy = self:_copy()
	-- if origin specified, then translate
	if x and y then
		copy:translateTo(x, y)
	end
	-- If rotation specified, then rotate_polygon
	if angle_rads then
		copy:rotateTo(angle_rads)
    end
	-- Return copy
	return copy
end

function Shape:calcArea()
end

function Shape:calcCentroid()
end

function Shape:calcAreaCentroid()
end

return Shape