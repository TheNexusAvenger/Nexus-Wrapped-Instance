--[[
TheNexusAvenger

Wraps a Roblox Instance to add additional
functionality.
--]]

local RunService = game:GetService("RunService")

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
Unwraps the instance or table.
--]]
local function UnwrapData(InstanceOrTable)
    --Unwrap the table.
    if typeof(InstanceOrTable) == "table" then
        if InstanceOrTable.WrappedInstance then
            --Unwrap the instance.
            return InstanceOrTable.WrappedInstance
        else
            --Change the table entries.
            for Key,Value in pairs(InstanceOrTable) do
                if typeof(Value) == "table" then
                    InstanceOrTable[Key] = UnwrapData(Value)
                end
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
    self.CachedInstances[InstanceToWrap] = self
    self.DisabledChangesReplication = {}
    self.WrappedInstance = InstanceToWrap

    --Set up the cyclic property changing blocking.
    --Done internally to reduce overhead.
    local PreviousChanges = {}
    local PreviousChangesClearQueued = false

    --[[
    Queues clearing the previous changes.
    --]]
    local function QueueClearingChanges()
        --Return if clearing is already queued.
        if PreviousChangesClearQueued then
            return
        end

        --Clear the previous changes after the next step.
        --Done to prevent storing extra data in memory that would prevent garbage collection.
        PreviousChangesClearQueued = true
        coroutine.wrap(function()
            RunService.Stepped:Wait()
            PreviousChanges = {}
            PreviousChangesClearQueued = false
        end)()
    end

    --Connect replicating properties.
    self.Changed:Connect(function(PropertyName)
        --Return if the replication is disabled.
        if self.DisabledChangesReplication[PropertyName] then
            return
        end

        --Return if the value is the same as the previous change in the last step.
        local Value = self[PropertyName]
        if PreviousChanges[PropertyName] == Value then
            return
        end

        --Add the property to the list of changed values and queue clearing the list.
        --This prevents converted values from affecting the previous set, leading to a stack overflow from the events.
        local ConvertedValue = self.object:ConvertProperty(PropertyName,Value)
        PreviousChanges[PropertyName] = ConvertedValue
        QueueClearingChanges()

        --Replicate the change.
        InstanceToWrap[PropertyName] = ConvertedValue
    end)
    InstanceToWrap.Changed:Connect(function(PropertyName)
        pcall(function()
            --Read the new value.
            local NewValue = InstanceToWrap[PropertyName]

            --Return if the value is the same as the previous change in the last step.
            if PreviousChanges[PropertyName] == NewValue then
                return
            end

             --Add the property to the list of changed values and queue clearing the list.
            --This prevents converted values from affecting the previous set, leading to a stack overflow from the events.
            PreviousChanges[PropertyName] = NewValue
            QueueClearingChanges()

            --Change the property.
            if self[PropertyName] ~= nil then
                self[PropertyName] = NewValue
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
        local BaseReturn = BaseIndexMethod(MethodObject,Index)
        if BaseReturn ~= nil or Index == "WrappedInstance" or Index == "DisabledChangesReplication" or Index == "super" then
            return WrapData(BaseReturn)
        end

        --Return nil if the replication is disabled.
        local DisabledChangesReplication = Object.DisabledChangesReplication
        if DisabledChangesReplication and DisabledChangesReplication[Index] then
            return nil
        end

        --Return the wrapped object's value.
        local WrappedInstance = Object.WrappedInstance
        if WrappedInstance then
            return WrapData(WrappedInstance[Index])
        end
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

--[[
Disables changes being replicated to the wrapped
instance for a specific property.
--]]
function NexusWrappedInstance:DisableChangeReplication(PropertyName)
    self.DisabledChangesReplication[PropertyName] = true
end

--[[
Enables changes being replicated to the wrapped
instance for a specific property.
--]]
function NexusWrappedInstance:EnableChangeReplication(PropertyName)
    self.DisabledChangesReplication[PropertyName] = nil
end

--[[
Converts a property for replicating to the
wrapped instance.
--]]
function NexusWrappedInstance:ConvertProperty(PropertyName,PropertyValue)
    return UnwrapData(PropertyValue)
end



return NexusWrappedInstance