--[[
TheNexusAvenger

Wraps a Roblox Instance to add additional
functionality.
--]]
--!strict

--Certain versions of Nexus Wrapped Instance have incompatibilities
--with other versions. Increment this number if a breaking change
--is made, such as Nexus Instance V.2.X.X to V.3.X.X.
local SINGLETON_COMPATIBILITY_VERSION = 2

local RunService = game:GetService("RunService")

local NexusInstance = require(script:WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))
local NexusEvent = require(script:WaitForChild("NexusInstance"):WaitForChild("Event"):WaitForChild("NexusEvent"))

local NexusWrappedInstance = NexusInstance:Extend()
NexusWrappedInstance:SetClassName("NexusWrappedInstance")
NexusWrappedInstance.CachedInstances = {}
setmetatable(NexusWrappedInstance.CachedInstances, {__mode = "v"})

export type NexusWrappedInstance = {
    new: (InstanceType: string | Instance) -> NexusWrappedInstance,
    Extend: (self: NexusWrappedInstance) -> NexusWrappedInstance,
    CreateGetInstance: (Class: NexusWrappedInstance) -> (),

    GetWrappedInstance: (self: NexusWrappedInstance) -> Instance,
    IgnoreWrapping: (self: NexusWrappedInstance, PropertyName: string) -> (),
    DisableChangeReplication: (self: NexusWrappedInstance, PropertyName: string) -> (),
    EnableChangeReplication: (self: NexusWrappedInstance, PropertyName: string) -> (),
    ConvertProperty: (self: NexusWrappedInstance, PropertyName: string, PropertyValue: any) -> any,
} & NexusInstance.NexusInstance & Instance



--[[
Wraps the instance or table.
--]]
local function WrapData(InstanceOrTable: any): any
    --Return the wrapped object.
    if typeof(InstanceOrTable) == "Instance" then
        return NexusWrappedInstance.GetInstance(InstanceOrTable)
    end

    --Change the table entries.
    if typeof(InstanceOrTable) == "table" and not InstanceOrTable.IsA then
        for Key,Value in InstanceOrTable do
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
local function UnwrapData(InstanceOrTable: any): any
    --Unwrap the table.
    if typeof(InstanceOrTable) == "table" then
        if InstanceOrTable.WrappedInstance then
            --Unwrap the instance.
            return InstanceOrTable.WrappedInstance
        else
            --Change the table entries.
            for Key,Value in InstanceOrTable do
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
function NexusWrappedInstance:CreateGetInstance(Class: NexusWrappedInstance)
    Class = Class or self
    Class.GetInstance = function(ExistingInstance: string | Instance): NexusWrappedInstance
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
function NexusWrappedInstance:__new(InstanceOrStringToWrap: string | Instance)
    if self.WrappedInstance then return end
    NexusInstance.__new(self)

    --Convert the instance to wrap if it is a string.
    local InstanceToWrap: Instance = nil
    if typeof(InstanceOrStringToWrap) == "string" then
        InstanceToWrap = Instance.new(InstanceOrStringToWrap :: any)
    else
        InstanceToWrap = InstanceOrStringToWrap :: Instance
    end
    
    --Store the value in the cache.
    local UnwrappedProperties = {
        WrappedInstance = true,
    }
    self.CachedInstances[InstanceToWrap] = self
    self.DisabledChangesReplication = {}
    self.EventsToDisconnect = {}
    self.UnwrappedProperties = UnwrappedProperties
    self.WrappedInstance = InstanceToWrap
    self:DisableChangeReplication("EventsToDisconnect")

    --Modify indexing to get instance properties.
    local OriginalIndexFunction = getmetatable(self).__index
    getmetatable(self).__index = function(MethodObject: any, Index: string): any
        --Return the object value if it exists.
        local BaseReturn = OriginalIndexFunction(MethodObject, Index)
        if UnwrappedProperties[Index] then
            return BaseReturn
        end
        if BaseReturn ~= nil or Index == "DisabledChangesReplication" or Index == "EventsToDisconnect" then
            return WrapData(BaseReturn)
        end

        --Return nil if the replication is disabled.
        local DisabledChangesReplication = self.DisabledChangesReplication
        if DisabledChangesReplication and DisabledChangesReplication[Index] then
            return nil
        end

        --Return the wrapped object's value.
        local WrappedInstance = self.WrappedInstance
        if WrappedInstance then
            local Value = WrappedInstance[Index]

            --Wrap the event.
            if typeof(Value) == "RBXScriptSignal" then
                --Create and store the event.
                local Event = NexusEvent.new()
                self:DisableChangeReplication(Index)
                self[Index] = Event
                table.insert(self.EventsToDisconnect, Event)

                --Connect the event.
                Value:Connect(function(...)
                    local TotalArguments = select("#", ...)
                    Event:Fire(table.unpack(WrapData({...}), 1, TotalArguments))
                end)

                --Return the event.
                return Event
            end

            --Wrap the function.
            if typeof(Value) == "function" then
                --Wrap the function.
                local function WrappedFunction(...)
                    --Unwrap the parameters for the call.
                    local TotalArguments = select("#", ...)
                    local UnwrappedArguments = UnwrapData(table.pack(...))

                    --Call and return the wrapped parameters.
                    return WrapData(Value(table.unpack(UnwrappedArguments, 1, TotalArguments)))
                end

                --Store and return the function.
                self:DisableChangeReplication(Index)
                self[Index] = WrappedFunction
                return WrappedFunction
            end

            --Return the wrapped data.
            return WrapData(Value)
        end

        --Return nil (default case for typing).
        return nil
    end

    --Set up the cyclic property changing blocking.
    --Done internally to reduce overhead.
    local PreviousChanges = {}
    local PreviousChangesClearQueued = false

    --[[
    Queues clearing the previous changes.
    --]]
    local function QueueClearingChanges(): ()
        --Return if clearing is already queued.
        if PreviousChangesClearQueued then
            return
        end

        --Clear the previous changes after the next step.
        --Done to prevent storing extra data in memory that would prevent garbage collection.
        PreviousChangesClearQueued = true
        task.spawn(function()
            RunService.Heartbeat:Wait()
            PreviousChanges = {}
            PreviousChangesClearQueued = false
        end)
    end

    --Connect replicating properties.
    self:AddGenericPropertyFinalizer(function(PropertyName: string, Value: any): ()
        --Return if the replication is disabled.
        if self.DisabledChangesReplication[PropertyName] then
            return
        end

        --Return if the value is the same as the previous change in the last step.
        if PreviousChanges[PropertyName] == Value then
            return
        end

        --Add the property to the list of changed values and queue clearing the list.
        --This prevents converted values from affecting the previous set, leading to a stack overflow from the events.
        local ConvertedValue = self:ConvertProperty(PropertyName,Value)
        PreviousChanges[PropertyName] = ConvertedValue
        QueueClearingChanges();

        --Replicate the change.
        (InstanceToWrap :: any)[PropertyName] = ConvertedValue
    end)
    InstanceToWrap.Changed:Connect(function(PropertyName: string): ()
        pcall(function()
            --Return if the replication is disabled.
            if self.DisabledChangesReplication[PropertyName] then
                return
            end

            --Read the new value.
            local NewValue = (InstanceToWrap :: any)[PropertyName]

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
    table.insert(self.EventsToDisconnect, AncestryChangedConnection)
end

--[[
Returns if the instance is or inherits from a class of that name.
--]]
function NexusWrappedInstance:IsA(ClassName: string): boolean
    return self:GetWrappedInstance():IsA(ClassName) or NexusInstance.IsA(self, ClassName)
end

--[[
Sets the Parent property to nil, locks the Parent
property, and calls Destroy on all children.
--]]
function NexusWrappedInstance:Destroy(): ()
    NexusInstance.Destroy(self)

    --Destroy the wrapped instance.
    local WrappedInstance = self:GetWrappedInstance()
    if WrappedInstance then
        WrappedInstance:Destroy()
    end

    --Disconnect the events.
    for _,Event in self.EventsToDisconnect do
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
Makes it so a property is never wrapped.
--]]
function NexusWrappedInstance:IgnoreWrapping(PropertYName: string): ()
    self.UnwrappedProperties[PropertYName] = true
end

--[[
Disables changes being replicated to the wrapped
instance for a specific property.
--]]
function NexusWrappedInstance:DisableChangeReplication(PropertyName: string): ()
    self.DisabledChangesReplication[PropertyName] = true
end

--[[
Enables changes being replicated to the wrapped
instance for a specific property.
--]]
function NexusWrappedInstance:EnableChangeReplication(PropertyName: string): ()
    self.DisabledChangesReplication[PropertyName] = nil
end

--[[
Converts a property for replicating to the
wrapped instance.
--]]
function NexusWrappedInstance:ConvertProperty(PropertyName: string, PropertyValue: any): any
    return UnwrapData(PropertyValue)
end



--In non-test environemnts, return a singleton version of the module.
--Multiple instances of Nexus Wrapped Instance can have unintended consequences with the state being distributed and inconsistent.
if _G.EnsureNexusWrappedInstanceSingleton ~= false then
    if not _G.NexusWrappedInstanceSingletonVersions then
        _G.NexusWrappedInstanceSingletonVersions = {}
    end
    if not _G.NexusWrappedInstanceSingletonVersions[SINGLETON_COMPATIBILITY_VERSION] then
        _G.NexusWrappedInstanceSingletonVersions[SINGLETON_COMPATIBILITY_VERSION] = NexusWrappedInstance
    end
    return _G.NexusWrappedInstanceSingletonVersions[SINGLETON_COMPATIBILITY_VERSION]
end
return (NexusWrappedInstance :: any) :: NexusWrappedInstance