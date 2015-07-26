local current_folder = (...):gsub('%.init$', '') .. "."
local cpml = require "cpml"
local ffi = require "ffi"

local use_gles = false

local l3d = {
	_LICENSE = "Love3D is distributed under the terms of the MIT license. See LICENSE.md.",
	_URL = "https://github.com/excessive/love3d",
	_VERSION = "0.0.1",
	_DESCRIPTION = "A 3D extension for LÖVE."
}

-- hang onto the original in case we patch over it, we need it!
local new_canvas = love.graphics.newCanvas

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
	local opengl
	if select(1, love.graphics.getRendererInfo()) == "OpenGL ES" then
		use_gles = true
		opengl = require(current_folder .. "opengles2")
	else
		opengl = require(current_folder .. "opengl")
	end
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

-- FXAA helpers
function l3d.get_fxaa_alpha(color)
	local c_vec = cpml.vec3.isvector(color) and color or cpml.vec3(color)
	return c_vec:dot(cpml.vec3(0.299, 0.587, 0.114))
end

function l3d.set_fxaa_background(color)
	local c_vec = cpml.vec3.isvector(color) and color or cpml.vec3(color)
	love.graphics.setBackgroundColor(c_vec.x, c_vec.y, c_vec.z, l3d.get_fxaa_alpha(c_vec))
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
		if use_gles then
			gl.DepthRangef(0, 1)
			gl.ClearDepthf(1.0)
		else
			gl.DepthRange(0, 1)
			gl.ClearDepth(1.0)
		end
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

-- Create a buffer from a list of vertices (just vec3's)
-- Offset will offset every vertex by the specified amount, useful for preventing z-fighting.
-- Optional mesh argument will update the mesh instead of creating a new one.
-- Specify usage as "dynamic" if you intend to update it frequently.
function l3d.new_triangles(t, offset, mesh, usage)
	offset = offset or cpml.vec3(0, 0, 0)
	local data, indices = {}, {}
	for k, v in ipairs(t) do
		local current = {}
		table.insert(current, v.x + offset.x)
		table.insert(current, v.y + offset.y)
		table.insert(current, v.z + offset.z)
		table.insert(data, current)
		if not mesh then
			table.insert(indices, k)
		end
	end

	if not mesh then
		local layout = {
			{ "VertexPosition", "float", 3 }
		}

		local m = love.graphics.newMesh(layout, data, "triangles", usage or "static")
		m:setVertexMap(indices)
		return m
	else
		if mesh.setVertices then
			mesh:setVertices(data)
		end
		return mesh
	end
end

-- TODO: Test this to make sure things are properly freed.
function l3d.new_canvas(width, height, format, msaa, gen_depth)
	local w, h = width or love.graphics.getWidth(), height or love.graphics.getHeight()
	local canvas = new_canvas(w, h, format, msaa)
	if gen_depth and canvas then
		love.graphics.setCanvas(canvas)

		local depth = ffi.new("unsigned int[1]", 1)
		gl.GenRenderbuffers(1, depth);
		gl.BindRenderbuffer(GL.RENDERBUFFER, depth[0]);
		if msaa > 1 then
			gl.RenderbufferStorageMultisample(GL.RENDERBUFFER, msaa, GL.DEPTH_COMPONENT24, w, h)
		else
			gl.RenderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT24, w, h)
		end
		gl.FramebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, depth[0])
		l3d.clear()
		-- if msaa > 1 then
		-- 	console.i(string.format("Created canvas with FSAA: %d", msaa))
		-- else
		-- 	console.i(string.format("Created canvas without FSAA.", msaa))
		-- end
		local status = gl.CheckFramebufferStatus(GL.FRAMEBUFFER)
		if status ~= GL.FRAMEBUFFER_COMPLETE then
			console.e("Framebuffer is borked :(")
		end
		love.graphics.setCanvas()
	end

	return canvas
end

--[[
-- depth-only canvas!
local function l3d.new_depth_canvas(w, h)
	local fbo = ffi.new("unsigned int[1]", 1)
	gl.GenFramebuffers(1, fbo)
	gl.BindFramebuffer(GL.FRAMEBUFFER, fbo[0])

	local depth = ffi.new("unsigned int[1]", 1)
	gl.GenTextures(1, depth)
	gl.BindTexture(GL.TEXTURE_2D, depth[0])
	gl.TexImage2D(GL.TEXTURE_2D, 0, GL.DEPTH_COMPONENT24, w, h, 0, GL.DEPTH_COMPONENT, GL.FLOAT, 0)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)

	gl.FramebufferTexture(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, depth, 0)

	gl.DrawBuffer(GL.NONE) -- No color buffer is drawn to.

	if gl.CheckFramebufferStatus(GL.FRAMEBUFFER) ~= GL.FRAMEBUFFER_COMPLETE then
		return false
	end

	return fbo
end
--]]

-- This isn't good practice (which is why you must explicitly call it), but
-- patching various love functions to maintain state here makes things a lot
-- more pleasant to use.
function l3d.patch()
	love.graphics.getLove3D    = function() return l3d end
	love.graphics.clearDepth   = function() l3d.clear() end
	love.graphics.setDepthTest = l3d.set_depth_test
	love.graphics.setCulling   = l3d.set_culling
	love.graphics.setFrontFace = l3d.set_front_face
	love.graphics.reset        = combine(l3d.reset, love.graphics.reset)

	love.graphics.origin       = combine(l3d.origin, love.graphics.origin)
	love.graphics.pop          = combine(l3d.pop, love.graphics.pop)
	love.graphics.push         = combine(l3d.push, love.graphics.push)
	love.graphics.rotate       = combine(l3d.rotate, love.graphics.rotate)
	love.graphics.scale        = combine(l3d.scale, love.graphics.scale)
	love.graphics.translate    = combine(l3d.translate, love.graphics.translate)
	love.graphics.getMatrix    = l3d.get_matrix

	love.graphics.setShader    = combine(l3d.update_shader, love.graphics.setShader)
	love.graphics.newCanvas    = l3d.new_canvas
end

return l3d
