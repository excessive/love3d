# LÖVE3D Roadmap

## VENI ☆ VIDI ☆ VICI

### Next

* Reimplement the things we killed when rewriting the networking
* Separate spawn points for players
* Make server terrain-aware


### Later

* Culling (skip drawing for chunks and objects that are not visible)
* Improve IRC Chat
* Teams
* in game hud
* Mouse control
* Fix terrain normals
* Fix shading
* Add light objects
* Shadows
* Single Player Mode (if server not available)
* Minimap
* Preferences system (just some json, really)
* Controller keyboards
	* T9
	* qwerty
	* flower
* Improve assets


### Eventually

* Accel / Decel
* Physically Based Rendering
* IQM support (now that we can read structs nicely!)
* Physics
	* Maybe we should look into Bullet
* PSO2 chat
	* what parts, specifically?
* Terrain generator needs some life
	* City generator!
	* Grass
	* Fauna
		* Fuck yeah, wild animal NPCs!
	* Floura
* NPCs
* Improve map loader
* Bounding Box Collision
	* Ray-Triangle (the first triangle is just 3 rays!)
* Quadtrees
* Octrees
* Terrain LOD
* Camera types
	* Rigid
	* Mouse
	* Free
	* Cinematic
* Two-bone IK
* Clamp nameplates to viewport
* Improve Character / Complex Model Support
* Area of Influence
	* Chat
	* Fog of War
	* Collision Detection


### ¡WE DID IT!

1. Bounding boxes (iqe)
1. Save name between sessions
1. Shooting
1. Fix name tags for off screen players
1. Collision (Circle-Circle)
1. IRC Chat
1. Share code between client and server
1. Gamepad support
1. Bone Interpolation
1. Rewrite server system
	1. map out packets
	1. implement a way to send/receive them
	1. actually make the game use that shit
