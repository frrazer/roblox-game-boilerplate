--!strict

local Signal = require(script.Parent.Packages.Signal)
local Task = require(script.Task)
local Types = require(script.Types)
local RateLimit = require(script.Parent.Utils.RateLimit)

export type Packet<A... = (), B... = ()> = {
	Type: "Packet",
	Id: number,
	Name: string,
	Reads: { () -> any },
	Writes: { (any) -> () },
	ResponseTimeout: number,
	ResponseTimeoutValue: any,
	ResponseReads: { () -> any },
	ResponseWrites: { (any) -> () },
	RateLimiter: RateLimit.RateLimit?,
	OnServerEvent: Signal.Signal<(Player, A...)>,
	OnClientEvent: Signal.Signal<A...>,
	OnServerInvoke: nil | (player: Player, A...) -> B...,
	OnClientInvoke: nil | (A...) -> B...,
	Response: (self: Packet<A..., B...>, B...) -> Packet<A..., B...>,
	RateLimit: (self: Packet<A..., B...>, count: number, window: number) -> Packet<A..., B...>,
	Fire: (self: Packet<A..., B...>, A...) -> B...,
	FireClient: (self: Packet<A..., B...>, player: Player, A...) -> B...,
	FireAllClients: (self: Packet<A..., B...>, A...) -> (),
	Serialize: (self: Packet<A..., B...>, A...) -> (buffer, { Instance }?),
	Deserialize: (self: Packet<A..., B...>, serializeBuffer: buffer, instances: { Instance }?) -> A...,
}

local Settings =
	{ UseBuffers = true, DebugOutgoing = false, DebugOutgoingInterval = 5, DebugOutgoingTop = 10 }
local ParametersToFunctions, TableToFunctions, ReadParameters, WriteParameters, Timeout, TryActivateChannel
local RunService = game:GetService("RunService")
local PlayersService = game:GetService("Players")
local reads, writes, Import, Export, Truncate, Ended =
	Types.Reads, Types.Writes, Types.Import, Types.Export, Types.Truncate, Types.Ended
local ReadU8, WriteU8, ReadU16, WriteU16 = reads.NumberU8, writes.NumberU8, reads.NumberU16, writes.NumberU16
local Packet = {} :: Packet<...any, ...any>
local packets = {} :: { [string | number]: Packet<...any, ...any> }
local playerCursors: { [Player]: Types.Cursor }
local playerThreads: { [Player]: { [number]: { Yielded: thread, Timeout: thread }, Index: number } }
local threads: { [number]: { Yielded: thread, Timeout: thread }, Index: number }
local remoteEvent: RemoteEvent
local packetCounter: number
local cursor =
	{ Buffer = buffer.create(128), BufferLength = 128, BufferOffset = 0, Instances = {}, InstancesOffset = 0 }
local debugOutgoingCounts: { [string]: number }? = nil
local debugOutgoingLastDump = 0
local packetRemotes: { RemoteEvent } = {}
local channelChosen = false

local honeypotCallback: ((player: Player) -> ())? = nil

local function OnHoneypot(player: Player)
	local callback = honeypotCallback
	if callback then
		task.spawn(callback, player)
	end
end

local function debugOutgoingIncrement(name: string)
	if Settings.DebugOutgoing ~= true or RunService:IsServer() ~= true then
		return
	end

	local counts: { [string]: number } = debugOutgoingCounts or {}
	if debugOutgoingCounts == nil then
		debugOutgoingCounts = counts
		debugOutgoingLastDump = os.clock()
	end

	counts[name] = (counts[name] or 0) + 1

	local now = os.clock()
	local interval = Settings.DebugOutgoingInterval or 5
	if (now - debugOutgoingLastDump) < interval then
		return
	end
	debugOutgoingLastDump = now

	local items: { { name: string, count: number } } = {}
	for packetName, count in counts do
		items[#items + 1] = { name = packetName, count = count }
	end
	table.sort(items, function(a, b)
		return a.count > b.count
	end)

	local top = Settings.DebugOutgoingTop or 10
	local parts = {}
	for i = 1, math.min(top, #items) do
		local item = items[i]
		parts[#parts + 1] = item.name .. "=" .. tostring(item.count)
	end
	print("[Packet] Outgoing:", table.concat(parts, ", "))

	table.clear(counts)
end

local function Constructor<A..., B...>(_, name: string, ...: A...)
	local existing = packets[name] :: Packet<A..., B...>
	if existing then
		return existing
	end
	local packet = (setmetatable({}, Packet) :: any) :: Packet<A..., B...>
	packet.Name = name
	if RunService:IsServer() then
		if channelChosen then
			error("Packet: all packets must be defined during startup", 2)
		end
		packet.Id = packetCounter
		packet.OnServerEvent = Signal.new() :: Signal.Signal<(Player, A...)>
		script:SetAttribute(name, packetCounter)
		local packetRemote = Instance.new("RemoteEvent")
		packetRemote.Name = name
		packetRemote.Parent = script
		table.insert(packetRemotes, packetRemote)
		task.defer(TryActivateChannel)
		packets[packetCounter] = packet
		packetCounter += 1
	else
		packet.Id = script:GetAttribute(name) :: number
		packet.OnClientEvent = Signal.new() :: Signal.Signal<A...>
		if packet.Id then
			packets[packet.Id] = packet
		end
	end
	packet.Reads, packet.Writes = ParametersToFunctions(table.pack(...))
	packets[packet.Name] = packet
	return packet
end

Packet["__index"] = Packet
Packet.Type = "Packet"

function Packet:Response(...)
	self.ResponseTimeout = self.ResponseTimeout or 10
	self.ResponseReads, self.ResponseWrites = ParametersToFunctions(table.pack(...))
	return self
end

function Packet:RateLimit(count, window)
	self.RateLimiter = RateLimit.new(count, window)
	return self
end

function Packet:Fire(...)
	if Settings.UseBuffers then
		if self.ResponseReads then
			if RunService:IsServer() then
				error("You must use FireClient(player)", 2)
			end
			local responseThread
			for i = 1, 128 do
				responseThread = threads[threads.Index]
				if responseThread then
					threads.Index = (threads.Index + 1) % 128
				else
					break
				end
			end
			if responseThread then
				error("Cannot have more than 128 yielded threads", 2)
			end
			Import(cursor)
			WriteU8(self.Id)
			WriteU8(threads.Index)
			threads[threads.Index] = {
				Yielded = coroutine.running(),
				Timeout = Task:Delay(
					self.ResponseTimeout,
					Timeout,
					threads,
					threads.Index,
					self.ResponseTimeoutValue
				),
			}
			threads.Index = (threads.Index + 1) % 128
			WriteParameters(self.Writes, { ... })
			cursor = Export()
			return coroutine.yield()
		else
			Import(cursor)
			WriteU8(self.Id)
			WriteParameters(self.Writes, { ... })
			cursor = Export()
		end
	else
		if self.ResponseReads then
			if RunService:IsServer() then
				error("You must use FireClient(player)", 2)
			end
			local responseThread
			for i = 1, 128 do
				responseThread = threads[threads.Index]
				if responseThread then
					threads.Index = (threads.Index + 1) % 128
				else
					break
				end
			end
			if responseThread then
				error("Cannot have more than 128 yielded threads", 2)
			end
			threads[threads.Index] = {
				Yielded = coroutine.running(),
				Timeout = Task:Delay(
					self.ResponseTimeout,
					Timeout,
					threads,
					threads.Index,
					self.ResponseTimeoutValue
				),
			}
			remoteEvent:FireServer(self.Id, threads.Index, ...)
			threads.Index = (threads.Index + 1) % 128
			return coroutine.yield()
		else
			remoteEvent:FireServer(self.Id, ...)
		end
	end
end

function Packet:FireClient(player, ...)
	if player.Parent == nil then
		return
	end
	if Settings.UseBuffers then
		if self.ResponseReads then
			debugOutgoingIncrement(self.Name)
			local threads = playerThreads[player]
			if threads == nil then
				threads = { Index = 0 }
				playerThreads[player] = threads
			end
			local responseThread
			for i = 1, 128 do
				responseThread = threads[threads.Index]
				if responseThread then
					threads.Index = (threads.Index + 1) % 128
				else
					break
				end
			end
			if responseThread then
				error("Cannot have more than 128 yielded threads", 2)
				return
			end
			Import(playerCursors[player] or {
				Buffer = buffer.create(128),
				BufferLength = 128,
				BufferOffset = 0,
				Instances = {},
				InstancesOffset = 0,
			})
			WriteU8(self.Id)
			WriteU8(threads.Index)
			threads[threads.Index] = {
				Yielded = coroutine.running(),
				Timeout = Task:Delay(
					self.ResponseTimeout,
					Timeout,
					threads,
					threads.Index,
					self.ResponseTimeoutValue
				),
			}
			threads.Index = (threads.Index + 1) % 128
			WriteParameters(self.Writes, { ... })
			playerCursors[player] = Export()
			return coroutine.yield()
		else
			debugOutgoingIncrement(self.Name)
			Import(playerCursors[player] or {
				Buffer = buffer.create(128),
				BufferLength = 128,
				BufferOffset = 0,
				Instances = {},
				InstancesOffset = 0,
			})
			WriteU8(self.Id)
			WriteParameters(self.Writes, { ... })
			playerCursors[player] = Export()
		end
	else
		if self.ResponseReads then
			debugOutgoingIncrement(self.Name)
			local threads = playerThreads[player]
			if threads == nil then
				threads = { Index = 0 }
				playerThreads[player] = threads
			end
			local responseThread
			for i = 1, 128 do
				responseThread = threads[threads.Index]
				if responseThread then
					threads.Index = (threads.Index + 1) % 128
				else
					break
				end
			end
			if responseThread then
				error("Cannot have more than 128 yielded threads", 2)
				return
			end
			threads[threads.Index] = {
				Yielded = coroutine.running(),
				Timeout = Task:Delay(
					self.ResponseTimeout,
					Timeout,
					threads,
					threads.Index,
					self.ResponseTimeoutValue
				),
			}
			remoteEvent:FireClient(player, self.Id, threads.Index, ...)
			threads.Index = (threads.Index + 1) % 128
			return coroutine.yield()
		else
			debugOutgoingIncrement(self.Name)
			remoteEvent:FireClient(player, self.Id, ...)
		end
	end
end

function Packet:FireAllClients(...)
	if not RunService:IsServer() then
		error("FireAllClients can only be called from the server", 2)
	end
	if self.ResponseReads then
		error("Cannot use FireAllClients with packets that expect a response", 2)
	end
	if Settings.UseBuffers then
		debugOutgoingIncrement(self.Name)
		Import(cursor)
		WriteU8(self.Id)
		WriteParameters(self.Writes, { ... })
		cursor = Export()
	else
		debugOutgoingIncrement(self.Name)
		remoteEvent:FireAllClients(self.Id, ...)
	end
end

function Packet:Serialize(...)
	Import({
		Buffer = buffer.create(128),
		BufferLength = 128,
		BufferOffset = 0,
		Instances = {},
		InstancesOffset = 0,
	})
	WriteParameters(self.Writes, { ... })
	return Truncate()
end

function Packet:Deserialize(serializeBuffer, instances)
	Import({
		Buffer = serializeBuffer,
		BufferLength = buffer.len(serializeBuffer),
		BufferOffset = 0,
		Instances = instances or {},
		InstancesOffset = 0,
	})
	return ReadParameters(self.Reads)
end

function ParametersToFunctions(parameters: { any })
	local readFunctions, writeFunctions = table.create(#parameters), table.create(#parameters)
	for index, parameter in ipairs(parameters) do
		if type(parameter) == "table" then
			readFunctions[index], writeFunctions[index] = TableToFunctions(parameter)
		else
			readFunctions[index], writeFunctions[index] = reads[parameter], writes[parameter]
		end
	end
	return readFunctions, writeFunctions
end

function TableToFunctions(parameters: { any })
	if #parameters == 1 then
		local parameter = parameters[1]
		local ReadFunction, WriteFunction
		if type(parameter) == "table" then
			ReadFunction, WriteFunction = TableToFunctions(parameter)
		else
			ReadFunction, WriteFunction = reads[parameter], writes[parameter]
		end
		local Read = function()
			local length = ReadU16()
			local values = table.create(length)
			for index = 1, length do
				values[index] = ReadFunction()
			end
			return values
		end
		local Write = function(values: { any })
			WriteU16(#values)
			for index, value in values do
				WriteFunction(value)
			end
		end
		return Read, Write
	else
		local keys = {}
		for key, value in parameters do
			table.insert(keys, key)
		end
		table.sort(keys)
		local readFunctions, writeFunctions = table.create(#keys), table.create(#keys)
		for index, key in keys do
			local parameter = parameters[key]
			if type(parameter) == "table" then
				readFunctions[index], writeFunctions[index] = TableToFunctions(parameter)
			else
				readFunctions[index], writeFunctions[index] = reads[parameter], writes[parameter]
			end
		end
		local Read = function()
			local values = {}
			for index, ReadFunction in readFunctions do
				values[keys[index]] = ReadFunction()
			end
			return values
		end
		local Write = function(values: { [any]: any })
			for index, WriteFunction in writeFunctions do
				WriteFunction(values[keys[index]])
			end
		end
		return Read, Write
	end
end

function ReadParameters(reads: { () -> any })
	local values = table.create(#reads)
	for index, func in reads do
		values[index] = func()
	end
	return table.unpack(values)
end

function WriteParameters(writes: { (any) -> () }, values: { any })
	for index, func in writes do
		func(values[index])
	end
end

function Timeout(
	threads: { [number]: { Yielded: thread, Timeout: thread }, Index: number },
	threadIndex: number,
	value: any
)
	local responseThreads = threads[threadIndex]
	task.defer(responseThreads.Yielded, value)
	threads[threadIndex] = nil
end

if RunService:IsServer() then
	playerCursors = {}
	playerThreads = {}
	packetCounter = 0

	local playerBytes = {}

	local thread = task.spawn(function()
		while true do
			coroutine.yield()
			if cursor.BufferOffset > 0 then
				local truncatedBuffer = buffer.create(cursor.BufferOffset)
				buffer.copy(truncatedBuffer, 0, cursor.Buffer, 0, cursor.BufferOffset)
				if cursor.InstancesOffset == 0 then
					remoteEvent:FireAllClients(truncatedBuffer)
				else
					remoteEvent:FireAllClients(truncatedBuffer, cursor.Instances)
					cursor.InstancesOffset = 0
					table.clear(cursor.Instances)
				end
				cursor.BufferOffset = 0
			end
			for player, cursor in playerCursors do
				local truncatedBuffer = buffer.create(cursor.BufferOffset)
				buffer.copy(truncatedBuffer, 0, cursor.Buffer, 0, cursor.BufferOffset)
				if cursor.InstancesOffset == 0 then
					remoteEvent:FireClient(player, truncatedBuffer)
				else
					remoteEvent:FireClient(player, truncatedBuffer, cursor.Instances)
				end
			end
			table.clear(playerCursors)
			table.clear(playerBytes)
		end
	end)

	local allowed = function(packet: Packet, player: Player): boolean
		local limiter = packet.RateLimiter
		if limiter == nil or limiter:Allow(player) then
			return true
		end
		if RunService:IsStudio() then
			warn(player.Name, "is rate limited on packet:", packet.Name)
		end
		return false
	end

	local respond = function(packet: Packet, player: Player, threadIndex: number, ...)
		if not allowed(packet, player) then
			return
		end
		if packet.OnServerInvoke == nil then
			if RunService:IsStudio() then
				warn("OnServerInvoke not found for packet:", packet.Name, "discarding event:", ...)
			end
			return
		end
		local values = { packet.OnServerInvoke(player, ...) }
		if player.Parent == nil then
			return
		end
		Import(playerCursors[player] or {
			Buffer = buffer.create(128),
			BufferLength = 128,
			BufferOffset = 0,
			Instances = {},
			InstancesOffset = 0,
		})
		WriteU8(packet.Id)
		WriteU8(threadIndex + 128)
		WriteParameters(packet.ResponseWrites, values)
		playerCursors[player] = Export()
	end

	local onServerEvent = function(player: Player, receivedBuffer: buffer, instances: { Instance }?)
		local bytes = (playerBytes[player] or 0) + math.max(buffer.len(receivedBuffer), 800)
		if bytes > 8_000 then
			if RunService:IsStudio() then
				warn(player.Name, "is exceeding the data/rate limit; some events may be dropped")
			end
			return
		end
		playerBytes[player] = bytes
		Import({
			Buffer = receivedBuffer,
			BufferLength = buffer.len(receivedBuffer),
			BufferOffset = 0,
			Instances = instances or {},
			InstancesOffset = 0,
		})
		while Ended() == false do
			local packet = packets[ReadU8()]
			if packet.ResponseReads then
				local threadIndex = ReadU8()
				if threadIndex < 128 then
					Task:Defer(respond, packet, player, threadIndex, ReadParameters(packet.Reads))
				else
					threadIndex -= 128
					local responseThreads = playerThreads[player][threadIndex]
					if responseThreads then
						task.cancel(responseThreads.Timeout)
						task.defer(responseThreads.Yielded, ReadParameters(packet.ResponseReads))
						playerThreads[player][threadIndex] = nil
					elseif RunService:IsStudio() then
						warn(
							"Response thread not found for packet:",
							packet.Name,
							"discarding response:",
							ReadParameters(packet.ResponseReads)
						)
					else
						ReadParameters(packet.ResponseReads)
					end
				end
			elseif allowed(packet, player) then
				packet.OnServerEvent:FireDeferred(player, ReadParameters(packet.Reads))
			else
				ReadParameters(packet.Reads)
			end
		end
	end

	local respondUnbuffered = function(packet: Packet, player: Player, threadIndex: number, ...)
		if not allowed(packet, player) then
			return
		end
		if packet.OnServerInvoke == nil then
			if RunService:IsStudio() then
				warn("OnServerInvoke not found for packet:", packet.Name, "discarding event:", ...)
			end
			return
		end
		local values = { packet.OnServerInvoke(player, ...) }
		if player.Parent == nil then
			return
		end
		remoteEvent:FireClient(player, packet.Id, threadIndex + 128, table.unpack(values))
	end

	local onServerEventUnbuffered = function(player: Player, packetId: number, ...)
		local packet = packets[packetId]
		if not packet then
			return
		end
		if packet.ResponseReads then
			local args = { ... }
			local threadIndex = table.remove(args, 1)
			Task:Defer(respondUnbuffered, packet, player, threadIndex, table.unpack(args))
		elseif allowed(packet, player) then
			packet.OnServerEvent:FireDeferred(player, ...)
		end
	end

	local onRemoteEvent = function(player: Player, arg1, ...)
		local _success, errorMessage: string?
		if typeof(arg1) == "buffer" then
			_success, errorMessage = pcall(onServerEvent, player, arg1, ...)
		else
			_success, errorMessage = pcall(onServerEventUnbuffered, player, arg1, ...)
		end
		if errorMessage and RunService:IsStudio() then
			warn(player.Name, errorMessage)
		end
	end

	TryActivateChannel = function()
		if channelChosen or #packetRemotes == 0 then
			return
		end
		channelChosen = true
		local startTime = os.time()
		remoteEvent = packetRemotes[Random.new(startTime):NextInteger(1, #packetRemotes)]
		remoteEvent.OnServerEvent:Connect(onRemoteEvent)
		for _, candidate in packetRemotes do
			if candidate ~= remoteEvent then
				candidate.OnServerEvent:Connect(OnHoneypot)
			end
		end
		workspace:SetAttribute("StartTime", startTime)
	end

	PlayersService.PlayerRemoving:Connect(function(player)
		playerCursors[player] = nil
		playerThreads[player] = nil
		playerBytes[player] = nil
		for _, packet in packets do
			if packet.RateLimiter then
				packet.RateLimiter:Remove(player)
			end
		end
	end)

	if Settings.UseBuffers then
		RunService.Heartbeat:Connect(function(deltaTime)
			task.defer(thread)
		end)
	end
else
	threads = { Index = 0 }
	local startTime = workspace:GetAttribute("StartTime")
	while type(startTime) ~= "number" do
		workspace.AttributeChanged:Wait()
		startTime = workspace:GetAttribute("StartTime")
	end
	local channelNames: { string } = {}
	for attributeName, id in script:GetAttributes() do
		if type(id) == "number" then
			channelNames[id + 1] = attributeName
		end
	end
	local channelName = channelNames[Random.new(startTime :: number):NextInteger(1, #channelNames)]
	remoteEvent = script:WaitForChild(channelName) :: RemoteEvent
	local totalTime = 0

	local thread = task.spawn(function()
		while true do
			coroutine.yield()
			if cursor.BufferOffset > 0 then
				local truncatedBuffer = buffer.create(cursor.BufferOffset)
				buffer.copy(truncatedBuffer, 0, cursor.Buffer, 0, cursor.BufferOffset)
				if cursor.InstancesOffset == 0 then
					remoteEvent:FireServer(truncatedBuffer)
				else
					remoteEvent:FireServer(truncatedBuffer, cursor.Instances)
					cursor.InstancesOffset = 0
					table.clear(cursor.Instances)
				end
				cursor.BufferOffset = 0
			end
		end
	end)

	local respond = function(packet: Packet, threadIndex: number, ...)
		if packet.OnClientInvoke == nil then
			warn("OnClientInvoke not found for packet:", packet.Name, "discarding event:", ...)
			return
		end
		local values = { packet.OnClientInvoke(...) }
		Import(cursor)
		WriteU8(packet.Id)
		WriteU8(threadIndex + 128)
		WriteParameters(packet.ResponseWrites, values)
		cursor = Export()
	end

	local respondUnbuffered = function(packet: Packet, threadIndex: number, ...)
		if packet.OnClientInvoke == nil then
			warn("OnClientInvoke not found for packet:", packet.Name, "discarding event:", ...)
			return
		end
		local values = { packet.OnClientInvoke(...) }
		remoteEvent:FireServer(packet.Id, threadIndex + 128, table.unpack(values))
	end

	local onClientEventUnbuffered = function(packetId: number, ...)
		local packet = packets[packetId]
		if not packet then
			return
		end
		if packet.ResponseReads then
			local args = { ... }
			local threadIndex = table.remove(args, 1) :: number
			if threadIndex < 128 then
				Task:Defer(respondUnbuffered, packet, threadIndex, table.unpack(args))
			else
				threadIndex -= 128
				local responseThreads = threads[threadIndex]
				if responseThreads then
					task.cancel(responseThreads.Timeout)
					task.defer(responseThreads.Yielded, table.unpack(args))
					threads[threadIndex] = nil
				else
					warn(
						"Response thread not found for packet:",
						packet.Name,
						"discarding response:",
						table.unpack(args)
					)
				end
			end
		else
			packet.OnClientEvent:FireDeferred(...)
		end
	end

	remoteEvent.OnClientEvent:Connect(function(arg1, ...)
		if typeof(arg1) == "buffer" then
			local instances = select(1, ...)
			Import({
				Buffer = arg1,
				BufferLength = buffer.len(arg1),
				BufferOffset = 0,
				Instances = instances or {},
				InstancesOffset = 0,
			})
			while Ended() == false do
				local packet = packets[ReadU8()]
				if packet.ResponseReads then
					local threadIndex = ReadU8()
					if threadIndex < 128 then
						Task:Defer(respond, packet, threadIndex, ReadParameters(packet.Reads))
					else
						threadIndex -= 128
						local responseThreads = threads[threadIndex]
						if responseThreads then
							task.cancel(responseThreads.Timeout)
							task.defer(responseThreads.Yielded, ReadParameters(packet.ResponseReads))
							threads[threadIndex] = nil
						else
							warn(
								"Response thread not found for packet:",
								packet.Name,
								"discarding response:",
								ReadParameters(packet.ResponseReads)
							)
						end
					end
				else
					packet.OnClientEvent:FireDeferred(ReadParameters(packet.Reads))
				end
			end
		else
			onClientEventUnbuffered(arg1, ...)
		end
	end)

	script.AttributeChanged:Connect(function(name)
		local packet = packets[name]
		if packet then
			if packet.Id then
				packets[packet.Id] = nil
			end
			packet.Id = script:GetAttribute(name) :: number
			if packet.Id then
				packets[packet.Id] = packet
			end
		end
	end)

	if Settings.UseBuffers then
		RunService.Heartbeat:Connect(function(deltaTime)
			totalTime += deltaTime
			if totalTime > 0.016666666666666666 then
				totalTime %= 0.016666666666666666
				task.defer(thread)
			end
		end)
	end
end

return setmetatable(Types.Types, {
	__call = Constructor,
	__index = {
		Settings = Settings,
		SetHoneypotCallback = function(callback: (player: Player) -> ())
			honeypotCallback = callback
		end,
	},
})
