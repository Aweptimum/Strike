-- "Abstract" base object, provides some generic methods.
local Object = require 'Strike.classic.classic'

local Shape = Object:extend()

Shape.type = 'shape'

function Shape:get_area()
    return self.area
end

function Shape:get_centroid()
    return self.centroid
end

function Shape:get_area_centroid()
    return self.area, self.centroid
end

function Shape:get_bbox()
end

function Shape:get_radius()
end

function Shape:project()
end

function Shape:unpack()
end

function Shape:translate()
end

function Shape:rotate()
end

function Shape:scale()
end

function Shape:copy(x, y, angle_rads)
    local copy = self:_copy()
	-- if origin specified, then translate
	if x and y then
		copy:translate_to(x, y)
	end
	-- If rotation specified, then rotate_polygon
	if angle_rads then
		copy:rotate(angle_rads)
    end
	-- Return copy
	return copy
end

function Shape:calc_area()
end

function Shape:calc_centroid()
end

function Shape:calc_area_centroid()
end

return Shape