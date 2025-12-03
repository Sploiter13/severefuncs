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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.Humanoid.RigType)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number (0=R6, 1=R15)")
            memory.writei32(self.Data, O.Humanoid.RigType, value)
        end
    }
})

-- WalkSpeed
Instance.declare({class = "Humanoid", name = "WalkSpeed", callback = {
        get = function(self)
            assert(self.Data and self.Data ~= 0, "Invalid Pointer")
            return memory.readf32(self.Data, O.Humanoid.Walkspeed)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid Pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Humanoid.JumpPower)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Humanoid.JumpHeight)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Humanoid.HipHeight)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Humanoid.MaxSlopeAngle)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.Humanoid.AutoRotate) == 1
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, LocalOffsets.Humanoid.BreakJointsOnDeath) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            local statePtr = memory.readu64(self.Data, O.Humanoid.HumanoidState)
            
            if statePtr and statePtr ~= 0 then
                local id = memory.readi32(statePtr, O.Humanoid.HumanoidStateID)
                return HumanoidStates[id] or id
            end
            return "None"
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
            return bit32.band(byte, 2) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
            return bit32.band(byte, 16) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, LocalOffsets.BasePart.CastShadow) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, LocalOffsets.BasePart.Massless) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.BasePart.Shape)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            local primitive = getPrimitive(self)
            assert(primitive and primitive ~= 0, "Invalid primitive")
            return memory.readi32(primitive, O.BasePart.Material)
        end,
        set = function(self, value)
            assert(type(value) == "number", "Value must be a number")
            local primitive = getPrimitive(self)
            assert(primitive and primitive ~= 0, "Invalid primitive")
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
            local primitive = getPrimitive(self)
            assert(primitive and primitive ~= 0, "Invalid primitive")
            local raw = memory.readvector(primitive, O.BasePart.AssemblyLinearVelocity)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)
            assert(isVector(value), "Value must be a vector or Vector3")
            local primitive = getPrimitive(self)
            assert(primitive and primitive ~= 0, "Invalid primitive")
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
            local primitive = getPrimitive(self)
            assert(primitive and primitive ~= 0, "Invalid primitive")
            local raw = memory.readvector(primitive, O.BasePart.AssemblyAngularVelocity)
            return vector.create(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
        end,
        set = function(self, value)
            assert(isVector(value), "Value must be a vector or Vector3")
            local primitive = getPrimitive(self)
            assert(primitive and primitive ~= 0, "Invalid primitive")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            local raw = memory.readvector(self.Data, O.BasePart.Color)
            return Color3.new(raw.X, raw.Y, raw.Z)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.BasePart.Transparency)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.BasePart.Reflectance)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, LocalOffsets.Camera.HeadScale)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.Camera.CameraType)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Lighting.Brightness)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.Lighting.FogColor)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.Lighting.Ambient)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.Lighting.OutdoorAmbient)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.Lighting.ColorShift_Top)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.Lighting.ColorShift_Bottom)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Lighting.FogStart)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Lighting.FogEnd)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Lighting.ExposureCompensation)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Lighting.GeographicLatitude)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf64(self.Data, O.Lighting.TimeOfDay) / 3600
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.Player.Country)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Player.MaxZoomDistance)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Player.MinZoomDistance)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.Player.CameraMode)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.Player.Gender)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Workspace.Gravity)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Model.Scale)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.MeshPart.MeshID)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.MeshPart.TextureID)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Sky.MoonAngularSize)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.Sky.SunAngularSize)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.Sky.StarCount)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
                assert(self.Data and self.Data ~= 0, "Invalid pointer")
                return memory.readstring(self.Data, offset)
            end,
            set = function(self, value)
                assert(self.Data and self.Data ~= 0, "Invalid pointer")
                assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.Sky.SunTextureId)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.Sky.MoonTextureId)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.SpecialMesh.MeshID)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.SpecialMesh.Scale)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isVector(value), "Value must be a vector or Vector3")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.ProximityPrompt.KeyCode)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.ProximityPrompt.RequiresLineOfSight) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.ProximityPrompt.HoldDuration)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.ProximityPrompt.MaxActivationDistance)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.ProximityPrompt.ActionText)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.ProximityPrompt.ObjectText)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.ProximityPrompt.Enabled) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.ClickDetector.MouseIcon)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.ClickDetector.MaxActivationDistance)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.GuiObject.BackgroundColor3)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.GuiObject.BorderColor3)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.GuiObject.Visible) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readf32(self.Data, O.GuiObject.Rotation)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readi32(self.Data, O.GuiObject.LayoutOrder)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "number", "Value must be a number")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.TextLabel.Text)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readvector(self.Data, O.TextLabel.TextColor3)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(isColor(value), "Value must be a Color3, Vector3, or vector")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.TextLabel.RichText) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.ImageLabel.Image)
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "string", "Value must be a string")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readu8(self.Data, O.ScreenGui.Enabled) ~= 0
        end,
        set = function(self, value)
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            assert(type(value) == "boolean", "Value must be a boolean")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
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
            assert(self.Data and self.Data ~= 0, "Invalid pointer")
            return memory.readstring(self.Data, O.DataModel.ServerIP)
        end
    }
})

-- ═══════════════════════════════════════════════════════════
-- SECTION 22: CFRAME METHODS
-- ═══════════════════════════════════════════════════════════

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
            
            local p0 = self.Position
            local p1 = goal.Position
            
            -- Lerp position
            local newPos = vector.create(
                p0.X + (p1.X - p0.X) * alpha,
                p0.Y + (p1.Y - p0.Y) * alpha,
                p0.Z + (p1.Z - p0.Z) * alpha
            )
            
            -- Lerp rotation vectors
            local r0 = self.RightVector
            local r1 = goal.RightVector
            local u0 = self.UpVector
            local u1 = goal.UpVector
            local l0 = self.LookVector
            local l1 = goal.LookVector
            
            local newRight = vector.create(
                r0.X + (r1.X - r0.X) * alpha,
                r0.Y + (r1.Y - r0.Y) * alpha,
                r0.Z + (r1.Z - r0.Z) * alpha
            )
            
            local newUp = vector.create(
                u0.X + (u1.X - u0.X) * alpha,
                u0.Y + (u1.Y - u0.Y) * alpha,
                u0.Z + (u1.Z - u0.Z) * alpha
            )
            
            local newLook = vector.create(
                l0.X + (l1.X - l0.X) * alpha,
                l0.Y + (l1.Y - l0.Y) * alpha,
                l0.Z + (l1.Z - l0.Z) * alpha
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

-- CFrame:AngleBetween()
Instance.declare({
    class = "CFrame",
    name = "AngleBetween",
    callback = {
        method = function(self, other)
            assert(other, "Other CFrame required")
            
            local l0 = self.LookVector
            local l1 = other.LookVector
            
            local dot = l0.X * l1.X + l0.Y * l1.Y + l0.Z * l1.Z
            dot = math.max(-1, math.min(1, dot))
            
            return math.acos(dot)
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
