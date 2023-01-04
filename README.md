# Nexus-Wrapped-Instance
Nexus Wrapped Instance adds functionality to Roblox
instances by wrapping Roblox instances transparently.
Initially, it was a component of
[Nexus Plugin Framework](https://github.com/TheNexusAvenger/Nexus-Plugin-Framework),
and was externalized for use with other projects.

## Example
Consider you want to add a `GetVolume()` function to `Part`.
It can be done with the following:

```lua
--Create the class.
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local PartWithVolume = NexusWrappedInstance:Extend()

--Add the constructor to wrap a part.
function PartWithVolume:__new()
	NexusWrappedInstance.__new(self, "Part")
end

--Add the method for getting the volume.
function PartWithVolume:GetVolume()
	return self.Size.X * self.Size.Y * self.Size.Z
end

--Test the code.
local Part = PartWithVolume.new()
Part.Size = Vector3.new(1, 2, 3)
print(Part:GetVolume()) --6
```

Say you want to add the ability to set the size to a number
and have it apply as if it were a cube. Converting
properties can accomplish this.

```lua
--Create the class.
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local PartWithVolume = NexusWrappedInstance:Extend()

--Add the constructor to wrap a part.
function PartWithVolume:__new()
	NexusWrappedInstance.__new(self, "Part")
end

--Add the method for getting the volume.
function PartWithVolume:GetVolume()
	return self:GetWrappedInstance().Size.X * self:GetWrappedInstance().Size.Y * self:GetWrappedInstance().Size.Z
end

--Add converting the properties.
function PartWithVolume:ConvertProperty(PropertyName, PropertyValue)
	if PropertyName == "Size" and typeof(PropertyValue) == "number" then
		return Vector3.new(PropertyValue, PropertyValue, PropertyValue)
	else
		return NexusWrappedInstance.ConvertProperty(self, PropertyName, PropertyValue)
	end
end

--Test the code.
local Part = PartWithVolume.new()
Part.Size = 4
print(Part.Size) --4
print(Part:GetWrappedInstance().Size) --4, 4, 4
print(Part:GetVolume()) --64
```

Custom properties are a bit more difficult
as the replication needs to be modified, but
can be done with the following:

```lua
--Create the class.
local NexusWrappedInstance = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusWrappedInstance"))
local PartWithVolume = NexusWrappedInstance:Extend()

--Add the constructor to wrap a part.
function PartWithVolume:__new()
	NexusWrappedInstance.__new(self, "Part")
	
	--Set up checking the diameter.
	self:DisableChangeReplication("Diameter")
	self:GetPropertyChangedSignal("Diameter"):Connect(function()
		self.Size = Vector3.new(self.Diameter, self.Diameter, self.Diameter)
	end)
end

--Add the method for getting the volume.
function PartWithVolume:GetVolume()
	return self.Size.X * self.Size.Y * self.Size.Z
end

--Test the code.
local Part = PartWithVolume.new()
Part.Diameter = 4
print(Part.Diameter) --4
print(Part.Size) --4, 4, 4
print(Part:GetWrappedInstance().Size) --4, 4, 4
print(Part:GetVolume()) --64
```

## Contributing
Both issues and pull requests are accepted for this project.

## License
Nexus Admin is available under the terms of the MIT 
Liscence. See [LICENSE](LICENSE) for details.