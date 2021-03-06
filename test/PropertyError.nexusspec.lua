--[[
TheNexusAvenger

Tests property errors of the NexusWrappedInstance class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local NexusInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"):WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))
local NexusWrappedInstanceTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function NexusWrappedInstanceTest:Setup()
    --Create the instances but don't store them to allow them to garbage collect.
    local TestClass = NexusInstance:Extend()
    function TestClass:__new()
        self:InitializeSuper()
        self.AncestryChanged = {
            Connect = function()
                
            end
        }
    end
    function TestClass:__createindexmethod(Object,Class,RootClass)
        local BaseIndexMethod = self.super:__createindexmethod(Object,Class,RootClass)
        return function(MethodObject,Index)
            if Index == "BadProperty" then
                error("Mock lack of permission error.")
            else
                return BaseIndexMethod(MethodObject,Index)
            end
        end
    end

    --Create the component under testing.
    self.CuT = NexusWrappedInstance.new(TestClass.new())
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
Tests instances with errors reading properties
with changed events.
Note: This may be a manual test by checking for errors.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("PropertyReadError"):SetRun(function(self)
    --Send a changed event for a bad property.
    self.CuT.WrappedInstance.Changed:Fire("BadProperty")

    --Set the name and assert that it changed.
    self.CuT.Name = "TestName"
    self:AssertEquals(self.CuT.Name,"TestName","Name is incorrect.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName","Name not replicated.")
end))



return true