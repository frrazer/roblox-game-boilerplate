--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)

type Spinner = {
	Instance: Instance,
	Speed: number,
}

return function(_controllers: { [string]: any })
	local Spinner = Component.new({ Tag = "Spinner" }) :: any

	function Spinner.Construct(self: Spinner)
		local speed = self.Instance:GetAttribute("SpinSpeed")
		self.Speed = if type(speed) == "number" then speed else 90
	end

	function Spinner.RenderSteppedUpdate(self: Spinner, dt: number)
		local part = self.Instance
		if part:IsA("BasePart") then
			part.CFrame *= CFrame.Angles(0, math.rad(self.Speed * dt), 0)
		end
	end

	return Spinner
end
