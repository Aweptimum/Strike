local bit 		= require'bit' --https://luajit.org/extensions.html
local Vec		= _Require_relative( ... , "lib.DeWallua.vector-light")
local Object	= _Require_relative( ... , "lib.classic.classic")
local Shapes 	= _Require_relative( ... , "shapes")
local Collider	= _Require_relative( ... , "colliders.Collider")
local Colliders	= _Require_relative( ... , "colliders")

local pi, cos, sin, atan2 = math.pi, math.cos, math.sin, math.atan2
-- atan(y, 0) returns 0, not undefined
local floor, ceil, sqrt, abs, max, min   = math.floor, math.ceil, math.sqrt, math.abs, math.max, math.min
local inf = math.huge
-- Push/pop
local push, pop = table.insert, table.remove

--local _PACKAGE = (...):match("^(.+)%.[^%.]+")

-- Polygon module for creating shapes to strike each other

-- [[---------------------]] Declaration of Spelling Collinear [[---------------------]] --

-- [[ IT IS TO BE DECLARED HEREIN THIS DOCUMENT THAT THE "LL" SPELLING OF COLLINEAR ]] --
-- [[ SHALL BE ADOPTED THROUGHOUT, AS IT'S SPELLED ON WIKIPEDIA. "WHY?" YOU MAY ASK ]] --
-- [[ Well, it's because that's how my vector calculus prof spelled it. Using 1 "L" ]] --
-- [[ just feels a bit wrong, y'know? So accept it. Or change it in your fork, idk. ]] --

-- [[---------------------]]        Utility Functions        [[---------------------]] --

-- Get signs of numbers
local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

-- Create MTV object
local MTV = Object:extend()

function MTV:new(dx, dy, collider, collided)
	self.x, self.y = dx or 0, dy or 0
	self.collider = collider or 'none'
	self.collided = collided or 'none'
end

function MTV:mag()
	return Vec.len(self.x, self.y)
end

function MTV:setCollider(collider)
	self.collider = collider
end

function MTV:setCollided(collider)
	self.collided = collider
end

-- [[---------------------]]         Table Utilities         [[---------------------]] --

-- Print table w/ formatting
function tprint (tbl, height, indent)
	if not tbl then return end
	if not height then height = 0 end
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		height = height+1
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting, indent*8, 16*height)
			tprint(v, height+1, indent+1)
		elseif type(v) == 'function' then
			print(formatting .. "function", indent*8, 16*height)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v), indent*8, 16*height)
		else
			print(formatting .. v, indent*8, 16*height)
		end
	end
end

-- For S.ettings, need an unpacking function that returns BOTH keys and values
-- Modified from this: https://stackoverflow.com/a/60731121/12135804
-- Basically returns new_key in addition to the value
local function unpack_unordered_recursive(tbl, key)
	local new_key, value = next(tbl, key)
	if new_key == nil then return end

	return new_key, value, unpack_unordered_recursive(tbl, new_key)
end

-- Might as well toss this experiment here too
local function unpack_n(tbl, n)
    n = n or #tbl
    if n >= 1 then
        --print(tbl[#tbl-n+1])
        return tbl[#tbl-n+1], unpack_n(tbl, n-1)
    end
end
--local tbl  = {7,8,9}
--local a,b,c=unpack_n(tbl)
--print("a: "..a.." b: "..b.." c: "..c)

-- Shallow copy table (depth-of-1) into re-usable table
-- Modified from lua-users wiki (http://lua-users.org/wiki/CopyTable)
function shallow_copy_table(orig, copy)
	copy = copy or {}
	local orig_type, copy_type = type(orig), type(copy)
    if orig_type == 'table' and copy_type == 'table' then
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
		return false -- not a table ye dummy
    end
    return copy
end

-- Recursively copy table
-- Taken from lua-users wiki
function deepcopy(o, seen)
	seen = seen or {}
	if o == nil then return nil end
	if seen[o] then return seen[o] end
		local no
		if type(o) == 'table' then
			no = {}
			seen[o] = no

			for k, v in next, o, nil do
				no[deepcopy(k, seen)] = deepcopy(v, seen)
			end
			setmetatable(no, deepcopy(getmetatable(o), seen))
		else -- number, string, boolean, etc
			no = o
		end
	return no
end

-- Declare read-only proxy table function for .config
local function read_only (t)
	local proxy = {}
	local mt = {       -- create metatable
		__index = t,
		__newindex = function (t,k,v)
		error("attempt to update a read-only table", 2)
		end
	}
	setmetatable(t, mt)
	setmetatable(proxy, mt)
	return proxy
end

-- [[--- Collision Functions ---]] --

-- Broadphase functions

-- Determine if two circles are colliding using their coordinates and radii
local function circle_circle(collider1, collider2)
	local x1,y1 = collider1.centroid.x, collider1.centroid.y
	local x2,y2 = collider2.centroid.x, collider2.centroid.y
	local r1,r2 = collider1.radius,	  collider2.radius
	return (x2 - x1)^2 + (y2 - y1)^2 <= (r1 + r2)^2
end

-- Use AABB collision for broadphase,
-- returns true if two bounding boxes overlap
local function aabb_aabb(collider1, collider2)
	local rect_1_x, rect_1_y, rect_1_w, rect_1_h = collider1:get_bbox()
	local rect_2_x, rect_2_y, rect_2_w, rect_2_h = collider2:get_bbox()
	return (
		rect_1_x < rect_2_x + rect_2_w and
		rect_1_x + rect_1_w > rect_2_x and
		rect_1_y < rect_2_y + rect_2_h and
		rect_1_y + rect_1_h > rect_2_y
	)
end

local function project(shape1, shape2)
	local minimum, mtv_dx, mtv_dy = inf, 0, 0
	local overlap, dx, dy
	local shape1_min_dot, shape1_max_dot, shape2_min_dot, shape2_max_dot
	-- loop through shape1 geometry
	for _, edge in shape1:ipairs() do
		-- get the normal
		dx, dy = Vec.normalize( Vec.sub(edge[3],edge[4], edge[1], edge[2]) )
		dx, dy = dy, -dx
		-- Project both shapes 1 and 2 onto this normal to get their shadows
		shape1_min_dot, shape1_max_dot = shape1:project(dx, dy)
		shape2_min_dot, shape2_max_dot = shape2:project(dx, dy)
		-- We've now reduced it to ranges intersecting on a number line,
		-- Test for bounding overlap
		if not ( shape1_max_dot > shape2_min_dot and shape2_max_dot > shape1_min_dot ) then
			-- WE FOUND IT BOIS, TIME TO GO HOME
			return MTV(0,0)
		else
			-- Find the overlap, which is equal to the magnitude of the MTV
			-- Overlap = minimum difference of bounds
			overlap = min(shape1_max_dot-shape2_min_dot, shape2_max_dot-shape1_min_dot)
			if overlap < minimum then
				-- Set our MTV to the smol vector
				minimum = overlap
				mtv_dx, mtv_dy = dx, dy
			end
		end
	end
	-- Flip it?
	local ccx, ccy = shape2.centroid.x - shape1.centroid.x, shape2.centroid.y - shape1.centroid.y
	local s = sign( Vec.dot(mtv_dx, mtv_dy, ccx, ccy) )
	-- Welp. We made it here. So they're colliding, I guess. Hope it's consensual :(
	return MTV( Vec.mul(s*minimum, mtv_dx, mtv_dy) )
end

local function SAT(shape1, shape2)
	local mtv1 = project(shape1, shape2)
	if mtv1:mag() == 0 then -- don't bother calculating mtv2
		return false, nil
	end
	local mtv2 = project(shape2, shape1)
	if mtv2:mag() == 0 then
		return false, nil
	end
	-- Else, return the min
	if mtv1:mag() < mtv2:mag() then
		return 1, mtv1
	else
		return 2, mtv2
	end
end

local function striking(collider1, collider2)
	local max_mtv, c = MTV(0, 0), 0
	local from, mtv
	local contactx, contacty
	local i, j = 0,0
	for _, shape1 in collider1:ipairs() do
		for _, shape2 in collider2:ipairs() do
			c, mtv = SAT(shape1, shape2)
			if c and mtv:mag() > max_mtv:mag() then
				from = c
				max_mtv = mtv
			end
		end
	end
	if from == 1 then
		max_mtv:setCollider(collider1)
		max_mtv:setCollided(collider2)
	elseif from == 2 then
		max_mtv:setCollider(collider2)
		max_mtv:setCollided(collider1)
	end
	return max_mtv:mag() ~= 0 and from, max_mtv or false
end

local function settle(mtv)
	mtv.collider:translate( Vec.mul(-.5, mtv.x, mtv.y))
	mtv.collided:translate( Vec.mul(0.5, mtv.x, mtv.y))
end

local function show_mtv(mtv)
	local c = mtv.collider.centroid
	love.graphics.line(c.x, c.y, c.x+mtv.x, c.y+mtv.y)
end

local function show_norms(collider)
	for _, shape in collider:ipairs() do
        for _, edge in shape:ipairs() do
            local  x,  y = Vec.div(2, Vec.add(edge[1], edge[2], edge[3], edge[4]) )
            local nx, ny = Vec.sub(edge[3], edge[4], edge[1], edge[2])
			nx, ny = ny, -nx
	        love.graphics.line(x, y, x+nx, y+ny)
        end
    end
end

local function show_proj(mtv)
	local c = mtv.collided.centroid
	for _, shape in mtv.collided:ipairs() do
		local nmx, nmy = Vec.normalize(mtv.x, mtv.y)
		local smin, smax = shape:project(nmx, nmy)
		love.graphics.setColor(.5,.5,.1)
	   	love.graphics.line(16+nmx*smin, nmy*smin, 16+nmx*smax, nmy*smax)
		love.graphics.setColor(1,1,1)
    end
end

-- [[---------------------]] Strike API Table [[---------------------]] --
-- Strike table
local S = {}

-- Config table
S.ettings = {}

-- Add shapes
S.hapes = Shapes

-- Add collider definition for each shape
for name, shape in pairs(Shapes) do
	Colliders[name] = function(...)
		return Collider( shape(...) )
	end
end
-- Add colliders
S.trikers = Colliders

-- Broadphase functions
S.aabb = aabb_aabb
S.ircle = circle_circle

-- Add collison functions
S.triking = striking
S.ettle = settle

-- Functions to draw collision info
S.howMTV = show_mtv
S.howNorms = show_norms
S.howProj = show_proj

-- Config flags for Strike
local default_config = {
	IDIOT_PROOF = true,		-- If false, turns off all checks in create_polygon - assumes only convex polygons
	CONVEX_ONLY = false,	-- All vertex lists in create_polygon should be convex - does not turn off checks
	BROAD_PHASE = 'none'	-- Specify broad_phase function to use w/ spatial hash
}

-- Edit the configuration for Strike to change some behavior using rawset
-- Takes a series of flag + value where flag is a string corresponding to the key
-- in S.ettings to change, and value is a valid value for that flag
-- flag-values can also be passed as a table containing key-value pairs
local function configure(self, config_flag, value, ...)

	-- Return if no config flag specified
	if not config_flag then return end

	-- If the user supplies their own config table, unpack it
	if type(config_flag) == "table" then
		return configure(self, unpack_unordered_recursive(config_flag))
	end

	-- Else, carry on
	-- Need to sandbox each config var so it's locked to appropriate options
	if		config_flag == 'IDIOT_PROOF' or config_flag == 'CONVEX_ONLY' then
		-- Assert if value is not bool
		assert(type(value) == "boolean", "In: strike:load() - IDIOT_PROOF must be of type boolean")
	elseif	config_flag == 'BROAD_PHASE' then
		local good =  value ~= 'none' or value ~= 'aabb' or value ~= 'radii'
		assert(good, "BROAD_PHASE must be (aabb/radii/none")
	end

	-- Use rawset to update config
	rawset( self.__instance_config, config_flag, value )
	return configure(self, ...)
end

local function load_strike(config_flag, value, ...)
	-- Create API table
	local strike = {
		-- Util functions
		new						= load_strike, -- Get new strike isntance
		configure				= configure, -- config function

		-- Broadphase/hash-table here
		aabb_collision			= aabb_collision,
		circle_collision		= circle_circle,

		-- Collision functions
		strike					= strike,

		-- Love functions
		draw_polygon			= draw_polygon
	}
	-- This is where the flag variables ACTUALLY live
	-- these are modifed through strike:configure
	strike.__instance_config = deepcopy(default_config)
	-- Init read-only proxy table, add to strike
	-- This is to prevent the user from accidentally setting flags to the wrong type.
	-- If you're reading this, just edit the __instance_config table yourself, I trust you.
	strike.config = read_only(strike.__instance_config)

	-- Config using args
	strike:configure(config_flag, value, ...)
	return strike
end


-- [[--- Some Benchmarking ---]] --

-- Function to benchmark a function
-- Courtesy of Infernum, https://otland.net/threads/benchmarking-your-code-in-lua.265961/
do
    local units = {
        ['seconds'] = 1,
        ['milliseconds'] = 1000,
        ['microseconds'] = 1000000,
        ['nanoseconds'] = 1000000000
    }

    function benchmark(unit, decPlaces, n, f_name, f, ...)
        if not f_name then f_name = 'Benchmark' end
        local elapsed = 0
        local multiplier = units[unit]
		local output
        for i = 1, n do
            local now = os.clock()
            output = f(...)
            elapsed = elapsed + (os.clock() - now)
        end
        -- TODO add ' Mem estimate: ' .. collectgarbage('count') to report
        local mem = collectgarbage('count')
        print(string.format(
            '\n%s results:\t%d function calls | %.3f kB estimated memory usage | %.'.. decPlaces ..'f %s elapsed | %.'.. decPlaces ..'f %s avg execution time.', f_name, n, mem, elapsed * multiplier, unit, (elapsed / n) * multiplier, unit))
        output = nil
        f = nil
        collectgarbage("collect")
        collectgarbage("collect")
    end
end

local benchmark_function = benchmark

-- Common args to pass
local args = {{},1,1,2,1,2,2,1,2,1,1,2,1,2,2,1,2}

-- Benchmarks
tbl = {}
for i = 1, 1000 do tbl[i] = i end
--benchmark_function('seconds',5,1000,'unpack', unpack, tbl)
--benchmark_function('seconds',5,1000,'unpack_n', unpack_n, tbl)
--benchmark_function('seconds', 5, 100000, 'create_regular_polygon', create_regular_polygon, 1000, 50)


-- Actually return Strike!
return S