local Shape = _Require_relative(..., "Shape")
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1)
local abs = math.abs
local push = table.insert

---@class VertexShape : Shape
---@field private centroid table<string, number>
---@field private vertices table<number, table<string, number>>
local VertexShape = Shape:extend()

-- Recursive function that returns a list of {x=#,y=#} coordinates given a list of procedural, ccw coordinate pairs
local function to_verts(vertices, x, y, ...)
    if not (x and y) then return vertices end
	vertices[#vertices + 1] = {x = x, y = y} -- , dx = 0, dy = 0}   -- set vertex
	return to_verts(vertices, ...)
end

local function to_vertices(x, ...)
	return type(x) == 'table'and to_verts({}, unpack(x)) or to_verts({}, x,...)
end

-- Create new Polygon object
---@vararg number x,y tuples
---@param x number
---@param y number
function VertexShape:new(x,y, ...)
    VertexShape.super.new(self)
	self.centroid = {x=0, y=0}
	self.vertices = to_vertices(x,y, ...)
end

---Get a vertex by its offset
---@param i number
---@return number|false v.x or false if beyond range
---@return number|false v.y
function VertexShape:getVertex(i)
	if i > #self.vertices then return false, false end
	local v = self.vertices[i]
	return v.x, v.y
end

---Get an edge by index
---@param i number
---@return table|false res edge of form {x1,y1, x2,y2} or false if index out of range
function VertexShape:getEdge(i)
	if i > #self.vertices then return false end
	local verts = self.vertices
	local j = i < #verts and i+1 or 1
	local p1x, p1y = self:getVertex(i)
	local p2x, p2y = self:getVertex(j)
	return {p1x, p1y, p2x, p2y}
end

---Project polygon along normalized vector
---@param nx number normalized x-component
---@param ny number normalized y-component
---@return number minimum, number maximumum smallest, largest projection
function VertexShape:project(nx,ny)
	local vertices = self.vertices
	local proj_x, proj_y
	local p, min_dot, max_dot
	-- Project each point onto vector <nx, ny>
	proj_x, proj_y = self:getVertex(1)
	-- Init our min/max dot products (Can't init to random value)
	min_dot = Vec.dot(proj_x,proj_y, nx,ny)
	max_dot = min_dot
	-- Create new projection vectors, dot-prod them with the input vector, and return the min/max
	for i = 2, #vertices do
		proj_x, proj_y = self:getVertex(i)
		p = Vec.dot(proj_x,proj_y, nx,ny)
		if p < min_dot then min_dot = p elseif p > max_dot then max_dot = p end
	end
	return min_dot, max_dot
end

---Translate by displacement vector
---@param dx number
---@param dy number
---@return VertexShape self
function VertexShape:translate(dx, dy)
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
---@return VertexShape self
function VertexShape:rotate(angle, refx, refy)
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

--- scale helper function
local function scale_p(x,y, sf,rx,ry)
	return Vec.add(rx, ry, Vec.mul(sf, x-rx, y - ry))
end

---Scale polygon
---@param sf number scale factor
---@param refx number reference x-coordinate
---@param refy number reference y-coordinate
---@return VertexShape self
function VertexShape:scale(sf, refx, refy)
	-- Default to centroid as ref-point
	local c = self.centroid
    refx = refx or c.x
	refy = refy or c.y
	-- Push each vertex out from the ref point by scale-factor
    for i = 1, #self.vertices do
        local v = self.vertices[i]
        v.x, v.y = scale_p(v.x,v.y, sf,refx,refy)
    end
	c.x, c.y = scale_p(c.x, c.y, sf, refx, refy)
    -- Recalculate area, and radius
    self.area = self.area * sf * sf
    self.radius = self.radius * sf
	return self
end

local function iter_edges(shape, i)
	i = i + 1
	local len, ix, iy = #shape.vertices, shape:getVertex(i)
	if i <= len then
		local j = i < len and i+1 or 1
		local jx, jy = shape:getVertex(j)
		return i, {ix, iy, jx, jy}
	end
end

---Edge Iterator
---@return function
---@return VertexShape
---@return number
function VertexShape:ipairs()
    return iter_edges, self, 0
end

---Iterate through vectors that make up edges
---@param shape VertexShape
---@param i number
---@return integer
---@return table
local function iter_vecs(shape, i)
	i = i + 1
	local len, ix, iy = #shape.vertices, shape:getVertex(i)
	if i <= len then
		local j = i < len and i+1 or 1
		local jx, jy = shape:getVertex(j)
		return i, {x = jx - ix, y = jy - iy}
	end
end

---Iterate over edge vectors
---@return function
---@return VertexShape
---@return number
function VertexShape:vecs()
    return iter_vecs, self, 0
end

---Project each individual edge instead of using self:project like in Circle
---@param x number ray origin
---@param y number ray origin
---@param dx number normalized x component
---@param dy number normalized y component
---@return boolean hit
function VertexShape:rayIntersects(x,y, dx,dy)
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
function VertexShape:rayIntersections(x,y, dx,dy, ts)
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

---Contact Functions
function VertexShape:getSupport(nx,ny)
    local maxd, index = -math.huge , 1
    for i = 1, #self.vertices do
		local px,py = self:getVertex(i)
        local projection = Vec.dot(px,py, nx,ny)
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
function VertexShape:getFeature(nx,ny)
    local verts = self.vertices
    -- get farthest point in direction of normal
    local index = self:getSupport(nx,ny)
    -- test adjacent points to find edge most perpendicular to normal
    local vx, vy = self:getVertex(index)
    local i0 = index - 1 >= 1 and index - 1 or #verts
    local i1 = index + 1 <= #verts and index + 1 or 1
    local v0x, v0y = self:getVertex(i0)
    local v1x, v1y = self:getVertex(i1)
    local gx,gy = Vec.normalize( Vec.sub(vx,vy, v0x,v0y) )
    local hx,hy = Vec.normalize( Vec.sub(vx,vy, v1x,v1y) )
    if math.abs(Vec.dot(gx,gy, nx,ny)) <= math.abs(Vec.dot(hx,hy, nx,ny)) then
        return {x=vx,y=vy}, {{x=v0x,y=v0y}, {x=vx,y=vy}}
    else
        return {x=vx,y=vy}, {{x=vx,y=vy}, {x=v1x,y=v1y}}
    end
end

return VertexShape