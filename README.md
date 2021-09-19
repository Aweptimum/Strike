# Strike
Strike (Separating-Axis Theorem Routines for Ill-tempered, Kaleidascopic Entities) is a 2D SAT Collision Detection library

## Shapes
Accessed via `S.hapes`, Shapes are objects representing convex geometry. Mostly polygons and circles. They are not used for collision detection by themselves, but are at your disposal. The available ones are in the `/shapes` directory, but you can add your own shape definitions as well. With the exception of `Circle`, every other shape is extended from `ConvexPolygon` and overrides its constructor. There are a few more requirements, but it's important to know that object definitions and instantiation are handled by rxi's [classic](https://github.com/rxi/classic). classic's distinction is that the constructor definition,`:new`, is not supposed to return the object at the end itself. The object's `__call` method handles that.

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
To actually create this, the ConvexPolygon definition can be extended and overriden with a new constructor. Example in [Defining Your Own Shapes](#defining-your-own-shapes)

## Colliders
Accessed via `S.trikers`, Colliders are grab-bags of geometry that are used for collision detection. They can be composed of Shapes, but may also contain other Colliders (and their shapes). The only requirement is that *every shape* in the Collider is convex. As with Shapes, the available ones are defined in the `/colliders` directory and auto-loaded in, and you can define custom collider definitions for particular collections of geometry that you're fond of. Just look at the included Capsule definition for an example. The included colliders are listed below. They are simply defined as `Collider(shape_name(shape_args))`, and so the basic colliders are not directly shapes.
### Basic Colliders
#### Circle
```lua
c = S.trikers.Circle(x_pos, y_pos, radius, angle_rads)
```
Creates a circle centered on `{x_pos, y_pos}` with the given `radius`. `angle_rads` not really useful at the moment, might delete it.

#### ConvexPolygon
```lua
cp = S.trikers.ConvexPolygon(x,y, ...)
```
Takes a vardiadic list of `x,y` pairs that describe a convex polygon.
Should be in counter-clockwise winding order, but the constructor will automatically sort non-ccw input when it fails a convexity check.

#### Edge
```lua
e = S.trikers.Edge(x1,y1, x2,y2)
```
Takes the two endpoints of an edge and... creates an edge

#### Ellipse
```lua
el = S.trikers.Ellipse(x_pos, y_pos, a, b, segments, angle_rads)
```
Creates a **discretized** Ellipse centered at `{x_pos, y_pos}`, `a` and `b` are lengths of major/minor axes, segments is the number of edges to use to approximate the Ellipse, and `angle_rads` is the angled offset in radians.

#### Rectangle
```lua
S.trikers.Rectangle(x_pos, y_pos, dx, dy, angle_rads)
```
Creates a rectangle centered at `{x_pos, y_pos}` with width `dx` and height `dy`, offset by `angle_rads` (radians).

#### RegularPolygon
```lua
r = S.trikers.RegularPolygon(x_pos, y_pos, n, radius, angle_rads)
```
Creates a regular polygon centered at `{x_pos, y_pos}` with `n` sides. `radius` is the radius of the circumscribed circle, `angle_rads` is the angled offset in radians.

### Special Colliders
#### Capsule
```lua
cap = S.trikers.Capsule(x_pos, y_pos, dx, dy, angle_rads)
```
Creates a capsule centered at `{x_pos, y_pos}` with width `dx` and height `dy`, offset by `angle_rads` (radians). Circles are along vertical axis.

#### Concave
```lua
concave = S.trikers.Concave(x,y, ...)
```
Takes a vardiadic list of `x,y` pairs that describe a convex polygon.
Should be in pseudo-counter-clockwise winding order. 

### Moving Colliders
The base Collider class (and all colliders that extend it) have these methods:

```lua
collider:translate(dx, dy) -- adds dx and dy to each shapes' points
collider:translate_to(x,y) -- translates centroid to position (and everything with it)
collider:rotate(angle, ref_x, ref_y) -- rotates by `angle` (radians) about a reference point (defaults to centroid)
collider:scale(sf, ref_x, ref_y) -- scales by factor `sf` with respect to a reference point (defaults to centroid)
```

### Manipulating Colliders
Other useful methods include:
```lua
collider:copy() -- returns a copy of the collider
collider:remove(index, ...) -- removes a shape at the specified index, can handle multiple indexes
	**uses table.remove internally, so as long as you don't have tens of thousands of shapes in a collider, you'll be fine! 
collider:consolidate() -- will merge incident convex polygons together, makes for less iterations if applicable
```

## MTV's
Minimum Translating Vectors are an object that represent the penetration depth between two colliders. The vector components are accessed via `mtv.x` and `mtv.y`, but they contain other information. An example of the contained fields is below:
```lua
MTV = {
    x = 0,
    y = 0,
    collider = <reference-to-collider>,
    collided = <reference-to-collider>
}
```
The `collider` field represents the collider that the mtv is oriented *from*. If you were to draw the mtv from the centroid of the collider object, it would point out of the shape, towards the collider it is currently intersecting. The `collided` field is a reference to that intersected collider, the one that the mtv would be pointing *towards*. This information is necessary to know the orientation of the mtv and for settling/resolving collisions; they can directly be operated on from the references in the mtv.

The plan is to add references to the two shapes that generated the collision and *maybe* the contact points between the two colliders (very unsure of how to go about that, will need to play with clipping algorithms)

## Collision
Calling `S:trike(collider1, collider2)` will check for collisions between the two given colliders and return a boolean (true/false) that signifies a collision, followed by a corresponding, second value (MTV/nil).

## Resolution
Calling `S.ettle(mtv)` will move the refrenced colliders by half the magnitude of the mtv in opposite directions to one another.

## In love?
If you're running within LÖVE, every included shape has an appropriate `:draw` function defined. Calling `collider:draw` will draw every single shape and collider contained.

# Bit more in depth

## Defining Your Own Shapes
You can create shape definitions in the /shapes directory of Strike that will be loaded into `S.hapes`. There are a few rules to follow:
1. The shape must be convex
2. At least define `:new` and `:unpack`
3. *All* necessary properties need to be initialized inside `:new`. If not, you'll get weird behavior as instantiated shapes will populate the object's attributes (I know from experience)

And you should generally be fine.

Let's use the example of the rectangle structure in the [Shapes](#shapes) section. We'll define a Rectangle object that can be used with Strike. There are a lot of methods that each shape needs to have, but the base ConvexPolygon object takes care of most of that. Generally, all you need to define is a constructor (`:new`) and "deconstructor" (`:unpack`).

Let's say we create an imaginary file called `Rectangle.lua`.

First, let's require Vector-light and ConvexPolygon so we can do some math and override the parent's behavior.
(Vector-light is currently accessed through DeWallua, the triangulation library)
```lua
local Vec = require "Strike.lib.DeWallua.vector-light"
local Polygon = require 'Strike.shapes.ConvexPolygon'

local Rect = Polygon:extend()
```
Then, we define a constructor:
```lua
function Rect:new((x_pos, y_pos, dx, dy, angle_rads)
    if not ( dx and dy ) then return false end
    local x_offset, y_offset = x_pos or 0, y_pos or 0
    self.dx, self.dy = dx, dy
    self.angle = angle_rads or 0
    local hx, hy = dx/2, dy/2 -- halfsize
    self.vertices = {
		{x = x_offset - hx, y = y_offset - hy},
		{x = x_offset + hx, y = y_offset - hy},
		{x = x_offset + hx, y = y_offset + hy},
		{x = x_offset - hx, y = y_offset + hy}
	}
    self.centroid   = {x = x_offset, y = y_offset}
    self.area       = dx*dy
    self.radius     = Vec.len(hx, hy)
    self:rotate(self.angle)
end
```
I know it looks a bit dense, but the important takeaway is that we are initializing all the same properties of ConvexPolygon, just in a different way.
You might notice that the attributes in the constructor that are no longer needed are actually stored (dx, dy). This is so that we can unpack those values if need-be, such as copying arguments into a constructor call. For that, we define `unpack`:
```lua
function Rect:unpack()
	return self.centroid.x, self.centroid.y, self.dx, self.dy, self.angle
end
```
And the last thing we need to do is return our object for when it's required by Strike:
```
return Rect
```

If you crack open Rectangle.lua, this is actually the entire file! Hopefully this is enough to get you started if you're in need of trapezoids, parallelograms, or anything else!

One last thing to touch on (and you may have wondered this already) - do I use this by calling `S.hapes.Rect` or `S.hapes.Rectangle`? The answer is that Strike stores each shape using the filename, so `S.hapes.Rectangle` it is.

## Defining Your Own Colliders
Just like Shapes, you can make your own ready-to-go Collider definitions. These follow the same rules as Shapes, with the exception of `:unpack` being unnecessary. You should, however, always call `self:calc_area_centroid` and `self:calc_radius` at the end of your constructor.

Let's make a Capsule!

Well, a Capsule is basically a Rectangle with two Circles on either end, so let's start there. We'll require the base `Collider`, the `Circle`, and the `Rectangle` objects:
```lua
local Collider  = require 'Strike.colliders.Collider'
local Circle    = require 'Strike.shapes.Circle'
local Rectangle = require 'Strike.shapes.Rectangle'

local Capsule = Collider:extend()
```

For our constructor, we'll have an x-y position that will be the center, a width, a height, and an angle-offset. Let's put the circles on top and bottom. This means their radii is equal to half the width of the `Capsule`. Let's say that the height encompasses both circles and the rectangle, so the Rectangle's height = `height - 2*circle-radius`. Lastly, the `Circle`s will be positioned on the top and bottom edge of the `Rectangle`, so we can just add/subtract half the height accordingle. 
Now, we have enough information to create our `Capusule` constructor:
```lua
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
    self:calc_area_centroid()
    self:calc_radius()
    self:rotate(self.angle)
end
```
All that's left is to return it
```lua
return Capsule
```
And that's it! 

Because the Collider object assumes it only contains convex shapes and other colliders, you have a lot of flexibility in what you can construct.

# Contributing
Very little in this library was done in the best way from the start, and it's been extensively rewritten as its author learned more about best practices. Still, there's further work to be done. If a particular snippet makes you cringe, or there's a feature missing, feel free to fork, edit, test, and PR.

## TODO
- [ ] Add `:getEdge(index)` methods to shapes to return an edge by its number
- [ ] Return references to the two shapes that actually collided in the returned mtv, as well as the index of the normal's edge for the `collider_shape` field
- [ ] Add a function to solve for the edge(s) in `collided_shape` interesecting the normal's edge of the `collider_shape`
- [ ] Add contact solver (some kind of clipping function that can optionally be run given an mtv that returns 1-2 points)
