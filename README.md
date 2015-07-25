# LÖVE3D

Extensions to the LÖVE API for 3D rendering - depth testing, depth buffers on canvases, etc. Works on desktop OpenGL and OpenGL ES (tested on Raspberry Pi, should work for Android with some tweaking).

Two ways to use the API are provided. You can either use it as a regular module or tell it to inject itself into love.graphics using `l3d.import(true)`. The latter is more user-friendly, but must be more carefully maintained with love versions (on our end).

While this can be used to make fully 3D games (and, in fact, we have), it's most reasonable to use it to lift art restrictions so you can make 2.5D games (or put 3D elements in otherwise 2D games). This is not intended to compete with the likes of any big 3D engine like Unreal Engine or Unity.

Depends on LÖVE 0.10 and [CPML](https://github.com/excessive/cpml)

You can load models using [IQM](https://github.com/excessive/iqm).

## Usage
```lua
require("love3d").import(true)

function love.load()
  -- we do not yet include a model loader or a shader, sorry!
  some_model = up_to_you()
  some_shader = up_to_you()
end

function love.draw()
  -- setup...
  love.graphics.setDepthTest("less")
  love.graphics.setShader(some_shader)

  -- ...move into place...
  love.graphics.translate(0, 10, 0)
  love.graphics.scale(5, 5, 5)

  -- ...and draw!
  love.graphics.draw(some_model)

  -- reset
  love.graphics.setShader()
  love.graphics.setDepthTest()

  -- now it's safe to draw 2D again.
  love.graphics.print(string.format("FPS: %0.2f (%0.4f)", love.timer.getFPS(), love.timer.getAverageDelta()))
end
```

## Todo
* Include a useful default shader
* Automatically update shader uniforms when doing transformations
* Implement love.graphics.shear, so that our matrix state won't desync if it is used.
* Add debug functionality:
  * Bounding boxes
  * Rays
  * OVR performance/latency hud
* Add real support for OVR layers.
