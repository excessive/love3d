--- LÖVE3D.
-- Utilities for working in 3D with LÖVE.
-- @module l3d

local current_folder = (...):gsub('%.init$', '') .. "."
local cpml = require "cpml"
local ffi = require "ffi"

local use_gles = false

local l3d = {
	_LICENSE = "Love3D is distributed under the terms of the MIT license. See LICENSE.md.",
	_URL = "https://github.com/excessive/love3d",
	_VERSION = "0.0.2",
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

--- Load OpenGL functions for use by LÖVE3D.
-- Loads extra functions that LÖVE does not provide and optionally adds/updates
-- functions in love.graphics for 3D.
--
-- This must be called before anything else.
-- @param use_monkeypatching patch the LOVE API with LOVE3D functions
function l3d.import()
	local already_loaded = pcall(function() return ffi.C.SDL_GL_DEPTH_SIZE end)
	if not already_loaded then
		ffi.cdef([[
			typedef enum {
				SDL_GL_DEPTH_SIZE = 6
			} SDL_GLattr;
			void *SDL_GL_GetProcAddress(const char *proc);
			int SDL_GL_GetAttribute(SDL_GLattr attr, int* value);
		]])
	end

	-- Windows needs to use an external SDL
	local sdl
	if love.system.getOS() == "Windows" then
		if not love.filesystem.isFused() and love.filesystem.isFile("bin/SDL2.dll") then
			sdl = ffi.load("bin/SDL2")
		else
			sdl = ffi.load("SDL2")
		end
	else
		-- On other systems, we get the symbols for free.
		sdl = ffi.C
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
		return sdl.SDL_GL_GetProcAddress(fn)
	end
	opengl:import()

	local out = ffi.new("int[?]", 1)
	sdl.SDL_GL_GetAttribute(sdl.SDL_GL_DEPTH_SIZE, out)
end

--- Clear color/depth buffers.
-- Must pass false (not nil!) to disable clearing. Defaults to depth only.
-- @param color clear color buffer (bool)
-- @param depth clear depth buffer (bool)
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

--- Reset LOVE3D state.
-- Disables depth testing, enables depth writing, disables culling and resets
-- front face.
function l3d.reset()
	l3d.set_depth_test()
	l3d.set_depth_write()
	l3d.set_culling()
	l3d.set_front_face()
end

-- FXAA helpers
--- Get FXAA alpha value for a given color
function l3d.get_fxaa_alpha(color)
	local c_vec = cpml.vec3.isvector(color) and color or cpml.vec3(color)
	return c_vec:dot(cpml.vec3(0.299, 0.587, 0.114))
end

function l3d.set_fxaa_background(color)
	local c_vec = cpml.vec3.isvector(color) and color or cpml.vec3(color)
	love.graphics.setBackgroundColor(c_vec.x, c_vec.y, c_vec.z, l3d.get_fxaa_alpha(c_vec))
end

--- Set depth writing.
-- Enable or disable writing to the depth buffer.
-- @param mask
function l3d.set_depth_write(mask)
	if mask then
		assert(type(mask) == "boolean", "set_depth_write expects one parameter of type 'boolean'")
	end
	if mask == nil then
		mask = true
	end
	gl.DepthMask(mask and 1 or 0)
end

--- Set depth test method.
-- Can be "greater", "equal", "less" or unspecified to disable depth testing.
-- Usually you want to use "less".
-- @param method
function l3d.set_depth_test(method)
	if method then
		local methods = {
			greater = GL.GEQUAL,
			equal = GL.EQUAL,
			less = GL.LEQUAL
		}
		assert(methods[method], "Invalid depth test method.")
		gl.Enable(GL.DEPTH_TEST)
		gl.DepthFunc(methods[method])
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

--- Set front face winding.
-- Can be "cw", "ccw" or unspecified to reset to ccw.
-- @param facing
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

--- Set culling method.
-- Can be "front", "back" or unspecified to reset to none.
-- @param method
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

--- Create a shader without LOVE's preprocessing.
-- Useful if you need different shader outputs or a later GLSL version.
-- The shader is still preprocessed for things such as VERTEX and PIXEL, but
-- you will have to write your own main() function, attributes, etc.
--
-- *Warning: This will very likely do bad things for your shader compatibility.*
-- @param gl_version
-- @param vc vertex shader code or filename
-- @param pc pixel shader code or filename
-- @return shader
function l3d.new_shader_raw(gl_version, vc, pc)
	local function is_vc(code)
		return code:match("#ifdef%s+VERTEX") ~= nil
	end
	local function is_pc(code)
		return code:match("#ifdef%s+PIXEL") ~= nil
	end
	local function mk_shader_code(arg1, arg2)
		-- local lang = "glsl"
		if (love.graphics.getRendererInfo()) == "OpenGL ES" then
			error("NYI: Can't into GLES")
			-- lang = "glsles"
		end
		local vc, pc
		-- as love does
		if arg1 then
			-- first arg contains vertex shader code
			if is_vc(arg1) then vc = arg1 end
			local ispixel = is_pc(arg1)
			-- first arg contains pixel shader code
			if ispixel then pc = arg1 end
		end
		if arg2 then
			-- second arg contains vertex shader code
			if is_vc(arg2) then vc = arg2 end
			local ispixel = is_pc(arg2)
			-- second arg contains pixel shader code
			if ispixel then pc = arg2 end
		end
		-- Later versions of GLSL do this anyways - so let's use GL version.
		local versions = {
			["2.1"] = "120", ["3.0"] = "130", ["3.1"] = "140", ["3.2"] = "150",
			["3.3"] = "330", ["4.0"] = "400", ["4.1"] = "410", ["4.2"] = "420",
			["4.3"] = "430", ["4.4"] = "440", ["4.5"] = "450",
		}
		local fmt = [[%s
#ifndef GL_ES
#define lowp
#define mediump
#define highp
#endif
#pragma optionNV(strict on)
#define %s
#line 0
%s]]
		local vs = arg1 and string.format(fmt, "#version " .. versions[gl_version], "VERTEX", vc) or nil
		local ps = arg2 and string.format(fmt, "#version " .. versions[gl_version], "PIXEL", pc) or nil
		return vs, ps
	end
	local orig = love.graphics._shaderCodeToGLSL
	love.graphics._shaderCodeToGLSL = mk_shader_code
	local shader = love.graphics.newShader(vc, pc)
	love.graphics._shaderCodeToGLSL = orig
	return shader
end

--- Create a buffer from a list of vertices (cpml.vec3's).
-- Offset will offset every vertex by the specified amount, useful for preventing z-fighting.
-- Optional mesh argument will update the mesh instead of creating a new one.
-- Specify usage as "dynamic" if you intend to update it frequently.
-- @param t vertex data
-- @param offset
-- @param mesh used when updating
-- @param usage
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

--- Create a canvas with a depth buffer.
-- @param width
-- @param height
-- @param format
-- @param msaa
-- @param gen_depth
function l3d.new_canvas(width, height, format, msaa, gen_depth)
	-- TODO: Test this to make sure things are properly freed.
	if use_gles then
		error()
		return
	end
	local w, h = width or love.graphics.getWidth(), height or love.graphics.getHeight()
	local canvas = new_canvas(w, h, format, msaa)
	if gen_depth and canvas then
		love.graphics.setCanvas(canvas)

		local depth = ffi.new("unsigned int[1]", 1)
		gl.GenRenderbuffers(1, depth);
		gl.BindRenderbuffer(GL.RENDERBUFFER, depth[0]);
		if not use_gles and (type(msaa) == "number" and msaa > 1) then
			gl.RenderbufferStorageMultisample(GL.RENDERBUFFER, msaa, use_gles and GL.DEPTH_COMPONENT16 or GL.DEPTH_COMPONENT24, w, h)
		else
			gl.RenderbufferStorage(GL.RENDERBUFFER, use_gles and GL.DEPTH_COMPONENT16 or GL.DEPTH_COMPONENT24, w, h)
		end
		gl.FramebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, depth[0])
		local status = gl.CheckFramebufferStatus(GL.FRAMEBUFFER)
		if status ~= GL.FRAMEBUFFER_COMPLETE then
			error(string.format("Framebuffer is borked :( (%d)", status))
		end
		if gl.GetError() ~= GL.NO_ERROR then
			error("You fucking broke GL you asshole.")
		end
		l3d.clear()
		love.graphics.setCanvas()
	end

	return canvas
end

--- Bind a shadow map.
-- Sets up drawing to a shadow map texture created with l3d.new_shadow_map.
-- @param map
function l3d.bind_shadow_map(map)
	if map then
		assert(map.shadow_map)
		gl.DrawBuffer(GL.NONE)
		gl.ReadBuffer(GL.NONE)
		love.graphics.setCanvas(map.dummy_canvas)
		gl.BindFramebuffer(GL.FRAMEBUFFER, map.buffers[0])
		gl.Viewport(0, 0, map.width, map.height)
	else
		--- XXX: This is not a good assumption on ES!
		-- gl.BindFramebuffer(0)
		love.graphics.setCanvas()
		gl.DrawBuffer(GL.BACK)
		gl.ReadBuffer(GL.BACK)
	end
end

--- Bind shadow map to a texture sampler.
-- @param map
-- @param shader
function l3d.bind_shadow_texture(map, shader)
	-- Throw me a bone here, slime, this sucks.
	local current = ffi.new("GLuint[1]")
	gl.GetIntegerv(GL.CURRENT_PROGRAM, current)
	local loc = gl.GetUniformLocation(current[0], "shadow_texture")
	gl.ActiveTexture(GL.TEXTURE7)
	gl.BindTexture(GL.TEXTURE_2D, map.buffers[1])
	gl.Uniform1i(loc, 7)
	gl.ActiveTexture(GL.TEXTURE0)
end

--- Create a new shadow map.
-- Creates a depth texture and framebuffer to draw to.
-- @param w shadow map width
-- @param h shadow map height
-- @return shadow_map
function l3d.new_shadow_map(w, h)
	-- Use a dummy canvas so that we can make LOVE reset the canvas for us.
	-- ...sneaky sneaky
	local dummy = love.graphics.newCanvas(1, 1)
	love.graphics.setCanvas(dummy)

	local buffers = ffi.gc(ffi.new("GLuint[2]"), function(ptr)
		gl.DeleteFramebuffers(1, ptr)
		gl.DeleteTextures(1, ptr+1)
	end)

	gl.GenTextures(1, buffers+1)
	gl.BindTexture(GL.TEXTURE_2D, buffers[1])
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
	gl.TexImage2D(GL.TEXTURE_2D, 0, GL.DEPTH_COMPONENT24, w, h, 0, GL.DEPTH_COMPONENT, GL.FLOAT, nil)

	gl.GenFramebuffers(1, buffers)
	gl.BindFramebuffer(GL.FRAMEBUFFER, buffers[0])

	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_COMPARE_MODE, GL.COMPARE_REF_TO_TEXTURE);
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_COMPARE_FUNC, GL.LEQUAL);
	gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.TEXTURE_2D, buffers[1], 0)

	gl.DrawBuffer(GL.NONE)
	gl.ReadBuffer(GL.NONE)

	if gl.CheckFramebufferStatus(GL.FRAMEBUFFER) ~= GL.FRAMEBUFFER_COMPLETE then
		l3d.bind_shadow_map()
		return false
	end

	l3d.bind_shadow_map()

	return {
		shadow_map   = true,
		buffers      = buffers,
		dummy_canvas = dummy,
		width        = w,
		height       = h
	}
end

return l3d
