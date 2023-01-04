--[[
TheNexusAvenger

Tests for NexusWrappedInstance.
--]]
--!strict

local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local NexusInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"):WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))

return function()
    describe("A wrapped instance of Part", function()
        local WrappedPart: NexusWrappedInstance.NexusWrappedInstance = nil
        beforeEach(function()
            WrappedPart = NexusWrappedInstance.new("Part")
        end)
        afterEach(function()
            WrappedPart:Destroy()
        end)

        it("should cache using GetInstance", function()
            expect(NexusWrappedInstance.new("Part")).to.never.equal(WrappedPart)
            expect(NexusWrappedInstance.GetInstance("Part")).to.never.equal(WrappedPart)
            expect(NexusWrappedInstance.GetInstance(WrappedPart:GetWrappedInstance())).to.equal(WrappedPart)
        end)

        it("should return the base instance.", function()
            expect(typeof(WrappedPart:GetWrappedInstance())).to.equal("Instance")
        end)

        it("should return the correct IsA values.", function()
            expect(WrappedPart:IsA("BasePart")).to.equal(true)
            expect(WrappedPart:IsA("Part")).to.equal(true)
            expect(WrappedPart:IsA("NexusWrappedInstance")).to.equal(true)
            expect(WrappedPart:IsA("NexusInstance")).to.equal(true)
            expect(WrappedPart:IsA("Model")).to.equal(false)
        end)

        it("should disable change replication.", function()
            --Assert disabled changes aren't replicated.
            WrappedPart:DisableChangeReplication("Name")
            WrappedPart.Name = "TestName1"
            expect(WrappedPart.Name).to.equal("TestName1")
            expect(WrappedPart.WrappedInstance.Name).to.equal("Part")

            --Assert an undisabled change is replicated.
            WrappedPart.Anchored = true
            expect(WrappedPart.Anchored).to.equal(true)
            expect(WrappedPart.WrappedInstance.Anchored).to.equal(true)

            --Assert an enabled change is replicated.
            WrappedPart:EnableChangeReplication("Name")
            WrappedPart.Name = "TestName2"
            expect(WrappedPart.Name).to.equal("TestName2")
            expect(WrappedPart.WrappedInstance.Name).to.equal("TestName2")

            --Assert disabled changes aren't fetched from the wrapped instance
            WrappedPart:DisableChangeReplication("UnknownProperty")
            expect(WrappedPart.UnknownProperty).to.equal(nil)
            WrappedPart.UnknownProperty = "TestValue"
            expect(WrappedPart.UnknownProperty).to.equal("TestValue")
        end)

        it("should convert properties.", function()
            expect(WrappedPart:ConvertProperty("Test", "Test")).to.equal("Test")
            expect(WrappedPart:ConvertProperty("Test", false)).to.equal(false)
            expect(WrappedPart:ConvertProperty("Test", WrappedPart)).to.equal(WrappedPart:GetWrappedInstance())

            local WrappedTable = WrappedPart:ConvertProperty("Test", {WrappedPart, WrappedPart, {WrappedPart, WrappedPart}} :: {any})
            expect(WrappedTable[1]).to.equal(WrappedPart:GetWrappedInstance())
            expect(WrappedTable[2]).to.equal(WrappedPart:GetWrappedInstance())
            expect(WrappedTable[3][1]).to.equal(WrappedPart:GetWrappedInstance())
            expect(WrappedTable[3][1]).to.equal(WrappedPart:GetWrappedInstance())
        end)

        it("should index correctly.", function()
            local Mesh = Instance.new("SpecialMesh")
            Mesh.Name = "Mesh"
            Mesh.Parent = WrappedPart.WrappedInstance

            expect(WrappedPart.Name).to.equal("Part")
            expect(WrappedPart.Mesh.Name).to.equal("Mesh")
            expect(WrappedPart.Parent).to.equal(nil)
            expect(WrappedPart.ClassName).to.equal("NexusWrappedInstance")
            expect(WrappedPart.Mesh:IsA("NexusWrappedInstance")).to.equal(true)
            expect(WrappedPart.Mesh:IsA("SpecialMesh")).to.equal(true)
        end)

        it("should replicate changes to the wrapped instance.", function()
            WrappedPart.Name = "TestName"
            expect(WrappedPart.Name).to.equal("TestName")
            expect(WrappedPart.WrappedInstance.Name).to.equal("TestName")
            WrappedPart.Anchored = true
            expect(WrappedPart.Anchored).to.equal(true)
            expect(WrappedPart.WrappedInstance.Anchored).to.equal(true)
        end)

        it("should replicate from the wrapped instance.", function()
            WrappedPart.Name = "TestName1"
            expect(WrappedPart.Name).to.equal("TestName1")
            expect(WrappedPart.WrappedInstance.Name).to.equal("TestName1")
            WrappedPart.WrappedInstance.Name = "TestName2"
            task.wait()
            expect(WrappedPart.Name).to.equal("TestName2")
            expect(WrappedPart.WrappedInstance.Name).to.equal("TestName2")
        end)

        it("should replicate changes to the wrapped instances with converted properties.", function()
            --Add a custom converter for the name.
            WrappedPart:DisableChangeReplication("ConvertProperty")
            function WrappedPart:ConvertProperty(PropertyName, PropertyValue)
                if PropertyName == "Name" then
                    return PropertyValue.."_2"
                else
                    return NexusWrappedInstance.ConvertProperty(WrappedPart, PropertyName, PropertyValue)
                end
            end

            --Change the name of the instance and assert it is correct.
            WrappedPart.Name = "TestName1"
            expect(WrappedPart.Name).to.equal("TestName1")
            expect(WrappedPart.WrappedInstance.Name).to.equal("TestName1_2")

            --Change the name of the wrapped instance and assert it is correct.
            WrappedPart.WrappedInstance.Name = "TestName2"
            task.wait()
            expect(WrappedPart.Name).to.equal("TestName2")
            expect(WrappedPart.WrappedInstance.Name).to.equal("TestName2")
        end)

        it("should wrap events.", function()
            --Connect the ChildAdded event.
            local EventCalls = {}
            local Connection = WrappedPart.ChildAdded:Connect(function(Ins)
                table.insert(EventCalls, Ins)
            end)

            --Add test children.
            local TestMesh,TestDecal = Instance.new("SpecialMesh"), Instance.new("Decal")
            TestMesh.Parent = WrappedPart:GetWrappedInstance()
            TestDecal.Parent = WrappedPart:GetWrappedInstance()
            task.wait()

            --Assert that the events were called correctly.
            expect(Connection.Connected).to.equal(true)
            expect(EventCalls[1]:GetWrappedInstance()).to.equal(TestMesh)
            expect(EventCalls[2]:GetWrappedInstance()).to.equal(TestDecal)
            expect(EventCalls[3]).to.equal(nil)

            --Destroy the component under testing and assert the event is disconnected.
            WrappedPart:Destroy()
            expect(Connection.Connected).to.equal(false)
        end)

        it("should wrap functions.", function()
            --Create and wrap 2 instances.
            local Mesh1, Mesh2 = Instance.new("SpecialMesh"), Instance.new("SpecialMesh")
            Mesh1.Name = "TestMesh"
            local WrappedMesh1, WrappedMesh2 = NexusWrappedInstance.new(Mesh1), NexusWrappedInstance.new(Mesh2)
            WrappedMesh1.Parent = WrappedPart

            --Assert Instance methods are correct.
            expect(WrappedPart:FindFirstChild("TestMesh")).to.equal(WrappedMesh1)
            expect(WrappedPart:FindFirstChild("TestMesh2")).to.equal(nil)
            expect(WrappedPart:IsAncestorOf(WrappedMesh1)).to.equal(true)
            expect(WrappedPart:IsAncestorOf(WrappedMesh2)).to.equal(false)
        end)

        it("should destroy children.", function()
            --Create and wrap 2 instances.
            local Mesh,Decal = Instance.new("SpecialMesh"), Instance.new("Decal")
            local WrappedMesh,WrappedDecal = NexusWrappedInstance.new(Mesh), NexusWrappedInstance.new(Decal)
            WrappedMesh.Parent = WrappedPart
            WrappedDecal.Parent = WrappedPart

            --Create the connections.
            local Connection1 = WrappedPart.ChildAdded:Connect(function() end)
            local Connection2 = WrappedPart.ChildAdded:Connect(function() end)
            local Connection3 = WrappedPart.ChildAdded:Connect(function() end)

            --Destroy the parent.
            WrappedPart:Destroy()
            task.wait()

            --Assert the connections were destroyed.
            expect(Connection1.Connected).to.equal(false)
            expect(Connection2.Connected).to.equal(false)
            expect(Connection3.Connected).to.equal(false)
        end)

        it("should fire the Changed event.", function()
            --Connect the events.
            local ChangeEventCalls = {}
            local SignalCalls = {}
            WrappedPart.Changed:Connect(function(Property)
                table.insert(ChangeEventCalls, Property)
            end)
            WrappedPart:GetPropertyChangedSignal("Name"):Connect(function()
                table.insert(SignalCalls, "Name")
            end)
            WrappedPart:GetPropertyChangedSignal("Anchored"):Connect(function()
                table.insert(SignalCalls, "Anchored")
            end)

            --Change the name of the instance and assert the changed events are correct.
            WrappedPart.Name = "Test1"
            task.wait()
            expect(ChangeEventCalls[1]).to.equal("Name")
            expect(SignalCalls[1]).to.equal("Name")

            --Change the name of the wrapped instance and assert the changed events are correct.
            WrappedPart.WrappedInstance.Name = "Test2"
            task. wait()
            expect(ChangeEventCalls[2]).to.equal("Name")
            expect(SignalCalls[2]).to.equal("Name")

            --Change the anchored property of the wrapped instance and assert the changed events are correct.
            WrappedPart.WrappedInstance.Anchored = true
            task.wait()
            expect(ChangeEventCalls[3]).to.equal("Anchored")
            expect(SignalCalls[3]).to.equal("Anchored")
            
            --Change the locked property of the wrapped instance and assert the changed events are correct.
            WrappedPart.WrappedInstance.Locked = true
            task.wait()
            expect(ChangeEventCalls[4]).to.equal("Locked")
            expect(SignalCalls[3]).to.equal("Anchored")
            
            --Change a property to the same value and assert that the event calls didn't change.
            WrappedPart.Name = "Test2"
            WrappedPart.WrappedInstance.Locked = true
            task.wait()
            expect(ChangeEventCalls[4]).to.equal("Locked")
            expect(SignalCalls[3]).to.equal("Anchored")
            expect(ChangeEventCalls[5]).to.equal(nil)
            expect(SignalCalls[4]).to.equal(nil)
        end)

        it("should raise an error when a non-existent property is read.", function()
            expect(function()
                local _ = WrappedPart.BadProperty
            end).to.throw()
        end)
    end)

    describe("A subclass of NexusWrappedInstance", function()
        it("should create a subclass correctly.", function()
            local TestClass = NexusWrappedInstance:Extend()
            TestClass:SetClassName("TestClass")
            function TestClass:__new()
                NexusWrappedInstance.__new(self, "Part")
            end

            local TestObject = TestClass.new()
            expect(TestObject:IsA("BasePart")).to.equal(true)
            expect(TestObject:IsA("Part")).to.equal(true)
            expect(TestObject:IsA("TestClass")).to.equal(true)
            expect(TestObject:IsA("NexusWrappedInstance")).to.equal(true)
            expect(TestObject:IsA("NexusInstance")).to.equal(true)
            expect(TestObject:IsA("Model")).to.equal(false)
            TestObject:Destroy()
        end)

        it("should create GetInstance methods.", function()
            --Create a sub class with GetInstance.
            local TestClass = NexusWrappedInstance:Extend()
            TestClass:SetClassName("TestClass")
            TestClass:CreateGetInstance()

            --Test that GetInstance returns correctly.
            local WrappedInstance1, WrappedInstance2 = TestClass.GetInstance("Part"), NexusWrappedInstance.GetInstance("Part")
            expect(WrappedInstance1:IsA("NexusWrappedInstance")).to.equal(true)
            expect(WrappedInstance1:IsA("TestClass")).to.equal(true)
            expect(WrappedInstance2:IsA("NexusWrappedInstance")).to.equal(true)
            expect(WrappedInstance2:IsA("TestClass")).to.equal(false)
        end)
    end)

    describe("A wrapped instance with a property read error", function()
        it("should not throw an error when a property is changed.", function()
            --Create an instance that throws an error when read.
            local TestClass = NexusInstance:Extend()
            function TestClass:__new()
                NexusInstance.__new(self)
                self.AncestryChanged = {
                    Connect = function()
                        
                    end
                }
        
                local BaseIndex = getmetatable(self).__index
                getmetatable(self).__index = function(MethodObject: any, Index: string): any
                    if Index == "BadProperty" then
                        error("Mock lack of permission error.")
                    end
                    return BaseIndex(MethodObject, Index)
                end
            end
            local WrappedInstance = NexusWrappedInstance.new(TestClass.new())

            --Send a changed event for a bad property.
            WrappedInstance.WrappedInstance.Changed:Fire("BadProperty")

            --Set the name and assert that it changed.
            WrappedInstance.Name = "TestName"
            expect(WrappedInstance.Name).to.equal("TestName")
            expect(WrappedInstance.WrappedInstance.Name).to.equal("TestName")
        end)
    end)
end