local Object = Libs.classic
---@type Pool
--local Pool = _Require_relative( ..., 'Pool')

---@class Transform : Object, Pool
---@field x number
---@field y number
---@field angle number
local Transform = Object:extend()--:implement(Pool)

function Transform:new(x,y,a)
    self.x = x or 0
    self.y = y or 0
    self.a = a or 0
end

---Apply transform to a Shape/Collider
---@param body Shape | Collider
---@return Shape | Collider
function Transform:apply(body)
    return body:translateTo(self.x,self.y):rotateTo(self.a)
end

return Transform