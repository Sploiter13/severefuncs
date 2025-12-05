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
    self.Completed = {
        Connect = function(_, callback)
            assert(type(callback) == "function", "[TweenService] Completed callback must be a function")
            self._onFinishCallback = callback
            return {
                Disconnect = function()
                    self._onFinishCallback = nil
                end
            }
        end
    }
    
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
        
        if self._onFinishCallback then
            pcall(self._onFinishCallback)
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
            
            if self._onFinishCallback then
                pcall(self._onFinishCallback)
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

return TweenService
