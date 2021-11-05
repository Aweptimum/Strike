local Object = Libs.classic

local push, pop = table.insert, table.remove

---@class Pool : table Mixin
---@field pool table
---@field limit number maximum number of instances
local Pool = Object:extend()

Pool.pool = {}
Pool.limit = 128

---Get size of object pool
---@return number size
function Pool:getPoolSize()
	return #self.pool
end

---Set size of object pool
---@param size number
---@return Object self
function Pool:setPoolSize(size)
    self.limit = size
	return self
end

---Fetch a pooled instance and init to given args
---@generic T : Object
---@return T
function Pool:fetch( ... )
	local p = #self.pool >0 and pop(self.pool) or self( ... )
	p:new( ... )
	return p
end

---Stow variable # of instances in Class pool
---
---**relies on class's :new functioning as a reset when no args passed
---@vararg Object
---@param obj Object
---@return nil
function Pool:stow( obj, ... )
	if not obj or #self.pool >= self.limit then return end
	obj:new() -- use :new as :reset
	push(self.pool, obj)
    return self:stow( ... )
end

return Pool