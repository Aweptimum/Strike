local abs, max, atan2 	= math.abs, math.max, math.atan2
local push = table.insert
local tbl = Libs.tbl
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local VertexShape = _Require_relative(...,"VertexShape")

---@class ConvexPolygon : VertexShape
ConvexPolygon = VertexShape:extend()
ConvexPolygon.name = 'convex'

-- Test if 3 points are collinear (do they not make a triangle?)
local function is_collinear(a, b, c)
	return abs(Vec.det(a.x-c.x, a.y-c.y, b.x-c.x,b.y-c.y)) <= 1e-32
end

-- Test if 3 points make a ccw turn (same as collinear function, but checks for >= 0)
local function is_ccw(p, q, r)
	return Vec.det(q.x-p.x, q.y-p.y,  r.x-p.x, r.y-p.y) >= 0
end

local function is_ccw_scalar(px,py, qx,qy, rx,ry)
	return Vec.det(qx-px, qy-py,  rx-px, ry-py) >= 0
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
---@return Shape self
function ConvexPolygon:calcArea()
	local len = #self.vertices
	-- Initialize p and q so we can wrap around in the loop
	local px, py = self:getVertex(len)
	local qx, qy = self:getVertex(1)
	-- a is the signed area of the triangle formed by the two legs of px - qx and py - qy - it is our weighting
	local a = Vec.det(px,py, qx,qy)
	-- signed_area is the total signed area of all triangles
	local area = a

	for i = 2, len do
		-- Now assign p to q, q to next
		px,py = qx,qy
		qx,qy = self:getVertex(i)
		a = Vec.det(px,py, qx,qy)
		area = area + a
	end

	self.area = area * 0.5
	return self
end

---Calculate centroid and area of the polygon at the _same_ time
---@return Shape self
function ConvexPolygon:calcAreaCentroid()
	local len = #self.vertices
	-- Initialize p and q so we can wrap around in the loop
	local px, py = self:getVertex(len)
	local qx, qy = self:getVertex(1)
	-- a is the signed area of the triangle formed by the two legs of px - qx and py - qy - it is our weighting
	local a = Vec.det(px,py, qx,qy)
	-- area is the total area of all triangles
	self.area = a
	local cx, cy = (px+qx)*a, (py+qy)*a

	for i = 2, len do
		-- Now assign p to q, q to next
		px,py = qx,qy
		qx,qy = self:getVertex(i)
		a = Vec.det(px,py, qx,qy)
		cx, cy = cx + (px+qx)*a, cy + (py+qy)*a
		self.area = self.area + a
	end
	self.area = self.area * 0.5
	self.centroid = {
		x = cx / (6*self.area),
		y = cy / (6*self.area)
	}
	return self
end

---Calculate polygon radius
---@return Shape self
function ConvexPolygon:calcRadius()
	local cx, cy = self:getCentroid()
	local vertices, radius = self.vertices, 0
	for i = 1,#vertices do
		local vx, vy = self:getVertex(i)
		radius = max(radius, Vec.dist(vx,vy, cx,cy))
	end
	self.radius = radius
	return self
end

---Get polygon bounding box
---@return number x, number y, number dx, number dy minimum x/y, width, and height
function ConvexPolygon:getBbox()
	local min_x, min_y = self:getVertex(1)
	local max_x, max_y = min_x, min_y
	local x, y--, bbox
	for i = 1, #self.vertices do
		x, y = self:getVertex(i)
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
    ConvexPolygon.super.new(self, x,y, ...)
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

--- Need this to test if a shape is completely inside
---@param point Point
function ConvexPolygon:containsPoint(point)
	local len = #self.vertices
	local winding = 0
	local px, py = self:getVertex(len)
	local qx, qy = self:getVertex(1)
	local rx, ry = point.x, point.y
	for i = 1, len do
		if py < point.y then
			if qy > point.y and is_ccw_scalar(px,py, qx,qy, rx,ry) then
				winding = winding + 1
			end
		else
			if qy < point.y and not is_ccw_scalar(px,py, qx,qy, rx,ry) then
				winding = winding - 1
			end
		end
	end
	return winding ~= 0
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
		local v1x, v1y = poly1:getVertex(i)
		local key = v1x..'-'..v1y
        p_map[key] = i
    end
    -- Now look through poly_2's vertices and see if there's a match
    local v2 = poly2.vertices
    local i = #v2
    for j = 1, #v2 do
        -- Set p and q to reference poly_2's vertices at i and j
        local px, py = poly2:getVertex(i)
		local qx, qy = poly2:getVertex(j)
		local kp, kq = px..'-'..py, qx..'-'..qy
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
---@throws error if the union is not convex
---@return ConvexPolygon
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
			local x,y = poly1:getVertex(i)
			push(union, x)
			push(union, y)
		end
	end
	-- Do the same for poly2
	for i = 1, #v2 do
		if i ~= i_2 then
			local x,y = poly2:getVertex(i)
			push(union, x)
			push(union, y)
		end
	end
	return ConvexPolygon(union)
end

ConvexPolygon.merge = merge_convex_incident

if love and love.graphics then
	---Draw polygon w/ LOVE
	---@param mode string fill/line
	function ConvexPolygon:draw(mode)
		-- default fill to "line"
		mode = mode or "line"
		for i, edge in self:ipairs() do
			love.graphics.line(unpack(edge))
		end
	end
end

return ConvexPolygon