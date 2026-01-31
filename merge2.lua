--!native
--!optimize 2

---- environment ----
local memory_readu8 = memory.readu8
local memory_readu16 = memory.readu16
local memory_readi32 = memory.readi32
local memory_readu64 = memory.readu64
local memory_readf32 = memory.readf32
local memory_readf64 = memory.readf64
local memory_readvector = memory.readvector
local memory_readstring = memory.readstring
local memory_readbool = memory.readbool

local memory_writeu8 = memory.writeu8
local memory_writeu16 = memory.writeu16
local memory_writei32 = memory.writei32
local memory_writeu64 = memory.writeu64
local memory_writef32 = memory.writef32
local memory_writef64 = memory.writef64
local memory_writevector = memory.writevector
local memory_writestring = memory.writestring
local memory_writebool = memory.writebool

local vector_create = vector.create  
local string_format = string.format  

local bit32_band = bit32.band
local bit32_bor = bit32.bor
local bit32_bnot = bit32.bnot

local assert, typeof = assert, typeof
local math_floor = math.floor

---- constants ----
local BASEPART_CLASSES = {"Part", "MeshPart", "UnionOperation", "TrussPart"}
local GUI_CLASSES = {"Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton", "ScrollingFrame"}
local TEXT_CLASSES = {"TextLabel", "TextButton", "TextBox"}

---- offsets ----
local Offsets = {
    Atmosphere = {
        Color = 0xD0,
        Decay = 0xDC,
        Density = 0xE8,
        Glare = 0xEC,
        Haze = 0xF0,
        Offset = 0xF4
    },
    
    BasePart = {
        Primitive = 0x148,
        Reflectance = 0xEC,
        Color = 0x194,
        CastShadow = 0xF5,
        Locked = 0xF6,
        Massless = 0xF7,
        Shape = 0x1B1,
        Rotation = 0xC0
    },
    
    Primitive = {
        AssemblyLinearVelocity = 0xF0,
        AssemblyAngularVelocity = 0xFC,
        Material = 0x246,
        Anchored = 0xD71,
        NetworkOwner = 0x248,
        CanQuery = 0xD75,
        CanTouch = 0xD74,
        EnableFluidForces = 0x126E,
        FrontSurface = 0x225,
        BackSurface = 0x222,
        LeftSurface = 0x223,
        RightSurface = 0x220,
        TopSurface = 0x221,
        BottomSurface = 0x224
    },
    
    Humanoid = {
        HipHeight = 0x1A0,
        MaxSlopeAngle = 0x1B8,
        WalkSpeed = 0x1D4,
        WalkSpeedCheck = 0x3C0,
        JumpPower = 0x1B0,
        JumpHeight = 0x1AC,
        MoveDirection = 0x158,
        WalkToPoint = 0x17C,
        IsWalking = 0x956,
        HealthDisplayDistance = 0x198,
        NameDisplayDistance = 0x1BC,
        AutoRotate = 0x1D9,
        AutoJumpEnabled = 0x1D8,
        BreakJointsOnDeath = 0x1DB,
        RequiresNeck = 0x1E0,
        UseJumpPower = 0x1E3,
        RigType = 0x1C8,
        Jump = 0x1DD,
        FloorMaterial = 0x190
    },
    
    GuiObject = {
        Active = 0x5BC,
        ClipsDescendants = 0x5BD,
        Draggable = 0x5BE,
        Selectable = 0x5C0,
        Visible = 0x5B1,
        BackgroundTransparency = 0x56C,
        BackgroundColor3 = 0x548,
        BorderColor3 = 0x554,
        Rotation = 0x188,
        LayoutOrder = 0x584,
        ZIndex = 0x5A8,
        BorderSizePixel = 0x574,
        Position = 0x528,
        Size = 0x538,
        AnchorPoint = 0x560,
        AbsolutePositionX = 0x2510,
        AbsolutePositionY = 0x2514,
        AbsoluteSizeX = 0x2518,
        AbsoluteSizeY = 0x251C,
    },
    
    TextLabel = {
        Text = 0xE08,
        TextColor3 = 0xEB8,
        TextSize = 0xCE4,
        TextTransparency = 0xEEC,
        TextStrokeColor3 = 0xEC4,
        TextStrokeTransparency = 0xEE8,
        LineHeight = 0xB1C
    },

    TextButton = {
        Text = 0x1088
    },

    TextBox = {
        Text = 0xE00
    },
    
    Lighting = {
        Ambient = 0xD8,
        Brightness = 0x120,
        ClockTime = 0x1B8,
        ColorShift_Bottom = 0xE4,
        ColorShift_Top = 0xF0,
        ExposureCompensation = 0x12C,
        FogColor = 0xFC,
        FogEnd = 0x134,
        FogStart = 0x138,
        GeographicLatitude = 0x190,
        OutdoorAmbient = 0x108
    },
    
    ProximityPrompt = {
        ActionText = 0xD0,
        ObjectText = 0xF0,
        Enabled = 0x156,
        HoldDuration = 0x140,
        MaxActivationDistance = 0x148,
        RequiresLineOfSight = 0x157,
        KeyboardKeyCode = 0x144
    },
    
    Sky = {
        MoonAngularSize = 0x25C,
        SunAngularSize = 0x264,
        StarCount = 0x260,
        MoonTextureId = 0xE0,
        SunTextureId = 0x230,
        SkyboxBk = 0x110,
        SkyboxDn = 0x140,
        SkyboxFt = 0x170,
        SkyboxLf = 0x1A0,
        SkyboxRt = 0x1D0,
        SkyboxUp = 0x200
    },
    
    BloomEffect = {
        Intensity = 0xD0,
        Size = 0xD4,
        Threshold = 0xD8
    },
    
    ColorCorrectionEffect = {
        TintColor = 0xD0,
        Brightness = 0xDC,
        Contrast = 0xE0,
        Saturation = 0xE4
    },
    
    DepthOfFieldEffect = {
        FocusDistance = 0xD4,
        InFocusRadius = 0xD8,
        NearIntensity = 0xDC
    },
    
    Highlight = {
        FillColor = 0xE0,
        OutlineColor = 0xEC,
        FillTransparency = 0xFC,
        OutlineTransparency = 0xF0,
        DepthMode = 0xF8
    },
    
    Tool = {
        CanBeDropped = 0x4A0,
        Enabled = 0x4A1,
        ManualActivationOnly = 0x4A2,
        RequiresHandle = 0x4A3,
        ToolTip = 0x450,
        GripPos = 0x494
    },

    Camera = {
        FieldOfView = 0x160
    },

    AnimationTrack = {
        Animation = 0xD0,
        Animator = 0x118,
        IsPlaying = 0x518,
        Looped = 0xF5,
        Speed = 0xE4,
        AnimationId = 0xD0
    },

    Terrain = {
        GrassLength = 0x1F8,
        MaterialColors = 0x280,
        WaterColor = 0x1E8,
        WaterReflectance = 0x200,
        WaterTransparency = 0x204,
        WaterWaveSize = 0x208,
        WaterWaveSpeed = 0x20C
    },

    MaterialColors = {
        Asphalt = 0x10,
        Basalt = 0xD,
        Brick = 0x5,
        Cobblestone = 0x11,
        Concrete = 0x4,
        CrackedLava = 0xF,
        Glacier = 0x9,
        Grass = 0x2,
        Ground = 0xE,
        Ice = 0x12,
        LeafyGrass = 0x13,
        Limestone = 0x15,
        Mud = 0xC,
        Pavement = 0x16,
        Rock = 0x8,
        Salt = 0x14,
        Sand = 0x6,
        Sandstone = 0xB,
        Slate = 0x3,
        Snow = 0xA,
        WoodPlanks = 0x7
    },

}



---- variables ----
local Camera = workspace.CurrentCamera

---- functions ----
local function getPrimitive(part)
    assert(part and part.Data and part.Data ~= 0, "Invalid part data")
    return memory_readu64(part, Offsets.BasePart.Primitive)
end

local function toVector(value)
    if type(value) == "vector" then
        return value
    elseif typeof(value) == "Vector3" then
        return vector.create(value.X, value.Y, value.Z)
    end
    error("Value must be vector or Vector3")
end

local function toColorVector(value)
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
        if value.R and value.G and value.B then
            return vector_create(value.R, value.G, value.B)
        elseif value.X and value.Y and value.Z then
            return vector_create(value.X, value.Y, value.Z)
        elseif value[1] and value[2] and value[3] then
            return vector_create(value[1], value[2], value[3])
        end
    end
    
    error(string_format(
        "toColorVector: Cannot convert %s to vector. Value: %s",
        t,
        tostring(value)
    ))
end

local function round(num, decimals)
    local mult = 10 ^ (decimals or 3)
    return math_floor(num * mult + 0.5) / mult
end

local function readUDim2(ptr, offset)
    local xScale = memory_readf32(ptr, offset)
    local xOffset = memory_readi32(ptr, offset + 0x4)
    local yScale = memory_readf32(ptr, offset + 0x8)
    local yOffset = memory_readi32(ptr, offset + 0xC)
    return xScale, xOffset, yScale, yOffset
end

local function readVector2(ptr, offset)
    local x = memory_readf32(ptr, offset)
    local y = memory_readf32(ptr, offset + 4)
    return x, y
end

local function newUDim2(sx, ox, sy, oy)
    return {
        X = { Scale = sx, Offset = ox },
        Y = { Scale = sy, Offset = oy }
    }
end

local function newVector2(x, y)
    return { X = x, Y = y }
end

local function readMaterialColor(terrain, materialIndex)
    local vectorPtr = memory_readu64(terrain, Offsets.Terrain.MaterialColors)
    
    local colorOffset = materialIndex * 3
    
    local r = memory_readu8(vectorPtr, colorOffset)
    local g = memory_readu8(vectorPtr, colorOffset + 1)
    local b = memory_readu8(vectorPtr, colorOffset + 2)
    
    return Color3.new(r / 255, g / 255, b / 255)
end

local function writeMaterialColor(terrain, materialIndex, color)
    local vectorPtr = memory_readu64(terrain, Offsets.Terrain.MaterialColors)
    
    local colorOffset = materialIndex * 3
    
    local colorVec = toColorVector(color)
    local r = math_floor(colorVec.X * 255 + 0.5)
    local g = math_floor(colorVec.Y * 255 + 0.5)
    local b = math_floor(colorVec.Z * 255 + 0.5)
    
    memory_writeu8(vectorPtr, colorOffset, r)
    memory_writeu8(vectorPtr, colorOffset + 1, g)
    memory_writeu8(vectorPtr, colorOffset + 2, b)
end


---- runtime ----

-- ═══════════════════════════════════════════════════════════
-- ATMOSPHERE PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Atmosphere",
    name = "Color",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Atmosphere.Color)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Atmosphere.Color, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Atmosphere",
    name = "Decay",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Atmosphere.Decay)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Atmosphere.Decay, value)
        end
    }
})

Instance.declare({
    class = "Atmosphere",
    name = "Density",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Atmosphere.Density)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Atmosphere.Density, value)
        end
    }
})

Instance.declare({
    class = "Atmosphere",
    name = "Glare",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Atmosphere.Glare)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Atmosphere.Glare, value)
        end
    }
})

Instance.declare({
    class = "Atmosphere",
    name = "Haze",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Atmosphere.Haze)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Atmosphere.Haze, value)
        end
    }
})

Instance.declare({
    class = "Atmosphere",
    name = "Offset",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Atmosphere.Offset)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Atmosphere.Offset, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- BASEPART PROPERTIES (Direct)
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Reflectance",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.BasePart.Reflectance)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.BasePart.Reflectance, value)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Color",
    callback = {
        get = function(self)
            local raw = memory_readvector(self, Offsets.BasePart.Color)
            return Color3.new(raw.X, raw.Y, raw.Z)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.BasePart.Color, toColorVector(value))
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "CastShadow",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.BasePart.CastShadow) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.BasePart.CastShadow, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Locked",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.BasePart.Locked) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.BasePart.Locked, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Massless",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.BasePart.Massless) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.BasePart.Massless, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Shape",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.BasePart.Shape)
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.BasePart.Shape, value)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Rotation",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.BasePart.Rotation)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.BasePart.Rotation, toVector(value))
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- BASEPART PROPERTIES (Through Primitive)
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = BASEPART_CLASSES,
    name = "AssemblyLinearVelocity",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            local raw = memory_readvector(primitive, Offsets.Primitive.AssemblyLinearVelocity)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writevector(primitive, Offsets.Primitive.AssemblyLinearVelocity, toVector(value))
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "AssemblyAngularVelocity",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            local raw = memory_readvector(primitive, Offsets.Primitive.AssemblyAngularVelocity)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writevector(primitive, Offsets.Primitive.AssemblyAngularVelocity, toVector(value))
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Material",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            return memory_readi32(primitive, Offsets.Primitive.Material)
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writei32(primitive, Offsets.Primitive.Material, value)
        end
    }
})

_G.OriginalNetworkOwners = _G.OriginalNetworkOwners or {}

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Anchored",
    callback = {
        get = function(self)
            local primitive_ptr = getPrimitive(self)
            if primitive_ptr == 0 then return false end
            
            local primitive = pointer_to_userdata(primitive_ptr)
            local owner = memory.readi32(primitive, Offsets.Primitive.NetworkOwner)
            
            return owner == 2
        end,
        set = function(self, value)
            local primitive_ptr = getPrimitive(self)
            if primitive_ptr == 0 then return end
            
            local primitive = pointer_to_userdata(primitive_ptr)
            local address = tonumber(self.Data, 16)
            
            if not _G.OriginalNetworkOwners[address] then
                _G.OriginalNetworkOwners[address] = memory.readi32(primitive, Offsets.Primitive.NetworkOwner)
            end
            
            if value then
                memory.writei32(primitive, Offsets.Primitive.NetworkOwner, 2)
            else
                local original = _G.OriginalNetworkOwners[address]
                if original then
                    memory.writei32(primitive, Offsets.Primitive.NetworkOwner, original)
                end
            end
        end
    }
})


Instance.declare({
    class = BASEPART_CLASSES,
    name = "CanQuery",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            return memory_readu8(primitive, Offsets.Primitive.CanQuery) ~= 0
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writeu8(primitive, Offsets.Primitive.CanQuery, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "CanTouch",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            return memory_readu8(primitive, Offsets.Primitive.CanTouch) ~= 0
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writeu8(primitive, Offsets.Primitive.CanTouch, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = BASEPART_CLASSES,
    name = "EnableFluidForces",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            return memory_readu8(primitive, Offsets.Primitive.EnableFluidForces) ~= 0
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writeu8(primitive, Offsets.Primitive.EnableFluidForces, value and 1 or 0)
        end
    }
})

-- Surface properties (Primitive)
local surfaces = {
    {name = "FrontSurface", offset = "FrontSurface"},
    {name = "BackSurface", offset = "BackSurface"},
    {name = "LeftSurface", offset = "LeftSurface"},
    {name = "RightSurface", offset = "RightSurface"},
    {name = "TopSurface", offset = "TopSurface"},
    {name = "BottomSurface", offset = "BottomSurface"}
}

for _, surf in ipairs(surfaces) do
    Instance.declare({
        class = BASEPART_CLASSES,
        name = surf.name,
        callback = {
            get = function(self)
                local primitive = getPrimitive(self)
                return memory_readu8(primitive, Offsets.Primitive[surf.offset])
            end,
            set = function(self, value)
                local primitive = getPrimitive(self)
                memory_writeu8(primitive, Offsets.Primitive[surf.offset], value)
            end
        }
    })
end

-- ═══════════════════════════════════════════════════════════
-- HUMANOID PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Humanoid",
    name = "HipHeight",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.HipHeight)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.HipHeight, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "MaxSlopeAngle",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.MaxSlopeAngle)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.MaxSlopeAngle, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "WalkSpeed",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.WalkSpeed)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.WalkSpeedCheck, value)
            memory_writef32(self, Offsets.Humanoid.WalkSpeed, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "JumpPower",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.JumpPower)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.JumpPower, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "JumpHeight",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.JumpHeight)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.JumpHeight, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "MoveDirection",
    callback = {
        get = function(self)
            local raw = memory_readvector(self, Offsets.Humanoid.MoveDirection)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "MoveDirection",
    callback = {
        get = function(self)
            local raw = memory_readvector(self, Offsets.Humanoid.MoveDirection)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Humanoid.MoveDirection, value)
        end
    }
})


Instance.declare({
    class = "Humanoid",
    name = "IsWalking",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Humanoid.IsWalking) ~= 0
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "HealthDisplayDistance",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.HealthDisplayDistance)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.HealthDisplayDistance, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "NameDisplayDistance",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Humanoid.NameDisplayDistance)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Humanoid.NameDisplayDistance, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "AutoRotate",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Humanoid.AutoRotate) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Humanoid.AutoRotate, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "AutoJumpEnabled",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Humanoid.AutoJumpEnabled) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Humanoid.AutoJumpEnabled, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "BreakJointsOnDeath",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Humanoid.BreakJointsOnDeath) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Humanoid.BreakJointsOnDeath, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "RequiresNeck",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Humanoid.RequiresNeck) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Humanoid.RequiresNeck, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "UseJumpPower",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Humanoid.UseJumpPower) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Humanoid.UseJumpPower, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "RigType",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.Humanoid.RigType)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.Humanoid.RigType, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "Jump",
    callback = {
        get = function(self)
            return memory_readbool(self, Offsets.Humanoid.Jump)
        end,
        set = function(self, value)
            memory_writebool(self, Offsets.Humanoid.Jump, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "FloorMaterial",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.Humanoid.FloorMaterial)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- GUI OBJECT PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = GUI_CLASSES,
    name = "Active",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.GuiObject.Active) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.GuiObject.Active, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "ClipsDescendants",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.GuiObject.ClipsDescendants) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.GuiObject.ClipsDescendants, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "Draggable",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.GuiObject.Draggable) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.GuiObject.Draggable, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "Selectable",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.GuiObject.Selectable) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.GuiObject.Selectable, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "Visible",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.GuiObject.Visible) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.GuiObject.Visible, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "BackgroundTransparency",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.GuiObject.BackgroundTransparency)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.GuiObject.BackgroundTransparency, value)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "BackgroundColor3",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.GuiObject.BackgroundColor3)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.GuiObject.BackgroundColor3, toColorVector(value))
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "BorderColor3",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.GuiObject.BorderColor3)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.GuiObject.BorderColor3, toColorVector(value))
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "Rotation",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.GuiObject.Rotation)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.GuiObject.Rotation, value)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "LayoutOrder",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.GuiObject.LayoutOrder)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.GuiObject.LayoutOrder, value)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "ZIndex",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.GuiObject.ZIndex)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.GuiObject.ZIndex, value)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "BorderSizePixel",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.GuiObject.BorderSizePixel)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.GuiObject.BorderSizePixel, value)
        end
    }
})


Instance.declare({
    class = GUI_CLASSES,
    name = "Position",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newUDim2(0, 0, 0, 0) end
            local sx, ox, sy, oy = readUDim2(self.Data, Offsets.GuiObject.Position)
            return newUDim2(sx, ox, sy, oy)
        end
    }
})


Instance.declare({
    class = GUI_CLASSES,
    name = "Size",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newUDim2(0, 0, 0, 0) end
            local sx, ox, sy, oy = readUDim2(self.Data, Offsets.GuiObject.Size)
            return newUDim2(sx, ox, sy, oy)
        end
    }
})


Instance.declare({
    class = GUI_CLASSES,
    name = "AnchorPoint",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newVector2(0, 0) end
            local x, y = readVector2(self.Data, Offsets.GuiObject.AnchorPoint)
            return newVector2(x, y)
        end
    }
})


Instance.declare({
    class = GUI_CLASSES,
    name = "AbsolutePosition",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newVector2(0, 0) end
            local x = memory_readf32(self.Data, Offsets.GuiObject.AbsolutePositionX)
            local y = memory_readf32(self.Data, Offsets.GuiObject.AbsolutePositionY)
            return newVector2(x, y)
        end
    }
})

Instance.declare({
    class = GUI_CLASSES,
    name = "AbsoluteSize",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newVector2(0, 0) end
            local w = memory_readf32(self.Data, Offsets.GuiObject.AbsoluteSizeX)
            local h = memory_readf32(self.Data, Offsets.GuiObject.AbsoluteSizeY)
            return newVector2(w, h)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
-- TEXT LABEL PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = TEXT_CLASSES,
    name = "Text",
    callback = {
        get = function(self)
            local offset
            if self.ClassName == "TextLabel" then
                offset = Offsets.TextLabel.Text
            elseif self.ClassName == "TextButton" then
                offset = Offsets.TextButton.Text
            elseif self.ClassName == "TextBox" then
                offset = Offsets.TextBox.Text
            else
                error("Unknown text class: " .. tostring(self.ClassName))
            end
            
            return memory_readstring(self, offset)
        end,
        set = function(self, value)
            local offset
            if self.ClassName == "TextLabel" then
                offset = Offsets.TextLabel.Text
            elseif self.ClassName == "TextButton" then
                offset = Offsets.TextButton.Text
            elseif self.ClassName == "TextBox" then
                offset = Offsets.TextBox.Text
            else
                error("Unknown text class: " .. tostring(self.ClassName))
            end
            
            memory_writestring(self, offset, value)
        end
    }
})


Instance.declare({
    class = TEXT_CLASSES,
    name = "TextColor3",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.TextLabel.TextColor3)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.TextLabel.TextColor3, toColorVector(value))
        end
    }
})

Instance.declare({
    class = TEXT_CLASSES,
    name = "TextSize",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.TextLabel.TextSize)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.TextLabel.TextSize, value)
        end
    }
})

Instance.declare({
    class = TEXT_CLASSES,
    name = "TextTransparency",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.TextLabel.TextTransparency)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.TextLabel.TextTransparency, value)
        end
    }
})

Instance.declare({
    class = TEXT_CLASSES,
    name = "TextStrokeColor3",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.TextLabel.TextStrokeColor3)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.TextLabel.TextStrokeColor3, toColorVector(value))
        end
    }
})

Instance.declare({
    class = TEXT_CLASSES,
    name = "TextStrokeTransparency",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.TextLabel.TextStrokeTransparency)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.TextLabel.TextStrokeTransparency, value)
        end
    }
})

Instance.declare({
    class = TEXT_CLASSES,
    name = "LineHeight",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.TextLabel.LineHeight)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.TextLabel.LineHeight, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- LIGHTING PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Lighting",
    name = "Ambient",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Lighting.Ambient)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Lighting.Ambient, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "Brightness",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Lighting.Brightness)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Lighting.Brightness, value)
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "ClockTime",
    callback = {
        get = function(self)
            return memory_readf64(self, Offsets.Lighting.ClockTime) / 3600
        end,
        set = function(self, value)
            memory_writef64(self, Offsets.Lighting.ClockTime, value * 3600)
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "ColorShift_Bottom",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Lighting.ColorShift_Bottom)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Lighting.ColorShift_Bottom, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "ColorShift_Top",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Lighting.ColorShift_Top)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Lighting.ColorShift_Top, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "ExposureCompensation",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Lighting.ExposureCompensation)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Lighting.ExposureCompensation, value)
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "FogColor",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Lighting.FogColor)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Lighting.FogColor, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "FogEnd",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Lighting.FogEnd)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Lighting.FogEnd, value)
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "FogStart",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Lighting.FogStart)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Lighting.FogStart, value)
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "GeographicLatitude",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Lighting.GeographicLatitude)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Lighting.GeographicLatitude, value)
        end
    }
})

Instance.declare({
    class = "Lighting",
    name = "OutdoorAmbient",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Lighting.OutdoorAmbient)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Lighting.OutdoorAmbient, toColorVector(value))
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- PROXIMITY PROMPT PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "ProximityPrompt",
    name = "ActionText",
    callback = {
        get = function(self)
            return memory_readstring(self, Offsets.ProximityPrompt.ActionText)
        end,
        set = function(self, value)
            memory_writestring(self, Offsets.ProximityPrompt.ActionText, value)
        end
    }
})

Instance.declare({
    class = "ProximityPrompt",
    name = "ObjectText",
    callback = {
        get = function(self)
            return memory_readstring(self, Offsets.ProximityPrompt.ObjectText)
        end,
        set = function(self, value)
            memory_writestring(self, Offsets.ProximityPrompt.ObjectText, value)
        end
    }
})

Instance.declare({
    class = "ProximityPrompt",
    name = "Enabled",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.ProximityPrompt.Enabled) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.ProximityPrompt.Enabled, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "ProximityPrompt",
    name = "HoldDuration",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.ProximityPrompt.HoldDuration)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.ProximityPrompt.HoldDuration, value)
        end
    }
})

Instance.declare({
    class = "ProximityPrompt",
    name = "MaxActivationDistance",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.ProximityPrompt.MaxActivationDistance)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.ProximityPrompt.MaxActivationDistance, value)
        end
    }
})

Instance.declare({
    class = "ProximityPrompt",
    name = "RequiresLineOfSight",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.ProximityPrompt.RequiresLineOfSight) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.ProximityPrompt.RequiresLineOfSight, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "ProximityPrompt",
    name = "KeyboardKeyCode",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.ProximityPrompt.KeyboardKeyCode)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.ProximityPrompt.KeyboardKeyCode, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SKY PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Sky",
    name = "MoonAngularSize",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Sky.MoonAngularSize)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Sky.MoonAngularSize, value)
        end
    }
})

Instance.declare({
    class = "Sky",
    name = "SunAngularSize",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Sky.SunAngularSize)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Sky.SunAngularSize, value)
        end
    }
})

Instance.declare({
    class = "Sky",
    name = "StarCount",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.Sky.StarCount)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.Sky.StarCount, value)
        end
    }
})

Instance.declare({
    class = "Sky",
    name = "MoonTextureId",
    callback = {
        get = function(self)
            return memory_readstring(self, Offsets.Sky.MoonTextureId)
        end,
        set = function(self, value)
            memory_writestring(self, Offsets.Sky.MoonTextureId, value)
        end
    }
})

Instance.declare({
    class = "Sky",
    name = "SunTextureId",
    callback = {
        get = function(self)
            return memory_readstring(self, Offsets.Sky.SunTextureId)
        end,
        set = function(self, value)
            memory_writestring(self, Offsets.Sky.SunTextureId, value)
        end
    }
})

local skyboxFaces = {
    "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"
}

for _, faceName in ipairs(skyboxFaces) do
    Instance.declare({
        class = "Sky",
        name = faceName,
        callback = {
            get = function(self)
                return memory_readstring(self, Offsets.Sky[faceName])
            end,
            set = function(self, value)
                memory_writestring(self, Offsets.Sky[faceName], value)
            end
        }
    })
end

-- ═══════════════════════════════════════════════════════════
-- BLOOM EFFECT PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "BloomEffect",
    name = "Intensity",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.BloomEffect.Intensity)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.BloomEffect.Intensity, value)
        end
    }
})

Instance.declare({
    class = "BloomEffect",
    name = "Size",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.BloomEffect.Size)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.BloomEffect.Size, value)
        end
    }
})

Instance.declare({
    class = "BloomEffect",
    name = "Threshold",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.BloomEffect.Threshold)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.BloomEffect.Threshold, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- COLOR CORRECTION EFFECT PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "ColorCorrectionEffect",
    name = "TintColor",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.ColorCorrectionEffect.TintColor)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.ColorCorrectionEffect.TintColor, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "ColorCorrectionEffect",
    name = "Brightness",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.ColorCorrectionEffect.Brightness)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.ColorCorrectionEffect.Brightness, value)
        end
    }
})

Instance.declare({
    class = "ColorCorrectionEffect",
    name = "Contrast",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.ColorCorrectionEffect.Contrast)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.ColorCorrectionEffect.Contrast, value)
        end
    }
})

Instance.declare({
    class = "ColorCorrectionEffect",
    name = "Saturation",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.ColorCorrectionEffect.Saturation)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.ColorCorrectionEffect.Saturation, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- DEPTH OF FIELD EFFECT PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "DepthOfFieldEffect",
    name = "FocusDistance",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.DepthOfFieldEffect.FocusDistance)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.DepthOfFieldEffect.FocusDistance, value)
        end
    }
})

Instance.declare({
    class = "DepthOfFieldEffect",
    name = "InFocusRadius",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.DepthOfFieldEffect.InFocusRadius)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.DepthOfFieldEffect.InFocusRadius, value)
        end
    }
})

Instance.declare({
    class = "DepthOfFieldEffect",
    name = "NearIntensity",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.DepthOfFieldEffect.NearIntensity)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.DepthOfFieldEffect.NearIntensity, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- HIGHLIGHT PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Highlight",
    name = "FillColor",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Highlight.FillColor)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Highlight.FillColor, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Highlight",
    name = "OutlineColor",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Highlight.OutlineColor)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Highlight.OutlineColor, toColorVector(value))
        end
    }
})

Instance.declare({
    class = "Highlight",
    name = "FillTransparency",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Highlight.FillTransparency)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Highlight.FillTransparency, value)
        end
    }
})

Instance.declare({
    class = "Highlight",
    name = "OutlineTransparency",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Highlight.OutlineTransparency)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Highlight.OutlineTransparency, value)
        end
    }
})

Instance.declare({
    class = "Highlight",
    name = "DepthMode",
    callback = {
        get = function(self)
            return memory_readi32(self, Offsets.Highlight.DepthMode)
        end,
        set = function(self, value)
            memory_writei32(self, Offsets.Highlight.DepthMode, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- TOOL PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Tool",
    name = "CanBeDropped",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Tool.CanBeDropped) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Tool.CanBeDropped, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Tool",
    name = "Enabled",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Tool.Enabled) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Tool.Enabled, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Tool",
    name = "ManualActivationOnly",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Tool.ManualActivationOnly) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Tool.ManualActivationOnly, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Tool",
    name = "RequiresHandle",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.Tool.RequiresHandle) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.Tool.RequiresHandle, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "Tool",
    name = "ToolTip",
    callback = {
        get = function(self)
            return memory_readstring(self, Offsets.Tool.ToolTip)
        end,
        set = function(self, value)
            memory_writestring(self, Offsets.Tool.ToolTip, value)
        end
    }
})

Instance.declare({
    class = "Tool",
    name = "GripPos",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Tool.GripPos)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Tool.GripPos, toVector(value))
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- CAMERA PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Camera",
    name = "FieldOfView",
    callback = {
        get = function(self)
            local radians = memory_readf32(self, Offsets.Camera.FieldOfView)
            return math.deg(radians)  
        end,
        set = function(self, value)
            local radians = math.rad(value)
            memory_writef32(self, Offsets.Camera.FieldOfView, radians)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- ANIMATIONTRACK PROPERTIES
-- ═══════════════════════════════════════════════════════════
Instance.declare({
    class = "AnimationTrack",
    name = "Animation",
    callback = {
        get = function(self)
            local ptr = memory_readu64(self, Offsets.AnimationTrack.Animation)
            return ptr ~= 0 and ptr or nil
        end
    }
})

Instance.declare({
    class = "AnimationTrack",
    name = "Animator",
    callback = {
        get = function(self)
            local ptr = memory_readu64(self, Offsets.AnimationTrack.Animator)
            return ptr ~= 0 and ptr or nil
        end
    }
})

Instance.declare({
    class = "AnimationTrack",
    name = "IsPlaying",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.AnimationTrack.IsPlaying) ~= 0
        end
    }
})

Instance.declare({
    class = "AnimationTrack",
    name = "Looped",
    callback = {
        get = function(self)
            return memory_readu8(self, Offsets.AnimationTrack.Looped) ~= 0
        end,
        set = function(self, value)
            memory_writeu8(self, Offsets.AnimationTrack.Looped, value and 1 or 0)
        end
    }
})

Instance.declare({
    class = "AnimationTrack",
    name = "Speed",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.AnimationTrack.Speed)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.AnimationTrack.Speed, value)
        end
    }
})

Instance.declare({
    class = "Animation",
    name = "AnimationId",
    callback = {
        get = function(self)
            local strPtr = memory.readu64(self, Offsets.AnimationTrack.Animation)
            if strPtr == 0 then return "" end
            return memory.readstring(self, Offsets.AnimationTrack.AnimationId)
        end,
        set = function(self, value)
            local strPtr = memory.readu64(self, Offsets.AnimationTrack.Animation)
            if strPtr ~= 0 then
                for i = 1, #value do
                    memory.writeu8(strPtr, i - 1, string.byte(value, i))
                end
                memory.writeu8(strPtr, #value, 0)
            end
        end
    }
})



-- ═══════════════════════════════════════════════════════════
-- TERRAIN PROPERTIES
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Terrain",
    name = "GrassLength",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Terrain.GrassLength)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Terrain.GrassLength, value)
        end
    }
})

Instance.declare({
    class = "Terrain",
    name = "WaterColor",
    callback = {
        get = function(self)
            local success, result = pcall(function()
                local raw = memory_readvector(self, Offsets.Terrain.WaterColor)
                return Color3.new(raw.X, raw.Y, raw.Z)
            end)
            
            if success then
                return result
            else
                warn("[Terrain.WaterColor] Read failed:", result)
                return Color3.new(0, 0, 0)
            end
        end,
        set = function(self, value)
            local success, err = pcall(function()
                local vec = toColorVector(value)
                memory_writevector(self, Offsets.Terrain.WaterColor, vec)
            end)
            
            if not success then
                warn("[Terrain.WaterColor] Write failed:", err)
                warn("Value type:", typeof(value), "Value:", value)
            end
        end
    }
})

Instance.declare({
    class = "Terrain",
    name = "WaterReflectance",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Terrain.WaterReflectance)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Terrain.WaterReflectance, value)
        end
    }
})

Instance.declare({
    class = "Terrain",
    name = "WaterTransparency",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Terrain.WaterTransparency)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Terrain.WaterTransparency, value)
        end
    }
})

Instance.declare({
    class = "Terrain",
    name = "WaterWaveSize",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Terrain.WaterWaveSize)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Terrain.WaterWaveSize, value)
        end
    }
})

Instance.declare({
    class = "Terrain",
    name = "WaterWaveSpeed",
    callback = {
        get = function(self)
            return memory_readf32(self, Offsets.Terrain.WaterWaveSpeed)
        end,
        set = function(self, value)
            memory_writef32(self, Offsets.Terrain.WaterWaveSpeed, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- TERRAIN MATERIAL COLORS
-- ═══════════════════════════════════════════════════════════

local materialNames = {
    "Asphalt", "Basalt", "Brick", "Cobblestone", "Concrete", 
    "CrackedLava", "Glacier", "Grass", "Ground", "Ice", 
    "LeafyGrass", "Limestone", "Mud", "Pavement", "Rock", 
    "Salt", "Sand", "Sandstone", "Slate", "Snow", "WoodPlanks"
}

for _, materialName in ipairs(materialNames) do
    Instance.declare({
        class = "Terrain",
        name = materialName .. "Color",
        callback = {
            get = function(self)
                return readMaterialColor(self, Offsets.MaterialColors[materialName])
            end,
            set = function(self, value)
                writeMaterialColor(self, Offsets.MaterialColors[materialName], value)
            end
        }
    })
end

Instance.declare({
    class = "Terrain",
    name = "GetMaterialColor",
    callback = {
        method = function(self, materialName)
            local materialIndex = Offsets.MaterialColors[materialName]
            assert(materialIndex, "Invalid material name: " .. tostring(materialName))
            return readMaterialColor(self, materialIndex)
        end
    }
})

Instance.declare({
    class = "Terrain",
    name = "SetMaterialColor",
    callback = {
        method = function(self, materialName, color)
            local materialIndex = Offsets.MaterialColors[materialName]
            assert(materialIndex, "Invalid material name: " .. tostring(materialName))
            writeMaterialColor(self, materialIndex, color)
        end
    }
})



local function createCFrameTable(pos, right, up, look)
    return {
        Position = pos,
        RightVector = right,
        UpVector = up,
        LookVector = look
    }
end

local function isVector(v)
    return type(v) == "vector" or (type(v) == "table" and v.X and v.Y and v.Z)
end

local function toVector(v)
    if type(v) == "vector" then
        return v
    elseif type(v) == "table" and v.X and v.Y and v.Z then
        return vector.create(v.X, v.Y, v.Z)
    end
    error("Invalid vector type")
end

-- CFrame:Inverse()
Instance.declare({
    class = "Instance",
    name = "Inverse",
    callback = {
        method = function(self)
            local pos = self.Position
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            -- Transpose rotation matrix
            local newRight = vector.create(right.X, up.X, look.X)
            local newUp = vector.create(right.Y, up.Y, look.Y)
            local newLook = vector.create(right.Z, up.Z, look.Z)
            
            -- Transform position
            local newPos = vector.create(
                -vector.dot(pos, newRight),
                -vector.dot(pos, newUp),
                -vector.dot(pos, newLook)
            )
            
            return createCFrameTable(newPos, newRight, newUp, newLook)
        end
    }
})

-- CFrame:ToWorldSpace()
Instance.declare({
    class = "Instance",
    name = "ToWorldSpace",
    callback = {
        method = function(self, cf)
            assert(cf, "CFrame argument required")
            
            local pos = self.Position
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            -- Transform rotation
            local otherRight = cf.RightVector
            local otherUp = cf.UpVector
            local otherLook = cf.LookVector
            
            local newRight = vector.create(
                right.X * otherRight.X + up.X * otherRight.Y + look.X * otherRight.Z,
                right.Y * otherRight.X + up.Y * otherRight.Y + look.Y * otherRight.Z,
                right.Z * otherRight.X + up.Z * otherRight.Y + look.Z * otherRight.Z
            )
            
            local newUp = vector.create(
                right.X * otherUp.X + up.X * otherUp.Y + look.X * otherUp.Z,
                right.Y * otherUp.X + up.Y * otherUp.Y + look.Y * otherUp.Z,
                right.Z * otherUp.X + up.Z * otherUp.Y + look.Z * otherUp.Z
            )
            
            local newLook = vector.create(
                right.X * otherLook.X + up.X * otherLook.Y + look.X * otherLook.Z,
                right.Y * otherLook.X + up.Y * otherLook.Y + look.Y * otherLook.Z,
                right.Z * otherLook.X + up.Z * otherLook.Y + look.Z * otherLook.Z
            )
            
            -- Transform position
            local otherPos = cf.Position
            local newPos = vector.create(
                pos.X + right.X * otherPos.X + up.X * otherPos.Y + look.X * otherPos.Z,
                pos.Y + right.Y * otherPos.X + up.Y * otherPos.Y + look.Y * otherPos.Z,
                pos.Z + right.Z * otherPos.X + up.Z * otherPos.Y + look.Z * otherPos.Z
            )
            
            return createCFrameTable(newPos, newRight, newUp, newLook)
        end
    }
})

-- CFrame:ToObjectSpace()
Instance.declare({
    class = "Instance",
    name = "ToObjectSpace",
    callback = {
        method = function(self, cf)
            assert(cf, "CFrame argument required")
            return self:Inverse():ToWorldSpace(cf)
        end
    }
})

-- CFrame:PointToWorldSpace()
Instance.declare({
    class = "Instance",
    name = "PointToWorldSpace",
    callback = {
        method = function(self, point)
            assert(isVector(point), "Vector argument required")
            point = toVector(point)
            
            local pos = self.Position
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            return vector.create(
                pos.X + right.X * point.X + up.X * point.Y + look.X * point.Z,
                pos.Y + right.Y * point.X + up.Y * point.Y + look.Y * point.Z,
                pos.Z + right.Z * point.X + up.Z * point.Y + look.Z * point.Z
            )
        end
    }
})

-- CFrame:PointToObjectSpace()
Instance.declare({
    class = "Instance",
    name = "PointToObjectSpace",
    callback = {
        method = function(self, point)
            assert(isVector(point), "Vector argument required")
            point = toVector(point)
            
            local pos = self.Position
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            local relativePoint = vector.create(
                point.X - pos.X,
                point.Y - pos.Y,
                point.Z - pos.Z
            )
            
            return vector.create(
                vector.dot(relativePoint, right),
                vector.dot(relativePoint, up),
                vector.dot(relativePoint, look)
            )
        end
    }
})

-- CFrame:VectorToWorldSpace()
Instance.declare({
    class = "Instance",
    name = "VectorToWorldSpace",
    callback = {
        method = function(self, vec)
            assert(isVector(vec), "Vector argument required")
            vec = toVector(vec)
            
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            return vector.create(
                right.X * vec.X + up.X * vec.Y + look.X * vec.Z,
                right.Y * vec.X + up.Y * vec.Y + look.Y * vec.Z,
                right.Z * vec.X + up.Z * vec.Y + look.Z * vec.Z
            )
        end
    }
})

-- CFrame:VectorToObjectSpace()
Instance.declare({
    class = "Instance",
    name = "VectorToObjectSpace",
    callback = {
        method = function(self, vec)
            assert(isVector(vec), "Vector argument required")
            vec = toVector(vec)
            
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            return vector.create(
                vector.dot(vec, right),
                vector.dot(vec, up),
                vector.dot(vec, look)
            )
        end
    }
})

-- CFrame:GetComponents()
Instance.declare({
    class = "Instance",
    name = "GetComponents",
    callback = {
        method = function(self)
            local pos = self.Position
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            return pos.X, pos.Y, pos.Z,
                   right.X, up.X, look.X,
                   right.Y, up.Y, look.Y,
                   right.Z, up.Z, look.Z
        end
    }
})

-- CFrame:ToEulerAnglesXYZ()
Instance.declare({
    class = "Instance",
    name = "ToEulerAnglesXYZ",
    callback = {
        method = function(self)
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            local x, y, z
            
            if look.Y < 0.99999 then
                if look.Y > -0.99999 then
                    x = math.atan2(look.Z, math.sqrt(look.X * look.X + look.Y * look.Y))
                    y = math.atan2(-look.X, look.Y)
                    z = math.atan2(right.Y, up.Y)
                else
                    x = -math.pi / 2
                    y = -math.atan2(right.Z, right.X)
                    z = 0
                end
            else
                x = math.pi / 2
                y = math.atan2(right.Z, right.X)
                z = 0
            end
            
            return x, y, z
        end
    }
})

-- CFrame:ToEulerAnglesYXZ()
Instance.declare({
    class = "Instance",
    name = "ToEulerAnglesYXZ",
    callback = {
        method = function(self)
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            local x, y, z
            
            if look.X < 0.99999 then
                if look.X > -0.99999 then
                    y = math.asin(-look.X)
                    x = math.atan2(look.Y, look.Z)
                    z = math.atan2(right.X, up.X)
                else
                    y = math.pi / 2
                    x = -math.atan2(-right.Y, right.Z)
                    z = 0
                end
            else
                y = -math.pi / 2
                x = math.atan2(-right.Y, right.Z)
                z = 0
            end
            
            return x, y, z
        end
    }
})

-- CFrame:ToOrientation()
Instance.declare({
    class = "Instance",
    name = "ToOrientation",
    callback = {
        method = function(self)
            local x, y, z = self:ToEulerAnglesYXZ()
            return math.deg(x), math.deg(y), math.deg(z)
        end
    }
})

-- CFrame:ToAxisAngle()
Instance.declare({
    class = "Instance",
    name = "ToAxisAngle",
    callback = {
        method = function(self)
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            local trace = right.X + up.Y + look.Z
            local angle = math.acos((trace - 1) / 2)
            
            if angle < 0.0001 then
                return vector.create(0, 1, 0), 0
            end
            
            local x = (up.Z - look.Y) / (2 * math.sin(angle))
            local y = (look.X - right.Z) / (2 * math.sin(angle))
            local z = (right.Y - up.X) / (2 * math.sin(angle))
            
            return vector.create(x, y, z), angle
        end
    }
})

-- CFrame:Lerp()
Instance.declare({
    class = "Instance",
    name = "Lerp",
    callback = {
        method = function(self, goal, alpha)
            assert(goal, "Goal CFrame required")
            assert(type(alpha) == "number", "Alpha must be a number")
            alpha = math.max(0, math.min(1, alpha))
            
            -- Lerp position
            local p0 = self.Position
            local p1 = goal.Position
            local newPos = vector.create(
                p0.X + (p1.X - p0.X) * alpha,
                p0.Y + (p1.Y - p0.Y) * alpha,
                p0.Z + (p1.Z - p0.Z) * alpha
            )
            
            -- Slerp rotation using axis-angle
            local relative = self:Inverse():ToWorldSpace(goal)
            local axis, angle = relative:ToAxisAngle()
            
            if angle < 0.0001 then
                -- No rotation needed
                return createCFrameTable(newPos, self.RightVector, self.UpVector, self.LookVector)
            end
            
            -- Scale the angle by alpha
            local scaledAngle = angle * alpha
            local c = math.cos(scaledAngle)
            local s = math.sin(scaledAngle)
            local t = 1 - c
            
            local x, y, z = axis.X, axis.Y, axis.Z
            
            -- Rodrigues' rotation formula to build rotation matrix
            local rotMatrix = {
                {t*x*x + c,    t*x*y - s*z,  t*x*z + s*y},
                {t*x*y + s*z,  t*y*y + c,    t*y*z - s*x},
                {t*x*z - s*y,  t*y*z + s*x,  t*z*z + c}
            }
            
            -- Apply rotation to self's orientation
            local r0 = self.RightVector
            local u0 = self.UpVector
            local l0 = self.LookVector
            
            local newRight = vector.create(
                rotMatrix[1][1]*r0.X + rotMatrix[1][2]*u0.X + rotMatrix[1][3]*l0.X,
                rotMatrix[1][1]*r0.Y + rotMatrix[1][2]*u0.Y + rotMatrix[1][3]*l0.Y,
                rotMatrix[1][1]*r0.Z + rotMatrix[1][2]*u0.Z + rotMatrix[1][3]*l0.Z
            )
            
            local newUp = vector.create(
                rotMatrix[2][1]*r0.X + rotMatrix[2][2]*u0.X + rotMatrix[2][3]*l0.X,
                rotMatrix[2][1]*r0.Y + rotMatrix[2][2]*u0.Y + rotMatrix[2][3]*l0.Y,
                rotMatrix[2][1]*r0.Z + rotMatrix[2][2]*u0.Z + rotMatrix[2][3]*l0.Z
            )
            
            local newLook = vector.create(
                rotMatrix[3][1]*r0.X + rotMatrix[3][2]*u0.X + rotMatrix[3][3]*l0.X,
                rotMatrix[3][1]*r0.Y + rotMatrix[3][2]*u0.Y + rotMatrix[3][3]*l0.Y,
                rotMatrix[3][1]*r0.Z + rotMatrix[3][2]*u0.Z + rotMatrix[3][3]*l0.Z
            )
            
            return createCFrameTable(newPos, newRight, newUp, newLook)
        end
    }
})
-- CFrame:Orthonormalize()
Instance.declare({
    class = "Instance",
    name = "Orthonormalize",
    callback = {
        method = function(self)
            local pos = self.Position
            local right = self.RightVector
            local up = self.UpVector
            local look = self.LookVector
            
            -- Normalize look vector
            local lookMag = math.sqrt(look.X * look.X + look.Y * look.Y + look.Z * look.Z)
            if lookMag > 0 then
                look = vector.create(look.X / lookMag, look.Y / lookMag, look.Z / lookMag)
            end
            
            -- Compute right = up × look
            local newRight = vector.create(
                up.Y * look.Z - up.Z * look.Y,
                up.Z * look.X - up.X * look.Z,
                up.X * look.Y - up.Y * look.X
            )
            
            local rightMag = math.sqrt(newRight.X * newRight.X + newRight.Y * newRight.Y + newRight.Z * newRight.Z)
            if rightMag > 0 then
                newRight = vector.create(newRight.X / rightMag, newRight.Y / rightMag, newRight.Z / rightMag)
            end
            
            -- Compute up = look × right
            local newUp = vector.create(
                look.Y * newRight.Z - look.Z * newRight.Y,
                look.Z * newRight.X - look.X * newRight.Z,
                look.X * newRight.Y - look.Y * newRight.X
            )
            
            return createCFrameTable(pos, newRight, newUp, look)
        end
    }
})

-- CFrame:FuzzyEq()
Instance.declare({
    class = "Instance",
    name = "FuzzyEq",
    callback = {
        method = function(self, other, epsilon)
            assert(other, "Other CFrame required")
            epsilon = epsilon or 0.00001
            
            local p0 = self.Position
            local p1 = other.Position
            
            if math.abs(p0.X - p1.X) > epsilon or
               math.abs(p0.Y - p1.Y) > epsilon or
               math.abs(p0.Z - p1.Z) > epsilon then
                return false
            end
            
            local r0 = self.RightVector
            local r1 = other.RightVector
            local u0 = self.UpVector
            local u1 = other.UpVector
            local l0 = self.LookVector
            local l1 = other.LookVector
            
            return math.abs(r0.X - r1.X) <= epsilon and
                   math.abs(r0.Y - r1.Y) <= epsilon and
                   math.abs(r0.Z - r1.Z) <= epsilon and
                   math.abs(u0.X - u1.X) <= epsilon and
                   math.abs(u0.Y - u1.Y) <= epsilon and
                   math.abs(u0.Z - u1.Z) <= epsilon and
                   math.abs(l0.X - l1.X) <= epsilon and
                   math.abs(l0.Y - l1.Y) <= epsilon and
                   math.abs(l0.Z - l1.Z) <= epsilon
        end
    }
})

Instance.declare({
    class = "Instance",
    name = "AngleBetween",
    callback = {
        method = function(self, other)
            assert(other, "Other CFrame required")
            
            -- Compute relative rotation
            local relative = self:Inverse():ToWorldSpace(other)
            local _, angle = relative:ToAxisAngle()
            
            return angle
        end
    }
})
-- ═══════════════════════════════════════════════════════════
-- SECTION 23: MODEL METHODS
-- ═══════════════════════════════════════════════════════════

-- GetBoundingBox
Instance.declare({
    class = "Model",
    name = "GetBoundingBox",
    callback = {
        GetBoundingBox = function(self)
            local minX, minY, minZ = math.huge, math.huge, math.huge
            local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
            
            local function processDescendants(parent)
                for _, child in ipairs(parent:GetChildren()) do
                    if child.ClassName == "Part" or child.ClassName == "MeshPart" or child.ClassName == "UnionOperation" or child.ClassName == "TrussPart" then
                        local pos = child.Position
                        local size = child.Size
                        
                        minX = math.min(minX, pos.X - size.X / 2)
                        minY = math.min(minY, pos.Y - size.Y / 2)
                        minZ = math.min(minZ, pos.Z - size.Z / 2)
                        
                        maxX = math.max(maxX, pos.X + size.X / 2)
                        maxY = math.max(maxY, pos.Y + size.Y / 2)
                        maxZ = math.max(maxZ, pos.Z + size.Z / 2)
                    end
                    processDescendants(child)
                end
            end
            
            processDescendants(self)
            
            if minX == math.huge then
                -- No parts found
                return createCFrameTable(
                    vector.create(0, 0, 0),
                    vector.create(1, 0, 0),
                    vector.create(0, 1, 0),
                    vector.create(0, 0, 1)
                ), vector.create(0, 0, 0)
            end
            
            local centerX = (minX + maxX) / 2
            local centerY = (minY + maxY) / 2
            local centerZ = (minZ + maxZ) / 2
            
            local sizeX = maxX - minX
            local sizeY = maxY - minY
            local sizeZ = maxZ - minZ
            
            return createCFrameTable(
                vector.create(centerX, centerY, centerZ),
                vector.create(1, 0, 0),
                vector.create(0, 1, 0),
                vector.create(0, 0, 1)
            ), vector.create(sizeX, sizeY, sizeZ)
        end
    }
})



local classHierarchy = {
    Instance = {},
    BasePart = {"Instance"},
    Part = {"BasePart", "Instance"},
    MeshPart = {"BasePart", "Instance"},
    UnionOperation = {"BasePart", "Instance"},
    TrussPart = {"BasePart", "Instance"},
    WedgePart = {"BasePart", "Instance"},
    CornerWedgePart = {"BasePart", "Instance"},
    SpawnLocation = {"BasePart", "Instance"},
    Seat = {"BasePart", "Instance"},
    VehicleSeat = {"BasePart", "Instance"},
    Model = {"Instance"},
    Folder = {"Instance"},
    Tool = {"Instance"},
    Accessory = {"Instance"},
    Hat = {"Instance"},
    GuiObject = {"Instance"},
    Frame = {"GuiObject", "Instance"},
    ScrollingFrame = {"GuiObject", "Instance"},
    TextLabel = {"GuiObject", "Instance"},
    TextButton = {"GuiObject", "Instance"},
    TextBox = {"GuiObject", "Instance"},
    ImageLabel = {"GuiObject", "Instance"},
    ImageButton = {"GuiObject", "Instance"},
    ScreenGui = {"Instance"},
    BillboardGui = {"Instance"},
    SurfaceGui = {"Instance"},
    Humanoid = {"Instance"},
    Player = {"Instance"},
    Camera = {"Instance"},
    Sound = {"Instance"},
    ParticleEmitter = {"Instance"},
    Attachment = {"Instance"},
    BaseScript = {"Instance"},
    Script = {"BaseScript", "Instance"},
    LocalScript = {"BaseScript", "Instance"},
    ModuleScript = {"BaseScript", "Instance"},
    RemoteEvent = {"Instance"},
    RemoteFunction = {"Instance"},
    BindableEvent = {"Instance"},
    BindableFunction = {"Instance"},
    ValueBase = {"Instance"},
    Vector3Value = {"ValueBase", "Instance"},
    StringValue = {"ValueBase", "Instance"},
    NumberValue = {"ValueBase", "Instance"},
    BoolValue = {"ValueBase", "Instance"},
    IntValue = {"ValueBase", "Instance"},
    ObjectValue = {"ValueBase", "Instance"},
    Motor6D = {"Instance"},
    Decal = {"Instance"},
    Shirt = {"Instance"},
    BodyColors = {"Instance"},
    Animator = {"Instance"}
}

local function registerIsA(classes)
    Instance.declare({
        class = classes,
        name = "IsA",
        callback = {
            method = function(self, targetClass)
                local s, r = pcall(function()
                    assert(self, "Self is nil")
                    assert(type(targetClass) == "string", "TargetClass must be a string")

                    local myClass = self.ClassName
                    if myClass == targetClass then
                        return true
                    end
                    
                    local parents = classHierarchy[myClass]
                    if parents then
                        for _, parent in ipairs(parents) do
                            if parent == targetClass then
                                return true
                            end
                        end
                    end
                    return false
                end)
                
                if s then return r else warn("IsA Error:", r) return false end
            end
        }
    })
end

-- Registering IsA for all groups
registerIsA({"Instance", "ServiceProvider", "DataModel", "Workspace", "Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst"})
registerIsA({"ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer", "Teams", "SoundService", "Chat"})
registerIsA({"LocalizationService", "MarketplaceService", "TeleportService", "UserInputService", "RunService", "ContextActionService"})
registerIsA({"HttpService", "TweenService", "CollectionService", "PhysicsService", "PathfindingService", "BadgeService", "InsertService"})
registerIsA({"BasePart", "Part", "MeshPart", "UnionOperation", "TrussPart", "WedgePart", "CornerWedgePart", "SpawnLocation"})
registerIsA({"Seat", "VehicleSeat", "Model", "Folder", "Configuration", "Tool", "HopperBin", "Accessory", "Hat"})
registerIsA({"ScreenGui", "BillboardGui", "SurfaceGui", "GuiObject", "GuiBase2d", "Frame", "ScrollingFrame", "TextLabel"})
registerIsA({"TextButton", "TextBox", "ImageLabel", "ImageButton", "ViewportFrame", "VideoFrame", "Humanoid", "HumanoidDescription"})
registerIsA({"Player", "Backpack", "PlayerGui", "StarterGear", "Camera", "PointLight", "SpotLight", "SurfaceLight"})
registerIsA({"Sky", "Atmosphere", "BloomEffect", "BlurEffect", "ColorCorrectionEffect", "DepthOfFieldEffect", "SunRaysEffect", "Sound"})
registerIsA({"SoundGroup", "ParticleEmitter", "Smoke", "Fire", "Sparkles", "Trail", "Beam", "Attachment"})
registerIsA({"Bone", "Constraint", "AlignOrientation", "AlignPosition", "BallSocketConstraint", "HingeConstraint", "LineForce", "Torque"})
registerIsA({"VectorForce", "RodConstraint", "RopeConstraint", "SpringConstraint", "WeldConstraint", "UniversalConstraint", "CylindricalConstraint"})
registerIsA({"PrismaticConstraint", "JointInstance", "Motor", "Motor6D", "Weld", "ManualWeld", "Snap", "Glue"})
registerIsA({"BodyMover", "BodyForce", "BodyGyro", "BodyPosition", "BodyThrust", "BodyVelocity", "RocketPropulsion", "BaseScript"})
registerIsA({"Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction", "ValueBase"})
registerIsA({"Vector3Value", "CFrameValue", "BoolValue", "StringValue", "NumberValue", "IntValue", "ObjectValue", "Color3Value"})
registerIsA({"BrickColorValue", "RayValue", "Shirt", "Pants", "ShirtGraphic", "BodyColors", "CharacterMesh", "Clothing"})
registerIsA({"Animator", "Animation", "AnimationController", "AnimationTrack", "Keyframe", "KeyframeSequence", "Pose", "Decal"})
registerIsA({"Texture", "SurfaceAppearance", "DataModelMesh", "FileMesh", "SpecialMesh", "BlockMesh", "CylinderMesh", "ClickDetector"})
registerIsA({"ProximityPrompt", "Terrain", "Team", "WrapTarget", "WrapLayer", "Highlight", "SelectionBox", "SelectionSphere"})
registerIsA({"Handles", "ArcHandles", "ForceField", "Explosion", "LocalizationTable", "Hint", "Message", "Dialog"})
registerIsA({"DialogChoice", "NoCollisionConstraint", "Path", "PathfindingLink", "PathfindingModifier", "UIAspectRatioConstraint", "UICorner"})
registerIsA({"UIGradient", "UIGridLayout", "UIListLayout", "UIPageLayout", "UIScale", "UISizeConstraint", "UIStroke", "UIPadding"})


Instance.declare({
    class = "Instance",
    name = "GetFullName",
    callback = {
        method = function(self)
            if not self then
                return "nil"
            end
            
            local path = {}
            local current = self
            
            -- Build path from current instance up to game
            while current do
                local success, name = pcall(function()
                    return current.Name
                end)
                
                if success and name then
                    table.insert(path, 1, name)
                else
                    break
                end
                
                -- Get parent
                local parentSuccess, parent = pcall(function()
                    return current.Parent
                end)
                
                if not parentSuccess or not parent then
                    break
                end
                
                current = parent
                
                -- Stop at DataModel (game)
                if current.ClassName == "DataModel" then
                    table.insert(path, 1, "game")
                    break
                end
            end
            
            if #path == 0 then
                return "game"
            end
            
            return table.concat(path, ".")
        end
    }
})


print("loaded")

---- Environment ----
local getpressedkeys = getpressedkeys
local isleftpressed = isleftpressed
local isrightpressed = isrightpressed
local getmouseposition = getmouseposition
local isrbxactive = isrbxactive
local task_spawn = task.spawn
local task_wait = task.wait

---- Constants ----
local UPDATE_RATE = 1 / 240

local KeyNameToKeyCode = {
    A = 97, B = 98, C = 99, D = 100, E = 101, F = 102, G = 103, H = 104,
    I = 105, J = 106, K = 107, L = 108, M = 109, N = 110, O = 111, P = 112,
    Q = 113, R = 114, S = 115, T = 116, U = 117, V = 118, W = 119, X = 120,
    Y = 121, Z = 122,
    
    -- Numbers
    ["0"] = 48, ["1"] = 49, ["2"] = 50, ["3"] = 51, ["4"] = 52,
    ["5"] = 53, ["6"] = 54, ["7"] = 55, ["8"] = 56, ["9"] = 57,
    
    -- Function keys
    F1 = 282, F2 = 283, F3 = 284, F4 = 285, F5 = 286, F6 = 287,
    F7 = 288, F8 = 289, F9 = 290, F10 = 291, F11 = 292, F12 = 293,
    
    -- Special keys
    Space = 32,
    Backspace = 8,
    Tab = 9,
    Return = 13,
    Enter = 13,
    Escape = 27,
    Delete = 127,
    
    -- Modifiers
    LeftShift = 304,
    RightShift = 303,
    LeftControl = 306,
    RightControl = 305,
    LeftAlt = 308,
    RightAlt = 307,
    CapsLock = 301,
    
    -- Arrow keys
    Up = 273,
    Down = 274,
    Left = 276,
    Right = 275,
    
    -- Navigation
    Insert = 277,
    Home = 278,
    End = 279,
    PageUp = 280,
    PageDown = 281,
    
    -- Punctuation
    LeftBracket = 91,
    RightBracket = 93,
    BackSlash = 92,
    Slash = 47,
    Period = 46,
    Comma = 44,
    Quote = 39,
    Semicolon = 59,
    Minus = 45,
    Equals = 61,
    Backquote = 96,
    
    LeftMouse = 0,
    RightMouse = 0,
    MiddleMouse = 0,
}

local function convertKeyNameToKeyCode(keyName)
    if type(keyName) == "number" then
        return keyName
    end
    return KeyNameToKeyCode[keyName] or 0
end

RobloxSignal = {}
RobloxSignal.__index = RobloxSignal

function RobloxSignal.new()
    return setmetatable({_signal = Signal.new()}, RobloxSignal)
end

function RobloxSignal:Connect(callback)
    local conn = self._signal:connect(callback)
    return {
        Connected = true,
        Disconnect = function(self)
            if self.Connected then
                conn:disconnect()
                self.Connected = false
            end
        end
    }
end

function RobloxSignal:Fire(...)
    self._signal:fire(...)
end

function RobloxSignal:Wait()
    return self._signal:wait()
end

function RobloxSignal:Once(callback)
	local conn
	conn = self:Connect(function(...)
		if conn and conn.Connected then
			conn:Disconnect()
		end
		callback(...)
	end)
	return conn
end

---- InputObject Class ----
local InputObject = {}
InputObject.__index = InputObject

function InputObject.new(inputType, keyCode, userInputState, delta, position)
    return setmetatable({
        UserInputType = inputType,
        KeyCode = keyCode,
        UserInputState = userInputState,
        Delta = delta or vector.create(0, 0, 0),
        Position = position or vector.create(0, 0, 0)
    }, InputObject)
end

---- State ----
local previousKeys = {}
local previousMouse1, previousMouse2 = false, false
local previousMousePosition = vector.create(0, 0, 0)
local previousWindowFocused = true

local InputBegan = RobloxSignal.new()
local InputEnded = RobloxSignal.new()
local InputChanged = RobloxSignal.new()
local WindowFocusReleased = RobloxSignal.new()
local WindowFocused = RobloxSignal.new()

---- Process Input ----
local function processInput()
    local currentKeyNames = getpressedkeys()  
    local currentMouse1 = isleftpressed()
    local currentMouse2 = isrightpressed()
    local currentMousePos = getmouseposition()
    local currentWindowFocused = isrbxactive()
    
    local currentKeysMap = {}
    for _, keyName in ipairs(currentKeyNames) do
        if keyName ~= "LeftMouse" and keyName ~= "RightMouse" and keyName ~= "MiddleMouse" then
            local keyCode = convertKeyNameToKeyCode(keyName)
            if keyCode ~= 0 then
                currentKeysMap[keyCode] = true
                
                if not previousKeys[keyCode] then
                    InputBegan:Fire(
                        InputObject.new(
                            Enum.UserInputType.Keyboard,
                            keyCode,
                            Enum.UserInputState.Begin,
                            vector.create(0, 0, 0),
                            currentMousePos
                        ),
                        false
                    )
                end
            end
        end
    end
    
    for keyCode, _ in pairs(previousKeys) do
        if not currentKeysMap[keyCode] then
            InputEnded:Fire(
                InputObject.new(
                    Enum.UserInputType.Keyboard,
                    keyCode,
                    Enum.UserInputState.End,
                    vector.create(0, 0, 0),
                    currentMousePos
                ),
                false
            )
        end
    end
    
    previousKeys = currentKeysMap
    
    if currentMouse1 ~= previousMouse1 then
        if currentMouse1 then
            InputBegan:Fire(
                InputObject.new(
                    Enum.UserInputType.MouseButton1,
                    Enum.KeyCode.Unknown,
                    Enum.UserInputState.Begin,
                    vector.create(0, 0, 0),
                    currentMousePos
                ),
                false
            )
        else
            InputEnded:Fire(
                InputObject.new(
                    Enum.UserInputType.MouseButton1,
                    Enum.KeyCode.Unknown,
                    Enum.UserInputState.End,
                    vector.create(0, 0, 0),
                    currentMousePos
                ),
                false
            )
        end
        previousMouse1 = currentMouse1
    end
    
    if currentMouse2 ~= previousMouse2 then
        if currentMouse2 then
            InputBegan:Fire(
                InputObject.new(
                    Enum.UserInputType.MouseButton2,
                    Enum.KeyCode.Unknown,
                    Enum.UserInputState.Begin,
                    vector.create(0, 0, 0),
                    currentMousePos
                ),
                false
            )
        else
            InputEnded:Fire(
                InputObject.new(
                    Enum.UserInputType.MouseButton2,
                    Enum.KeyCode.Unknown,
                    Enum.UserInputState.End,
                    vector.create(0, 0, 0),
                    currentMousePos
                ),
                false
            )
        end
        previousMouse2 = currentMouse2
    end
    
    if currentMousePos.X ~= previousMousePosition.X or currentMousePos.Y ~= previousMousePosition.Y then
        local delta = vector.create(
            currentMousePos.X - previousMousePosition.X,
            currentMousePos.Y - previousMousePosition.Y,
            0
        )
        InputChanged:Fire(
            InputObject.new(
                Enum.UserInputType.MouseMovement,
                Enum.KeyCode.Unknown,
                Enum.UserInputState.Change,
                delta,
                currentMousePos
            ),
            false
        )
        previousMousePosition = currentMousePos
    end
    
    if currentWindowFocused ~= previousWindowFocused then
        if currentWindowFocused then
            WindowFocused:Fire()
        else
            WindowFocusReleased:Fire()
        end
        previousWindowFocused = currentWindowFocused
    end
end

---- Start Loop ----
previousMouse1 = isleftpressed()
previousMouse2 = isrightpressed()
previousMousePosition = getmouseposition()
previousWindowFocused = isrbxactive()

task_spawn(function()
    while true do
        pcall(processInput)
        task_wait(UPDATE_RATE)
    end
end)

---- Declare Methods ----
Instance.declare({
    class = "UserInputService",
    name = "IsKeyDown",
    callback = {
        method = function(self, keyCode)
            local pressedKeyNames = getpressedkeys()
            for _, keyName in ipairs(pressedKeyNames) do
                if convertKeyNameToKeyCode(keyName) == keyCode then
                    return true
                end
            end
            return false
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "IsMouseButtonPressed",
    callback = {
        method = function(self, mouseButton)
            if mouseButton == 0 then
                return isleftpressed()
            elseif mouseButton == 1 then
                return isrightpressed()
            end
            return false
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "GetKeysPressed",
    callback = {
        method = function(self)
            local pressedKeyNames = getpressedkeys()
            local inputObjects = {}
            for _, keyName in ipairs(pressedKeyNames) do
                if keyName ~= "LeftMouse" and keyName ~= "RightMouse" and keyName ~= "MiddleMouse" then
                    local keyCode = convertKeyNameToKeyCode(keyName)
                    if keyCode ~= 0 then
                        table.insert(inputObjects, InputObject.new(
                            Enum.UserInputType.Keyboard,
                            keyCode,
                            Enum.UserInputState.Begin,
                            vector.create(0, 0, 0),
                            vector.create(0, 0, 0)
                        ))
                    end
                end
            end
            return inputObjects
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "GetMouseButtonsPressed",
    callback = {
        method = function(self)
            local buttons = {}
            if isleftpressed() then
                table.insert(buttons, InputObject.new(
                    Enum.UserInputType.MouseButton1,
                    Enum.KeyCode.Unknown,
                    Enum.UserInputState.Begin,
                    vector.create(0, 0, 0),
                    getmouseposition()
                ))
            end
            if isrightpressed() then
                table.insert(buttons, InputObject.new(
                    Enum.UserInputType.MouseButton2,
                    Enum.KeyCode.Unknown,
                    Enum.UserInputState.Begin,
                    vector.create(0, 0, 0),
                    getmouseposition()
                ))
            end
            return buttons
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "GetMouseLocation",
    callback = {
        method = function(self)
            return getmouseposition()
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "InputBegan",
    callback = {
        get = function(self)
            return InputBegan
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "InputEnded",
    callback = {
        get = function(self)
            return InputEnded
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "InputChanged",
    callback = {
        get = function(self)
            return InputChanged
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "WindowFocusReleased",
    callback = {
        get = function(self)
            return WindowFocusReleased
        end
    }
})

Instance.declare({
    class = "UserInputService",
    name = "WindowFocused",
    callback = {
        get = function(self)
            return WindowFocused
        end
    }
})

print("fon")

-- ═══════════════════════════════════════════════════════════
-- ---- ENVIRONMENT ----
-- ═══════════════════════════════════════════════════════════

local game = game
local typeof, pcall = typeof, pcall
local setmetatable = setmetatable

local tableinsert = table.insert
local tableremove = table.remove

local taskspawn = task.spawn
local taskwait = task.wait

-- ═══════════════════════════════════════════════════════════
-- ---- CONSTANTS ----
-- ═══════════════════════════════════════════════════════════

local POLL_INTERVAL = 0.1

-- ═══════════════════════════════════════════════════════════
-- ---- VARIABLES ----
-- ═══════════════════════════════════════════════════════════

local childTrackers = {}
local propertyWatchers = {}

-- ═══════════════════════════════════════════════════════════
-- ---- CHILD TRACKING ----
-- ═══════════════════════════════════════════════════════════

local function startChildTracker(instance)
    if childTrackers[instance] then
        return childTrackers[instance]
    end
    
    local tracker = {
        ChildAdded = RobloxSignal.new(),
        ChildRemoved = RobloxSignal.new(),
        lastChildren = {},
        active = true
    }
    
    -- Get initial children
    local success, children = pcall(function()
        return instance:GetChildren()
    end)
    
    if success and children then
        for _, child in children do
            tracker.lastChildren[child] = true
        end
    end
    
    -- Start polling loop
    taskspawn(function()
        while tracker.active do
            taskwait(POLL_INTERVAL)
            
            -- Check if instance still valid
            local success, parent = pcall(function()
                return instance.Parent
            end)
            
            if not success or (not parent and instance ~= game) then
                tracker.active = false
                childTrackers[instance] = nil
                break
            end
            
            -- Get current children
            local success2, currentChildren = pcall(function()
                return instance:GetChildren()
            end)
            
            if not success2 or not currentChildren then
                break
            end
            
            local currentSet = {}
            
            -- Find added
            for _, child in currentChildren do
                currentSet[child] = true
                if not tracker.lastChildren[child] then
                    pcall(function()
                        tracker.ChildAdded:Fire(child)
                    end)
                end
            end
            
            -- Find removed
            for child in tracker.lastChildren do
                if not currentSet[child] then
                    pcall(function()
                        tracker.ChildRemoved:Fire(child)
                    end)
                end
            end
            
            tracker.lastChildren = currentSet
        end
    end)
    
    childTrackers[instance] = tracker
    return tracker
end

-- ═══════════════════════════════════════════════════════════
-- ---- PROPERTY TRACKING ----
-- ═══════════════════════════════════════════════════════════

local function startPropertyWatcher(instance, propName)
    if not propertyWatchers[instance] then
        propertyWatchers[instance] = {}
    end
    
    if propertyWatchers[instance][propName] then
        return propertyWatchers[instance][propName]
    end
    
    local signal = RobloxSignal.new()
    local lastValue = nil
    local active = true
    
    -- Get initial value
    pcall(function()
        lastValue = instance[propName]
    end)
    
    -- Start polling loop
    taskspawn(function()
        while active do
            taskwait(POLL_INTERVAL)
            
            local success, currentValue = pcall(function()
                return instance[propName]
            end)
            
            if not success then
                active = false
                propertyWatchers[instance][propName] = nil
                break
            end
            
            if currentValue ~= lastValue then
                lastValue = currentValue
                pcall(function()
                    signal:Fire()
                end)
            end
        end
    end)
    
    propertyWatchers[instance][propName] = signal
    return signal
end

-- ═══════════════════════════════════════════════════════════
-- ---- INSTANCE EXTENSIONS ----
-- ═══════════════════════════════════════════════════════════

local function registerEvents(classes)
    -- ChildAdded
    Instance.declare({
        class = classes,
        name = "ChildAdded",
        callback = {
            get = function(self)
                local success, tracker = pcall(function()
                    return startChildTracker(self)
                end)
                
                if success and tracker then
                    return tracker.ChildAdded
                end
                
                return RobloxSignal.new()
            end
        }
    })
    
    -- ChildRemoved
    Instance.declare({
        class = classes,
        name = "ChildRemoved",
        callback = {
            get = function(self)
                local success, tracker = pcall(function()
                    return startChildTracker(self)
                end)
                
                if success and tracker then
                    return tracker.ChildRemoved
                end
                
                return RobloxSignal.new()
            end
        }
    })
    
    -- GetPropertyChangedSignal
    Instance.declare({
        class = classes,
        name = "GetPropertyChangedSignal",
        callback = {
            method = function(self, propName)
                local success, signal = pcall(function()
                    return startPropertyWatcher(self, propName)
                end)
                
                if success and signal then
                    return signal
                end
                
                return RobloxSignal.new()
            end
        }
    })
end

-- ═══════════════════════════════════════════════════════════
-- ---- RUNTIME ----
-- ═══════════════════════════════════════════════════════════

local allClasses = {
    "Instance", "Workspace", "Model", "Part", "MeshPart", "Folder",
    "Frame", "ScreenGui", "Players", "Player", "Humanoid"
}

registerEvents(allClasses)

-- Players aliases
Instance.declare({
    class = "Players",
    name = "PlayerAdded",
    callback = {
        get = function(self)
            local success, tracker = pcall(function()
                return startChildTracker(self)
            end)
            
            if success and tracker then
                return tracker.ChildAdded
            end
            
            return RobloxSignal.new()
        end
    }
})

Instance.declare({
    class = "Players",
    name = "PlayerRemoved",
    callback = {
        get = function(self)
            local success, tracker = pcall(function()
                return startChildTracker(self)
            end)
            
            if success and tracker then
                return tracker.ChildRemoved
            end
            
            return RobloxSignal.new()
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: CONFIGURATION & CONSTANTS
-- ═══════════════════════════════════════════════════════════

local TweenService = {}

-- Performance settings
local TARGET_FPS = 144
local MIN_FRAME_TIME = 1 / 240
local MAX_FRAME_TIME = 1 / 30
local UPDATE_INTERVAL = 1 / TARGET_FPS

-- Animation registry
local _activeAnimations = {}
local _isProcessing = false
local _updateThread = nil
local _previousTickTime = 0

-- Validation tables (for internal use)
local VALID_EASING_STYLES = {
    Back = true, Bounce = true, Circ = true, Cubic = true,
    Elastic = true, Expo = true, Linear = true, Quad = true,
    Quart = true, Quint = true, Sine = true
}

local VALID_EASING_DIRECTIONS = {
    In = true, Out = true, InOut = true
}


-- ═══════════════════════════════════════════════════════════
-- SECTION 3: UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function getCurrentTime()
    local success, result = pcall(function()
        return tick()
    end)
    if success then
        return result
    else
        return os.clock()
    end
end

local function isVectorType(obj)
    local objType = type(obj)
    if objType == "vector" then return true end
    
    local typeofResult = typeof(obj)
    if typeofResult == "Vector3" then return true end
    
    if objType == "table" then
        return obj.X ~= nil and obj.Y ~= nil and obj.Z ~= nil
    end
    
    return false
end

local function toUnifiedVector(v)
    assert(v, "[TweenService] Vector value is nil")
    
    local vType = type(v)
    if vType == "vector" then
        return v
    end
    
    local typeofV = typeof(v)
    if typeofV == "Vector3" then
        return vector.create(v.X, v.Y, v.Z)
    end
    
    if vType == "table" and v.X and v.Y and v.Z then
        return vector.create(v.X, v.Y, v.Z)
    end
    
    error("[TweenService] Invalid vector type provided")
end

local function isCFrameType(obj)
    if type(obj) ~= "table" then
        return false
    end
    if obj.type == "Vector" then
        return false
    end
    return obj.Position ~= nil and (obj.RightVector ~= nil or obj.LookVector ~= nil or obj.UpVector ~= nil)
end

local function validateInstanceProperty(instance, propName)
    if not instance then
        warn("[TweenService] Instance is nil")
        return false
    end
    
    if not instance.Data or instance.Data == 0 then
        warn(string.format("[TweenService] Instance has invalid Data pointer for property '%s'", propName))
        return false
    end
    
    local success, value = pcall(function()
        return instance[propName]
    end)
    
    if not success then
        warn(string.format("[TweenService] Property '%s' is not accessible on %s", 
            propName, instance.ClassName or "unknown"))
        return false
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 4: INTERPOLATION SYSTEM
-- ═══════════════════════════════════════════════════════════

local function interpolateNumber(start, finish, alpha)
    return start + (finish - start) * alpha
end

local function interpolateVector(startVec, endVec, alpha)
    local sv = toUnifiedVector(startVec)
    local ev = toUnifiedVector(endVec)
    
    return vector.create(
        sv.X + (ev.X - sv.X) * alpha,
        sv.Y + (ev.Y - sv.Y) * alpha,
        sv.Z + (ev.Z - sv.Z) * alpha
    )
end

-- Quaternion helpers
local function quaternionFromCFrame(cf)
    local trace = cf.RightVector.X + cf.UpVector.Y + cf.LookVector.Z
    
    if trace > 0 then
        local s = math.sqrt(1 + trace) * 2
        return {
            w = 0.25 * s,
            x = (cf.UpVector.Z - cf.LookVector.Y) / s,
            y = (cf.LookVector.X - cf.RightVector.Z) / s,
            z = (cf.RightVector.Y - cf.UpVector.X) / s
        }
    elseif cf.RightVector.X > cf.UpVector.Y and cf.RightVector.X > cf.LookVector.Z then
        local s = math.sqrt(1 + cf.RightVector.X - cf.UpVector.Y - cf.LookVector.Z) * 2
        return {
            w = (cf.UpVector.Z - cf.LookVector.Y) / s,
            x = 0.25 * s,
            y = (cf.UpVector.X + cf.RightVector.Y) / s,
            z = (cf.LookVector.X + cf.RightVector.Z) / s
        }
    elseif cf.UpVector.Y > cf.LookVector.Z then
        local s = math.sqrt(1 + cf.UpVector.Y - cf.RightVector.X - cf.LookVector.Z) * 2
        return {
            w = (cf.LookVector.X - cf.RightVector.Z) / s,
            x = (cf.UpVector.X + cf.RightVector.Y) / s,
            y = 0.25 * s,
            z = (cf.LookVector.Y + cf.UpVector.Z) / s
        }
    else
        local s = math.sqrt(1 + cf.LookVector.Z - cf.RightVector.X - cf.UpVector.Y) * 2
        return {
            w = (cf.RightVector.Y - cf.UpVector.X) / s,
            x = (cf.LookVector.X + cf.RightVector.Z) / s,
            y = (cf.LookVector.Y + cf.UpVector.Z) / s,
            z = 0.25 * s
        }
    end
end

local function quaternionToRotationMatrix(q)
    local qx, qy, qz, qw = q.x, q.y, q.z, q.w
    
    local x2 = qx + qx
    local y2 = qy + qy
    local z2 = qz + qz
    
    local xx2 = qx * x2
    local xy2 = qx * y2
    local xz2 = qx * z2
    
    local yy2 = qy * y2
    local yz2 = qy * z2
    local zz2 = qz * z2
    
    local wx2 = qw * x2
    local wy2 = qw * y2
    local wz2 = qw * z2
    
    local right = vector.create(
        1 - (yy2 + zz2),
        xy2 + wz2,
        xz2 - wy2
    )
    
    local up = vector.create(
        xy2 - wz2,
        1 - (xx2 + zz2),
        yz2 + wx2
    )
    
    local look = vector.create(
        xz2 + wy2,
        yz2 - wx2,
        1 - (xx2 + yy2)
    )
    
    return right, up, look
end

local function quaternionSlerp(q1, q2, alpha)
    local dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w
    
    local q2_adjusted = q2
    if dot < 0 then
        q2_adjusted = {x = -q2.x, y = -q2.y, z = -q2.z, w = -q2.w}
        dot = -dot
    end
    
    dot = math.clamp(dot, -1, 1)
    
    if dot > 0.9995 then
        local result = {
            x = q1.x + alpha * (q2_adjusted.x - q1.x),
            y = q1.y + alpha * (q2_adjusted.y - q1.y),
            z = q1.z + alpha * (q2_adjusted.z - q1.z),
            w = q1.w + alpha * (q2_adjusted.w - q1.w)
        }
        
        local len = math.sqrt(result.x * result.x + result.y * result.y + 
                              result.z * result.z + result.w * result.w)
        if len > 0 then
            result.x = result.x / len
            result.y = result.y / len
            result.z = result.z / len
            result.w = result.w / len
        end
        
        return result
    end
    
    local theta = math.acos(dot)
    local sinTheta = math.sin(theta)
    
    local scale1 = math.sin((1 - alpha) * theta) / sinTheta
    local scale2 = math.sin(alpha * theta) / sinTheta
    
    return {
        x = scale1 * q1.x + scale2 * q2_adjusted.x,
        y = scale1 * q1.y + scale2 * q2_adjusted.y,
        z = scale1 * q1.z + scale2 * q2_adjusted.z,
        w = scale1 * q1.w + scale2 * q2_adjusted.w
    }
end

local function interpolateCFrame(cf1, cf2, alpha)
    if not cf1 or not cf2 then
        warn("[TweenService] interpolateCFrame: nil CFrame detected")
        return cf1 or cf2
    end
    
    if not cf1.Position or not cf2.Position then
        warn("[TweenService] interpolateCFrame: CFrame missing Position")
        return cf2
    end
    
    local p1 = cf1.Position
    local p2 = cf2.Position
    local newPos = vector.create(
        p1.X + (p2.X - p1.X) * alpha,
        p1.Y + (p2.Y - p1.Y) * alpha,
        p1.Z + (p2.Z - p1.Z) * alpha
    )
    
    local q1 = quaternionFromCFrame(cf1)
    local q2 = quaternionFromCFrame(cf2)
    local qResult = quaternionSlerp(q1, q2, alpha)
    local right, up, look = quaternionToRotationMatrix(qResult)
    
    local fixedLook = vector.create(-look.X, -look.Y, -look.Z)
    local lookAtPoint = vector.create(
        newPos.X + fixedLook.X,
        newPos.Y + fixedLook.Y,
        newPos.Z + fixedLook.Z
    )
    
    return CFrame.lookAt(newPos, lookAtPoint, up)
end

local function interpolateTable(startTable, endTable, alpha)
    local result = {}
    
    for key, startValue in pairs(startTable) do
        if endTable[key] then
            local endValue = endTable[key]
            
            if type(startValue) == "number" and type(endValue) == "number" then
                result[key] = interpolateNumber(startValue, endValue, alpha)
            elseif isVectorType(startValue) and isVectorType(endValue) then
                result[key] = interpolateVector(startValue, endValue, alpha)
            else
                result[key] = endValue
            end
        else
            result[key] = startValue
        end
    end
    
    return result
end

local function interpolateValue(startVal, endVal, alpha)
    local startType = type(startVal)
    local endType = type(endVal)
    
    if startType == "number" and endType == "number" then
        return interpolateNumber(startVal, endVal, alpha)
    elseif isVectorType(startVal) and isVectorType(endVal) then
        return interpolateVector(startVal, endVal, alpha)
    elseif isCFrameType(startVal) and isCFrameType(endVal) then
        return interpolateCFrame(startVal, endVal, alpha)
    elseif startType == "table" and endType == "table" then
        return interpolateTable(startVal, endVal, alpha)
    else
        return endVal
    end
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 5: EASING FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local EasingLibrary = {}

-- Back easing
EasingLibrary.Back = {
    In = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * t * t * t - c1 * t * t
    end,
    
    Out = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
    end,
    
    InOut = function(t)
        local c1 = 1.70158
        local c2 = c1 * 1.525
        if t < 0.5 then
            return ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) / 2
        else
            return ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
        end
    end
}

-- Bounce easing
EasingLibrary.Bounce = {
    Out = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end
}

EasingLibrary.Bounce.In = function(t)
    return 1 - EasingLibrary.Bounce.Out(1 - t)
end

EasingLibrary.Bounce.InOut = function(t)
    if t < 0.5 then
        return (1 - EasingLibrary.Bounce.Out(1 - 2 * t)) / 2
    else
        return (1 + EasingLibrary.Bounce.Out(2 * t - 1)) / 2
    end
end

-- Circ easing
EasingLibrary.Circ = {
    In = function(t)
        return 1 - math.sqrt(1 - t ^ 2)
    end,
    
    Out = function(t)
        return math.sqrt(1 - (t - 1) ^ 2)
    end,
    
    InOut = function(t)
        if t < 0.5 then
            return (1 - math.sqrt(1 - (2 * t) ^ 2)) / 2
        else
            return (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
        end
    end
}

-- Cubic easing
EasingLibrary.Cubic = {
    In = function(t)
        return t * t * t
    end,
    
    Out = function(t)
        return 1 - (1 - t) ^ 3
    end,
    
    InOut = function(t)
        if t < 0.5 then
            return 4 * t * t * t
        else
            return 1 - (-2 * t + 2) ^ 3 / 2
        end
    end
}

-- Elastic easing
EasingLibrary.Elastic = {
    In = function(t)
        local c4 = (2 * math.pi) / 3
        if t == 0 then
            return 0
        elseif t == 1 then
            return 1
        else
            return -(2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
        end
    end,
    
    Out = function(t)
        local c4 = (2 * math.pi) / 3
        if t == 0 then
            return 0
        elseif t == 1 then
            return 1
        else
            return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
        end
    end,
    
    InOut = function(t)
        local c5 = (2 * math.pi) / 4.5
        if t == 0 then
            return 0
        elseif t == 1 then
            return 1
        elseif t < 0.5 then
            return -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
        else
            return (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
        end
    end
}

-- Expo easing
EasingLibrary.Expo = {
    In = function(t)
        return t == 0 and 0 or 2 ^ (10 * t - 10)
    end,
    
    Out = function(t)
        return t == 1 and 1 or 1 - 2 ^ (-10 * t)
    end,
    
    InOut = function(t)
        if t == 0 then
            return 0
        elseif t == 1 then
            return 1
        elseif t < 0.5 then
            return 2 ^ (20 * t - 10) / 2
        else
            return (2 - 2 ^ (-20 * t + 10)) / 2
        end
    end
}

-- Linear easing
EasingLibrary.Linear = function(t)
    return t
end

-- Quad easing
EasingLibrary.Quad = {
    In = function(t)
        return t * t
    end,
    
    Out = function(t)
        return 1 - (1 - t) * (1 - t)
    end,
    
    InOut = function(t)
        if t < 0.5 then
            return 2 * t * t
        else
            return 1 - (-2 * t + 2) ^ 2 / 2
        end
    end
}

-- Quart easing
EasingLibrary.Quart = {
    In = function(t)
        return t * t * t * t
    end,
    
    Out = function(t)
        return 1 - (1 - t) ^ 4
    end,
    
    InOut = function(t)
        if t < 0.5 then
            return 8 * t * t * t * t
        else
            return 1 - (-2 * t + 2) ^ 4 / 2
        end
    end
}

-- Quint easing
EasingLibrary.Quint = {
    In = function(t)
        return t * t * t * t * t
    end,
    
    Out = function(t)
        return 1 - (1 - t) ^ 5
    end,
    
    InOut = function(t)
        if t < 0.5 then
            return 16 * t * t * t * t * t
        else
            return 1 - (-2 * t + 2) ^ 5 / 2
        end
    end
}

-- Sine easing
EasingLibrary.Sine = {
    In = function(t)
        return 1 - math.cos((t * math.pi) / 2)
    end,
    
    Out = function(t)
        return math.sin((t * math.pi) / 2)
    end,
    
    InOut = function(t)
        return -(math.cos(math.pi * t) - 1) / 2
    end
}

local function getEasingFunction(style, direction)
    if not VALID_EASING_STYLES[style] then
        warn(string.format("[TweenService] Invalid easing style '%s', using Linear", tostring(style)))
        return EasingLibrary.Linear
    end
    
    if style == "Linear" then
        return EasingLibrary.Linear
    end
    
    if not VALID_EASING_DIRECTIONS[direction] then
        warn(string.format("[TweenService] Invalid easing direction '%s', using Out", tostring(direction)))
        direction = "Out"
    end
    
    local easingGroup = EasingLibrary[style]
    if easingGroup and easingGroup[direction] then
        return easingGroup[direction]
    end
    
    warn(string.format("[TweenService] Easing function not found for %s.%s", style, direction))
    return EasingLibrary.Linear
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 6: TWEENINFO CLASS (USES SEVERE'S ENUM)
-- ═══════════════════════════════════════════════════════════

local function getEnumName(enumValue)
    if type(enumValue) == "string" then
        return enumValue
    end
    
    -- Convert enum to string and extract the name part
    local enumString = tostring(enumValue)
    
    -- Extract just the last part after the final dot
    -- "Enum.EasingStyle.Quad" -> "Quad"
    local name = enumString:match("%.([^%.]+)$")
    if name then
        return name
    end
    
    -- Fallback: return the whole string
    return enumString
end

local TweenInfo = {}
TweenInfo.__index = TweenInfo

function TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)
    local self = setmetatable({}, TweenInfo)
    
    -- Handle Enum.EasingStyle values (from Severe's Enum table)
    local style = easingStyle or Enum.EasingStyle.Quad
    local direction = easingDirection or Enum.EasingDirection.Out
    
    -- Extract just the enum name (e.g., "Quad" from "Enum.EasingStyle.Quad")
    self.EasingStyle = getEnumName(style)
    self.EasingDirection = getEnumName(direction)
    
    self.Time = time or 1
    self.RepeatCount = repeatCount or 0
    self.Reverses = reverses or false
    self.DelayTime = delayTime or 0
    
    assert(type(self.Time) == "number" and self.Time >= 0, "[TweenService] TweenInfo.Time must be a positive number")
    assert(type(self.RepeatCount) == "number" and self.RepeatCount >= -1, "[TweenService] TweenInfo.RepeatCount must be >= -1")
    assert(type(self.DelayTime) == "number" and self.DelayTime >= 0, "[TweenService] TweenInfo.DelayTime must be >= 0")
    
    return self
end

_G.TweenInfo = TweenInfo

-- ═══════════════════════════════════════════════════════════
-- SECTION 7: TWEEN CLASS
-- ═══════════════════════════════════════════════════════════

local Tween = {}
Tween.__index = Tween

function Tween.new(instance, tweenInfo, properties)
    assert(instance, "[TweenService] Instance cannot be nil")
    assert(tweenInfo, "[TweenService] TweenInfo cannot be nil")
    assert(properties, "[TweenService] Properties table cannot be nil")
    assert(type(properties) == "table", "[TweenService] Properties must be a table")
    
    local self = setmetatable({}, Tween)
    
    self.Instance = instance
    
    if type(tweenInfo) == "table" and getmetatable(tweenInfo) ~= TweenInfo then
        self.TweenInfo = TweenInfo.new(
            tweenInfo.Time or 1,
            tweenInfo.EasingStyle or Enum.EasingStyle.Quad,
            tweenInfo.EasingDirection or Enum.EasingDirection.Out,
            tweenInfo.RepeatCount or 0,
            tweenInfo.Reverses or false,
            tweenInfo.DelayTime or 0
        )
    else
        self.TweenInfo = tweenInfo
    end
    
    self.Properties = properties
    self._originalValues = {}
    self._isActive = false
    self._beginTime = 0
    self._elapsedTime = 0
    self._iterationCount = 0
    self._playbackDirection = 1
    self._onFinishCallback = nil
    self._valuesStored = false
    
    -- Store initial property values
    for propName, targetValue in pairs(properties) do
        if validateInstanceProperty(instance, propName) then
            local success, currentValue = pcall(function()
                return instance[propName]
            end)
            
            if success then
                if isVectorType(currentValue) then
                    local vec = toUnifiedVector(currentValue)
                    self._originalValues[propName] = {type = "Vector", X = vec.X, Y = vec.Y, Z = vec.Z}
                elseif isCFrameType(currentValue) then
                    self._originalValues[propName] = currentValue
                elseif type(currentValue) == "table" then
                    self._originalValues[propName] = {}
                    for k, v in pairs(currentValue) do
                        self._originalValues[propName][k] = v
                    end
                else
                    self._originalValues[propName] = currentValue
                end
            else
                warn(string.format("[TweenService] Failed to read initial value for property '%s'", propName))
            end
        end
    end
    
    -- Normalize target values
    for propName, targetValue in pairs(properties) do
        if isCFrameType(targetValue) then
            self.Properties[propName] = {
                type = "CFrame",
                Position = targetValue.Position,
                RightVector = targetValue.RightVector,
                UpVector = targetValue.UpVector,
                LookVector = targetValue.LookVector
            }
        elseif isVectorType(targetValue) then
            local vec = toUnifiedVector(targetValue)
            self.Properties[propName] = {type = "Vector", X = vec.X, Y = vec.Y, Z = vec.Z}
        end
    end
    
    -- Event system (using RobloxSignal wrapper)
    self.Completed = RobloxSignal.new()
    
    return self
end

function Tween:Play()
    if self._isActive then
        return
    end
    
    if not self._valuesStored then
        for propName, targetValue in pairs(self.Properties) do
            if validateInstanceProperty(self.Instance, propName) then
                local success, currentValue = pcall(function()
                    return self.Instance[propName]
                end)
                
                if success then
                    if isVectorType(currentValue) then
                        local vec = toUnifiedVector(currentValue)
                        self._originalValues[propName] = {type = "Vector", X = vec.X, Y = vec.Y, Z = vec.Z}
                    elseif isCFrameType(currentValue) then
                        self._originalValues[propName] = currentValue
                    elseif type(currentValue) == "table" then
                        self._originalValues[propName] = {}
                        for k, v in pairs(currentValue) do
                            self._originalValues[propName][k] = v
                        end
                    else
                        self._originalValues[propName] = currentValue
                    end
                end
            end
        end
        self._valuesStored = true
    end
    
    self._isActive = true
    self._beginTime = getCurrentTime()
    self._elapsedTime = 0
    self._iterationCount = 0
    self._playbackDirection = 1
    
    TweenService._registerAnimation(self)
    
    pcall(function()
        self:_step(0.001)
    end)
end

function Tween:Pause()
    if not self._isActive then
        return
    end
    
    self._isActive = false
    self.PlaybackState = "Paused"
end

function Tween:Resume()
    if self._isActive then
        return
    end
    
    self._isActive = true
    self.PlaybackState = "Playing"
    
    local pausedDuration = getCurrentTime() - (self._beginTime + self._elapsedTime)
    self._beginTime = self._beginTime + pausedDuration
end

function Tween:Stop()
    if not self._isActive then
        return
    end
    
    self._isActive = false
    TweenService._unregisterAnimation(self)
end

function Tween:Cancel()
    if not self._isActive then
        return
    end
    
    self:Stop()
    
    for propName, originalValue in pairs(self._originalValues) do
        local success = pcall(function()
            if type(originalValue) == "table" and originalValue.type == "Vector" then
                self.Instance[propName] = vector.create(originalValue.X, originalValue.Y, originalValue.Z)
            else
                self.Instance[propName] = originalValue
            end
        end)
        
        if not success then
            warn(string.format("[TweenService] Failed to restore property '%s'", propName))
        end
    end
end

function Tween:_step(deltaTime)
    if not self._isActive then
        return false
    end
    
    self._elapsedTime = self._elapsedTime + deltaTime
    local tweenInfo = self.TweenInfo
    
    if not tweenInfo then
        warn("[TweenService] TweenInfo is missing")
        return false
    end
    
    if self._elapsedTime < tweenInfo.DelayTime then
        return true
    end
    
    local adjustedTime = self._elapsedTime - tweenInfo.DelayTime
    local duration = tweenInfo.Time
    local totalIterations = tweenInfo.RepeatCount == 0 and 1 or tweenInfo.RepeatCount
    local totalDuration = duration * totalIterations
    
    if adjustedTime >= totalDuration then
        local success = pcall(function()
            for propName, targetValue in pairs(self.Properties) do
                if type(targetValue) == "table" and targetValue.type == "Vector" then
                    self.Instance[propName] = vector.create(targetValue.X, targetValue.Y, targetValue.Z)
                elseif type(targetValue) == "table" and targetValue.Position and targetValue.LookVector then
                    local pos = targetValue.Position
                    local look = targetValue.LookVector
                    local up = targetValue.UpVector
                    
                    local fixedLook = vector.create(-look.X, -look.Y, -look.Z)
                    local lookAtPoint = vector.create(
                        pos.X + fixedLook.X,
                        pos.Y + fixedLook.Y,
                        pos.Z + fixedLook.Z
                    )
                    
                    self.Instance[propName] = CFrame.lookAt(pos, lookAtPoint, up)
                else
                    self.Instance[propName] = targetValue
                end
            end
        end)
        
        if not success then
            warn("[TweenService] Failed to set final property values")
        end
        
        self:Stop()
        
        if self.Completed then
            self.Completed:Fire()
        end
        
        return false
    end
    
    local iterationProgress = (adjustedTime % duration) / duration
    if self._playbackDirection == -1 then
        iterationProgress = 1 - iterationProgress
    end
    
    local easingFunc = getEasingFunction(tweenInfo.EasingStyle, tweenInfo.EasingDirection)
    local alpha = easingFunc(iterationProgress)
    
    for propName, targetValue in pairs(self.Properties) do
        if self._originalValues[propName] ~= nil then
            local originalValue = self._originalValues[propName]
            local success = pcall(function()
                if type(originalValue) == "table" and originalValue.type == "Vector" then
                    local startVec = vector.create(originalValue.X, originalValue.Y, originalValue.Z)
                    local endVec
                    if type(targetValue) == "table" and targetValue.type == "Vector" then
                        endVec = vector.create(targetValue.X, targetValue.Y, targetValue.Z)
                    else
                        endVec = toUnifiedVector(targetValue)
                    end
                    local resultVec = interpolateVector(startVec, endVec, alpha)
                    self.Instance[propName] = resultVec
                    
                elseif isCFrameType(originalValue) then
                    local success2, resultCF = pcall(function()
                        return interpolateCFrame(originalValue, targetValue, alpha)
                    end)
                    
                    if not success2 then
                        warn("[TweenService] interpolateCFrame failed:", resultCF)
                    elseif resultCF and resultCF.Position then
                        local success3, err = pcall(function()
                            self.Instance[propName] = resultCF
                        end)
                        
                        if not success3 then
                            warn("[TweenService] Failed to SET CFrame:", err)
                        end
                    else
                        warn("[TweenService] Invalid CFrame result, skipping frame")
                    end
                    
                elseif type(originalValue) == "table" and type(targetValue) == "table" then
                    local result = interpolateTable(originalValue, targetValue, alpha)
                    self.Instance[propName] = result
                    
                elseif type(originalValue) == "number" and type(targetValue) == "number" then
                    self.Instance[propName] = interpolateNumber(originalValue, targetValue, alpha)
                    
                else
                    self.Instance[propName] = targetValue
                end
            end)
            
            if not success then
                warn(string.format("[TweenService] Failed to update property '%s'", propName))
            end
        end
    end
    
    if adjustedTime >= (self._iterationCount + 1) * duration then
        self._iterationCount = self._iterationCount + 1
        
        if tweenInfo.Reverses then
            self._playbackDirection = self._playbackDirection * -1
        end
        
        local shouldComplete
        if tweenInfo.RepeatCount == 0 then
            shouldComplete = self._iterationCount >= 1
        else
            shouldComplete = self._iterationCount >= tweenInfo.RepeatCount
        end
        
        if shouldComplete then
            self:Stop()
            
            if self.Completed then
                self.Completed:Fire()
            end
            
            return false
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 8: ANIMATION REGISTRY & UPDATE LOOP
-- ═══════════════════════════════════════════════════════════

function TweenService._registerAnimation(tween)
    table.insert(_activeAnimations, tween)
    TweenService._startUpdateLoop()
end

function TweenService._unregisterAnimation(tween)
    for i = #_activeAnimations, 1, -1 do
        if _activeAnimations[i] == tween then
            table.remove(_activeAnimations, i)
            break
        end
    end
end

function TweenService._processAllAnimations(deltaTime)
    deltaTime = math.clamp(deltaTime, MIN_FRAME_TIME, MAX_FRAME_TIME)
    
    local i = 1
    while i <= #_activeAnimations do
        local tween = _activeAnimations[i]
        
        local success, shouldContinue = pcall(function()
            return tween:_step(deltaTime)
        end)
        
        if success and shouldContinue then
            i = i + 1
        else
            if not success then
                warn("[TweenService] Animation update failed, removing from queue")
            end
            table.remove(_activeAnimations, i)
        end
    end
end

function TweenService._startUpdateLoop()
    if _isProcessing and _updateThread then
        return
    end
    
    _isProcessing = true
    _previousTickTime = getCurrentTime()
    
    _updateThread = task.spawn(function()
        while true do
            if #_activeAnimations == 0 then
                task.wait(0.1)
                if #_activeAnimations == 0 then
                    _isProcessing = false
                    _updateThread = nil
                    break
                end
            end
            
            local currentTime = getCurrentTime()
            local deltaTime = currentTime - _previousTickTime
            _previousTickTime = currentTime
            
            TweenService._processAllAnimations(deltaTime)
            
            task.wait(UPDATE_INTERVAL)
        end
    end)
end

function TweenService._stopUpdateLoop()
    _isProcessing = false
    
    if _updateThread then
        task.cancel(_updateThread)
        _updateThread = nil
    end
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 9: TWEENSERVICE API
-- ═══════════════════════════════════════════════════════════

function TweenService:Create(instance, tweenInfo, properties)
    assert(instance, "[TweenService] Create: instance cannot be nil")
    assert(tweenInfo, "[TweenService] Create: tweenInfo cannot be nil")
    assert(properties, "[TweenService] Create: properties cannot be nil")
    
    return Tween.new(instance, tweenInfo, properties)
end

function TweenService:GetActiveTweens()
    local activeCopy = {}
    for i, tween in ipairs(_activeAnimations) do
        activeCopy[i] = tween
    end
    return activeCopy
end

TweenService.TweenInfo = TweenInfo

Instance.declare({
    class = "TweenService",
    name = "Create",
    callback = {
        method = function(self, instance, tweenInfo, properties)
            assert(instance, "[TweenService] Create: instance cannot be nil")
            assert(tweenInfo, "[TweenService] Create: tweenInfo cannot be nil")
            assert(properties, "[TweenService] Create: properties cannot be nil")
            
            return Tween.new(instance, tweenInfo, properties)
        end
    }
})

Instance.declare({
    class = "TweenService",
    name = "GetActiveTweens",
    callback = {
        method = function(self)
            local activeCopy = {}
            for i, tween in ipairs(_activeAnimations) do
                activeCopy[i] = tween
            end
            return activeCopy
        end
    }
})
print("done")
print"1"
return TweenService
