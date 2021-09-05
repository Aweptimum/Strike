-- "Abstract" base object, provides some generic methods.
local Object = require 'Slap.classic.classic'

local Shape = Object:extend()

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
	if x or y then
		local dx = x and x - self.centroid.x or 0 -- amount to translate in x if x specified
    	local dy = y and y - self.centroid.y or 0 -- amount to translate in y if y specified
		copy:translate(dx, dy)
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