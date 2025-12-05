
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


