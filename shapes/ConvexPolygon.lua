local Vec = require "Slap.DeWallua.vector-light"
local Shape = require "Slap.shapes.shape"
local abs = math.abs

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
	local area = a
	local centroid = {x = (p.x+q.x)*a, y = (p.y+q.y)*a}

	for i = 2, #vertices do
		-- Now cycle p to q, q to next vertex
		p, q = q, vertices[i]
		a = Vec.det(p.x,p.y, q.x,q.y)
		centroid.x, centroid.y = centroid.x + (p.x+q.x)*a, centroid.y + (p.y+q.y)*a
		area = area + a
	end

	self.area = area * 0.5
	self.centroid.x	= centroid.x / (6.0*area);
    self.centroid.y	= centroid.y / (6.0*area);
	return centroid, area
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
	print('constructing polygon')
    self.vertices = to_vertices({},...)
	self:calc_area_centroid()
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

function ConvexPolygon:rotate(angle, ref_x, ref_y)
	-- Default to centroid as ref-point
    ref_x = ref_x or self.centroid.x
	ref_y = ref_y and ref_x or self.centroid.y
	-- Rotate each vertex about ref-point
    for i = 1, self.vertices do
        local v = self.vertices[i]
        v.x, v.y = Vec.add(ref_x, ref_y, Vec.rotate(angle, v.x-ref_x, v.y - ref_y))
    end
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
    -- Recalculate centroid, area, and radius while we're here
    self.centroid, self.area = self:calc_area_centroid()
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

function ConvexPolygon:draw(mode)
	-- default fill to "line"
	mode = mode or "line"
	love.graphics.polygon("line", self:unpack())
end

return ConvexPolygon