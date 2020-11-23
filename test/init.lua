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

--[[
Tests the DisableChangeReplication method.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("DisableChangeReplication"):SetRun(function(self)
    --Assert disabled changes aren't replicated.
    self.CuT:DisableChangeReplication("Name")
    self.CuT.Name = "TestName1"
    self:AssertEquals(self.CuT.Name,"TestName1","Name is incorrect.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"Part","Name was replicated.")

    --Assert an undisabled change is replicated.
    self.CuT.Anchored = true
    self:AssertTrue(self.CuT.Anchored,"Anchored is incorrect.")
    self:AssertTrue(self.CuT.WrappedInstance.Anchored,"Anchored not replicated.")

    --Assert an enabled change is replicated.
    self.CuT:EnableChangeReplication("Name")
    self.CuT.Name = "TestName2"
    self:AssertEquals(self.CuT.Name,"TestName2","Name is incorrect.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName2","Name not replicated.")

    --Assert disabled changes aren't fetched from the wrapped instance
    self.CuT:DisableChangeReplication("UnknownProperty")
    self:AssertEquals(self.CuT.UnknownProperty,nil,"Value is incorrect.")
    self.CuT.UnknownProperty = "TestValue"
    self:AssertEquals(self.CuT.UnknownProperty,"TestValue","Value is incorrect.")
end))

--[[
Tests the ConvertProperty method.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("ConvertProperty"):SetRun(function(self)
    self:AssertEquals(self.CuT:ConvertProperty("Test","Test"),"Test","Value was changed.")
    self:AssertEquals(self.CuT:ConvertProperty("Test",false),false,"Value was changed.")
    self:AssertEquals(self.CuT:ConvertProperty("Test",self.CuT),self.CuT:GetWrappedInstance(),"Value wasn't unwrapped correctly.")
    self:AssertEquals(self.CuT:ConvertProperty("Test",{self.CuT,self.CuT,{self.CuT,self.CuT}}),{self.CuT:GetWrappedInstance(),self.CuT:GetWrappedInstance(),{self.CuT:GetWrappedInstance(),self.CuT:GetWrappedInstance()}},"Value wasn't unwrapped correctly.")
end))

--[[
Tests indexing the instance.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("ObjectIndexing"):SetRun(function(self)
    local Mesh = Instance.new("SpecialMesh")
    Mesh.Name = "Mesh"
    Mesh.Parent = self.CuT.WrappedInstance
    self:AssertEquals(self.CuT.Name,"Part","Name is incorrect.")
    self:AssertEquals(self.CuT.Mesh.Name,"Mesh","Child name is incorrect.")
    self:AssertEquals(self.CuT.Parent,nil,"Nil property is incorrect.")
    self:AssertEquals(self.CuT.ClassName,"NexusWrappedInstance","Class name (class property) is incorrect.")
    self:AssertTrue(self.CuT.Mesh:IsA("NexusWrappedInstance"),"Child isn't wrapped.")
    self:AssertTrue(self.CuT.Mesh:IsA("SpecialMesh"),"Child isn't wrapped.")
end))

--[[
Tests replicating changes to the wrapped object.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("ToWrapppedObjectReplication"):SetRun(function(self)
    self.CuT.Name = "TestName"
    self:AssertEquals(self.CuT.Name,"TestName","Name is incorrect.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName","Name not replicated.")
    self.CuT.Anchored = true
    self:AssertTrue(self.CuT.Anchored,"Anchored is incorrect.")
    self:AssertTrue(self.CuT.WrappedInstance.Anchored,"Anchored not replicated.")
end))

--[[
Tests replicating changes to the wrapped object.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("FromWrapppedObjectReplication"):SetRun(function(self)
    self.CuT.Name = "TestName1"
    self:AssertEquals(self.CuT.Name,"TestName1","Name is incorrect.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName1","Name not replicated.")
    self.CuT.WrappedInstance.Name = "TestName2"
    self:AssertEquals(self.CuT.Name,"TestName2","Name not replicated.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName2","Name is incorrect.")
end))

--[[
Tests replicating changes with converted properties.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("ConvertedWrapppedObjectReplication"):SetRun(function(self)
    --Add a custom converter for the name.
    self.CuT:DisableChangeReplication("ConvertProperty")
    function self.CuT:ConvertProperty(PropertyName,PropertyValue)
        if PropertyName == "Name" then
            return PropertyValue.."_2"
        else
            return NexusWrappedInstance.ConvertProperty(self.CuT,PropertyName,PropertyValue)
        end
    end

    --Change the name of the instance and assert it is correct.
    self.CuT.Name = "TestName1"
    self:AssertEquals(self.CuT.Name,"TestName1","Name is incorrect.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName1_2","Name not replicated.")

    --Change the name of the wrapped instance and assert it is correct.
    self.CuT.WrappedInstance.Name = "TestName2"
    self:AssertEquals(self.CuT.Name,"TestName2","Name not replicated.")
    self:AssertEquals(self.CuT.WrappedInstance.Name,"TestName2","Name was changed.")
end))



return true