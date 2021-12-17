local Object = Libs.classic
local Transform = _Require_relative( ..., 'Transform')
local pi, floor = math.pi, math.floor

---@class Sweep : Object
---@field t1 Transform
---@field t2 Transform
---@field alpha number
local Sweep = Object:extend()

function Sweep:new(body, x2,y2,a2, alpha)
    self.body = body
    local x1,y1,a1 = body.centroid.x, body.centroid.y, body.angle
    self.t1, self.t2 = Transform(x1,y1,a1), Transform(x2,y2,a2)
    self.a = alpha or 0
end

function Sweep:getTransform(beta, t)
    beta = beta or 0
    t = t or Transform()
    local x1, x2 = self.t1.x, self.t2.x
    local y1, y2 = self.t1.y, self.t2.y
    local a1, a2 = self.t1.a, self.t2.a
    t.x = x1 + beta*(x2-x1)
    t.y = y1 + beta*(y2-y1)
    t.a = a1 + beta*(a2-a1)
    return t
end

function Sweep:normalize()
    local a1, a2 = self.t1.a, self.t2.a
    local d = a2 -  (2*pi)* floor((a2 + pi) / (2*pi))
    self.t1.a = a1 - d
    self.t2.a = a2 - d
    return self
end

---Apply sweep @ beta [0-1] to body
---@param beta number [0-1]
---@return Shape | Collider self.body
function Sweep:apply(beta)
    local t = self:getTransform(beta)
    return t:apply(self.body)
end

function Sweep:resetBody()
    return self:apply(0)
end

return Sweep