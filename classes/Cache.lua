-- This Cache class steals cache_get/put from Kikito's memoize.lua
-- https://github.com/kikito/memoize.lua
--[[
    Copyright (c) 2018 Enrique García Cota
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local Object = Libs.classic

---@class Cache
---@field cache table tree structure of weak tables
Cache = Object:extend()

local function wt()
	return setmetatable({}, {__mode = "v"})
end

---Initializes cache to new weak-table
function Cache:new()
    self.cache = wt()
end

---Set result for given params table
---@param params table Array of keys
---@param results table Value/Array of values
function Cache:set(params, results)
    local node = self.cache
    for i = 1, #params do
        local param = params[i]
        node.children = node.children or wt()
        node.children[param] = node.children[param] or wt()
        node = node.children[param]
    end
    node.results = results
end

---Return value for given param table
---@param params table Array of keys
---@return any result Cached value
function Cache:get(params)
    local node = self.cache
    for i = 1, #params do
        node = node.children and node.children[params[i]]
        if not node then return nil end
    end
    return node.results
end

return Cache