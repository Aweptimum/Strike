local Object = Libs.classic

local push, pop = table.insert, table.remove

---@class Pool : table Interface
---@field pool table
---@field limit number maximum number of instances
Pool = Object:extend()

Pool.pool = {}
Pool.limit = 128

---Get size of object pool
---@return number size
function Pool:getPoolSize()
	return #self.pool
end

---Set size of objectp ool
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
---@vararg Object
---@return nil
function Pool:stow( obj, ... )
	if not obj or #self.pool >= self.limit then return end
	push(self.pool, obj)
    print('pool size: '..self:getPoolSize())
    return self:stow( ... )
end

return Pool