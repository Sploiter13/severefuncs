--!native
--!optimize 2

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
-- ---- SIGNAL CLASS ----
-- ═══════════════════════════════════════════════════════════

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback)
    return setmetatable({
        _signal = signal,
        _callback = callback,
        Connected = true
    }, Connection)
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false
    
    local connections = self._signal._connections
    for i = #connections, 1, -1 do
        if connections[i] == self then
            tableremove(connections, i)
            break
        end
    end
end

Connection.disconnect = Connection.Disconnect

function Signal.new()
    return setmetatable({
        _connections = {}
    }, Signal)
end

function Signal:Connect(callback)
    local conn = Connection.new(self, callback)
    tableinsert(self._connections, conn)
    return conn
end

Signal.connect = Signal.Connect

function Signal:Fire(...)
    for _, conn in self._connections do
        if conn.Connected then
            taskspawn(conn._callback, ...)
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        taskspawn(thread, ...)
    end)
    return coroutine.yield()
end

Signal.wait = Signal.Wait

function Signal:Once(callback)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        callback(...)
    end)
    return conn
end

_G.Signal = Signal

-- ═══════════════════════════════════════════════════════════
-- ---- CHILD TRACKING ----
-- ═══════════════════════════════════════════════════════════

local function startChildTracker(instance)
    if childTrackers[instance] then
        return childTrackers[instance]
    end
    
    local tracker = {
        ChildAdded = Signal.new(),
        ChildRemoved = Signal.new(),
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
    
    local signal = Signal.new()
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
                
                return Signal.new()
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
                
                return Signal.new()
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
                
                return Signal.new()
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
            
            return Signal.new()
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
            
            return Signal.new()
        end
    }
})
