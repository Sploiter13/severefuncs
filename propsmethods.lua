--!optimize 2

local function hex(str)
    return tonumber(str, 16)
end

local success, result = pcall(function()
    local response = game:HttpGet("https://imtheo.lol/Offsets/Offsets.json")
    assert(response, "Failed to fetch offsets")
    return response
end)

if not success then
    warn("Offsets Fetch Error:", result)
end

local TheoOffsets
if success then
    TheoOffsets = crypt.json.decode(result)
end

if TheoOffsets and TheoOffsets.Offsets then
    local O = TheoOffsets.Offsets
local Offsets = {
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
    }
}
    local function round(num, decimals)
        local mult = 10 ^ (decimals or 3)
        return math.floor(num * mult + 0.5) / mult
    end

    local function getPrimitive(part)
        local success, result = pcall(function()
            assert(part, "Part is nil")
            assert(part.Data and part.Data ~= 0, "Part Data is invalid")
            return memory.readu64(part.Data, O.BasePart.Primitive)
        end)
        if success then 
            return result 
        else
            warn("getPrimitive Error:", result)
        end
        return nil
    end

    local BaseParts = {"Part", "MeshPart", "UnionOperation", "TrussPart"}
    local GuiElements = {"Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton"}
    local TextElements = {"TextLabel", "TextButton", "TextBox"}
    local ImageElements = {"ImageLabel", "ImageButton"}


    Instance.declare({class = "Humanoid", name = "RigType", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.Humanoid.RigType)
            end)
            if s then return r else warn("RigType Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writei32(self.Data, O.Humanoid.RigType, value)
            end)
            if not s then warn("RigType Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "BreakJointsOnDeath", callback = {
    get = function(self)
        local success, result = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            return memory.readu8(self.Data, Offsets.Humanoid.BreakJointsOnDeath) ~= 0
        end)
        if not success then warn("[BreakJointsOnDeath Get] Error:", result) return false end
        return result
    end,
    set = function(self, value)
        local success, err = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            assert(type(value) == "boolean", "Value must be a boolean")
            memory.writeu8(self.Data, Offsets.Humanoid.BreakJointsOnDeath, value and 1 or 0)
        end)
        if not success then warn("[BreakJointsOnDeath Set] Error:", err) end
    end
}})

--Instance.declare({class = "Humanoid", name = "WalkToPoint", callback = {
  --  get = function(self)
       -- local success, result = pcall(function()
        --    assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
          --  local vec = memory.readvector(self.Data, Offsets.Humanoid.WalkToPoint)
         --   return vector.create(vec.X, vec.Y, vec.Z)
      --  end)
       -- if not success then warn("[WalkToPoint Get] Error:", result) return vector.create(0,0,0) end
      --  return result
  --  end,
   -- set = function(self, value)
      --  local success, err = pcall(function()
          --  assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            
            -- Handle both Roblox Vector3 and vector lib object
          --  local vecToWrite = value
           -- if typeof(value) == "Vector3" then
              --  vecToWrite = vector.create(value.X, value.Y, value.Z)
           -- elseif type(value) == "vector" then
                -- Already correct format
          --  else
                 -- Try to treat as table if needed, or fail
                 -- If your environment strictly uses 'vector' lib objects, ensure test sends that.
                 -- The previous error was likely due to type checking logic mismatch.
                 -- We will just pass it through if it's a vector type.
          --  end
            
           -- memory.writevector(self.Data, Offsets.Humanoid.WalkToPoint, vecToWrite)
      --  end)
       -- if not success then warn("[WalkToPoint Set] Error:", err) end
   -- end
--}})

Instance.declare({class = BaseParts, name = "CastShadow", callback = {
    get = function(self)
        local success, result = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            return memory.readu8(self.Data, Offsets.BasePart.CastShadow) ~= 0
        end)
        if not success then warn("[CastShadow Get] Error:", result) return false end
        return result
    end,
    set = function(self, value)
        local success, err = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            assert(type(value) == "boolean", "Value must be a boolean")
            memory.writeu8(self.Data, Offsets.BasePart.CastShadow, value and 1 or 0)
        end)
        if not success then warn("[CastShadow Set] Error:", err) end
    end
}})

Instance.declare({class = BaseParts, name = "Massless", callback = {
    get = function(self)
        local success, result = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            return memory.readu8(self.Data, Offsets.BasePart.Massless) ~= 0
        end)
        if not success then warn("[Massless Get] Error:", result) return false end
        return result
    end,
    set = function(self, value)
        local success, err = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            assert(type(value) == "boolean", "Value must be a boolean")
            memory.writeu8(self.Data, Offsets.BasePart.Massless, value and 1 or 0)
        end)
        if not success then warn("[Massless Set] Error:", err) end
    end
}})

Instance.declare({class = "Camera", name = "HeadScale", callback = {
    get = function(self)
        local success, result = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            return memory.readf32(self.Data, Offsets.Camera.HeadScale)
        end)
        if not success then warn("[HeadScale Get] Error:", result) return 1 end
        return result
    end,
    set = function(self, value)
        local success, err = pcall(function()
            assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
            assert(type(value) == "number", "Value must be a number")
            memory.writef32(self.Data, Offsets.Camera.HeadScale, value)
        end)
        if not success then warn("[HeadScale Set] Error:", err) end
    end
}})

--Instance.declare({class = "Camera", name = "FieldOfView", callback = {
  --  get = function(self)
    --    local success, result = pcall(function()
        --    assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
      --      return memory.readf32(self.Data, Offsets.Camera.FieldOfView)
      --  end)
      --  if not success then warn("[FieldOfView Get] Error:", result) return 70 end
      --  return result
  --  end,
   -- set = function(self, value)
      --  local success, err = pcall(function()
       --     assert(self.Data and self.Data ~= 0, "Invalid Instance Data")
        --    assert(type(value) == "number", "Value must be a number")
         --   memory.writef32(self.Data, Offsets.Camera.FieldOfView, value)
      --  end)
      --  if not success then warn("[FieldOfView Set] Error:", err) end
  --  end
--}})

    local HumanoidStates = {
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
        [18] = "None"
    }

   
    local HumanoidStateNames = {}
    for id, name in pairs(HumanoidStates) do
        HumanoidStateNames[name] = id
    end

        Instance.declare({class = "Humanoid", name = "HumanoidStateType", callback = {
            get = function(self)
                local s, r = pcall(function()
                    assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                    
                   
                    local statePtr = memory.readu64(self.Data, O.Humanoid.HumanoidState)
                    
                   
                    if statePtr and statePtr ~= 0 then
                        local id = memory.readi32(statePtr, O.Humanoid.HumanoidStateID)
                       
                        return HumanoidStates[id] or id 
                    end
                    return "None"
                end)
                
                if s then 
                    return r 
                else 
                    warn("Humanoid State Get Error:", r) 
                    return "None" 
                end
            end,
            
            set = function(self, value)
                local s, err = pcall(function()
                     assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                     
                     local idToSet = value
                     
                     if type(value) == "string" then
                         idToSet = HumanoidStateNames[value]
                         assert(idToSet, "Invalid Humanoid State Name: " .. tostring(value))
                     else
                         assert(type(value) == "number", "Value must be a number or valid state string")
                     end

                     local statePtr = memory.readu64(self.Data, O.Humanoid.HumanoidState)
                                
                     if statePtr and statePtr ~= 0 then
                         memory.writei32(statePtr, O.Humanoid.HumanoidStateID, idToSet)
                     else
                         warn("Humanoid State Set Failed: State Pointer is nil")
                     end
                end)
                
                if not s then 
                    warn("Humanoid State Set Error:", err) 
                end
            end
        }})

    Instance.declare({class = "Humanoid", name = "WalkSpeed", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Humanoid.Walkspeed) 
            end)
            if s then return r else warn("WalkSpeed Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Humanoid.WalkspeedCheck, value)
                memory.writef32(self.Data, O.Humanoid.Walkspeed, value)
            end)
            if not s then warn("WalkSpeed Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "JumpPower", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Humanoid.JumpPower) 
            end)
            if s then return r else warn("JumpPower Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Humanoid.JumpPower, value)
            end)
            if not s then warn("JumpPower Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "JumpHeight", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Humanoid.JumpHeight) 
            end)
            if s then return r else warn("JumpHeight Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Humanoid.JumpHeight, value)
            end)
            if not s then warn("JumpHeight Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "HipHeight", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Humanoid.HipHeight) 
            end)
            if s then return r else warn("HipHeight Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Humanoid.HipHeight, value)
            end)
            if not s then warn("HipHeight Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "MaxSlopeAngle", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Humanoid.MaxSlopeAngle) 
            end)
            if s then return r else warn("MaxSlopeAngle Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Humanoid.MaxSlopeAngle, value)
            end)
            if not s then warn("MaxSlopeAngle Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "AutoRotate", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.Humanoid.AutoRotate) == 1 
            end)
            if s then return r else warn("AutoRotate Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.Humanoid.AutoRotate, value and 1 or 0)
            end)
            if not s then warn("AutoRotate Set Error:", err) end
        end
    }})

    --// BasePart Properties

    Instance.declare({class = BaseParts, name = "Anchored", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
                return bit32.band(byte, 2) ~= 0
            end)
            if s then return r else warn("Anchored Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
                byte = value and bit32.bor(byte, 2) or bit32.band(byte, bit32.bnot(2))
                memory.writeu8(self.Data, O.BasePart.PrimitiveFlags, byte)
            end)
            if not s then warn("Anchored Set Error:", err) end
        end
    }})

    Instance.declare({class = BaseParts, name = "CanTouch", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
                return bit32.band(byte, 16) ~= 0
            end)
            if s then return r else warn("CanTouch Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                local byte = memory.readu8(self.Data, O.BasePart.PrimitiveFlags)
                byte = value and bit32.bor(byte, 16) or bit32.band(byte, bit32.bnot(16))
                memory.writeu8(self.Data, O.BasePart.PrimitiveFlags, byte)
            end)
            if not s then warn("CanTouch Set Error:", err) end
        end
    }})

    Instance.declare({class = BaseParts, name = "Shape", callback = {
        get = function(self)
            local s, r = pcall(function() 
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.BasePart.Shape) 
            end)
            if s then return r else warn("Shape Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writeu8(self.Data, O.BasePart.Shape, value)
            end)
            if not s then warn("Shape Set Error:", err) end
        end
    }})

    
     --// BasePart Physics & Material

    Instance.declare({class = BaseParts, name = "AssemblyLinearVelocity", callback = {
        get = function(self)
            local s, r = pcall(function()
                local primitive = getPrimitive(self)
                assert(primitive and primitive ~= 0, "Invalid Primitive")
                
                local raw = memory.readvector(primitive, O.BasePart.AssemblyLinearVelocity)
                return Vector3.new(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
            end)
            if s then return r end
            if not s then warn("AssemblyLinearVelocity Get Error:", r) end
            return Vector3.new(0, 0, 0)
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(typeof(value) == "Vector3", "Value must be a Vector3")
                local primitive = getPrimitive(self)
                assert(primitive and primitive ~= 0, "Invalid Primitive")
                
                memory.writevector(primitive, O.BasePart.AssemblyLinearVelocity, value)
            end)
            if not s then warn("AssemblyLinearVelocity Set Error:", err) end
        end
    }})

    Instance.declare({class = BaseParts, name = "AssemblyAngularVelocity", callback = {
        get = function(self)
            local s, r = pcall(function()
                local primitive = getPrimitive(self)
                assert(primitive and primitive ~= 0, "Invalid Primitive")
                
                local raw = memory.readvector(primitive, O.BasePart.AssemblyAngularVelocity)
                return Vector3.new(round(raw.X, 3), round(raw.Y, 3), round(raw.Z, 3))
            end)
            if s then return r end
            if not s then warn("AssemblyAngularVelocity Get Error:", r) end
            return Vector3.new(0, 0, 0)
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(typeof(value) == "Vector3", "Value must be a Vector3")
                local primitive = getPrimitive(self)
                assert(primitive and primitive ~= 0, "Invalid Primitive")
                
                memory.writevector(primitive, O.BasePart.AssemblyAngularVelocity, value)
            end)
            if not s then warn("AssemblyAngularVelocity Set Error:", err) end
        end
    }})

    Instance.declare({class = BaseParts, name = "Material", callback = {
        get = function(self)
            local s, r = pcall(function()
                local primitive = getPrimitive(self)
                assert(primitive and primitive ~= 0, "Invalid Primitive")
                return memory.readi32(primitive, O.BasePart.Material)
            end)
            if s then return r end
            if not s then warn("Material Get Error:", r) end
            return 256 -- Default Plastic/Fabric value
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(type(value) == "number", "Value must be a number (Enum item value)")
                local primitive = getPrimitive(self)
                assert(primitive and primitive ~= 0, "Invalid Primitive")
                
                memory.writei32(primitive, O.BasePart.Material, value)
            end)
            if not s then warn("Material Set Error:", err) end
        end
    }})

    --// Camera Properties

    Instance.declare({class = "Camera", name = "CameraType", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.Camera.CameraType)
            end)
            if s then return r else warn("CameraType Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number (Enum item value)")
                memory.writei32(self.Data, O.Camera.CameraType, value)
            end)
            if not s then warn("CameraType Set Error:", err) end
        end
    }})

    --// Player Properties

    Instance.declare({class = "Player", name = "Country", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Player.Country)
            end)
            if s then return r else warn("Country Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Player.Country, value)
            end)
            if not s then warn("Country Set Error:", err) end
        end
    }})

    Instance.declare({class = "Player", name = "CameraMaxZoomDistance", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Player.MaxZoomDistance)
            end)
            if s then return r else warn("CameraMaxZoomDistance Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Player.MaxZoomDistance, value)
            end)
            if not s then warn("CameraMaxZoomDistance Set Error:", err) end
        end
    }})

    Instance.declare({class = "Player", name = "CameraMinZoomDistance", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Player.MinZoomDistance)
            end)
            if s then return r else warn("CameraMinZoomDistance Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Player.MinZoomDistance, value)
            end)
            if not s then warn("CameraMinZoomDistance Set Error:", err) end
        end
    }})

    Instance.declare({class = "Player", name = "CameraMode", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.Player.CameraMode)
            end)
            if s then return r else warn("CameraMode Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number (Enum item value)")
                memory.writei32(self.Data, O.Player.CameraMode, value)
            end)
            if not s then warn("CameraMode Set Error:", err) end
        end
    }})

    --// Lighting Properties

    Instance.declare({class = "Lighting", name = "Brightness", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Lighting.Brightness)
            end)
            if s then return r else warn("Brightness Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Lighting.Brightness, value)
            end)
            if not s then warn("Brightness Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "FogStart", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Lighting.FogStart)
            end)
            if s then return r else warn("FogStart Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Lighting.FogStart, value)
            end)
            if not s then warn("FogStart Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "FogEnd", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Lighting.FogEnd)
            end)
            if s then return r else warn("FogEnd Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Lighting.FogEnd, value)
            end)
            if not s then warn("FogEnd Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "FogColor", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.Lighting.FogColor)
            end)
            if s then return r else warn("FogColor Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                
                -- If Color3, convert to Vector3 if memory.writevector expects vectors for colors
                -- Assuming memory.readvector returns a Vector3 based on your snippet, writevector likely expects it too.
                if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                
                memory.writevector(self.Data, O.Lighting.FogColor, value)
            end)
            if not s then warn("FogColor Set Error:", err) end
        end
    }})

    
        --// Lighting Continued

    Instance.declare({class = "Lighting", name = "Ambient", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.Lighting.Ambient)
            end)
            if s then return r else warn("Ambient Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.Lighting.Ambient, value)
            end)
            if not s then warn("Ambient Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "OutdoorAmbient", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.Lighting.OutdoorAmbient)
            end)
            if s then return r else warn("OutdoorAmbient Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.Lighting.OutdoorAmbient, value)
            end)
            if not s then warn("OutdoorAmbient Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "ColorShift_Top", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.Lighting.ColorShift_Top)
            end)
            if s then return r else warn("ColorShift_Top Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.Lighting.ColorShift_Top, value)
            end)
            if not s then warn("ColorShift_Top Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "ColorShift_Bottom", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.Lighting.ColorShift_Bottom)
            end)
            if s then return r else warn("ColorShift_Bottom Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.Lighting.ColorShift_Bottom, value)
            end)
            if not s then warn("ColorShift_Bottom Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "ExposureCompensation", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Lighting.ExposureCompensation)
            end)
            if s then return r else warn("ExposureCompensation Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Lighting.ExposureCompensation, value)
            end)
            if not s then warn("ExposureCompensation Set Error:", err) end
        end
    }})

    Instance.declare({class = "Lighting", name = "GeographicLatitude", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Lighting.GeographicLatitude)
            end)
            if s then return r else warn("GeographicLatitude Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Lighting.GeographicLatitude, value)
            end)
            if not s then warn("GeographicLatitude Set Error:", err) end
        end
    }})

    --// Workspace Properties

    Instance.declare({class = "Workspace", name = "DistributedGameTime", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf64(self.Data, O.Workspace.DistributedGameTime)
            end)
            if s then return r else warn("DistributedGameTime Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef64(self.Data, O.Workspace.DistributedGameTime, value)
            end)
            if not s then warn("DistributedGameTime Set Error:", err) end
        end
    }})

    --// Model Properties

    Instance.declare({class = "Model", name = "Scale", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Model.Scale)
            end)
            if s then return r else warn("Model Scale Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Model.Scale, value)
            end)
            if not s then warn("Model Scale Set Error:", err) end
        end
    }})

    --// MeshPart Properties

    Instance.declare({class = "MeshPart", name = "MeshId", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.MeshPart.MeshId)
            end)
            if s then return r else warn("MeshId Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.MeshPart.MeshId, value)
            end)
            if not s then warn("MeshId Set Error:", err) end
        end
    }})

    Instance.declare({class = "MeshPart", name = "TextureID", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.MeshPart.Texture)
            end)
            if s then return r else warn("TextureID Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.MeshPart.Texture, value)
            end)
            if not s then warn("TextureID Set Error:", err) end
        end
    }})

    --// ProximityPrompt Properties

    Instance.declare({class = "ProximityPrompt", name = "KeyCode", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.ProximityPrompt.KeyCode)
            end)
            if s then return r else warn("KeyCode Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number (Enum item value)")
                memory.writei32(self.Data, O.ProximityPrompt.KeyCode, value)
            end)
            if not s then warn("KeyCode Set Error:", err) end
        end
    }})

    Instance.declare({class = "ProximityPrompt", name = "RequiresLineOfSight", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.ProximityPrompt.RequiresLineOfSight) == 1
            end)
            if s then return r else warn("RequiresLineOfSight Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.ProximityPrompt.RequiresLineOfSight, value and 1 or 0)
            end)
            if not s then warn("RequiresLineOfSight Set Error:", err) end
        end
    }})

    --// Sky Properties

    Instance.declare({class = "Sky", name = "MoonAngularSize", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Sky.MoonAngularSize)
            end)
            if s then return r else warn("MoonAngularSize Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Sky.MoonAngularSize, value)
            end)
            if not s then warn("MoonAngularSize Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SunAngularSize", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Sky.SunAngularSize)
            end)
            if s then return r else warn("SunAngularSize Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Sky.SunAngularSize, value)
            end)
            if not s then warn("SunAngularSize Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxOrientation", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.Sky.SkyboxOrientation)
            end)
            if s then return r else warn("SkyboxOrientation Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3", "Value must be a Vector3")
                memory.writevector(self.Data, O.Sky.SkyboxOrientation, value)
            end)
            if not s then warn("SkyboxOrientation Set Error:", err) end
        end
    }})

    --// SpecialMesh Properties

    Instance.declare({class = "SpecialMesh", name = "MeshId", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.SpecialMesh.MeshId)
            end)
            if s then return r else warn("SpecialMesh MeshId Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.SpecialMesh.MeshId, value)
            end)
            if not s then warn("SpecialMesh MeshId Set Error:", err) end
        end
    }})

    Instance.declare({class = "SpecialMesh", name = "Scale", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.SpecialMesh.Scale)
            end)
            if s then return r else warn("SpecialMesh Scale Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3", "Value must be a Vector3")
                memory.writevector(self.Data, O.SpecialMesh.Scale, value)
            end)
            if not s then warn("SpecialMesh Scale Set Error:", err) end
        end
    }})
    
    --// ClickDetector Properties

    Instance.declare({class = "ClickDetector", name = "MouseIcon", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.ClickDetector.MouseIcon)
            end)
            if s then return r else warn("MouseIcon Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.ClickDetector.MouseIcon, value)
            end)
            if not s then warn("MouseIcon Set Error:", err) end
        end
    }})

    --// GUI Properties

    Instance.declare({class = GuiElements, name = "BackgroundColor3", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.GuiObject.BackgroundColor3)
            end)
            if s then return r else warn("BackgroundColor3 Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.GuiObject.BackgroundColor3, value)
            end)
            if not s then warn("BackgroundColor3 Set Error:", err) end
        end
    }})

    Instance.declare({class = GuiElements, name = "BorderColor3", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.GuiObject.BorderColor3)
            end)
            if s then return r else warn("BorderColor3 Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.GuiObject.BorderColor3, value)
            end)
            if not s then warn("BorderColor3 Set Error:", err) end
        end
    }})

    Instance.declare({class = ImageElements, name = "Image", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.GuiObject.Image)
            end)
            if s then return r else warn("Image Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.GuiObject.Image, value)
            end)
            if not s then warn("Image Set Error:", err) end
        end
    }})

    Instance.declare({class = GuiElements, name = "LayoutOrder", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.GuiObject.LayoutOrder)
            end)
            if s then return r else warn("LayoutOrder Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writei32(self.Data, O.GuiObject.LayoutOrder, value)
            end)
            if not s then warn("LayoutOrder Set Error:", err) end
        end
    }})

    Instance.declare({class = TextElements, name = "RichText", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.GuiObject.RichText) == 1
            end)
            if s then return r else warn("RichText Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.GuiObject.RichText, value and 1 or 0)
            end)
            if not s then warn("RichText Set Error:", err) end
        end
    }})

    Instance.declare({class = TextElements, name = "Text", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.GuiObject.Text)
            end)
            if s then return r else warn("Text Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.GuiObject.Text, value)
            end)
            if not s then warn("Text Set Error:", err) end
        end
    }})

    Instance.declare({class = TextElements, name = "TextColor3", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, O.GuiObject.TextColor3)
            end)
            if s then return r else warn("TextColor3 Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3" or typeof(value) == "Color3", "Value must be a Vector3 or Color3")
                 if typeof(value) == "Color3" then
                     value = Vector3.new(value.R, value.G, value.B)
                end
                memory.writevector(self.Data, O.GuiObject.TextColor3, value)
            end)
            if not s then warn("TextColor3 Set Error:", err) end
        end
    }})

    --// AnimationTrack Properties

    Instance.declare({class = "AnimationTrack", name = "IsPlaying", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.AnimationTrack.IsPlaying) == 1
            end)
            if s then return r else warn("IsPlaying Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.AnimationTrack.IsPlaying, value and 1 or 0)
            end)
            if not s then warn("IsPlaying Set Error:", err) end
        end
    }})

    Instance.declare({class = "AnimationTrack", name = "Looped", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.AnimationTrack.Looped) == 1
            end)
            if s then return r else warn("Looped Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.AnimationTrack.Looped, value and 1 or 0)
            end)
            if not s then warn("Looped Set Error:", err) end
        end
    }})

    Instance.declare({class = "AnimationTrack", name = "Speed", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.AnimationTrack.Speed)
            end)
            if s then return r else warn("Speed Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.AnimationTrack.Speed, value)
            end)
            if not s then warn("Speed Set Error:", err) end
        end
    }})

    Instance.declare({class = "Workspace", name = "Gravity", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Workspace.Gravity)
            end)
            if s then return r else warn("Gravity Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Workspace.Gravity, value)
            end)
            if not s then warn("Gravity Set Error:", err) end
        end
    }})

    --// Humanoid Extra & BasePart Color

    Instance.declare({class = "Humanoid", name = "FloorMaterial", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.Humanoid.FloorMaterial)
            end)
            if s then return r else warn("FloorMaterial Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writei32(self.Data, O.Humanoid.FloorMaterial, value)
            end)
            if not s then warn("FloorMaterial Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "Jump", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.Humanoid.Jump) == 1
            end)
            if s then return r else warn("Jump Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.Humanoid.Jump, value and 1 or 0)
            end)
            if not s then warn("Jump Set Error:", err) end
        end
    }})

    Instance.declare({class = BaseParts, name = "Color", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                local vec = memory.readvector(self.Data, O.BasePart.Color3)
                return Color3.new(vec.X, vec.Y, vec.Z)
            end)
            if s then return r else warn("Color Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Color3", "Value must be a Color3")
                local vec = vector.create(value.R, value.G, value.B)
                memory.writevector(self.Data, O.BasePart.Color3, vec)
            end)
            if not s then warn("Color Set Error:", err) end
        end
    }})

        --// Lighting Time & Skybox Properties

    Instance.declare({class = "Lighting", name = "ClockTime", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.Lighting.ClockTime)
            end)
            if s then return r else warn("ClockTime Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.Lighting.ClockTime, value)
            end)
            if not s then warn("ClockTime Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxBk", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SkyboxBk)
            end)
            if s then return r else warn("SkyboxBk Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SkyboxBk, value)
            end)
            if not s then warn("SkyboxBk Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxDn", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SkyboxDn)
            end)
            if s then return r else warn("SkyboxDn Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SkyboxDn, value)
            end)
            if not s then warn("SkyboxDn Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxFt", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SkyboxFt)
            end)
            if s then return r else warn("SkyboxFt Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SkyboxFt, value)
            end)
            if not s then warn("SkyboxFt Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxLf", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SkyboxLf)
            end)
            if s then return r else warn("SkyboxLf Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SkyboxLf, value)
            end)
            if not s then warn("SkyboxLf Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxRt", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SkyboxRt)
            end)
            if s then return r else warn("SkyboxRt Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SkyboxRt, value)
            end)
            if not s then warn("SkyboxRt Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SkyboxUp", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SkyboxUp)
            end)
            if s then return r else warn("SkyboxUp Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SkyboxUp, value)
            end)
            if not s then warn("SkyboxUp Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "SunTextureId", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.SunTextureId)
            end)
            if s then return r else warn("SunTextureId Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.SunTextureId, value)
            end)
            if not s then warn("SunTextureId Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "MoonTextureId", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.Sky.MoonTextureId)
            end)
            if s then return r else warn("MoonTextureId Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.Sky.MoonTextureId, value)
            end)
            if not s then warn("MoonTextureId Set Error:", err) end
        end
    }})

    Instance.declare({class = "Sky", name = "StarCount", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readi32(self.Data, O.Sky.StarCount)
            end)
            if s then return r else warn("StarCount Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writei32(self.Data, O.Sky.StarCount, value)
            end)
            if not s then warn("StarCount Set Error:", err) end
        end
    }})

    --// ProximityPrompt Extras

    Instance.declare({class = "ProximityPrompt", name = "HoldDuration", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.ProximityPrompt.HoldDuration)
            end)
            if s then return r else warn("HoldDuration Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.ProximityPrompt.HoldDuration, value)
            end)
            if not s then warn("HoldDuration Set Error:", err) end
        end
    }})

    Instance.declare({class = "ProximityPrompt", name = "MaxActivationDistance", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.ProximityPrompt.MaxActivationDistance)
            end)
            if s then return r else warn("MaxActivationDistance Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.ProximityPrompt.MaxActivationDistance, value)
            end)
            if not s then warn("MaxActivationDistance Set Error:", err) end
        end
    }})

    Instance.declare({class = "ProximityPrompt", name = "ActionText", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.ProximityPrompt.ActionText)
            end)
            if s then return r else warn("ActionText Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.ProximityPrompt.ActionText, value)
            end)
            if not s then warn("ActionText Set Error:", err) end
        end
    }})

    Instance.declare({class = "ProximityPrompt", name = "ObjectText", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readstring(self.Data, O.ProximityPrompt.ObjectText)
            end)
            if s then return r else warn("ObjectText Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "string", "Value must be a string")
                memory.writestring(self.Data, O.ProximityPrompt.ObjectText, value)
            end)
            if not s then warn("ObjectText Set Error:", err) end
        end
    }})

    Instance.declare({class = "ProximityPrompt", name = "Enabled", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.ProximityPrompt.Enabled) == 1
            end)
            if s then return r else warn("Enabled Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.ProximityPrompt.Enabled, value and 1 or 0)
            end)
            if not s then warn("Enabled Set Error:", err) end
        end
    }})

    --// ClickDetector Distance

    Instance.declare({class = "ClickDetector", name = "MaxActivationDistance", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.ClickDetector.MaxActivationDistance)
            end)
            if s then return r else warn("CD MaxActivationDistance Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.ClickDetector.MaxActivationDistance, value)
            end)
            if not s then warn("CD MaxActivationDistance Set Error:", err) end
        end
    }})

    --// GuiObject Vis/Rot

    -- Update table to match earlier definition if needed, or rely on local scope
    local GuiElementsAll = {"Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton", "ScreenGui"}

    Instance.declare({class = GuiElementsAll, name = "Visible", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, O.GuiObject.Visible) == 1
            end)
            if s then return r else warn("Visible Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, O.GuiObject.Visible, value and 1 or 0)
            end)
            if not s then warn("Visible Set Error:", err) end
        end
    }})

    Instance.declare({class = GuiElementsAll, name = "Rotation", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readf32(self.Data, O.GuiObject.Rotation)
            end)
            if s then return r else warn("Rotation Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "number", "Value must be a number")
                memory.writef32(self.Data, O.GuiObject.Rotation, value)
            end)
            if not s then warn("Rotation Set Error:", err) end
        end
    }})

    --// Animation Pointers

    Instance.declare({class = "AnimationTrack", name = "Animation", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                local ptr = memory.readu64(self.Data, O.AnimationTrack.Animation)
                if ptr and ptr ~= 0 then
                    return pointer_to_userdata(ptr)
                end
                return nil
            end)
            if s then return r else warn("Animation Get Error:", r) end
        end
    }})

end


-- NtgetOffsets Logic
local successNt, resultNt = pcall(function()
    local response = game:HttpGet("https://offsets.ntgetwritewatch.workers.dev/offsets.json")
    assert(response, "Failed to fetch NtgetOffsets")
    return response
end)

if not successNt then
    warn("NtgetOffsets Fetch Error:", resultNt)
end

local NtgetOffsets
if successNt then
    NtgetOffsets = crypt.json.decode(resultNt)
end

if NtgetOffsets and NtgetOffsets.MoveDirection then
    Instance.declare({class = "Humanoid", name = "MoveDirection", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readvector(self.Data, hex(NtgetOffsets.MoveDirection))
            end)
            if s then return r else warn("MoveDirection Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(typeof(value) == "Vector3", "Value must be a Vector3")
                memory.writevector(self.Data, hex(NtgetOffsets.MoveDirection), value)
            end)
            if not s then warn("MoveDirection Set Error:", err) end
        end
    }})

    Instance.declare({class = "Humanoid", name = "Sit", callback = {
        get = function(self)
            local s, r = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                return memory.readu8(self.Data, hex(NtgetOffsets.Sit)) == 1
            end)
            if s then return r else warn("Sit Get Error:", r) end
        end,
        set = function(self, value)
            local s, err = pcall(function()
                assert(self.Data and self.Data ~= 0, "Invalid Pointer")
                assert(type(value) == "boolean", "Value must be a boolean")
                memory.writeu8(self.Data, hex(NtgetOffsets.Sit), value and 1 or 0)
            end)
            if not s then warn("Sit Set Error:", err) end
        end
    }})
end

-- IsA Implementation

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

-- GetBoundingBox Method

Instance.declare({
    class = {"Model"},
    name = "GetBoundingBox",
    callback = {
        method = function(self)
            local s, cframe, size = pcall(function()
                assert(self, "Self is nil")
                local parts = {}

                local function collectParts(instance)
                    -- Using the custom IsA method here internally
                    local children = instance:GetChildren()
                    for _, child in ipairs(children) do
                        if child.ClassName == "Part" or child.ClassName == "MeshPart" or child.ClassName == "UnionOperation" then
                             table.insert(parts, child)
                        end
                        collectParts(child)
                    end
                end

                collectParts(self)

                if #parts == 0 then
                    return CFrame.new(0, 0, 0), Vector3.new(0, 0, 0)
                end

                local minX, minY, minZ = math.huge, math.huge, math.huge
                local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

                for _, part in ipairs(parts) do
                    local partCF = part.CFrame
                    local partSize = part.Size
                    local halfSize = Vector3.new(partSize.x / 2, partSize.y / 2, partSize.z / 2)

                    local corners = {
                        part:PointToWorldSpace(Vector3.new(-halfSize.x, -halfSize.y, -halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(-halfSize.x, -halfSize.y, halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(-halfSize.x, halfSize.y, -halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(-halfSize.x, halfSize.y, halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(halfSize.x, -halfSize.y, -halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(halfSize.x, -halfSize.y, halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(halfSize.x, halfSize.y, -halfSize.z)),
                        part:PointToWorldSpace(Vector3.new(halfSize.x, halfSize.y, halfSize.z)),
                    }

                    for _, corner in ipairs(corners) do
                        minX = math.min(minX, corner.x)
                        minY = math.min(minY, corner.y)
                        minZ = math.min(minZ, corner.z)
                        maxX = math.max(maxX, corner.x)
                        maxY = math.max(maxY, corner.y)
                        maxZ = math.max(maxZ, corner.z)
                    end
                end

                local centerX = (minX + maxX) / 2
                local centerY = (minY + maxY) / 2
                local centerZ = (minZ + maxZ) / 2
                local sizeX = maxX - minX
                local sizeY = maxY - minY
                local sizeZ = maxZ - minZ

                return CFrame.new(centerX, centerY, centerZ), Vector3.new(sizeX, sizeY, sizeZ)
            end)
            
            if s then return cframe, size else warn("GetBoundingBox Error:", cframe) return CFrame.new(), Vector3.new() end
        end
    }
})


local CFrameClasses = {"Part", "MeshPart", "UnionOperation", "TrussPart", "Camera"}

Instance.declare({
    class = CFrameClasses,
    name = "Inverse",
    callback = {
        method = function(self)
            local currentCFrame = self.CFrame
            local posX, posY, posZ = currentCFrame.Position.x, currentCFrame.Position.y, currentCFrame.Position.z
            
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local transposeRightX, transposeRightY, transposeRightZ = rightX, rightY, rightZ
            local transposeUpX, transposeUpY, transposeUpZ = upX, upY, upZ
            local transposeLookX, transposeLookY, transposeLookZ = lookX, lookY, lookZ
            
            local inverseX = -(transposeRightX * posX + transposeRightY * posY + transposeRightZ * posZ)
            local inverseY = -(transposeUpX * posX + transposeUpY * posY + transposeUpZ * posZ)
            local inverseZ = -(transposeLookX * posX + transposeLookY * posY + transposeLookZ * posZ)
            
            return CFrame.new(
                inverseX, inverseY, inverseZ,
                transposeRightX, transposeRightY, transposeRightZ,
                transposeUpX, transposeUpY, transposeUpZ,
                transposeLookX, transposeLookY, transposeLookZ
            )
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "ToWorldSpace",
    callback = {
        method = function(self, offsetCFrame)
            local baseCFrame = self.CFrame
            
            local baseRightX = baseCFrame.RightVector.x
            local baseRightY = baseCFrame.RightVector.y
            local baseRightZ = baseCFrame.RightVector.z
            local baseUpX = baseCFrame.UpVector.x
            local baseUpY = baseCFrame.UpVector.y
            local baseUpZ = baseCFrame.UpVector.z
            local baseLookX = -baseCFrame.LookVector.x
            local baseLookY = -baseCFrame.LookVector.y
            local baseLookZ = -baseCFrame.LookVector.z
            local basePosX = baseCFrame.Position.x
            local basePosY = baseCFrame.Position.y
            local basePosZ = baseCFrame.Position.z
            
            local offsetPosX = offsetCFrame.X
            local offsetPosY = offsetCFrame.Y
            local offsetPosZ = offsetCFrame.Z
            local offsetRightX = offsetCFrame.R00
            local offsetRightY = offsetCFrame.R01
            local offsetRightZ = offsetCFrame.R02
            local offsetUpX = offsetCFrame.R10
            local offsetUpY = offsetCFrame.R11
            local offsetUpZ = offsetCFrame.R12
            local offsetLookX = offsetCFrame.R20
            local offsetLookY = offsetCFrame.R21
            local offsetLookZ = offsetCFrame.R22
            
            local resultRightX = baseRightX * offsetRightX + baseUpX * offsetUpX + baseLookX * offsetLookX
            local resultRightY = baseRightX * offsetRightY + baseUpX * offsetUpY + baseLookX * offsetLookY
            local resultRightZ = baseRightX * offsetRightZ + baseUpX * offsetUpZ + baseLookX * offsetLookZ
            local resultUpX = baseRightY * offsetRightX + baseUpY * offsetUpX + baseLookY * offsetLookX
            local resultUpY = baseRightY * offsetRightY + baseUpY * offsetUpY + baseLookY * offsetLookY
            local resultUpZ = baseRightY * offsetRightZ + baseUpY * offsetUpZ + baseLookY * offsetLookZ
            local resultLookX = baseRightZ * offsetRightX + baseUpZ * offsetUpX + baseLookZ * offsetLookX
            local resultLookY = baseRightZ * offsetRightY + baseUpZ * offsetUpY + baseLookZ * offsetLookY
            local resultLookZ = baseRightZ * offsetRightZ + baseUpZ * offsetUpZ + baseLookZ * offsetLookZ
            
            local resultPosX = basePosX + baseRightX * offsetPosX + baseUpX * offsetPosY + baseLookX * offsetPosZ
            local resultPosY = basePosY + baseRightY * offsetPosX + baseUpY * offsetPosY + baseLookY * offsetPosZ
            local resultPosZ = basePosZ + baseRightZ * offsetPosX + baseUpZ * offsetPosY + baseLookZ * offsetPosZ
            
            return CFrame.new(
                resultPosX, resultPosY, resultPosZ,
                resultRightX, resultRightY, resultRightZ,
                resultUpX, resultUpY, resultUpZ,
                resultLookX, resultLookY, resultLookZ
            )
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "ToObjectSpace",
    callback = {
        method = function(self, targetCFrame)
            local inverseCFrame = self:Inverse()
            return inverseCFrame:ToWorldSpace(targetCFrame)
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "PointToWorldSpace",
    callback = {
        method = function(self, localPoint)
            local currentCFrame = self.CFrame
            
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            local posX, posY, posZ = currentCFrame.Position.x, currentCFrame.Position.y, currentCFrame.Position.z
            
            local pointX, pointY, pointZ = localPoint.x, localPoint.y, localPoint.z
            
            return Vector3.new(
                posX + rightX * pointX + upX * pointY + lookX * pointZ,
                posY + rightY * pointX + upY * pointY + lookY * pointZ,
                posZ + rightZ * pointX + upZ * pointY + lookZ * pointZ
            )
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "PointToObjectSpace",
    callback = {
        method = function(self, worldPoint)
            local currentCFrame = self.CFrame
            
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            local posX, posY, posZ = currentCFrame.Position.x, currentCFrame.Position.y, currentCFrame.Position.z
            
            local deltaX = worldPoint.x - posX
            local deltaY = worldPoint.y - posY
            local deltaZ = worldPoint.z - posZ
            
            return Vector3.new(
                rightX * deltaX + rightY * deltaY + rightZ * deltaZ,
                upX * deltaX + upY * deltaY + upZ * deltaZ,
                lookX * deltaX + lookY * deltaY + lookZ * deltaZ
            )
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "VectorToWorldSpace",
    callback = {
        method = function(self, localVector)
            local currentCFrame = self.CFrame
            
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local vecX, vecY, vecZ = localVector.x, localVector.y, localVector.z
            
            return Vector3.new(
                rightX * vecX + upX * vecY + lookX * vecZ,
                rightY * vecX + upY * vecY + lookY * vecZ,
                rightZ * vecX + upZ * vecY + lookZ * vecZ
            )
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "VectorToObjectSpace",
    callback = {
        method = function(self, worldVector)
            local currentCFrame = self.CFrame
            
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local vecX, vecY, vecZ = worldVector.x, worldVector.y, worldVector.z
            
            return Vector3.new(
                rightX * vecX + rightY * vecY + rightZ * vecZ,
                upX * vecX + upY * vecY + upZ * vecZ,
                lookX * vecX + lookY * vecY + lookZ * vecZ
            )
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "GetComponents",
    callback = {
        method = function(self)
            local currentCFrame = self.CFrame
            local posX, posY, posZ = currentCFrame.Position.x, currentCFrame.Position.y, currentCFrame.Position.z
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            return posX, posY, posZ, rightX, rightY, rightZ, upX, upY, upZ, lookX, lookY, lookZ
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "ToEulerAnglesXYZ",
    callback = {
        method = function(self)
            local currentCFrame = self.CFrame
            local rightX, rightY = currentCFrame.RightVector.x, currentCFrame.RightVector.y
            local upY, upZ = currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local sinY = lookX
            local angleX, angleY, angleZ
            
            if math.abs(sinY) < 0.999999 then
                angleX = math.atan2(-lookY, lookZ)
                angleY = math.atan2(sinY, math.sqrt(1 - sinY * sinY))
                angleZ = math.atan2(-rightY, rightX)
            else
                angleX = math.atan2(upY, upZ)
                angleY = math.atan2(sinY, math.sqrt(1 - sinY * sinY))
                angleZ = 0
            end
            
            return angleX, angleY, angleZ
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "ToEulerAnglesYXZ",
    callback = {
        method = function(self)
            local currentCFrame = self.CFrame
            local rightX = currentCFrame.RightVector.x
            local upX, upY = currentCFrame.UpVector.x, currentCFrame.UpVector.y
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local sinX = -lookY
            local angleX, angleY, angleZ
            
            if math.abs(sinX) < 0.999999 then
                angleY = math.atan2(lookX, lookZ)
                angleX = math.atan2(sinX, math.sqrt(1 - sinX * sinX))
                angleZ = math.atan2(upX, upY)
            else
                angleY = math.atan2(-lookZ, rightX)
                angleX = math.atan2(sinX, math.sqrt(1 - sinX * sinX))
                angleZ = 0
            end
            
            return angleX, angleY, angleZ
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "ToOrientation",
    callback = {
        method = function(self)
            return self:ToEulerAnglesYXZ()
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "ToAxisAngle",
    callback = {
        method = function(self)
            local currentCFrame = self.CFrame
            local rightX, rightY, rightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local upX, upY, upZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local lookX, lookY, lookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local trace = rightX + upY + lookZ
            local quatW, quatX, quatY, quatZ
            
            if trace > 0 then
                local scale = math.sqrt(trace + 1.0) * 2
                quatW = 0.25 * scale
                quatX = (upZ - lookY) / scale
                quatY = (lookX - rightZ) / scale
                quatZ = (rightY - upX) / scale
            elseif rightX > upY and rightX > lookZ then
                local scale = math.sqrt(1.0 + rightX - upY - lookZ) * 2
                quatW = (upZ - lookY) / scale
                quatX = 0.25 * scale
                quatY = (upX + rightY) / scale
                quatZ = (lookX + rightZ) / scale
            elseif upY > lookZ then
                local scale = math.sqrt(1.0 + upY - rightX - lookZ) * 2
                quatW = (lookX - rightZ) / scale
                quatX = (upX + rightY) / scale
                quatY = 0.25 * scale
                quatZ = (lookY + upZ) / scale
            else
                local scale = math.sqrt(1.0 + lookZ - rightX - upY) * 2
                quatW = (rightY - upX) / scale
                quatX = (lookX + rightZ) / scale
                quatY = (lookY + upZ) / scale
                quatZ = 0.25 * scale
            end
            
            local quatLength = math.sqrt(quatX * quatX + quatY * quatY + quatZ * quatZ + quatW * quatW)
            if quatLength == 0 then
                return Vector3.new(1, 0, 0), 0
            end
            
            quatX, quatY, quatZ, quatW = quatX / quatLength, quatY / quatLength, quatZ / quatLength, quatW / quatLength
            
            local angle = 2 * math.acos(math.clamp(quatW, -1, 1))
            local sinHalfAngle = math.sqrt(1 - quatW * quatW)
            
            if sinHalfAngle < 1e-6 then
                return Vector3.new(1, 0, 0), 0
            end
            
            return Vector3.new(quatX / sinHalfAngle, quatY / sinHalfAngle, quatZ / sinHalfAngle), angle
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "Lerp",
    callback = {
        method = function(self, goalCFrame, alpha)
            local startCFrame = self.CFrame
            local startPosX, startPosY, startPosZ = startCFrame.Position.x, startCFrame.Position.y, startCFrame.Position.z
            local goalPosX, goalPosY, goalPosZ = goalCFrame.X, goalCFrame.Y, goalCFrame.Z
            
            local lerpedPosX = startPosX + (goalPosX - startPosX) * alpha
            local lerpedPosY = startPosY + (goalPosY - startPosY) * alpha
            local lerpedPosZ = startPosZ + (goalPosZ - startPosZ) * alpha
            
            local startRightX, startRightY, startRightZ = startCFrame.RightVector.x, startCFrame.RightVector.y, startCFrame.RightVector.z
            local startUpX, startUpY, startUpZ = startCFrame.UpVector.x, startCFrame.UpVector.y, startCFrame.UpVector.z
            local startLookX, startLookY, startLookZ = -startCFrame.LookVector.x, -startCFrame.LookVector.y, -startCFrame.LookVector.z
            
            local goalRightX, goalRightY, goalRightZ = goalCFrame.R00, goalCFrame.R01, goalCFrame.R02
            local goalUpX, goalUpY, goalUpZ = goalCFrame.R10, goalCFrame.R11, goalCFrame.R12
            local goalLookX, goalLookY, goalLookZ = goalCFrame.R20, goalCFrame.R21, goalCFrame.R22
            
            local function matrixToQuaternion(rightX, rightY, rightZ, upX, upY, upZ, lookX, lookY, lookZ)
                local trace = rightX + upY + lookZ
                local quatW, quatX, quatY, quatZ
                
                if trace > 0 then
                    local scale = math.sqrt(trace + 1.0) * 2
                    quatW = 0.25 * scale
                    quatX = (upZ - lookY) / scale
                    quatY = (lookX - rightZ) / scale
                    quatZ = (rightY - upX) / scale
                elseif rightX > upY and rightX > lookZ then
                    local scale = math.sqrt(1.0 + rightX - upY - lookZ) * 2
                    quatW = (upZ - lookY) / scale
                    quatX = 0.25 * scale
                    quatY = (upX + rightY) / scale
                    quatZ = (lookX + rightZ) / scale
                elseif upY > lookZ then
                    local scale = math.sqrt(1.0 + upY - rightX - lookZ) * 2
                    quatW = (lookX - rightZ) / scale
                    quatX = (upX + rightY) / scale
                    quatY = 0.25 * scale
                    quatZ = (lookY + upZ) / scale
                else
                    local scale = math.sqrt(1.0 + lookZ - rightX - upY) * 2
                    quatW = (rightY - upX) / scale
                    quatX = (lookX + rightZ) / scale
                    quatY = (lookY + upZ) / scale
                    quatZ = 0.25 * scale
                end
                
                local quatLength = math.sqrt(quatX * quatX + quatY * quatY + quatZ * quatZ + quatW * quatW)
                return quatX / quatLength, quatY / quatLength, quatZ / quatLength, quatW / quatLength
            end
            
            local startQuatX, startQuatY, startQuatZ, startQuatW = matrixToQuaternion(startRightX, startRightY, startRightZ, startUpX, startUpY, startUpZ, startLookX, startLookY, startLookZ)
            local goalQuatX, goalQuatY, goalQuatZ, goalQuatW = matrixToQuaternion(goalRightX, goalRightY, goalRightZ, goalUpX, goalUpY, goalUpZ, goalLookX, goalLookY, goalLookZ)
            
            local dotProduct = startQuatX * goalQuatX + startQuatY * goalQuatY + startQuatZ * goalQuatZ + startQuatW * goalQuatW
            if dotProduct < 0 then
                goalQuatX, goalQuatY, goalQuatZ, goalQuatW = -goalQuatX, -goalQuatY, -goalQuatZ, -goalQuatW
                dotProduct = -dotProduct
            end
            
            local lerpedQuatX, lerpedQuatY, lerpedQuatZ, lerpedQuatW
            if dotProduct > 1 - 1e-6 then
                lerpedQuatX = startQuatX + (goalQuatX - startQuatX) * alpha
                lerpedQuatY = startQuatY + (goalQuatY - startQuatY) * alpha
                lerpedQuatZ = startQuatZ + (goalQuatZ - startQuatZ) * alpha
                lerpedQuatW = startQuatW + (goalQuatW - startQuatW) * alpha
                local quatLength = math.sqrt(lerpedQuatX * lerpedQuatX + lerpedQuatY * lerpedQuatY + lerpedQuatZ * lerpedQuatZ + lerpedQuatW * lerpedQuatW)
                lerpedQuatX, lerpedQuatY, lerpedQuatZ, lerpedQuatW = lerpedQuatX / quatLength, lerpedQuatY / quatLength, lerpedQuatZ / quatLength, lerpedQuatW / quatLength
            else
                local theta0 = math.acos(math.clamp(dotProduct, -1, 1))
                local sinTheta0 = math.sin(theta0)
                local theta = theta0 * alpha
                local sinTheta = math.sin(theta)
                local scale0 = math.cos(theta) - dotProduct * sinTheta / sinTheta0
                local scale1 = sinTheta / sinTheta0
                lerpedQuatX = scale0 * startQuatX + scale1 * goalQuatX
                lerpedQuatY = scale0 * startQuatY + scale1 * goalQuatY
                lerpedQuatZ = scale0 * startQuatZ + scale1 * goalQuatZ
                lerpedQuatW = scale0 * startQuatW + scale1 * goalQuatW
            end
            
            local quatLength = math.sqrt(lerpedQuatX * lerpedQuatX + lerpedQuatY * lerpedQuatY + lerpedQuatZ * lerpedQuatZ + lerpedQuatW * lerpedQuatW)
            lerpedQuatX, lerpedQuatY, lerpedQuatZ, lerpedQuatW = lerpedQuatX / quatLength, lerpedQuatY / quatLength, lerpedQuatZ / quatLength, lerpedQuatW / quatLength
            
            local xx, yy, zz = lerpedQuatX * lerpedQuatX, lerpedQuatY * lerpedQuatY, lerpedQuatZ * lerpedQuatZ
            local xy, xz, yz = lerpedQuatX * lerpedQuatY, lerpedQuatX * lerpedQuatZ, lerpedQuatY * lerpedQuatZ
            local wx, wy, wz = lerpedQuatW * lerpedQuatX, lerpedQuatW * lerpedQuatY, lerpedQuatW * lerpedQuatZ
            
            local resultRightX = 1 - 2 * (yy + zz)
            local resultRightY = 2 * (xy + wz)
            local resultRightZ = 2 * (xz - wy)
            local resultUpX = 2 * (xy - wz)
            local resultUpY = 1 - 2 * (xx + zz)
            local resultUpZ = 2 * (yz + wx)
            local resultLookX = 2 * (xz + wy)
            local resultLookY = 2 * (yz - wx)
            local resultLookZ = 1 - 2 * (xx + yy)
            
            return CFrame.new(lerpedPosX, lerpedPosY, lerpedPosZ, resultRightX, resultRightY, resultRightZ, resultUpX, resultUpY, resultUpZ, resultLookX, resultLookY, resultLookZ)
        end
    }
})

Instance.declare({
    class = {"Part", "MeshPart", "UnionOperation", "TrussPart", "Camera"},
    name = "Orthonormalize",
    callback = {
        method = function(self)  local currentCFrame = self.CFrame
            local posX, posY, posZ = currentCFrame.Position.X, currentCFrame.Position.Y, currentCFrame.Position.Z
            
            -- Use vector.create to make compatible vectors
            local xVecRaw = vector.create(currentCFrame.RightVector.X, currentCFrame.RightVector.Y, currentCFrame.RightVector.Z)
            local yVecRaw = vector.create(currentCFrame.UpVector.X, currentCFrame.UpVector.Y, currentCFrame.UpVector.Z)
            
            -- Use vector library functions
            local xAxis = vector.normalize(xVecRaw)
            local dotProduct = vector.dot(xAxis, yVecRaw)
            local yAxisRaw = yVecRaw - xAxis * dotProduct
            local yAxis = vector.normalize(yAxisRaw)
            local zAxis = vector.cross(xAxis, yAxis)
            
            -- Use .X, .Y, .Z (Uppercase) for vector library objects
            return CFrame.new(posX, posY, posZ, xAxis.X, yAxis.X, zAxis.X, xAxis.Y, yAxis.Y, zAxis.Y, xAxis.Z, yAxis.Z, zAxis.Z)
        end
    }
})


Instance.declare({
    class = CFrameClasses,
    name = "FuzzyEq",
    callback = {
        method = function(self, otherCFrame, epsilon)
            epsilon = epsilon or 1e-5
            local currentCFrame = self.CFrame
            local currentPosX, currentPosY, currentPosZ = currentCFrame.Position.x, currentCFrame.Position.y, currentCFrame.Position.z
            
            if math.abs(currentPosX - otherCFrame.X) > epsilon or 
               math.abs(currentPosY - otherCFrame.Y) > epsilon or 
               math.abs(currentPosZ - otherCFrame.Z) > epsilon then
                return false
            end
            
            return self:AngleBetween(otherCFrame) <= epsilon
        end
    }
})

Instance.declare({
    class = CFrameClasses,
    name = "AngleBetween",
    callback = {
        method = function(self, otherCFrame)
            local currentCFrame = self.CFrame
            local currentRightX, currentRightY, currentRightZ = currentCFrame.RightVector.x, currentCFrame.RightVector.y, currentCFrame.RightVector.z
            local currentUpX, currentUpY, currentUpZ = currentCFrame.UpVector.x, currentCFrame.UpVector.y, currentCFrame.UpVector.z
            local currentLookX, currentLookY, currentLookZ = -currentCFrame.LookVector.x, -currentCFrame.LookVector.y, -currentCFrame.LookVector.z
            
            local otherRightX, otherRightY, otherRightZ = otherCFrame.R00, otherCFrame.R01, otherCFrame.R02
            local otherUpX, otherUpY, otherUpZ = otherCFrame.R10, otherCFrame.R11, otherCFrame.R12
            local otherLookX, otherLookY, otherLookZ = otherCFrame.R20, otherCFrame.R21, otherCFrame.R22
            
            local dotRightX = currentRightX * otherRightX + currentUpX * otherUpX + currentLookX * otherLookX
            local dotUpY = currentRightY * otherRightY + currentUpY * otherUpY + currentLookY * otherLookY
            local dotLookZ = currentRightZ * otherRightZ + currentUpZ * otherUpZ + currentLookZ * otherLookZ
            
            return math.acos(math.clamp((dotRightX + dotUpY + dotLookZ - 1) * 0.5, -1, 1))
        end
    }
})
