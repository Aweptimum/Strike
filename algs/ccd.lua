local S = require (string.gsub(..., '.ccd','.Strike' ))
local MTV = _Require_relative(..., 'classes.MTV')
local Vec		= _Require_relative( ... , 'lib.DeWallua.vector-light')
local tbl = Libs.tbl

local SAT = S.AT
local slop = 0.000001

local ccdState = Libs.classic:extend()

function ccdState:new(sweep1, sweep2, t)
    self.sweep1 = sweep1
    self.sweep2 = sweep2
    self.shape1 = sweep1.body
    self.shape2 = sweep2.body
    self.axis = MTV()
    self.indxs = {
        [self.shape1] = 1,
        [self.shape2] = 1
    }
    self.cache = {}
end

function ccdState:sweep(t)
    self.sweep1:apply(t) self.sweep2:apply(t)
    return self
end

function ccdState:seen(dx,dy)
    --print(tostring(self.cache))
    for i, vec in ipairs(self.cache) do
        if math.abs(Vec.det(vec.x,vec.y, dx,dy)) < 0.0001 then return true end
    end
    --print('added to cache')
    table.insert(self.cache, {x=dx,y=dy})
    return false
end

function ccdState:init_axis(t)
    self:sweep(t)
    local from, mtv = SAT(self.sweep1.body, self.sweep2.body)
    self.axis = mtv
    local v = Vec.str(Vec.normalize(mtv.x,mtv.y))
    --print('init axis: '..v)
    --print('at t: '..tostring(t))
    return from, mtv
end

function ccdState:evaluate_axis(t)
    local axis, shape1, shape2 = self.axis, self.shape1, self.shape2
    local idx1,idx2 = self.indxs[shape1], self.indxs[shape2]
    self:sweep(t)
    local nx,ny = Vec.normalize(axis.x,axis.y)
    local e1,e2 = shape1.vertices[idx1], shape2.vertices[idx2]
    local dx,dy = Vec.sub(e2.x,e2.y, e1.x,e1.y)
    local separation = Vec.dot(dx,dy, nx,ny)
    return separation
end

function ccdState:get_separation(mtv)
    local shape1, shape2 = mtv.colliderShape, mtv.collidedShape
    local nx,ny = Vec.normalize(mtv.x,mtv.y)
    local idx1, idx2 = shape1:getSupport(nx,ny), shape2:getSupport(-nx,-ny)
    self.indxs[shape1], self.indxs[shape2] = idx1, idx2
    local e1, e2 = shape1.vertices[idx1], shape2.vertices[idx2]
    local dx,dy = Vec.sub(e2.x,e2.y, e1.x,e1.y)
    local separation = Vec.dot(dx,dy, nx,ny)
    return separation
end

function ccdState:find_min_separation(t)
    self:sweep(t)
    return self:get_separation(self.axis)
end

local function time_of_impact(sweep1, sweep2)
    local state = ccdState(sweep1, sweep2, 0)
    local shape1, shape2 = sweep1.body, sweep2.body
    local totalradius = shape1:getRadius() + shape2:getRadius()
    local target = math.max(slop, totalradius)
    target = slop
    --print('target: '..target)
    local tolerance = 0.25 * slop

    local t1, t2 = 0, 1
    local max_itrs = 20
    local iter = 0
    -- The outer loop progressively attempts to compute new separating axes.
    for i = iter, max_itrs do
        state:sweep(t1)
        -- Get separating axis (if 'from' is a number then it's an MTV)
        local from, mtv = state:init_axis(t1)
        state:seen(mtv.x,mtv.y)
        --tbl.tprint(state.cache)
        --If the shapes are overlapped, we give up on continuous collision.
        if from then
            --print('overlapped')
            return 0
        end

        -- Get distance between support points along separating axis
        local separation = state:get_separation(mtv)

        if separation < target + tolerance then
            --print('touching')
            return t1
        end

        --Compute the TOI on the separating axis. We do this by successively
        --resolving the deepest point. This loop is bounded by the number of vertices.
        local done = false
        local push_back_ters = 0
        t2 = 1
        while true do
            -- find the deepest points at t2, store their indices
            local s2 = state:find_min_separation(t2)
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

            local s1 = state:evaluate_axis(t1)
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

                local s = state:evaluate_axis(t)

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
    return 'failure'
end

local function TOI(sweep1, sweep2)
    local t = time_of_impact(sweep1, sweep2)
    if type(t) == 'number' then
        --sweep2:apply(t)
        --sweep1:apply(t)
    end
    --print('t: '..tostring(t))
    return t
end

return TOI