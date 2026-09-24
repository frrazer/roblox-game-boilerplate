--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("Packages")
packages:WaitForChild("Trove")

local Lifecycle = require(ReplicatedStorage:WaitForChild("Lifecycle"))
local controllers = require(script.Parent.Registry)
local runtime = Lifecycle.new(controllers)

script.Destroying:Connect(function()
	runtime:Destroy()
end)

runtime:Start()
script:SetAttribute("Ready", true)
