# Strike
Strike (Separating-Axis Theorem Routines for Ill-tempered, Kaleidascopic Entities) is a 2D SAT Collision Detection library.\
Made primarily for the [LÖVE](https://github.com/love2d/love) community, but should be compatible with any Lua version (at least at time of writing)

## Installation
Drop the folder into your project and require it:
```lua
local S = require 'Strike'
```

## Shapes
Accessed via `S.hapes`, Shapes are objects representing convex geometry, mostly polygons and circles. They are not used for collision detection by themselves, but are at your disposal. The available ones are in the `/shapes` directory, but you can add your own shape definitions as well. With the exception of `Circle`, every shape is extended from `ConvexPolygon` and overrides its constructor. There are a few more things to note, but it's important to know that both object definitions and instantiation are handled by rxi's [classic](https://github.com/rxi/classic). classic's distinction is that the constructor definition,`:new`, does not return the object itself. The object's `__call` method handles that, which is in turn handled by classic.

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
To actually define this, the `ConvexPolygon` definition can be extended and overriden with a new constructor. Example in [Defining Your Own Shapes](#defining-your-own-shapes)

See [Basic Colliders](#basic-colliders) down below for available Shapes.

Now for some Shape methods:
### Transforming Shapes
All of the below methods return `self` if you need to do some transformation chaining
```lua
shape:translate(dx, dy)		  -- adds dx and dy to each shapes' points
shape:translateTo(x,y)		  -- translates centroid to position (and everything with it)
shape:rotate(angle, refx, refy)	  -- rotates by `angle` (radians) about a reference point (defaults to centroid)
shape:rotateTo(angle, refx, refy) -- rotates the shape *to* an `angle` (radians) about a reference point (defaults to centroid)
shape:scale(sf, refx, refy)	  -- scales by factor `sf` with respect to a reference point (defaults to centroid)
```

### Querying Shapes
```lua
shape:getArea()		-- Returns the area of the shape
shape:getCentroid()	-- Returns the centroid of the shape as a table {x = x, y = y}
shape:getAreaCentroid()	-- Returns the area *and* the centroid of the shape
shape:getRadius()	-- Returns the radies of the shape's circumscribed circle
shape:getBbox()		-- Returns the minimum AABB dimensions of the shape as 4 numbers: minimum-x, minimum-y, width, height
shape:unpack()		-- Returns the args the shape was constructed with
```
#### More specific query methods:
```lua
shape:project(nx, ny)
```
Given two normalized vector components, returns the minimum and maximum values of the shape's projection onto the vector
```lua
shape:getEdge(i)
```
Given an index, returns the corresponding numbered edge. Returns `false` if OOB
```lua
shape:containsPoint(point)
```
Given a point ({x=x,y=y}), returns `true` if it is within bounds of the shape, else `false`
```lua
shape:rayIntersects(x,y, nx,ny)
```
Given a ray-origin `x,y` and a normalized vector, returns `true` if it intersects the shape, else `false`
```lua
shape:rayInteresections(x,y, nx,ny, ts)	-- Returns a table of numbers that are 
```
Same args as `rayIntersects` w/ optional table to insert into. Returns a list of numbers representing lengths along normal `nx, ny`

### Misc Shape Methods
There are a few more methods, specifically:
```lua
shape:copy(x,y, angle_rads) -- (returns a copy, go figure) w/ centroid located at `x, y` and the specified angle.
shape:ipairs( ?shape2 )	    -- Edge iterator. shape2 only necessary for Circles, which need another shape to get a useful edge
```
## Colliders
Accessed via `S.trikers`, Colliders are grab-bags of geometry that are used for collision detection. They can be composed of Shapes, but may also contain other Colliders (and their shapes). The only requirement is that *every shape* in the Collider is convex. As with Shapes, available Colliders are defined in the `/colliders` directory and auto-loaded in. You can define custom collider definitions for particular collections of geometry that you're fond of. Just look at the included `Capsule` definition for a simple example. The included collider objects are listed below.
### Basic Colliders
These correspond to the available `S.hapes`, but are not Shapes themselves. Their constructors are identical to the referenced shapes, and are automatically defined as `Collider(shape_name(shape_args))`. They are a Collider that contains a single shape of the same name.
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

### Composite Colliders
#### Collider
```lua
coll = S.trikers.Collider( S.hapes.Rectangle(...), S.hapes.Circle(...), S.trikers.Circle(...), ... )
```
Creates a collider object given a variadic amount of `S.hapes` or `S.trikers` that contains the specified geometry, though `S.hapes` make for a flatter object

#### Capsule
```lua
cap = S.trikers.Capsule(x_pos, y_pos, dx, dy, angle_rads)
```
Creates a capsule centered at `{x_pos, y_pos}` with width `dx` and height `dy`, offset by `angle_rads` (radians). Circles are along vertical axis.

#### Concave
```lua
concave = S.trikers.Concave(x,y, ...)
```
Takes a vardiadic list of `x,y` pairs that describe a concave polygon.
Should be in pseudo-counter-clockwise winding order. 

### Transforming Colliders
The base Collider class (and all colliders that extend it) have the below methods
All of them return `self` if you need to do some transformation chaining

```lua
collider:translate(dx, dy)		-- adds dx and dy to each shapes' points
collider:translateTo(x,y)		-- translates centroid to position (and everything with it)
collider:rotate(angle, refx, refy)	-- rotates by `angle` (radians) about a reference point (defaults to centroid)
collider:rotateTo(angle, refx, refy)	-- rotates the shape *to* an `angle` (radians) about a reference point (defaults to centroid)
collider:scale(sf, refx, refy)		-- scales by factor `sf` with respect to a reference point (defaults to centroid)
```
### Querying Colliders
```lua
collider:getArea()		-- Returns the area of the collider
collider:getCentroid()		-- Returns the centroid of the collider as a table {x = x, y = y}
collider:getAreaCentroid()	-- Returns the area *and* the centroid of the collider
collider:getRadius()		-- Returns the radies of the collider's circumscribed circle
collider:getBbox()		-- Returns the minimum AABB dimensions of the collider as 4 numbers: minimum-x, minimum-y, width, height
collider:unpack()		-- Returns the the shapes a collider contains
```
#### More specific query methods:
```lua
collider:project(nx, ny)
```
Given two normalized vector components, returns the minimum and maximum values of the collider's projection onto the vector.
Not super useful for concave colliders, but it's there.

Of course, there's also ray-methods, but they're expounded upon in [Ray Intersection](#ray-intersection)

### Manipulating Colliders
Other useful methods include:
```lua
collider:copy() 		-- returns a copy of the collider
collider:remove(index, ...) 	-- removes a shape at the specified index, can handle multiple indexes
	**uses table.remove internally, so as long as you don't have tens of thousands of shapes in a collider, you'll be fine! 
collider:consolidate() 		-- will merge incident convex polygons together, makes for less iterations if applicable
```

### Collider Iterating
```lua
for parent_collider, shape, shape_index in collider:ipairs() do
	-- stuff
end
```
`Collider:ipairs()` is a flattened-list iterator that will return *all* Shapes, nested or not, contained within the 'root' Collider it's called from.
`parent_collider` is the collider that contains `shape`, and `shape_index` is the index of `shape` within `parent_collider.shapes`.\
If you wanted to remove a shape from a Collider that met some condition, calling `parent_collider:remove( shape_index )` would do it.

## Ray Intersection
There are two ray intersection functions: `rayIntersects` and `rayIntersections`. Both have the same arguments: a ray origin and a normalized vector. The current implementation also assumes infinite length. They are defined both at the `Shapes` level and at the `Collider` level.
```lua
Collider:rayIntersect(ion)s(x,y, dx,dy)
```
`Intersects` earlies out at the first intersection and returns true (else false).

`Intersections` returns a list of key-value pairs, where the keys are references to the shape objects hit and the values are a table of lengths along the ray vector. 
It looks like this:
```lua
hits = Collider:rayIntersections(0,0, 1,1)
-- hits = {
--	<shape1> = {length-1, length-2},
--	<shape2> = {length-1},
--	<shape3> = {length-1, length-2}
--	}
```
Because the keys are references, it is possible to iterate through the `hits` table using `pairs()` and operate on them individually.

To compute the intersection points, here's a sample loop:
```lua
for shape, dists in pairs(hits) do
	for _, dist in ipairs(dists) do
		local px, py = rx + dx*dist, ry + dy*dist -- coordinate math
		love.graphics.points(px, py) -- draw with love
	end
end
```
## MTV's
Minimum Translating Vectors are an object that represent the penetration depth between two colliders. It sits under the `classes/` directory if you wish to use it. Here's the cosntructor:
```lua
MTV(dx, dy, collider, collided)
```
Where `dx,dy` are the vector components and `collider/collided` are each a Collider.
There are other fields that are not currently set from the constructor. An example of the contained fields is below:
```lua
MTV = {
    x = 0,
    y = 0,
    collider = <reference-to-collider>,
    collided = <reference-to-collider>,
    colliderShape = <reference-to-collider-shape>,
    collidedShape = <reference-to-collided-shape>,
    edgeIndex = colliderShape-edge-index
}
```
The vector components are accessed via `mtv.x` and `mtv.y`. The `collider` field represents the collider that the mtv is oriented *from*. If you were to draw the mtv from the centroid of the collider object, it would point out of the shape, towards the collider it is currently intersecting. The `collided` field is a reference to that intersected collider, the one that the mtv would be pointing *towards*. This information is necessary to know the orientation of the mtv and for settling/resolving collisions; they can directly be operated on from the references in the mtv.

The `colliderShape` and `collidedShape` fields are references to the two actual shapes that generated the collision. `edgeIndex` is the actual index of the edge that generated the separating axis. The edge can be retrieved by calling `mtv.colliderShape:getEdge( mtv.edgeIndex )`.

The plan is to add a solver that can calculate the contact points between the two colliders given the information inside of a MTV alone. Similar to Box2D's manifolds.
(very unsure of how to go about this, will need to play with clipping algorithms).

The MTV object has a camelCased setter for every single field (`setCollider` for `collider`). It's unlikely anyone will need to use them, but here they are:
```lua
MTV:setCollider(collider)

MTV:setColliderShape(shape)

MTV:setEdgeIndex(index)

MTV:setCollided(collider)

MTV:setCollidedShape(shape)
```
The one practical instance method of interest might be `MTV:mag()` - it returns the magnitude of the separating vector.

### Object Pooling
The `MTV` object implements the `Pool` interface in `classes/Pool.lua`. The following instance methods can be used to interact with the pool:
```lua
MTV:fetch(dx, dy, collider, collided)
MTV:stow()
```
`fetch()` sets a previously initialized MTV to the given arguments and returns it from the pool. Its arguments are identical to the `MTV()` constructor as it uses `:new` to init the object
`stow()` inserts the MTV instance into the object pool
There is a default limit of 128 for any pool. The MTV pool size can be changed using Strike's `S.etPoolSize(size)` method or requiring the `MTV` object and calling `:setPoolSize(size)`. Multiples of 2 are best because of lua-hash-table-resizing-stuff. The size can be acquired via `S.eePoolSize()/MTV:getPoolSize()` (yes, I am aware that these API function names are suffering from the `S.` gimmick)

### Implementing Pooling
If you're ok with embracing `classic` in your own project and want to pool an ubiquitous object in your code, it's easy:
```lua
Object = Libs.classic
Pool = require 'module-path.Strike.classes.Pool`

local myObject = Object:extend():implement(Pool)
```
Your `myObject` object now has access to these methods and fields:
```lua
Pool.pool               -- Class's object pool
Pool.size               -- Pool size limit
Pool:getPoolSize()      -- Get the size of the object pool
Pool:setPoolSize(size)  -- Set size of object pool (returns self)
Pool:fetch( ... )       -- Fetch a pooled instance and init to given args (should match class constructor)
Pool:stow( obj, ... )   -- Stow variable # of instances in Class pool
```

## Collision
### Broad Phase
Has both circle-circle and aabb-aabb intersection test functions - `S.ircle(collider1, collider2)` and `S.aabb(collider1, collider2)` respectively. Both return true on interesction, else false.
### Narrow Phase (SAT)
Calling `S:trike(collider1, collider2)` will check for collisions between the two given colliders and return a boolean (true/false) that signifies a collision, followed by a corresponding, second value (MTV/nil).

It's important to note that geometries within a Collider do not collide with each other. This is relevant for how Strike unintentionally gets around [Ghost Collisions](#ghosting)
## Resolution
Calling `S.ettle(mtv)` will move the referenced colliders by half the magnitude of the mtv in opposite directions to one another.

## In Love?
If you're running within [LÖVE](https://github.com/love2d/love), every included shape has an appropriate `:draw` function defined. Calling `collider:draw` will draw every single shape and collider contained.

# Bit more in depth

## Ghosting
Erin Catto wrote up a nice article on the subject of [ghost collisions](https://box2d.org/posts/2020/06/ghost-collisions/). The problem outlined is this: if two colliders intersect, and a third collider hits both at their intersection, not-nice things can happen. Strike has this problem as well. Box2D solves it with chain shapes, which store edges together and modify the collision logic to avoid bad resolution. Strike doesn't directly solve this. However, in the case of two edges intersecting at a common endpoint and a shape hitting that intersection, it seems to be circumvented by adding both edge colliders to a common collider. A minimum example is below:
```lua
local edges = {
	S.hapes.Edge(400,600, 600,600),
	S.hapes.Edge(600,600, 800,600)
}
-- vs
local EDGE = S.trikers.Collider(
	S.hapes.Edge(400,600, 600,600),
	S.hapes.Edge(600,600, 800,600)
)
```
The first will produce ghosting, while the second does not. This is either because of extreme luck during testing or built into the collision detection logic on accident. Either way, it's a feature.

To make this explicit, a check for whether the MTV is headed *into* a Collider's centroid should probably be added somewhere in the logic for `S.triking`.

## Defining Your Own Shapes
You can create shape definitions in the `/shapes` directory of Strike that will be loaded into `S.hapes`. There are a few rules to follow:
1. The shape must be convex
2. At least define `:new` and `:unpack`
3. *All* necessary properties need to be initialized inside `:new`. If not, you'll get weird behavior as instantiated shapes will populate the object's attributes (I know from experience)

And you should generally be fine.

Let's use the example of the rectangle structure in the [Shapes](#shapes) section. We'll define a Rectangle object that can be used with Strike. There are a lot of methods that each shape needs to have, but the base ConvexPolygon object takes care of most of that. Generally, all you need to define is a constructor (`:new`) and "deconstructor" (`:unpack`).

Let's say we create an imaginary file called `Rectangle.lua`.

First, let's require Vector-light and ConvexPolygon so we can do some math and override the parent's behavior.
(Vector-light is currently accessed through DeWallua, the triangulation library)
```lua
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light',1) -- yes, this is pretty horrible
local Polygon = _Require_relative(..., 'ConvexPolygon')

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
Just like Shapes, you can make your own ready-to-go Collider definitions. These follow the same rules as Shapes, with the exception of `:unpack` being unnecessary. You should, however, always call `self:calcAreaCentroid` and `self:calcRadius` at the end of your constructor.

Let's make a Capsule!

Well, a Capsule is basically a Rectangle with two Circles on either end, so let's start there. We'll require the base `Collider`, the `Circle`, and the `Rectangle` objects:
```lua
local Collider	= _Require_relative(..., 'Collider')
local Circle	= _Require_relative(..., 'shapes.Circle', 1)
local Rectangle	= _Require_relative(..., 'shapes.Rectangle', 1)

local Capsule = Collider:extend()
```

For our constructor, we'll have an x-y position that will be the center, a width, a height, and an angle-offset. Let's put the circles on top and bottom. This means their radii is equal to half the width of the `Capsule`. Let's say that the height encompasses both circles and the rectangle, so the Rectangle's height = `height - 2*circle-radius`. Lastly, the `Circle`s will be positioned on the top and bottom edge of the `Rectangle`, so we can just add/subtract half the height accordingle. 
Now, we have enough information to create our `Capsule` constructor:
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
    self:calcAreaCentroid()
    self:calcRadius()
    self:rotate(self.angle)
end
```
All that's left is to return it
```lua
return Capsule
```
And that's it! 

Because the Collider object assumes it only contains convex shapes and other colliders, you have a lot of flexibility in what you can construct.

# Thanks
I'd like to thank Max Cahill, MikuAuahDark, Potatonomicon, and radgeRayden for helping (knowingly or not) with some details :)

# Contributing
Very little in this library was done in the best way from the start, and it's been extensively rewritten as its author learned more about best practices. Still, there's further work to be done (the require structure is particularly bad). If a snippet makes you cringe, or there's a feature missing, feel free to fork, edit, test, and PR.

## Out-Of-Scope Features
* **Bit-Masking/Layering**\
	I want to add it, but this is where Lua falls down a bit. Between Lua 5.1/5.2, LuaJIT, and Lua 5.3+, there's too much compatibility to consider.\
	Best left to the user to implement it
* **Broad-Phase Data Structures**\
	There's more than one way to do it ¯\\\_(ツ)\_/¯\
	Strike's geometry objects are really just factories - pipe their output into your structure of choice.
* **Continuous Collision Detection**\
	For good CCD, it's best to handle it in a physics implementation that would wrap around Strike. Mostly because having access to velocity and rotation vectors allows
	for interpolationg between timesteps. Right now, `dt` is absent from this library.

## TODO
- [X] Add `:getEdge(index)` methods to shapes to return an edge by its number
- [X] Return references to the two shapes that actually collided in the returned mtv, as well as the index of the normal's edge for the `collider_shape` field
- [X] Add MTV pool to generate less garbage
- [ ] Add a function to solve for the edge(s) in `collided_shape` interesecting the normal's edge of the `collider_shape`
- [ ] Add contact solver (some kind of clipping function that can optionally be run given an mtv that returns 1-2 points)
