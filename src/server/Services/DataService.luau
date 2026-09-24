--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Signal = require(ReplicatedStorage.Packages.Signal)
local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local DataSessions = require(script.Parent.Parent.Data.DataSessions)

local DataService = {
	Name = "DataService",
	Published = Signal.new() :: Signal.Signal<(Player, PlayerData.Data)>,
	PlayerLoaded = Signal.new() :: Signal.Signal<(Player, PlayerData.Data)>,
	PlayerReleasing = Signal.new() :: Signal.Signal<(Player, PlayerData.Data)>,
}
local sessions: DataSessions.DataSessions? = nil
local connections: { RBXScriptConnection } = {}
local stopped = false
local warnedMock = false

function DataService.Init(_self: any, _services: { [string]: any })
	local storeName = if RunService:IsStudio() then "PlayerData_Studio" else "PlayerData"
	local store = ProfileStore.New(storeName, PlayerData.Template)
	sessions = DataSessions.new(store :: any, function(player)
		return player.Parent == Players
	end)
end

local function load(player: Player)
	player:SetAttribute("DataLoaded", false)
	while ProfileStore.DataStoreState == "NotReady" and not stopped and player.Parent == Players do
		task.wait()
	end
	if stopped or player.Parent ~= Players then
		return
	end
	if ProfileStore.DataStoreState ~= "Access" and not warnedMock then
		warnedMock = true
		warn(
			`[DataService] DataStores unavailable ({ProfileStore.DataStoreState}); using mock data that resets when Play stops. Enable Studio Access to API Services to test saving.`
		)
	end
	local activeSessions = sessions
	if not activeSessions then
		return
	end
	activeSessions:Load(player)
	local data = activeSessions:GetData(player)
	if data then
		DataService:Publish(player)
		DataService.PlayerLoaded:Fire(player, data)
	end
end

function DataService.GetData(_self: any, player: Player): PlayerData.Data?
	local activeSessions = sessions
	return if activeSessions then activeSessions:GetData(player) else nil
end

function DataService.Publish(_self: any, player: Player)
	local data = DataService:GetData(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	DataService.Published:Fire(player, data)
end

function DataService.Start(_self: any)
	table.insert(connections, Players.PlayerAdded:Connect(load))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local activeSessions = sessions
			if not activeSessions then
				return
			end
			local data = activeSessions:GetData(player)
			if data then
				DataService.PlayerReleasing:Fire(player, data)
			end
			activeSessions:Release(player)
		end)
	)
	for _, player in Players:GetPlayers() do
		task.defer(load, player)
	end
end

function DataService.RequestSave(_self: any, player: Player): boolean
	local activeSessions = sessions
	DataService:Publish(player)
	return if activeSessions then activeSessions:RequestSave(player) else false
end

function DataService.WaitForSave(_self: any, player: Player, saved: (any) -> boolean): boolean
	local activeSessions = sessions
	DataService:Publish(player)
	return if activeSessions then activeSessions:WaitForSave(player, saved) else false
end

function DataService.AdjustCash(_self: any, player: Player, amount: number): boolean
	if amount ~= amount or math.abs(amount) == math.huge or amount % 1 ~= 0 then
		return false
	end
	local data = DataService:GetData(player)
	if not data then
		return false
	end
	local nextBalance = data.Cash + amount
	if nextBalance < 0 or nextBalance > 9007199254740991 then
		return false
	end
	data.Cash = nextBalance
	return DataService:RequestSave(player)
end

function DataService.Destroy(_self: any)
	stopped = true
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	local activeSessions = sessions
	if activeSessions then
		for _, player in Players:GetPlayers() do
			local data = activeSessions:GetData(player)
			if data then
				DataService.PlayerReleasing:Fire(player, data)
			end
		end
		activeSessions:Destroy()
	end
end

return DataService
