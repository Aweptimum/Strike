local Vec	= require "Slap.DeWallua.vector-light"
local Shape = require "Slap.shapes.shape"
local abs, max	= math.abs, math.max
local atan2 = math.atan2

-- Create polygon object
local ConvexPolygon = {
    vertices 		= {},              -- list of {x,y} coords
    convex      	= true,             -- boolean
    centroid   		= {x = 0, y = 0},	-- {x, y} coordinate pair
    radius			= 0,				-- radius of circumscribed circle
    area			= 0					-- absolute/unsigned area of polygon
}
--ConvexPolygon.__index = ConvexPolygon
ConvexPolygon = Shape:extend()
ConvexPolygon.name = 'convex'

-- Recursive function that returns a list of {x=#,y=#} coordinates given a list of procedural, ccw coordinate pairs
local function to_vertices(vertices, x, y, ...)
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
	local trimmed = {}
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

-- Two lines, a-b and c-d, intersect if their endpoints lie on different sides wrt each other
local function are_lines_intersecting(a,b, c,d)
	return is_ccw(a,b,c) ~= is_ccw(a,b,d) and is_ccw(a,c,d) ~= is_ccw(b,c,d)
end

-- Checks for physical intersection of lines within polygon's vertices
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

-- Check if points are convex by verifying all groups of 3 points make a ccw winding
local function is_convex(vertices)
	local i, j = #vertices-1, #vertices
	for k = 1, #vertices do
		-- Convex polygons always make a ccw turn
		-- If we don't, then this is not a convex polygon and we return false.
		if not is_ccw(vertices[i], vertices[j], vertices[k]) then
			return false
		end
		-- Cycle i to j, j to k
		i,j = j,k
	end
	-- Made it out, so it must be convex
	return true
end

-- Enforce counter-clockwise points order
-- using graham scan algorithm to return the ordered hull.
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

    -- Creat table of indices, sort the indices by corresponding vertex, then check if index order is_convex.
	-- If is_convex, apply order to vertices, then return vertices, return false if not convex (triangulation time).
	local vertices_clone = {}
    -- Shallow copy vertices
	shallow_copy_table(vertices, vertices_clone)
	-- Sort table
	table.sort(vertices_clone, sort_ccw)
	-- Check if convex
	local good_sort = is_convex(vertices_clone)

	-- And return our investigation
    if good_sort then
        table.sort(vertices, sort_ccw)
		return true --- true means the list is convex after all
    else
        return false -- false means not convex, treat it as concave
    end

end

function ConvexPolygon:calc_area()
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

-- Calculate centroid and area of the polygon at the _same_ time using the shoe-lace algorithm
function ConvexPolygon:calc_area_centroid()
	local vertices = self.vertices
	-- Initialize p and q so we can wrap around in the loop
	local p, q = vertices[#vertices], vertices[1]
	-- a is the signed area of the triangle formed by the two legs of p.x-q.x and p.y-q.y - it is our weighting
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
	return self.centroid, self.area
end

function ConvexPolygon:calc_radius()
	local vertices, radius = self.vertices, 0
	for i = 1,#vertices do
		radius = max(radius, Vec.dist(vertices[i].x,vertices[i].y, self.centroid.x, self.centroid.y))
	end
	self.radius = radius
	return radius
end

function ConvexPolygon:get_bbox()

	local min_x, max_x, min_y, max_y = self.vertices[1].x,self.vertices[1].x, self.vertices[1].y, self.vertices[1].y
	local x, y--, bbox
	for __, vertex in ipairs(self.vertices) do
		x, y = vertex.x, vertex.y
		if x < min_x then min_x = x end
		if x > max_x then max_x = x end
		if y < min_y then min_y = y end
		if y > max_y then max_y = y end
	end
    -- Return rect info as separate values (don't create a table!)
	-- If the bbox is constantly being re-calculated every frame for broadphase, that's a lot of garbage.
	return min_x, min_y, max_x-min_x, max_y-min_y
end

function ConvexPolygon:unpack()
	local v = {}
	for i = 1,#self.vertices do
		v[2*i-1] = self.vertices[i].x
		v[2*i]   = self.vertices[i].y
	end
	return unpack(v)
end

-- Create new Polygon object
function ConvexPolygon:new(...)
    self.vertices = to_vertices({},...)
	if not is_convex(self.vertices) then
		assert(order_points_ccw(self.vertices), 'Points cannot be ordered into a convex shape')
	end
	trim_collinear_points(self.vertices)
	assert(not is_self_intersecting(self.vertices), 'Ordered points still self-intersecting')
	self:calc_area_centroid()
	self:calc_radius()
end

local function iter_edges(shape, i)
	i = i + 1
	local v = shape.vertices
	if i <= #v then
		local j = i < #v and i+1 or 1
		return i, {v[i].x, v[i].y, v[j].x, v[j].y}
	end
end

function ConvexPolygon:ipairs()
    return iter_edges, self, 0
end

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
    return self.centroid.x, self.centroid.y
end

function ConvexPolygon:translate_to(x, y)
	local dx, dy = x - self.centroid.x, y - self.centroid.y
	return self:translate(dx,dy)
end

function ConvexPolygon:rotate(angle, ref_x, ref_y)
	-- Default to centroid as ref-point
    ref_x = ref_x or self.centroid.x
	ref_y = ref_y or self.centroid.y
	-- Rotate each vertex about ref-point
    for i = 1, #self.vertices do
        local v = self.vertices[i]
        v.x, v.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, v.x-ref_x, v.y - ref_y))
    end
	self.centroid.x, self.centroid.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, self.centroid.x-ref_x, self.centroid.y-ref_y))
end

function ConvexPolygon:scale(sf, ref_x, ref_y)
	-- Default to centroid as ref-point
    ref_x = ref_x or self.centroid.x
	ref_y = ref_y and ref_x or self.centroid.y
	-- Push each vertex out from the ref point by scale-factor
    for i = 1, #self.vertices do
        local v = self.vertices[i]
        v.x, v.y = Vec.add(ref_x, ref_y, Vec.mul(sf, v.x-ref_x, v.y - ref_y))
    end
	self.centroid.x, self.centroid.y = Vec.add(ref_x, ref_y, Vec.mul(sf, self.centroid.x-ref_x, self.centroid.y - ref_y))
    -- Recalculate area, and radius
    self:calc_area()
    self.radius = self.radius * sf
end

function ConvexPolygon:project(nx,ny)
	-- Dummy var for storing dot-product results
	local vertices = self.vertices
	local p = 0
	-- The vector to project, travelling from the origin to the vertices of the polygon
	-- So it's really just the x/y coordinates of a vertex
	local proj_x, proj_y = vertices[1].x, vertices[1].y
	-- Init our min/max dot products.
	-- Can't init to random value; min_dot might never go below the starting value.
	local min_dot = Vec.dot(proj_x,proj_y, nx,ny)
	local max_dot = min_dot
	-- Create new projection vectors, dot-prod them with the input vector, and return the min/max
	for i = 2, #vertices do
		proj_x, proj_y = vertices[i].x , vertices[i].y
		p = Vec.dot(proj_x,proj_y, nx,ny)
		if p < min_dot then min_dot = p elseif p > max_dot then max_dot = p end
	end
	return min_dot, max_dot
end

-- Need this to test if a shape is completely inside
function ConvexPolygon:point_inside(point)
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

ConvexPolygon._get_verts = ConvexPolygon.unpack

function ConvexPolygon:draw(mode)
	-- default fill to "line"
	mode = mode or "line"
	love.graphics.polygon("line", self:_get_verts())
end

return ConvexPolygon