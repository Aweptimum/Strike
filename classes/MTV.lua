local Vec = _Require_relative( ... , "lib.DeWallua.vector-light", 1)
local Object = Libs.classic
---@type Pool
local Pool = _Require_relative( ..., 'Pool')

---@class MTV : Object, Pool
---@field x number
---@field y number
---@field collider Collider the collider this MTV is oriented from
---@field collided Collider the collider this MTV is oriented to
---@field collidedShape Shape the shape this MTV is oriented to
---@field colliderShape Shape the shape this MTV is oriented from
---@field separating boolean true = separating axis, false = overlapping axis
local MTV = Object:extend():implement(Pool)

---MTV ctor
---@param dx number magnitude of x-component
---@param dy number magnitude of y-component
---@param rshape Shape mtv oriented from
---@param dshape Shape mtv oriented towards
function MTV:new(dx, dy, rshape, dshape, separating)
	self.x, self.y = dx or 0, dy or 0
	self.colliderShape = rshape
	self.collidedShape = dshape
	self.separating = separating or not true
	self.edgeIndex = 0
end

---Get MTV magnitude
---@return number
function MTV:mag()
	return Vec.len(self.x, self.y)
end

---Get MTV magnitude squared
---@return number
function MTV:mag2()
	return Vec.len2(self.x, self.y)
end

function MTV:scale(s)
	self.x, self.y = s*self.x, s*self.y
	return self
end

---Set the mtv's reference
---@param collider Collider
function MTV:setCollider(collider)
	self.collider = collider
	return self
end

---Set the mtv's reference *shape*
---@param shape Shape
function MTV:setColliderShape(shape)
	self.colliderShape = shape
	return self
end

---Get edge at index
---@param index number index of colliderShape's edge that generated mtv
function MTV:setEdgeIndex(index)
	self.edgeIndex = index
	return self
end

---Set mtv's hit collider
---@param collider Collider
function MTV:setCollided(collider)
	self.collided = collider
	return self
end

---Set mtv's hit collider's *shape*
---@param shape Shape
function MTV:setCollidedShape(shape)
	self.collidedShape = shape
	return self
end

---Set separation flag to true/false
---@param bool boolean
---@return MTV self
function MTV:setSeparating(bool)
	self.separating = bool
	return self
end

return MTV