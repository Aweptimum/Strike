local S   = require (string.gsub(..., 'algs.ccd','.Strike' ))
local MTV = require (string.gsub(..., 'algs.ccd','classes.mtv' ))
local Vec = require (string.gsub(..., 'algs.ccd','lib.DeWallua.vector-light'))

local SAT = S.AT
local slop = 0.000001
local function clamp(n)
    return n > 1 and 1 or n < 0 and 0
end

---@class CcdState : Object
local CcdState = Libs.classic:extend()

function CcdState:new(sweep1, sweep2, t)
    self.sweep1 = sweep1
    self.sweep2 = sweep2
    self.shape1 = sweep1.body
    self.shape2 = sweep2.body
    self.axis = MTV()
    self.features = {}
    self.cache = {}
end

---Get the distance between two points
---@param px number x coord of first point
---@param py number y coord of first point
---@param qx number x coord of second point
---@param qy number y coord of second point
---@return number dist
local function point_to_point_dist(px,py, qx, qy)
    local vx, vy = qx - px, qy - py
    return MTV(vx,vy) -- return Vec.dist(vx, vy)
end

---Get the shortest distance between a point and a line
---https://stackoverflow.com/a/1501725/12135804
---@param px number x coordinate
---@param py number y coordinate
---@param edge table feature
---@return number dist
local function point_to_line_dist(px,py, edge)
    local e1x, e1y = edge[1].x, edge[1].x
    local e2x, e2y = edge[2].x, edge[2].x
    local l2 = Vec.dist2(e1x, e1y, e2x, e2y)
    if l2 == 0 then return Vec.dist2(px,py, e1x, e1y) end
    local t = ((px-e1x) * (e2x - e1x) + (py - e1y) * (e2y - e1y)) / l2
    t = math.max(0, math.min(1,t))
    local npx = e1x + t * (e2x - e1x)
    local npy = e1y + t * (e2y - e1y)
    return MTV(npx-px, npy-py) --Vec.dist(px, py, npx, npy)
end

---Get the shortest distance between two lines
---@param e1 any
---@param e2 any
---@return number p1x, number p1y, number p2x, number p2y
local function line_to_line_dist(e1, e2)
    local a0, a1 = e1[1], e1[2]
    local b0, b1 = e2[1], e2[2]
   -- calculate denom
   local ax, ay = a1.x - a0.x, a1.y - a0.y
   local bx, by = b1.x - b0.x, b1.y - b0.y
   local maga, magb = Vec.dist(ax,ay), Vec.dist(bx,by)
   local nax, nay = Vec.normalize(ax, ay)
   local nbx, nby = Vec.normalize(bx, by)
   local cross = Vec.cross(nax,nay, nbx, nby)
   local denom = Vec.dist2(Vec.cross(nax, nay, nbx, nby))

   -- Check for overlap
   if denom == 0 then
        local fx,fy = b0.x - a0.x, b0.y - a0.y
        local d0 = Vec.dot(nax,nay, fx,fy)
        local gx, gy = b1.x - a0.x, b1.y - a0.y
        local d1 = Vec.dot(nax,nay, gx,gy)
        if (d0 <= 0 and 0 >= d1) then
            if math.abs(d0) > math.abs(d1) then
                return MTV(fx,fy) --a0.x,a0.y, b0.x,b0.y --Vec.dist(fx, fy)
            else
                return MTV(gx,gy) --a0.x,a0.y, b1.x,b1.y --Vec.dist(gx, gy)
            end
        elseif d0 >= maga and maga <= d1 then
            if math.abs(d0) < math.abs(d1) then
                -- a1 - b0
                local hx, hy = a1.x - b0.x, a1.y - b0.y
                return MTV(hx,hy) --a1.x,a1.y, b0.x,b0.y --Vec.dist(hx,hy)
            else
                local ix, iy = a1.x - b1.x, a1.y - b1.y
                return MTV(ix,iy) --a1.x,a1.y, b1.x,b1.y --Vec.dist(ix,iy)
            end
        else
            -- segments overlap, return dist between parallel segments
            local sx,sy = Vec.mul(d0, nax, nay)
            sx,sy = sx + a0.x - b0.x, sy + a0.y - b0.y
            return Vec.dist(sx,sy)
        end
   end

   -- Lines criss-cross
   local tx,ty = e2[1].x - e1[1].x, e2[1].y - e1[1].y
   -- det of 3x3 [t, b, cross]
   local deta = tx*nby*cross - ty*nbx*cross
   local detb = tx*nay*cross - ty*nax*cross

   local t0 = clamp(deta / denom)
   local t1 = clamp(detb / denom)

   local pax, pay = Vec.mul(t0, nax,nay)
   pax,pay = a0.x + pax, a0.y + pay

   local pbx, pby = Vec.mul(t1, nbx,nby)
   pbx, pby = b0.x + pbx, b0.y + pby

   return Vec.dist(pax,pay, pbx,pby)
end

local function feature_distance(f1, f2)
    -- We have a point and (maybe) an edge

end

---Advance the state to time t
---@param t number [0,1]
---@return CcdState
function CcdState:sweep(t)
    self.sweep1:apply(t) self.sweep2:apply(t)
    return self
end

function CcdState:seen(dx,dy)
    for i, vec in ipairs(self.cache) do
        if math.abs(Vec.det(vec.x,vec.y, dx,dy)) < 0.0001 then return true end
    end
    table.insert(self.cache, {x=dx,y=dy})
    return false
end

---Get an axis at time t
---@param t number [0, 1]
---@return MTV axis
function CcdState:initAxis(t)
    self:sweep(t)
    local mtv = SAT(self.sweep1.body, self.sweep2.body)
    self.axis = mtv
    return mtv
end

function CcdState:evaluateAxis(t)
    local axis, shape1, shape2 = self.axis, self.shape1, self.shape2
    local f1,f2 = self.features[shape1], self.features[shape2]
    self:sweep(t)
    local nx,ny = axis:norm()
    local e1,e2 = shape1.vertices[f1], shape2.vertices[f2]
    local dx,dy = Vec.sub(e2.x,e2.y, e1.x,e1.y)
    local separation = Vec.dot(dx,dy, nx,ny)
    return separation
end

---Get features of both shapes, calculate separation between the 2 features
---@param mtv any
---@return number distance between two shapes
function CcdState:getSeparation(mtv)
    local shape1, shape2 = mtv.colliderShape, mtv.collidedShape
    local nx,ny = mtv:norm()
    local f1, f2 = shape1:getFeature(nx,ny), shape2:getFeature(-nx,-ny)
    self.features[shape1], self.features[shape2] = f1, f2
    local e1, e2 = shape1.vertices[f1], shape2.vertices[f2]
    local dx,dy = Vec.sub(e2.x,e2.y, e1.x,e1.y)
    local separation = Vec.dot(dx,dy, nx,ny)
    return separation
end

function CcdState:getMinSeparation(t)
    self:sweep(t)
    return self:getSeparation(self.axis)
end

local function time_of_impact(sweep1, sweep2)
    local state = CcdState(sweep1, sweep2, 0)
    local shape1, shape2 = sweep1.body, sweep2.body
    --local totalradius = shape1:getRadius() + shape2:getRadius()
    --local target = math.max(slop, totalradius)
    local target = slop
    local tolerance = 0.5

    local t1, t2 = 0, 1
    local max_itrs = 20
    local iter = 0
    local push_back_ters = sweep1.body:getVertexCount() + sweep2.body:getVertexCount()
    -- The outer loop progressively attempts to compute new separating axes.
    for i = iter, max_itrs do
        state:sweep(t1)
        -- Get separating axis (if 'from' is a number then it's an MTV)
        local from, mtv = state:initAxis(t1)

        --If the shapes are overlapped, we give up on continuous collision.
        if from then
            --print('overlapped')
            return 0
        end

        -- Get distance between support points along separating axis
        local separation = state:getSeparation(mtv)

        if separation < target + tolerance then
            --print('touching')
            return t1
        end

        --Compute the TOI on the separating axis. We do this by successively
        --resolving the deepest point. This loop is bounded by the number of vertices.
        local done = false
        t2 = 1
        for i = 1, push_back_ters do
            -- find the deepest points at t2, store their indices
            local s2 = state:getMinSeparation(t2)
            -- Is the final configuration separated?
            if s2 > target + tolerance then
                --print('final config separated')
                --print('s2('..s2..') > '..target..'+'..tolerance)
                return 1
            end

            -- Has the separation reached tolerance?
            if s2 > target - tolerance then
                --print('s2('..s2..') > '..target..'-'..tolerance)
                t1 = t2
                break
            end

            local s1 = state:evaluateAxis(t1)
            if s1 < target - tolerance then
                --print('overlap')
                --print('s1 ('..s1..') < '..target..'-'..tolerance)
                return t1
            end

            -- Check for touching
            if s1 <= target + tolerance then
                --print('touching')
                --print('s1 ('..s1..') < '..target..'+'..tolerance)
                return t1
            end

            -- Compute root
            local root_iters = 0
            local root_iters_max = 50
            local a1, a2 = t1, t2
            while root_iters < root_iters_max do
                --print('t1: '..t1..', t2: '..t2)
                local t
                if root_iters % 2 == 0 then
                    t = a1 + (target - s1) * (a2 - a1) / (s2 - s1)
                else
                    t = 0.5 * (a1 + a2)
                end
                root_iters = root_iters + 1

                local s = state:evaluateAxis(t)

                if math.abs(s - target) < tolerance then
                    t2 = t
                    break
                end
                if s > target then
                    a1 = t
                    s1 = s
                else
                    a2 = t
                    s2 = s
                end
            end
        end
    end
    -- failure
    return false
end

return time_of_impact