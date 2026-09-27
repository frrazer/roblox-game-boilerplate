--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaClient = require(ReplicatedStorage.ReplicaClient)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Path = { string | number }
type Connection = { Disconnect: (self: any) -> () }

local DataController = {
	Name = "DataController",
	Loaded = Signal.new() :: Signal.Signal<{ [any]: any }>,
}
local replica: ReplicaClient.Replica? = nil
local connections: { Connection } = {}

local function read(data: any, path: Path): any
	local value = data
	for _, key in path do
		if type(value) ~= "table" then
			return nil
		end
		value = value[key]
	end
	return value
end

local function overlaps(changed: { any }, path: Path): boolean
	for index = 1, math.min(#changed, #path) do
		if changed[index] ~= path[index] then
			return false
		end
	end
	return true
end

function DataController.Init(_self: any, _controllers: { [string]: any }) end

function DataController.Start(_self: any)
	table.insert(
		connections,
		ReplicaClient.OnNew("PlayerData", function(newReplica: ReplicaClient.Replica)
			if newReplica.Tags.Player ~= Players.LocalPlayer then
				return
			end
			replica = newReplica
			DataController.Loaded:Fire(newReplica.Data)
		end) :: any
	)
	ReplicaClient.RequestData()
end

function DataController.IsLoaded(_self: any): boolean
	return replica ~= nil
end

function DataController.Get(_self: any, path: Path?): any
	local current = replica
	if not current then
		return nil
	end
	return if path then read(current.Data, path) else current.Data
end

function DataController.Observe(_self: any, path: Path, callback: (value: any) -> ()): Connection
	local active = true
	local changeConnection: Connection? = nil
	local loadedConnection: Connection? = nil
	local function watch(current: ReplicaClient.Replica)
		callback(read(current.Data, path))
		changeConnection = current:OnChange(function(_action: string, changedPath: { any })
			if active and overlaps(changedPath, path) then
				callback(read(current.Data, path))
			end
		end) :: any
	end
	local current = replica
	if current then
		watch(current)
	else
		loadedConnection = DataController.Loaded:Connect(function()
			if loadedConnection then
				loadedConnection:Disconnect()
			end
			local loaded = replica
			if active and loaded then
				watch(loaded)
			end
		end) :: any
	end
	return {
		Disconnect = function(_connection: any)
			active = false
			if loadedConnection then
				loadedConnection:Disconnect()
			end
			if changeConnection then
				changeConnection:Disconnect()
			end
		end,
	}
end

function DataController.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	replica = nil
end

return DataController
