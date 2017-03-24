local ffi = require("ffi")

local glheader = [[
typedef float GLfloat;
typedef unsigned int GLbitfield;
typedef unsigned int GLuint;
typedef double GLdouble;
typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef int GLsizei;
typedef int GLint;
typedef char GLchar;

#define GL_NO_ERROR                       0
#define GL_NONE                           0
#define GL_EQUAL                          0x0202
#define GL_LEQUAL                         0x0203
#define GL_GEQUAL                         0x0206
#define GL_FRONT                          0x0404
#define GL_BACK                           0x0405
#define GL_CW                             0x0900
#define GL_CCW                            0x0901
#define GL_CULL_FACE                      0x0B44
#define GL_DEPTH_TEST                     0x0B71
#define GL_TEXTURE_2D                     0x0DE1
#define GL_FLOAT                          0x1406
#define GL_DEPTH_COMPONENT                0x1902
#define GL_NEAREST                        0x2600
#define GL_LINEAR                         0x2601
#define GL_TEXTURE_MAG_FILTER             0x2800
#define GL_TEXTURE_MIN_FILTER             0x2801
#define GL_TEXTURE_WRAP_S                 0x2802
#define GL_TEXTURE_WRAP_T                 0x2803
#define GL_CLAMP_TO_EDGE                  0x812F
#define GL_TEXTURE0                       0x84C0
#define GL_TEXTURE7                       0x84C7
#define GL_TEXTURE_COMPARE_MODE           0x884C
#define GL_TEXTURE_COMPARE_FUNC           0x884D
#define GL_COMPARE_REF_TO_TEXTURE         0x884E
#define GL_CURRENT_PROGRAM                0x8B8D
#define GL_FRAMEBUFFER_COMPLETE           0x8CD5
#define GL_DEPTH_ATTACHMENT               0x8D00
#define GL_FRAMEBUFFER                    0x8D40
#define GL_RENDERBUFFER                   0x8D41

#define GL_DEPTH_COMPONENT16              0x81A5
#define GL_DEPTH_COMPONENT24              0x81A6

#define GL_DEPTH_BUFFER_BIT               0x00000100
#define GL_COLOR_BUFFER_BIT               0x00004000

typedef void (APIENTRYP PFNGLUNIFORM1IPROC) (GLint location, GLint v0);
typedef void (APIENTRYP PFNGLACTIVETEXTUREPROC) (GLenum texture);
typedef GLint (APIENTRYP PFNGLGETUNIFORMLOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGETINTEGERVPROC) (GLenum pname, GLint *data);
typedef GLenum (APIENTRYP PFNGLGETERRORPROC) (void);
typedef void (APIENTRYP PFNGLFRAMEBUFFERRENDERBUFFERPROC) (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
typedef void (APIENTRYP PFNGLVIEWPORTPROC) (GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLREADBUFFERPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE2DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLBINDRENDERBUFFERPROC) (GLenum target, GLuint renderbuffer);
typedef void (APIENTRYP PFNGLDELETERENDERBUFFERSPROC) (GLsizei n, const GLuint *renderbuffers);
typedef void (APIENTRYP PFNGLGENRENDERBUFFERSPROC) (GLsizei n, GLuint *renderbuffers);
typedef void (APIENTRYP PFNGLRENDERBUFFERSTORAGEPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLBINDFRAMEBUFFERPROC) (GLenum target, GLuint framebuffer);
typedef void (APIENTRYP PFNGLDELETEFRAMEBUFFERSPROC) (GLsizei n, const GLuint *framebuffers);
typedef void (APIENTRYP PFNGLGENFRAMEBUFFERSPROC) (GLsizei n, GLuint *framebuffers);
typedef GLenum (APIENTRYP PFNGLCHECKFRAMEBUFFERSTATUSPROC) (GLenum target);
typedef void (APIENTRYP PFNGLTEXIMAGE2DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXPARAMETERIPROC) (GLenum target, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLBINDTEXTUREPROC) (GLenum target, GLuint texture);
typedef void (APIENTRYP PFNGLDELETETEXTURESPROC) (GLsizei n, const GLuint *textures);
typedef void (APIENTRYP PFNGLGENTEXTURESPROC) (GLsizei n, GLuint *textures);
typedef void (APIENTRYP PFNGLDRAWBUFFERPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLDEPTHMASKPROC) (GLboolean flag);
typedef void (APIENTRYP PFNGLDISABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLCLEARPROC) (GLbitfield mask);
typedef void (APIENTRYP PFNGLCLEARDEPTHPROC) (GLdouble depth);
typedef void (APIENTRYP PFNGLCLEARDEPTHFPROC) (GLfloat d);
typedef void (APIENTRYP PFNGLDEPTHFUNCPROC) (GLenum func);
typedef void (APIENTRYP PFNGLDEPTHRANGEPROC) (GLdouble near, GLdouble far);
typedef void (APIENTRYP PFNGLENABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLCULLFACEPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLFRONTFACEPROC) (GLenum mode);
]]

local openGL = {
	GL = {},
	gl = {},
	loader = nil,

	import = function(self)
		rawset(_G, "GL", self.GL)
		rawset(_G, "gl", self.gl)
	end
}

if ffi.os == "Windows" then
	glheader = glheader:gsub("APIENTRYP", "__stdcall *")
	glheader = glheader:gsub("APIENTRY", "__stdcall")
else
	glheader = glheader:gsub("APIENTRYP", "*")
	glheader = glheader:gsub("APIENTRY", "")
end

local type_glenum = ffi.typeof("unsigned int")
local type_uint64 = ffi.typeof("uint64_t")

local function constant_replace(name, value)
	local ctype = type_glenum
	local GL = openGL.GL

	local num = tonumber(value)
	if (not num) then
		if (value:match("ull$")) then
			--Potentially reevaluate this for LuaJIT 2.1
			GL[name] = loadstring("return " .. value)()
		elseif (value:match("u$")) then
			value = value:gsub("u$", "")
			num = tonumber(value)
		end
	end

	GL[name] = GL[name] or ctype(num)

	return ""
end

glheader = glheader:gsub("#define GL_(%S+)%s+(%S+)\n", constant_replace)

ffi.cdef(glheader)

--ffi.load(ffi.os == 'OSX' and 'OpenGL.framework/OpenGL' or ffi.os == 'Windows' and 'opengl32' or 'GL')
if ffi.os == "Windows" then
	ffi.load('opengl32')
end

local gl_mt = {
	__index = function(self, name)
		local glname = "gl" .. name
		local procname = "PFNGL" .. name:upper() .. "PROC"
		local func = ffi.cast(procname, openGL.loader(glname))
		rawset(self, name, func)
		return func
	end
}

setmetatable(openGL.gl, gl_mt)

return openGL
