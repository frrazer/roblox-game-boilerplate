--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)
local Types = require(script.Types)

local modules: { [string]: Types.ScreenModule } = {}

local UIController = { Name = "UIController" }
local registry: { [string]: any } = {}
local screens: { [string]: Types.Screen } = {}
local opened: { [string]: boolean } = {}
local pending: { any } = {}
local destroyed = false

function UIController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
end

function UIController.Open(_self: any, name: string)
	local screen = screens[name]
	if not screen or opened[name] then
		return
	end
	if screen.Modal then
		for otherName in opened do
			if screens[otherName].Modal then
				UIController:Close(otherName)
			end
		end
	end
	opened[name] = true
	screen:Open()
end

function UIController.Close(_self: any, name: string)
	local screen = screens[name]
	if not screen or not opened[name] then
		return
	end
	opened[name] = nil
	screen:Close()
end

function UIController.IsOpen(_self: any, name: string): boolean
	return opened[name] == true
end

function UIController.Start(_self: any)
	local context: Types.Context = {
		Controllers = registry,
		Open = function(name: string)
			UIController:Open(name)
		end,
		Close = function(name: string)
			UIController:Close(name)
		end,
	}
	for name, module in modules do
		local promise = WaitFor.Child(Players.LocalPlayer, "PlayerGui", 15)
			:andThen(function(playerGui: Instance)
				return WaitFor.Child(playerGui, name, 15)
			end)
			:andThen(function(gui: Instance)
				if destroyed then
					return
				end
				if not gui:IsA("ScreenGui") then
					error(`{gui:GetFullName()} is a {gui.ClassName}, not a ScreenGui`)
				end
				gui.ResetOnSpawn = false
				local screen = module.new(context, gui)
				screens[name] = screen
				if screen.StartsOpen then
					UIController:Open(name)
				else
					screen:Close()
				end
			end)
			:catch(function(problem: any)
				warn(
					`[UIController] {name} screen disabled; needs a ScreenGui at PlayerGui.{name}: {tostring(
						problem
					)}`
				)
			end)
		table.insert(pending, promise)
	end
end

function UIController.Destroy(_self: any)
	destroyed = true
	for _, promise in pending do
		promise:cancel()
	end
	table.clear(pending)
	for _, screen in screens do
		screen:Destroy()
	end
	table.clear(screens)
	table.clear(opened)
end

return UIController
