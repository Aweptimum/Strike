local Object = Libs.classic
local Pool = _Require_relative( ..., 'Pool')
local abs, min, max, floor, sqrt = math.abs, math.min, math.max, math.floor, math.sqrt
local push = table.insert

---@class Box
local Box = Object:extend():implement(Pool)

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

---@class Cell
local Cell = Object:extend()

function Cell:new(body, ...)
    if not body then return end
    push(self, body)
    self:new(...)
end

function Cell:has(body)
    for i = 1, #self do
        if self[i] == body then
            return i
        end
    end
    return false
end

function Cell:add(body, ...)
    if not body then return self end
    if not self:has(body) then
        push(self, body)
    end
    self:add(...)
end

function Cell:remove(body, i)
    if not body then return self end
    i = i or self:has(body)
    if i then
        self[i], self[#self] = self[#self], nil
        return true
    end
    return false
end

---@class Space
---@field cellsize number
---@field bodies table hashmap of stored items
---@field cells Cell[] array-map of buckets
Space = Object:extend()

---Ctor
---@param cellsize number defaults to 128
function Space:new(cellsize)
    self.cellsize = cellsize or 128
    self.cells = {}
    self.bodies = {}
end

-- World-cell-key functions
function Space:toWorld(cx, cy)
    return (cx)*self.cellsize, (cy)*self.cellsize
end

function Space:toCell(x, y)
    return floor(x / self.cellsize) , floor(y / self.cellsize)
end
-- Hash function inspired by this: https://stackoverflow.com/a/919661/12135804
local function transform(x)
    return x >= 0 and x*2 or -x*2 - 1
end

function Space:cellToKey(cx,cy)
    cx,cy = transform(cx), transform(cy)
    return cx + cy*1e10
end

local function revert(x)
    return x%2 == 0 and x/2 or (x+1)/-2
end

function Space:keyToCell(key)
    key = key / 1e10
    local y,x = math.modf(key)
    x = math.modf(x *1e10)
    x,y = revert(x), revert(y)
    return x,y
end

-- CRUD cell functions
function Space:addCell(cx,cy)
    local key = self:cellToKey(cx,cy)
    if not self.cells[key] then
        self.cells[key] = Cell()
    end
end

function Space:getCell(cx,cy)
    return self.cells[self:cellToKey(cx,cy)], self:cellToKey(cx,cy)
end

function Space:getWorld(x,y)
    return self:getCell(self:toCell(x, y))
end

function Space:coalesceCell(cx,cy)
    local c = self:getCell(cx,cy)
    if not c then
        self:addCell(cx,cy)
    end
    return self:getCell(cx,cy)
end

function Space:addToCell(cx, cy, body)
    return self:coalesceCell(cx,cy):add(body)
end

function Space:coalesceWorld(x,y)
    return self:coalesceCell(self:toCell(x, y))
end

function Space:removeFromCell(cx, cy, body)
    local c = self:getCell(cx,cy)
    if not c then return false end
    local i = c:has(body)
    if i then
        if #c == 1 then
            self:removeCell(cx,cy)
        else
            return c:remove(body, i)
        end
    end
    return false
end

function Space:removeCell(cx,cy)
    self.cells[self:cellToKey(cx,cy)] = nil
end

function Space:removeWorld(x,y)
    return self:removeCell(self:toCell(x, y))
end

--CRUD body/item functions
function Space:add(body, x,y,w,h)
    if self.bodies[body] then return false end
    local box = x and Box(x,y,w,h) or Box(body)
    self.bodies[body] = box
    x,y,w,h = box[1], box[2], box[3], box[4]
    local ix, iy = self:toCell(x,y)
    local jx, jy = self:toCell(x+w,y+h)
    print('coords: '..ix..', '..iy..'-'..jx..', '..jy)
    for cx = ix, jx do
        for cy = iy, jy do
            self:addToCell(cx,cy, body)
        end
    end
    return true
end

function Space:remove(body)
    if not self.bodies[body] then return end
    local box = self.bodies[body]
    local x,y,w,h = box[1], box[2], box[3], box[4]
    local ix, iy = self:toCell(x,y)
    local jx, jy = self:toCell(x+w,y+h)
    print('coords: '..ix..', '..iy..'-'..jx..', '..jy)
    for cx = ix, jx do
        for cy = iy, jy do
            self:removeFromCell(cx,cy, box)
        end
    end
end

function Space:update()
    for body, box in pairs(self.bodies) do
        local ox,oy,ow,oh = box:getBbox()
        local nx,ny,nw,nh = body:getBbox()
        -- potentially old
        local ax, ay = self:toCell(ox,oy)
        local adx, ady =  self:toCell(ox+ow,oy+oh)
        -- potentially new
        local bx, by = self:toCell(nx,ny)
        local bdx, bdy = self:toCell(nx+nw,ny+nh)
        local stale = ax ~= bx or ay ~= by or adx ~= bdx or ady ~= bdy
        if stale then
            local cxOut
            for cx = ax, adx do
                cxOut = cx < bx or cx > bdx
                for cy = ay, ady do
                    if cxOut or (cy < by or cy > bdy) then
                        self:removeFromCell(cx,cy, body)
                    end
                end
            end
            -- Now add
            for cx = bx, bdx do
                cxOut = cx < ax or cx > adx
                for cy = ay, ady do
                    if cxOut or (cy < ay or cy > ady) then
                        self:addToCell(cx,cy, body)
                    end
                end
            end
            self.bodies[body] = box
        end
    end
end

function Space:clear()
    self.bodies, self.cells = {}, {}
end

-- Query functions


-- Fast-Voxel Traversal
--https://github.com/OneLoneCoder/olcPixelGameEngine/blob/12f634007c617e0fc3c7b8c5991f5310ea1b22b0/Videos/OneLoneCoder_PGE_RayCastDDA.cpp#L95
local function len(x,y)
	return sqrt(x*x + y*y)
end

-- Get sign of number
local function sign(number)
    return (number > 0 and 1 or (number == 0 and 0 or -1))
end

local function unit_step(x,y)
    return sqrt(1+(y/x)^2), sqrt(1+(x/y)^2)
end

local function frac(dir, n)
    local f = dir < 0 and n - floor(n) or floor(n+1)-n
    return f
end

local function tmax(dir, delta, origin)
    return delta*frac(dir,origin)
end

function Space:line_traverse(x1,y1,x2,y2, f)
    local cs = self.cellsize
    local cx1,cy1        = self:toCell(x1,y1)
    local cx2,cy2        = self:toCell(x2,y2)
    local rdx, rdy = x2-x1, y2-y1
    local l = len(rdx,rdy)
    local nx,ny = rdx/l, rdy/l
    local stepX, stepY = sign(rdx), sign(rdy)
    local dx,dy = unit_step(nx,ny)
    local tx,ty = tmax(nx, dx, x1/cs), tmax(ny, dy,y1/cs)

    local cx,cy          = cx1,cy1
    if f then f(cx, cy) end

    while abs(cx2 - cx) + abs(cy2 - cy) > 1 do
        if tx < ty then
            tx, cx = tx + dx, cx + stepX
        else
            ty, cy = ty + dy, cy + stepY
        end
        if f then f(cx, cy) end
    end

    -- If we have not arrived to the last cell, use it
    if cx ~= cx2 or cy ~= cy2 then
        if f then f(cx2, cy2) end
    end
end


function Space:line_traverse_debug(x1,y1, x2,y2)
    local draw = function (cx,cy)
        self:drawCell(cx,cy,'fill')
    end
    self:line_traverse(x1,y1,x2,y2, draw)
end
function Space:drawCell(cx,cy, mode)
    local wx,wy = cx*self.cellsize, cy*self.cellsize
    love.graphics.rectangle(mode or 'line', wx,wy, self.cellsize, self.cellsize)
end

function Space:draw(mode, show_empty, print_key)
	show_empty = show_empty or not true
	for key, cell in pairs(self.cells) do
        if show_empty or cell[1] then
            local cx,cy = self:keyToCell(key)
            self:drawCell(cx,cy, mode)
            if print_key then
                love.graphics.print(("%d"):format(key), cx*self.cellsize+3,cy*self.cellsize+3)
            end
        end
    end
end

return Space