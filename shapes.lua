local scandir 	= _Require_relative(..., 'fileloader')
local Shape     = require 'Slap.shapes.Shape'
-- Two kinds of shapes:
-- circles and polygons

local Shapes = {}

function Shapes:Create_Definition(name, object)
    print('Creating definition for:' .. name)
    --Check that the object implements new
    assert(object.new, "\tnew is null for shape: ".. name..'\n Make sure to :extend() it')
    -- Add "private" _copy method for each object
    function object:_copy()
        print('self is:'..self.name)
        return object(self:unpack())
    end
    self[name] = object
end

local function load_shapes(cwd)
    local shape_files = scandir('shapes')
    tprint(shape_files)
    for _, filename in ipairs(shape_files) do
        local name = filename:sub(1,filename:len()-4)
        local s = _Require_relative(cwd, 'shapes.'..name)
        if type(s) == 'table' and s:implements(Shape) then
            -- Add to shapes
            Shapes:Create_Definition(name, s)
        else
            Shapes[name] = false
        end
    end
end

load_shapes(...)

-- Shapes: edge, aabb, ellipse, regular poly, convex poly, concave poly

return Shapes