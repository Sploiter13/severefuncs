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
    name = "Text",
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
