--!strict
--!optimize 2

-- ════════════════════════════════════════════════════════════════════
-- Severe property/method extension layer  (performance rewrite)
-- Offsets hardcoded from: roblox-dumper 2.6 — version-460909c4fe904aae
-- ════════════════════════════════════════════════════════════════════

-- ───────────── memory aliases ─────────────
local memory_readu8     = memory.readu8
local memory_readi32    = memory.readi32
local memory_readu64    = memory.readu64
local memory_readf32    = memory.readf32
local memory_readf64    = memory.readf64
local memory_readvector = memory.readvector
local memory_readstring = memory.readstring

local memory_writeu8     = memory.writeu8
local memory_writei32    = memory.writei32
local memory_writeu64    = memory.writeu64
local memory_writef32    = memory.writef32
local memory_writef64    = memory.writef64
local memory_writevector = memory.writevector
local memory_writestring = memory.writestring

local memory_base = memory.base

-- ───────────── library aliases ─────────────
local vector_create = vector.create
local vector_floor  = vector.floor

local math_floor = math.floor
local math_sqrt  = math.sqrt
local math_sin   = math.sin
local math_cos   = math.cos
local math_acos  = math.acos
local math_asin  = math.asin
local math_atan2 = math.atan2
local math_abs   = math.abs
local math_clamp = math.clamp
local math_max   = math.max
local math_min   = math.min
local math_rad   = math.rad
local math_deg   = math.deg
local math_pi    = math.pi

local os_clock    = os.clock
local task_spawn  = task.spawn
local task_wait   = task.wait
local task_cancel = task.cancel

local Color3_new = Color3.new
local declare    = Instance.declare

-- ───────────── class groups ─────────────
local BASEPART_CLASSES = table.freeze({ "Part", "MeshPart", "UnionOperation", "TrussPart" })
local GUI_CLASSES = table.freeze({
	"Frame", "TextLabel", "TextButton", "TextBox",
	"ImageLabel", "ImageButton", "ScrollingFrame",
})

-- ───────────── structural offsets ─────────────
local OFF_PRIMITIVE  = 0x148 -- BasePart -> Primitive pointer
local OFF_PRIM_FLAGS = 0x1B6 -- Primitive flags byte
local FLAG_ANCHORED  = 0x2
local FLAG_CANTOUCH  = 0x10
local FLAG_CANQUERY  = 0x20
local OFF_TERRAIN_MATCOLORS = 0x2A8

-- ════════════════════════════════════════════════════════════════════
-- conversion helpers  (kept as helpers: complex + reused in many setters)
-- ════════════════════════════════════════════════════════════════════

local function toVector(value: any): vector
	if type(value) == "vector" then
		return value
	end
	local t = typeof(value)
	if t == "Vector3" or (type(value) == "table" and value.X ~= nil) then
		return vector_create(value.X, value.Y, value.Z)
	end
	error("toVector: expected vector or Vector3")
end

local function toColorVector(value: any): vector
	local t = typeof(value)
	if t == "Color3" then
		return vector_create(value.R, value.G, value.B)
	end
	if t == "Vector3" then
		return vector_create(value.X, value.Y, value.Z)
	end
	if type(value) == "vector" then
		return value
	end
	if type(value) == "table" then
		if value.R ~= nil then
			return vector_create(value.R, value.G, value.B)
		end
		if value.X ~= nil then
			return vector_create(value.X, value.Y, value.Z)
		end
		if value[1] ~= nil then
			return vector_create(value[1], value[2], value[3])
		end
	end
	error("toColorVector: cannot convert value to color")
end

-- round each component to 3 decimals (pure SIMD vector math)
local ROUND_HALF = vector_create(0.5, 0.5, 0.5)

@native
local function round3(v: vector): vector
	return vector_floor(v * 1000 + ROUND_HALF) * 0.001
end

-- ───────────── UDim2 / Vector2 memory layout (reused by GUI props) ─────────────
local function readUDim2(self: any, offset: number): (number, number, number, number)
	return memory_readf32(self, offset),
		memory_readi32(self, offset + 0x4),
		memory_readf32(self, offset + 0x8),
		memory_readi32(self, offset + 0xC)
end

local function writeUDim2(self: any, offset: number, sx: number, ox: number, sy: number, oy: number)
	memory_writef32(self, offset, sx)
	memory_writei32(self, offset + 0x4, ox)
	memory_writef32(self, offset + 0x8, sy)
	memory_writei32(self, offset + 0xC, oy)
end

-- ───────────── terrain material colors (reused: 21 props + 2 methods) ─────────────
-- offsets.h MaterialColors.* are already byte offsets into the color buffer.
local function readMaterialColor(self: any, byteOffset: number): Color3
	local ptr = memory_readu64(self, OFF_TERRAIN_MATCOLORS)
	return Color3_new(
		memory_readu8(ptr, byteOffset) / 255,
		memory_readu8(ptr, byteOffset + 1) / 255,
		memory_readu8(ptr, byteOffset + 2) / 255
	)
end

local function writeMaterialColor(self: any, byteOffset: number, color: any)
	local ptr = memory_readu64(self, OFF_TERRAIN_MATCOLORS)
	local c = toColorVector(color)
	memory_writeu8(ptr, byteOffset, math_floor(c.X * 255 + 0.5))
	memory_writeu8(ptr, byteOffset + 1, math_floor(c.Y * 255 + 0.5))
	memory_writeu8(ptr, byteOffset + 2, math_floor(c.Z * 255 + 0.5))
end

-- ───────────── render view (VisualEngine chain) ─────────────
local function getRenderView(): number
	local visualEngine = memory_readu64(memory_base + 0x7FED100) -- VisualEngine.Pointer
	if visualEngine == 0 then
		return 0
	end
	return memory_readu64(visualEngine + 0xBB0) -- VisualEngine.RenderView
end

local function invalidateRender()
	local rv = getRenderView()
	if rv == 0 then
		return
	end
	memory_writeu8(rv + 0x170, 0) -- RenderView.LightingValid
	memory_writeu8(rv + 0x28D, 0) -- RenderView.SkyValid
end

-- ════════════════════════════════════════════════════════════════════
-- declaration factories
-- These run ONCE at load and produce closures that call memory.* directly,
-- so runtime cost is identical to hand-written get/set (the offset is an
-- immutable upvalue captured by value). They remove ~1500 lines of repetition.
-- ════════════════════════════════════════════════════════════════════

local function declareF32(class: any, name: string, offset: number)
	declare({ class = class, name = name, callback = {
		get = function(self: any): number
			return memory_readf32(self, offset)
		end,
		set = function(self: any, value: number)
			memory_writef32(self, offset, value)
		end,
	} })
end

local function declareI32(class: any, name: string, offset: number)
	declare({ class = class, name = name, callback = {
		get = function(self: any): number
			return memory_readi32(self, offset)
		end,
		set = function(self: any, value: number)
			memory_writei32(self, offset, value)
		end,
	} })
end

local function declareBool(class: any, name: string, offset: number)
	declare({ class = class, name = name, callback = {
		get = function(self: any): boolean
			return memory_readu8(self, offset) ~= 0
		end,
		set = function(self: any, value: boolean)
			memory_writeu8(self, offset, if value then 1 else 0)
		end,
	} })
end

local function declareString(class: any, name: string, offset: number)
	declare({ class = class, name = name, callback = {
		get = function(self: any): string
			return memory_readstring(self, offset)
		end,
		set = function(self: any, value: string)
			memory_writestring(self, offset, value)
		end,
	} })
end

-- color stored as a 3-float vector, exposed as Color3
local function declareColor(class: any, name: string, offset: number)
	declare({ class = class, name = name, callback = {
		get = function(self: any): Color3
			local r = memory_readvector(self, offset)
			return Color3_new(r.X, r.Y, r.Z)
		end,
		set = function(self: any, value: any)
			memory_writevector(self, offset, toColorVector(value))
		end,
	} })
end

-- raw Vector3 (velocity / position style)
local function declareVector(class: any, name: string, offset: number)
	declare({ class = class, name = name, callback = {
		get = function(self: any): vector
			return memory_readvector(self, offset)
		end,
		set = function(self: any, value: any)
			memory_writevector(self, offset, toVector(value))
		end,
	} })
end

-- ───────────── ParticleEmitter ─────────────
declareColor("ParticleEmitter", "Color", 0x1A4)

-- ───────────── Atmosphere ─────────────
declareColor("Atmosphere", "Color", 0xD0)
declareF32("Atmosphere", "Decay", 0xDC)
declareF32("Atmosphere", "Density", 0xE8)
declareF32("Atmosphere", "Glare", 0xEC)
declareF32("Atmosphere", "Haze", 0xF0)
declareF32("Atmosphere", "Offset", 0xF4)

-- ───────────── BasePart (direct) ─────────────
declareF32(BASEPART_CLASSES, "Reflectance", 0xEC)
declareColor(BASEPART_CLASSES, "Color", 0x194)
declareBool(BASEPART_CLASSES, "CastShadow", 0xF5)
declareBool(BASEPART_CLASSES, "Locked", 0xF6)
declareBool(BASEPART_CLASSES, "Massless", 0xF7)

declare({ class = BASEPART_CLASSES, name = "Shape", callback = {
	get = function(self: any): number
		return memory_readu8(self, 0x1B1)
	end,
	set = function(self: any, value: number)
		memory_writeu8(self, 0x1B1, value)
	end,
} })

-- ───────────── BasePart (through Primitive) ─────────────
declare({ class = BASEPART_CLASSES, name = "AssemblyLinearVelocity", callback = {
	get = function(self: any): vector
		return round3(memory_readvector(memory_readu64(self, OFF_PRIMITIVE), 0xF8))
	end,
	set = function(self: any, value: any)
		memory_writevector(memory_readu64(self, OFF_PRIMITIVE), 0xF8, toVector(value))
	end,
} })

declare({ class = BASEPART_CLASSES, name = "AssemblyAngularVelocity", callback = {
	get = function(self: any): vector
		return round3(memory_readvector(memory_readu64(self, OFF_PRIMITIVE), 0x104))
	end,
	set = function(self: any, value: any)
		memory_writevector(memory_readu64(self, OFF_PRIMITIVE), 0x104, toVector(value))
	end,
} })

declare({ class = BASEPART_CLASSES, name = "Material", callback = {
	get = function(self: any): number
		return memory_readi32(memory_readu64(self, OFF_PRIMITIVE), 0x236)
	end,
	set = function(self: any, value: number)
		memory_writei32(memory_readu64(self, OFF_PRIMITIVE), 0x236, value)
	end,
} })

-- Anchored / CanQuery / CanTouch are bits in the Primitive flags byte (0x1B6).
local function declarePrimitiveFlag(name: string, mask: number)
	declare({ class = BASEPART_CLASSES, name = name, callback = {
		get = function(self: any): boolean
			local prim = memory_readu64(self, OFF_PRIMITIVE)
			return bit32.band(memory_readu8(prim, OFF_PRIM_FLAGS), mask) ~= 0
		end,
		set = function(self: any, value: boolean)
			local prim = memory_readu64(self, OFF_PRIMITIVE)
			local flags = memory_readu8(prim, OFF_PRIM_FLAGS)
			memory_writeu8(prim, OFF_PRIM_FLAGS,
				if value then bit32.bor(flags, mask) else bit32.band(flags, bit32.bnot(mask)))
		end,
	} })
end

declarePrimitiveFlag("Anchored", FLAG_ANCHORED)
declarePrimitiveFlag("CanQuery", FLAG_CANQUERY)
declarePrimitiveFlag("CanTouch", FLAG_CANTOUCH)

-- ───────────── Humanoid ─────────────
declareF32("Humanoid", "HipHeight", 0x1A0)
declareF32("Humanoid", "MaxSlopeAngle", 0x1B8)
declareF32("Humanoid", "JumpPower", 0x1B0)
declareF32("Humanoid", "JumpHeight", 0x1AC)
declareF32("Humanoid", "HealthDisplayDistance", 0x198)
declareF32("Humanoid", "NameDisplayDistance", 0x1BC)
declareBool("Humanoid", "AutoRotate", 0x1E1)
declareBool("Humanoid", "AutoJumpEnabled", 0x1E0)
declareBool("Humanoid", "BreakJointsOnDeath", 0x1E3)
declareBool("Humanoid", "RequiresNeck", 0x1E9)
declareBool("Humanoid", "UseJumpPower", 0x1EC)
declareBool("Humanoid", "Jump", 0x1E6)
declareI32("Humanoid", "RigType", 0x1CC)

-- WalkSpeed also writes the anti-cheat shadow copy (WalkSpeedCheck @ 0x2A8)
declare({ class = "Humanoid", name = "WalkSpeed", callback = {
	get = function(self: any): number
		return memory_readf32(self, 0x1DC)
	end,
	set = function(self: any, value: number)
		memory_writef32(self, 0x2A8, value)
		memory_writef32(self, 0x1DC, value)
	end,
} })

declare({ class = "Humanoid", name = "MoveDirection", callback = {
	get = function(self: any): vector
		return round3(memory_readvector(self, 0x158))
	end,
	set = function(self: any, value: any)
		memory_writevector(self, 0x158, toVector(value))
	end,
} })

declare({ class = "Humanoid", name = "IsWalking", callback = {
	get = function(self: any): boolean
		return memory_readu8(self, 0x91F) ~= 0
	end,
} })

declare({ class = "Humanoid", name = "FloorMaterial", callback = {
	get = function(self: any): number
		return memory_readi32(self, 0x190)
	end,
} })

declare({ class = "Humanoid", name = "MoveTo", callback = {
	method = function(self: any, target: any)
		local pos: vector
		if type(target) == "vector" or (type(target) == "table" and target.X ~= nil) then
			pos = toVector(target)
		elseif target ~= nil and target.ClassName ~= nil then
			memory_writeu64(self, 0x130, tonumber(target.Data)) -- MoveToPart
			pos = toVector(target.Position)
		else
			error("[Humanoid:MoveTo] target must be a Vector3 or a Part")
		end
		memory_writevector(self, 0x17C, pos) -- WalkToPoint
	end,
} })

-- ───────────── GuiObject ─────────────
declareBool(GUI_CLASSES, "Active", 0x5B8)
declareBool(GUI_CLASSES, "ClipsDescendants", 0x5B9)
declareBool(GUI_CLASSES, "Selectable", 0x5BC)
declareBool(GUI_CLASSES, "Visible", 0x5BD)
declareF32(GUI_CLASSES, "BackgroundTransparency", 0xD0)
declareColor(GUI_CLASSES, "BackgroundColor3", 0x550)
declareColor(GUI_CLASSES, "BorderColor3", 0x55C)
declareF32(GUI_CLASSES, "Rotation", 0xD0)
declareI32(GUI_CLASSES, "LayoutOrder", 0x590)
declareI32(GUI_CLASSES, "ZIndex", 0x5B4)
declareI32(GUI_CLASSES, "BorderSizePixel", 0x57C)

declare({ class = GUI_CLASSES, name = "Position", callback = {
	get = function(self: any)
		local sx, ox, sy, oy = readUDim2(self, 0x520)
		return { X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } }
	end,
	set = function(self: any, value: any)
		writeUDim2(self, 0x520, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	end,
} })

declare({ class = GUI_CLASSES, name = "Size", callback = {
	get = function(self: any)
		local sx, ox, sy, oy = readUDim2(self, 0x540)
		return { X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } }
	end,
	set = function(self: any, value: any)
		writeUDim2(self, 0x540, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	end,
} })

declare({ class = GUI_CLASSES, name = "AnchorPoint", callback = {
	get = function(self: any)
		return { X = memory_readf32(self, 0x568), Y = memory_readf32(self, 0x56C) }
	end,
} })

-- GuiBase2D AbsolutePosition / AbsoluteSize (read-only)
declare({ class = GUI_CLASSES, name = "AbsolutePosition", callback = {
	get = function(self: any)
		return { X = memory_readf32(self, 0xD0), Y = memory_readf32(self, 0xD4) }
	end,
} })

declare({ class = GUI_CLASSES, name = "AbsoluteSize", callback = {
	get = function(self: any)
		return { X = memory_readf32(self, 0xD0), Y = memory_readf32(self, 0xD4) }
	end,
} })

-- ───────────── Text classes (per-class offsets) ─────────────
local TEXT_CONFIG = {
	{ class = "TextLabel", text = 0xB68, color = 0xE60, stroke = 0xE6C },
	{ class = "TextButton", text = 0xDE8, color = 0x10E0, stroke = 0x10EC },
	{ class = "TextBox", text = 0xB60, color = 0xE84, stroke = 0xE90 },
}

for _, cfg in TEXT_CONFIG do
	declareString(cfg.class, "Text", cfg.text)
	declareColor(cfg.class, "TextColor3", cfg.color)
	declareColor(cfg.class, "TextStrokeColor3", cfg.stroke)
	declareF32(cfg.class, "TextSize", 0xD0)
	declareF32(cfg.class, "TextTransparency", 0xD0)
	declareF32(cfg.class, "TextStrokeTransparency", 0xD0)
	declareF32(cfg.class, "LineHeight", 0xD0)
end

-- ───────────── Lighting ─────────────
declareColor("Lighting", "Ambient", 0xE0)
declareF32("Lighting", "Brightness", 0x128)
declareColor("Lighting", "ColorShift_Bottom", 0xEC)
declareColor("Lighting", "ColorShift_Top", 0xF8)
declareF32("Lighting", "ExposureCompensation", 0x134)
declareColor("Lighting", "FogColor", 0x104)
declareF32("Lighting", "FogEnd", 0x13C)
declareF32("Lighting", "FogStart", 0x140)
declareColor("Lighting", "OutdoorAmbient", 0x110)

declare({ class = "Lighting", name = "ClockTime", callback = {
	get = function(self: any): number
		return memory_readf64(self, 0x1C0) / 3600
	end,
	set = function(self: any, value: number)
		memory_writef64(self, 0x1C0, value * 3600)
	end,
} })

-- ───────────── ProximityPrompt ─────────────
declareString("ProximityPrompt", "ActionText", 0xC8)
declareString("ProximityPrompt", "ObjectText", 0xE8)
declareBool("ProximityPrompt", "Enabled", 0x14E)
declareF32("ProximityPrompt", "HoldDuration", 0x138)
declareF32("ProximityPrompt", "MaxActivationDistance", 0x140)
declareBool("ProximityPrompt", "RequiresLineOfSight", 0x14F)
declareI32("ProximityPrompt", "KeyboardKeyCode", 0x13C)

-- ───────────── Sky ─────────────
declareF32("Sky", "MoonAngularSize", 0x25C)
declareF32("Sky", "SunAngularSize", 0x264)
declareI32("Sky", "StarCount", 0x260)
declareString("Sky", "MoonTextureId", 0xE0)
declareString("Sky", "SunTextureId", 0x230)

-- Skybox faces: write the new id into the existing string buffer, then force a
-- render-view revalidation so the change is picked up.
local SKYBOX_FACES = {
	SkyboxBk = 0x110, SkyboxDn = 0x140, SkyboxFt = 0x170,
	SkyboxLf = 0x1A0, SkyboxRt = 0x1D0, SkyboxUp = 0x200,
}

for faceName, faceOffset in SKYBOX_FACES do
	declare({ class = "Sky", name = faceName, callback = {
		get = function(self: any): string
			return memory_readstring(self, faceOffset)
		end,
		set = function(self: any, value: string)
			invalidateRender()
			local pointer = memory_readu64(self, faceOffset)
			local buf = buffer.create(#value + 1)
			buffer.writestring(buf, 0, value)
			memory.writebuffer(pointer, buf)
			invalidateRender()
		end,
	} })
end

-- ───────────── BloomEffect ─────────────
declareF32("BloomEffect", "Intensity", 0xD0)
declareF32("BloomEffect", "Size", 0xD4)
declareF32("BloomEffect", "Threshold", 0xD8)

-- ───────────── ColorCorrectionEffect ─────────────
declareColor("ColorCorrectionEffect", "TintColor", 0xD0)
declareF32("ColorCorrectionEffect", "Brightness", 0xDC)
declareF32("ColorCorrectionEffect", "Contrast", 0xE0)

-- ───────────── DepthOfFieldEffect ─────────────
declareF32("DepthOfFieldEffect", "FocusDistance", 0xD4)
declareF32("DepthOfFieldEffect", "InFocusRadius", 0xD8)
declareF32("DepthOfFieldEffect", "NearIntensity", 0xDC)

-- ───────────── Highlight ─────────────
declareColor("Highlight", "FillColor", 0xE0)
declareColor("Highlight", "OutlineColor", 0xEC)
declareF32("Highlight", "FillTransparency", 0xFC)
declareF32("Highlight", "OutlineTransparency", 0x104)
declareI32("Highlight", "DepthMode", 0xF8)

-- ───────────── Tool ─────────────
declareBool("Tool", "CanBeDropped", 0x4C8)
declareBool("Tool", "Enabled", 0x4C9)
declareBool("Tool", "ManualActivationOnly", 0x4CA)
declareBool("Tool", "RequiresHandle", 0x4CB)
declareString("Tool", "ToolTip", 0x478)
declareVector("Tool", "GripPos", 0x4BC)

-- ───────────── Camera ─────────────
declare({ class = "Camera", name = "FieldOfView", callback = {
	get = function(self: any): number
		return math_deg(memory_readf32(self, 0x160))
	end,
	set = function(self: any, value: number)
		memory_writef32(self, 0x160, math_rad(value))
	end,
} })

-- ───────────── AnimationTrack ─────────────
declareBool("AnimationTrack", "Looped", 0xF5)
declareF32("AnimationTrack", "Speed", 0xE4)

declare({ class = "AnimationTrack", name = "Animation", callback = {
	get = function(self: any): number?
		local ptr = memory_readu64(self, 0xD0)
		return if ptr ~= 0 then ptr else nil
	end,
} })

declare({ class = "AnimationTrack", name = "Animator", callback = {
	get = function(self: any): number?
		local ptr = memory_readu64(self, 0x118)
		return if ptr ~= 0 then ptr else nil
	end,
} })

declare({ class = "AnimationTrack", name = "IsPlaying", callback = {
	get = function(self: any): boolean
		return memory_readu8(self, 0xF4) ~= 0
	end,
} })

-- ───────────── Animation ─────────────
declareString("Animation", "AnimationId", 0xD0)

-- ───────────── Animator ─────────────
local ANIM_TRACK_MT = { __tostring = function(t: any): string return t.AnimationId end }

declare({ class = "Animator", name = "GetPlayingAnimationTracks", callback = {
	method = function(self: any)
		local head = memory_readu64(self, 0x868) -- Animator.ActiveAnimations
		if head == 0 then
			return {}
		end

		local result = {}
		local node = memory_readu64(head)
		local count = 0

		while node ~= 0 and node ~= head and count < 100 do
			count += 1
			local trackPtr = memory_readu64(node + 0x10)
			if trackPtr ~= 0 then
				local animationPtr = memory_readu64(trackPtr, 0xD0)
				if animationPtr ~= 0 then
					local animId = memory_readstring(animationPtr, 0xD0)
					result[#result + 1] = setmetatable({
						AnimationId = animId,
						IsPlaying = memory_readu8(trackPtr, 0xF4) ~= 0,
						Speed = memory_readf32(trackPtr, 0xE4),
						Looped = memory_readu8(trackPtr, 0xF5) ~= 0,
						Animation = { AnimationId = animId },
					}, ANIM_TRACK_MT)
				end
			end
			node = memory_readu64(node)
		end

		return result
	end,
} })

-- ───────────── Terrain ─────────────
declareF32("Terrain", "GrassLength", 0x1F8)
declareColor("Terrain", "WaterColor", 0x1E8)
declareF32("Terrain", "WaterReflectance", 0x200)
declareF32("Terrain", "WaterTransparency", 0x204)
declareF32("Terrain", "WaterWaveSize", 0x208)
declareF32("Terrain", "WaterWaveSpeed", 0x20C)

-- MaterialColors values are byte offsets into the terrain color buffer.
local MATERIAL_COLORS = {
	Asphalt = 0x30, Basalt = 0x27, Brick = 0xF, Cobblestone = 0x33,
	Concrete = 0xC, CrackedLava = 0x2D, Glacier = 0x1B, Grass = 0x6,
	Ground = 0x2A, Ice = 0x36, LeafyGrass = 0x39, Limestone = 0x3F,
	Mud = 0x24, Pavement = 0x42, Rock = 0x18, Salt = 0x3C,
	Sand = 0x12, Sandstone = 0x21, Slate = 0x9, Snow = 0x1E, WoodPlanks = 0x15,
}

for matName, byteOffset in MATERIAL_COLORS do
	declare({ class = "Terrain", name = matName .. "Color", callback = {
		get = function(self: any): Color3
			return readMaterialColor(self, byteOffset)
		end,
		set = function(self: any, value: any)
			writeMaterialColor(self, byteOffset, value)
		end,
	} })
end

declare({ class = "Terrain", name = "GetMaterialColor", callback = {
	method = function(self: any, materialName: string): Color3
		local byteOffset = MATERIAL_COLORS[materialName]
		if byteOffset == nil then
			error(`[Terrain:GetMaterialColor] invalid material name: {materialName}`)
		end
		return readMaterialColor(self, byteOffset)
	end,
} })

declare({ class = "Terrain", name = "SetMaterialColor", callback = {
	method = function(self: any, materialName: string, color: any)
		local byteOffset = MATERIAL_COLORS[materialName]
		if byteOffset == nil then
			error(`[Terrain:SetMaterialColor] invalid material name: {materialName}`)
		end
		writeMaterialColor(self, byteOffset, color)
	end,
} })

-- ════════════════════════════════════════════════════════════════════
-- CFrame math (declared on Instance — operates on a part's CFrame basis)
-- Pure helpers so the methods compose correctly on intermediate results.
-- ════════════════════════════════════════════════════════════════════
local vector_dot = vector.dot

type CF = { Position: vector, RightVector: vector, UpVector: vector, LookVector: vector }

local function readCF(x: any): CF
	return {
		Position = x.Position,
		RightVector = x.RightVector,
		UpVector = x.UpVector,
		LookVector = x.LookVector,
	}
end

local function cfInverse(cf: CF): CF
	local p, r, u, l = cf.Position, cf.RightVector, cf.UpVector, cf.LookVector
	local nr = vector_create(r.X, u.X, l.X)
	local nu = vector_create(r.Y, u.Y, l.Y)
	local nl = vector_create(r.Z, u.Z, l.Z)
	return {
		Position = vector_create(-vector_dot(p, nr), -vector_dot(p, nu), -vector_dot(p, nl)),
		RightVector = nr, UpVector = nu, LookVector = nl,
	}
end

local function cfMul(a: CF, b: CF): CF
	local ar, au, al, ap = a.RightVector, a.UpVector, a.LookVector, a.Position
	local br, bu, bl, bp = b.RightVector, b.UpVector, b.LookVector, b.Position
	return {
		Position = vector_create(
			ap.X + ar.X * bp.X + au.X * bp.Y + al.X * bp.Z,
			ap.Y + ar.Y * bp.X + au.Y * bp.Y + al.Y * bp.Z,
			ap.Z + ar.Z * bp.X + au.Z * bp.Y + al.Z * bp.Z),
		RightVector = vector_create(
			ar.X * br.X + au.X * br.Y + al.X * br.Z,
			ar.Y * br.X + au.Y * br.Y + al.Y * br.Z,
			ar.Z * br.X + au.Z * br.Y + al.Z * br.Z),
		UpVector = vector_create(
			ar.X * bu.X + au.X * bu.Y + al.X * bu.Z,
			ar.Y * bu.X + au.Y * bu.Y + al.Y * bu.Z,
			ar.Z * bu.X + au.Z * bu.Y + al.Z * bu.Z),
		LookVector = vector_create(
			ar.X * bl.X + au.X * bl.Y + al.X * bl.Z,
			ar.Y * bl.X + au.Y * bl.Y + al.Y * bl.Z,
			ar.Z * bl.X + au.Z * bl.Y + al.Z * bl.Z),
	}
end

local function cfToAxisAngle(cf: CF): (vector, number)
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local angle = math_acos(math_clamp((r.X + u.Y + l.Z - 1) / 2, -1, 1))
	if angle < 0.0001 then
		return vector_create(0, 1, 0), 0
	end
	local s = 2 * math_sin(angle)
	return vector_create((u.Z - l.Y) / s, (l.X - r.Z) / s, (r.Y - u.X) / s), angle
end

declare({ class = "Instance", name = "Inverse", callback = {
	method = function(self: any): CF
		return cfInverse(readCF(self))
	end,
} })

declare({ class = "Instance", name = "ToWorldSpace", callback = {
	method = function(self: any, cf: any): CF
		return cfMul(readCF(self), readCF(cf))
	end,
} })

declare({ class = "Instance", name = "ToObjectSpace", callback = {
	method = function(self: any, cf: any): CF
		return cfMul(cfInverse(readCF(self)), readCF(cf))
	end,
} })

declare({ class = "Instance", name = "PointToWorldSpace", callback = {
	method = function(self: any, point: any): vector
		local p = toVector(point)
		local cf = readCF(self)
		local r, u, l, pos = cf.RightVector, cf.UpVector, cf.LookVector, cf.Position
		return vector_create(
			pos.X + r.X * p.X + u.X * p.Y + l.X * p.Z,
			pos.Y + r.Y * p.X + u.Y * p.Y + l.Y * p.Z,
			pos.Z + r.Z * p.X + u.Z * p.Y + l.Z * p.Z)
	end,
} })

declare({ class = "Instance", name = "PointToObjectSpace", callback = {
	method = function(self: any, point: any): vector
		local p = toVector(point)
		local cf = readCF(self)
		local r, u, l, pos = cf.RightVector, cf.UpVector, cf.LookVector, cf.Position
		local rel = vector_create(p.X - pos.X, p.Y - pos.Y, p.Z - pos.Z)
		return vector_create(vector_dot(rel, r), vector_dot(rel, u), vector_dot(rel, l))
	end,
} })

declare({ class = "Instance", name = "VectorToWorldSpace", callback = {
	method = function(self: any, vec: any): vector
		local v = toVector(vec)
		local cf = readCF(self)
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		return vector_create(
			r.X * v.X + u.X * v.Y + l.X * v.Z,
			r.Y * v.X + u.Y * v.Y + l.Y * v.Z,
			r.Z * v.X + u.Z * v.Y + l.Z * v.Z)
	end,
} })

declare({ class = "Instance", name = "VectorToObjectSpace", callback = {
	method = function(self: any, vec: any): vector
		local v = toVector(vec)
		local cf = readCF(self)
		return vector_create(
			vector_dot(v, cf.RightVector),
			vector_dot(v, cf.UpVector),
			vector_dot(v, cf.LookVector))
	end,
} })

declare({ class = "Instance", name = "GetComponents", callback = {
	method = function(self: any)
		local p, r, u, l = self.Position, self.RightVector, self.UpVector, self.LookVector
		return p.X, p.Y, p.Z, r.X, u.X, l.X, r.Y, u.Y, l.Y, r.Z, u.Z, l.Z
	end,
} })

declare({ class = "Instance", name = "ToEulerAnglesXYZ", callback = {
	method = function(self: any)
		local right, up, look = self.RightVector, self.UpVector, self.LookVector
		if look.Y < 0.99999 then
			if look.Y > -0.99999 then
				return math_atan2(look.Z, math_sqrt(look.X * look.X + look.Y * look.Y)),
					math_atan2(-look.X, look.Y),
					math_atan2(right.Y, up.Y)
			end
			return -math_pi / 2, -math_atan2(right.Z, right.X), 0
		end
		return math_pi / 2, math_atan2(right.Z, right.X), 0
	end,
} })

declare({ class = "Instance", name = "ToEulerAnglesYXZ", callback = {
	method = function(self: any)
		local right, up, look = self.RightVector, self.UpVector, self.LookVector
		if look.X < 0.99999 then
			if look.X > -0.99999 then
				return math_atan2(look.Y, look.Z),
					math_asin(-look.X),
					math_atan2(right.X, up.X)
			end
			return -math_atan2(-right.Y, right.Z), math_pi / 2, 0
		end
		return math_atan2(-right.Y, right.Z), -math_pi / 2, 0
	end,
} })

declare({ class = "Instance", name = "ToOrientation", callback = {
	method = function(self: any)
		local x, y, z = self:ToEulerAnglesYXZ()
		return math_deg(x), math_deg(y), math_deg(z)
	end,
} })

declare({ class = "Instance", name = "ToAxisAngle", callback = {
	method = function(self: any): (vector, number)
		return cfToAxisAngle(readCF(self))
	end,
} })

declare({ class = "Instance", name = "Lerp", callback = {
	method = function(self: any, goal: any, alpha: number): CF
		alpha = math_clamp(alpha, 0, 1)
		local a = readCF(self)
		local b = readCF(goal)

		local p0, p1 = a.Position, b.Position
		local np = vector_create(
			p0.X + (p1.X - p0.X) * alpha,
			p0.Y + (p1.Y - p0.Y) * alpha,
			p0.Z + (p1.Z - p0.Z) * alpha)

		local axis, angle = cfToAxisAngle(cfMul(cfInverse(a), b))
		if angle < 0.0001 then
			return { Position = np, RightVector = a.RightVector, UpVector = a.UpVector, LookVector = a.LookVector }
		end

		local sa = angle * alpha
		local c = math_cos(sa)
		local s = math_sin(sa)
		local t = 1 - c
		local x, y, z = axis.X, axis.Y, axis.Z

		local m11, m12, m13 = t * x * x + c, t * x * y - s * z, t * x * z + s * y
		local m21, m22, m23 = t * x * y + s * z, t * y * y + c, t * y * z - s * x
		local m31, m32, m33 = t * x * z - s * y, t * y * z + s * x, t * z * z + c

		local r0, u0, l0 = a.RightVector, a.UpVector, a.LookVector
		return {
			Position = np,
			RightVector = vector_create(
				m11 * r0.X + m12 * u0.X + m13 * l0.X,
				m11 * r0.Y + m12 * u0.Y + m13 * l0.Y,
				m11 * r0.Z + m12 * u0.Z + m13 * l0.Z),
			UpVector = vector_create(
				m21 * r0.X + m22 * u0.X + m23 * l0.X,
				m21 * r0.Y + m22 * u0.Y + m23 * l0.Y,
				m21 * r0.Z + m22 * u0.Z + m23 * l0.Z),
			LookVector = vector_create(
				m31 * r0.X + m32 * u0.X + m33 * l0.X,
				m31 * r0.Y + m32 * u0.Y + m33 * l0.Y,
				m31 * r0.Z + m32 * u0.Z + m33 * l0.Z),
		}
	end,
} })

declare({ class = "Instance", name = "Orthonormalize", callback = {
	method = function(self: any): CF
		local pos, up, look = self.Position, self.UpVector, self.LookVector
		local lm = math_sqrt(look.X * look.X + look.Y * look.Y + look.Z * look.Z)
		if lm > 0 then
			look = vector_create(look.X / lm, look.Y / lm, look.Z / lm)
		end
		local nr = vector_create(
			up.Y * look.Z - up.Z * look.Y,
			up.Z * look.X - up.X * look.Z,
			up.X * look.Y - up.Y * look.X)
		local rm = math_sqrt(nr.X * nr.X + nr.Y * nr.Y + nr.Z * nr.Z)
		if rm > 0 then
			nr = vector_create(nr.X / rm, nr.Y / rm, nr.Z / rm)
		end
		local nu = vector_create(
			look.Y * nr.Z - look.Z * nr.Y,
			look.Z * nr.X - look.X * nr.Z,
			look.X * nr.Y - look.Y * nr.X)
		return { Position = pos, RightVector = nr, UpVector = nu, LookVector = look }
	end,
} })

declare({ class = "Instance", name = "FuzzyEq", callback = {
	method = function(self: any, other: any, epsilon: number?): boolean
		local e = epsilon or 0.00001
		local a = readCF(self)
		local b = readCF(other)
		local ap, bp = a.Position, b.Position
		if math_abs(ap.X - bp.X) > e or math_abs(ap.Y - bp.Y) > e or math_abs(ap.Z - bp.Z) > e then
			return false
		end
		local ar, br = a.RightVector, b.RightVector
		local au, bu = a.UpVector, b.UpVector
		local al, bl = a.LookVector, b.LookVector
		return math_abs(ar.X - br.X) <= e and math_abs(ar.Y - br.Y) <= e and math_abs(ar.Z - br.Z) <= e
			and math_abs(au.X - bu.X) <= e and math_abs(au.Y - bu.Y) <= e and math_abs(au.Z - bu.Z) <= e
			and math_abs(al.X - bl.X) <= e and math_abs(al.Y - bl.Y) <= e and math_abs(al.Z - bl.Z) <= e
	end,
} })

declare({ class = "Instance", name = "AngleBetween", callback = {
	method = function(self: any, other: any): number
		local _, angle = cfToAxisAngle(cfMul(cfInverse(readCF(self)), readCF(other)))
		return angle
	end,
} })

-- ───────────── Model:GetBoundingBox ─────────────
local BBOX_PARTS = { Part = true, MeshPart = true, UnionOperation = true, TrussPart = true }

declare({ class = "Model", name = "GetBoundingBox", callback = {
	method = function(self: any)
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

		local function scan(parent: any)
			for _, child in parent:GetChildren() do
				if BBOX_PARTS[child.ClassName] then
					local pos, size = child.Position, child.Size
					local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
					minX = math_min(minX, pos.X - hx)
					minY = math_min(minY, pos.Y - hy)
					minZ = math_min(minZ, pos.Z - hz)
					maxX = math_max(maxX, pos.X + hx)
					maxY = math_max(maxY, pos.Y + hy)
					maxZ = math_max(maxZ, pos.Z + hz)
				end
				scan(child)
			end
		end
		scan(self)

		local idR, idU, idL = vector_create(1, 0, 0), vector_create(0, 1, 0), vector_create(0, 0, 1)
		if minX == math.huge then
			return { Position = vector_create(0, 0, 0), RightVector = idR, UpVector = idU, LookVector = idL },
				vector_create(0, 0, 0)
		end
		return {
			Position = vector_create((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5),
			RightVector = idR, UpVector = idU, LookVector = idL,
		}, vector_create(maxX - minX, maxY - minY, maxZ - minZ)
	end,
} })

-- ───────────── Instance:GetFullName ─────────────
declare({ class = "Instance", name = "GetFullName", callback = {
	method = function(self: any): string
		local parts = {}
		local current = self
		while current ~= nil do
			if current.ClassName == "DataModel" then
				parts[#parts + 1] = "game"
				break
			end
			parts[#parts + 1] = current.Name
			current = current.Parent
		end

		local n = #parts
		if n == 0 then
			return "game"
		end
		for i = 1, n // 2 do
			parts[i], parts[n - i + 1] = parts[n - i + 1], parts[i]
		end
		return table.concat(parts, ".")
	end,
} })

-- ════════════════════════════════════════════════════════════════════
-- Signal (minimal — only used for Tween.Completed)
-- ════════════════════════════════════════════════════════════════════
local RobloxSignal = {}
do
	RobloxSignal.__index = RobloxSignal

	function RobloxSignal.new(): any
		return setmetatable({ _listeners = {}, _waiters = {} }, RobloxSignal)
	end

	function RobloxSignal.Connect(self: any, callback: (...any) -> ()): any
		local node = { fn = callback }
		local listeners = self._listeners
		listeners[#listeners + 1] = node
		return {
			Connected = true,
			Disconnect = function(conn: any)
				conn.Connected = false
				node.fn = nil
			end,
		}
	end

	function RobloxSignal.Once(self: any, callback: (...any) -> ()): any
		local conn
		conn = self:Connect(function(...)
			conn:Disconnect()
			callback(...)
		end)
		return conn
	end

	function RobloxSignal.Fire(self: any, ...: any)
		local listeners = self._listeners
		for i = #listeners, 1, -1 do
			local node = listeners[i]
			if node.fn == nil then
				local n = #listeners
				listeners[i] = listeners[n]
				listeners[n] = nil
			else
				task_spawn(node.fn, ...)
			end
		end
		local waiters = self._waiters
		if #waiters > 0 then
			self._waiters = {}
			for _, co in waiters do
				task_spawn(co, ...)
			end
		end
	end

	function RobloxSignal.Wait(self: any): ...any
		local waiters = self._waiters
		waiters[#waiters + 1] = coroutine.running()
		return coroutine.yield()
	end
end

-- ════════════════════════════════════════════════════════════════════
-- TweenService
-- ════════════════════════════════════════════════════════════════════

local MIN_FRAME      = 1 / 240
local MAX_FRAME      = 1 / 30
local UPDATE_INTERVAL = 1 / 144

-- ───────────── easing ─────────────
local EasingLibrary: { [string]: any } = {}

EasingLibrary.Linear = function(t: number): number
	return t
end

EasingLibrary.Quad = {
	In = function(t: number): number return t * t end,
	Out = function(t: number): number return 1 - (1 - t) * (1 - t) end,
	InOut = function(t: number): number
		return if t < 0.5 then 2 * t * t else 1 - (-2 * t + 2) ^ 2 / 2
	end,
}

EasingLibrary.Cubic = {
	In = function(t: number): number return t * t * t end,
	Out = function(t: number): number return 1 - (1 - t) ^ 3 end,
	InOut = function(t: number): number
		return if t < 0.5 then 4 * t * t * t else 1 - (-2 * t + 2) ^ 3 / 2
	end,
}

EasingLibrary.Quart = {
	In = function(t: number): number return t * t * t * t end,
	Out = function(t: number): number return 1 - (1 - t) ^ 4 end,
	InOut = function(t: number): number
		return if t < 0.5 then 8 * t * t * t * t else 1 - (-2 * t + 2) ^ 4 / 2
	end,
}

EasingLibrary.Quint = {
	In = function(t: number): number return t ^ 5 end,
	Out = function(t: number): number return 1 - (1 - t) ^ 5 end,
	InOut = function(t: number): number
		return if t < 0.5 then 16 * t ^ 5 else 1 - (-2 * t + 2) ^ 5 / 2
	end,
}

EasingLibrary.Sine = {
	In = function(t: number): number return 1 - math_cos((t * math_pi) / 2) end,
	Out = function(t: number): number return math_sin((t * math_pi) / 2) end,
	InOut = function(t: number): number return -(math_cos(math_pi * t) - 1) / 2 end,
}

EasingLibrary.Expo = {
	In = function(t: number): number return if t == 0 then 0 else 2 ^ (10 * t - 10) end,
	Out = function(t: number): number return if t == 1 then 1 else 1 - 2 ^ (-10 * t) end,
	InOut = function(t: number): number
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return if t < 0.5 then 2 ^ (20 * t - 10) / 2 else (2 - 2 ^ (-20 * t + 10)) / 2
	end,
}

EasingLibrary.Circ = {
	In = function(t: number): number return 1 - math_sqrt(1 - t * t) end,
	Out = function(t: number): number return math_sqrt(1 - (t - 1) ^ 2) end,
	InOut = function(t: number): number
		return if t < 0.5 then (1 - math_sqrt(1 - (2 * t) ^ 2)) / 2 else (math_sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
	end,
}

EasingLibrary.Back = {
	In = function(t: number): number
		return 2.70158 * t * t * t - 1.70158 * t * t
	end,
	Out = function(t: number): number
		return 1 + 2.70158 * (t - 1) ^ 3 + 1.70158 * (t - 1) ^ 2
	end,
	InOut = function(t: number): number
		local c2 = 1.70158 * 1.525
		return if t < 0.5
			then ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) / 2
			else ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
	end,
}

EasingLibrary.Elastic = {
	In = function(t: number): number
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return -(2 ^ (10 * t - 10)) * math_sin((t * 10 - 10.75) * (2 * math_pi) / 3)
	end,
	Out = function(t: number): number
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return 2 ^ (-10 * t) * math_sin((t * 10 - 0.75) * (2 * math_pi) / 3) + 1
	end,
	InOut = function(t: number): number
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		local c5 = (2 * math_pi) / 4.5
		return if t < 0.5
			then -(2 ^ (20 * t - 10) * math_sin((20 * t - 11.125) * c5)) / 2
			else (2 ^ (-20 * t + 10) * math_sin((20 * t - 11.125) * c5)) / 2 + 1
	end,
}

EasingLibrary.Bounce = {}
EasingLibrary.Bounce.Out = function(t: number): number
	local n1, d1 = 7.5625, 2.75
	if t < 1 / d1 then
		return n1 * t * t
	elseif t < 2 / d1 then
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elseif t < 2.5 / d1 then
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	end
	t -= 2.625 / d1
	return n1 * t * t + 0.984375
end
EasingLibrary.Bounce.In = function(t: number): number
	return 1 - EasingLibrary.Bounce.Out(1 - t)
end
EasingLibrary.Bounce.InOut = function(t: number): number
	return if t < 0.5
		then (1 - EasingLibrary.Bounce.Out(1 - 2 * t)) / 2
		else (1 + EasingLibrary.Bounce.Out(2 * t - 1)) / 2
end

local function getEasingFunction(style: string, direction: string): (number) -> number
	if style == "Linear" then
		return EasingLibrary.Linear
	end
	local group = EasingLibrary[style]
	if group == nil then
		return EasingLibrary.Linear
	end
	if type(group) == "function" then
		return group
	end
	return group[direction] or group.Out or EasingLibrary.Linear
end

-- ───────────── CFrame interpolation (quaternion slerp) ─────────────
local function quatFromCF(cf: CF): (number, number, number, number)
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local trace = r.X + u.Y + l.Z
	if trace > 0 then
		local s = math_sqrt(1 + trace) * 2
		return (u.Z - l.Y) / s, (l.X - r.Z) / s, (r.Y - u.X) / s, 0.25 * s
	elseif r.X > u.Y and r.X > l.Z then
		local s = math_sqrt(1 + r.X - u.Y - l.Z) * 2
		return 0.25 * s, (u.X + r.Y) / s, (l.X + r.Z) / s, (u.Z - l.Y) / s
	elseif u.Y > l.Z then
		local s = math_sqrt(1 + u.Y - r.X - l.Z) * 2
		return (u.X + r.Y) / s, 0.25 * s, (l.Y + u.Z) / s, (l.X - r.Z) / s
	end
	local s = math_sqrt(1 + l.Z - r.X - u.Y) * 2
	return (l.X + r.Z) / s, (l.Y + u.Z) / s, 0.25 * s, (r.Y - u.X) / s
end

@native
local function quatSlerp(x1: number, y1: number, z1: number, w1: number,
	x2: number, y2: number, z2: number, w2: number, a: number): (number, number, number, number)
	local dot = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	if dot < 0 then
		x2, y2, z2, w2, dot = -x2, -y2, -z2, -w2, -dot
	end
	if dot > 0.9995 then
		local x, y, z, w = x1 + (x2 - x1) * a, y1 + (y2 - y1) * a, z1 + (z2 - z1) * a, w1 + (w2 - w1) * a
		local len = math_sqrt(x * x + y * y + z * z + w * w)
		if len > 0 then
			return x / len, y / len, z / len, w / len
		end
		return x, y, z, w
	end
	local theta = math_acos(math_clamp(dot, -1, 1))
	local st = math_sin(theta)
	local s1 = math_sin((1 - a) * theta) / st
	local s2 = math_sin(a * theta) / st
	return s1 * x1 + s2 * x2, s1 * y1 + s2 * y2, s1 * z1 + s2 * z2, s1 * w1 + s2 * w2
end

local function interpolateCFrame(a: CF, b: CF, alpha: number): any
	local p0, p1 = a.Position, b.Position
	local np = vector_create(
		p0.X + (p1.X - p0.X) * alpha,
		p0.Y + (p1.Y - p0.Y) * alpha,
		p0.Z + (p1.Z - p0.Z) * alpha)

	local x1, y1, z1, w1 = quatFromCF(a)
	local x2, y2, z2, w2 = quatFromCF(b)
	local x, y, z, w = quatSlerp(x1, y1, z1, w1, x2, y2, z2, w2, alpha)

	-- basis from quaternion (only up + look needed for lookAt)
	local x2_, y2_, z2_ = x + x, y + y, z + z
	local xx, xy, xz = x * x2_, x * y2_, x * z2_
	local yy, yz = y * y2_, y * z2_
	local zz = z * z2_
	local wx, wy, wz = w * x2_, w * y2_, w * z2_
	local up = vector_create(xy - wz, 1 - (xx + zz), yz + wx)
	local look = vector_create(xz + wy, yz - wx, 1 - (xx + yy))
	return CFrame.lookAt(np, vector_create(np.X - look.X, np.Y - look.Y, np.Z - look.Z), up)
end

-- ───────────── value classification ─────────────
local function classify(value: any): string
	local t = type(value)
	if t == "number" then return "number" end
	if t == "vector" then return "vector" end
	local tof = typeof(value)
	if tof == "Vector3" then return "vector" end
	if tof == "Color3" then return "color3" end
	if t == "table" then
		if value.Position ~= nil and (value.RightVector ~= nil or value.LookVector ~= nil or value.UpVector ~= nil) then
			return "cframe"
		end
		if value.X ~= nil and value.Y ~= nil and value.Z ~= nil then
			return "vector"
		end
	end
	return "other"
end

-- ───────────── TweenInfo ─────────────
local TweenInfo = {}
TweenInfo.__index = TweenInfo

local function enumName(v: any): string
	if type(v) == "string" then return v end
	if v == nil then return "" end
	local s = tostring(v)
	return string.match(s, "%.([^%.]+)$") or s
end

function TweenInfo.new(time: number?, style: any?, direction: any?,
	repeatCount: number?, reverses: boolean?, delayTime: number?): any
	local s = enumName(style)
	if s == "" then s = "Quad" end
	local d = enumName(direction)
	if d == "" then d = "Out" end
	return setmetatable({
		Time = time or 1,
		EasingStyle = s,
		EasingDirection = d,
		RepeatCount = repeatCount or 0,
		Reverses = reverses or false,
		DelayTime = delayTime or 0,
	}, TweenInfo)
end

-- ───────────── registry + update loop ─────────────
type TweenProp = { name: string, kind: string, target: any, start: any }

local activeTweens: { any } = {}
local loopRunning = false

local function unregister(tween: any)
	for i = #activeTweens, 1, -1 do
		if activeTweens[i] == tween then
			local n = #activeTweens
			activeTweens[i] = activeTweens[n]
			activeTweens[n] = nil
			break
		end
	end
end

local function processTweens(dt: number)
	dt = math_clamp(dt, MIN_FRAME, MAX_FRAME)
	local i = 1
	while i <= #activeTweens do
		local tween = activeTweens[i]
		local ok, alive = pcall(tween._step, tween, dt)
		if ok and alive then
			i += 1
		else
			local n = #activeTweens
			activeTweens[i] = activeTweens[n]
			activeTweens[n] = nil
		end
	end
end

local function startLoop()
	if loopRunning then return end
	loopRunning = true
	task_spawn(function()
		local prev = os_clock()
		while #activeTweens > 0 do
			local now = os_clock()
			processTweens(now - prev)
			prev = now
			task_wait(UPDATE_INTERVAL)
		end
		loopRunning = false
	end)
end

local function register(tween: any)
	activeTweens[#activeTweens + 1] = tween
	startLoop()
end

-- ───────────── Tween ─────────────
local Tween = {}
Tween.__index = Tween

function Tween.new(instance: any, info: any, properties: { [string]: any }): any
	assert(instance ~= nil, "[TweenService] instance cannot be nil")
	if type(properties) ~= "table" then
		error("[TweenService] properties must be a table")
	end

	local realInfo
	if getmetatable(info) == TweenInfo then
		realInfo = info
	elseif type(info) == "table" then
		realInfo = TweenInfo.new(info.Time, info.EasingStyle, info.EasingDirection,
			info.RepeatCount, info.Reverses, info.DelayTime)
	else
		realInfo = TweenInfo.new(if type(info) == "number" then info else nil)
	end

	local props: { TweenProp } = {}
	for name, target in properties do
		local kind = classify(target)
		local stored: any
		if kind == "vector" then
			stored = toVector(target)
		elseif kind == "color3" then
			stored = toColorVector(target)
		elseif kind == "cframe" then
			stored = readCF(target)
		else
			stored = target
		end
		props[#props + 1] = { name = name, kind = kind, target = stored, start = nil }
	end

	return setmetatable({
		Instance = instance,
		Info = realInfo,
		Completed = RobloxSignal.new(),
		_props = props,
		_active = false,
		_elapsed = 0,
		_easing = EasingLibrary.Linear,
	}, Tween)
end

function Tween.Play(self: any)
	if self._active then return end
	local inst = self.Instance
	local props = self._props
	for i = 1, #props do
		local prop = props[i]
		local cur = inst[prop.name]
		local kind = prop.kind
		if kind == "vector" then
			prop.start = toVector(cur)
		elseif kind == "color3" then
			prop.start = toColorVector(cur)
		elseif kind == "cframe" then
			prop.start = readCF(cur)
		else
			prop.start = cur
		end
	end
	local info = self.Info
	self._easing = getEasingFunction(info.EasingStyle, info.EasingDirection)
	self._elapsed = 0
	self._active = true
	register(self)
end

function Tween.Pause(self: any)
	if not self._active then return end
	self._active = false
	unregister(self)
end

function Tween.Resume(self: any)
	if self._active then return end
	self._active = true
	register(self)
end

function Tween.Stop(self: any)
	self._active = false
	unregister(self)
end

function Tween._applyFinal(self: any, useStart: boolean)
	local inst = self.Instance
	local props = self._props
	for i = 1, #props do
		local prop = props[i]
		local v = if useStart then prop.start else prop.target
		if v == nil then continue end
		local kind = prop.kind
		if kind == "color3" then
			inst[prop.name] = Color3_new(v.X, v.Y, v.Z)
		elseif kind == "cframe" then
			inst[prop.name] = interpolateCFrame(v, v, 0)
		else
			inst[prop.name] = v
		end
	end
end

function Tween.Cancel(self: any)
	self:Stop()
	self._elapsed = 0
	if self._props[1] ~= nil and self._props[1].start ~= nil then
		self:_applyFinal(true)
	end
end

function Tween._apply(self: any, alpha: number)
	local inst = self.Instance
	local props = self._props
	for i = 1, #props do
		local prop = props[i]
		local s = prop.start
		if s == nil then continue end
		local kind = prop.kind
		if kind == "number" then
			inst[prop.name] = s + (prop.target - s) * alpha
		elseif kind == "vector" then
			inst[prop.name] = s + (prop.target - s) * alpha
		elseif kind == "color3" then
			local c = s + (prop.target - s) * alpha
			inst[prop.name] = Color3_new(c.X, c.Y, c.Z)
		elseif kind == "cframe" then
			inst[prop.name] = interpolateCFrame(s, prop.target, alpha)
		end
	end
end

function Tween._step(self: any, dt: number): boolean
	if not self._active then
		return false
	end

	local info = self.Info
	local duration = info.Time
	self._elapsed += dt

	local t = self._elapsed - info.DelayTime
	if t < 0 then
		return true
	end

	if duration <= 0 then
		self:_applyFinal(false)
		self._active = false
		self.Completed:Fire()
		return false
	end

	local reverses = info.Reverses
	local repeatCount = info.RepeatCount
	local iterDur = if reverses then duration * 2 else duration
	local completed = t // iterDur

	if repeatCount >= 0 and completed > repeatCount then
		self:_applyFinal(reverses)
		self._active = false
		self.Completed:Fire()
		return false
	end

	local within = t - completed * iterDur
	local progress
	if reverses then
		local frac = within / duration
		progress = if frac > 1 then 2 - frac else frac
	else
		progress = within / duration
	end

	self:_apply(self._easing(progress))
	return true
end

-- ───────────── public API ─────────────
local TweenService = {}
TweenService.TweenInfo = TweenInfo

function TweenService.Create(instance: any, info: any, properties: { [string]: any }): any
	return Tween.new(instance, info, properties)
end

function TweenService.GetActiveTweens(): { any }
	local copy = table.create(#activeTweens)
	table.move(activeTweens, 1, #activeTweens, 1, copy)
	return copy
end

declare({ class = "TweenService", name = "Create", callback = {
	method = function(self: any, instance: any, info: any, properties: { [string]: any }): any
		return Tween.new(instance, info, properties)
	end,
} })

declare({ class = "TweenService", name = "GetActiveTweens", callback = {
	method = function(self: any): { any }
		local copy = table.create(#activeTweens)
		table.move(activeTweens, 1, #activeTweens, 1, copy)
		return copy
	end,
} })

_G.TweenInfo = TweenInfo

return TweenService
