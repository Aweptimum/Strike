# Strike
Strike (Separating-Axis Theorem Routines for Ill-tempered, Kaleidascopic Entities) is a 2D SAT Collision Detection library

## Shapes
Accessed via `S.hapes`, Shapes are objects representing convex geometry. Mostly polygons and circles. They are not used for collision detection by themselves, but are at your disposal. The available ones are in the `/shapes` directory, but you can add your own shape definitions as well. With the exception of `Circle`, every other shape is extended from `ConvexPolygon` and overrides its constructor. There are a few more requirements.

## Colliders
Accessed via `S.trikers`, Colliders are grab-bags of geometry and what are used for collision detection. They can be composed of Shapes, but may also contain other Colliders (and their shapes). As with Shapes, the available ones are defined in the `/colliders` directory and auto-loaded in, and you can define your collider definitions for particular collections of geometry that you're fond of.

## The Hash

## Collision
Calling `S:trike()` will check for collisions

# Contributing
Very little in this library was done in the best way from the start, and it's been extensively rewritten as its author learned more about best practices. Still, there's further work to be done. If a particular snippet makes you cringe, or there's a feature missing, feel free to fork, edit, verify, and PR. 
