local abs, min, max, atan2 	= math.abs, math.min, math.max, math.atan2
local push = table.insert
local tbl = Libs.tbl
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local Shape = _Require_relative(...,"Shape")

---@class ConvexPolygon : Shape
ConvexPolygon = Shape:extend()
ConvexPolygon.name = 'convex'

-- Recursive function that returns a list of {x=#,y=#} coordinates given a list of procedural, ccw coordinate pairs
local function to_verts(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_verts(vertices, ...)
end

local function to_vertices(vertices, x, ...)
	return type(x) == 'table'and to_verts(vertices, unpack(x)) or to_verts(vertices, x,...)
end

-- Test if 3 points are collinear (do they not make a triangle?)
local function is_collinear(a, b, c)
	return abs(Vec.det(a.x-c.x, a.y-c.y, b.x-c.x,b.y-c.y)) <= 1e-32
end

-- Test if 3 points make a ccw turn (same as collinear function, but checks for >= 0)
local function is_ccw(p, q, r)
	return Vec.det(q.x-p.x, q.y-p.y,  r.x-p.x, r.y-p.y) >= 0
end

-- Remove vertices that are collinear
local function trim_collinear(vertices)
	local trimmed = {}
	local i, j = #vertices-1, #vertices
	for k = 1, #vertices do
		if not is_collinear(vertices[i], vertices[j], vertices[k]) then
			trimmed[#trimmed+1] = vertices[j]
		end
		i,j = j,k
	end
	return trimmed
end

-- Two lines, a-b and c-d, intersect if their endpoints lie on different sides wrt each other
local function are_lines_intersecting(a,b, c,d)
	return is_ccw(a,b,c) ~= is_ccw(a,b,d) and is_ccw(a,c,d) ~= is_ccw(b,c,d)
end

-- Checks for physical intersection of lines within polygon's vertices
local function self_intersecting(vertices)
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

-- Check if points are convex by verifying all groups of 3 points make a ccw winding
local function is_convex(vertices)
	local i, j = #vertices-1, #vertices
	for k = 1, #vertices do
		-- Convex polygons always make a ccw turn
		if not is_ccw(vertices[i], vertices[j], vertices[k]) then
			return false
		end
		-- Cycle i to j, j to k
		i,j = j,k
	end
	-- Made it out, must be convex
	return true
end

-- Enforce counter-clockwise points order using graham scan sort
local function order_points_ccw(vertices)
	-- Find reference point to calculate cw/ccw from (left-most x, lowest y)
	local p_ref = vertices[1]
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
    -- Sort a copy of vertices. If convex, then apply the sort to the original, else return false
	local vertices_clone = tbl.shallow_copy(vertices, {})
	-- Sort table, Check if convex
	table.sort(vertices_clone, sort_ccw)
	local good_sort = is_convex(vertices_clone)

	-- Return our investigation
    return good_sort and true, table.sort(vertices, sort_ccw) or not true
end

---Calculate polygon area using shoelace algorithm
---@return number area
function ConvexPolygon:calcArea()
	local vertices = self.vertices
	-- Initialize p and q so we can wrap around in the loop
	local p, q = vertices[#vertices], vertices[1]
	-- a is the signed area of the triangle formed by the two legs of p.x-q.x and p.y-q.y - it is our weighting
	local a = Vec.det(p.x,p.y, q.x,q.y)
	-- signed_area is the total signed area of all triangles
	local area = a

	for i = 2, #vertices do
		-- Now assign p to q, q to next
		p, q = q, vertices[i]
		a = Vec.det(p.x,p.y, q.x,q.y)
		area = area + a
	end

	self.area = area * 0.5
	return self.area
end

---Calculate centroid and area of the polygon at the _same_ time
---@return number area
---@return table centroid
function ConvexPolygon:calcAreaCentroid()
	local vertices = self.vertices
	-- Initialize p and q so we can wrap around in the loop
	local p, q = vertices[#vertices], vertices[1]
	-- a is the area of the triangle formed by the two legs of p.x-q.x and p.y-q.y - it is our weighting
	local a = Vec.det(p.x,p.y, q.x,q.y)
	-- area is the total area of all triangles
	self.area = a
	self.centroid = {x = (p.x+q.x)*a, y = (p.y+q.y)*a}

	for i = 2, #vertices do
		-- Now cycle p to q, q to next vertex
		p, q = q, vertices[i]
		a = Vec.det(p.x,p.y, q.x,q.y)
		self.centroid.x, self.centroid.y = self.centroid.x + (p.x+q.x)*a, self.centroid.y + (p.y+q.y)*a
		self.area = self.area + a
	end
	self.area = self.area * 0.5
	self.centroid.x	= self.centroid.x / (6*self.area);
    self.centroid.y	= self.centroid.y / (6*self.area);
	return self.area, self.centroid
end

---Calculate polygon radius
---@return number radius
function ConvexPolygon:calcRadius()
	local vertices, radius = self.vertices, 0
	for i = 1,#vertices do
		radius = max(radius, Vec.dist(vertices[i].x,vertices[i].y, self.centroid.x, self.centroid.y))
	end
	self.radius = radius
	return self.radius
end

function ConvexPolygon:getVertexCount()
    return #self.vertices
end

---Get polygon bounding box
---@return number x, number y, number dx, number dy minimum x/y, width, and height
function ConvexPolygon:getBbox()
	local min_x, max_x, min_y, max_y = self.vertices[1].x,self.vertices[1].x, self.vertices[1].y, self.vertices[1].y
	local x, y--, bbox
	for __, vertex in ipairs(self.vertices) do
		x, y = vertex.x, vertex.y
		if x < min_x then min_x = x end
		if x > max_x then max_x = x end
		if y < min_y then min_y = y end
		if y > max_y then max_y = y end
	end
    -- Return rect info as separate values (don't create a table (aka garbage)!)
	return min_x, min_y, max_x-min_x, max_y-min_y
end

---Return unpacked vertices
---@return number[] ... variable list used to construct the polygon
function ConvexPolygon:unpack()
	local v = {}
	for i = 1,#self.vertices do
		v[2*i-1] = self.vertices[i].x
		v[2*i]   = self.vertices[i].y
	end
	return unpack(v)
end

-- Create new Polygon object
---@vararg number x,y tuples
---@param x number
---@param y number
function ConvexPolygon:new(x,y, ...)
    self.vertices = to_vertices({}, x,y, ...)
	assert(#self.vertices >= 3, "Need at least 3 non collinear points to build polygon (got "..#self.vertices..")")
	if not is_convex(self.vertices) then
		assert(order_points_ccw(self.vertices), 'Points cannot be ordered into a convex shape')
	end
	trim_collinear(self.vertices)
	assert(not self_intersecting(self.vertices), 'Ordered points still self-intersecting')
	self.centroid = {x=0,y=0}
	self.area = 0
	self.radius = 0
	self.angle = 0
	self:calcAreaCentroid()
	self:calcRadius()
end

local function iter_edges(shape, i)
	i = i + 1
	local v = shape.vertices
	if i <= #v then
		local j = i < #v and i+1 or 1
		return i, {v[i].x, v[i].y, v[j].x, v[j].y}
	end
end

---Edge Iterator
---@return function
---@return ConvexPolygon
---@return number
function ConvexPolygon:ipairs()
    return iter_edges, self, 0
end

---Translate by displacement vector
---@param dx number
---@param dy number
---@return ConvexPolygon self
function ConvexPolygon:translate(dx, dy)
	-- Translate each vertex by dx, dy
	local vertices = self.vertices
    for i = 1, #vertices do
        vertices[i].x = vertices[i].x + dx
        vertices[i].y = vertices[i].y + dy
    end
	-- Translate centroid
	self.centroid.x = self.centroid.x + dx
	self.centroid.y = self.centroid.y + dy
    return self
end

---Rotate by specified radians
---@param angle number radians
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return ConvexPolygon self
function ConvexPolygon:rotate(angle, refx, refy)
	-- Default to centroid as ref-point
    refx = refx or self.centroid.x
	refy = refy or self.centroid.y
	-- Rotate each vertex about ref-point
    for i = 1, #self.vertices do
        local v = self.vertices[i]
        v.x, v.y = Vec.add(refx, refy, Vec.rotate(angle, v.x-refx, v.y - refy))
    end
	self.centroid.x, self.centroid.y = Vec.add(refx, refy, Vec.rotate(angle, self.centroid.x-refx, self.centroid.y-refy))
	self.angle = self.angle + angle
	return self
end

---Scale polygon
---@param sf number scale factor
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return ConvexPolygon self
function ConvexPolygon:scale(sf, refx, refy)
	-- Default to centroid as ref-point
    refx = refx or self.centroid.x
	refy = refy or self.centroid.y
	-- Push each vertex out from the ref point by scale-factor
    for i = 1, #self.vertices do
        local v = self.vertices[i]
        v.x, v.y = Vec.add(refx, refy, Vec.mul(sf, v.x-refx, v.y - refy))
    end
	self.centroid.x, self.centroid.y = Vec.add(refx, refy, Vec.mul(sf, self.centroid.x-refx, self.centroid.y - refy))
    -- Recalculate area, and radius
    self:calcArea()
    self.radius = self.radius * sf
	return self
end

---Project polygon along normalized vector
---@param nx number normalized x-component
---@param ny number normalized y-component
---@return number minimum, number maximumum smallest, largest projection
function ConvexPolygon:project(nx,ny)
	local vertices = self.vertices
	local proj_x, proj_y
	local p, min_dot, max_dot
	-- Project each point onto vector <nx, ny>
	proj_x, proj_y = vertices[1].x, vertices[1].y
	-- Init our min/max dot products (Can't init to random value)
	min_dot = Vec.dot(proj_x,proj_y, nx,ny)
	max_dot = min_dot
	-- Create new projection vectors, dot-prod them with the input vector, and return the min/max
	for i = 2, #vertices do
		proj_x, proj_y = vertices[i].x , vertices[i].y
		p = Vec.dot(proj_x,proj_y, nx,ny)
		if p < min_dot then min_dot = p elseif p > max_dot then max_dot = p end
	end
	return min_dot, max_dot
end

---Get an edge by index
---@param i number
---@return table {x1,y1, x2,y2}
function ConvexPolygon:getEdge(i)
	if i > #self.vertices then return false end
	local verts = self.vertices
	local j = i < #verts and i+1 or 1
	local p1, p2 = verts[i], verts[j]
	return {p1.x, p1.y, p2.x, p2.y}
end

--- Need this to test if a shape is completely inside
---@param point Point
function ConvexPolygon:containsPoint(point)
	local vertices = self.vertices
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

---Project each individual edge instead of using self:project like in Circle
---@param x number ray origin
---@param y number ray origin
---@param dx number normalized x component
---@param dy number normalized y component
---@return boolean hit
function ConvexPolygon:rayIntersects(x,y, dx,dy)
	dx, dy = Vec.perpendicular(dx,dy)
    local d = Vec.dot(x,y, dx,dy)
	for i, edge in self:ipairs() do
		local e1 = Vec.dot(edge[1],edge[2], dx,dy)
		local e2 = Vec.dot(edge[3],edge[4], dx,dy)
		if (e1-d) * (e2-d) <= 0 then return true end
	end
	return false
end

-- https://stackoverflow.com/a/32146853/12135804
---Return all intersections as distances along ray
---@param x number ray origin
---@param y number ray origin
---@param dx number normalized x component
---@param dy number normalized y component
---@param ts table
---@return table | nil intersections
function ConvexPolygon:rayIntersections(x,y, dx,dy, ts)
	local v1x, v1y, v2x, v2y
	local nx, ny = -dy, dx
	ts = ts or {}
	for i, edge in self:ipairs() do
		v1x, v1y = Vec.sub(x, y, edge[1], edge[2])
		v2x, v2y = Vec.sub(edge[3], edge[4], edge[1], edge[2])
		local dot = Vec.dot(v2x, v2y, nx, ny)
		if abs(dot) < 0.0001 then break end
		local t1 = Vec.det(v2x,v2y, v1x,v1y) / dot
		local t2 = Vec.dot(v1x,v1y, nx,ny) / dot
		if t1 >= 0 and (t2 >= 0 and t2 <= 1) then push(ts, t1) end
	end
	return #ts > 0 and ts or nil
end

ConvexPolygon._get_verts = ConvexPolygon.unpack

-- ------------------]]    Polygon Merging    [[------------------ --

-- Use spatial-coordinate search to detect if two polygons
-- share a coordinate pair (means have an incident face)
local function get_incident_edge(poly1, poly2)
    -- Define hash table
    local p_map = {}
    -- Iterate over poly_1's vertices, add x/y coords as keys to pmap
    local v1 = poly1.vertices
    for i = 1, #v1 do
		local key = v1[i].x..'-'..v1[i].y
        p_map[key] = i
    end
    -- Now look through poly_2's vertices and see if there's a match
    local v2 = poly2.vertices
    local i = #v2
    for j = 1, #v2 do
        -- Set p and q to reference poly_2's vertices at i and j
        local p, q = v2[i], v2[j]
		local kp, kq = p.x..'-'..p.y, q.x..'-'..q.y
        -- Access p_map based on line p-q's two coordinates
        if p_map[kp] and p_map[kq] then
            -- Return the indices of the edge in both polygons
            return p_map[kp],p_map[kq], i,j
        end
        i = j
    end
    -- No incident edge
    return false
end

-- Given two convex polygons, merge them together
-- So long as the new polygon is also convex
---@param poly1 ConvexPolygon
---@param poly2 ConvexPolygon
---@return ConvexPolygon | boolean
local function merge_convex_incident(poly1, poly2)
	if not poly2.vertices then return false end
    -- Find an incident edge between the two polygons
    local i_1,j_1, i_2,j_2 = get_incident_edge(poly1, poly2)

	if not i_1 then return false end

	local v1, v2 = poly1.vertices, poly2.vertices
	local union = {}
	-- Loop through the vertices of poly_1 and add applicable points to the union
	for i = 1, #v1 do
		-- Skip the vertex if it's part of the poly_2's half of the incident edge
		if i ~= j_1 then
			push(union, v1[i].x)
			push(union, v1[i].y)
		end
	end
	-- Do the same for poly2
	for i = 1, #v2 do
		if i ~= i_2 then
			push(union, v2[i].x)
			push(union, v2[i].y)
		end
	end
	local new_verts = to_vertices({},unpack(union))
	order_points_ccw(new_verts)
	return is_convex(new_verts) and ConvexPolygon(unpack(union)) or not true
end

ConvexPolygon.merge = merge_convex_incident

---Contact Functions
function ConvexPolygon:getSupport(nx,ny)
    local maxd, index = -math.huge , 1
    for i, point in ipairs(self.vertices) do
        local projection = Vec.dot(point.x,point.y, nx,ny)
        if projection > maxd then
            maxd = projection
            index = i
        end
    end
    return index
end

---Get the edge involved in a collision
---@param nx number normalized x dir
---@param ny number normalized y dir
---@return table Max-Point
---@return table Edge
function ConvexPolygon:getFeature(nx,ny)
    local verts = self.vertices
    -- get farthest point in direction of normal
    local index = self:getSupport(nx,ny)
    -- test adjacent points to find edge most perpendicular to normal
    local v = verts[index]
    local i0 = index - 1 >= 1 and index - 1 or #verts
    local i1 = index + 1 <= #verts and index + 1 or 1
    local v0 = verts[i0]
    local v1 = verts[i1]
    local gx,gy = Vec.normalize( Vec.sub(v.x,v.y, v0.x,v0.y) )
    local hx,hy = Vec.normalize( Vec.sub(v.x,v.y, v1.x,v1.y) )
    if math.abs(Vec.dot(gx,gy, nx,ny)) <= math.abs(Vec.dot(hx,hy, nx,ny)) then
        return {x=v.x,y=v.y}, {{x=v0.x,y=v0.y}, {x=v.x,y=v.y}}
    else
        return {x=v.x,y=v.y}, {{x=v.x,y=v.y}, {x=v1.x,y=v1.y}}
    end
end

if love and love.graphics then
	---Draw polygon w/ LOVE
	---@param mode string fill/line
	function ConvexPolygon:draw(mode)
		-- default fill to "line"
		mode = mode or "line"
		love.graphics.polygon(mode, self:_get_verts())
	end
end

return ConvexPolygon