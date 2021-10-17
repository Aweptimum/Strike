-- "Abstract" base object, provides some generic methods.
local Object = Libs.classic

local Shape = Object:extend()

Shape.type = 'shape'

function Shape:getArea()
    return self.area
end

function Shape:getCentroid()
    return self.centroid
end

function Shape:getAreaCentroid()
    return self.area, self.centroid
end

function Shape:getBbox()
end

function Shape:getRadius()
end

function Shape:project()
end

function Shape:unpack()
end

function Shape:translate()
end

function Shape:translateTo(x, y)
	local dx, dy = x - self.centroid.x, y - self.centroid.y
	return self:translate(dx,dy)
end

function Shape:rotate()
end

function Shape:rotateTo(angle_rads, ref_x, ref_y)
	local aoffset = angle_rads - self.angle
	return self:rotate(aoffset, ref_x, ref_y)
end

function Shape:scale()
end

function Shape:copy(x, y, angle_rads)
    local copy = self:_copy()
	-- if origin specified, then translate
	if x and y then
		copy:translateTo(x, y)
	end
	-- If rotation specified, then rotate_polygon
	if angle_rads then
		copy:rotateTo(angle_rads)
    end
	-- Return copy
	return copy
end

function Shape:calcArea()
end

function Shape:calcCentroid()
end

function Shape:calcAreaCentroid()
end

return Shape