local Object = Libs.classic
local cos, sin = math.cos, math.sin
---@type Pool
--local Pool = _Require_relative( ..., 'Pool')

---@class Transform : Object, Pool
---@field x number
---@field y number
---@field cosa number cos term of a 2x2 rotation matrix
---@field sina number sin term of a 2x2 rotation matrix
---@field s number scale factor
local Transform = Object:extend()--:implement(Pool)

function Transform:new(x, y, ca, sa, s)
    self.x = x or 0
    self.y = y or 0
    -- normalize rotation components
    local m = (ca*ca + sa*sa)^0.5
    self.cosa = ca/m
    self.sina = sa/m
    self.s = s or 1
end

function Transform.fromAngle(x, y, a, s)
    local cosa = a and cos(a) or 1
    local sina = a and sin(a) or 0
    return Transform(x, y, cosa, sina, s)
end

---Return the cos and sin components of the angle
---@return number cosa
---@return number sina
function Transform:getRotation()
    return self.cosa, self.sina
end

---Return the scale factor
---@return number s
function Transform:getScale()
    return self.s
end

---Return the x and y coordinates
---@return number x
---@return number y
function Transform:getTranslation()
    return self.x, self.y
end

---Calculates the cos and sin terms of the product of 2 2x2 rotation matrices
---
---Multiplying a 2x2 matrix that has terms (cosa,sina) with one that has (cosb,sinb)
---yields a rotation matrix with the terms (cosa*cosb - sina*sinb, cosa*sinb + cosb*sina)
---@param ca number cos component of angle
---@param sa number sin component of angle
---@param rx ?number reference x coordinate defaults to centroid
---@param ry ?number reference y coordinate defaults to centroid
---@return Transform
function Transform:rotate(ca, sa, rx, ry)
    ca = ca or 1
    sa = sa or 0
    rx = rx or self.x
    ry = ry or self.y
    -- normalize rotation components
    local m = (ca*ca + sa*sa)^0.5
    ca = ca/m
    sa = sa/m

    local cosa = ca * self.cosa - sa * self.sina
    local sina = sa * self.cosa + ca * self.sina

    self.cosa, self.sina = cosa, sina

    -- rotate the translaton about the ref point
    local dx, dy = self.x - rx, self.y - ry
    self.x = ca*dx - sa*dy + rx
    self.y = sa*dx + ca*dy + ry

    return self
end

---Calls :rotate with decomposed angle 
---@param a number angle in radians
---@param rx ?number reference x coordinate defaults to centroid
---@param ry ?number reference y coordinate defaults to centroid
---@return Transform
function Transform:rotateA(a, rx, ry)
    return self:rotate(cos(a), sin(a), rx, ry)
end

---Sets the rotation components
---@param ca number cos component of angle
---@param sa number sin component of angle
---@param rx ?number reference x coordinate defaults to centroid
---@param ry ?number reference y coordinate defaults to centroid
---@return Transform
function Transform:rotateTo(ca, sa, rx, ry)
    ca = ca or 1
    sa = sa or 0
    rx = rx or self.x
    ry = ry or self.y
    -- normalize rotation components
    local m = (ca*ca + sa*sa)^0.5
    ca = ca/m
    sa = sa/m

    self.cosa, self.sina = ca, sa

    -- rotate the translaton about the ref point
    local dx, dy = self.x - rx, self.y - ry
    self.x = ca*dx - sa*dy + rx
    self.y = sa*dx + ca*dy + ry

    return self
end

---Calls :rotateTo with decomposed angle 
---@param a number angle in radians
---@param rx ?number reference x coordinate defaults to centroid
---@param ry ?number reference y coordinate defaults to centroid
---@return Transform self
function Transform:rotateToA(a, rx, ry)
    return self:rotateTo(cos(a), sin(a), rx, ry)
end

---Modify points by a scale multiplier wrt a reference point
---@param s number scale factor (multiplies w/ current scale)
---@param sx number reference x coordinate (defaults to position) 
---@param sy number reference y coordinate (defaults to position)
---@return Transform self
function Transform:scale(s, sx, sy)
    self.s = self.s * s

    -- scale the translaton about the ref point
    local dx, dy = self.x - sx, self.y - sy
    self.x = dx * self.s + sx
    self.y = dy * self.s + sy

    return self
end

---Sets the scale factor about a reference point
---@param s number scale factor
---@param sx number reference x coordinate (defaults to position) 
---@param sy number reference y coordinate (defaults to position)
---@return Transform self
function Transform:scaleTo(s, sx, sy)
    self.s = s

    -- scale the translaton about the ref point
    local dx, dy = self.x - sx, self.y - sy
    self.x = dx * self.s + sx
    self.y = dy * self.s + sy

    return self
end

---Translates the current position by x and y
---@param x number
---@param y number
---@return Transform self
function Transform:translate(x, y)
    self.x = self.x + x
    self.y = self.y + y

    return self
end

---Sets the current position
---@param x number
---@param y number
---@return Transform self
function Transform:translateTo(x, y)
    self.x = x
    self.y = y

    return self
end

---Copy the given transform's values
---@param t any
---@return Transform self
function Transform:setFromTransform(t)
    self.x = t.x
    self.y = t.y
    self.cosa = t.cosa
    self.sina = t.sina
    self.s = t.s
    return self
end

---Return a new copy of this transform
---@return Transform
function Transform:copy()
    return Transform(self.x,self.y,self.cosa,self.sina)
end

---Given a point, return the transformed coordinates
---Scale, rotate, translate
---@param px number x coordinate of point to transform
---@param py number y coordinate of point to transform
---@return number px transformed x coordinate
---@return number pytransformed y coordinate
function Transform:transform(px, py)
    px, py = px * self.s, py * self.s -- scale first
    local x = self.cosa * px - self.sina * py + self.x
    local y = self.sina * px + self.cosa * py + self.y
    return x, y
end

return Transform
