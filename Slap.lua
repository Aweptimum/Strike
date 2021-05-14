local Stable	= _Require_relative( ... , "DeWallua.Stable" )
local Vec		= _Require_relative( ... , "DeWallua.vector-light")
local DeWall	= _Require_relative( ... , "DeWallua")

local t1, t2, t3 = Stable:fetch_table_n(3)
print(t1)
t1.hi = 'hi'
t2.hi = 'no'
print("hi: "..t1.hi.." no: "..t2.hi)

--local _PACKAGE = (...):match("^(.+)%.[^%.]+")
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

-- Polygon module for creating shapes to slap each other
package.path = package.path .. ';C:/Users/Sam/Documpolygons/GitHub/Anachronism/Anachronism'

-- [[---------------------]] Declaration of Spelling Collinear [[---------------------]] --

-- [[ IT IS TO BE DECLARED HEREIN THIS DOCUMENT THAT THE "LL" SPELLING OF COLLINEAR ]] --
-- [[ SHALL BE ADOPTED THROUGHOUT, AS IT'S SPELLED ON WIKIPEDIA. "WHY?" YOU MAY ASK ]] --
-- [[ Well, it's because that's how my vector calculus prof spelled it. Using 1 "L" ]] --
-- [[ just feels a bit wrong, y'know? So accept it. Or change it in your copy, idk. ]] --

-- [[---------------------]]        Utility Functions        [[---------------------]] --
local pi , cos, sin, atan2 = math.pi, math.cos, math.sin, math.atan2
-- atan(y, 0) returns 0, not undefined
local floor, ceil, sqrt, abs, max, min   = math.floor, math.ceil, math.sqrt, math.abs, math.max, math.min
-- Push/pop
local push, pop = table.insert, table.remove

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

--[[ local function to_vertices(vertices, x, y, ...)
    -- points can be {x1,y1,x2,y2}, {{x1,y1},{x2,y2}}, {{x1,y1,dx,dy},{x2,y2,dx,dy}}
    -- Convert all inputs to last representation
    if not (x) then return vertices end

	if type(x) == "number" then -- HC style definition
		if not (y) then print("Odd number of x/y coordinates") return vertices end
        --print('x is numbers!: ') print(x)
        vertices[#vertices + 1] = {x = x, y = y, dx = 0, dy = 0}   -- set vertex
        return to_vertices(vertices, ...)

    elseif type(x) == "table" then
        print('x is table!: ')print(#x)
        -- Check if next element is table
        if type(y) == "table" then
			vertices[#vertices+1] = {x = x[1], y = x[2], dx = x[3] or (x[1]-y[1]) or 0, dy = x[4] or (x[2]-y[2]) or 0}
			if (y) then vertices[#vertices+1] = {x = y[1], y = y[2], dx = x[3] or 0, dy = x[4] or 0} end
			print('this weird thing is running')
            return to_vertices(vertices, ...)
        -- Check if inner elempolygons are tables

        elseif type(x[1]) == "number" or type(x[1]) == "table" then

            return to_vertices(vertices, unpack(x))

        end
    end
end ]]
--verts = to_vertices({}, {1,1,2,1,2,2,1,2})
--tprint(verts)
--verts = to_vertices({}, {1,1},      {2,1},     {2,2},     {1,2} )
--tprint(verts)
--verts = to_vertices({},{{1,1},      {2,1},     {2,2},     {1,2}})
--tprint(verts)
--verts = to_vertices({},{{1,-1,1,0}, {2,-1,0,1}, {2,2,-1,0}, {1,2,0,-1},{90,90,90,90}})
--tprint(verts)
--verts = to_vertices({}, 1,1,2,1,2,2,1,2)


-- [[---------------------]]         Table Utilities         [[---------------------]] --

-- Declare read-only proxy table function for .config
local function read_only (t)
	local proxy = Stable:fetch_table()
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

-- For slap.config, need an unpacking function that returns BOTH keys and values
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
local function shallow_copy_table(orig, copy)
	-- If a table isn't manually given, grab one from the Stable
	if not copy then
		copy = Stable:fetch_table()
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
local function deepcopy(o, seen)
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


-- [[---------------------]]    Polygon Utility Functions    [[---------------------]] --

-- Recursive function that returns a list of {x,y} coordinates given a variable amount of
-- Procedural x/y values.
local function to_vertices(vertices, x, y, ...)
    -- points can be {x1,y1,x2,y2}, {{x1,y1},{x2,y2}}, {{x1,y1,dx,dy},{x2,y2,dx,dy}}
    -- Convert all inputs to last representation
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_vertices(vertices, ...)
end

-- Test if 3 points are collinear (do they not make a triangle?)
local function is_collinear_points(a, b, c)
	return abs(Vec.det(a.x-c.x, a.y-c.y, b.x-c.x,b.y-c.y)) <= 1e-32
end

-- Test if 3 points make a ccw turn (same as collinear function, but checks for >= 0)
local function is_ccw(p, q, r)
	return Vec.det(q.x-p.x, q.y-p.y,  r.x-p.x, r.y-p.y) >= 0
end

-- Remove vertices that are collinear
local function trim_collinear_points(vertices)

	local trimmed = Stable:fetch_table() -- {}
	-- Initialize vars for fancy wrap-around loop (⌐■_■)
	local i, j = #vertices-1, #vertices
	for k = 1, #vertices do
		if not is_collinear_points(vertices[i], vertices[j], vertices[k]) then
			trimmed[#trimmed+1] = vertices[j]
		end
		i,j = j,k
	end
	return trimmed

end

-- Check if points are convex by verifying all groups of 3 points make a ccw winding
-- True = convex, False = concave
local function is_convex_i(vertices, index_order)
	if #vertices == 3 then return true end -- Triangles are always ccw
	-- index_order has numeric keys, values are keys to vertices array

	-- Initialize vars for fancy wrap-around loop (⌐■_■)
	-- local i, j = #vertices-1, #vertices -- equivalent below
	local i, j = index_order[#index_order-1], index_order[#index_order]
	for k = 1, #index_order do
		-- Convex polygons always make a ccw turn
		-- If we don't, then this is not a convex polygon and we return false.
		if not is_ccw(vertices[i], vertices[j], vertices[k]) then
			return false
		end
		-- Cycle i to j, j to k
		i,j = j,k
	end
	-- Well we made it out, so it must be convex
	return true

end

-- Do graham scan using p_i as an index to p_ref
-- Init re-usable vertex pool table for sorting
local vertices_indices = Stable:fetch_table() -- {}
local function order_points_ccw_i(vertices)

	-- Find reference point to calculate cw/ccw from (left-most x, lowest y)
	local p_i = 1

	for i = 2, #vertices do
		-- if vertices[i].x < ref.x    then ref.x = vertices[i].x else ref.x = ref.x
		--p_ref.x = (vertices[i].x < p_ref.x) and vertices.x or p_ref.x;
		if vertices[i].y < vertices[p_i].y then
			p_i = i
		elseif vertices[i].y == vertices[p_i].y then
			if vertices[i].x < vertices[p_i].x then
				p_i = i
			end
		end
	end

	-- Pull p_ref out of vertices for the sort function to use
	local p_ref = vertices[p_i]

	-- Declare table.sort function
	-- p_ref is an upvalue (within scope), so it can be accessed from table.sort
	-- vertices is also an upvalue
	local function sort_ccw_i(v1,v2)
		-- v1 and v2 are indices of vertices from vertices_indices
		-- if v1 is p_ref, then it should win the sort automatically
		if vertices[v1].x == p_ref.x and vertices[v1].y == p_ref.y then
			return true
		elseif vertices[v2].x == p_ref.x and vertices[v2].y == p_ref.y then
		-- if v2 is p_ref, then v1 should lose the sort automatically
			return false
		end

		-- Else compute and compare polar angles
		local a1 = atan2(vertices[v1].y - p_ref.y, vertices[v1].x - p_ref.x) -- angle between x axis and line from p_ref to v1
		local a2 = atan2(vertices[v2].y - p_ref.y, vertices[v2].x - p_ref.x) -- angle between x axis and line from p_ref to v1

		if a1 < a2 then
            return true -- true means first arg wins the sort (v1 in our case)
        elseif a1 == a2 then -- points have same angle, so choose the point furthest from p_ref
            local m1 = Vec.dist(vertices[v1].x,vertices[v1].y, p_ref.x,p_ref.y)
            local m2 = Vec.dist(vertices[v2].x,vertices[v2].y, p_ref.x,p_ref.y)
            if m1 > m2 then
                return true -- v1 is further away, so it wins the sort
            end
        end
	end

	-- Build index clone of vertices
	for i = 1, #vertices do vertices_indices[i] = i end

	-- Sort vertices_indices
	table.sort(vertices_indices, sort_ccw_i)
	-- That was easy

	-- Test if convex
	if is_convex_i(vertices, vertices_indices) then
		for i = 1, #vertices_indices do
			vertices[i] = vertices[vertices_indices[i]]
		end
		return true
	else
		return false
	end
    -- TODO: Finish implementing graham scan (or some algo that can sort points ccw)
    -- Now the real algo begins
    local stack = {1, 2}
	tprint(vertices[stack[2]])
    for i = 3, #vertices do
        while #stack > 2 and not is_ccw(vertices[stack[1]], vertices[stack[2]], vertices[i]) do
			pop(stack)
        end
		push(stack, i)
    end
	-- That's it!
	tprint(stack)
end

-- Check if points are convex by verifying all groups of 3 points make a ccw winding
-- True = convex, False = concave
local function is_convex(vertices)
	if #vertices == 3 then return true end -- Triangles are always ccw

	-- Initialize vars for fancy wrap-around loop (⌐■_■)
	local i, j = #vertices-1, #vertices
	for k = 1, #vertices do
		-- Convex polygons always make a ccw turn
		-- If we don't, then this is not a convex polygon and we return false.
		if not is_ccw(vertices[i], vertices[j], vertices[k]) then
			return false
		end
		-- Cycel i to j, j to k
		i,j = j,k
	end
	-- Well we made it out, so it must be convex
	return true

end


-- Enforce counter-clockwise points order
-- using graham scan algorithm to return the ordered hull.
local vertices_clone = Stable:fetch_table() -- {}
local function order_points_ccw(vertices)

	-- Find reference point to calculate cw/ccw from (left-most x, lowest y)
	local p_ref = vertices[1]
	-- Find lowest, left-most point to use as referbce
	for i = 2, #vertices do
		-- if vertices[i].x < ref.x    then ref.x = vertices[i].x else ref.x = ref.x
		--p_ref.x = (vertices[i].x < p_ref.x) and vertices.x or p_ref.x;
		if vertices[i].y < p_ref.y then
			p_ref = vertices[i]
		elseif vertices[i].y == p_ref.y then
			if vertices[i].x < p_ref.x then
				p_ref = vertices[i]
			end
		end
	end

	--tprint(p_ref)

	-- Declare table.sort function
	-- p_ref is an upvalue (within scope), so it can be accessed from table.sort
	local function sort_ccw(v1,v2)
		-- if v1 is p_ref, then it should win the sort automatically
		if v1.x == p_ref.x and v1.y == p_ref.y then
			return true
		elseif v2.x == p_ref.x and v2.y == p_ref.y then
		-- if v2 is p_ref, then v1 should lose the sort automatically
			return false
		end

		-- Else compare polar angles
		local a1 = atan2(v1.y - p_ref.y, v1.x - p_ref.x) -- angle between x axis and line from p_ref to v1
		local a2 = atan2(v2.y - p_ref.y, v2.x - p_ref.x) -- angle between x axis and line from p_ref to v1

		if a1 < a2 then
            return true -- true means first arg wins the sort (v1 in our case)
        elseif a1 == a2 then -- points have same angle, so choose the point furthest from p_ref
			-- Compute points' distances
			local m1 = Vec.dist(v1.x,v1.y, p_ref.x,p_ref.y)
            local m2 = Vec.dist(v2.x,v2.y, p_ref.x,p_ref.y)
            if m1 > m2 then -- Pick the furthest point to win
                return true -- v1 is fatrther, so it wins the sort
            end
        end
	end

    --- TODO:
    --- Don't actually want to modify original list if it is intended to be concave;
	--- the resulting polygon will not match user input
    --- Maybe do:
    --- Creat table of indices, sort the indices by corresponding vertex, then check if index order is_convex.
	--- If is_convex, apply order to vertices, then return vertices, return false if not convex (triangulation time).
    -- Shallow copy vertices
	shallow_copy_table(vertices, vertices_clone)
	-- Sort table - That's it! (For a convex polygon at least)
	table.sort(vertices_clone, sort_ccw)

	-- Set convexity flag
	local good_sort = is_convex(vertices_clone)

	-- Now we can clear table for re-use
	Stable:clean_table(vertices_clone)

	-- And return our investigation
    if good_sort then
        table.sort(vertices, sort_ccw)
		return true --- true means the list is convex after all
    else
        return false -- false means not convex, treat it as concave
    end

end

-- Find convex hull if ccw sort fails
local function graham_scan(vertices)

	-- Now the real algo begins
    local stack = {vertices[1], vertices[2]}
    for i = 3, #vertices do

        while #stack > 2 and not is_ccw(stack[#stack-1], stack[#stack], vertices[i]) do
			pop(stack)
        end
		push(stack, vertices[i])

    end
	-- That's it!

	-- Now return sorted vertices
	-- Don't want to return
	tprint(stack)
end

-- Test if points a and b are on different sides of line cd
-- If points a and b lie on the same side of line cd,
-- or points c and d lie on the same side of line ab,
-- there's no intersection!
-- a-b are endpoints of line 1, c-d are endpoints of line 2
local function are_lines_intersecting_inf(a,b, c,d)
    -- print(tostring(is_ccw(a,b,c)) .. tostring(is_ccw(a,b,d)) .. tostring(is_ccw(c,d,a)) .. tostring(is_ccw(c,d,b)))
	-- In each condition, if both are ccw, then points a and b lie on the same side of line cd
	-- To return true ("Yes, there is an intersection bucko"), we need to negate the whoooole condition.
	-- Feels illegal.
	return not ( is_ccw(a, b, c) and is_ccw(a, b, d) or ( is_ccw(c, d, a) and is_ccw(c, d, b)) )

	-- Do I bother adding a collinear case? If two lines in a polygon are collinear,
	-- then trim_collinear points will commit die on one of them.

end

-- If we want to check if the line formed by ab PHYSICALLY intersects cd
-- We need to check if the dot-product of vectors a-c and a-d are both:
-- greater-than-or-equal-to 0 and less-than-or-equal-to a-b * a-b
-- The dot-product of a vec by itself is equal to the its magnitude², hence Vec.len2
-- a-b are endpoints of line 1, c-d are endpoints of line 2
local function is_line_between_line(a,b, c,d)

	local mag_ab = Vec.len2(b.x-a.x,b.y-a.y)
	local dotc = Vec.dot(b.x-a.x,b.y-a.y, c.x-a.x,c.y-a.y)
	local dotd = Vec.dot(b.x-a.x,b.y-a.y, d.x-a.x,d.y-a.y)
	-- If both dotc and dotd are positive AND less than mag_ab, return true
	return dotc >= 0 and dotc <= mag_ab and dotd >= 0 and dotd <= mag_ab
end

-- Two lines, a-b and c-d, intersect if their endpoints lie on different sides wrt each other
-- and they pass a projection test to check if points c and d are in boudns of a and b
-- a-b are endpoints of line 1, c-d are endpoints of line 2
local function are_lines_intersecting(a,b, c,d)
	return is_line_between_line(a,b, c,d) and are_lines_intersecting_inf(a,b, c,d)
end

-- Checks for physical intersection of lines within polygon
-- vertices is the vertex list of the polygon
local function is_self_intersecting(vertices)

	local a, b = nil, vertices[#vertices]

	for i = 1, #vertices-2 do
		a, b = b, vertices[i]
		for j = i+1, #vertices-1 do
			local c, d = vertices[j], vertices[j+1]
			if are_lines_intersecting(a,b, c,d) then return true end
		end
	end

	return false

end

local function point_in_polygn(polygon, point)
	local vertices = polygon.vertices
	local winding = 0
	local p, q = vertices[#vertices], vertices[1]
	for i = 1, #vertices do
		if p.y < point.y then
			if q.y > point.y and is_ccw(p,q, point) then
				winding = winding + 1
			end
		else
			if q.y < point.y and not is_ccw(p,q, point) then
				winding = winding - 1
			end
		end
	end
	return winding ~= 0
end

-- Calculate signed area of polygon using shoelace algorithm
local function calc_signed_area(vertices)

	-- Initialize p and q so we can wrap around in the loop
	local p, q = vertices[#vertices], vertices[1]
	-- a is the signed area of the triangle formed by the two legs of p.x-q.x and p.y-q.y - it is our weighting
	local a = Vec.det(p.x,p.y, q.x,q.y)
	-- signed_area is the total signed area of all triangles
	local signed_area = a

	for i = 2, #vertices do
		-- Now assign p to q, q to next
		p, q = q, vertices[i]
		a = Vec.det(p.x,p.y, q.x,q.y)
		signed_area = signed_area + a


	end

	signed_area = signed_area * 0.5
	return signed_area--, area

end

-- Calculate centroid and signed area of the polygon at the _same_ time
local function calc_area_centroid(vertices)

	-- Initialize p and q so we can wrap around in the loop
	local p, q = vertices[#vertices], vertices[1]
	-- a is the signed area of the triangle formed by the two legs of p.x-q.x and p.y-q.y - it is our weighting
	local a = Vec.det(p.x,p.y, q.x,q.y)
	-- signed_area is the total signed area of all triangles
	local signed_area = a
	local centroid	  = {x = (p.x+q.x)*a, y = (p.y+q.y)*a}

	for i = 2, #vertices do
		-- Now cycle p to q, q to next vertex
		p, q = q, vertices[i]
		a = Vec.det(p.x,p.y, q.x,q.y)
		centroid.x, centroid.y = centroid.x + (p.x+q.x)*a, centroid.y + (p.y+q.y)*a
		signed_area = signed_area + a

	end

	signed_area = signed_area * 0.5
	centroid.x	= centroid.x / (6.0*signed_area);
    centroid.y	= centroid.y / (6.0*signed_area);
	return centroid, signed_area--, area

end

local function polygon_bounding_radius(vertices, centroid)

	local radius = 0

	for i = 1,#vertices do
		radius = max(radius, Vec.dist(vertices[i].x,vertices[i].y, centroid.x, centroid.y))
	end
	return radius
end

local function polygon_vertex_deltas(vertices)
    for i, v in ipairs(vertices) do
        local next = vertices[i+1] or vertices[1]
        v[dx], v[dy] = next[x] - v[x], next[y] - v[y]
    end

end


-- [[--- Begin polygon functions! ---]] --


-- Create edge/line segment for collision
local function create_edge(x1,y1, x2,y2)

	local vertices = {
		{x = x1, y = y1},
		{x = x2, y = y2},
	}

	local centroid = {
		x = (x1 + x2) / 2,
		y = (y1 + y2) / 2,
	}

	local norm = 0

	local edge = {
		vertices	= vertices,
		centroid	= centroid,
		norm		= norm,
	}
end
-- Create rectangle.
-- It's not a regular polygon, but it's the most common, so it gets it's own function.
-- I guess.
-- Specify width height first? Is that more convenient? idk. whatevs.
local function create_rectangle(dx, dy, x_pos, y_pos, angle_rads)
	if not ( dx and dy ) then return false end
	local x_offset	= x_pos or 0
	local y_offset 	= y_pos or 0
	local angle 	= angle_rads or 0

	local vertices = {
		{x = x_offset					, y = y_offset					},
		{x = x_offset + dx*cos(angle)	, y = y_offset					},
		{x = x_offset + dx*cos(angle)	, y = y_offset + dy*sin(angle)	},
		{x = x_offset					, y = y_offset + dy*sin(angle)	}
	}

	local centroid  	= {x = x_offset+dx/2, y = y_offset+dy/2}
	local area 			= dx*dy
	local signed_area	= calc_signed_area(vertices)
	local radius		= Vec.len(dx, dy)

	-- Put everything into polygon table and then return it
	local polygon = {

        vertices 		= vertices,     	-- list of {x,y} coords
		convex      	= true,       		-- boolean
		centroid   		= centroid,	-- {x, y} coordinate pair
		radius			= radius,			-- radius of circumscribed circle
		area			= area,				-- absolute/unsigned area of polygon
		signed_area 	= signed_area,  	-- +/- area of polygon (depends on if intersecting coordinate axes)

	}

	return polygon
end

-- Create circle.
-- Not a fan of circles? Then go make a chiliagon :)
-- Like so: create_regular_polygon(1000, 1, 0, 0)
local function create_circle(radius, x_pos, y_pos, angle_rads)
	if not ( radius ) then return false end
	local x_offset 	= x_pos or 0
	local y_offset 	= y_pos or 0
	local angle = angle_rads or 0

	-- Put everything into circle table and then return it
	local circle = {

        vertices 		= nil,     						-- list of {x,y} coords
		convex      	= true,       					-- boolean
		centroid   		= {x = x_offset, y = y_offset},	-- {x, y} coordinate pair
		radius			= radius,						-- radius of circumscribed circle
		area			= pi*radius^2,					-- absolute/unsigned area of polygon

	}

	return circle
end

-- What about an ellipse? You a fan of ellipses?
-- Too bad. This isn't an ellipse. It's an approximation.
-- Create a discretized ellipse.
-- a and b are major/minor axes
-- segments = # of lien segments to use to approximate it (even numbers are better!)
-- x/y_pos is the coordinate to create it at
-- angle_rads is the angle offset to create it with
local function create_ellipse(a, b, segments, x_pos, y_pos, angle_rads)
	if not ( a or b ) then return false end -- We need both to make an ellipse!
	-- Set default value for segments if it's nil
	-- Ratio of major/minor axes = # of segments per quadrant - multiply by 4 to get total segments
	local segs = segments or max( floor(a/b)*4, 8)
	-- Set ellipse coords
	local x_offset 	= x_pos or 0
	local y_offset 	= y_pos or 0
	-- Set angle offset
	local angle 	= angle_rads or 0

	-- Init vertices list
	local vertices = Stable:fetch_table() -- {}
	-- Init delta-angle between vertices lying on ellipse hull
	local d_rads = 2*pi / segs
	-- For # of segs, compute vertex coordinates using
	-- parametric eqns for an ellipse:
	-- 		x = a * cos(theta)
	-- 		y = b * sin(theta)
	-- where a is the major axis and b is the minor axis
	for i = 1, segs do
		-- Increment our angle offset
		angle = angle + d_rads
		-- Add to vertices list
		vertices[#vertices+1] = {
			x = x_offset + a * cos(angle),
			y = y_offset + b * sin(angle),
		}
	end
	-- Put everything into circle table and then return it
	local ellipse = {

        vertices 		= vertices,     				-- list of {x,y} coords
		convex      	= true,       					-- boolean
		centroid   		= {x = x_offset, y = y_offset},	-- {x, y} coordinate pair
		radius			= a,							-- radius of circumscribed circle
		area			= pi*a*b,						-- absolute/unsigned area of polygon

	}

	return ellipse
end

-- Create regular polygon given number of sides (n) and radius of circumscribed circle (radius)
-- Optional:
--		1) (x,y) coordinates to create at (origin of circumscribed circle)
-- 		2) Angle offset to rotate by in RADIANS - all default to 0
local function create_regular_polygon(n, radius, x_pos, y_pos, angle_rads)
	-- Initialize our polygon's origin and rotation
	local x_offset 	= x_pos or 0
	local y_offset 	= y_pos or 0
	local angle 	= angle_rads or 0
	-- Initalize our dummy point vars to put into the vertices list
	local x, y
	local vertices = Stable:fetch_table() -- {}

    -- Print easter-egg warning
    --if n == 1000 then print("OH NO, NOT A CHILIAGON! YOU MANIAC! HOW COULD YOU!?\n") end
    -- Calculate the points
	for i = n, 1, -1 do -- i = 1, n calculates vertices in clockwise order, so go backwards
		x = ( sin( i / n * 2 * pi - angle) * radius) + x_offset
		y = ( cos( i / n * 2 * pi - angle) * radius) + y_offset
		vertices[#vertices+1] = {x = x, y = y}
	end

	-- Calculate the signed area of our polygon.
	-- Since it's regular, the centroid is the origin of the circumscribed circle
	local signed_area = calc_signed_area(vertices)

	-- Put everything into polygon table and then return it
	local polygon = {

        vertices 		= vertices,     	-- list of {x,y} coords
		convex      	= true,       		-- boolean
		centroid   		= {x = x_offset, y = y_offset},	-- {x, y} coordinate pair
		radius			= radius,			-- radius of circumscribed circle
		signed_area 	= signed_area,  	-- +/- area of polygon (depends on if intersecting coordinate axes)

	}

    return polygon

end

-- Create a convex polygon from a list of points
local function  create_convex(...)
	if type(...) == "table" then return create_convex(unpack(...)) end
    local vertices = to_vertices({}, ...)
	-- Check we got at least 3 vertices
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")
    if is_self_intersecting(vertices) then
        -- Idk what to do here :/
	end
	-- Check for ccw orienation of points and self-intersections
	local convex = true

    if not is_convex(vertices) then
		print("Polygon not convex, ordering points\n")
		-- We sort!
		-- order_points_ccw returns true if convex, false if concave
		convex = order_points_ccw(vertices)

		-- Now the points might be ccw,
		-- But a self-intersection is possible
		if not convex then
			print("Ordered points, polygon still not convex\n")
            assert(not convex, "In create_convex(): Points list could not be converted to a convex polygon")
        end
    end
    -- Trim_collinear assumes the points are already ordered ccw,
    -- So we have to wait to use it here, when we're sure it's convex :(
    trim_collinear_points( vertices )
    convex = true

    -- Calc centroid
	local centroid, signed_area = calc_area_centroid(vertices)

	-- Get outer radius/rect of vertices
	local radius = polygon_bounding_radius(vertices, centroid)

	-- Return polygon
	local polygon = {

        vertices 		= vertices,     -- list of {x,y} coords
		convex      	= convex,       -- boolean
		centroid   		= centroid,     -- {x, y} coordinate pair
		radius			= radius,
		signed_area 	= signed_area,  -- +/- area of polygon (depends on if intersecting coordinate axes)

	}

    return polygon

end

-- Create concave polygon
local function create_concave(...)
	if type(...) == "table" then return create_concave(unpack(...)) end
    local vertices = to_vertices({}, ...)
	-- Check we got at least 3 vertices
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")
    local convex = false
    -- Triangulation!
    local triangles = DeWall.constrained(vertices)
	-- Convert triangles to polygons
	for i = 1, #triangles do
		triangles[i] = create_convex((triangles[i]))
	end
    -- Need to merge triangles into the largest concave polygons possible
    -- Then, for each polygon, calc area/centroid
    -- Figure out how to store several sub-polygons in a consistent way
	return triangles
end

-- Given a list of integers, create a polygon
-- IDIOT_PROOF = false - no convex check
-- CONVEX_ONLY = true - convex check, order points, assertion failue
-- TODO: handle concave, complex cases
local function create_polygon(...) -- ... is a vararg; so user supplies 1,2,3,4, etc... to create_polygon

	local vertices = to_vertices({}, ...)
	-- Check we got at least 3 vertices
	assert(#vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#vertices..")")

	-- Check for self-intersection

	if is_self_intersecting(vertices) then

	end
	-- Check for ccw orienation of points and self-intersections
	local convex = true

    if not is_convex(vertices) then
		print("Polygon not convex, ordering points\n")
		-- We sort!
		-- order_points_ccw returns true if convex, false if concave
		convex = order_points_ccw(vertices)

		-- Now the points might be ccw,
		-- But a self-intersection is possible
		if not convex then
			print("Ordered points, polygon still not convex\n")
			-- RED ALERT: CONCAVITY DETECTED (ccw sort 'failed' (not really it did its best))
			-- TODO: DO SOMETHING MAN COME ON
			-- Ok, triangulate and merge?
			-- Triangulation!
            local triangles = DeWall.constrained(vertices)
			-- Convert triangles to polygons
			for i = 1, #triangles do
				triangles[i] = create_convex((triangles[i]))
			end
			convex = false
		else
            -- Trim_collinear assumes the points are already ordered ccw,
            -- So we have to wait to use it here, when we're sure it's convex :(
            trim_collinear_points( vertices )
			convex = true
        end
	end

	-- Self-intersection test

	-- Calc centroid
	local centroid, signed_area = calc_area_centroid(vertices)

	-- Get outer radius/rect of vertices
	local radius = polygon_bounding_radius(vertices, centroid)

	-- Return polygon
	local polygon = {

        vertices 		= vertices,     -- list of {x,y} coords
		convex      	= convex,       -- boolean
		centroid   		= centroid,     -- {x, y} coordinate pair
		radius			= radius,
		signed_area 	= signed_area,  -- +/- area of polygon (depends on if intersecting coordinate axes)

	}

    return polygon

end

--[[ TODO: ]]--
-- All polygon functions need to be able to work on concave shapes as well
-- HC solves this by creating separate functions for concave polygons
-- However, imo, this sucks. It's explicit, but the user might call the wrong function.
-- Would be nice to just 'handle' the behavior for the user.

-- You can only slap if you move, y'know?
-- Moves specified polygon by dx, dy (change in x and y position)
-- Either specify coordinates as two ints (dx, dy)
-- or as a table - which will be unpacked
local function translate_polygon(polygon, dx, dy)
	if not dy and type(dx) == "table" then
		dx, dy = dx:unpack()
	end
	-- Could still have a nil value, so default to 0
	dx = dx or 0
	dy = dy or 0
	-- Move all the points
	for i = 1, #polygon.vertices do
		polygon.vertices[i].x = polygon.vertices[i].x + dx
		polygon.vertices[i].y = polygon.vertices[i].y + dy
	end
	-- Move centroid
	polygon.centroid.x = polygon.centroid.x + dx
	polygon.centroid.y = polygon.centroid.y + dy
end

-- Rotate polygon about reference point specified by user
local function rotate_polygon(polygon, angle, ref_x, ref_y)
    if not (ref_x and ref_y) then
        ref_x, ref_y = polygon.centroid.x, polygon.centroid.y
    end

    for i = 1, #polygon.vertices do
        local v = polygon.vertices[i]
        v.x, v.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, v.x-ref_x, v.y - ref_y))
    end
end

-- Scale polygon in relation to reference point
local function scale_polygon(polygon, sf, ref_x, ref_y)
    if not (ref_x and ref_y) then
        ref_x, ref_y = polygon.centroid.x, polygon.centroid.y
    end

    for i = 1, #polygon.vertices do
        local v = polygon.vertices[i]
        v.x, v.y = Vec.add(ref_x, ref_y, Vec.mul(sf, v.x-ref_x, v.y - ref_y))
    end
    -- Recalculate radius while we're here
    polygon.radius = polygon.radius * sf
end

-- Get the bounding box of the polygon as anchor point (x,y) and (width height)
-- looks like: x, y, dx, dy
local function get_polygon_bbox(polygon)

	local min_x, max_x, min_y, max_y = polygon.vertices[1].x,polygon.vertices[1].x, polygon.vertices[1].y, polygon.vertices[1].y
	local x, y, bbox
	for __, vertex in ipairs(polygon.vertices) do
		x, y = vertex.x, vertex.y
		if x < min_x then min_x = x end
		if x > max_x then max_x = x end
		if y < min_y then min_y = y end
		if y > max_y then max_y = y end
	end

    --return bbox
	-- Return rect info as separate values (don't create a table!)
	-- If the bbox is constantly being re-calculated every frame for broadphase, that's a lot of garbage.
	return min_x, min_y, max_x-min_x, max_y-min_y

end

-- Return a polygon's list of vertices as an unpacked table
local function get_polygon_vertices(polygon)

    local v = Stable:fetch_table() -- List to return
	for i = 1, #polygon.vertices do
		v[2*i-1] = polygon.vertices[i].x
		v[2*i]   = polygon.vertices[i].y
	end
	return unpack(v)

end

-- Copy polygon with optional {x,y} coordinates to place it at
local function copy_polygon(polygon, x, y, angle_rads)

	-- Create new polygon - maybe just do deepcopy since we don't need to re-calc everything
	local copy = create_polygon( get_polygon_vertices(polygon) )

	-- if origin specified, then translate_polygon
	if x or y then
		local dx = x and x - polygon.centroid.x or 0 -- amount to translate in x if x specified
    	local dy = y and y - polygon.centroid.y or 0 -- amount to translate in y if y specified
		translate_polygon(copy, dx, dy)
	end

	-- If rotation specified, then rotate_polygon
	if angle_rads then
		rotate_polygon(copy, angle_rads)
    end

	-- Return copy
	return copy
end

-- [[------------------]]    Polygon (Merging) Triangulation Functions    [[------------------]] --

-- Use a spatial-coordinate search to detect if two polygons
-- share a coordinate pair (and are thus incident to one another)
local function get_incident_edge(poly_1, poly_2)
    -- Define hash table
    local p_map = Stable:fetch_table()
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
        local union = Stable:fetch_table()
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
local function layer_mask_polygon(polygon, bit)
	polygon.layer_mask = bit
end

-- Should I add two masks, one that is "affected" and one that is "affects"
-- Like: Wing affects particle = true, particle affects wing = false
-- https://stackoverflow.com/questions/39063949/cant-understand-how-collision-bit-mask-works
-- Mask collisions - polygons will only collide if their masks AND'd = true
local function collision_mask_polygon(polygon, bit)
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
	local rect_1_x, rect_1_y, rect_1_w, rect_1_h = get_polygon_bbox(shape_1)
	local rect_2_x, rect_2_y, rect_2_w, rect_2_h = get_polygon_bbox(shape_2)
	return (
		rect_1_x < rect_2_x + rect_2_w and
		rect_1_x + rect_1_w > rect_2_x and
		rect_1_y < rect_2_y + rect_2_h and
		rect_1_y + rect_1_h > rect_2_y
	)
end

-- Narrow-phase functions

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
		overlap = dot_prod(cx,cy, dx,dy)
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

-- Project all of a polygon's edges onto a vector
-- In SAT, we will be projecting a polygon onto another polygon's edge normals
-- nx/ny are the vector origin, dx/dy are the vector components (should have a magnitude of 1)
local function project_polygon(vertices, nx,ny)
	-- Dummy var for storing dot-product results
	local p = 0
	-- The vector to project, travelling from the origin to the vertices of the polygon
	-- So it's really just the x/y coordinates of a vertex
	local proj_x, proj_y = vertices[1].x, vertices[1].y
	-- Init our min/max dot products.
	-- We can't init them to a random value. I mean we can, but then we would return the wrong results
	-- if min_dot never went below the starting value. Might come back to bite in the butt.
	local min_dot = dot_prod(proj_x,proj_y, nx,ny)
	local max_dot = min_dot
	-- Create new projection vectors, dot-prod them with the input vector, and return the min/max
	for i = 2, #vertices do
		proj_x, proj_y = vertices[i].x , vertices[i].y
		p = dot_prod(proj_x,proj_y, nx,ny)
		if p < min_dot then min_dot = p elseif p > max_dot then max_dot = p end
	end
	return min_dot, max_dot
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


-- Collision function that handles calling the right method
-- on all pairs of shapes in polygons
local function slaps(shapes)
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


-- [[---------------------]] Slap2D API Table [[---------------------]] --
local tslap = {
	-- Creation functions
	create_circle			= create_circle,
	create_edge				= create_edge,
	create_rectangle		= create_rectangle,
	create_ellipse			= create_ellipse,
	create_regular_polygon	= create_regular_polygon,
	create_polygon			= create_polygon,

	-- Union Functions
	merge_convex_incident	= merge_convex_incident,

	-- Transform functions
	translate_polygon		= translate_polygon,
	rotate_polygon			= rotate_polygon,
	scale_polygon			= scale_polygon,
	copy_polygon			= copy_polygon,

	-- Query polygons
	get_polygon_bbox		= get_polygon_bbox,
	get_polygon_vertices	= get_polygon_vertices,

	-- Broadphase/hash-table here
	aabb_collision			= aabb_collision,
	circle_collision		= circle_circle,

	-- Collision functions
	collision				= slaps,
}

-- Config flags for slap
local default_config = {
	IDIOT_PROOF = true,		-- If false, turns off all checks in create_polygon - assumes only convex polygons
	CONVEX_ONLY = false,	-- All vertex lists in create_polygon should be convex - does not turn off checks
	BROAD_PHASE = 'none',	-- Specify broad_phase function to use w/ spatial hash
}

-- Edit the configuration for slap to change some behavior using rawset
-- Takes a series of flag + value where flag is a string corresponding to the key
-- in slap.config to change, and value is a valid value for that flag
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
		assert(type(value) == "boolean", "In: slap:load() - IDIOT_PROOF must be of type boolean")
	elseif	config_flag == 'BROAD_PHASE' then
		local good =  value ~= 'none' or value ~= 'aabb' or value ~= 'radii'
		assert(good, "BROAD_PHASE must be (aabb/radii/none")
	end

	-- Use rawset to update config
	rawset( self.__instance_config, config_flag, value )
	return configure(self, ...)
end

local function load_slap(config_flag, value, ...)
	-- Create API table
	local slap = {
		-- Util functions
		new						= load_slap, -- Get new slap isntance
		configure				= configure, -- config function
		pool					= Stable,
		-- Creation functions
		create_circle			= create_circle,
		create_edge				= create_edge,
		create_rectangle		= create_rectangle,
		create_ellipse			= create_ellipse,
		create_regular_polygon	= create_regular_polygon,
		create_polygon			= create_polygon,

		-- Union Functions
		merge_convex_incident	= merge_convex_incident,

		-- Transform functions
		translate_polygon		= translate_polygon,
		rotate_polygon			= rotate_polygon,
		scale_polygon			= scale_polygon,
		copy_polygon			= copy_polygon,

		-- Query polygons
		get_polygon_bbox		= get_polygon_bbox,
		get_polygon_vertices	= get_polygon_vertices,

		-- Broadphase/hash-table here
		aabb_collision			= aabb_collision,
		circle_collision		= circle_circle,

		-- Collision functions
		slaps					= slaps,
	}
	-- This is where the flag variables ACTUALLY live
	-- these are modifed through slap:configure
	slap.__instance_config = deepcopy(default_config)
	-- Init read-only proxy table, add to slap
	-- This is to prevent the user from accidentally setting flags to the wrong type.
	-- If you're reading this, just edit the __instance_config table yourself, I trust you.
	slap.config = read_only(slap.__instance_config)

	-- Config using args
	slap:configure(config_flag, value, ...)
	return slap
end

-- Test slap:load()
local slap = load_slap()

--slap.config.IDIOT_PROOF = true
slap:configure('IDIOT_PROOF', false)
print("slap:load with given value: " .. tostring( slap.config.IDIOT_PROOF ) )
-- Test slap:load with table
slap:configure( {IDIOT_PROOF = true} )
print("slap:load with given table:  " .. tostring( slap.config.IDIOT_PROOF ) )
--slap.config.IDIOT_PROOF = false

-- Test Slap.Stable
local test_tbl = slap.pool:fetch_table()
print("test table worked: "..tostring(test_tbl))
-- [[--- Test Functions for Bugs ---]] --
-- Function to set configs

-- Test to_vertices
arg = {{}, 1,1,2,1,2,2,1,2}
local verts = to_vertices( unpack(arg) )
local centroid, signed_area = calc_area_centroid(verts)
--tprint(verts)
print("Area is: "..signed_area..", and centroid is: "..centroid.x..", "..centroid.y)

-- Test ccw function
print(is_ccw({x=1,y=1}, {x=2, y=1}, {x=2,y=2})) -- Yep, prints true!
print(is_ccw({x=1,y=1}, {x=2, y=1}, {x=2,y=0})) -- Yep, prints false!

-- Test lines intersecting
local intersection = are_lines_intersecting({x=3,y=3}, {x=3, y=8}, {x=1, y=4}, {x=4, y=4})
local parallel = are_lines_intersecting({x=3,y=3}, {x=3, y=8}, {x=1, y=3}, {x=1, y=8})
print("Are intersecting lines intersecting? " .. tostring(intersection))
print("Are parallel lines intersecting? " .. tostring(parallel))

-- Test self-intersecting polygon
local not_intersecting  = to_vertices({}, 3,3,8,3,8,9,3,8)
local self_intersecting = to_vertices({}, 3,3,8,9,8,3,3,8)
print( "Not-intersecting polygon  self-intersecting? " .. tostring(is_self_intersecting(not_intersecting )) .. "\n")
print( "Self-intersecting polygon self-intersecting? " .. tostring(is_self_intersecting(self_intersecting)) .. "\n")


-- Test out of order octagon
local polygon = create_polygon(

	588, 642,
	458, 512,
	512, 458,
	458, 588,
	512, 642,
	642, 588,
	588, 458,
	642, 512

 )

print("Scrambled octagon convex? " .. tostring( polygon.convex ) .. "\n")
print("Check if vertices_clone is clean after polygon creation:")
print("Vertices_clone is of type: " .. type(vertices_clone) .. " and has length: " .. #vertices_clone .. "\n")

 -- Test regular polygon
local reg_polygon = create_regular_polygon(32, 50)
reg_polygon = create_regular_polygon(32, 50, 50, 50, pi/3)
print("Regular polygon convex? " .. tostring( reg_polygon.convex ) .. "\n")

-- Test functions out
translate_polygon(reg_polygon, 5, 5)
rotate_polygon(reg_polygon, pi/2, 0, 0)
scale_polygon(reg_polygon, 5, 5, 5)
local reg_polygon_2 = copy_polygon(reg_polygon, 0, 0)


-- Test concave polygon
polygon = create_polygon(

	286, 217,
	747,  69,
	910, 308,
	439, 644,
	196, 423,
	416, 338

)

print("Concave polygon convex? " .. tostring( polygon.convex ) .. "\n")
tprint(polygon.vertices)

--if true then return end

-- Test create_concave
polygon = create_concave(

	298, 600,
	462, 410,
	462, 200,
	545, 200,
	545, 410,
	700, 600,
	650, 650,
	500, 485,
	350, 650

)


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


-- benchmark toVertexList against to_vertices
-- HC function in question
local function toVertexList(vertices, x,y, ...)
	if not (x and y) then return vertices end -- no more argumpolygons

	vertices[#vertices + 1] = {x = x, y = y}   -- set vertex
	return toVertexList(vertices, ...)         -- recurse
end

-- Common args to pass
local args = {{},1,1,2,1,2,2,1,2,1,1,2,1,2,2,1,2}

-- Benchmarks
tbl = {}
for i = 1, 1000 do tbl[i] = i end
--benchmark_function('seconds',5,1000,'unpack', unpack, tbl)
--benchmark_function('seconds',5,1000,'unpack_n', unpack_n, tbl)
--benchmark_function('seconds', 5, 100000, 'create_regular_polygon', create_regular_polygon, 1000, 50)
--
--benchmark_function('seconds', 5, 100000, 'to_vertices',   to_vertices, unpack(args))
--
--benchmark_function('seconds', 5, 100000, 'toVertexList', toVertexList, unpack(args))


-- Actually return Slap!
return slap