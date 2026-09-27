--[[
MAD STUDIO

-[Remote]---------------------------------------
	Remote event setup utility; Prevents duplicate RemoteEvent names server-side

	Functions:
			
		Remote.New(name [string], is_unreliable [bool]) --> [RemoteEvent]
			-- Calling this with the same name server-side twice will throw an error
	
--]]

----- Private -----

local CONTAINER_NAME = "RemoteEvents"
local REMOTE_MISSING_TIME = 20

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IsStudio = RunService:IsStudio()
local IsServer = RunService:IsServer()
local DefinedRemotes = {} -- [name] = true, ...

local Container, OnContainerReady do
	
	if IsServer == true then
		
		Container = ReplicatedStorage:FindFirstChild(CONTAINER_NAME)
		
		if Container ~= nil then
			if IsStudio == true then
				warn(`[{script.Name}]: ReplicatedStorage "{CONTAINER_NAME}" container was already defined`)
			end
		else
			Container = Instance.new("Folder")
			Container.Name = CONTAINER_NAME
			Container.Parent = ReplicatedStorage
		end
		
	else
		
		Container = ReplicatedStorage:FindFirstChild(CONTAINER_NAME)
		
		if Container == nil then
			
			OnContainerReady = Instance.new("BindableEvent")
			
			task.spawn(function()
				while task.wait() do
					Container = ReplicatedStorage:FindFirstChild(CONTAINER_NAME)
					if Container ~= nil then
						OnContainerReady:Fire()
						break
					end
				end
			end)
			
		end
		
	end
	
end

----- Public -----

local Connection = {}
Connection.__index = Connection

function Connection.New(fn)
	return setmetatable({
		fn = fn,
		is_disconnected = false,
		real_connection = nil,
	}, Connection)
end

function Connection:Disconnect()
	self.is_disconnected = true
	if self.real_connection ~= nil then
		self.real_connection:Disconnect()
	end
end

local Remote = {}
Remote.__index = Remote

function Remote.New(name: string, is_unreliable: boolean?): RemoteEvent
	
	if type(name) ~= "string" then
		error(`[{script.Name}]: name must be a string`)
	end
	
	if IsServer == true then
		
		if DefinedRemotes[name] ~= nil then
			error(`[{script.Name}]: RemoteEvent {name} was already defined`)
		end
		
		DefinedRemotes[name] = true
		
		local remote = Instance.new(if is_unreliable == true then "UnreliableRemoteEvent" else "RemoteEvent")
		remote.Name = name
		remote.Parent = Container
		
		return remote
		
	else
		
		local remote: RemoteEvent = Container and Container:FindFirstChild(name)
		
		if remote ~= nil then
			return remote
		end
		
		local connections = {}
		
		local self = setmetatable({
			OnClientEvent = {
				Connect = function(_, fn)

					if remote ~= nil then
						return remote.OnClientEvent:Connect(fn)
					else
						local connection = Connection.New(fn)
						table.insert(connections, connection)
						return connection
					end

				end,
			},
			OnServerEvent = {
				Connect = function()
					error(`[{script.Name}]: Can't connect to "OnServerEvent" client-side`)
				end,
			},
			RemoteEvent = nil,
		}, Remote)
		
		local function on_container_ready()
			
			local missing_start = os.clock()

			while true do
				remote = Container:FindFirstChild(name)
				if remote == nil then
					if missing_start ~= nil and os.clock() - missing_start > REMOTE_MISSING_TIME then
						missing_start = nil
						warn(`[{script.Name}]: RemoteEvent "{name}" hasn't been defined server-side`)
					end
					task.wait()
				else
					break
				end
			end

			for _, connection in ipairs(connections) do
				if connection.is_disconnected == false then
					connection.real_connection = remote.OnClientEvent:Connect(connection.fn)
				end
			end

			self.RemoteEvent = remote
			connections = nil :: any
			
		end
		
		if Container ~= nil then
			task.spawn(on_container_ready)
		else
			local wait_connection
			wait_connection = OnContainerReady.Event:Connect(function()
				wait_connection:Disconnect()
				on_container_ready()
			end)
		end
		
		return self
		
	end
	
end

function Remote:FireServer(...)
	if self.RemoteEvent ~= nil then
		self.RemoteEvent:FireServer(...)
	end
end

function Remote:FireClient()
	error(`[{script.Name}]: Can't use "FireClient" client-side`)
end

function Remote:FireAllClients()
	error(`[{script.Name}]: Can't use "FireAllClients" client-side`)
end

return Remote