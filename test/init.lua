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
    self:AssertEquals(typeof(self.CuT:GetWrappedInstance()),"Instance","Wrapped instance is not an instance.")
end))

--[[
Tests the IsA method.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("IsA"):SetRun(function(self)
    --Test on the base class.
    self:AssertTrue(self.CuT:IsA("BasePart"))
    self:AssertTrue(self.CuT:IsA("Part"))
    self:AssertTrue(self.CuT:IsA("NexusWrappedInstance"))
    self:AssertTrue(self.CuT:IsA("NexusInstance"))
    self:AssertFalse(self.CuT:IsA("Model"))

    --Test on an extended class.
    local TestClass = NexusWrappedInstance:Extend()
    TestClass:SetClassName("TestClass")
    function TestClass:__new()
        self:InitializeSuper("Part")
    end
    local CuT2 = TestClass.new()
    self:AssertTrue(CuT2:IsA("BasePart"))
    self:AssertTrue(CuT2:IsA("Part"))
    self:AssertTrue(CuT2:IsA("TestClass"))
    self:AssertTrue(CuT2:IsA("NexusWrappedInstance"))
    self:AssertTrue(CuT2:IsA("NexusInstance"))
    self:AssertFalse(CuT2:IsA("Model"))
    CuT2:Destroy()
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

--[[
Tests wrapping events.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("WrapEvents"):SetRun(function(self)
    --Connect the ChildAdded event.
    local EventCalls = {}
    local Connection = self.CuT.ChildAdded:Connect(function(Ins)
        table.insert(EventCalls,Ins)
    end)

    --Add test children.
    local TestMesh,TestDecal = Instance.new("SpecialMesh"),Instance.new("Decal")
    TestMesh.Parent = self.CuT:GetWrappedInstance()
    TestDecal.Parent = self.CuT:GetWrappedInstance()

    --Assert that the events were called correctly.
    self:AssertTrue(Connection.Connected,"Connection is not connected.")
    self:AssertNotNil(EventCalls[1],"Child added not called.")
    self:AssertEquals(EventCalls[1]:GetWrappedInstance(),TestMesh,"Wrong parameter returned.")
    self:AssertNotNil(EventCalls[2],"Child added not called.")
    self:AssertEquals(EventCalls[2]:GetWrappedInstance(),TestDecal,"Wrong parameter returned.")
    self:AssertNil(EventCalls[3],"Child added was called.")

    --Destroy the component under testing and assert the event is disconnected.
    self.CuT:Destroy()
    self:AssertFalse(Connection.Connected,"Connection is connected.")
end))

--[[
Tests wrapping functions.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("WrapFunctions"):SetRun(function(self)
    --Create and wrap 2 instances.
    local Mesh1,Mesh2 = Instance.new("SpecialMesh"),Instance.new("SpecialMesh")
    Mesh1.Name = "TestMesh"
    local WrappedMesh1,WrappedMesh2 = NexusWrappedInstance.new(Mesh1),NexusWrappedInstance.new(Mesh2)
    WrappedMesh1.Parent = self.CuT

    --Assert Instance methods are correct.
    self:AssertSame(self.CuT:FindFirstChild("TestMesh"),WrappedMesh1,"Wrong result returned.")
    self:AssertSame(self.CuT:FindFirstChild("TestMesh2"),nil,"Wrong result returned.")
    self:AssertSame(self.CuT:IsAncestorOf(WrappedMesh1),true,"Wrong result returned.")
    self:AssertSame(self.CuT:IsAncestorOf(WrappedMesh2),false,"Wrong result returned.")
end))

--[[
Tests destroying the children when ClearAllChildren is called.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("DestroyChildren"):SetRun(function(self)
    --Create and wrap 2 instances.
    local Mesh,Decal = Instance.new("SpecialMesh"),Instance.new("Decal")
    local WrappedMesh,WrappedDecal = NexusWrappedInstance.new(Mesh),NexusWrappedInstance.new(Decal)
    WrappedMesh.Parent = self.CuT
    WrappedDecal.Parent = self.CuT

    --Create the connections.
    local Connection1 = self.CuT.ChildAdded:Connect(function() end)
    local Connection2 = self.CuT.ChildAdded:Connect(function() end)
    local Connection3 = self.CuT.ChildAdded:Connect(function() end)

    --Destroy the parent.
    self.CuT:Destroy()
    wait()

    --Assert the connections were destroyed.
    self:AssertFalse(Connection1.Connected,"Connection was not disconnected.")
    self:AssertFalse(Connection2.Connected,"Connection was not disconnected.")
    self:AssertFalse(Connection3.Connected,"Connection was not disconnected.")
end))

--[[
Tests the Changed event.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("Changed"):SetRun(function(self)
    --Connect the events.
    local ChangeEventCalls = {}
    local SignalCalls = {}
    self.CuT.Changed:Connect(function(Property)
        table.insert(ChangeEventCalls,Property)
    end)
    self.CuT:GetPropertyChangedSignal("Name"):Connect(function()
        table.insert(SignalCalls,"Name")
    end)
    self.CuT:GetPropertyChangedSignal("Anchored"):Connect(function()
        table.insert(SignalCalls,"Anchored")
    end)

    --Change the name of the instance and assert the changed events are correct.
    self.CuT.Name = "Test1"
    self:AssertEquals(ChangeEventCalls,{"Name"},"Changed calls are incorrect.")
    self:AssertEquals(SignalCalls,{"Name"},"GetPropertyChangedSignal calls are incorrect.")

    --Change the name of the wrapped instance and assert the changed events are correct.
    self.CuT.WrappedInstance.Name = "Test2"
    self:AssertEquals(ChangeEventCalls,{"Name","Name"},"Changed calls are incorrect.")
    self:AssertEquals(SignalCalls,{"Name","Name"},"GetPropertyChangedSignal calls are incorrect.")

    --Change the anchored property of the wrapped instance and assert the changed events are correct.
    self.CuT.WrappedInstance.Anchored = true
    self:AssertEquals(ChangeEventCalls,{"Name","Name","Anchored"},"Changed calls are incorrect.")
    self:AssertEquals(SignalCalls,{"Name","Name","Anchored"},"GetPropertyChangedSignal calls are incorrect.")

    --Change the locked property of the wrapped instance and assert the changed events are correct.
    self.CuT.WrappedInstance.Locked = true
    self:AssertEquals(ChangeEventCalls,{"Name","Name","Anchored","Locked"},"Changed calls are incorrect.")
    self:AssertEquals(SignalCalls,{"Name","Name","Anchored"},"GetPropertyChangedSignal calls are incorrect.")

    --Change a property to the same value and assert that the event calls didn't change.
    self.CuT.Name = "Test2"
    self.CuT.WrappedInstance.Locked = true
    self:AssertEquals(ChangeEventCalls,{"Name","Name","Anchored","Locked"},"Changed calls are incorrect.")
    self:AssertEquals(SignalCalls,{"Name","Name","Anchored"},"GetPropertyChangedSignal calls are incorrect.")
end))

--[[
Tests reading non-existent properties.
--]]
NexusUnitTesting:RegisterUnitTest(NexusWrappedInstanceTest.new("ReadNonExistentProperty"):SetRun(function(self)
    self:AssertErrors(function()
        local Temp = self.CuT.BadProperty
    end)
end))



return true