local Vec  = _Require_relative( ..., "vector-light" )
local Pool = _Require_relative( ..., "Pool" )
-- [[---------------------]]        Utility Functions        [[---------------------]] --
local pi , cos, sin, atan2 = math.pi, math.cos, math.sin, math.atan2
-- atan(y, 0) returns 0, not undefined
local floor, ceil, sqrt, abs, max, min   = math.floor, math.ceil, math.sqrt, math.abs, math.max, math.min
-- Push/pop
local push, pop = table.insert, table.remove

-- [[---------------------]]       DeWall Triangulation      [[---------------------]] --

-- 1) divide the input vertices into subset P1 and P2
-- 2) recursively solve on P1 and P2 (in parallel, if possible)
-- 3) Merge the partial solutions of P1 and P2, S1 and S2, into the solution S

-- Steps
-- 1) Select the dividing plan, a (Vertical), to split P into P1 and P2 along
-- 2) Make the first simplex/triangle intersected by the cutting plane.
--      Select point p1 nearest to a, then point p2 which is nearest on the other side of a
--      Select p3 such that the radius of the circumscribed circle is minimized

-- Based off of DeWall algorithm, pseudocode found here on page 18:
-- http://vcg.isti.cnr.it/publications/papers/dewall.pdf
-- Description of algorithm is in section 3.1

-- TODO:
-- I don't think I'm decrementing/incrementing counter at the right time either, not sure

-- Get circumcircle of triangle formed by 3 points
local function triangle_circumcircle(a,b,c)
	local A, B, C = Vec.dist(a.x,a.y, b.x,b.y), Vec.dist(b.x,b.y, c.x,c.y), Vec.dist(c.x,c.y, a.x,a.y)
	local s = (A + B + C) / 2
	-- the equation for the radius is the below return value
	return (A * B * C) / (4 * sqrt(s * (s-A) * (s-B) * (s-C)))
end

-- Test if point d in triangle abc using determinant method
-- a,b,c needs to be in ccw order
-- Stolen from: https://stackoverflow.com/a/44875841/12135804
-- The DeWall algorithm doesn't specify a check for this, but I feel like it needs it at some point
local function point_in_triangle(a,b,c, d)
	local ax = a.x-d.x
	local ay = a.y-d.y
	local bx = b.x-d.x
	local by = b.y-d.y
	local cx = c.y-d.y
	local cy = c.y-d.y
	return (
		(ax*ax + ay*ay) * (bx*cy - cx*by) -
		(bx*bx + by*by) * (ax*cy - cx*ay) +
		(cx*cx + cy*cy) * (ax*by - bx*ay)
	) > 0;
end

-- Get sign of a number
local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

-- Test if two edges having endpoints p-q and r-s are equal
-- Not used in triangulation atm, this is just in case I find out if the indices in vertices no longer
-- correlate to simplices/faces, in which case x/y coordinate comparisons will be needed. Not too hard to switch though,
-- index comparison is just a little faster/cleaner looking (despite being a bit less human readable)
local function same_edge(p,q, r,s)
	return (
		(p.x == r.x and p.y == r.y) and (q.x == s.x and q.y == s.y)
	or
		(q.x == r.x and q.y == r.y) and (p.x == s.x and p.y == s.y)
	)
end

-- Same as same_edge, uses indices instead of x/y comparison
-- p,q and r,s are numbers
local function same_edge_index(p,q, r,s)
	return (
		(p == r and q == s)
	or
		(p == s and q == r)
	)
end

-- Test if 3 points make a ccw turn (same as collinear function, but checks for >= 0)
local function is_ccw(p, q, r)
	return Vec.det(q.x-p.x, q.y-p.y,  r.x-p.x, r.y-p.y) >= 0
end

-- Test if points a and b lie on the same side of cd by testing if line ab intersects with line cd
-- If points a and b lie on the same side of line cd,
-- Or points c and d lie on the same side of line ab,
-- then there's no intersection!
local function are_lines_intersecting_inf(a,b, c,d)
    -- print(tostring(is_ccw(a,b,c)) .. tostring(is_ccw(a,b,d)) .. tostring(is_ccw(c,d,a)) .. tostring(is_ccw(c,d,b)))
	-- In each condition, if both are ccw, then points a and b lie on the same side of line cd
	-- To return true ("Yes, there is an intersection bucko"), we need to negate the whoooole condition.
	-- Feels illegal.
	return not ( is_ccw(a, b, c) and is_ccw(a, b, d) or ( is_ccw(c, d, a) and is_ccw(c, d, b)) )

	-- Do I bother adding a collinear case? If two lines in a polygon are collinear,
	-- then trim_collinear points will commit die on one of them.

end

-- Find if edge p-q is contained within hull of polygon
-- n, o are indices of vertices corresponding to points p,q
local function edge_in_polygon(n,o, vertices)
	-- Reference vertices using n, o
	local p, q = vertices[n], vertices[o]
	-- init first two points
	local r, s = #vertices, 1
	-- Assuming the points are ordered, we should be able to test
	-- consecutive vertices in the polygon rather than
	-- checking if point p1 exists, then point p2
	for i = 1, #vertices do
		if same_edge_index(p,q, r,s) then
			return true
		end
		-- Cycle r to s, s to next
		r, s = s, i
	end
	-- Didn't find matching edge, return false
	return false
end

-- Select cutting plane as average of values in vertices
-- Along specified axis ('x' or 'y')

local function cutting_plane(vertices,points,axis)
	local plane = Pool:fetch_table()
	local a = 0
	for i = 1, #points do
		a = (a + vertices[points[i]][axis])
	end
	plane[axis] = a / #points
	return plane
end

-- Given vertices and cutting plane,
-- Partition vertices into two subsets on either side of a
local function points_partition(vertices,points, plane)
	local axis, a = next(plane)
	-- Init lists of indices pointing to vertices:
	-- p_1 = subset of points left of a
	-- p_2 = subset of points right of a
	print("Points partition a is: " .. a)
	local p_1, p_2 = Pool:fetch_table(), Pool:fetch_table()
	for i = 1, #points do
		if vertices[points[i]][axis] >= a then-- to the right, wins if x = a
			push(p_2, points[i])
		else -- it's to the left
			push(p_1, points[i])
		end
	end
	return p_1, p_2
end

-- Find if a vector, b, is in the acute bound of vectors a and c
-- Return true if b is ON the bound as a separate value.
-- (When the cross product of ab or ac is 0 and the corresponding dot_prod is +)
-- Separate value needed to override the flip test
local function vec_in_bounds(ax,ay, bx,by, cx,cy)
	-- Calculate A's rotation to B and C, then C's rotation to B and A
	local AxB = Vec.det(ax,ay, bx,by)
	local AxC = Vec.det(ax,ay, cx,cy)
	local CxB = Vec.det(cx,cy, bx,by)
	local CxA = Vec.det(cx,cy, ax,ay)
	-- Get dot products
	local AdB = Vec.dot(ax,ay, bx,by)
	local CdB = Vec.dot(cx,cy, bx,by)
	--print(string.format("A: <%.f,%.f>, B: <%.f,%.f>, C: <%.f,%.f>",ax,ay,bx,by,cx,cy) )
	--print(string.format("AxB: %.f, AdB: %.f, CxB: %.f, CdB: %.f",AxB, AdB, CxB, CdB))
	return (AxB * AxC >= 0 and CxB * CxA >= 0), ( (AxB == 0 and AdB > 0 ) or (CxB == 0 and CdB > 0) )
end
-- Given a line defined by two indices of a vertex list,
-- test if the line pr is within the angular bound of the 2 edges adjacent to p
-- and, likewise, if it is within the angular bound of the two edges adjacent to r.
-- For a better explanation, see me talking to myself on stackoverflow: https://stackoverflow.com/a/66403123/12135804
-- Vertices is list of ccw ordered points {x= x_val, y= y_val}
-- p and r are both indices of vertices, forming a line pr
local function line_in_shell(vertices,p,r)
	-- For both endpoints of the line, test if they're between the bounds of
	-- the adjacent lines
	-- For p:
	-- lines ap and pb are the lines to test the rotation of pr against
	-- The points a and b are adjacent indices of p
	local a = p-1 >= 1			and p-1 or #vertices
	-- b = p
	local c = p+1 <= #vertices  and p+1 or 1
	-- Get vectors from p to a (A), p to b (C), P to R (B (notice the order))
	local A_x, A_y = vertices[a].x - vertices[p].x, vertices[a].y - vertices[p].y
	local C_x, C_y = vertices[c].x - vertices[p].x, vertices[c].y - vertices[p].y
	local B_x, B_y = vertices[r].x - vertices[p].x, vertices[r].y - vertices[p].y
	-- Check if pr is in the acute bound of ap, pb
	-- p_in_bounds
	local p_in_bounds, p_on_bounds = vec_in_bounds(A_x,A_y, B_x,B_y, C_x,C_y)
	--print ("Is p in_bounds: " .. tostring(p_in_bounds))
	-- If not ccw, flip p_in_bounds - we need to check the obtuse bound
	local convex = is_ccw(vertices[a], vertices[p], vertices[c])

	--print(string.format("p_in_bounds: %s, p_on_bounds: %s, convex: %s", p_in_bounds,p_on_bounds, convex) )
	-- Flip test as needed - in bounds is actually true if it is equal to the convex flag
	-- Automatically return true if CxB/CxA is 0 and the corresponding dot_prod is > 0
	p_in_bounds = p_on_bounds or (convex and p_in_bounds) or (not convex and not p_in_bounds)

	--print(string.format("Is line %d-%d (p-r) in_bounds: %s",p,r, p_in_bounds) )
	-- For r:
	-- Do it all over again! Whoo!
	-- The points a and b are adjacent indices of r
	a = r-1 >= 1			and r-1 or #vertices
	-- b = r
	c = r+1 <= #vertices  	and r+1 or 1
	-- Get vectors from r to a (A), r to b (C), R to P (B (notice the order))
	A_x, A_y = vertices[a].x - vertices[r].x, vertices[a].y - vertices[r].y
	C_x, C_y = vertices[c].x - vertices[r].x, vertices[c].y - vertices[r].y
	B_x, B_y = vertices[p].x - vertices[r].x, vertices[p].y - vertices[r].y
	-- Check if rp is in the acute bound of ar, rb
	local r_in_bounds, r_on_bounds = vec_in_bounds(A_x,A_y, B_x,B_y, C_x,C_y)
	--print ("Is r in_bounds: " .. tostring(r_in_bounds))
	-- If not ccw, flip r_in_bounds - we need to check the obtuse bound
	convex = is_ccw(vertices[a], vertices[r], vertices[c])
	--print ("Is r convex: " .. tostring(convex))
	--print(string.format("r_in_bounds: %s, r_on_bounds: %s, convex: %s", r_in_bounds, r_on_bounds, convex) )
	-- Flip test as needed - in bounds is actually true if it is equal to the convex flag
	r_in_bounds = r_on_bounds or (convex and r_in_bounds) or (not convex and not r_in_bounds)
	--print(string.format("Is line %d-%d (r-p) in_bounds: %s",r,p, r_in_bounds) )
	-- If both bounding conditions are true, then pr lies inside of the polygon
	return p_in_bounds and r_in_bounds
end

-- Next 2 functions have same args:
-- p-q are the face the simplex is being built from
-- i is the 3rd POTENTIAL point for the simplex we're checking
-- w is the 3rd point of the simplex p-q CAME FROM (if p-q came from a simplex)
local function is_point_in_halfspace(vertices, p,q,w,i)
    -- If w is 0/nil, then it's part of the convex hull
    -- If line w-i crosses p-q, then i is in the proper halfspace
    return ((w == 0 or w == nil) or are_lines_intersecting_inf(vertices[p],vertices[q], vertices[w],vertices[i]) )
end
-- If make_simplex's constraint flag is true, run this test
-- p-q are the face the simplex is being built from
-- i is the 3rd POTENTIAL point for the simplex we're checking
-- Notes:
-- If lines p-i and q-i are BOTH within the bounds of their neighboring vertices, then the line is (most likely) IN the polygon
-- TODO: Need to detect if p-i and q-i cross the bounds of the polygon. It is possible for two "ears" of a polygon
-- to be placed such that a line between them passses this test, but it violates the polygon boundary.
-- Think of a line between the ends of a bicycle's handlebars - it crosses the handlebar boundary twice.
local function is_simplex_constrained(vertices, p,q,i)
    return line_in_shell(vertices, p, i) and line_in_shell(vertices, q, i)
end
-- Given subsets p_1 and p_2, make the first simplex for the wall
-- p_1 and p_2 are a list of indices of vertices, NOT points
-- this means we need to index vertices by vertices[p_n[i]] to get the points we need
local function make_first_simplex(vertices, p_1, p_2, a)
	-- Find nearest points to a
	local p,q,r
	p = 1
	for i = 2, #p_1 do -- Sorry if the below condition is unreadable, it's indexing vertices by indexing p_1
		if abs(vertices[p_1[i]].x - a) < abs(vertices[p_1[p]].x - a) then
			p = i
		end
	end
	-- Now get closest point to p in p_2
	q = 1
	for i = 2, #p_2 do
		if Vec.len(vertices[p_2[i]], vertices[p]) < Vec.len(vertices[p_2[q]], vertices[p]) then
			q = i
		end
	end
	-- Now find point r in vertices that minimizes the circumcirle of the triangle p,q,r
	r = 1
	local min_r, temp_r = triangle_circumcircle(vertices[p], vertices[q], vertices[r]), 0

	-- Only test i if it isn't p/q
	for i = 2, #vertices do
		if i ~= p and i ~= q then
			-- Find triangle with smallest circumcircle
			temp_r = triangle_circumcircle(vertices[p], vertices[q], vertices[i])
			if temp_r < min_r  then
				-- radius is smaller, so keep it
				min_r = temp_r
				r = i
			end
		end
	end

end

-- Given a face, f, find the point, r, in vertices that makes the triangle
-- with the smallest circumcircle possible
-- Args:
-- vertices is list of {x = x, y = y}, counter is list # of available adjacent triangulations per point,
-- f is a single pair of vertex indices that corresponds to vertices list, t is the simplex f came from
-- Conditions:
-- 1. Taking f as a plane, r must lie on the side of f that does not contain the simplex f came from
--		(Test w/ are_lines_intersecting - true means the point is on the opposite side of the simplex)
-- 2. Only pick points with a counter greater than 0
-- 3. For a concave polygon, lines pr and qr must lie INSIDE the concave hull
local function make_simplex(vertices,counter, f)
	print("counter is: ")
	print("f is: "..f[1]..", "..f[2]..", "..tostring(f[3]))
	tprint(counter, 0, 3)
	-- p and q are indices in face f
	local p, q, w = f[1], f[2], f[3]
	local r --= 1
	local min_r, temp_r --triangle_circumcircle(vertices[p],vertices[q], vertices[r]), 0
	for i, count in ipairs( counter ) do -- ONLY CHECK VERTICES IN COUNTER
		-- Skip over nils
		if count > 0 then
			-- Only test i if it isn't p/q
			if i ~= p and i ~= q then

				print('testing vertex #: ' .. i)
				--Test two things:
				-- If i is in the outer half-space of pq, and if pr and qr are within the polygon
				--print(string.format("P: %i, Q: %i, W: %i, I: %i", p,q,w,i))
				--if w == nil then tprint(f) end
				if is_point_in_halfspace(vertices,p,q,w,i) and is_simplex_constrained(vertices, p,q,i) then
					-- Find triangle with smallest circumcircle
					temp_r = triangle_circumcircle(vertices[p], vertices[q], vertices[i])
					print("circumcircle is " .. temp_r)
					if not min_r or temp_r < min_r then
						-- radius is smaller, so keep it, and set r to i
						min_r = temp_r
						r = i
					end
				end
			end
		end
	end

	print("Make simplex: " .. p .. ", " .. q .. ", " .. tostring(r))
	-- Return simplex of 3 indices
	-- Check if the triangle is not already made up of the hull
	if r == nil then --or edge_in_polygon(p,q, vertices) and edge_in_polygon(q,r, vertices) and edge_in_polygon(r,p, vertices) then
		-- Already exists, return nil
		return nil
	else
        -- We have a new triangle
        -- When an edge becomes part of a triangulation,
        -- points p,q,r "lose" two incident faces, therefore
        -- Decrement counters for points p,q,r
        counter[p] = counter[p] ~= 0 and counter[p] - 2 or 0
        counter[q] = counter[q] ~= 0 and counter[q] - 2 or 0
        counter[r] = counter[r] ~= 0 and counter[r] - 2 or 0

		-- Return the simplex
		return {p,q,r}
	end
end

-- A face intersects a vertical line if the signs of the difference of their points' x-coords
-- with the x coordinate of the line, a, are the same.
local function face_intersects(f,vertices, plane)
	local axis, a = next(plane)
	local p,q = vertices[f[1]], vertices[f[2]]
	--print("Cutting plane is: " .. a .. " p, q x's are: " .. p.x .. ", " .. q.x)
	return not (sign(p[axis] - a) == sign(q[axis] - a) )
end


-- A face is a subset of points, p_n, if their indices match
-- Basically the same as same_edge, but operates on indices
local function face_subset(f,p_n)
	local match_1, match_2 = false, false
	for i=1,#p_n do
		-- Check if point 1 of f matches index in p_n
		if f[1] == p_n[i] then
			match_1 = true

		-- Check if point 2 of f matches index in p_n
		elseif f[2] == p_n[i] then
			match_2 = true
		end
	end
	return match_1 and match_2
end


-- For each face in t, insert it into AFL if it does not exist, otherwise, delete it.
-- Increment the counters of each face's endpoints if it's a new face.

-- t is a simplex/triangle of 3 indices pointing to vertices
-- vertices is the vertices of the polygon
-- counter is the number of incident points to p in vertices that has yet to be made part of a simplex
-- AFL is the current active-faces-list
local function AFL_update(f, vertices,counter, AFL)
	-- first simplex should be convex
	-- f is a list of 2 point indices
	-- Reference points in vertices using f[1], f[2]
	local p,q,w = f[1], f[2], f[3]
	print("\tAFL update f is: " .. p .. ", " .. q)
	--tprint(AFL, 0, 3)
	-- Init index pair to test f against
	local r,s
	for i = 1, #AFL do
		r,s = AFL[i][1], AFL[i][2]
		if same_edge_index(p,q, r,s) then
			-- Already here, remove the edge using swapop
			AFL[i], AFL[#AFL] = AFL[#AFL], AFL[i]
			-- pop the last face and put it into the table pool
			Pool:eat_table( pop(AFL) )
			-- We can return now
			print("\tRemoving: " .. p .. ", " .. q .. " because of: " .. r .. ", " ..s)
			--tprint(AFL, 0, 2)
			return
		end
	end

	-- Well, we made it here, so we can insert new face into AFL
	-- Insert indices, not points
	push(AFL, {p, q, w})
	-- We can increment the counters for points n and o
	print("\tInserting f: " .. f[1] .. ", " .. f[2])
	--tprint(AFL, 0, 2)
	counter[f[1]] = counter[f[1]] +1 --and counter[f[1]] + 1 or 1
	counter[f[2]] = counter[f[2]] +1 --and counter[f[2]] + 1 or 1

	return
end

-- Takes a polygon and triangulates it
-- vertices is the list of x/y points that make up a concave polygon
-- Points is the subset of vertices we're working with
-- 		- it is a list of indices corresponding to the working set of vertices
-- AFL_o is the active-face-list from which new triangles are seeded
-- I think seeding AFL with all of the edges in vertices "constrains" it to the polygon, not sure
-- simplices = table of t's
-- f = 'face', a table of two points representing an edge
-- f_prime is also a face, used for inner-loop
-- t = triangle/simplex, a table of 3 values corresponding to indices in polygon.vertices
-- counter = key corresponds to a vertex in polygon.vertices, value is a counter
-- 		when a point in vertices becomes part of a new f, the counter increases by 1
-- 		when a point's incident f is fed into make simplex, the counter decreases by 1
local counter = Pool:fetch_table()
local function dewall_triangulation(vertices,points, AFL_o, simplices, axis)
	-- Init subsets of points
	local AFL_a, AFL_1, AFL_2 = Pool:fetch_table_n(3)
	-- Init local temp vars
	local f, f_prime, t = Pool:fetch_table_n(3)
	--local counter = {}

	-- DeWall Begins!

	-- If axis not specified, default to x
	axis = axis or 'x'
	-- Get cutting plane
	local plane = cutting_plane(vertices,points, axis)
	print("Given points set: ")
	tprint(points)
	-- Partition points
	local p_1, p_2 = points_partition(vertices,points, plane)
	print("Partitions: ")
	tprint(p_1)
	tprint(p_2)

	-- If AFL is empty, then we need to make the first simplex
	-- Supplying AFL with polygon edges skips the following block
	-- This should constrain the triangulation to the edges of the polygon (right?)
	if #AFL_o == 0 then
		print("Make first simplex ran (NO! BAD!)")
		t = make_first_simplex(vertices, p_1, p_2, plane)
		-- Insert t (triangle) into list of simplices
		push(simplices, t)
		-- Loop over simplex and insert each f into AFL lists if conditions met
		f = {t[#t], t[1], 0}
	end

	-- Set counter
	-- Init counter per vertex to the number of times it appears in the input AFL
	-- af = active face, v = vertex index
	if #counter == 0 then
		local af, v
		for i = 1, #AFL_o do
			af = AFL_o[i]
			for j = 1, 2 do -- Only touch the first two indices, 3rd index is not part of the face
				v = af[j]
				counter[v] = counter[v] and counter[v] + 1 or 1
			end
		end
	end
	--tprint(counter)

	-- For each face in AFL, put it in the appropriate sub-AFL
	for i=1,#AFL_o do
		-- Set face
		f = AFL_o[i]
		-- Check for where the face should go
		if face_intersects(f,vertices, plane) then 	-- If face interesects cutting plane, goes in the wall
			print("Adding f to AFL_a (" .. f[1] .. ", " .. f[2] .. ")" )
			push(AFL_a, f)
		elseif face_subset(f, p_1) then 		-- If face is a subset of p_1, add it to AFL_1
			print("Adding f to AFL_1 (" .. f[1] .. ", " .. f[2] .. ")" )
			push(AFL_1, f)
		elseif face_subset(f, p_2) then 		-- If face is a subset of p_2, add it to AFL_2
			print("Adding f to AFL_2 (" .. f[1] .. ", " .. f[2] .. ")" )
			push(AFL_2, f)
		end
	end

	-- Length of AFL_a is non-zero, so build out simplices from it
	while #AFL_a ~= 0 do
		-- Extract a face from the AFL list for the wall
		f = pop(AFL_a)
		--print("F is : " .. f[1] .. ", " .. f[2] .. ", "..f[3])
		-- Create a simplex using the face f
		t = make_simplex(vertices,counter, f)
		if t then
			-- Union the simplex t with the rest of the simplices
			push(simplices, t)
			-- loop over faces in simplex t as f_prime, add vertex to test halfspace against
			f_prime[1], f_prime[2], f_prime[3] = t[#t-2], t[#t-1], t[#t]
			for i = 1,#t do
				-- Check f_prime doesn't match f
				if not same_edge_index(f_prime[1], f_prime[2], f[1], f[2]) then
					print("\tF_prime: " .. f_prime[1] .. ", " .. f_prime[2])
					-- Check for where the faces in AFL should go
					if face_intersects(f_prime,vertices, plane) then 	-- If face interesects the plane, update the wall
						print("\tUpdating AFL_a")
						AFL_update(f_prime, vertices,counter, AFL_a)
					elseif face_subset(f_prime, p_1) then 		-- If face is a subset of p_1, update AFL_1
						print("\tUpdating AFL_1")
						AFL_update(f_prime, vertices,counter, AFL_1)
					elseif face_subset(f_prime, p_2) then 		-- If face is a subset of p_2, update AFL_2
						print("\tUpdating AFL_2")
						AFL_update(f_prime, vertices,counter, AFL_2)
						tprint(AFL_2)
					else
						print("uh oh")
						local a, __ = next(plane)
						print("AFL_a"); print("A is: "..a..", "..vertices[f_prime[1]].x..vertices[f_prime[2]].x); tprint(AFL_a)
						print("AFL_1"); tprint(AFL_1)
						print("AFL_2"); tprint(AFL_2)
					end
				end
				-- Cycle f_prime
				f_prime[1], f_prime[2], f_prime[3] = f_prime[2], f_prime[3], t[i]
			end
		end
	end

	-- Recurse into P_1, P_2
	if #AFL_1 ~= 0 then print("recursing for AFL_1") end
	if #AFL_2 ~= 0 then print("recursing for AFL_2") end
	-- Flip axis
	axis = axis == 'x' and 'y' or 'x'
	if #AFL_1 ~= 0 then simplices = dewall_triangulation(vertices,p_1, AFL_1, simplices, axis) end
	if #AFL_2 ~= 0 then simplices = dewall_triangulation(vertices,p_2, AFL_2, simplices, axis) end
	-- Clear counter - it's a dedicated table for this function,
	-- so adding it to the pool is a no-no
	Pool:clean_table( counter )
	-- Return simplices
	return simplices
end

-- Convert simplices returned by triangulation into actual polygons
-- Yes, simplices is plural of simplex
-- No, I did not choose 'simplices' because this function sounds like poetry
local function simplices_indices_vertices(vertices, simplices)
	print("Simplices: ")
	tprint(simplices)
	-- Init triangles table of alternating x,y vals per triangle (6 vals each)
	local triangles = Pool:fetch_table()
    -- Loop over simplices, convert the list of 3 indices to ccw vertices
    -- Use ipairs because we're not doing index-based baffoonery
    for iindex, simplex in ipairs(simplices) do
		triangles[iindex] = Pool:fetch_table()
        for jindex, vertex in ipairs(simplex) do
            triangles[iindex][jindex*2-1] = vertices[vertex].x
			triangles[iindex][jindex * 2] = vertices[vertex].y
        end
    end
	tprint(triangles)
	return triangles
end

-- API Functions

local function unconstrained_delaunay(vertices)
    local points = vertices
    local AFL = Pool:fetch_table() -- {}
    -- Pass args to triangulation function
    local simplices = dewall_triangulation(vertices, points, AFL, {} )
    -- Use simplices to index into vertices and generate list of triangles
    local triangles = simplices_indices_vertices(vertices, simplices)
    -- well, simplices has served its purpose
    Pool:eat_table(simplices)
    -- Create concave polygon per triangle, store in triangles list?
    print("Creating triangle polygons")
    return triangles
end
-- Given a polygon, triangulate it using DeWall given the condition that
-- no lines must be created outside the polygon
-- Takes a vertex list where values are of the form: {x=val, y=val}
local function constrained_delaunay(vertices)
	-- Init points (index list of vertices) and Active-Face List (list of index-pairs that make edges)
	local points = Pool:fetch_table() -- {}
	local AFL = Pool:fetch_table() -- {}
	-- Init point indices with last key of vertices
	points[#vertices] = #vertices
	-- Init AFL list with last entry, edge containing last and first vertex indices
	AFL[#vertices] = {#vertices, 1}
	-- Loop through vertex numbers - 1
	for i = 1, #vertices-1 do
		-- Store point indices
		points[i] = i
		-- Store consecutive edges
		AFL[i] = {i, i+1, 0}
	end
	-- Pass args to triangulation function
	local simplices = dewall_triangulation(vertices, points, AFL, {} )
	-- Use simplices to index into vertices and generate list of triangles
	local triangles = simplices_indices_vertices(vertices, simplices)
	-- well, simplices has served its purpose
	Pool:eat_table(simplices)
	-- Create concave polygon per triangle, store in triangles list?
	print("Creating triangle polygons")
	return triangles
end


-- Test stuff
-- Test line_in_shell
-- create shape with 4 points that make a left and right turn
local vertices = {
	{x =  0, y = 0}, -- origin
	{x =  0, y = 1}, -- up
	{x = -1, y = 1}, -- left
	{x = -1, y = 2}, -- right
	{x = -2, y = 2}, -- left
	{x = -2, y = 0}, -- left
}
print("Testing line_in_shell")
-- Test line from 3 to 6
print("Testing 3, 6: " .. tostring( line_in_shell(vertices, 3, 6) ) )

print("Testing 6, 3: " .. tostring( line_in_shell(vertices, 6, 3) ) )
-- Test from 2 to 4
print("Testing 2, 4: " .. tostring( line_in_shell(vertices, 2, 4) ) )

print("Testing 4, 2: " .. tostring( line_in_shell(vertices, 4, 2) ) )
-- line_in_shell works!


local DeWall = {
    constrained = constrained_delaunay
}

return DeWall