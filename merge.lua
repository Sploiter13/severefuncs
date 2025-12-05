--!optimize 2

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function hex(str)
    return tonumber(str, 16)
end

local function round(num, decimals)
    local mult = 10 ^ (decimals or 3)
    return math.floor(num * mult + 0.5) / mult
end

-- Type checking helpers
local function isVector(value)
    local t = type(value)
    if t == "vector" then return true end
    if typeof(value) == "Vector3" then return true end
    return false
end

local function toVector(value)
    if type(value) == "vector" then
        return value
    elseif typeof(value) == "Vector3" then
        return vector.create(value.X, value.Y, value.Z)
    end
    error("Value must be a vector or Vector3")
end

local function toVector3(value)
    if typeof(value) == "Vector3" then
        return value
    elseif type(value) == "vector" then
        return Vector3.new(value.X, value.Y, value.Z)
    end
    error("Value must be a vector or Vector3")
end

local function isColor(value)
    if typeof(value) == "Color3" then return true end
    if typeof(value) == "Vector3" then return true end
    if type(value) == "vector" then return true end
    return false
end

local function toColorVector(value)
    if typeof(value) == "Color3" then
        return vector.create(value.R, value.G, value.B)
    elseif typeof(value) == "Vector3" then
        return vector.create(value.X, value.Y, value.Z)
    elseif type(value) == "vector" then
        return value
    end
    error("Value must be a Color3, Vector3, or vector")
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 2: OFFSET FETCHING & CONFIGURATION
-- ═════════════════════════════════════════════════════════════

local TheoOffsets
local Camera = workspace.CurrentCamera

local response = game:HttpGet("https://imtheo.lol/Offsets/Offsets.json")
assert(response, "Failed to fetch offsets")
TheoOffsets = crypt.json.decode(response)

assert(TheoOffsets and TheoOffsets.Offsets, "Invalid offset structure")

local O = TheoOffsets.Offsets

-- Local offsets (not in TheoOffsets yet)
local LocalOffsets = {
    Humanoid = {
        BreakJointsOnDeath = 0x1DB,
        WalkToPoint = 0x17C
    },
    BasePart = {
        CastShadow = 0xF5,
        Massless = 0xF7
    },
    Camera = {
        HeadScale = 0x168,
        FieldOfView = 0x160
    },
    Gui = {
        Position = 0x520,
        Size = 0x540,
        AnchorPoint = 0x568
    }
}

-- ═══════════════════════════════════════════════════════════
-- SECTION 3: CLASS DEFINITIONS
-- ═══════════════════════════════════════════════════════════

local ClassGroups = {
    BaseParts = {"Part", "MeshPart", "UnionOperation", "TrussPart"},
    GuiElements = {"Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton", "ScrollingFrame", "ViewportFrame"},
    TextElements = {"TextLabel", "TextButton", "TextBox"},
    ImageElements = {"ImageLabel", "ImageButton"}
}

-- ═══════════════════════════════════════════════════════════
-- SECTION 4: MEMORY HELPERS
-- ═══════════════════════════════════════════════════════════

local function getPrimitive(part)
    assert(part and part.Data and part.Data ~= 0, "Invalid part data")
    return memory.readu64(part.Data, O.BasePart.Primitive)
end

local function readUDim2(ptr, offset)
    local xScale = memory.readf32(ptr, offset)
    local xOffset = memory.readi32(ptr, offset + 0x4)
    local yScale = memory.readf32(ptr, offset + 0x8)
    local yOffset = memory.readi32(ptr, offset + 0xC)
    return xScale, xOffset, yScale, yOffset
end

local function readVector2(ptr, offset)
    local x = memory.readf32(ptr, offset)
    local y = memory.readf32(ptr, offset + 4)
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

-- ═══════════════════════════════════════════════════════════
-- SECTION 5: GUI CALCULATION HELPERS
-- ═══════════════════════════════════════════════════════════

local GetCalculatedAbsoluteSize
local GetCalculatedAbsolutePosition

GetCalculatedAbsoluteSize = function(instance)
    if not instance or instance.ClassName == "ScreenGui" or instance == game then
        local vp = Camera.ViewportSize
        return vp.X, vp.Y
    end
    
    local pW, pH = GetCalculatedAbsoluteSize(instance.Parent)
    
    if not instance.Data or instance.Data == 0 then 
        return 0, 0 
    end
    
    local sx, ox, sy, oy = readUDim2(instance.Data, LocalOffsets.Gui.Size)
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
    
    local px, pox, py, poy = readUDim2(instance.Data, LocalOffsets.Gui.Position)
    local anchorPosX = pX + (pW * px) + pox
    local anchorPosY = pY + (pH * py) + poy
    
    local myW, myH = GetCalculatedAbsoluteSize(instance)
    local anchorX, anchorY = readVector2(instance.Data, LocalOffsets.Gui.AnchorPoint)
    
    local finalX = anchorPosX - (myW * anchorX)
    local finalY = anchorPosY - (myH * anchorY)
    
    return finalX, finalY
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 6: HUMANOID PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- RigType (0 = R6, 1 = R15)
Instance.declare({
    class = "Humanoid",
    name = "RigType",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.Humanoid.RigType)
        end,
        set = function(self, value)
            assert(type(value) == "number", "Value must be a number (0=R6, 1=R15)")
            memory.writei32(self.Data, O.Humanoid.RigType, value)
        end
    }
})

Instance.declare({
    class = "Humanoid",
    name = "Jump",
    callback = {
        get = function(self)
            return memory.readbool(self.Data, O.Humanoid.Jump)
        end,
        set = function(self, value)
            memory.writebool(self.Data, O.Humanoid.Jump, value)
        end
    }
})

-- WalkSpeed
Instance.declare({class = "Humanoid", name = "WalkSpeed", callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Humanoid.Walkspeed)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Humanoid.WalkspeedCheck, value)
            memory.writef32(self.Data, O.Humanoid.Walkspeed, value)
            memory.writef32(self.Data, O.Humanoid.WalkspeedCheck, value)
        end
    }})

-- JumpPower
Instance.declare({
    class = "Humanoid",
    name = "JumpPower",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Humanoid.JumpPower)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Humanoid.JumpPower, value)
        end
    }
})

-- JumpHeight
Instance.declare({
    class = "Humanoid",
    name = "JumpHeight",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Humanoid.JumpHeight)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Humanoid.JumpHeight, value)
        end
    }
})

-- HipHeight
Instance.declare({
    class = "Humanoid",
    name = "HipHeight",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Humanoid.HipHeight)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Humanoid.HipHeight, value)
        end
    }
})

-- MaxSlopeAngle
Instance.declare({
    class = "Humanoid",
    name = "MaxSlopeAngle",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Humanoid.MaxSlopeAngle)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Humanoid.MaxSlopeAngle, value)
        end
    }
})

-- AutoRotate
Instance.declare({
    class = "Humanoid",
    name = "AutoRotate",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.Humanoid.AutoRotate) == 1
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.Humanoid.AutoRotate, value and 1 or 0)
        end
    }
})

-- BreakJointsOnDeath
Instance.declare({
    class = "Humanoid",
    name = "BreakJointsOnDeath",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, LocalOffsets.Humanoid.BreakJointsOnDeath) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, LocalOffsets.Humanoid.BreakJointsOnDeath, value and 1 or 0)
        end
    }
})

-- HumanoidStateType
local HumanoidStates = {
    [0] = "FallingDown", [1] = "Ragdoll", [2] = "GettingUp", [3] = "Jumping",
    [4] = "Swimming", [5] = "Freefall", [6] = "Flying", [7] = "Landed",
    [8] = "Running", [10] = "RunningNoPhysics", [11] = "StrafingNoPhysics",
    [12] = "Climbing", [13] = "Seated", [14] = "PlatformStanding",
    [15] = "Dead", [16] = "Physics", [18] = "None"
}

local HumanoidStateNames = {}
for id, name in pairs(HumanoidStates) do
    HumanoidStateNames[name] = id
end

Instance.declare({
    class = "Humanoid",
    name = "HumanoidStateType",
    callback = {
        get = function(self)
            local statePtr = memory.readu64(self.Data, O.Humanoid.HumanoidState)
            
            if statePtr and statePtr ~= 0 then
                local id = memory.readi32(statePtr, O.Humanoid.HumanoidStateID)
                return HumanoidStates[id] or id
            end
            return "None"
        end,
        set = function(self, value)
            
            local idToSet = value
            if type(value) == "string" then
                idToSet = HumanoidStateNames[value]
                assert(idToSet, "Invalid state name: " .. tostring(value))
            else
                assert(type(value) == "number", "Value must be a number or state string")
            end
            
            local statePtr = memory.readu64(self.Data, O.Humanoid.HumanoidState)
            if statePtr and statePtr ~= 0 then
                memory.writei32(statePtr, O.Humanoid.HumanoidStateID, idToSet)
            else
                warn("[HumanoidStateType] State pointer is nil")
            end
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 7: BASEPART PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- Anchored
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Anchored",
    callback = {
        get = function(self)
            local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
            return bit32.band(byte, 2) ~= 0
        end,
        set = function(self, value)
            local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
            byte = value and bit32.bor(byte, 2) or bit32.band(byte, bit32.bnot(2))
            memory.writeu8(self.Data, O.BasePart.PrimitiveFlags, byte)
        end
    }
})

-- CanTouch
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "CanTouch",
    callback = {
        get = function(self)
            local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
            return bit32.band(byte, 16) ~= 0
        end,
        set = function(self, value)
            local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
            byte = value and bit32.bor(byte, 16) or bit32.band(byte, bit32.bnot(16))
            memory.writeu8(self.Data, O.BasePart.PrimitiveFlags, byte)
        end
    }
})

-- CastShadow
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "CastShadow",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, LocalOffsets.BasePart.CastShadow) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, LocalOffsets.BasePart.CastShadow, value and 1 or 0)
        end
    }
})

-- Massless
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Massless",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, LocalOffsets.BasePart.Massless) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, LocalOffsets.BasePart.Massless, value and 1 or 0)
        end
    }
})

-- Shape
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Shape",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.BasePart.Shape)
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.BasePart.Shape, value)
        end
    }
})

-- Material
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Material",
    callback = {
        get = function(self)

            return memory.readi32(primitive, O.BasePart.Material)
        end,
        set = function(self, value)

            memory.writei32(primitive, O.BasePart.Material, value)
        end
    }
})

-- AssemblyLinearVelocity (FIXED: accepts both vector and Vector3)
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "AssemblyLinearVelocity",
    callback = {
        get = function(self)

            local raw = memory.readvector(primitive, O.BasePart.AssemblyLinearVelocity)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)

            local vecToWrite = toVector(value)
            memory.writevector(primitive, O.BasePart.AssemblyLinearVelocity, vecToWrite)
        end
    }
})

-- AssemblyAngularVelocity (FIXED: accepts both vector and Vector3)
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "AssemblyAngularVelocity",
    callback = {
        get = function(self)

            local raw = memory.readvector(primitive, O.BasePart.AssemblyAngularVelocity)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)

            local vecToWrite = toVector(value)
            memory.writevector(primitive, O.BasePart.AssemblyAngularVelocity, vecToWrite)
        end
    }
})

-- Color (FIXED: accepts Color3, Vector3, or vector)
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Color",
    callback = {
        get = function(self)
            local raw = memory.readvector(self.Data, O.BasePart.Color)
            return Color3.new(raw.X, raw.Y, raw.Z)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.BasePart.Color, vecToWrite)
        end
    }
})

-- Transparency
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Transparency",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.BasePart.Transparency)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.BasePart.Transparency, value)
        end
    }
})

-- Reflectance
Instance.declare({
    class = ClassGroups.BaseParts,
    name = "Reflectance",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.BasePart.Reflectance)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.BasePart.Reflectance, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 8: GUI PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- Position
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "Position",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newUDim2(0, 0, 0, 0) end
            local sx, ox, sy, oy = readUDim2(self.Data, LocalOffsets.Gui.Position)
            return newUDim2(sx, ox, sy, oy)
        end
    }
})

-- Size
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "Size",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newUDim2(0, 0, 0, 0) end
            local sx, ox, sy, oy = readUDim2(self.Data, LocalOffsets.Gui.Size)
            return newUDim2(sx, ox, sy, oy)
        end
    }
})

-- AnchorPoint
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "AnchorPoint",
    callback = {
        get = function(self)
            if not self.Data or self.Data == 0 then return newVector2(0, 0) end
            local x, y = readVector2(self.Data, LocalOffsets.Gui.AnchorPoint)
            return newVector2(x, y)
        end
    }
})

-- AbsolutePosition
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "AbsolutePosition",
    callback = {
        get = function(self)
            local x, y = GetCalculatedAbsolutePosition(self)
            return newVector2(x, y)
        end
    }
})

-- AbsoluteSize
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "AbsoluteSize",
    callback = {
        get = function(self)
            local w, h = GetCalculatedAbsoluteSize(self)
            return newVector2(w, h)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 9: CAMERA PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- HeadScale
Instance.declare({
    class = "Camera",
    name = "HeadScale",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, LocalOffsets.Camera.HeadScale)
        end,
        set = function(self, value)
            memory.writef32(self.Data, LocalOffsets.Camera.HeadScale, value)
        end
    }
})

-- CameraType
Instance.declare({
    class = "Camera",
    name = "CameraType",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.Camera.CameraType)
        end,
        set = function(self, value)
            memory.writei32(self.Data, O.Camera.CameraType, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 10: LIGHTING PROPERTIES (FIXED: Color support)
-- ═══════════════════════════════════════════════════════════

-- Brightness
Instance.declare({
    class = "Lighting",
    name = "Brightness",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Lighting.Brightness)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Lighting.Brightness, value)
        end
    }
})

-- FogColor (FIXED: accepts Color3, Vector3, or vector)
Instance.declare({
    class = "Lighting",
    name = "FogColor",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.Lighting.FogColor)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.Lighting.FogColor, vecToWrite)
        end
    }
})

-- Ambient (FIXED)
Instance.declare({
    class = "Lighting",
    name = "Ambient",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.Lighting.Ambient)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.Lighting.Ambient, vecToWrite)
        end
    }
})

-- OutdoorAmbient (FIXED)
Instance.declare({
    class = "Lighting",
    name = "OutdoorAmbient",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.Lighting.OutdoorAmbient)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.Lighting.OutdoorAmbient, vecToWrite)
        end
    }
})

-- ColorShift_Top (FIXED)
Instance.declare({
    class = "Lighting",
    name = "ColorShift_Top",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.Lighting.ColorShift_Top)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.Lighting.ColorShift_Top, vecToWrite)
        end
    }
})

-- ColorShift_Bottom (FIXED)
Instance.declare({
    class = "Lighting",
    name = "ColorShift_Bottom",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.Lighting.ColorShift_Bottom)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.Lighting.ColorShift_Bottom, vecToWrite)
        end
    }
})

-- FogStart
Instance.declare({
    class = "Lighting",
    name = "FogStart",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Lighting.FogStart)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Lighting.FogStart, value)
        end
    }
})

-- FogEnd
Instance.declare({
    class = "Lighting",
    name = "FogEnd",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Lighting.FogEnd)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Lighting.FogEnd, value)
        end
    }
})

-- ExposureCompensation
Instance.declare({
    class = "Lighting",
    name = "ExposureCompensation",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Lighting.ExposureCompensation)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Lighting.ExposureCompensation, value)
        end
    }
})

-- GeographicLatitude
Instance.declare({
    class = "Lighting",
    name = "GeographicLatitude",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Lighting.GeographicLatitude)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Lighting.GeographicLatitude, value)
        end
    }
})

-- ClockTime
Instance.declare({
    class = "Lighting",
    name = "ClockTime",
    callback = {
        get = function(self)
            return memory.readf64(self.Data, O.Lighting.TimeOfDay) / 3600
        end,
        set = function(self, value)
            memory.writef64(self.Data, O.Lighting.TimeOfDay, value * 3600)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 11: PLAYER PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- Country
Instance.declare({
    class = "Player",
    name = "Country",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.Player.Country)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.Player.Country, value)
        end
    }
})

-- CameraMaxZoomDistance
Instance.declare({
    class = "Player",
    name = "CameraMaxZoomDistance",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Player.MaxZoomDistance)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Player.MaxZoomDistance, value)
        end
    }
})

-- CameraMinZoomDistance
Instance.declare({
    class = "Player",
    name = "CameraMinZoomDistance",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Player.MinZoomDistance)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Player.MinZoomDistance, value)
        end
    }
})

-- CameraMode
Instance.declare({
    class = "Player",
    name = "CameraMode",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.Player.CameraMode)
        end,
        set = function(self, value)
            memory.writei32(self.Data, O.Player.CameraMode, value)
        end
    }
})

-- Gender
Instance.declare({
    class = "Player",
    name = "Gender",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.Player.Gender)
        end,
        set = function(self, value)
            memory.writei32(self.Data, O.Player.Gender, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 12: WORKSPACE PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- Gravity
Instance.declare({
    class = "Workspace",
    name = "Gravity",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Workspace.Gravity)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Workspace.Gravity, value)
        end
    }
})

-- DistributedGameTime
Instance.declare({
    class = "Workspace",
    name = "DistributedGameTime",
    callback = {
        get = function(self)
            return memory.readf64(self.Data, O.Workspace.DistributedGameTime)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 13: MODEL PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- Scale
Instance.declare({
    class = "Model",
    name = "Scale",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Model.Scale)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Model.Scale, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 14: MESHPART PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- MeshId
Instance.declare({
    class = "MeshPart",
    name = "MeshId",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.MeshPart.MeshID)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.MeshPart.MeshID, value)
        end
    }
})

-- TextureID
Instance.declare({
    class = "MeshPart",
    name = "TextureID",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.MeshPart.TextureID)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.MeshPart.TextureID, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 15: SKY PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- MoonAngularSize
Instance.declare({
    class = "Sky",
    name = "MoonAngularSize",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Sky.MoonAngularSize)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Sky.MoonAngularSize, value)
        end
    }
})

-- SunAngularSize
Instance.declare({
    class = "Sky",
    name = "SunAngularSize",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.Sky.SunAngularSize)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.Sky.SunAngularSize, value)
        end
    }
})

-- StarCount
Instance.declare({
    class = "Sky",
    name = "StarCount",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.Sky.StarCount)
        end,
        set = function(self, value)
            memory.writei32(self.Data, O.Sky.StarCount, value)
        end
    }
})

-- Skybox Textures (Bk, Dn, Ft, Lf, Rt, Up)
local skyboxFaces = {
    {"SkyboxBk", O.Sky.SkyboxBk},
    {"SkyboxDn", O.Sky.SkyboxDn},
    {"SkyboxFt", O.Sky.SkyboxFt},
    {"SkyboxLf", O.Sky.SkyboxLf},
    {"SkyboxRt", O.Sky.SkyboxRt},
    {"SkyboxUp", O.Sky.SkyboxUp}
}

for _, face in ipairs(skyboxFaces) do
    local name, offset = face[1], face[2]
    Instance.declare({
        class = "Sky",
        name = name,
        callback = {
            get = function(self)
                    return memory.readstring(self.Data, offset)
            end,
            set = function(self, value)
                        memory.writestring(self.Data, offset, value)
            end
        }
    })
end

-- SunTextureId
Instance.declare({
    class = "Sky",
    name = "SunTextureId",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.Sky.SunTextureId)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.Sky.SunTextureId, value)
        end
    }
})

-- MoonTextureId
Instance.declare({
    class = "Sky",
    name = "MoonTextureId",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.Sky.MoonTextureId)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.Sky.MoonTextureId, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 16: SPECIALMESH PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- MeshId (SpecialMesh)
Instance.declare({
    class = "SpecialMesh",
    name = "MeshId",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.SpecialMesh.MeshID)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.SpecialMesh.MeshID, value)
        end
    }
})

-- Scale (SpecialMesh) - FIXED: accepts vector or Vector3
Instance.declare({
    class = "SpecialMesh",
    name = "Scale",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.SpecialMesh.Scale)
        end,
        set = function(self, value)
            local vecToWrite = toVector(value)
            memory.writevector(self.Data, O.SpecialMesh.Scale, vecToWrite)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 17: PROXIMITYPROMT PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- KeyCode
Instance.declare({
    class = "ProximityPrompt",
    name = "KeyCode",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.ProximityPrompt.KeyCode)
        end,
        set = function(self, value)
            memory.writei32(self.Data, O.ProximityPrompt.KeyCode, value)
        end
    }
})

-- RequiresLineOfSight
Instance.declare({
    class = "ProximityPrompt",
    name = "RequiresLineOfSight",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.ProximityPrompt.RequiresLineOfSight) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.ProximityPrompt.RequiresLineOfSight, value and 1 or 0)
        end
    }
})

-- HoldDuration
Instance.declare({
    class = "ProximityPrompt",
    name = "HoldDuration",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.ProximityPrompt.HoldDuration)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.ProximityPrompt.HoldDuration, value)
        end
    }
})

-- MaxActivationDistance
Instance.declare({
    class = "ProximityPrompt",
    name = "MaxActivationDistance",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.ProximityPrompt.MaxActivationDistance)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.ProximityPrompt.MaxActivationDistance, value)
        end
    }
})

-- ActionText
Instance.declare({
    class = "ProximityPrompt",
    name = "ActionText",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.ProximityPrompt.ActionText)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.ProximityPrompt.ActionText, value)
        end
    }
})

-- ObjectText
Instance.declare({
    class = "ProximityPrompt",
    name = "ObjectText",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.ProximityPrompt.ObjectText)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.ProximityPrompt.ObjectText, value)
        end
    }
})

-- Enabled (ProximityPrompt)
Instance.declare({
    class = "ProximityPrompt",
    name = "Enabled",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.ProximityPrompt.Enabled) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.ProximityPrompt.Enabled, value and 1 or 0)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 18: CLICKDETECTOR PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- MouseIcon
Instance.declare({
    class = "ClickDetector",
    name = "MouseIcon",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.ClickDetector.MouseIcon)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.ClickDetector.MouseIcon, value)
        end
    }
})

-- MaxActivationDistance (ClickDetector)
Instance.declare({
    class = "ClickDetector",
    name = "MaxActivationDistance",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.ClickDetector.MaxActivationDistance)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.ClickDetector.MaxActivationDistance, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 19: GUIOBJECT ADDITIONAL PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- BackgroundColor3 (FIXED: accepts Color3, Vector3, or vector)
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "BackgroundColor3",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.GuiObject.BackgroundColor3)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.GuiObject.BackgroundColor3, vecToWrite)
        end
    }
})

-- BorderColor3 (FIXED)
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "BorderColor3",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.GuiObject.BorderColor3)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.GuiObject.BorderColor3, vecToWrite)
        end
    }
})

-- Visible
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "Visible",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.GuiObject.Visible) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.GuiObject.Visible, value and 1 or 0)
        end
    }
})

-- Rotation
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "Rotation",
    callback = {
        get = function(self)
            return memory.readf32(self.Data, O.GuiObject.Rotation)
        end,
        set = function(self, value)
            memory.writef32(self.Data, O.GuiObject.Rotation, value)
        end
    }
})

-- LayoutOrder
Instance.declare({
    class = ClassGroups.GuiElements,
    name = "LayoutOrder",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.GuiObject.LayoutOrder)
        end,
        set = function(self, value)
            memory.writei32(self.Data, O.GuiObject.LayoutOrder, value)
        end
    }
})

-- Text (for TextLabel, TextButton, TextBox)
Instance.declare({
    class = ClassGroups.TextElements,
    name = "Textt",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.TextLabel.Text)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.TextLabel.Text, value)
        end
    }
})

-- TextColor3 (FIXED)
Instance.declare({
    class = ClassGroups.TextElements,
    name = "TextColor3",
    callback = {
        get = function(self)
            return memory.readvector(self.Data, O.TextLabel.TextColor3)
        end,
        set = function(self, value)
            local vecToWrite = toColorVector(value)
            memory.writevector(self.Data, O.TextLabel.TextColor3, vecToWrite)
        end
    }
})

-- RichText
Instance.declare({
    class = ClassGroups.TextElements,
    name = "RichText",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.TextLabel.RichText) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.TextLabel.RichText, value and 1 or 0)
        end
    }
})

-- Image (for ImageLabel, ImageButton)
Instance.declare({
    class = ClassGroups.ImageElements,
    name = "Image",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.ImageLabel.Image)
        end,
        set = function(self, value)
            memory.writestring(self.Data, O.ImageLabel.Image, value)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 20: SCREENGUI PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- Enabled (ScreenGui)
Instance.declare({
    class = "ScreenGui",
    name = "Enabled",
    callback = {
        get = function(self)
            return memory.readu8(self.Data, O.ScreenGui.Enabled) ~= 0
        end,
        set = function(self, value)
            memory.writeu8(self.Data, O.ScreenGui.Enabled, value and 1 or 0)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 21: DATAMODEL PROPERTIES
-- ═══════════════════════════════════════════════════════════

-- CreatorId
Instance.declare({
    class = "DataModel",
    name = "CreatorId",
    callback = {
        get = function(self)
            return memory.readi64(self.Data, O.DataModel.CreatorId)
        end
    }
})

-- PlaceVersion
Instance.declare({
    class = "DataModel",
    name = "PlaceVersion",
    callback = {
        get = function(self)
            return memory.readi32(self.Data, O.DataModel.PlaceVersion)
        end
    }
})

-- ServerIP
Instance.declare({
    class = "DataModel",
    name = "ServerIP",
    callback = {
        get = function(self)
            return memory.readstring(self.Data, O.DataModel.ServerIP)
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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
    class = "CFrame",
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


print("loaded")


--!optimization 2

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

-- Validation tables
local VALID_EASING_STYLES = {
    Back = true, Bounce = true, Circ = true, Cubic = true,
    Elastic = true, Expo = true, Linear = true, Quad = true,
    Quart = true, Quint = true, Sine = true
}

local VALID_EASING_DIRECTIONS = {
    In = true, Out = true, InOut = true
}

-- ═══════════════════════════════════════════════════════════
-- SECTION 2: UTILITY FUNCTIONS
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
-- SECTION 3: INTERPOLATION SYSTEM
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

--!optimization 2

-- ═══════════════════════════════════════════════════════════
-- FIXED CFRAME INTERPOLATION WITH QUATERNION SLERP
-- ═══════════════════════════════════════════════════════════

-- Add this to your utility functions section
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
    
    -- Calculate rotation matrix components
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
    
    -- Build rotation vectors
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
    -- Compute dot product
    local dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w
    
    -- If dot is negative, negate one quaternion to take shorter path
    local q2_adjusted = q2
    if dot < 0 then
        q2_adjusted = {x = -q2.x, y = -q2.y, z = -q2.z, w = -q2.w}
        dot = -dot
    end
    
    -- Clamp dot to avoid numerical errors
    dot = math.clamp(dot, -1, 1)
    
    -- If quaternions are very close, use linear interpolation
    if dot > 0.9995 then
        local result = {
            x = q1.x + alpha * (q2_adjusted.x - q1.x),
            y = q1.y + alpha * (q2_adjusted.y - q1.y),
            z = q1.z + alpha * (q2_adjusted.z - q1.z),
            w = q1.w + alpha * (q2_adjusted.w - q1.w)
        }
        
        -- Normalize
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
    
    -- Calculate angle and perform slerp
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
    -- Validate inputs
    if not cf1 or not cf2 then
        warn("[TweenService] interpolateCFrame: nil CFrame detected")
        return cf1 or cf2
    end
    
    if not cf1.Position or not cf2.Position then
        warn("[TweenService] interpolateCFrame: CFrame missing Position")
        return cf2
    end
    
    -- Interpolate position (simple linear)
    local p1 = cf1.Position
    local p2 = cf2.Position
    local newPos = vector.create(
        p1.X + (p2.X - p1.X) * alpha,
        p1.Y + (p2.Y - p1.Y) * alpha,
        p1.Z + (p2.Z - p1.Z) * alpha
    )
    
    -- Convert CFrames to quaternions (keep this for smooth rotation)
    local q1 = quaternionFromCFrame(cf1)
    local q2 = quaternionFromCFrame(cf2)
    
    -- Slerp between quaternions
    local qResult = quaternionSlerp(q1, q2, alpha)
    
    -- Convert quaternion back to rotation matrix
    local right, up, look = quaternionToRotationMatrix(qResult)
    
    -- ✅ FIX: Use CFrame.lookAt instead of CFrame.fromMatrix!
    -- Calculate the forward direction point
   local fixedLook = vector.create(-look.X, -look.Y, -look.Z)

-- Use the negated look to build the lookAt point
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
-- SECTION 4: EASING FUNCTIONS
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
-- SECTION 5: TWEENINFO CLASS
-- ═══════════════════════════════════════════════════════════

local Enum = {
    EasingStyle = {
        Linear = "Linear",
        Sine = "Sine",
        Back = "Back",
        Quad = "Quad",
        Quart = "Quart",
        Quint = "Quint",
        Bounce = "Bounce",
        Elastic = "Elastic",
        Exponential = "Expo",
        Expo = "Expo",
        Cubic = "Cubic",
        Circ = "Circ"
    },
    EasingDirection = {
        In = "In",
        Out = "Out",
        InOut = "InOut"
    }
}


local TweenInfo = {}
TweenInfo.__index = TweenInfo

function TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)
    local self = setmetatable({}, TweenInfo)
    
    -- Handle different input types for easingStyle and easingDirection
    local style = easingStyle or "Quad"
    local direction = easingDirection or "Out"
    
    -- If it's already a string, use it directly
    if type(style) == "string" then
        self.EasingStyle = style
    else
        -- It's an Enum value, convert to string
        self.EasingStyle = tostring(style)
    end
    
    if type(direction) == "string" then
        self.EasingDirection = direction
    else
        -- It's an Enum value, convert to string
        self.EasingDirection = tostring(direction)
    end
    
    self.Time = time or 1
    self.RepeatCount = repeatCount or 0
    self.Reverses = reverses or false
    self.DelayTime = delayTime or 0
    
    -- Validate settings
    assert(type(self.Time) == "number" and self.Time >= 0, "[TweenService] TweenInfo.Time must be a positive number")
    assert(type(self.RepeatCount) == "number" and self.RepeatCount >= -1, "[TweenService] TweenInfo.RepeatCount must be >= -1")
    assert(type(self.DelayTime) == "number" and self.DelayTime >= 0, "[TweenService] TweenInfo.DelayTime must be >= 0")
    
    return self
end

_G.TweenInfo = TweenInfo
_G.Enum = Enum

-- ═══════════════════════════════════════════════════════════
-- SECTION 6: TWEEN CLASS
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
    
    -- Handle TweenInfo creation if table is passed
    if type(tweenInfo) == "table" and getmetatable(tweenInfo) ~= TweenInfo then
        self.TweenInfo = TweenInfo.new(
            tweenInfo.Time or 1,
            tweenInfo.EasingStyle or "Quad",
            tweenInfo.EasingDirection or "Out",
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
                -- Store original value based on type
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
    
    -- Event system
    self.Completed = Signal.new()
    
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
        self._valuesStored = true  -- Mark as stored
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
    
    -- Restore original values
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

--!optimization 2

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
    
    -- Handle delay
    if self._elapsedTime < tweenInfo.DelayTime then
        return true
    end
    
    local adjustedTime = self._elapsedTime - tweenInfo.DelayTime
    local duration = tweenInfo.Time
    local totalIterations = tweenInfo.RepeatCount == 0 and 1 or tweenInfo.RepeatCount
    local totalDuration = duration * totalIterations
    
    -- ✅ Check if animation is complete FIRST
    if adjustedTime >= totalDuration then
        -- Set final values with exact target (alpha = 1.0)
        local success = pcall(function()
            for propName, targetValue in pairs(self.Properties) do
                if type(targetValue) == "table" and targetValue.type == "Vector" then
                    -- Vector: final value
                    self.Instance[propName] = vector.create(targetValue.X, targetValue.Y, targetValue.Z)
                    
                elseif type(targetValue) == "table" and targetValue.Position and targetValue.LookVector then
                    -- CFrame: Use CFrame.lookAt for final value
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
                    -- Other types: direct assignment
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
    
    -- Calculate progress within current iteration
    local iterationProgress = (adjustedTime % duration) / duration
    if self._playbackDirection == -1 then
        iterationProgress = 1 - iterationProgress
    end
    
    -- Apply easing
    local easingFunc = getEasingFunction(tweenInfo.EasingStyle, tweenInfo.EasingDirection)
    local alpha = easingFunc(iterationProgress)
    
    -- Update properties during animation
    for propName, targetValue in pairs(self.Properties) do
        if self._originalValues[propName] ~= nil then
            local originalValue = self._originalValues[propName]
            local success = pcall(function()
                if type(originalValue) == "table" and originalValue.type == "Vector" then
                    -- Vector interpolation
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
                    -- CFrame interpolation
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
                    -- Table interpolation
                    local result = interpolateTable(originalValue, targetValue, alpha)
                    self.Instance[propName] = result
                    
                elseif type(originalValue) == "number" and type(targetValue) == "number" then
                    -- Number interpolation
                    self.Instance[propName] = interpolateNumber(originalValue, targetValue, alpha)
                    
                else
                    -- Direct assignment
                    self.Instance[propName] = targetValue
                end
            end)
            
            if not success then
                warn(string.format("[TweenService] Failed to update property '%s'", propName))
            end
        end
    end
    
    -- Check for iteration completion
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
-- SECTION 7: ANIMATION REGISTRY & UPDATE LOOP
-- ═══════════════════════════════════════════════════════════

function TweenService._registerAnimation(tween)
    table.insert(_activeAnimations, tween)
    
    -- Always try to start the loop (fix will handle if already running)
    TweenService._startUpdateLoop()
end

function TweenService._unregisterAnimation(tween)
    for i = #_activeAnimations, 1, -1 do
        if _activeAnimations[i] == tween then
            table.remove(_activeAnimations, i)
            break
        end
    end
    
    -- Don't stop loop here, let it exit naturally
end

function TweenService._processAllAnimations(deltaTime)
    -- Clamp delta time to prevent spikes
    deltaTime = math.clamp(deltaTime, MIN_FRAME_TIME, MAX_FRAME_TIME)
    
    -- Process all animations
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
    -- FIX: Check if loop is actually running, not just the flag
    if _isProcessing and _updateThread then
        return
    end
    
    _isProcessing = true
    _previousTickTime = getCurrentTime()
    
    _updateThread = task.spawn(function()
        while true do
            -- Check if we have animations to process
            if #_activeAnimations == 0 then
                -- Wait a bit before exiting in case new tweens are added
                task.wait(0.1)
                if #_activeAnimations == 0 then
                    -- Still empty, exit
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
-- SECTION 8: TWEENSERVICE API
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

--Instance.declare({
  --  class = "TweenService",
  --  name = "TweenInfo",
   -- callback = {
   --     get = function(self)
       --     return TweenInfo
      --  end
  --  }
--})

--!optimize 2

-- ═══════════════════════════════════════════════════════════
-- OFFSET SETUP
-- ═══════════════════════════════════════════════════════════

local TheoOffsets
local O
-- Local offsets for things not providing in the JSON or custom overrides
local LocalOffsets = {
    Humanoid = {
        BreakJointsOnDeath = 0x1DB,
        WalkToPoint = 0x17C
    },
    BasePart = {
        CastShadow = 0xF5,
        Massless = 0xF7
    },
    Camera = {
        HeadScale = 0x168,
        FieldOfView = 0x160
    },
    Gui = {
        Position = 0x520,
        Size = 0x540,
        AnchorPoint = 0x568
    }
}

pcall(function()
    local response = game:HttpGet("https://imtheo.lol/Offsets/Offsets.json")
    if response then
        TheoOffsets = crypt.json.decode(response)
        if TheoOffsets then
            O = TheoOffsets.Offsets
        end
    end
end)

-- Fallback to global if fetch failed
if not O and _G.O then
    O = _G.O
end

local function getPrimitive(part)
    if not O or not O.BasePart or not O.BasePart.Primitive then return 0 end
    return memory.readu64(part.Data, O.BasePart.Primitive)
end

-- ═══════════════════════════════════════════════════════════
-- Signal Implementation (GLOBAL)
-- ═══════════════════════════════════════════════════════════

Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback)
    local self = setmetatable({}, Connection)
    self._signal = signal
    self._callback = callback
    self.Connected = true
    return self
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false
    self._signal:_removeConnection(self)
end

function Connection:disconnect() return self:Disconnect() end

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    return self
end

function Signal:Connect(callback)
    local connection = Connection.new(self, callback)
    table.insert(self._connections, connection)
    return connection
end

function Signal:connect(callback) return self:Connect(callback) end

function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            task.spawn(connection._callback, ...)
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:wait() return self:Wait() end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:_removeConnection(connection)
    for i, conn in ipairs(self._connections) do
        if conn == connection then
            table.remove(self._connections, i)
            break
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- Event Services
-- ═══════════════════════════════════════════════════════════

local InstanceEventService = {
    _watchedInstances = {}, 
    _propertyWatchers = {}, -- [instance] = { [propName] = Signal }
}

-- ChildAdded / ChildRemoved Logic
function InstanceEventService:GetSignal(instance, eventType)
    if not self._watchedInstances[instance] then
        if not instance.Data or instance.Data == 0 then
             return Signal.new()
        end

        local watcherData = {
            Signals = {
                ChildAdded = Signal.new(),
                ChildRemoved = Signal.new()
            },
            LastChildren = {},
            Cleanups = {}
        }
        
        local initialChildren = instance:GetChildren()
        for _, child in ipairs(initialChildren) do
            watcherData.LastChildren[child] = true
        end

        self._watchedInstances[instance] = watcherData
        
        local dataAddr = tonumber(instance.Data)
        local childrenStartPtr = memory.readu64(dataAddr + 0x70)
        local childrenEndPtrAddr = childrenStartPtr + 0x8
        local childrenListStart = memory.readu64(childrenStartPtr)
        
        local function CheckChanges()
            if not instance.Parent and instance ~= game then return end
            
            local currentChildren = instance:GetChildren()
            local currentSet = {}
            local added = {}
            local removed = {}
            
            for _, child in ipairs(currentChildren) do
                currentSet[child] = true
                if not watcherData.LastChildren[child] then
                    table.insert(added, child)
                end
            end
            
            for child, _ in pairs(watcherData.LastChildren) do
                if not currentSet[child] then
                    table.insert(removed, child)
                end
            end
            
            watcherData.LastChildren = currentSet
            
            for _, child in ipairs(added) do
                watcherData.Signals.ChildAdded:Fire(child)
            end
            for _, child in ipairs(removed) do
                watcherData.Signals.ChildRemoved:Fire(child)
            end
        end
        
        if childrenEndPtrAddr and childrenEndPtrAddr > 0 then
            table.insert(watcherData.Cleanups, memory.changed(childrenEndPtrAddr, "u64", function() pcall(CheckChanges) end))
        end
        
        if childrenListStart and childrenListStart > 0 then
            table.insert(watcherData.Cleanups, memory.changed(childrenListStart, "u64", function() pcall(CheckChanges) end))
        end
        
        table.insert(watcherData.Cleanups, memory.changed(dataAddr + 0x70, "u64", function()
            pcall(function()
                childrenStartPtr = memory.readu64(dataAddr + 0x70)
                if childrenStartPtr and childrenStartPtr > 0 then
                    childrenEndPtrAddr = childrenStartPtr + 0x8
                    childrenListStart = memory.readu64(childrenStartPtr)
                end
                CheckChanges()
            end)
        end))
    end
    
    return self._watchedInstances[instance].Signals[eventType]
end

-- Property Change Logic
-- Property Change Logic
function InstanceEventService:GetPropertySignal(instance, propName)
    if not self._propertyWatchers[instance] then
        self._propertyWatchers[instance] = {}
    end
    
    -- Normalize propName casing if needed (e.g. WalkSpeed -> Walkspeed)
    local resolvedPropName = propName
    
    -- Cache check with original name
    if self._propertyWatchers[instance][propName] then
        return self._propertyWatchers[instance][propName]
    end
    
    local signal = Signal.new()
    self._propertyWatchers[instance][propName] = signal
    
    if not instance.Data or instance.Data == 0 then
        return signal
    end
    
    -- Resolve Offset
    local offset = nil
    local ptr = instance.Data
    local className = instance.ClassName
    
    -- 1. Check LocalOffsets
    if LocalOffsets[className] and LocalOffsets[className][propName] then
        offset = LocalOffsets[className][propName]
    end
    
    -- 2. Check O (TheoOffsets)
    if not offset and O and O[className] then
        if O[className][propName] then
            offset = O[className][propName]
        else
            -- Case-insensitive Fallback
            local lowerProp = propName:lower()
            for k, v in pairs(O[className]) do
                if k:lower() == lowerProp then
                    resolvedPropName = k
                    offset = v
                    break
                end
            end
        end
    end
    
    -- 3. BasePart Special Handling
    if not offset and (className == "Part" or className == "MeshPart" or className == "UnionOperation" or className == "BasePart") then
         if LocalOffsets.BasePart and LocalOffsets.BasePart[propName] then
             offset = LocalOffsets.BasePart[propName]
         elseif O and O.BasePart then
             if O.BasePart[propName] then
                 offset = O.BasePart[propName]
                 ptr = getPrimitive(instance)
             end
         end
    end
     
    -- 4. Gui Special Handling
    if not offset and (className:match("Gui") or className:match("Frame") or className:match("Button") or className:match("Label")) then
         if LocalOffsets.Gui and LocalOffsets.Gui[propName] then
             offset = LocalOffsets.Gui[propName]
         end
    end

    if offset and ptr and ptr ~= 0 then
        local addr = tonumber(ptr) + offset
        
        -- Determine type to watch
        -- We try to read the property to see if it's a string
        local watcherType = "u64" -- Default safe watcher
        local success, val = pcall(function() return instance[propName] end)
        
        if success and type(val) == "string" then
             watcherType = "string"
        end
        
        memory.changed(addr, watcherType, function()
             -- Check if this Instance (or Class) has a 'Changed' signal connected
             -- If so, fire it too.
             if self._changedSignals and self._changedSignals[instance] then
                 -- If it's a ValueBase (having "Value" property being watched), we propagate the Value.
                 -- Note: This requires determining if this 'propName' IS "Value".
                 -- But 'Changed' logic is handled in 'GetChangedSignal' mostly.
                 -- Here we just need generic firing. 
                 -- Wait, standard Roblox 'Changed' fires with *propertyName*.
                 -- Unless it's ValueBase.Value changing.
                 
                 -- Optimization: The Changed signal logic below handles aggregation.
                 -- We just need to ensure that individual property signals exist so they CAN fire.
             end
             signal:Fire() 
        end)
    else
        warn("[Events] GetPropertyChangedSignal: Could not find offset for " .. className .. "." .. propName)
    end

    return signal
end

function InstanceEventService:GetChangedSignal(instance)
    if not self._changedSignals then self._changedSignals = {} end
    if self._changedSignals[instance] then return self._changedSignals[instance] end
    
    local signal = Signal.new()
    self._changedSignals[instance] = signal
    
    -- "Monitors every property (in our case the ones we can get to)"
    local className = instance.ClassName
    local propertiesToWatch = {}
    
    -- 1. Gather properties
    if LocalOffsets[className] then
        for k, _ in pairs(LocalOffsets[className]) do propertiesToWatch[k] = true end
    end
    if O and O[className] then
         for k, _ in pairs(O[className]) do propertiesToWatch[k] = true end
    end
    
    -- BasePart Inherited
     if (className == "Part" or className == "MeshPart" or className == "UnionOperation" or className == "BasePart") then
         if LocalOffsets.BasePart then for k, _ in pairs(LocalOffsets.BasePart) do propertiesToWatch[k] = true end end
         if O and O.BasePart then for k, _ in pairs(O.BasePart) do propertiesToWatch[k] = true end end
     end
     
     -- Gui Inherited
     if (className:match("Gui") or className:match("Frame") or className:match("Button") or className:match("Label")) then
          if LocalOffsets.Gui then for k, _ in pairs(LocalOffsets.Gui) do propertiesToWatch[k] = true end end
     end

    -- 2. Determine behavior (ValueBase or Regular)
    -- We assume standard behavior: fire with propertyName.
    -- UNLESS it's a ValueBase (IntValue, StringValue, etc)
    local isValueBase = false
    -- Simple check for known Value types or suffix
    if className:match("Value$") and className ~= "ObjectValue" then
         -- IntValue, StringValue, etc.
         -- ObjectValue is also a ValueBase in Roblox.
         isValueBase = true
    elseif className == "ObjectValue" then
         isValueBase = true
    end

    if isValueBase then
        -- Only watch "Value"
        if propertiesToWatch["Value"] or (O and O[className] and O[className].Value) then
             local ps = self:GetPropertySignal(instance, "Value")
             ps:Connect(function()
                 -- Fire with the NEW VALUE
                 signal:Fire(instance.Value)
             end)
        else
            -- Check if "value" lowercase exists
             local ps = self:GetPropertySignal(instance, "Value") -- Logic handles casing
             ps:Connect(function()
                 signal:Fire(instance.Value)
             end)
        end
    else
        -- Watch ALL
        for propName, _ in pairs(propertiesToWatch) do
            -- Filter out internal fields if needed? Assuming all in O are valid props.
            -- Don't block 'Parent' etc. offset provides internal/private fields too sometimes?
            -- TheoOffsets usually provides valid property offsets.
            local ps = self:GetPropertySignal(instance, propName)
            ps:Connect(function()
                signal:Fire(propName)
            end)
        end
    end
    
    return signal
end

-- ═══════════════════════════════════════════════════════════
-- Instance Extensions
-- ═══════════════════════════════════════════════════════════

local function registerEvents(classes)
    -- ChildAdded
    Instance.declare({
        class = classes,
        name = "ChildAdded",
        callback = {
            get = function(self)
                return InstanceEventService:GetSignal(self, "ChildAdded")
            end
        }
    })
    
    -- ChildRemoved
    Instance.declare({
        class = classes,
        name = "ChildRemoved",
        callback = {
            get = function(self)
                return InstanceEventService:GetSignal(self, "ChildRemoved")
            end
        }
    })
    
    Instance.declare({
        class = classes,
        name = "Changed",
        callback = {
            get = function(self)
                return InstanceEventService:GetChangedSignal(self)
            end
        }
    })

    -- GetPropertyChangedSignal
    Instance.declare({
        class = classes,
        name = "GetPropertyChangedSignal",
        callback = {
            method = function(self, propName)
                if type(propName) ~= "string" then
                    error("GetPropertyChangedSignal argument must be a string")
                end
                return InstanceEventService:GetPropertySignal(self, propName)
            end
        }
    })
end

-- Registering Events for all groups
registerEvents({"Instance", "ServiceProvider", "DataModel", "Workspace", "Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst"})
registerEvents({"ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer", "Teams", "SoundService", "Chat"})
registerEvents({"LocalizationService", "MarketplaceService", "TeleportService", "UserInputService", "RunService", "ContextActionService"})
registerEvents({"HttpService", "TweenService", "CollectionService", "PhysicsService", "PathfindingService", "BadgeService", "InsertService"})
registerEvents({"BasePart", "Part", "MeshPart", "UnionOperation", "TrussPart", "WedgePart", "CornerWedgePart", "SpawnLocation"})
registerEvents({"Seat", "VehicleSeat", "Model", "Folder", "Configuration", "Tool", "HopperBin", "Accessory", "Hat"})
registerEvents({"ScreenGui", "BillboardGui", "SurfaceGui", "GuiObject", "GuiBase2d", "Frame", "ScrollingFrame", "TextLabel"})
registerEvents({"TextButton", "TextBox", "ImageLabel", "ImageButton", "ViewportFrame", "VideoFrame", "Humanoid", "HumanoidDescription"})
registerEvents({"Player", "Backpack", "PlayerGui", "StarterGear", "Camera", "PointLight", "SpotLight", "SurfaceLight"})
registerEvents({"Sky", "Atmosphere", "BloomEffect", "BlurEffect", "ColorCorrectionEffect", "DepthOfFieldEffect", "SunRaysEffect", "Sound"})
registerEvents({"SoundGroup", "ParticleEmitter", "Smoke", "Fire", "Sparkles", "Trail", "Beam", "Attachment"})
registerEvents({"Bone", "Constraint", "AlignOrientation", "AlignPosition", "BallSocketConstraint", "HingeConstraint", "LineForce", "Torque"})
registerEvents({"VectorForce", "RodConstraint", "RopeConstraint", "SpringConstraint", "WeldConstraint", "UniversalConstraint", "CylindricalConstraint"})
registerEvents({"PrismaticConstraint", "JointInstance", "Motor", "Motor6D", "Weld", "ManualWeld", "Snap", "Glue"})
registerEvents({"BodyMover", "BodyForce", "BodyGyro", "BodyPosition", "BodyThrust", "BodyVelocity", "RocketPropulsion", "BaseScript"})
registerEvents({"Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction", "ValueBase"})
registerEvents({"Vector3Value", "CFrameValue", "BoolValue", "StringValue", "NumberValue", "IntValue", "ObjectValue", "Color3Value"})
registerEvents({"BrickColorValue", "RayValue", "Shirt", "Pants", "ShirtGraphic", "BodyColors", "CharacterMesh", "Clothing"})
registerEvents({"Animator", "Animation", "AnimationController", "AnimationTrack", "Keyframe", "KeyframeSequence", "Pose", "Decal"})
registerEvents({"Texture", "SurfaceAppearance", "DataModelMesh", "FileMesh", "SpecialMesh", "BlockMesh", "CylinderMesh", "ClickDetector"})
registerEvents({"ProximityPrompt", "Terrain", "Team", "WrapTarget", "WrapLayer", "Highlight", "SelectionBox", "SelectionSphere"})
registerEvents({"Handles", "ArcHandles", "ForceField", "Explosion", "LocalizationTable", "Hint", "Message", "Dialog"})
registerEvents({"DialogChoice", "NoCollisionConstraint", "Path", "PathfindingLink", "PathfindingModifier", "UIAspectRatioConstraint", "UICorner"})
registerEvents({"UIGradient", "UIGridLayout", "UIListLayout", "UIPageLayout", "UIScale", "UISizeConstraint", "UIStroke", "UIPadding"})


-- ═══════════════════════════════════════════════════════════
-- Players Service Extensions (Aliases)
-- ═══════════════════════════════════════════════════════════

Instance.declare({
    class = "Players",
    name = "PlayerAdded",
    callback = {
        get = function(self)
            return InstanceEventService:GetSignal(self, "ChildAdded")
        end
    }
})

Instance.declare({
    class = "Players",
    name = "PlayerRemoved",
    callback = {
        get = function(self)
            return InstanceEventService:GetSignal(self, "ChildRemoved")
        end
    }
})


print("loaded events and tweenService")

return TweenService

