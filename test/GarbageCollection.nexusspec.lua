--[[
TheNexusAvenger

Tests garbage collection of the NexusWrappedInstance class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local NexusWrappedInstanceTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function NexusWrappedInstanceTest:Setup()
    --Create the instances but don't store them to allow them to garbage collect.
    for _ = 1,10 do
        NexusWrappedInstance.new("Part"):Destroy()
    end
end

--[[
Tests instances being garbage collected.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("GarbageCollection"):SetRun(function(self)
    --Determine how many instances are stored and break if 0 is reached.
    local CachedInstances = 10
    for _ = 1,120 * 10 do
        CachedInstances = 0
        for _,_ in pairs(NexusWrappedInstance.CachedInstances) do
            CachedInstances = CachedInstances + 1
        end
        if CachedInstances == 0 then break end
        wait(0.1)
    end

    --Assert that the instances are garbage collected.
    self:AssertEquals(CachedInstances,0,"Not all instances were garbage collected.")
end))



return true