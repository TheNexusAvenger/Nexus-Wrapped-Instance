--[[
TheNexusAvenger

Wraps a Roblox Instance to add additional
functionality.
--]]

local NexusInstance = require(script:WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))

local NexusWrappedInstance = NexusInstance:Extend()
NexusWrappedInstance:SetClassName("NexusWrappedInstance")
NexusWrappedInstance.CachedInstances = {}
setmetatable(NexusWrappedInstance.CachedInstances,{__mode="v"})



--[[
Wraps the instance or table.
--]]
local function WrapData(InstanceOrTable)
    --Return the wrapped object.
    if typeof(InstanceOrTable) == "Instance" then
        return NexusWrappedInstance.GetInstance(InstanceOrTable)
    end

    --Change the table entries.
    if typeof(InstanceOrTable) == "table" and not InstanceOrTable.IsA then
        for Key,Value in pairs(InstanceOrTable) do
            if typeof(Value) == "Instance" or typeof(Value) == "table" then
                InstanceOrTable[Key] = WrapData(Value)
            end
        end
    end

    --Return the base value.
    return InstanceOrTable
end



--[[
Gets a Nexus Wrapped Instance.
--]]
function NexusWrappedInstance.GetInstance(ExistingInstance)
	--Create the string instance or create the cached instance if needed.
	local CachedInstance = NexusWrappedInstance.CachedInstances[ExistingInstance]
	if typeof(ExistingInstance) == "string" then
		CachedInstance = NexusWrappedInstance.new(ExistingInstance)
	else
		if not CachedInstance then
			CachedInstance = NexusWrappedInstance.new(ExistingInstance)
		end
	end
	
	--Return the cached entry.
	return CachedInstance
end

--[[
Creates a Nexus Wrapped Instance object.
--]]
function NexusWrappedInstance:__new(InstanceToWrap)
    self:InitializeSuper()

    --Convert the instance to wrap if it is a string.
    if typeof(InstanceToWrap) == "string" then
		InstanceToWrap = Instance.new(tostring(InstanceToWrap))
    end
    
    --Store the value in the cache.
    self.WrappedInstance = InstanceToWrap
    self.CachedInstances[InstanceToWrap] = self

    --Connect replicating properties.
    self.Changed:Connect(function(PropertyName)
        pcall(function()
            InstanceToWrap[PropertyName] = self[PropertyName]
        end)
    end)
    InstanceToWrap.Changed:Connect(function(PropertyName)
        pcall(function()
            if self[PropertyName] ~= nil then
                self[PropertyName] = InstanceToWrap[PropertyName]
            end
        end)
    end)
end

--[[
Creates an __index metamethod for an object. Used to
setup custom indexing.
--]]
function NexusWrappedInstance:__createindexmethod(Object,Class,RootClass)
	--Get the base method.
	local BaseIndexMethod = self.super:__createindexmethod(Object,Class,RootClass)
	
	--Return a wrapped method.
    return function(MethodObject,Index)
        --Return the object value if it exists.
        --TODO: Add ability to set "nillable".
        local BaseReturn = BaseIndexMethod(MethodObject,Index)
        if BaseReturn ~= nil or Index == "WrappedInstance" or Index == "super" then
            return WrapData(BaseReturn)
        end

        --Return the wrapped object's value.
        return WrapData(Object.WrappedInstance[Index])
	end
end

--[[
Returns if the instance is or inherits from a class of that name.
--]]
function NexusWrappedInstance:IsA(ClassName)
	return self.ClassName == ClassName or self.super:IsA(ClassName) or self:GetWrappedInstance():IsA(ClassName)
end

--[[
Sets the Parent property to nil, locks the Parent
property, and calls Destroy on all children.
--]]
function NexusWrappedInstance:Destroy()
	self.super:Destroy()
    
    --Destroy the wrapped instance.
	local WrappedInstance = self:GetWrappedInstance()
	if WrappedInstance then
		WrappedInstance:Destroy()
    end
    
    --Disconnect the events.
end

--[[
Returns the wrapped instance.
--]]
function NexusWrappedInstance:GetWrappedInstance()
	return self.WrappedInstance
end



return NexusWrappedInstance