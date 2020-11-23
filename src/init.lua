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
    
    --Store the value.
    self.WrappedInstance = InstanceToWrap
    self.CachedInstances[InstanceToWrap] = self
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