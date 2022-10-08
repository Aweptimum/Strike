-- "Abstract" base object, provides some generic methods.
local Object = Libs.classic
local Transform = _Require_relative(..., 'classes.Transform', 1)

---@class Shape : Object
---@field public transform Transform
---@field public area number
---@field public radius number
---@field public vertices Point[]
---@field public parent nil|Shape|Collider
local Shape = Object:extend()

Shape.name = 'shape'
Shape.type = 'shape'
Shape.area = 0
Shape.radius = 0
Shape.vertices = {}
Shape.parent = nil

function Shape:new(transform)
	self.transform = transform or Transform()
end

function Shape.fromComponents(x,y,ca,sa)
	return Shape(
		Transform(x,y,ca,sa)
	)
end

---@return Transform
function Shape:getTransform()
	return self.transform
end

---@param transform Transform
---@return Shape self
function Shape:setTransform(transform)
	self.transform = transform
	return self
end

---Get Shape's root container
---@return Collider | Shape
function Shape:getRoot()
	local s = self
	while s.parent do
		s = s.parent
	end
	return s
end

---@return number area
function Shape:getArea()
    return self.area * self.transform.s * self.transform.s
end

---@return number x
---@return number y
function Shape:getCentroid()
    return self.transform:getTranslation()
end

function Shape:getRadius()
	return self.radius * self.transform.s
end

function Shape:getBbox()
end

function Shape:project()
end

function Shape:unpack()
end

---Rotate by specified radians
---@param a number radians
---@param x ?number reference x-coordinate to rotate about
---@param y ?number reference y-coordinate to rotate about
---@return Shape self
function Shape:rotate(a,x,y)
	self.transform:rotateA(a,x,y)
	return self
end

---@param a number
---@param x number x coordinate to rotate about
---@param y number y coordinate to rotate about
---@return Shape self
function Shape:rotateTo(a, x, y)
	self.transform:rotateToA(a, x, y)
	return self
end

---Scale shape by a factor (multiplies previous factor)
---@param sf number scale factor
---@param sx ?number reference x-coordinate
---@param sy ?number reference y-coordinate
---@return Shape self
function Shape:scale(sf, sx, sy)
	self.transform:scale(sf, sx, sy)
	return self
end

---Scale shape by a factor (sets factor)
---@param sf number scale factor
---@param sx ?number reference x-coordinate
---@param sy ?number reference y-coordinate
---@return Shape self
function Shape:scaleTo(sf, sx, sy)
	self.transform:scaleTo(sf, sx, sy)
	return self
end

---Translate by displacement vector
---@param x number
---@param y number
---@return Shape self
function Shape:translate(x,y)
	self.transform:translate(x,y)
	return self
end

---@param x number
---@param y number
---@return Shape self
function Shape:translateTo(x, y)
	self.transform:translateTo(x, y)
	return self
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