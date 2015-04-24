local current_folder = (...):gsub('%.init$', '') .. "."
local cpml = require(current_folder .. "cpml")
local ffi = require "ffi"

local l3d = {}

-- from rxi/lume
local function iscallable(x)
	if type(x) == "function" then return true end
	local mt = getmetatable(x)
	return mt and mt.__call ~= nil
end

local function combine(...)
	local n = select('#', ...)
	if n == 0 then return noop end
	if n == 1 then
		local fn = select(1, ...)
		if not fn then return noop end
		assert(iscallable(fn), "expected a function or nil")
		return fn
	end
	local funcs = {}
	for i = 1, n do
		local fn = select(i, ...)
		if fn ~= nil then
			assert(iscallable(fn), "expected a function or nil")
			funcs[#funcs + 1] = fn
		end
	end
	return function(...)
		for _, f in ipairs(funcs) do f(...) end
	end
end

-- import all the GL function pointers (using SDL)
function l3d.import(use_monkeypatching)
	ffi.cdef([[void *SDL_GL_GetProcAddress(const char *proc);]])

	-- Windows needs to use an external SDL
	local sdl_on_windows_tho
	if love.system.getOS() == "Windows" then
		if love and love.system.getOS() == "Windows" and love.filesystem.isDirectory("bin") then
			sdl_on_windows_tho = ffi.load("bin/SDL2")
		else
			sdl_on_windows_tho = ffi.load("SDL2")
		end
	end

	-- Get handles for OpenGL
	local opengl = require(current_folder .. "opengl")
	opengl.loader = function(fn)
		local ptr
		if sdl_on_windows_tho then
			ptr = sdl_on_windows_tho.SDL_GL_GetProcAddress(fn)
		else
			ptr = ffi.C.SDL_GL_GetProcAddress(fn)
		end

		return ptr
	end
	opengl:import()

	l3d._state = {}
	l3d._state.stack = {}
	l3d.push("all")

	if use_monkeypatching then
		l3d.patch()
	end
end

-- clear color/depth buffers; must pass false (not nil!) to disable clearing.
-- defaults to depth only.
function l3d.clear(color, depth)
	local to_clear = 0
	if color then
		to_clear = bit.bor(to_clear, tonumber(GL.COLOR_BUFFER_BIT))
	end
	if depth or depth == nil then
		to_clear = bit.bor(to_clear, tonumber(GL.DEPTH_BUFFER_BIT))
	end
	gl.Clear(to_clear)
end

function l3d.reset()
	l3d.set_depth_test()
	l3d.set_culling()
	l3d.set_front_face()
	l3d.set_blending()
end

function l3d.set_blending(enabled)
	if enabled or enabled == nil then
		gl.Enable(GL.BLEND)
	else
		gl.Disable(GL.BLEND)
	end
end

function l3d.set_depth_test(method)
	if method then
		local methods = {
			greater = GL.GREATER,
			equal = GL.EQUAL,
			less = GL.LESS
		}
		assert(methods[method], "Invalid depth test method.")
		gl.Enable(GL.DEPTH_TEST)
		gl.DepthFunc(methods[method] or methods.less)
		gl.DepthRange(0, 1)
		gl.ClearDepth(1.0)
	else
		gl.Disable(GL.DEPTH_TEST)
	end
end

function l3d.set_front_face(facing)
	if not facing or facing == "ccw" then
		gl.FrontFace(GL.CCW)
		return
	elseif facing == "cw" then
		gl.FrontFace(GL.CW)
		return
	end

	error("Invalid face winding. Parameter must be one of: 'cw', 'ccw' or unspecified.")
end

function l3d.set_culling(method)
	if not method then
		gl.Disable(GL.CULL_FACE)
		return
	end

	gl.Enable(GL.CULL_FACE)

	if method == "back" then
		gl.CullFace(GL.BACK)
		return
	elseif method == "front" then
		gl.CullFace(GL.FRONT)
		return
	end

	error("Invalid culling method: Parameter must be one of: 'front', 'back' or unspecified")
end

function l3d.update_shader(shader)
	l3d._active_shader = shader
end

function l3d.push(which)
	local stack = l3d._state.stack
	assert(#stack < 64, "Stack overflow - your stack is too deep, did you forget to pop?")
	if #stack == 0 then
		table.insert(stack, {
			matrix = cpml.mat4(),
			active_shader = l3d._active_shader,
		})
	else
		-- storing the active shader is useful, but don't touch it!
		local top = stack[#stack]
		local new = {
			matrix = top.matrix:clone(),
			active_shader = top.active_shader,
		}
		if which == "all" then
			-- XXX: I hope this is what's expected.
			new.active_shader = top.active_shader
		end
		table.insert(stack, new)
	end
	l3d._state.stack_top = stack[#stack]
end

function l3d.pop()
	local stack = l3d._state.stack
	assert(#stack > 1, "Stack underflow - you've popped more than you pushed!")
	table.remove(stack)

	local top = stack[#stack]
	l3d._state.stack_top = top
end

function l3d.translate(x, y, z)
	local top = l3d._state.stack_top
	top.matrix = top.matrix:translate(cpml.vec3(x, y, z or 0))
end

function l3d.rotate(r, axis)
	assert(type(r) == "number")
	local top = l3d._state.stack_top
	top.matrix = top.matrix:rotate(r, axis or { 0, 0, 1 })
end

function l3d.scale(x, y, z)
	local top = l3d._state.stack_top
	top.matrix = top.matrix:scale(cpml.vec3(x, y, z or 1))
end

function l3d.origin()
	local top = l3d._state.stack_top
	top.matrix = top.matrix:identity()
end

function l3d.get_matrix()
	return l3d._state.stack_top.matrix
end

-- This isn't good practice (which is why you must explicitly call it), but
-- patching various love functions to maintain state here makes things a lot
-- more pleasant to use.
function l3d.patch()
	love.graphics.clearDepth   = function() l3d.clear() end
	love.graphics.setDepthTest = l3d.set_depth_test
	love.graphics.setCulling   = l3d.set_culling
	love.graphics.setFrontFace = l3d.set_front_face
	love.graphics.setBlending  = l3d.set_blending
	love.graphics.reset        = combine(l3d.reset, love.graphics.reset)

	love.graphics.origin       = combine(l3d.origin, love.graphics.origin)
	love.graphics.pop          = combine(l3d.pop, love.graphics.pop)
	love.graphics.push         = combine(l3d.push, love.graphics.push)
	love.graphics.rotate       = combine(l3d.rotate, love.graphics.rotate)
	love.graphics.scale        = combine(l3d.scale, love.graphics.scale)
	love.graphics.translate    = combine(l3d.translate, love.graphics.translate)
	love.graphics.getMatrix    = l3d.get_matrix

	love.graphics.setShader    = combine(l3d.update_shader, love.graphics.setShader)
end

return l3d
