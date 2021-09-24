local Collider  = require 'Strike.colliders.Collider'
local Circle    = require 'Strike.shapes.Circle'
local Rectangle = require 'Strike.shapes.Rectangle'

local Capsule = Collider:extend()

-- A Capsule is a rectangle + 2 circles
function Capsule:new(x, y, dx, dy, angle_rads)
    self.shapes = {}
    self.centroid = {x=0,y=0}
    self.radius = 0
    self.angle = angle_rads or 0
    local hx, hy = dx/2, dy/2
    self:add(
        Circle(x, y-hy, hx),
        Circle(x, y+hy, hx),
        Rectangle(x,y,dx,dy)
    )
    self:calcAreaCentroid()
    self:calcRadius()
    self:rotate(self.angle)
end

return Capsule