# LÖVE3D

Extensions to the LÖVE API for 3D rendering - depth testing, depth buffers on canvases, etc. Works on desktop OpenGL and OpenGL ES (tested on Raspberry Pi, should work for Android with some tweaking).

Two ways to use the API are provided. You can either use it as a regular module or tell it to inject itself into love.graphics using `l3d.import(true)`. The latter is more user-friendly, but must be more carefully maintained with love versions (on our end).

While this can be used to make fully 3D games (and, in fact, we have), it's most reasonable to use it to lift art restrictions so you can make 2.5D games (or put 3D elements in otherwise 2D games). This is not intended to compete with the likes of any big 3D engine like Unreal Engine or Unity.

Depends on LÖVE 0.10 and [CPML](https://github.com/excessive/cpml)

You can load models using [IQM](https://github.com/excessive/iqm).

Online documentation can be found [here](http://excessive.github.io/love3d/) or you can generate them yourself using `ldoc -c doc/config.ld -o index .`

## Usage

Examples can be found here: https://github.com/excessive/love3d-demos

## TODO
* ~Convince slime to add depth support to love.~ Depth canvases will be supported in love 0.11, and this will get a lot smaller.
