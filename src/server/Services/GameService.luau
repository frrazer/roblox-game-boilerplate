--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)

local GameService: Lifecycle.System = { Name = "GameService" }

function GameService.Init(_self: Lifecycle.System, _services: { [string]: any }) end

function GameService.Start(_self: Lifecycle.System)
	Packets.Ping.OnServerInvoke = function(_player: Player)
		return workspace:GetServerTimeNow()
	end
	print(`[{GameConfig.Name}] Server services ready`)
end

function GameService.Destroy(_self: Lifecycle.System)
	Packets.Ping.OnServerInvoke = nil
end

return GameService
