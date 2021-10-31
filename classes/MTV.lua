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
local MTV = Object:extend()
MTV:implement(Pool)

---MTV ctor
---@param dx number magnitude of x-component
---@param dy number magnitude of y-component
---@param collider Collider mtv oriented from
---@param collided Collider mtv oriented towards
function MTV:new(dx, dy, collider, collided)
	self.x, self.y = dx or 0, dy or 0
	self.collider = collider or 'none'
	self.collided = collided or 'none'
	self.colliderShape = 'none'
	self.collidedShape = 'none'
	self.edgeIndex = 0
end

---Get MTV magnitude
---@return number
function MTV:mag()
	return Vec.len(self.x, self.y)
end

---Set the mtv's reference
---@param collider Collider
function MTV:setCollider(collider)
	self.collider = collider
end

---Set the mtv's reference *shape*
---@param shape Shape
function MTV:setColliderShape(shape)
	self.colliderShape = shape
end

---Get edge at index
---@param index number index of colliderShape's edge that generated mtv
function MTV:setEdgeIndex(index)
	self.edgeIndex = index
end

---Set mtv's hit collider
---@param collider Collider
function MTV:setCollided(collider)
	self.collided = collider
end

---Set mtv's hit collider's *shape*
---@param shape Shape
function MTV:setCollidedShape(shape)
	self.collidedShape = shape
end

return MTV