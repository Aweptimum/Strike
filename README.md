# Strike
Strike (Separating-Axis Theorem Routines for Ill-tempered, Kaleidascopic Entities) is a 2D SAT Collision Detection library

## Shapes
Accessed via `S.hapes`, Shapes are objects representing convex geometry. Mostly polygons and circles. They are not used for collision detection by themselves, but are at your disposal. The available ones are in the `/shapes` directory, but you can add your own shape definitions as well. With the exception of `Circle`, every other shape is extended from `ConvexPolygon` and overrides its constructor. There are a few more requirements, but it's important to know that object definitions and instantiation are handled by rxi's [classic](https://github.com/rxi/classic). Its distinction is that the constructor definition,`:new`, is not supposed to return the object at the end itself. The object's `__call` method handles that.

An example of a shape structure
```lua
Rect = {
    vertices    = {},             -- list of {x,y} coords
    convex      = true,           -- boolean
    centroid    = {x = 0, y = 0}, -- {x, y} coordinate pair
    radius      = 0,              -- radius of circumscribed circle
    area        = 0               -- absolute/unsigned area of polygon
}
```
To actually create this, the ConvexPolygon definition can be extended and overriden with a new constructor.
```lua
local Polygon = require 'Strike.shapes.ConvexPolygon'

local Rect = Polygon:extend()

function Rect:new( x, y, dx, dy )
  -- Set attributes above in here
  ...
  self.area = dx * dy / 2
  ...
  -- Don't return self
end

-- Do return the object
return Rect
```

## Colliders
Accessed via `S.trikers`, Colliders are grab-bags of geometry that are used for collision detection. They can be composed of Shapes, but may also contain other Colliders (and their shapes). As with Shapes, the available ones are defined in the `/colliders` directory and auto-loaded in, and you can define custom collider definitions for particular collections of geometry that you're fond of. Just look at the included Capsule definition for an example.

## Collision
Calling `S:trike(collider1, collider2)` will check for collisions between the two given colliders and return a boolean (true/false) that signifies a collision, followed by a corresponding, second value (mtv/nil).

## MTV's
Minimum Translating Vectors are an object that represent the penetration depth between two colliders. The vector components are accessed via `mtv.x` and `mtv.y`, but they contain other information (similar to Box2D's manifolds). An example of the contained fields is below:
```lua
MTV = {
    x = 0,
    y = 0,
    collider = <reference-to-collider>,
    collided = <reference-to-collider>
}
```
The `collider` field represents the collider that the mtv is oriented *from*. If you were to draw the mtv from the centroid of the collider object, it would point out of the shape, towards the collider it is currently intersecting. The `collided` field is a reference to that intersected collider, the one that the mtv would be pointing *towards*. This information is necessary to know the orientation of the mtv and for settling/resolving collisions; they can directly be operated on from the references in the mtv.

# Contributing
Very little in this library was done in the best way from the start, and it's been extensively rewritten as its author learned more about best practices. Still, there's further work to be done. If a particular snippet makes you cringe, or there's a feature missing, feel free to fork, edit, test, and PR.

## TODO
- [ ] Add `:getEdge(index)` methods to shapes to return an edge by its number
- [ ] Return references to the two shapes that actually collided in the returned mtv, as well as the index of the normal's edge for the `collider_shape` field
- [ ] Add a function to solve for the edge(s) in `collided_shape` interesecting the normal's edge of the `collider_shape`
- [ ] Add contact solver (some kind of clipping function that can optionally be run given an mtv that returns 1-2 points)
