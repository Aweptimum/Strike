local Object = Libs.classic
local Pool = _Require_relative( ..., 'classes.Pool', 1)
local min, max = math.min, math.max
---@class Box
Box = Object:extend():implement(Pool)

function Box:new(x,y,w,h)
    if type(x) == 'table' and x.getBbox then self:new(x:getBbox()) return end
    self[1] = x or 0
    self[2] = y or 0
    self[3] = w or 0
    self[4] = h or 0
end

function Box:getBbox()
    return self[1], self[2], self[3], self[4]
end

function Box:overlaps(other)
    return self[3] > other[1] and self[1] < other[3] and self[4] > other[2] and self[2] < other[4]
end

function Box:rayIntersects(x1,y1, x2,y2)
    local invx, invy = 1/(x2-x1), 1/(y2-y1)
    local tx1 = (self[1] - x1)*invx;
    local tx2 = (self[1]+self[3] - x1)*invx;

    local tmin = min(tx1, tx2)
    local tmax = max(tx1, tx2)

    local ty1 = (self[2] - y1)*invy
    local ty2 = (self[2]+self[4]- y1)*invy

    tmin = max(tmin, min(ty1, ty2))
    tmax = min(tmax, max(ty1, ty2))

    return tmax >= tmin
end

return Box