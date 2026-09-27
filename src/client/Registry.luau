--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local controllers: { Lifecycle.System } = {
	require(script.Parent.Controllers.DataController),
	require(script.Parent.Controllers.AppController),
	require(script.Parent.Controllers.UIController),
	require(script.Parent.Controllers.ComponentController),
}

return controllers
