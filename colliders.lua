local scandir 	= _Require_relative(..., 'fileloader')
local Collider  = _Require_relative(..., 'colliders.Collider')
-- Two kinds of shapes:
-- circles and polygons

local Colliders = {}

function Colliders:Create_Definition(name, object)
    --Check that the object implements new
    assert(object.new, "\tnew is null for shape: ".. name..'\n Make sure to :extend() it')
    self[name] = object
end

local function load_colliders(cwd)
    local shape_files = scandir('colliders')
    for _, filename in ipairs(shape_files) do
        local name = filename:sub(1,filename:len()-4)
        local c = _Require_relative(cwd, 'colliders.'..name)
        if type(c) == 'table' and c:implements(Collider) then
            -- Add to shapes
            Colliders:Create_Definition(name, c)
        else
            Colliders[name] = false
        end
    end
end

load_colliders(...)

-- Shapes: edge, aabb, ellipse, regular poly, convex poly, concave poly

return Colliders