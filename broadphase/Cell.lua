local Object = Libs.classic
local push = table.insert

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

return Cell