--[[
TheNexusAvenger

Wraps a Roblox Instance to add additional
functionality.
--]]

local RunService = game:GetService("RunService")

local NexusInstance = require(script:WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))
local NexusEventCreator = require(script:WaitForChild("NexusInstance"):WaitForChild("Event"):WaitForChild("NexusEventCreator"))

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
Creates a GetInstance method for the class. Should be
called staticly (right after NexusObject::Extend).
--]]
function NexusWrappedInstance:CreateGetInstance(Class)
    Class = Class or self
	Class.GetInstance = function(ExistingInstance)
        --Create the string instance or create the cached instance if needed.
        local CachedInstance = NexusWrappedInstance.CachedInstances[ExistingInstance]
        if typeof(ExistingInstance) == "string" then
            CachedInstance = Class.new(ExistingInstance)
        else
            if not CachedInstance then
                CachedInstance = Class.new(ExistingInstance)
            end
        end
        
        --Return the cached entry.
        return CachedInstance
    end
end
NexusWrappedInstance:CreateGetInstance(NexusWrappedInstance)

--[[
Creates a Nexus Wrapped Instance object.
--]]
function NexusWrappedInstance:__new(InstanceToWrap)
    if self.WrappedInstance then return end
    self:InitializeSuper()

    --Convert the instance to wrap if it is a string.
    if typeof(InstanceToWrap) == "string" then
		InstanceToWrap = Instance.new(tostring(InstanceToWrap))
    end
    
    --Store the value in the cache.
    self.CachedInstances[InstanceToWrap] = self.object
    self.DisabledChangesReplication = {}
    self.EventsToDisconnect = {}
    self.WrappedInstance = InstanceToWrap
    self:DisableChangeReplication("EventsToDisconnect")

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
            RunService.Heartbeat:Wait()
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
            local ExistingValue = self[PropertyName]
            if ExistingValue ~= nil and ExistingValue ~= NewValue then
                self[PropertyName] = NewValue
            else
                self.Changed:Fire(PropertyName)
                self:GetPropertyChangedSignal(PropertyName):Fire()
            end
        end)
    end)

    --Connect the instance being destroyed.
    --Mainly used if ClearAllChildren is called and Destroy isn't explicitly called.
    --Workaround by Corecii.
    local AncestryChangedConnection
    AncestryChangedConnection = InstanceToWrap.AncestryChanged:Connect(function()
        RunService.Heartbeat:Wait()
        if not AncestryChangedConnection.Connected then
            self:Destroy()
        end
    end)
    table.insert(self.EventsToDisconnect,AncestryChangedConnection)
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
        if Index == "WrappedInstance" then
            return BaseReturn
        end
        if BaseReturn ~= nil or Index == "DisabledChangesReplication" or Index == "EventsToDisconnect" or Index == "super" then
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
            local Value = WrappedInstance[Index]

            --Wrap the event.
            if typeof(Value) == "RBXScriptSignal" then
                --Create and store the event.
                local Event = NexusEventCreator:CreateEvent()
                Object:DisableChangeReplication(Index)
                Object[Index] = Event
                table.insert(Object.EventsToDisconnect,Event)

                --Connect the event.
                Value:Connect(function(...)
                    local TotalArguments = select("#",...)
                    Event:Fire(unpack(WrapData({...}),1,TotalArguments))
                end)

                --Return the event.
                return Event
            end

            --Wrap the function.
            if typeof(Value) == "function" then
                --Wrap the function.
                local function WrappedFunction(...)
                    --Unwrap the parameters for the call.
                    local TotalArguments = select("#",...)
                    local UnwrappedArguments = UnwrapData({...})

                    --Call and return the wrapped parameters.
                    return WrapData(Value(unpack(UnwrappedArguments,1,TotalArguments)))
                end

                --Store and return the function.
                Object:DisableChangeReplication(Index)
                Object[Index] = WrappedFunction
                return WrappedFunction
            end

            --Return the wrapped data.
            return WrapData(Value)
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
    for _,Event in pairs(self.EventsToDisconnect) do
        Event:Disconnect()
    end
    self.EventsToDisconnect = {}
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