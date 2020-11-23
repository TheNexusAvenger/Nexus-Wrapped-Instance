--[[
TheNexusAvenger

Tests for NexusWrappedInstance.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local NexusWrappedInstanceTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function NexusWrappedInstanceTest:Setup()
    self.CuT = NexusWrappedInstance.new("Part")
end

--[[
Tears down the test.
--]]
function NexusWrappedInstanceTest:Teardown()
    if self.CuT then
        self.CuT:Destroy()
    end
end

--[[
Tests the GetInstance method.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("GetInstance"):SetRun(function(self)
    self:AssertNotSame(self.CuT,NexusWrappedInstance.new("Part"),"Different instances are the same.")
    self:AssertNotSame(self.CuT,NexusWrappedInstance.GetInstance("Part"),"Different instances are the same.")
    self:AssertSame(self.CuT,NexusWrappedInstance.GetInstance(self.CuT:GetWrappedInstance()),"Incorrect cache entry fetched.")
end))

--[[
Tests the IsA method.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("IsA"):SetRun(function(self)
    self:AssertTrue(self.CuT:IsA("BasePart"))
    self:AssertTrue(self.CuT:IsA("Part"))
    self:AssertTrue(self.CuT:IsA("NexusWrappedInstance"))
    self:AssertTrue(self.CuT:IsA("NexusInstance"))
    self:AssertFalse(self.CuT:IsA("Model"))
end))



return true