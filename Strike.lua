local bit 		= require'bit' --https://luajit.org/extensions.html
local Stable	= _Require_relative( ... , "DeWallua.Stable" )
local Vec		= _Require_relative( ... , "DeWallua.vector-light")
local Shapes 	= _Require_relative( ... , "shapes")
local Collider	= _Require_relative( ... , "colliders.Collider")
local Colliders	= _Require_relative( ... , "colliders")

local pi , cos, sin, atan2 = math.pi, math.cos, math.sin, math.atan2
-- atan(y, 0) returns 0, not undefined
local floor, ceil, sqrt, abs, max, min   = math.floor, math.ceil, math.sqrt, math.abs, math.max, math.min
local inf = math.huge
-- Push/pop
local push, pop = table.insert, table.remove

--tprint(Shapes)
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

-- Given two x, y points, calculate ccw normal at their midpoint
local function normal_vec_ccw(x1,y1, x2,y2)
    local x = (x1+x2)/2
    local y = (y1+y2)/2
    local dy, dx = Vec.normalize(x2-x1, y2-y1)
    return x, y, -dx, dy -- dx of the normal vector is the -dy of the given vec, dy of the normal vector is the dx of the vector
end

-- Given two x, y points, calculate cw normal at their midpoint
local function normal_vec_cw(x1,y1, x2,y2)
    local x = (x1+x2)/2
    local y = (y1+y2)/2
    local dy, dx = Vec.normalize(x2-x1, y2-y1)
    return x, y, dx, -dy
	-- x/y are the vector origin (midpoint of line)
	-- dx of the normal vector is the dy of the given vec, dy of the normal vector is the -dx of the vector
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
	-- If a table isn't manually given, grab one from the Stable
	if not copy then
		copy = Stable:fetch()
	end
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
	local proxy = Stable:fetch()
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

-- [[---------------------]]    Polygon Utility Functions    [[---------------------]] --


-- [[------------------]]    Polygon (Merging) Triangulation Functions    [[------------------]] --

-- Use a spatial-coordinate search to detect if two polygons
-- share a coordinate pair (and are thus incident to one another)
local function get_incident_edge(poly_1, poly_2)
    -- Define hash table
    local p_map = Stable:fetch()
    -- Iterate over poly_1's vertices
    -- Place in p using x/y coords as keys
    local v_1 = poly_1.vertices
    for i = 1, #v_1 do
        p_map[v_1[i].x][p_map[i].y] = i
    end

    -- Now look through poly_2's vertices and see if there's a match
    local v_2 = poly_2.vertices
    local i = #v_2
    for j = 1, #v_2 do
        -- Set p and q to reference poly_2's vertices at i and j
        local p, q = v_2[i], v_2[j]
        -- Access p_map based on line p-q's two coordinates
        if p_map[p.x][p.y] and p_map[q.x][q.y] then
            -- Return the indices of the edge in both polygons
            return p_map[p.x][p.y],p_map[q.x][q.y], i,j
        end
        -- Cycle i up to j
        i = j
    end
    -- Well, we looped through and got nothing, so eat p_map and return nil
	Stable:eat_table(p_map)
    return nil, nil, nil, nil
end


-- Merge simplices (index-based) into convex polygons
--
local function merge_simplices(simplices, vertices, convex_polys)

    -- For simplex in simplices
    --      For edge in simplex
	--
end

-- Given two convex polygons, merge them together
-- Assuming they share at least one edge,
-- and so long as the new polygon is also convex
local function merge_convex_incident(poly_1, poly_2)
    -- Find an incident edge between the two polygons
    local i_1,j_1, i_2,j_2 = get_incident_edge(poly_1, poly_2)
    -- Check that one of them is not nil
    if i_1 then
        -- Let's meeeerge bay-bee!
        -- Ref both polygons' vertices
        local v_1, v_2 = poly_1, poly_2
        -- Init new verts table
        local union = Stable:fetch()
        -- Loop through the vertices of poly_1 and add applicable points to the union
        for i = 1, #v_1 do
            -- Skip the vertex if it's part of the poly_2's half of the incident edge
            if i ~= j_1 then
                push(union, v_1[i])
            end
        end
        -- Loop through the vertices of poly_2 and add applicable points to the union
        for i = 1, #v_2 do
            -- Skip the vertex if it's part of the poly_2's half of the incident edge
            if i ~= i_2 then
                push(union, v_1[i])
            end
        end
        return create_polygon(unpack(union))
    else
        -- Got nil, no incident edge, so return nil
        return nil
    end
end

-- Love2d Specific Draw Function
local function draw_polygon(polygon, fill)
	-- default fill to "line"
	fill = fill or "line"
	love.graphics.polygon("line", get_polygon_vertices(polygon))
end

-- [[--- Masking functions ---]] --

-- Mask layer - objects will only check for collisions if they're in the same layer
local function mask_polygon_layer(polygon, bit)
	polygon.layer_mask = bit
end

-- Should I add two masks, one that is "affected" and one that is "affects"
-- Like: Wing affects particle = true, particle affects wing = false
-- https://stackoverflow.com/questions/39063949/cant-understand-how-collision-bit-mask-works
-- Mask collisions - polygons will only collide if their masks AND'd = true
local function mask_polygon_collision(polygon, bit)
	polygon.collision_mask = bit
end


-- [[--- Collision Functions ---]] --

-- Broadphase functions

-- Determine if two circles are colliding using their coordinates and radii
local function circle_circle(shape_1, shape_2)
	local x1,y1 = shape_1.centroid.x, shape_1.centroid.y
	local x2,y2 = shape_2.centroid.x, shape_2.centroid.y
	local r1,r2 = shape_1.radius,	  shape_2.radius
	return (x2 - x1)^2 + (y2 - y1)^2 <= (r1 + r2)^2
end

-- Use AABB collision for broadphase,
-- returns true if two bounding boxes overlap
local function aabb_collision(shape_1, shape_2)
	local rect_1_x, rect_1_y, rect_1_w, rect_1_h = shape_1:get_bbox()
	local rect_2_x, rect_2_y, rect_2_w, rect_2_h = shape_2:get_bbox()
	return (
		rect_1_x < rect_2_x + rect_2_w and
		rect_1_x + rect_1_w > rect_2_x and
		rect_1_y < rect_2_y + rect_2_h and
		rect_1_y + rect_1_h > rect_2_y
	)
end

-- Narrow-phase functions
-- Edge-Edge, Edge-Circle, Edge-Poly
-- Circle-Circle, Circle-Poly,
-- Poly-Poly
-- Slaps function that checks types and orders the function inputs.


-- Circle - Poly
-- Expand the edges of a polygon by the radius of the circle
-- Then! Check if the center of the circle is within those bounds
-- Two phases:
--		1) Solve for rects directly extruded from sides, check for point
--		2) Else, solve for radial regions at points of polygon

local function circle_poly(circle, polygon)
	-- Init normal vars
	local nx, ny, dx, dy
	local overlap, minimum, mtv_dx, mtv_dy
	local cx, cy
	-- Get geometry info
	local radius = circle.radius
	local verts = polygon.vertices
	-- For each edge, get the normal, build a rectangle where the height = circle radius
	-- Init starting points
	local p, q = verts[#verts], verts[1]

	-- Now lööp through verts
	for i = 1, #verts do
		-- Get edge normal
		nx, ny, dx, dy = normal_vec_cw(p.x,p.y, q.x.qy)
		-- Get the line segment from the normal origin to the circle center
		-- Project that line onto the normal - if the projection
		-- is less than the radius, then the circle is overlapping the polygon
		cx, cy = circle.centroid.x - nx, circle.centroid.y - ny
		overlap = Vec.dot(cx,cy, dx,dy)
		if overlap < radius then
			if overlap < minimum or not minimum then
				-- Set our MTV to the smol vector
				minimum = overlap
				mtv_dx, mtv_dy = nx, ny
			end
		else
			-- Found a separating axis
			return false
		end
		-- Cycle p to q, q to next point
		p, q = q, verts[i]
	end

	-- Welp. We made it here. So they're colliding, I guess. Hope it's consensual :(
	return minimum, mtv_dy, mtv_dy
end

-- SAT alg for polygon-polygon collision
-- Only tests half the edges of even polygons (parallel edges are redundant)
-- Two convex polygons are intersecting when all edge normal projects have been checked and no gap found
-- If intersecting, push the MTV onto the stack of the polygon being looped over
-- If not intersecting, exit early and return false - found a separating axis
local function poly_poly(poly_1, poly_2)
	local verts_1, verts_2 = poly_1, poly_2

	-- Minimum magnitude of mtv vector
	local n
	local overlap, minimum, mtv_dx, mtv_dy
	local nx, ny, dx, dy
	local verts_1_min_dot, verts_1_max_dot, verts_2_min_dot, verts_2_max_dot

	-- Init starting points
	local p, q = verts_1[#verts_1], verts_1[1]

	-- if verts_1 has even edges, we only need to iterate through half of the edges ( n/2 + 1 points)
	-- Use bitwise AND operator to test for even/odd
	-- n = (#verts_1 and 1) == 0 and #verts_1/2 or #verts_1
	n = #verts_1 % 2 == 0 and #verts_1 / 2 or #verts_1

	-- Now lööp through verts_1
	for i = 1, n do
		-- For each edge in verts_1 get the normal
		nx, ny, dx, dy = normal_vec_cw(p.x,p.y, q.x.qy)
		-- Then project verts_1 onto its normal, and verts_2 onto the normal to compare shadows
		verts_1_min_dot, verts_1_max_dot = project_polygon(verts_1, nx, ny)
		verts_2_min_dot, verts_2_max_dot = project_polygon(verts_2, nx, ny)

		-- We've now reduced it to ranges intersecting on a number line,
		-- Compare verts_2 bounds to verts_1's lower bound
		if verts_1_min_dot < verts_2_max_dot and verts_1_min_dot > verts_2_min_dot then
			-- Not a separating axis
			-- Find the overlap, which is equal to the magnitude of the MTV
			-- Overlap = difference between max of min's and min of max's
			overlap = max(verts_1_min_dot, verts_2_max_dot) - min(verts_1_max_dot, verts_2_max_dot)
			-- Check if it's less than minimum
			if overlap < minimum or not minimum then
				-- Set our MTV to the smol vector
				minimum = overlap
				mtv_dx, mtv_dy = nx, ny
			end
		else
			-- separating axis
			return false -- WE FOUND IT BOIS, TIME TO GO HOME
		end
		-- Cycle p to q, q to next point
		p, q = q, verts_1[i]
	end

	-- Ok, we didn't find a separating axis on verts_1,
	-- Now need to check verts_2
	-- Re-Init starting points
	p, q = verts_2[#verts_2], verts_2[1]

	-- if verts_2 has even edges, we only need to iterate through half of the edges ( n/2 + 1 points)
	-- Use bitwise AND operator to test for even/odd
	-- n = (#verts_2 and 1) ~= 0 and #verts_2/2 or #verts_2
	n = verts_2 % 2 == 0 and #verts_2 / 2 or #verts_2

	-- Now lööp
	for i = 1, n do
		-- For each edge in verts_2 get the normal
		nx, ny, dx, dy = normal_vec_cw(p.x,p.y, q.x.qy)
		-- Then project verts_2 onto its normal, and verts_1 onto the normal to compare shadows
		verts_1_min_dot, verts_1_max_dot = project_polygon(verts_1, nx, ny)
		verts_2_min_dot, verts_2_max_dot = project_polygon(verts_2, nx, ny)

		-- We've now reduced it to ranges intersecting on a number line,
		-- Compare verts_2 bounds to verts_1's lower bound
		if verts_1_min_dot < verts_2_max_dot and verts_1_min_dot > verts_2_min_dot then
			-- Not a separating axis
			-- Find the overlap, which is equal to the magnitude of the MTV
			-- Overlap = difference between max of min's and min of max's
			overlap = max(verts_1_min_dot, verts_2_max_dot) - min(verts_1_max_dot, verts_2_max_dot)
			-- Check if it's less than minimum
			if overlap < minimum then
				-- Set our MTV to the smol vector
				minimum = overlap
				mtv_dx, mtv_dy = nx, ny
			end
		else
			-- separating axis
			return false -- WE FOUND IT BOIS, TIME TO GO HOME
		end
		-- Cycle p to q, q to next point
		p, q = q, verts_1[i]
	end

	-- Welp. We made it here. So they're colliding, I guess. Hope it's consensual :(
	return minimum, mtv_dy, mtv_dy
	-- TODO: WHERE DO I STORE THE MTV'S AHHH
end

local function project(shape1, shape2)
	local n
	local overlap, minimum, mtv_dx, mtv_dy
	local nx, ny, dx, dy
	local shape1_min_dot, shape1_max_dot, shape2_min_dot, shape2_max_dot
	-- loop through shape1 geometry
	for _, edge in shape1:ipairs() do
		-- get the normal
		nx, ny, dx, dy = normal_vec_cw(edge[1],edge[2], edge[3], edge[4])
		-- Then project verts_1 onto its normal, and verts_2 onto the normal to compare shadows
		shape1_min_dot, shape1_max_dot = shape1:project(nx, ny)
		shape2_min_dot, shape2_max_dot = shape2:project(nx, ny)
		-- We've now reduced it to ranges intersecting on a number line,
		-- Compare verts_2 bounds to verts_1's lower bound
		if shape1_min_dot < shape2_max_dot and shape1_min_dot > shape2_min_dot then
			-- Not a separating axis
			-- Find the overlap, which is equal to the magnitude of the MTV
			-- Overlap = difference between max of min's and min of max's
			overlap = max(shape1_min_dot, shape2_max_dot) - min(shape1_max_dot, shape2_max_dot)
			-- Check if it's less than minimum
			if overlap < minimum or not minimum then
				-- Set our MTV to the smol vector
				minimum = overlap
				mtv_dx, mtv_dy = nx, ny
			end
		else
			-- separating axis
			return {mag = 0, x=0, y=0} -- WE FOUND IT BOIS, TIME TO GO HOME
		end
	end
	-- Welp. We made it here. So they're colliding, I guess. Hope it's consensual :(
	return {mag = minimum, x = mtv_dx, y = mtv_dy}
end

local function SAT(shape1, shape2)
	print('SAT!')
	local mtv1 = project(shape1, shape2)
	local mtv2 =  mtv1.mag ~= 0 and project(shape2, shape1) or {mag=0, x=0, y=0}
	if mtv1.mag < mtv2.mag then -- false if both equal 0
		return 1, mtv1
	elseif mtv2.mag > 0 then
		return 2, mtv2
	else
		return false, nil -- no collision
	end
end

function collision(collider1, collider2)
	local mtvx, mtvy, contactx, contacty
	local i, j = 0,0
	print('collider1 ipairs: '..tostring(collider1.ipairs))
	for _, shape1 in collider1:ipairs() do
		i = i +1
		print('i: '..i)
		print('collider2 ipairs: '..tostring(collider2.ipairs))
		for _, shape2 in collider2:ipairs() do
			j = j +1
			print('j: '..j)
			-- skip shape2 if their radii don't intersect
			if circle_circle(shape1, shape2) then
				local from, mtv = SAT(shape1, shape2)
				if from then
					return mtv
				end
			end
		end
	end
	return false
end

-- Collision function that handles calling the right method
-- on all pairs of shapes in polygons
local function strike(shapes)
	local type_1, type_2
	local shape_1, shape_2

	local k = #shapes

	for i = 1, k do
		-- Shadow polygons so we can modify them more easily
		shape_1 = shapes[i]
		-- Set type_1 to the polygon we're inspecting
		type_1 = shape_1.type
		for j = i+1, k do
			shape_2 = shapes[j]
			-- before we set any other vars, check collision masks
			if shape_1.collision_mask and shape_2.collision_mask then
				-- Now we do collision checking
				type_2 = shape_2.type

				--TODO - do stuff :(

			end
			-- their masks didn't collide, so move on to the next shape
		end
	end
end


-- [[---------------------]] Strike API Table [[---------------------]] --
-- Strike table
local S = {}

-- Config table
S.ettings = {}

-- Add table for collider instances
S.tash = {}

function S:tow(collider)
end

function S:hed(collider)
	return nil
end

-- Add shapes
S.hapes = Shapes

-- Add collider definition for each shape
for name, shape in pairs(Shapes) do
	Colliders[name] = function(...)
		return Collider( shape(...) )
	end
end
-- Add colliders
S.lappers = Colliders

-- Add collisions table
S.laps = {}

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
		pool					= Stable,

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