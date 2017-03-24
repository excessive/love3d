--- Oculus Rift support for LÖVE3D.
-- Currently targets SDK 0.6
-- @module ovr
-- @alias ret

local ffi = require "ffi"

ffi.cdef [[
typedef int32_t ovrResult;
typedef enum ovrSuccessType_
{
ovrSuccess = 0,
ovrSuccess_NotVisible = 1000,
ovrSuccess_HMDFirmwareMismatch = 4100,
ovrSuccess_TrackerFirmwareMismatch = 4101,
} ovrSuccessType;
typedef enum ovrErrorType_
{
ovrError_MemoryAllocationFailure = -1000,
ovrError_SocketCreationFailure = -1001,
ovrError_InvalidHmd = -1002,
ovrError_Timeout = -1003,
ovrError_NotInitialized = -1004,
ovrError_InvalidParameter = -1005,
ovrError_ServiceError = -1006,
ovrError_NoHmd = -1007,
ovrError_AudioReservedBegin = -2000,
ovrError_AudioReservedEnd = -2999,
ovrError_Initialize = -3000,
ovrError_LibLoad = -3001,
ovrError_LibVersion = -3002,
ovrError_ServiceConnection = -3003,
ovrError_ServiceVersion = -3004,
ovrError_IncompatibleOS = -3005,
ovrError_DisplayInit = -3006,
ovrError_ServerStart = -3007,
ovrError_Reinitialization = -3008,
ovrError_MismatchedAdapters = -3009,
ovrError_InvalidBundleAdjustment = -4000,
ovrError_USBBandwidth = -4001,
ovrError_USBEnumeratedSpeed = -4002,
ovrError_ImageSensorCommError = -4003,
ovrError_GeneralTrackerFailure = -4004,
ovrError_ExcessiveFrameTruncation = -4005,
ovrError_ExcessiveFrameSkipping = -4006,
ovrError_SyncDisconnected = -4007,
ovrError_HMDFirmwareMismatch = -4100,
ovrError_TrackerFirmwareMismatch = -4101,
ovrError_Incomplete = -5000,
ovrError_Abandoned = -5001,
} ovrErrorType;
typedef char ovrBool;
typedef struct ovrVector2i_ { int x, y; } ovrVector2i;
typedef struct ovrSizei_ { int w, h; } ovrSizei;
typedef struct ovrRecti_
{
ovrVector2i Pos;
ovrSizei Size;
} ovrRecti;
typedef struct ovrQuatf_ { float x, y, z, w; } ovrQuatf;
typedef struct ovrVector2f_ { float x, y; } ovrVector2f;
typedef struct ovrVector3f_ { float x, y, z; } ovrVector3f;
typedef struct ovrMatrix4f_ { float M[4][4]; } ovrMatrix4f;
typedef struct ovrPosef_
{
ovrQuatf Orientation;
ovrVector3f Position;
} ovrPosef;
typedef struct ovrPoseStatef_
{
ovrPosef ThePose;
ovrVector3f AngularVelocity;
ovrVector3f LinearVelocity;
ovrVector3f AngularAcceleration;
ovrVector3f LinearAcceleration;
char pad0[4];
double TimeInSeconds;
} ovrPoseStatef;
typedef struct ovrFovPort_
{
float UpTan;
float DownTan;
float LeftTan;
float RightTan;
} ovrFovPort;
typedef enum ovrHmdType_
{
ovrHmd_None = 0,
ovrHmd_DK1 = 3,
ovrHmd_DKHD = 4,
ovrHmd_DK2 = 6,
ovrHmd_CB = 8,
ovrHmd_Other = 9,
ovrHmd_EnumSize = 0x7fffffff
} ovrHmdType;
typedef enum ovrHmdCaps_
{
ovrHmdCap_DebugDevice = 0x0010,
ovrHmdCap_LowPersistence = 0x0080,
ovrHmdCap_DynamicPrediction = 0x0200,
ovrHmdCap_Writable_Mask = ovrHmdCap_LowPersistence | ovrHmdCap_DynamicPrediction,
ovrHmdCap_Service_Mask = ovrHmdCap_LowPersistence | ovrHmdCap_DynamicPrediction,
ovrHmdCap_EnumSize = 0x7fffffff
} ovrHmdCaps;
typedef enum ovrTrackingCaps_
{
ovrTrackingCap_Orientation = 0x0010,
ovrTrackingCap_MagYawCorrection = 0x0020,
ovrTrackingCap_Position = 0x0040,
ovrTrackingCap_Idle = 0x0100,
ovrTrackingCap_EnumSize = 0x7fffffff
} ovrTrackingCaps;
typedef enum ovrEyeType_
{
ovrEye_Left = 0,
ovrEye_Right = 1,
ovrEye_Count = 2,
ovrEye_EnumSize = 0x7fffffff
} ovrEyeType;
typedef struct ovrHmdDesc_
{
struct ovrHmdStruct* Handle;
ovrHmdType Type;
const char* ProductName;
const char* Manufacturer;
short VendorId;
short ProductId;
char SerialNumber[24];
short FirmwareMajor;
short FirmwareMinor;
float CameraFrustumHFovInRadians;
float CameraFrustumVFovInRadians;
float CameraFrustumNearZInMeters;
float CameraFrustumFarZInMeters;
unsigned int HmdCaps;
unsigned int TrackingCaps;
ovrFovPort DefaultEyeFov[ovrEye_Count];
ovrFovPort MaxEyeFov[ovrEye_Count];
ovrEyeType EyeRenderOrder[ovrEye_Count];
ovrSizei Resolution;
} ovrHmdDesc;
typedef const ovrHmdDesc* ovrHmd;
typedef enum ovrStatusBits_
{
ovrStatus_OrientationTracked = 0x0001,
ovrStatus_PositionTracked = 0x0002,
ovrStatus_CameraPoseTracked = 0x0004,
ovrStatus_PositionConnected = 0x0020,
ovrStatus_HmdConnected = 0x0080,
ovrStatus_EnumSize = 0x7fffffff
} ovrStatusBits;
typedef struct ovrSensorData_
{
ovrVector3f Accelerometer;
ovrVector3f Gyro;
ovrVector3f Magnetometer;
float Temperature;
float TimeInSeconds;
} ovrSensorData;
typedef struct ovrTrackingState_
{
ovrPoseStatef HeadPose;
ovrPosef CameraPose;
ovrPosef LeveledCameraPose;
ovrSensorData RawSensorData;
unsigned int StatusFlags;
uint32_t LastCameraFrameCounter;
char pad0[4];
} ovrTrackingState;
typedef struct ovrFrameTiming_
{
double DisplayMidpointSeconds;
double FrameIntervalSeconds;
unsigned AppFrameIndex;
unsigned DisplayFrameIndex;
} ovrFrameTiming;
typedef struct ovrEyeRenderDesc_
{
ovrEyeType Eye;
ovrFovPort Fov;
ovrRecti DistortedViewport;
ovrVector2f PixelsPerTanAngleAtCenter;
ovrVector3f HmdToEyeViewOffset;
} ovrEyeRenderDesc;
typedef struct ovrTimewarpProjectionDesc_
{
float Projection22;
float Projection23;
float Projection32;
} ovrTimewarpProjectionDesc;
typedef struct ovrViewScaleDesc_
{
ovrVector3f HmdToEyeViewOffset[ovrEye_Count];
float HmdSpaceToWorldScaleInMeters;
} ovrViewScaleDesc;
typedef enum ovrRenderAPIType_
{
ovrRenderAPI_None,
ovrRenderAPI_OpenGL,
ovrRenderAPI_Android_GLES,
ovrRenderAPI_D3D9_Obsolete,
ovrRenderAPI_D3D10_Obsolete,
ovrRenderAPI_D3D11,
ovrRenderAPI_Count,
ovrRenderAPI_EnumSize = 0x7fffffff
} ovrRenderAPIType;
typedef struct ovrTextureHeader_
{
ovrRenderAPIType API;
ovrSizei TextureSize;
} ovrTextureHeader;
typedef struct ovrTexture_
{
ovrTextureHeader Header;
uintptr_t PlatformData[8];
} ovrTexture;
typedef struct ovrSwapTextureSet_
{
ovrTexture* Textures;
int TextureCount;
int CurrentIndex;
} ovrSwapTextureSet;
typedef enum ovrInitFlags_
{
ovrInit_Debug = 0x00000001,
ovrInit_ServerOptional = 0x00000002,
ovrInit_RequestVersion = 0x00000004,
ovrInit_ForceNoDebug = 0x00000008,
ovrInit_EnumSize = 0x7fffffff
} ovrInitFlags;
typedef enum ovrLogLevel_
{
ovrLogLevel_Debug = 0,
ovrLogLevel_Info = 1,
ovrLogLevel_Error = 2,
ovrLogLevel_EnumSize = 0x7fffffff
} ovrLogLevel;
typedef void (__cdecl* ovrLogCallback)(int level, const char* message);
typedef struct ovrInitParams_
{
uint32_t Flags;
uint32_t RequestedMinorVersion;
ovrLogCallback LogCallback;
uint32_t ConnectionTimeoutMS;
} ovrInitParams;
ovrResult ovr_Initialize(const ovrInitParams* params);
void ovr_Shutdown();
typedef struct ovrErrorInfo_
{
ovrResult Result;
char ErrorString[512];
} ovrErrorInfo;
void ovr_GetLastErrorInfo(ovrErrorInfo* errorInfo);
const char* ovr_GetVersionString();
//int ovr_TraceMessage(int level, const char* message);
ovrResult ovrHmd_Detect();
ovrResult ovrHmd_Create(int index, ovrHmd* pHmd);
ovrResult ovrHmd_CreateDebug(ovrHmdType type, ovrHmd* pHmd);
void ovrHmd_Destroy(ovrHmd hmd);
unsigned int ovrHmd_GetEnabledCaps(ovrHmd hmd);
void ovrHmd_SetEnabledCaps(ovrHmd hmd, unsigned int hmdCaps);
ovrResult ovrHmd_ConfigureTracking(ovrHmd hmd, unsigned int supportedTrackingCaps, unsigned int requiredTrackingCaps);
void ovrHmd_RecenterPose(ovrHmd hmd);
ovrTrackingState ovrHmd_GetTrackingState(ovrHmd hmd, double absTime);
typedef enum ovrLayerType_
{
ovrLayerType_Disabled = 0,
ovrLayerType_EyeFov = 1,
ovrLayerType_EyeFovDepth = 2,
ovrLayerType_QuadInWorld = 3,
ovrLayerType_QuadHeadLocked = 4,
ovrLayerType_Direct = 6,
ovrLayerType_EnumSize = 0x7fffffff
} ovrLayerType;
typedef enum ovrLayerFlags_
{
ovrLayerFlag_HighQuality = 0x01,
ovrLayerFlag_TextureOriginAtBottomLeft = 0x02
} ovrLayerFlags;
typedef struct ovrLayerHeader_
{
ovrLayerType Type;
unsigned Flags;
} ovrLayerHeader;
typedef struct ovrLayerEyeFov_
{
ovrLayerHeader Header;
ovrSwapTextureSet* ColorTexture[ovrEye_Count];
ovrRecti Viewport[ovrEye_Count];
ovrFovPort Fov[ovrEye_Count];
ovrPosef RenderPose[ovrEye_Count];
} ovrLayerEyeFov;
typedef struct ovrLayerEyeFovDepth_
{
ovrLayerHeader Header;
ovrSwapTextureSet* ColorTexture[ovrEye_Count];
ovrRecti Viewport[ovrEye_Count];
ovrFovPort Fov[ovrEye_Count];
ovrPosef RenderPose[ovrEye_Count];
ovrSwapTextureSet* DepthTexture[ovrEye_Count];
ovrTimewarpProjectionDesc ProjectionDesc;
} ovrLayerEyeFovDepth;
typedef struct ovrLayerQuad_
{
ovrLayerHeader Header;
ovrSwapTextureSet* ColorTexture;
ovrRecti Viewport;
ovrPosef QuadPoseCenter;
ovrVector2f QuadSize;
} ovrLayerQuad;
typedef struct ovrLayerDirect_
{
ovrLayerHeader Header;
ovrSwapTextureSet* ColorTexture[ovrEye_Count];
ovrRecti Viewport[ovrEye_Count];
} ovrLayerDirect;
typedef union ovrLayer_Union_
{
ovrLayerHeader Header;
ovrLayerEyeFov EyeFov;
ovrLayerEyeFovDepth EyeFovDepth;
ovrLayerQuad Quad;
ovrLayerDirect Direct;
} ovrLayer_Union;
void ovrHmd_DestroySwapTextureSet(ovrHmd hmd, ovrSwapTextureSet* textureSet);
void ovrHmd_DestroyMirrorTexture(ovrHmd hmd, ovrTexture* mirrorTexture);
ovrSizei ovrHmd_GetFovTextureSize(ovrHmd hmd, ovrEyeType eye, ovrFovPort fov, float pixelsPerDisplayPixel);
ovrEyeRenderDesc ovrHmd_GetRenderDesc(ovrHmd hmd, ovrEyeType eyeType, ovrFovPort fov);
ovrResult ovrHmd_SubmitFrame(ovrHmd hmd, unsigned int frameIndex, const ovrViewScaleDesc* viewScaleDesc, ovrLayerHeader const * const * layerPtrList, unsigned int layerCount);
ovrFrameTiming ovrHmd_GetFrameTiming(ovrHmd hmd, unsigned int frameIndex);
//void ovrHmd_ResetFrameTiming(ovrHmd hmd, unsigned int frameIndex);
double ovr_GetTimeInSeconds();
typedef enum ovrPerfHudMode_
{
ovrPerfHud_Off = 0,
ovrPerfHud_LatencyTiming = 1,
ovrPerfHud_RenderTiming = 2,
ovrPerfHud_Count = 2,
ovrPerfHud_EnumSize = 0x7fffffff
} ovrPerfHudMode;

//ovrBool ovrHmd_GetBool(ovrHmd hmd, const char* propertyName, ovrBool defaultVal);
//ovrBool ovrHmd_SetBool(ovrHmd hmd, const char* propertyName, ovrBool value);
//int ovrHmd_GetInt(ovrHmd hmd, const char* propertyName, int defaultVal);
//ovrBool ovrHmd_SetInt(ovrHmd hmd, const char* propertyName, int value);
//float ovrHmd_GetFloat(ovrHmd hmd, const char* propertyName, float defaultVal);
//ovrBool ovrHmd_SetFloat(ovrHmd hmd, const char* propertyName, float value);
//unsigned int ovrHmd_GetFloatArray(ovrHmd hmd, const char* propertyName, float values[], unsigned int valuesCapacity);
//ovrBool ovrHmd_SetFloatArray(ovrHmd hmd, const char* propertyName, const float values[], unsigned int valuesSize);
//const char* ovrHmd_GetString(ovrHmd hmd, const char* propertyName, const char* defaultVal);
//ovrBool ovrHmd_SetString(ovrHmd hmd, const char* propertyName, const char* value);

typedef enum ovrProjectionModifier_
{
ovrProjection_None = 0x00,
ovrProjection_RightHanded = 0x01,
ovrProjection_FarLessThanNear = 0x02,
ovrProjection_FarClipAtInfinity = 0x04,
ovrProjection_ClipRangeOpenGL = 0x08,
} ovrProjectionModifier;

ovrMatrix4f ovrMatrix4f_Projection(ovrFovPort fov, float znear, float zfar, unsigned int projectionModFlags);
//ovrTimewarpProjectionDesc ovrTimewarpProjectionDesc_FromProjection(ovrMatrix4f projection, unsigned int projectionModFlags);
//ovrMatrix4f ovrMatrix4f_OrthoSubProjection(ovrMatrix4f projection, ovrVector2f orthoScale, float orthoDistance, float hmdToEyeViewOffsetX);
void ovr_CalcEyePoses(ovrPosef headPose, const ovrVector3f hmdToEyeViewOffset[2], ovrPosef outEyePoses[2]);
void ovrHmd_GetEyePoses(ovrHmd hmd, unsigned int frameIndex, const ovrVector3f hmdToEyeViewOffset[2], ovrPosef outEyePoses[2], ovrTrackingState* outHmdTrackingState);
//double ovr_WaitTillTime(double absTime);

// GL stuff
typedef unsigned int GLuint;
typedef struct ovrGLTextureData_s
{
ovrTextureHeader Header;
GLuint TexId;
} ovrGLTextureData;
typedef union ovrGLTexture_s
{
ovrTexture Texture; ///< General device settings.
ovrGLTextureData OGL; ///< OpenGL-specific settings.
} ovrGLTexture;
ovrResult ovrHmd_CreateSwapTextureSetGL(ovrHmd hmd, GLuint format, int width, int height, ovrSwapTextureSet** outTextureSet);
ovrResult ovrHmd_CreateMirrorTextureGL(ovrHmd hmd, GLuint format, int width, int height, ovrTexture** outMirrorTexture);

]]

local ovr = ffi.load(ffi.os == "Windows" and "bin/LibOVR.dll" or error("Oculus really should support not windows, too."))

local ret = {}

--- Initialize the Rift.
-- Quality defaults to 0.9, set lower or higher depending on GPU performance.
-- In practice 0.9 is usually about ideal, but >1 can be used for super sampling
-- the buffers.
-- Usage:
-- 	local rift = ovr.init()
-- 	-- (later)
-- 	rift:shutdown()
-- @param quality scaling factor for render buffers.
function ret.init(quality)
	local rift
	quality = quality or 0.9
	if ovr.ovr_Initialize(nil) == ovr.ovrSuccess then
		rift = {}
		print("Initialized LibOVR")
		local hmd = ffi.new("ovrHmd[?]", 1)
		if ovr.ovrHmd_Create(0, hmd) == ovr.ovrSuccess then
			hmd = hmd[0]
			print("Initialized HMD")

			local flags = ovr.ovrTrackingCap_Orientation
			flags = bit.bor(flags, ovr.ovrTrackingCap_MagYawCorrection)
			flags = bit.bor(flags, ovr.ovrTrackingCap_Position) -- DK2+

			ovr.ovrHmd_SetEnabledCaps(hmd, bit.bor(ovr.ovrHmdCap_LowPersistence, ovr.ovrHmdCap_DynamicPrediction))
			ovr.ovrHmd_ConfigureTracking(hmd, flags, 0)

			rift.hmd = hmd

			local rec_size = ovr.ovrHmd_GetFovTextureSize(hmd, ovr.ovrEye_Left, hmd.DefaultEyeFov[0], quality)
			local rec_size_r = ovr.ovrHmd_GetFovTextureSize(hmd, ovr.ovrEye_Right, hmd.DefaultEyeFov[1], quality)
			rec_size.w = rec_size.w + rec_size_r.w
			rec_size.h = math.max(rec_size.h, rec_size_r.h)

			local function mk_color(hmd, size)
				local swaps = ffi.new("ovrSwapTextureSet*[?]", 1)
				local textures = {}
				assert(ovr.ovrHmd_CreateSwapTextureSetGL(hmd, GL.RGBA, size.w, size.h, swaps) == ovr.ovrSuccess)
				print(string.format("Created %dx%d swap texture set.", size.w, size.h))
				for i = 1, swaps[0].TextureCount do
					local tex = ffi.cast("ovrGLTexture*", swaps[0].Textures[i-1])
					gl.BindTexture(GL.TEXTURE_2D_MULTISAMPLE, tex.OGL.TexId)
					gl.TexParameteri(GL.TEXTURE_2D_MULTISAMPLE, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
					gl.TexParameteri(GL.TEXTURE_2D_MULTISAMPLE, GL.TEXTURE_MAG_FILTER, GL.LINEAR)
					gl.TexParameteri(GL.TEXTURE_2D_MULTISAMPLE, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
					gl.TexParameteri(GL.TEXTURE_2D_MULTISAMPLE, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
					gl.TexImage2DMultisample(GL.TEXTURE_2D_MULTISAMPLE, 4, GL.RGBA8, size.w, size.h, false)
					textures[i] = tex.OGL.TexId
				end
				local fbo = ffi.new("GLuint[?]", 1)
				gl.GenFramebuffers(1, fbo)

				local cpml = require "cpml"
				return {
					swaps = swaps,
					size = cpml.vec2(size.w, size.h),
					textures = textures,
					fbo = fbo
				}
			end

			local function mk_depth(size)
				local dt = ffi.new("GLuint[?]", 1)
				gl.GenTextures(1, dt)
				gl.BindTexture(GL.TEXTURE_2D, dt[0])

				gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
				gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)
				gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
				gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)

				-- Your shitty system had better have GL_ARB_depth_buffer_float, scrublord.
				gl.TexImage2D(GL.TEXTURE_2D, 0, GL.DEPTH_COMPONENT32F, size.w, size.h, 0, GL.DEPTH_COMPONENT, GL.FLOAT, nil)

				return dt
			end

			local textures = {
				color = {},
				depth = {}
			}
			for i=0,1 do
			local size = ovr.ovrHmd_GetFovTextureSize(hmd, ffi.cast("ovrEyeType", i), hmd.DefaultEyeFov[i], quality)
				textures.color[i] = mk_color(hmd, size)
				textures.depth[i] = mk_depth(size)
			end
			rift.textures = textures

			-- Initialize our single full screen Fov layer.
			local layer = ffi.new("ovrLayerEyeFov")
			layer.Header.Type = ovr.ovrLayerType_EyeFov
			layer.Header.Flags = ovr.ovrLayerFlag_TextureOriginAtBottomLeft

			local rect = ffi.new("ovrRecti[?]", 2)
			rect[1].Pos.x, rect[1].Pos.y = 0, 0
			rect[1].Size.w, rect[1].Size.h = rec_size.w / 2, rec_size.h

			rect[0].Pos.x, rect[0].Pos.y = 0, 0 --rec_size.w / 2, 0
			rect[0].Size.w, rect[0].Size.h = rec_size.w / 2, rec_size.h

			-- Initialize VR structures, filling out description.
			local eyeRenderDesc = ffi.new("ovrEyeRenderDesc*[?]", 2)
			local hmdToEyeViewOffset = ffi.new("ovrVector3f[?]", 2)
			eyeRenderDesc[0] = ovr.ovrHmd_GetRenderDesc(hmd, ovr.ovrEye_Left, hmd.DefaultEyeFov[0])
			eyeRenderDesc[1] = ovr.ovrHmd_GetRenderDesc(hmd, ovr.ovrEye_Right, hmd.DefaultEyeFov[1])

			rift.offsets = {}
			for i = 0, 1 do
				hmdToEyeViewOffset[i] = eyeRenderDesc[i].HmdToEyeViewOffset
				rift.offsets[i] = hmdToEyeViewOffset[i]
				layer.ColorTexture[i] = textures.color[i].swaps[0]
				layer.Viewport[i] = rect[i]
				layer.Fov[i] = eyeRenderDesc[i].Fov
			end

			rift.layer = layer

			rift.fov = {
				[0] = {
					UpTan = eyeRenderDesc[0].Fov.UpTan,
					DownTan = eyeRenderDesc[0].Fov.DownTan,
					LeftTan = eyeRenderDesc[0].Fov.LeftTan,
					RightTan = eyeRenderDesc[0].Fov.RightTan
				},
				[1] = {
					UpTan = eyeRenderDesc[1].Fov.UpTan,
					DownTan = eyeRenderDesc[1].Fov.DownTan,
					LeftTan = eyeRenderDesc[1].Fov.LeftTan,
					RightTan = eyeRenderDesc[1].Fov.RightTan
				}
			}

			-- Create mirror texture and an FBO used to copy mirror texture to back buffer
			local mirrorTexture = ffi.new("ovrGLTexture*[?]", 1)
			local w, h = love.graphics.getDimensions()
			ovr.ovrHmd_CreateMirrorTextureGL(hmd, GL.RGBA, w, h, ffi.cast("ovrTexture**", mirrorTexture))
			rift.mirror_texture = mirrorTexture

			-- Configure the mirror read buffer
			local mirrorFBO = ffi.new("GLuint[?]", 1)
			gl.GenFramebuffers(1, mirrorFBO)
			gl.BindFramebuffer(GL.READ_FRAMEBUFFER, mirrorFBO[0])
			gl.FramebufferTexture2D(GL.READ_FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, mirrorTexture[0].OGL.TexId, 0)
			gl.FramebufferRenderbuffer(GL.READ_FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, 0)
			gl.BindFramebuffer(GL.READ_FRAMEBUFFER, 0)
			rift.mirror_fbo = mirrorFBO

			local layers = ffi.new("const ovrLayerHeader*[?]", 1)
			layers[0] = rift.layer.Header

			local vsd = ffi.new("ovrViewScaleDesc")
			vsd.HmdSpaceToWorldScaleInMeters = 1.0
			vsd.HmdToEyeViewOffset[0] = rift.offsets[0]
			vsd.HmdToEyeViewOffset[1] = rift.offsets[1]

			rift.layers = layers
			rift.vsd = vsd

			local eye_offsets = ffi.new("ovrVector3f[?]", 2)
			eye_offsets[0] = rift.offsets[0]
			eye_offsets[1] = rift.offsets[1]

			rift.eye_offsets = eye_offsets
		end
	end
	return rift
end

--- Clean up all data used by LibOVR.
-- Call this when shutting down your program.
-- @param rift
function ret.shutdown(rift)
	if type(rift) == "table" then
		if rift.hmd then
			ovr.ovrHmd_Destroy(rift.hmd)
			rift.hmd = nil
			rift.layer = nil
			rift.fov = nil
			print("Shutdown HMD")
		end
		ovr.ovr_Shutdown()
		rift = nil
		print("Shutdown LibOVR")
	end
end

--- Draw a mirror of what is displaying on the Rift.
-- Used to view what is happening on the headset on your monitor.
--
-- Note: Blits directly to the window.
-- @param rift
function ret.draw_mirror(rift)
	if not rift.mirror_texture then
		return
	end
	-- Blit mirror texture to back buffer
	gl.BindFramebuffer(GL.READ_FRAMEBUFFER, rift.mirror_fbo[0])
	gl.BindFramebuffer(GL.DRAW_FRAMEBUFFER, 0)
	local w = rift.mirror_texture[0].OGL.Header.TextureSize.w
	local h = rift.mirror_texture[0].OGL.Header.TextureSize.h
	gl.BlitFramebuffer(0, h, w, 0, 0, 0, w, h, GL.COLOR_BUFFER_BIT, GL.NEAREST)
	gl.BindFramebuffer(GL.READ_FRAMEBUFFER, 0)
end

--- Create a projection matrix appropriate for HMD usage.
-- Convenience function.
--
-- Shortcut for `cpml.mat4():hmd_perspective(rift.fov[eye], near, far, false, false)`.
-- @param rift
-- @param eye eye index
function ret.projection(rift, eye)
	local cpml = require "cpml"
	local fov = assert(rift.fov[eye])
	return cpml.mat4():hmd_perspective(fov, 0.01, 10000, false, false)
end

--- Iterator for processing each view.
-- You should draw the same thing for each eye, just offset with the pose.
-- Usage:
-- 	for eye, pose in rift:eyes() do
-- 		-- eye is a number, pose is an orientation and a position.
-- 		-- Usually used like this (ugly! may be cleaned up later).
-- 		-- cpml.mat4():rotate(pose.orientation:conjugate()):translate(-pose.position)
-- 		draw(eye, pose)
-- 	end
-- This function takes care of frame timings and per-eye render setup for you.
-- @param rift
function ret.eyes(rift)
	if not rift or not rift.hmd then
		return nil
	end

	local eye = -1

	local ft = ovr.ovrHmd_GetFrameTiming(rift.hmd, 0)
	local ts = ovr.ovrHmd_GetTrackingState(rift.hmd, ft.DisplayMidpointSeconds)

	if bit.band(ts.StatusFlags, bit.bor(ovr.ovrStatus_OrientationTracked, ovr.ovrStatus_PositionTracked)) ~= 0 then
		local eye_poses = ffi.new("ovrPosef[?]", 2)
		ovr.ovr_CalcEyePoses(ts.HeadPose.ThePose, rift.eye_offsets, eye_poses)

		rift.layer.RenderPose[0] = eye_poses[0]
		rift.layer.RenderPose[1] = eye_poses[1]
	end

	local idx = ft.AppFrameIndex % 2

	local closure = function()
		if eye >= 1 then
			local w, h = love.graphics.getDimensions()

			gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, 0, 0)
			gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.TEXTURE_2D, 0, 0)

			gl.BindFramebuffer(GL.FRAMEBUFFER, 0)
			gl.Viewport(0, 0, w, h)
			gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))

			return nil
		else
			eye = eye + 1

			local cpml        = require "cpml"
			local pose        = rift.layer.RenderPose[eye]
			local orientation = cpml.quat(pose.Orientation.x, pose.Orientation.y, pose.Orientation.z, pose.Orientation.w)
			local position	   = cpml.vec3(pose.Position.x, pose.Position.y, pose.Position.z)

			local texture = {
				color = rift.textures.color[eye],
				depth = rift.textures.depth[eye],
			}
			texture.color.swaps[0].CurrentIndex = idx

			local fbo = texture.color.fbo

			gl.BindFramebuffer(GL.FRAMEBUFFER, fbo[0])
			gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture.color.textures[idx+1], 0)
			gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.TEXTURE_2D, texture.depth[0], 0)

			-- Does the GPU support current FBO configuration?
			local status = gl.CheckFramebufferStatus(GL.FRAMEBUFFER)
			assert(status == GL.FRAMEBUFFER_COMPLETE)

			gl.Viewport(0, 0, texture.color.size.x, texture.color.size.y)
			gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))

			return eye, { orientation = orientation, position = position }
		end
	end
	return closure
end

--- Submit current frame to Rift.
-- @param rift
function ret.submit_frame(rift)
	assert(ovr.ovrHmd_SubmitFrame(rift.hmd, 0, rift.vsd, rift.layers, 1) == ovr.ovrSuccess)
end

return setmetatable(ret, { __index = ovr })
