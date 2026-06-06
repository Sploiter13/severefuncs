--!strict
--!optimize 2


local Offsets: any = (function()

local offsets = {

    ROBLOX_VERSION = "version-460909c4fe904aae",

    AirProperties = {
        AirDensity = 0x18,
        GlobalWind = 0x3C,
    },

    Animation = {
        AnimationId = 0xD0,
    },

    AnimationTrack = {
        Animation = 0xD0,
        Animator = 0x118,
        IsPlaying = 0xF4,
        Looped = 0xF5,
        Speed = 0xE4,
        TimePosition = 0xE8,
    },

    Animator = {
        ActiveAnimations = 0x868,
    },

    Atmosphere = {
        Color = 0xD0,
        Decay = 0xDC,
        Density = 0xE8,
        Glare = 0xEC,
        Haze = 0xF0,
        Offset = 0xF4,
    },

    Attachment = {
        CFrame = 0xDC,
        Visible = 0xF4,
    },

    BasePart = {
        CastShadow = 0xF5,
        Color3 = 0x194,
        Locked = 0xF6,
        Massless = 0xF7,
        Primitive = 0x148,
        Reflectance = 0xEC,
        Shape = 0x1B1,
        Transparency = 0xF0,
    },

    Beam = {
        Attachment0 = 0x170,
        Attachment1 = 0x180,
        Brightness = 0x190,
        Color = 0x124,
        ColorSequence = 0x110,
        CurveSize0 = 0x194,
        CurveSize1 = 0x198,
        Enabled = 0x1C4,
        FaceCamera = 0x1C5,
        LightEmission = 0x19C,
        LightInfluence = 0x1A0,
        Segments = 0x1A8,
        TextureLength = 0x1AC,
        TextureMode = 0x1B0,
        TextureSpeed = 0x1B4,
        Transparency = 0xE4,
        TransparencySequence = 0xD0,
        Width0 = 0x1B8,
        Width1 = 0x1BC,
        ZOffset = 0x1C0,
    },

    BillboardGui = {
        Active = 0x7CC,
        Adornee = 0x70,
        AlwaysOnTop = 0x7CD,
        Brightness = 0x7B0,
        ClipsDescendants = 0x7CE,
        ExtentsOffset = 0x778,
        ExtentsOffsetWorldSpace = 0x784,
        LightInfluence = 0x7C4,
        MaxDistance = 0x7C8,
        Size = 0x768,
        SizeOffset = 0x7A8,
        StudsOffset = 0x790,
        StudsOffsetWorldSpace = 0x79C,
    },

    BloomEffect = {
        Enabled = 0xD,
        Intensity = 0xD0,
        Size = 0xD4,
        Threshold = 0xD8,
    },

    BlurEffect = {
        Enabled = 0xD,
        Size = 0xD0,
    },

    ByteCode = {
        Pointer = 0x10,
        Size = 0xD0,
    },

    Camera = {
        CFrame = 0xF8,
        CameraType = 0x158,
        FieldOfView = 0x160,
        Position = 0x11C,
        Rotation = 0xF8,
        ViewportInt16 = 0x2AC,
        ViewportSize = 0x2E8,
    },

    CharacterMesh = {
        BaseTextureId = 0xE0,
        BodyPart = 0x160,
        MeshId = 0x110,
        OverlayTextureId = 0x140,
    },

    ClickDetector = {
        MaxActivationDistance = 0x100,
    },

    Clothing = {
        Color3 = 0x128,
        Template = 0x108,
    },

    ColorCorrectionEffect = {
        Brightness = 0xDC,
        Contrast = 0xE0,
        Enabled = 0xD,
        TintColor = 0xD0,
    },

    ColorGradingEffect = {
        Enabled = 0xD,
        TonemapperPreset = 0x30,
    },

    DataModel = {
        CreatorId = 0x190,
        GameId = 0x198,
        GameLoaded = 0x638,
        JobId = 0x138,
        PlaceId = 0x1A0,
        ServerIP = 0x620,
        Workspace = 0x178,
    },

    DepthOfFieldEffect = {
        Enabled = 0xD,
        FarIntensity = 0xD0,
        FocusDistance = 0xD4,
        InFocusRadius = 0xD8,
        NearIntensity = 0xDC,
    },

    FakeDataModel = {
        Pointer = 0x74F6758,
        RealDataModel = 0x1D0,
    },

    GuiBase2D = {
        AbsolutePosition = 0x110,
        AbsoluteRotation = 0x188,
        AbsoluteSize = 0x118,
    },

    GuiObject = {
        Active = 0x5B0,
        AnchorPoint = 0x560,
        AutomaticSize = 0x568,
        BackgroundColor3 = 0x548,
        BackgroundTransparency = 0x56C,
        BorderColor3 = 0x554,
        BorderMode = 0x570,
        BorderSizePixel = 0x574,
        ClipsDescendants = 0x5B1,
        GuiState = 0x580,
        Interactable = 0x5B3,
        LayoutOrder = 0x588,
        Position = 0x518,
        Rotation = 0x188,
        Selectable = 0x5B4,
        SelectionOrder = 0x5A4,
        Size = 0x538,
        SizeConstraint = 0x5A8,
        Visible = 0x5B5,
        ZIndex = 0x5AC,
    },

    Highlight = {
        DepthMode = 0xF8,
        Enabled = 0x10C,
        FillColor = 0xE0,
        FillTransparency = 0xFC,
        OutlineColor = 0xEC,
        OutlineTransparency = 0x104,
    },

    Humanoid = {
        AutoJumpEnabled = 0x1E0,
        AutoRotate = 0x1E1,
        AutomaticScalingEnabled = 0x1E2,
        BreakJointsOnDeath = 0x1E3,
        CameraOffset = 0x140,
        DisplayDistanceType = 0x18C,
        DisplayName = 0xD0,
        EvaluateStateMachine = 0x1E4,
        FloorMaterial = 0x190,
        Health = 0x194,
        HealthDisplayDistance = 0x198,
        HealthDisplayType = 0x19C,
        HipHeight = 0x1A0,
        HumanoidRootPart = 0x488,
        HumanoidState = 0x8A8,
        HumanoidStateID = 0x20,
        IsWalking = 0x927,
        Jump = 0x1E6,
        JumpHeight = 0x1AC,
        JumpPower = 0x1B0,
        MaxHealth = 0x1B4,
        MaxSlopeAngle = 0x1B8,
        MoveDirection = 0x158,
        MoveToPart = 0x130,
        MoveToPoint = 0x17C,
        NameDisplayDistance = 0x1BC,
        NameOcclusion = 0x1C0,
        PlatformStand = 0x1E8,
        RequiresNeck = 0x1E9,
        RigType = 0x1CC,
        SeatPart = 0x120,
        Sit = 0x1EA,
        TargetPoint = 0x164,
        UseJumpPower = 0x1EC,
        WalkSpeed = 0x1DC,
        WalkSpeedCheck = 0x3C4,
        WalkTimer = 0x418,
        WalkToPoint = 0x17C,
        Walkspeed = 0x1DC,
        WalkspeedCheck = 0x3C4,
    },

    ImageButton = {
        HoverImage = 0xC98,
        Image = 0xCC8,
        ImageColor3 = 0xD38,
        PressedImage = 0xCF8,
    },

    ImageLabel = {
        Image = 0xA18,
        ImageColor3 = 0xA58,
        ImageTransparency = 0xA7C,
        ScaleType = 0xA84,
    },

    InputObject = {
        MousePosition = 0xEC,
    },

    Instance = {
        AttributeContainer = 0x48,
        AttributeList = 0x18,
        AttributeToNext = 0x58,
        AttributeToValue = 0x18,
        ChildrenEnd = 0x8,
        ChildrenStart = 0x78,
        ClassDescriptor = 0x18,
        ClassName = 0x8,
        Name = 0xB0,
        Parent = 0x70,
        This = 0x8,
    },

    Light = {
        Brightness = 0xE4,
        Color = 0xD8,
        Enabled = 0xE8,
        Shadows = 0xE9,
    },

    Lighting = {
        Ambient = 0xE0,
        Atmosphere = 0x1F0,
        Brightness = 0x128,
        ClockTime = 0x1C0,
        ColorShift_Bottom = 0xEC,
        ColorShift_Top = 0xF8,
        EnvironmentDiffuseScale = 0x12C,
        EnvironmentSpecularScale = 0x130,
        ExposureCompensation = 0x134,
        FogColor = 0x104,
        FogEnd = 0x13C,
        FogStart = 0x140,
        OutdoorAmbient = 0x110,
        ShadowSoftness = 0x148,
        Sky = 0x1E0,
    },

    LightingParameters = {
        GeographicLatitude = 0x198,
        LightColor = 0x164,
        LightDirection = 0x170,
        SkyAmbient = 0x158,
        SkyAmbient2 = 0x19C,
        Source = 0x17C,
        TrueMoonPosition = 0x18C,
        TrueSunPosition = 0x180,
    },

    LocalScript = {
        ByteCode = 0x1A8,
        Bytecode = 0x1A8,
        GUID = 0x1B8,
        Hash = 0x1B8,
    },

    MaterialColors = {
        Asphalt = 0x30,
        Basalt = 0x27,
        Brick = 0xF,
        Cobblestone = 0x33,
        Concrete = 0xC,
        CrackedLava = 0x2D,
        Glacier = 0x1B,
        Grass = 0x6,
        Ground = 0x2A,
        Ice = 0x36,
        LeafyGrass = 0x39,
        Limestone = 0x3F,
        Mud = 0x24,
        Pavement = 0x42,
        Rock = 0x18,
        Salt = 0x3C,
        Sand = 0x12,
        Sandstone = 0x21,
        Slate = 0x9,
        Snow = 0x1E,
        WoodPlanks = 0x15,
    },

    MeshPart = {
        MeshId = 0x2F8,
        Texture = 0x328,
        TextureId = 0x328,
    },

    Misc = {
        Adornee = 0x70,
        AnimationId = 0xD0,
        StringLength = 0x10,
        Value = 0xD0,
    },

    Model = {
        PrimaryPart = 0x278,
        WorldPivot = 0x120,
    },

    ModuleScript = {
        ByteCode = 0xD0,
        Bytecode = 0xD0,
        GUID = 0x160,
        Hash = 0x160,
    },

    MouseService = {
        InputObject = 0x118,
    },

    ParticleEmitter = {
        Acceleration = 0x1F0,
        Brightness = 0x22C,
        Color = 0x1A4,
        ColorSequence = 0x190,
        Drag = 0x230,
        EmissionDirection = 0x234,
        Enabled = 0x278,
        Lifetime = 0x204,
        LightEmission = 0x248,
        LightInfluence = 0x24C,
        Rate = 0x258,
        RotSpeed = 0x20C,
        Rotation = 0x214,
        Size = 0xE4,
        SizeSequence = 0xD0,
        Speed = 0x21C,
        SpreadAngle = 0x224,
        TimeScale = 0x26C,
        Transparency = 0x164,
        TransparencySequence = 0x150,
        VelocityInheritance = 0x270,
        ZOffset = 0x274,
    },

    Player = {
        AccountAge = 0x32C,
        CameraMode = 0x30,
        Character = 0x3A8,
        DisplayName = 0x130,
        HealthDisplayDistance = 0x358,
        LocalPlayer = 0x138,
        LocaleId = 0x700,
        MaxZoomDistance = 0x330,
        MinZoomDistance = 0x334,
        ModelInstance = 0x3A8,
        NameDisplayDistance = 0x368,
        Team = 0x2B0,
        TeamColor = 0x374,
        UserId = 0x2D8,
    },

    Players = {
        LocalPlayer = 0x138,
    },

    PointLight = {
        Range = 0xF0,
    },

    Primitive = {
        AssemblyAngularVelocity = 0x104,
        AssemblyLinearVelocity = 0xF8,
        CFrame = 0xC8,
        Flags = 0x1B6,
        Material = 0x236,
        Orientation = 0xC8,
        Position = 0xEC,
        PrimitiveFlags = 0x1B6,
        Rotation = 0xC8,
        Size = 0x1B8,
    },

    PrimitiveFlags = {
        Anchored = 0x2,
        CanCollide = 0x8,
        CanQuery = 0x20,
        CanTouch = 0x10,
    },

    ProximityPrompt = {
        ActionText = 0xC8,
        Enabled = 0x14E,
        HoldDuration = 0x138,
        KeyCode = 0x13C,
        KeyboardKeyCode = 0x13C,
        MaxActivationDistance = 0x140,
        ObjectText = 0xE8,
        RequiresLineOfSight = 0x14F,
    },

    RenderView = {
        LightingValid = 0x150,
        SkyValid = 0x28D,
        SkyboxValid = 0x28D,
    },

    ScreenGui = {
        ClipToDeviceSafeArea = 0x750,
        DisplayOrder = 0xE0,
        Enabled = 0x4C8,
        IgnoreGuiInset = 0x4C8,
        ResetOnSpawn = 0x4CD,
        SafeAreaCompatibility = 0x4C8,
        ScreenInsets = 0x74C,
        ZIndexBehavior = 0x4C8,
    },

    ScrollingFrame = {
        CanvasPosition = 0x600,
        CanvasSize = 0xA18,
        ScrollBarThickness = 0xA78,
        ScrollingDirection = 0xA80,
    },

    Seat = {
        Occupant = 0x220,
    },

    Sky = {
        MoonAngularSize = 0x25C,
        MoonTextureId = 0xE0,
        SkyboxBk = 0x110,
        SkyboxDn = 0x140,
        SkyboxFt = 0x170,
        SkyboxLf = 0x1A0,
        SkyboxOrientation = 0x250,
        SkyboxRt = 0x1D0,
        SkyboxUp = 0x200,
        StarCount = 0x260,
        SunAngularSize = 0x264,
        SunTextureId = 0x230,
    },

    Sound = {
        Looped = 0x155,
        PlayOnRemove = 0x156,
        PlaybackRegionsEnabled = 0x157,
        PlaybackSpeed = 0x134,
        RollOffMaxDistance = 0x138,
        RollOffMinDistance = 0x13C,
        RollOffMode = 0x140,
        SoundId = 0xE0,
        Volume = 0x148,
    },

    SpawnLocation = {
        AllowTeamChangeOnTouch = 0x45,
        Duration = 0x1F0,
        Enabled = 0x1F9,
        ForcefieldDuration = 0x1F0,
        Neutral = 0x1FA,
        TeamColor = 0x1F4,
    },

    SpecialMesh = {
        MeshId = 0x108,
        Offset = 0xD0,
        Scale = 0xDC,
        TextureId = 0x130,
    },

    SpotLight = {
        Angle = 0xF0,
        Face = 0xF4,
        Range = 0xF8,
    },

    SunRaysEffect = {
        Intensity = 0xD0,
        Spread = 0xD4,
    },

    SurfaceAppearance = {
        AlphaMode = 0x2A0,
        Color = 0x288,
        EmissiveStrength = 0x2A4,
        ResampleMode = 0x2A8,
    },

    SurfaceGui = {
        PixelsPerStud = 0x784,
        SizingMode = 0x788,
        ToolPunchThroughDistance = 0x798,
        ZOffset = 0xE4,
    },

    SurfaceLight = {
        Angle = 0xF0,
        Face = 0xF4,
        Range = 0xF8,
    },

    TaskScheduler = {
        JobEnd = 0xD0,
        JobName = 0x18,
        JobStart = 0xC8,
        Pointer = 0x7BFE988,
    },

    Team = {
        BrickColor = 0xD0,
        TeamColor = 0xD0,
    },

    Terrain = {
        GrassLength = 0x1F8,
        MaterialColors = 0x2A8,
        WaterColor = 0x1E8,
        WaterReflectance = 0x200,
        WaterTransparency = 0x204,
        WaterWaveSize = 0x208,
        WaterWaveSpeed = 0x20C,
    },

    TextBox = {
        ClearTextOnFocus = 0xED0,
        Font = 0xE98,
        LineHeight = 0xC50,
        MaxVisibleGraphemes = 0xEA4,
        MultiLine = 0xED3,
        PlaceholderColor3 = 0xE70,
        PlaceholderText = 0xE00,
        RichText = 0xD46,
        ShowNativeInput = 0xED9,
        Text = 0xB58,
        TextColor3 = 0xE7C,
        TextDirection = 0xCF0,
        TextEditable = 0xEDA,
        TextScaled = 0xD42,
        TextSize = 0xEB8,
        TextStrokeColor3 = 0xE88,
        TextStrokeTransparency = 0xEBC,
        TextTransparency = 0xEC0,
        TextTruncate = 0xEC4,
        TextWrapped = 0xD44,
        TextXAlignment = 0xEC8,
        TextYAlignment = 0xC98,
    },

    TextButton = {
        AutoButtonColor = 0x9CC,
        ContentText = 0xDE0,
        Font = 0x10F0,
        LineHeight = 0xED8,
        LocalizedText = 0xDE0,
        MaxVisibleGraphemes = 0x10FC,
        Modal = 0x9CD,
        RichText = 0xFD2,
        Selected = 0x9CE,
        Text = 0xDE0,
        TextColor3 = 0x10D8,
        TextDirection = 0xF78,
        TextScaled = 0xDC9,
        TextSize = 0x1104,
        TextStrokeColor3 = 0x10E4,
        TextStrokeTransparency = 0x1108,
        TextTransparency = 0x110C,
        TextTruncate = 0x1110,
        TextWrapped = 0xFCC,
        TextXAlignment = 0x1114,
        TextYAlignment = 0xF20,
    },

    TextLabel = {
        ContentText = 0xB60,
        Font = 0xE70,
        LineHeight = 0xC58,
        LocalizedText = 0xB60,
        MaxVisibleGraphemes = 0xE7C,
        RichText = 0xD52,
        Text = 0xB60,
        TextColor3 = 0xE58,
        TextDirection = 0xCF8,
        TextScaled = 0xD4A,
        TextSize = 0xE84,
        TextStrokeColor3 = 0xE64,
        TextStrokeTransparency = 0xE88,
        TextTransparency = 0xE8C,
        TextTruncate = 0xE90,
        TextWrapped = 0xD4C,
        TextXAlignment = 0xE94,
        TextYAlignment = 0xCA0,
    },

    Tool = {
        CanBeDropped = 0x4C8,
        Enabled = 0x4C9,
        Grip = 0x498,
        GripForward = 0x4B0,
        GripPos = 0x4BC,
        GripRight = 0x498,
        GripUp = 0x4A4,
        ManualActivationOnly = 0x4CA,
        RequiresHandle = 0x4CB,
        Tooltip = 0x478,
    },

    UIGradient = {
        Color = 0x134,
        ColorSequence = 0x120,
        Enabled = 0x164,
        Offset = 0x158,
        Rotation = 0x160,
        Transparency = 0xF4,
        TransparencySequence = 0xE0,
    },

    Value = {
        Value = 0xD0,
    },

    VehicleSeat = {
        MaxSpeed = 0x238,
        Occupant = 0x218,
        SteerFloat = 0x240,
        ThrottleFloat = 0x248,
        Torque = 0x24C,
        TurnSpeed = 0x250,
    },

    VisualEngine = {
        Dimensions = 0xAA0,
        FakeDataModel = 0xA80,
        Pointer = 0x7BD51F8,
        RenderView = 0xB80,
        ViewMatrix = 0x140,
    },

    WeldConstraint = {
        Enabled = 0xF0,
        Part0 = 0x70,
        Part1 = 0xE0,
    },

    Workspace = {
        CurrentCamera = 0x4B0,
        FallenPartsDestroyHeight = 0x208,
        ReadOnlyGravity = 0x9E0,
        World = 0x408,
    },

    World = {
        AirProperties = 0x218,
        FallenPartsDestroyHeight = 0x208,
        Gravity = 0x210,
        Primitives = 0x280,
        WorldSteps = 0x678,
        worldStepsPerSec = 0x678,
    },

}

return offsets
end)()

local function O(ns: string, field: string): number
	local namespace = Offsets[ns]
	if namespace == nil then
		error(`[offsets] missing namespace '{ns}' — re-paste offsets.lua`)
	end
	local value = namespace[field]
	if type(value) ~= "number" then
		error(`[offsets] missing offset '{ns}.{field}' — re-paste offsets.lua`)
	end
	return value
end

local function nsFor(class: any, ns: string?): string
	if ns ~= nil then
		return ns
	end
	if type(class) == "string" then
		return class
	end
	error("[offsets] explicit namespace required for multi-class declarations")
end

local memory_readu8     = memory.readu8
local memory_readu32    = memory.readu32
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
local math_min   = math.min
local math_max   = math.max
local math_rad   = math.rad
local math_deg   = math.deg
local math_pi    = math.pi

local os_clock = os.clock

local coroutine_create  = coroutine.create
local coroutine_resume  = coroutine.resume
local coroutine_running = coroutine.running
local coroutine_yield   = coroutine.yield

local RunService = game:GetService("RunService")

local Color3_new = Color3.new
local declare    = Instance.declare

local BASEPART_CLASSES = table.freeze({ "Part", "MeshPart", "UnionOperation", "TrussPart" })
local GUI_CLASSES = table.freeze({
	"Frame", "TextLabel", "TextButton", "TextBox",
	"ImageLabel", "ImageButton", "ScrollingFrame",
})
local TEXT_CLASSES = table.freeze({ "TextLabel", "TextButton", "TextBox" })

local OFF_PRIMITIVE  = O("BasePart", "Primitive")
local OFF_PRIM_FLAGS = O("Primitive", "Flags")
local OFF_MATCOLORS  = O("Terrain", "MaterialColors")

local VE_POINTER    = O("VisualEngine", "Pointer")
local VE_RENDERVIEW = O("VisualEngine", "RenderView")
local RV_LIGHTING   = O("RenderView", "LightingValid")
local RV_SKY        = O("RenderView", "SkyValid")

local function toVector(value: any): vector
	if type(value) == "vector" then
		return value
	end
	if typeof(value) == "Vector3" or (type(value) == "table" and value.X ~= nil) then
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

local ROUND_HALF = vector_create(0.5, 0.5, 0.5)

@native
local function round3(v: vector): vector
	return vector_floor(v * 1000 + ROUND_HALF) * 0.001
end

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

local function readMaterialColor(self: any, byteOffset: number): Color3
	local ptr = memory_readu64(self, OFF_MATCOLORS)
	return Color3_new(
		memory_readu8(ptr, byteOffset) / 255,
		memory_readu8(ptr, byteOffset + 1) / 255,
		memory_readu8(ptr, byteOffset + 2) / 255
	)
end

local function writeMaterialColor(self: any, byteOffset: number, color: any)
	local ptr = memory_readu64(self, OFF_MATCOLORS)
	local c = toColorVector(color)
	memory_writeu8(ptr, byteOffset, math_floor(c.X * 255 + 0.5))
	memory_writeu8(ptr, byteOffset + 1, math_floor(c.Y * 255 + 0.5))
	memory_writeu8(ptr, byteOffset + 2, math_floor(c.Z * 255 + 0.5))
end

local function getRenderView(): number
	local ve = memory_readu64(memory_base + VE_POINTER)
	if ve == 0 then
		return 0
	end
	return memory_readu64(ve + VE_RENDERVIEW)
end

local function invalidateRender()
	local rv = getRenderView()
	if rv == 0 then
		return
	end
	memory_writeu8(rv + RV_LIGHTING, 0)
	memory_writeu8(rv + RV_SKY, 0)
end

local function declareF32(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
	declare({ class = class, name = name, callback = {
		get = function(self: any): number
			return memory_readf32(self, offset)
		end,
		set = function(self: any, value: number)
			memory_writef32(self, offset, value)
		end,
	} })
end

local function declareI32(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
	declare({ class = class, name = name, callback = {
		get = function(self: any): number
			return memory_readi32(self, offset)
		end,
		set = function(self: any, value: number)
			memory_writei32(self, offset, value)
		end,
	} })
end

local function declareU8(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
	declare({ class = class, name = name, callback = {
		get = function(self: any): number
			return memory_readu8(self, offset)
		end,
		set = function(self: any, value: number)
			memory_writeu8(self, offset, value)
		end,
	} })
end

local function declareBool(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
	declare({ class = class, name = name, callback = {
		get = function(self: any): boolean
			return memory_readu8(self, offset) ~= 0
		end,
		set = function(self: any, value: boolean)
			memory_writeu8(self, offset, if value then 1 else 0)
		end,
	} })
end

local function declareString(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
	declare({ class = class, name = name, callback = {
		get = function(self: any): string
			return memory_readstring(self, offset)
		end,
		set = function(self: any, value: string)
			memory_writestring(self, offset, value)
		end,
	} })
end

local function declareColor(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
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

local function declareVector(class: any, name: string, ns: string?, field: string?)
	local offset = O(nsFor(class, ns), field or name)
	declare({ class = class, name = name, callback = {
		get = function(self: any): vector
			return memory_readvector(self, offset)
		end,
		set = function(self: any, value: any)
			memory_writevector(self, offset, toVector(value))
		end,
	} })
end

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

local COLOR_STRIDE = 20
local NUMBER_STRIDE = 12

local function readColorSeq(self: any, seqOff: number)
	local count = memory_readu32(self, seqOff + 8)
	local arr = pointer_to_userdata(memory_readu64(self, seqOff))
	local out = table.create(count)
	for i = 0, count - 1 do
		local o = i * COLOR_STRIDE
		out[i + 1] = {
			Time = memory_readf32(arr, o),
			Color = Color3_new(
				memory_readf32(arr, o + 4),
				memory_readf32(arr, o + 8),
				memory_readf32(arr, o + 12)),
		}
	end
	return out
end

local function readNumberSeq(self: any, seqOff: number)
	local count = memory_readu32(self, seqOff + 8)
	local arr = pointer_to_userdata(memory_readu64(self, seqOff))
	local out = table.create(count)
	for i = 0, count - 1 do
		local o = i * NUMBER_STRIDE
		out[i + 1] = {
			Time = memory_readf32(arr, o),
			Value = memory_readf32(arr, o + 4),
		}
	end
	return out
end

local function writeColorSeqSolid(self: any, seqOff: number, c: vector)
	local count = memory_readu32(self, seqOff + 8)
	local arr = pointer_to_userdata(memory_readu64(self, seqOff))
	for i = 0, count - 1 do
		local o = i * COLOR_STRIDE
		memory_writef32(arr, o + 4, c.X)
		memory_writef32(arr, o + 8, c.Y)
		memory_writef32(arr, o + 12, c.Z)
	end
end

local function writeNumberSeqSolid(self: any, seqOff: number, v: number)
	local count = memory_readu32(self, seqOff + 8)
	local arr = pointer_to_userdata(memory_readu64(self, seqOff))
	for i = 0, count - 1 do
		memory_writef32(arr, i * NUMBER_STRIDE + 4, v)
	end
end

local function writeColorSeqKeypoints(self: any, seqOff: number, kps: { any })
	local count = memory_readu32(self, seqOff + 8)
	local arr = pointer_to_userdata(memory_readu64(self, seqOff))
	local n = math_min(count, #kps)
	for i = 1, n do
		local c = toColorVector(kps[i].Color)
		local o = (i - 1) * COLOR_STRIDE
		memory_writef32(arr, o + 4, c.X)
		memory_writef32(arr, o + 8, c.Y)
		memory_writef32(arr, o + 12, c.Z)
	end
end

local function writeNumberSeqKeypoints(self: any, seqOff: number, kps: { any })
	local count = memory_readu32(self, seqOff + 8)
	local arr = pointer_to_userdata(memory_readu64(self, seqOff))
	local n = math_min(count, #kps)
	for i = 1, n do
		memory_writef32(arr, (i - 1) * NUMBER_STRIDE + 4, kps[i].Value)
	end
end

local function isColorKeypointArray(value: any): boolean
	return type(value) == "table" and type(value[1]) == "table" and value[1].Color ~= nil
end

local function isNumberKeypointArray(value: any): boolean
	return type(value) == "table" and type(value[1]) == "table" and value[1].Value ~= nil
end

local function declareSequenceColor(class: string, seqField: string, plainField: string)
	local seqOff = O(class, seqField)
	local plainOff = O(class, plainField)
	declare({ class = class, name = plainField, callback = {
		get = function(self: any): any
			local count = memory_readu32(self, seqOff + 8)
			if count > 1 and count < 100 then
				return readColorSeq(self, seqOff)
			end
			local r = memory_readvector(self, plainOff)
			return Color3_new(r.X, r.Y, r.Z)
		end,
		set = function(self: any, value: any)
			local count = memory_readu32(self, seqOff + 8)
			if count > 1 and count < 100 then
				if isColorKeypointArray(value) then
					writeColorSeqKeypoints(self, seqOff, value)
				else
					writeColorSeqSolid(self, seqOff, toColorVector(value))
				end
			else
				memory_writevector(self, plainOff, toColorVector(value))
			end
		end,
	} })
end

local function declareSequenceNumber(class: string, seqField: string, plainField: string)
	local seqOff = O(class, seqField)
	local plainOff = O(class, plainField)
	declare({ class = class, name = plainField, callback = {
		get = function(self: any): any
			local count = memory_readu32(self, seqOff + 8)
			if count > 1 and count < 100 then
				return readNumberSeq(self, seqOff)
			end
			return memory_readf32(self, plainOff)
		end,
		set = function(self: any, value: any)
			local count = memory_readu32(self, seqOff + 8)
			if count > 1 and count < 100 then
				if isNumberKeypointArray(value) then
					writeNumberSeqKeypoints(self, seqOff, value)
				else
					writeNumberSeqSolid(self, seqOff, value)
				end
			else
				memory_writef32(self, plainOff, value)
			end
		end,
	} })
end

declareSequenceColor("ParticleEmitter", "ColorSequence", "Color")
declareSequenceNumber("ParticleEmitter", "TransparencySequence", "Transparency")
declareSequenceColor("Beam", "ColorSequence", "Color")
declareSequenceNumber("Beam", "TransparencySequence", "Transparency")
declareSequenceColor("UIGradient", "ColorSequence", "Color")
declareSequenceNumber("UIGradient", "TransparencySequence", "Transparency")

declareColor("Atmosphere", "Color")
declareF32("Atmosphere", "Decay")
declareF32("Atmosphere", "Density")
declareF32("Atmosphere", "Glare")
declareF32("Atmosphere", "Haze")
declareF32("Atmosphere", "Offset")

declareF32(BASEPART_CLASSES, "Reflectance", "BasePart")
declareColor(BASEPART_CLASSES, "Color", "BasePart", "Color3")
declareBool(BASEPART_CLASSES, "CastShadow", "BasePart")
declareBool(BASEPART_CLASSES, "Locked", "BasePart")
declareBool(BASEPART_CLASSES, "Massless", "BasePart")
declareU8(BASEPART_CLASSES, "Shape", "BasePart")

do
	local velLinear = O("Primitive", "AssemblyLinearVelocity")
	local velAngular = O("Primitive", "AssemblyAngularVelocity")
	local material = O("Primitive", "Material")

	declare({ class = BASEPART_CLASSES, name = "AssemblyLinearVelocity", callback = {
		get = function(self: any): vector
			return round3(memory_readvector(memory_readu64(self, OFF_PRIMITIVE), velLinear))
		end,
		set = function(self: any, value: any)
			memory_writevector(memory_readu64(self, OFF_PRIMITIVE), velLinear, toVector(value))
		end,
	} })

	declare({ class = BASEPART_CLASSES, name = "AssemblyAngularVelocity", callback = {
		get = function(self: any): vector
			return round3(memory_readvector(memory_readu64(self, OFF_PRIMITIVE), velAngular))
		end,
		set = function(self: any, value: any)
			memory_writevector(memory_readu64(self, OFF_PRIMITIVE), velAngular, toVector(value))
		end,
	} })

	declare({ class = BASEPART_CLASSES, name = "Material", callback = {
		get = function(self: any): number
			return memory_readi32(memory_readu64(self, OFF_PRIMITIVE), material)
		end,
		set = function(self: any, value: number)
			memory_writei32(memory_readu64(self, OFF_PRIMITIVE), material, value)
		end,
	} })
end

declarePrimitiveFlag("Anchored", O("PrimitiveFlags", "Anchored"))
declarePrimitiveFlag("CanQuery", O("PrimitiveFlags", "CanQuery"))
declarePrimitiveFlag("CanTouch", O("PrimitiveFlags", "CanTouch"))

declareF32("Humanoid", "HipHeight")
declareF32("Humanoid", "MaxSlopeAngle")
declareF32("Humanoid", "JumpPower")
declareF32("Humanoid", "JumpHeight")
declareF32("Humanoid", "HealthDisplayDistance")
declareF32("Humanoid", "NameDisplayDistance")
declareBool("Humanoid", "AutoRotate")
declareBool("Humanoid", "AutoJumpEnabled")
declareBool("Humanoid", "BreakJointsOnDeath")
declareBool("Humanoid", "RequiresNeck")
declareBool("Humanoid", "UseJumpPower")
declareBool("Humanoid", "Jump")
declareI32("Humanoid", "RigType")

do
	local walkSpeed = O("Humanoid", "WalkSpeed")
	local walkSpeedCheck = O("Humanoid", "WalkSpeedCheck")
	declare({ class = "Humanoid", name = "WalkSpeed", callback = {
		get = function(self: any): number
			return memory_readf32(self, walkSpeed)
		end,
		set = function(self: any, value: number)
			memory_writef32(self, walkSpeedCheck, value)
			memory_writef32(self, walkSpeed, value)
		end,
	} })

	local moveDir = O("Humanoid", "MoveDirection")
	declare({ class = "Humanoid", name = "MoveDirection", callback = {
		get = function(self: any): vector
			return round3(memory_readvector(self, moveDir))
		end,
		set = function(self: any, value: any)
			memory_writevector(self, moveDir, toVector(value))
		end,
	} })

	local isWalking = O("Humanoid", "IsWalking")
	declare({ class = "Humanoid", name = "IsWalking", callback = {
		get = function(self: any): boolean
			return memory_readu8(self, isWalking) ~= 0
		end,
	} })

	local floorMaterial = O("Humanoid", "FloorMaterial")
	declare({ class = "Humanoid", name = "FloorMaterial", callback = {
		get = function(self: any): number
			return memory_readi32(self, floorMaterial)
		end,
	} })

	local moveToPart = O("Humanoid", "MoveToPart")
	local walkToPoint = O("Humanoid", "WalkToPoint")
	declare({ class = "Humanoid", name = "MoveTo", callback = {
		method = function(self: any, target: any)
			local pos: vector
			if type(target) == "vector" or (type(target) == "table" and target.X ~= nil) then
				pos = toVector(target)
			elseif target ~= nil and target.ClassName ~= nil then
				memory_writeu64(self, moveToPart, tonumber(target.Data))
				pos = toVector(target.Position)
			else
				error("[Humanoid:MoveTo] target must be a Vector3 or a Part")
			end
			memory_writevector(self, walkToPoint, pos)
		end,
	} })
end

do
	local HUMANOID_STATES = table.freeze({
		[0] = "FallingDown",
		[1] = "Ragdoll",
		[2] = "GettingUp",
		[3] = "Jumping",
		[4] = "Swimming",
		[5] = "Freefall",
		[6] = "Flying",
		[7] = "Landed",
		[8] = "Running",
		[10] = "RunningNoPhysics",
		[11] = "StrafingNoPhysics",
		[12] = "Climbing",
		[13] = "Seated",
		[14] = "PlatformStanding",
		[15] = "Dead",
		[16] = "Physics",
		[18] = "None",
	})

	local stateOff = O("Humanoid", "HumanoidState")
	local stateIdOff = O("Humanoid", "HumanoidStateID")

	local function readStateId(self: any): number
		local statePtr = memory_readu64(self, stateOff)
		if statePtr == 0 then
			return 18
		end
		return memory_readu32(statePtr, stateIdOff)
	end

	declare({ class = "Humanoid", name = "HumanoidStateId", callback = {
		get = function(self: any): number
			return readStateId(self)
		end,
	} })

	declare({ class = "Humanoid", name = "State", callback = {
		get = function(self: any): string
			return HUMANOID_STATES[readStateId(self)] or "None"
		end,
	} })

	declare({ class = "Humanoid", name = "GetState", callback = {
		method = function(self: any): string
			return HUMANOID_STATES[readStateId(self)] or "None"
		end,
	} })
end

declareBool(GUI_CLASSES, "Active", "GuiObject")
declareBool(GUI_CLASSES, "ClipsDescendants", "GuiObject")
declareBool(GUI_CLASSES, "Selectable", "GuiObject")
declareBool(GUI_CLASSES, "Visible", "GuiObject")
declareF32(GUI_CLASSES, "BackgroundTransparency", "GuiObject")
declareColor(GUI_CLASSES, "BackgroundColor3", "GuiObject")
declareColor(GUI_CLASSES, "BorderColor3", "GuiObject")
declareF32(GUI_CLASSES, "Rotation", "GuiObject")
declareI32(GUI_CLASSES, "LayoutOrder", "GuiObject")
declareI32(GUI_CLASSES, "ZIndex", "GuiObject")
declareI32(GUI_CLASSES, "BorderSizePixel", "GuiObject")

do
	local posOff = O("GuiObject", "Position")
	declare({ class = GUI_CLASSES, name = "Position", callback = {
		get = function(self: any)
			local sx, ox, sy, oy = readUDim2(self, posOff)
			return { X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } }
		end,
		set = function(self: any, value: any)
			writeUDim2(self, posOff, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
		end,
	} })

	local sizeOff = O("GuiObject", "Size")
	declare({ class = GUI_CLASSES, name = "Size", callback = {
		get = function(self: any)
			local sx, ox, sy, oy = readUDim2(self, sizeOff)
			return { X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } }
		end,
		set = function(self: any, value: any)
			writeUDim2(self, sizeOff, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
		end,
	} })

	local anchorOff = O("GuiObject", "AnchorPoint")
	declare({ class = GUI_CLASSES, name = "AnchorPoint", callback = {
		get = function(self: any)
			return { X = memory_readf32(self, anchorOff), Y = memory_readf32(self, anchorOff + 0x4) }
		end,
	} })

	local absPos = O("GuiBase2D", "AbsolutePosition")
	declare({ class = GUI_CLASSES, name = "AbsolutePosition", callback = {
		get = function(self: any)
			return { X = memory_readf32(self, absPos), Y = memory_readf32(self, absPos + 0x4) }
		end,
	} })

	local absSize = O("GuiBase2D", "AbsoluteSize")
	declare({ class = GUI_CLASSES, name = "AbsoluteSize", callback = {
		get = function(self: any)
			return { X = memory_readf32(self, absSize), Y = memory_readf32(self, absSize + 0x4) }
		end,
	} })
end

for _, cls in TEXT_CLASSES do
	declareString(cls, "Text")
	declareColor(cls, "TextColor3")
	declareColor(cls, "TextStrokeColor3")
	declareF32(cls, "TextSize")
	declareF32(cls, "TextTransparency")
	declareF32(cls, "TextStrokeTransparency")
	declareF32(cls, "LineHeight")
end

declareColor("Lighting", "Ambient")
declareF32("Lighting", "Brightness")
declareColor("Lighting", "ColorShift_Bottom")
declareColor("Lighting", "ColorShift_Top")
declareF32("Lighting", "ExposureCompensation")
declareColor("Lighting", "FogColor")
declareF32("Lighting", "FogEnd")
declareF32("Lighting", "FogStart")
declareColor("Lighting", "OutdoorAmbient")

do
	local clockOff = O("Lighting", "ClockTime")
	declare({ class = "Lighting", name = "ClockTime", callback = {
		get = function(self: any): number
			return memory_readf64(self, clockOff) / 3600
		end,
		set = function(self: any, value: number)
			memory_writef64(self, clockOff, value * 3600)
		end,
	} })
end

declareString("ProximityPrompt", "ActionText")
declareString("ProximityPrompt", "ObjectText")
declareBool("ProximityPrompt", "Enabled")
declareF32("ProximityPrompt", "HoldDuration")
declareF32("ProximityPrompt", "MaxActivationDistance")
declareBool("ProximityPrompt", "RequiresLineOfSight")
declareI32("ProximityPrompt", "KeyboardKeyCode")

declareF32("Sky", "MoonAngularSize")
declareF32("Sky", "SunAngularSize")
declareI32("Sky", "StarCount")
declareString("Sky", "MoonTextureId")
declareString("Sky", "SunTextureId")

for _, faceName in { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" } do
	local faceOffset = O("Sky", faceName)
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

declareF32("BloomEffect", "Intensity")
declareF32("BloomEffect", "Size")
declareF32("BloomEffect", "Threshold")

declareColor("ColorCorrectionEffect", "TintColor")
declareF32("ColorCorrectionEffect", "Brightness")
declareF32("ColorCorrectionEffect", "Contrast")

declareF32("DepthOfFieldEffect", "FocusDistance")
declareF32("DepthOfFieldEffect", "InFocusRadius")
declareF32("DepthOfFieldEffect", "NearIntensity")

declareColor("Highlight", "FillColor")
declareColor("Highlight", "OutlineColor")
declareF32("Highlight", "FillTransparency")
declareF32("Highlight", "OutlineTransparency")
declareI32("Highlight", "DepthMode")

declareBool("Tool", "CanBeDropped")
declareBool("Tool", "Enabled")
declareBool("Tool", "ManualActivationOnly")
declareBool("Tool", "RequiresHandle")
declareString("Tool", "ToolTip", "Tool", "Tooltip")
declareVector("Tool", "GripPos")

do
	local fovOff = O("Camera", "FieldOfView")
	declare({ class = "Camera", name = "FieldOfView", callback = {
		get = function(self: any): number
			return math_deg(memory_readf32(self, fovOff))
		end,
		set = function(self: any, value: number)
			memory_writef32(self, fovOff, math_rad(value))
		end,
	} })
end

declareBool("AnimationTrack", "Looped")
declareF32("AnimationTrack", "Speed")

do
	local animOff = O("AnimationTrack", "Animation")
	declare({ class = "AnimationTrack", name = "Animation", callback = {
		get = function(self: any): number?
			local ptr = memory_readu64(self, animOff)
			return if ptr ~= 0 then ptr else nil
		end,
	} })

	local animatorOff = O("AnimationTrack", "Animator")
	declare({ class = "AnimationTrack", name = "Animator", callback = {
		get = function(self: any): number?
			local ptr = memory_readu64(self, animatorOff)
			return if ptr ~= 0 then ptr else nil
		end,
	} })

	local isPlayingOff = O("AnimationTrack", "IsPlaying")
	declare({ class = "AnimationTrack", name = "IsPlaying", callback = {
		get = function(self: any): boolean
			return memory_readu8(self, isPlayingOff) ~= 0
		end,
	} })
end

declareString("Animation", "AnimationId")

do
	local activeAnims = O("Animator", "ActiveAnimations")
	local atAnim = O("AnimationTrack", "Animation")
	local atPlaying = O("AnimationTrack", "IsPlaying")
	local atSpeed = O("AnimationTrack", "Speed")
	local atLooped = O("AnimationTrack", "Looped")
	local animId = O("Animation", "AnimationId")
	local trackMeta = { __tostring = function(t: any): string return t.AnimationId end }

	declare({ class = "Animator", name = "GetPlayingAnimationTracks", callback = {
		method = function(self: any)
			local head = memory_readu64(self, activeAnims)
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
					local animationPtr = memory_readu64(trackPtr, atAnim)
					if animationPtr ~= 0 then
						local id = memory_readstring(animationPtr, animId)
						result[#result + 1] = setmetatable({
							AnimationId = id,
							IsPlaying = memory_readu8(trackPtr, atPlaying) ~= 0,
							Speed = memory_readf32(trackPtr, atSpeed),
							Looped = memory_readu8(trackPtr, atLooped) ~= 0,
							Animation = { AnimationId = id },
						}, trackMeta)
					end
				end
				node = memory_readu64(node)
			end
			return result
		end,
	} })
end

declareF32("Terrain", "GrassLength")
declareColor("Terrain", "WaterColor")
declareF32("Terrain", "WaterReflectance")
declareF32("Terrain", "WaterTransparency")
declareF32("Terrain", "WaterWaveSize")
declareF32("Terrain", "WaterWaveSpeed")

local matColors = Offsets.MaterialColors
if type(matColors) ~= "table" then
	error("[offsets] missing MaterialColors namespace — re-paste offsets.lua")
end

for matName, byteOffset in matColors do
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
		local byteOffset = matColors[materialName]
		if type(byteOffset) ~= "number" then
			error(`[Terrain:GetMaterialColor] invalid material '{materialName}'`)
		end
		return readMaterialColor(self, byteOffset)
	end,
} })

declare({ class = "Terrain", name = "SetMaterialColor", callback = {
	method = function(self: any, materialName: string, color: any)
		local byteOffset = matColors[materialName]
		if type(byteOffset) ~= "number" then
			error(`[Terrain:SetMaterialColor] invalid material '{materialName}'`)
		end
		writeMaterialColor(self, byteOffset, color)
	end,
} })

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
				coroutine_resume(coroutine_create(node.fn), ...)
			end
		end
		local waiters = self._waiters
		if #waiters > 0 then
			self._waiters = {}
			for _, co in waiters do
				coroutine_resume(co, ...)
			end
		end
	end

	function RobloxSignal.Wait(self: any): ...any
		local waiters = self._waiters
		waiters[#waiters + 1] = coroutine_running()
		return coroutine_yield()
	end
end

local MIN_FRAME = 1 / 240
local MAX_FRAME = 1 / 30

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

	local x2_, y2_, z2_ = x + x, y + y, z + z
	local xx, xy, xz = x * x2_, x * y2_, x * z2_
	local yy, yz = y * y2_, y * z2_
	local zz = z * z2_
	local wx, wy, wz = w * x2_, w * y2_, w * z2_
	local up = vector_create(xy - wz, 1 - (xx + zz), yz + wx)
	local look = vector_create(xz + wy, yz - wx, 1 - (xx + yy))
	return CFrame.lookAt(np, vector_create(np.X - look.X, np.Y - look.Y, np.Z - look.Z), up)
end

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

type TweenProp = { name: string, kind: string, target: any, start: any }

local activeTweens: { any } = {}
local stepConn: any = nil
local stepping = false
local lastTick = 0

local function stopStepping()
	if not stepping then
		return
	end
	stepping = false
	local conn = stepConn
	stepConn = nil
	if conn ~= nil then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function unregister(tween: any)
	for i = #activeTweens, 1, -1 do
		if activeTweens[i] == tween then
			local n = #activeTweens
			activeTweens[i] = activeTweens[n]
			activeTweens[n] = nil
			break
		end
	end
	if #activeTweens == 0 then
		stopStepping()
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

local function onTweenStep()
	if not stepping then
		return
	end
	local now = os_clock()
	local dt = now - lastTick
	lastTick = now
	processTweens(dt)
	if #activeTweens == 0 then
		stopStepping()
	end
end

local function register(tween: any)
	activeTweens[#activeTweens + 1] = tween
	if not stepping then
		stepping = true
		lastTick = os_clock()
		stepConn = RunService.PostLocal:Connect(onTweenStep)
	end
end

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

print(`[merge2] loaded — offsets {Offsets.ROBLOX_VERSION}`)

return TweenService
