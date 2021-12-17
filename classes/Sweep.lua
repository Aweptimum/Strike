local Object = Libs.classic
local Transform = _Require_relative( ..., 'Transform')
local pi, floor = math.pi, math.floor
local cos, sin = math.cos, math.sin

---@class Sweep : Object
---@field body Shape the shape being swept
---@field t1 Transform transformation at t = 0
---@field t2 Transform transformation at t = 1
---@field t1a number cached angle at t = 0
---@field t2a number cached angle at t = 1 
---@field alpha number current t [0, 1]
local Sweep = Object:extend()

local function clamp(n)
    return n > 1 and 1 or n < 0 and 0
end

---comment
---@param body Shape
---@param x2 number final x coordinate at t = 1
---@param y2 number final y coordinate at t = 1
---@param a2 number final angle at t = 1 (radians)
---@param alpha number [0,1] t (defaults to 0)
function Sweep:new(body, x2,y2,a2, alpha)
    self.body = body
    self.t1 = body:getTransform()
    self.t1a = self.t1:getAngle()
    self.t2 = Transform.fromAngle(x2,y2,a2)
    self.t2a = self.t2:getAngle()
    self.alpha = alpha or 0
end

---Get the currently interpolated transform
---@param beta number [0,1] value of t
---@param t ?Transform copies values into supplied transform
---@return any
function Sweep:getTransform(beta, t)
    beta = beta and clamp(beta) or 0
    t = t or Transform()
    -- get vars
    local x1, x2 = self.t1.x, self.t2.x
    local y1, y2 = self.t1.y, self.t2.y
    local s1, s2 = self.t1.s, self.t2.s
    local a1, a2 = self.t1a, self.t2a
    -- interpolate
    local tx = x1 + beta*(x2-x1)
    local ty = y1 + beta*(y2-y1)
    local ts = s1 + beta*(s2-s1)
    local ta = a1 + beta*(a2-a1)
    local cosa, sina = cos(ta), sin(ta)
    -- init the transform to use the interpolated values
    t:new(tx, ty, cosa, sina, ts)
    return t
end

function Sweep:getShape()
    return self.body
end

function Sweep:normalize()
    local a1, a2 = self.t1a, self.t2a
    local d = a2 -  (2*pi)* floor((a2 + pi) / (2*pi))
    self.t1a = a1 - d
    self.t2a = a2 - d
    return self
end

---Apply sweep @ beta [0-1] to body
---@param beta number [0-1]
---@return Shape self.body
function Sweep:apply(beta)
    local t = self:getTransform(beta)
    return self.body:setTransform(t)
end

function Sweep:resetBody()
    return self.body:setTransform(self.t1)
end

return Sweep