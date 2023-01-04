--[[
TheNexusAvenger

Tests garbage collection of the NexusWrappedInstance class.
--]]
--!strict

_G.EnsureNexusWrappedInstanceSingleton = false
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))

return function()
    describe("Instances of NexusWrappedInstance", function()
        it("should garbage collect", function()
            --Create the instances but don't store them to allow them to garbage collect.
            for _ = 1, 10 do
                NexusWrappedInstance.new("Part"):Destroy()
            end

            --Determine how many instances are stored and break if 0 is reached.
            local CachedInstances = 10
            for _ = 1, 120 * 10 do
                CachedInstances = 0
                for _, _ in pairs(NexusWrappedInstance.CachedInstances) do
                    CachedInstances = CachedInstances + 1
                end
                if CachedInstances == 0 then break end
                task.wait(0.1)
            end

            --Assert that the instances are garbage collected.
            expect(CachedInstances).to.equal(0)
        end)
    end)
end