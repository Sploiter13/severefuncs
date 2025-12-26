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
        Material = 0x226,
        Anchored = 0xD20,
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
        Active = 0x5B4,
        ClipsDescendants = 0x5B5,
        Draggable = 0x5B6,
        Selectable = 0x5B8,
        Visible = 0x5B9,
        BackgroundTransparency = 0x574,
        BackgroundColor3 = 0x550,
        BorderColor3 = 0x55C,
        Rotation = 0x188,
        LayoutOrder = 0x58C,
        ZIndex = 0x5B0,
        BorderSizePixel = 0x57C,
        Position = 0x520,
        Size = 0x540,
        AnchorPoint = 0x568
    },
    
    TextLabel = {
        Text = 0xE40,
        TextColor3 = 0xEF0,
        TextSize = 0xD1C,
        TextTransparency = 0xF24,
        TextStrokeColor3 = 0xEFC,
        TextStrokeTransparency = 0xF20,
        LineHeight = 0xB54
    },

    TextButton = {
        Text = 0x1120
    },

    TextBox = {
        Text = 0xAD8
    },
    
    Lighting = {
        Ambient = 0xD8,
        Brightness = 0x120,
        ClockTime = 0x1B8,
        ColorShift_Bottom = 0xF0,
        ColorShift_Top = 0xE4,
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
        CanBeDropped = 0x490,
        Enabled = 0x491,
        ManualActivationOnly = 0x492,
        RequiresHandle = 0x493,
        ToolTip = 0x440,
        GripPos = 0x484
    },

    Camera = {
        FieldOfView = 0x160
    },

    AnimationTrack = {
        Animation = 0xD0,
        Animator = 0x118,
        IsPlaying = 0x2BD,
        Looped = 0xF5,
        Speed = 0xE4,
        AnimationId = 0xD0
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
    if typeof(value) == "Color3" then
        return vector.create(value.R, value.G, value.B)
    elseif typeof(value) == "Vector3" then
        return vector.create(value.X, value.Y, value.Z)
    elseif type(value) == "vector" then
        return value
    end
    error("Value must be Color3, Vector3, or vector")
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

local GUI_INSET_Y = 58  

local GetCalculatedAbsoluteSize
local GetCalculatedAbsolutePosition

GetCalculatedAbsoluteSize = function(instance)
    if not instance or instance.ClassName == "ScreenGui" or instance == game then
        local vp = Camera.ViewportSize
        return vp.X, vp.Y - GUI_INSET_Y
    end
    
    local pW, pH = GetCalculatedAbsoluteSize(instance.Parent)
    
    if not instance.Data or instance.Data == 0 then 
        return 0, 0 
    end
    
    local sx, ox, sy, oy = readUDim2(instance.Data, Offsets.GuiObject.Size)
    return (pW * sx) + ox, (pH * sy) + oy
end

GetCalculatedAbsolutePosition = function(instance)
    if not instance or instance.ClassName == "ScreenGui" or instance == game then
        return 0, 0
    end
    
    local pX, pY = GetCalculatedAbsolutePosition(instance.Parent)
    local pW, pH = GetCalculatedAbsoluteSize(instance.Parent)
    
    if not instance.Data or instance.Data == 0 then 
        return 0, 0 
    end
    
    local px, pox, py, poy = readUDim2(instance.Data, Offsets.GuiObject.Position)
    local anchorPosX = pX + (pW * px) + pox
    local anchorPosY = pY + (pH * py) + poy
    
    local myW, myH = GetCalculatedAbsoluteSize(instance)
    local anchorX, anchorY = readVector2(instance.Data, Offsets.GuiObject.AnchorPoint)
    
    local finalX = anchorPosX - (myW * anchorX)
    local finalY = anchorPosY - (myH * anchorY)
    
    return finalX, finalY
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

Instance.declare({
    class = BASEPART_CLASSES,
    name = "Anchored",
    callback = {
        get = function(self)
            local primitive = getPrimitive(self)
            return memory_readbool(primitive, Offsets.Primitive.Anchored)
        end,
        set = function(self, value)
            local primitive = getPrimitive(self)
            memory_writebool(primitive, Offsets.Primitive.Anchored, value)
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
    name = "WalkToPoint",
    callback = {
        get = function(self)
            return memory_readvector(self, Offsets.Humanoid.WalkToPoint)
        end,
        set = function(self, value)
            memory_writevector(self, Offsets.Humanoid.WalkToPoint, toVector(value))
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
            local x, y = GetCalculatedAbsolutePosition(self)
            return newVector2(x, y)
        end
    }
})


Instance.declare({
    class = GUI_CLASSES,
    name = "AbsoluteSize",
    callback = {
        get = function(self)
            local w, h = GetCalculatedAbsoluteSize(self)
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
            return memory_readu64(self, Offsets.AnimationTrack.Animation)
        end
    }
})

Instance.declare({
    class = "AnimationTrack",
    name = "Animator",
    callback = {
        get = function(self)
            return memory_readu64(self, Offsets.AnimationTrack.Animator)
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
    class = "AnimationTrack",
    name = "AnimationId",
    callback = {
        get = function(self)
            return memory_readstring(self, Offsets.AnimationTrack.AnimationId)
        end,
        set = function(self, value)
            memory_writestring(self, Offsets.AnimationTrack.AnimationId, value)
        end
    }
})
