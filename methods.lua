
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
