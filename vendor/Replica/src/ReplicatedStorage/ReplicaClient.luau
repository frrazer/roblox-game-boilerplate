--[[
MAD STUDIO

-[Replica]---------------------------------------
	
	State replication with life cycle handling and individual client subscription control.
	
	WARNING: Avoid numeric tables with gaps & non string/numeric keys - They can't be replicated!
			
	Members:
	
		Replica.IsReady:      boolean
		Replica.OnLocalReady: Signal<>
	
	Functions:
	
		Replica.RequestData() -- Requests the server to start sending replica data
		
		Replica.OnNew(token: string, listener: (replica) -> ()): Signal.Connection
		Replica.FromId(id: number): Replica?
		
	Members [Replica]:
	
		Replica.Tags:          {} -- Secondary Replica identifiers
		Replica.Data:          {} -- Table which is replicated; Can only be written to through setter methods server-side
		
		Replica.Id:            number -- Unique identifier
		Replica.Token:         string -- Primary Replica identifier
		
		Replica.Parent:        Replica?
		Replica.Children:      {[Replica]: true}
		
		Replica.BoundInstance: Instance? -- WARNING: Will be set to nil after destruction
		
		Replica.OnClientEvent: Signal<...>
		
		Replica.Maid:          Maid
	
	Methods [Replica]:
	
		-- (EXAMPLE) path: {"Players", "2312310", "Health"} -- A path defines a key branch within Replica.Data
		-- Listeners are called after Replica.Data mutation.
	
		Replica:OnSet(path: {string | number}, listener): Signal.Connection -- (Only for :Set(); For :SetValues() you can use :OnChange())
			listener: (new_value: any, old_value: any) -> ()
			
		Replica:OnWrite(function_name: string, listener): Signal.Connection
			listener: (...) -> ()
			
		Replica:OnChange(listener): Signal.Connection
			listener: (action: string, path: {string | number}, param1: any, param2: any?) -> ()
				-- ("Set",         path, value, old_value)
				-- ("SetValues",   path, values)
				-- ("TableInsert", path, value, index)
				-- ("TableRemove", path, value, index)
				
		Replica:GetChild(token: string): Replica? -- Searches for a child replica with given token name
		
		Replica:FireServer(...) -- Fire a signal to server-side listeners for this specific Replica; Must be subscribed
		Replica:UFireServer(...) -- Same as "Replica:FireServer()", but using UnreliableRemoteEvent
		
		Replica:Identify(): string -- Debug

		Replica:IsActive(): boolean
	
--]]

----- Dependencies -----

local ReplicaShared = game.ReplicatedStorage.ReplicaShared
local Remote = require(ReplicaShared.Remote)
local Signal = require(ReplicaShared.Signal)
local Maid = require(ReplicaShared.Maid)

----- Private -----

local BIND_TAG = "Bind"
local CS_TAG = "REPLICA" -- CollectionService tag
local MAID_LOCK = {}
local REQUEST_DATA_REPEAT = 2

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataRequestStarted = false

local TokenReplicas = {} -- {[token]: {[Replica]: true}}
local Replicas = {} -- {[id]: Replica}
local BindReplicas = {} -- {[id]: Replica} -- Unannounced Replicas waiting for their binds to stream in
local BindInstances = {} -- {[id]: Instance}

local NewReplicaListeners = {} -- {[token]: Signal}

local RemoteRequestData = Remote.New("ReplicaRequestData") -- Fired client-side when the client loads for the first time

local RemoteSet = Remote.New("ReplicaSet")                 -- (replica_id, path, value)
local RemoteSetValues = Remote.New("ReplicaSetValues")     -- (replica_id, path, values)
local RemoteTableInsert = Remote.New("ReplicaTableInsert") -- (replica_id, path, value, index)
local RemoteTableRemove = Remote.New("ReplicaTableRemove") -- (replica_id, path, index)
local RemoteWrite = Remote.New("ReplicaWrite")             -- (replica_id, fn_id, ...)
local RemoteSignal = Remote.New("ReplicaSignal")           -- (replica_id, ...)
local RemoteParent = Remote.New("ReplicaParent")           -- (replica_id, parent_id)
local RemoteCreate = Remote.New("ReplicaCreate")           -- (creation, root_id?) or ({creation, ...})
local RemoteBind = Remote.New("ReplicaBind")               -- (replica_id)
local RemoteDestroy = Remote.New("ReplicaDestroy")         -- (replica_id)
local RemoteSignalUnreliable = Remote.New("ReplicaSignalUnreliable", true)   -- (replica_id, ...)

local WriteLibCache: {[ModuleScript]: {[string | number]: {Name: string, Id: number, fn: (...any) -> (...any)}}} = {}
local ReplicationFlag = false

local function LoadWriteLib(module: ModuleScript)

	local write_lib = WriteLibCache[module]

	if write_lib ~= nil then
		return write_lib -- WriteLib module was previously loaded
	end

	local loaded_module = require(module)

	local function_list = {} -- fn_id = {fn_name, fn}

	for key, value in pairs(loaded_module) do
		table.insert(function_list, {key, value})
	end

	table.sort(function_list, function(item1, item2)
		return item1[1] < item2[1] -- Sort functions by their names - this creates a consistent indexing on server and client-side
	end)

	write_lib = {} -- {["fn_name" | fn_id] = {Id = fn_id, fn = fn}, ...}

	for fn_id, fn_entry in ipairs(function_list) do
		local entry_table = {Name = fn_entry[1], Id = fn_id, fn = fn_entry[2]}
		write_lib[fn_entry[1]] = entry_table
		write_lib[fn_id] = entry_table
	end

	WriteLibCache[module] = write_lib

	return write_lib

end

----- Public -----

export type Replica = {
	Tags: {[any]: any},
	Data: {[any]: any},
	Id: number,
	Token: string,
	Parent: Replica?,
	Children: {[Replica]: boolean?},
	BoundInstance: Instance?,
	OnClientEvent: {Connect: (self: any, listener: (...any) -> ()) -> ({Disconnect: (self: any) -> ()})},
	Maid: typeof(Maid),

	OnSet: (self: any, path: {}, listener: () -> ()) -> (Signal.Connection),
	OnWrite: (self: any, function_name: string, listener: (...any) -> ()) -> (Signal.Connection),
	OnChange: (self: any, listener: (action: "Set" | "SetValues" | "TableInsert" | "TableRemove", path: {any}, param1: any, param2: any?) -> ()) -> (Signal.Connection),
	GetChild: (self: any, token: string) -> (Replica?),
	FireServer: (self: any, ...any) -> (),
	UFireServer: (self: any, ...any) -> (),
	Identify: (self: any) -> (string),
	IsActive: (self: any) -> (boolean),
}

local FreeRunnerThread

--[[
	Yield-safe coroutine reusing by stravant;
	Sources:
	https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063
	https://gist.github.com/stravant/b75a322e0919d60dde8a0316d1f09d2f
--]]

local function AcquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquired_runner_thread = FreeRunnerThread
	FreeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	FreeRunnerThread = acquired_runner_thread
end

local function RunEventHandlerInFreeThread(...)
	AcquireRunnerThreadAndCallEventHandler(...)
	while true do
		AcquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Replica = {
	IsReady = false,
	OnLocalReady = Signal.New(),
}
Replica.__index = Replica

local function ReplicaNew(id: number, self_creation: {}) -- self_creation = {token, tags, data, parent_id, write_module}
	
	local write_lib = nil
	if self_creation[5] ~= nil then
		write_lib = LoadWriteLib(self_creation[5])
	end
	
	local token = self_creation[1]
	local parent = BindReplicas[self_creation[4]] or Replicas[self_creation[4]]
	
	local self = setmetatable({
		Tags = self_creation[2],
		Data = self_creation[3],
		Id = id,
		Token = token,
		Parent = parent,
		Children = {},
		BoundInstance = nil,
		OnClientEvent = Signal.New(),
		Maid = Maid.New(MAID_LOCK),

		self_creation = self_creation,

		write_lib = write_lib,
		
		set_listeners = {}, -- {[key]: Signal}
		write_listeners = {}, -- {[key]: Signal}
		changed_listeners = Signal.New(),
		
	}, Replica)
	
	if parent ~= nil then
		parent.Children[self] = true
	end
	
	return self
	
end

function Replica.RequestData()
	
	if DataRequestStarted == true then
		return
	end
	
	DataRequestStarted = true
	
	task.spawn(function()

		RemoteRequestData:FireServer()
		
		while task.wait(REQUEST_DATA_REPEAT) do
			if Replica.IsReady == true then
				break
			end
			RemoteRequestData:FireServer()
		end
		
	end)
	
end
	
function Replica.OnNew(token: string, listener: (replica: Replica) -> ()): Signal.Connection
	
	if type(token) ~= "string" then
		error(`[{script.Name}]: "token" must be a string`)
	end
	
	local listeners = NewReplicaListeners[token]
	
	if listeners == nil then
		listeners = Signal.New()
		NewReplicaListeners[token] = listeners
	end
	
	local existing_replicas = TokenReplicas[token]
	
	local connection = listeners:Connect(listener)
	
	if existing_replicas ~= nil then

		local announce = {}
		for replica in pairs(existing_replicas) do
			announce[replica] = true
		end

		task.defer(function()
			for replica in pairs(announce) do
				if connection.IsConnected ~= true then
					break
				end
				if not FreeRunnerThread then
					FreeRunnerThread = coroutine.create(RunEventHandlerInFreeThread)
				end
				task.spawn(FreeRunnerThread, listener, replica)
			end
		end)

	end
	
	return connection
	
end

function Replica.FromId(id: number): typeof(Replica)?
	return Replicas[id]
end

function Replica.Test()
	return {
		TokenReplicas = TokenReplicas, -- [token] = {[replica] = true, ...}
		Replicas = Replicas, -- [id] = Replica, ...
		BindReplicas = BindReplicas, -- [id] = Replica, ... -- Unannounced Replicas waiting for their binds to stream in
		BindInstances = BindInstances, -- [id] = Instance, ...
	}
end

function Replica:OnSet(path: {}, listener: () -> ()): Signal.Connection
	local path_key = table.concat(path, ".")
	local listeners = self.set_listeners[path_key]
	if listeners == nil then
		listeners = Signal.New()
		self.set_listeners[path_key] = listeners
	end
	
	return listeners:Connect(listener)
end

function Replica:OnWrite(function_name: string, listener: (...any) -> ()): Signal.Connection
	local listeners = self.write_listeners[function_name]
	if listeners == nil then
		listeners = Signal.New()
		self.write_listeners[function_name] = listeners
	end
	
	return listeners:Connect(listener)
end

function Replica:OnChange(listener: (action: "Set" | "SetValues" | "TableInsert" | "TableRemove", path: {any}, param1: any, param2: any?) -> ()): Signal.Connection
	return self.changed_listeners:Connect(listener)
end

function Replica:GetChild(token: string): Replica?
	if type(token) ~= "string" then
		error(`[{script.Name}]: "token" must be a string`)
	end
	for replica in pairs(self.Children) do
		if replica.Token == token then
			return replica
		end
	end
	return nil
end

function Replica:FireServer(...)
	RemoteSignal:FireServer(self.Id, ...)
end

function Replica:UFireServer(...)
	RemoteSignalUnreliable:FireServer(self.Id, ...)
end

function Replica:Identify(): string
	local tag_string = ""
	local first_tag = true
	for key, value in pairs(self.Tags) do
		tag_string ..= `{if first_tag == true then "" else ";"}{tostring(key)}={tostring(value)}`
		first_tag = false
	end
	return `[Id:{self.Id};Token:{self.Token};Tags:[{tag_string}]]`
end

function Replica:IsActive(): boolean
	return self.Maid:IsActive()
end

function Replica:Set(path: {string}, value: any)
	
	if ReplicationFlag ~= true then
		error(`[{script.Name}]: "Set()" can't be called outside of WriteLibs client-side`)
	end
	
	-- Apply local change:
	
	local pointer = self.Data
	for i = 1, #path - 1 do
		pointer = pointer[path[i]]
	end
	local last_key = path[#path]
	local old_value = pointer[last_key]
	pointer[last_key] = value
	
	-- Firing signals:
	
	if next(self.set_listeners) ~= nil then
		local listeners = self.set_listeners[table.concat(path, ".")]
		if listeners ~= nil then
			listeners:Fire(value, old_value)
		end
	end
	self.changed_listeners:Fire("Set", path, value, old_value)
	
end

function Replica:SetValues(path: {string}, values: {[string]: any})
	
	if ReplicationFlag ~= true then
		error(`[{script.Name}]: "SetValues()" can't be called outside of WriteLibs client-side`)
	end
	
	-- Apply local change:

	local pointer = self.Data
	for _, key in ipairs(path) do
		pointer = pointer[key]
	end
	for key, value in pairs(values) do
		pointer[key] = value
	end
	
	-- Firing signals:

	self.changed_listeners:Fire("SetValues", path, values)
	
end

function Replica:TableInsert(path: {string}, value: any, index: number?): number
	
	if ReplicationFlag ~= true then
		error(`[{script.Name}]: "TableInsert()" can't be called outside of WriteLibs client-side`)
	end
	
	-- Apply local change:

	local pointer = self.Data
	for _, key in ipairs(path) do
		pointer = pointer[key]
	end
	if index ~= nil then
		table.insert(pointer, index, value)
	else
		table.insert(pointer, value)
		index = #pointer
	end
	
	-- Firing signals:

	self.changed_listeners:Fire("TableInsert", path, value, index)
	
	return (index :: number)

end

function Replica:TableRemove(path: {string}, index: number): any
	
	if ReplicationFlag ~= true then
		error(`[{script.Name}]: "TableRemove()" can't be called outside of WriteLibs client-side`)
	end
	
	-- Apply local change:

	local pointer = self.Data
	for _, key in ipairs(path) do
		pointer = pointer[key]
	end
	local removed_value = table.remove(pointer, index)
	
	-- Firing signals:

	self.changed_listeners:Fire("TableRemove", path, removed_value, index)
	
	return removed_value
	
end

function Replica:Write(function_name: string, ...): ...any
	
	if ReplicationFlag ~= true then
		error(`[{script.Name}]: "Write()" can't be called outside of WriteLibs client-side`)
	end
	
	-- Apply local change:
	
	local write_lib_entry = self.write_lib[function_name]
	local return_params = table.pack(write_lib_entry.fn(self, ...))
	
	-- Firing signals:
	
	local listeners = self.write_listeners[function_name]
	if listeners ~= nil then
		listeners:Fire(...)
	end
	
	return table.unpack(return_params)
	
end

local function DestroyReplica(replica, is_depth_call)
	-- Scan children replicas:
	for child in pairs(replica.Children) do
		DestroyReplica(child, true)
	end

	if is_depth_call ~= true then
		if replica.Parent ~= nil then
			replica.Parent.Children[replica] = nil
		end
	end

	local id = replica.Id

	-- Clear replica references:
	local token_replicas = TokenReplicas[replica.Token]
	if token_replicas ~= nil then
		token_replicas[replica] = nil
	end
	if Replicas[id] == replica then
		Replicas[id] = nil
	end
	if BindReplicas[id] == replica then
		BindReplicas[id] = nil
	end
	-- Cleanup:
	replica.Maid:Unlock(MAID_LOCK)
	replica.Maid:Cleanup()
	-- Bind cleanup:
	replica.BoundInstance = nil
end

local function ReplicaToBindBuffer(replica, is_depth_call)

	-- Copy replica group:

	local copy_replica = ReplicaNew(replica.Id, replica.self_creation)
	BindReplicas[replica.Id] = copy_replica
	
	for group_replica in pairs(replica.Children) do
		ReplicaToBindBuffer(group_replica, true)
	end

	-- Destroy original:
	
	if is_depth_call ~= true then
		DestroyReplica(replica)
	end
	
	return copy_replica

end

local function ReplicaFromBindBuffer(replica, announce_buffer)
	
	local top_call = false
	
	if announce_buffer == nil then
		top_call = true
		announce_buffer = {}
	end
	
	BindReplicas[replica.Id] = nil
	
	local token = replica.Token
	local token_replicas = TokenReplicas[token]

	if token_replicas == nil then
		token_replicas = {}
		TokenReplicas[token] = token_replicas
	end

	token_replicas[replica] = true
	Replicas[replica.Id] = replica
	
	table.insert(announce_buffer, replica)
	
	for group_replica in pairs(replica.Children) do
		ReplicaFromBindBuffer(group_replica, announce_buffer)
	end
	
	if top_call == true then
		for _, replica in ipairs(announce_buffer) do
			local listeners = NewReplicaListeners[replica.Token]
			if listeners ~= nil then
				listeners:Fire(replica)
			end
		end
	end
	
end

local function CreationScan(nested_creation, iterator, parent_id)
	local entries = nested_creation[parent_id]
	if entries ~= nil then
		
		table.sort(entries, function(a, b)
			return a.Id < b.Id
		end)
		
		for _, entry in ipairs(entries) do
			iterator(entry.Id, entry.SelfCreation)
			CreationScan(nested_creation, iterator, entry.Id)
		end
		
	end
end

local function BreadthCreationSort(creation: {}, root_id: number?, iterator: (Id: number, SelfCreation: {}) -> ())
	
	-- self_creation = {token, tags, data, parent_id, write_module}
	local top_creation = {} -- {Id = id, SelfCreation = self_creation}, ...
	local nested_creation = {} -- [parent_id] = {{Id = id, SelfCreation = self_creation}, ...}, ...
	local error_creation = {} -- {Id = id, SelfCreation = self_creation}, ... -- Missing parents
	
	if type(creation[1]) == "table" then -- creation pack {creation, ...}
		
		for _, packed_creation in ipairs(creation) do
			
			for string_id, self_creation in pairs(packed_creation) do
				local entry = {Id = tonumber(string_id), SelfCreation = self_creation}
				local parent_id = self_creation[4]
				if parent_id == 0 or entry.Id == root_id then
					table.insert(top_creation, entry)
				elseif packed_creation[tostring(parent_id)] ~= nil then
					local entries = nested_creation[parent_id]
					if entries == nil then
						entries = {}
						nested_creation[parent_id] = entries
					end
					table.insert(entries, entry)
				else
					table.insert(error_creation, entry)
				end
			end
			
		end
		
	else
		
		for string_id, self_creation in pairs(creation) do
			local entry = {Id = tonumber(string_id), SelfCreation = self_creation}
			local parent_id = self_creation[4]
			if parent_id == 0 or entry.Id == root_id then
				table.insert(top_creation, entry)
			elseif creation[tostring(parent_id)] ~= nil then
				local entries = nested_creation[parent_id]
				if entries == nil then
					entries = {}
					nested_creation[parent_id] = entries
				end
				table.insert(entries, entry)
			else
				table.insert(error_creation, entry)
			end
		end
		
	end
	
	table.sort(top_creation, function(a, b)
		return a.Id < b.Id
	end)
	
	local result = {}
	
	for _, entry in ipairs(top_creation) do
		iterator(entry.Id, entry.SelfCreation)
		CreationScan(nested_creation, iterator, entry.Id)
	end
	
	if #error_creation ~= 0 then -- An error occurred while replicating a replica group.
		
		local msg = `[{script.Name}]: GROUP REPLICATION ERROR - Missing parents for:\n`
		
		for i = 1, math.min(#error_creation, 50) do
			local entry = error_creation[i]
			local self_creation = entry.SelfCreation
			local tag_string = ""
			local first_tag = true
			for key, value in pairs(self_creation[2]) do
				tag_string ..= `{if first_tag == true then "" else ";"}{tostring(key)}={tostring(value)}`
				first_tag = false
			end
			msg ..= `[Id:{entry.Id};ParentId:{self_creation[4]};Token:{self_creation[1]};Tags:[{tag_string}]]\n`
		end
		
		if #error_creation > 50 then
			msg ..= `(hiding {50 - #error_creation} more)\n`
		end
		
		msg ..= "Traceback:\n" .. debug.traceback()
		
		warn(msg)
		
	end
	
	return result
	
end

local function GetInternalReplica(id)
	local replica = Replicas[id] or BindReplicas[id]
	if replica == nil then
		error(`[{script.Name}]: Received update for missing replica [Id:{id}]`)
	end
	return replica
end

----- Init -----

RemoteRequestData.OnClientEvent:Connect(function()
	
	if Replica.IsReady == true then
		return
	end
	
	Replica.IsReady = true
	print(`[{script.Name}]: Initial data received`)
	Replica.OnLocalReady:Fire()
	
end)

RemoteSet.OnClientEvent:Connect(function(id: number, path: {}, value: any)
	local replica = GetInternalReplica(id)
	ReplicationFlag = true
	local success, msg = pcall(replica.Set, replica, path, value)
	ReplicationFlag = false
	if success ~= true then
		error(`[{script.Name}]: Error while updating replica:\n{replica:Identify()}\n` .. msg)
	end
end)

RemoteSetValues.OnClientEvent:Connect(function(id: number, path: {}, values: {})
	local replica = GetInternalReplica(id)
	ReplicationFlag = true
	local success, msg = pcall(replica.SetValues, replica, path, values)
	ReplicationFlag = false
	if success ~= true then
		error(`[{script.Name}]: Error while updating replica:\n{replica:Identify()}\n` .. msg)
	end
end)

RemoteTableInsert.OnClientEvent:Connect(function(id: number, path: {}, value: any, index: number?)
	local replica = GetInternalReplica(id)
	ReplicationFlag = true
	local success, msg = pcall(replica.TableInsert, replica, path, value, index)
	ReplicationFlag = false
	if success ~= true then
		error(`[{script.Name}]: Error while updating replica:\n{replica:Identify()}\n` .. msg)
	end
end)

RemoteTableRemove.OnClientEvent:Connect(function(id: number, path: {}, index: number)
	local replica = GetInternalReplica(id)
	ReplicationFlag = true
	local success, msg = pcall(replica.TableRemove, replica, path, index)
	ReplicationFlag = false
	if success ~= true then
		error(`[{script.Name}]: Error while updating replica:\n{replica:Identify()}\n` .. msg)
	end
end)

RemoteWrite.OnClientEvent:Connect(function(id: number, fn_id: number, ...)
	local replica = GetInternalReplica(id)
	local fn_name = replica.write_lib[fn_id].Name
	ReplicationFlag = true
	local success, msg = pcall(replica.Write, replica, fn_name, ...)
	ReplicationFlag = false
	if success ~= true then
		error(`[{script.Name}]: Error while updating replica:\n{replica:Identify()}\n` .. msg)
	end
end)

local function RemoteSignalHandle(id: number, ...)
	local replica = GetInternalReplica(id)
	replica.OnClientEvent:Fire(...)
end

RemoteSignal.OnClientEvent:Connect(RemoteSignalHandle)
RemoteSignalUnreliable.OnClientEvent:Connect(RemoteSignalHandle)

RemoteParent.OnClientEvent:Connect(function(id: number, parent_id: number)
	
	local replica = GetInternalReplica(id)
	local old_parent = replica.Parent
	local new_parent = GetInternalReplica(parent_id)
	
	old_parent.Children[replica] = nil
	new_parent.Children[replica] = true
	replica.Parent = new_parent
	replica.self_creation[4] = parent_id
	
	if BindReplicas[old_parent.Id] ~= nil and Replicas[parent_id] ~= nil then
		-- Replica streaming in:
		ReplicaFromBindBuffer(replica)
	elseif Replicas[old_parent.Id] ~= nil and BindReplicas[parent_id] ~= nil then
		-- Replica streaming out:
		ReplicaToBindBuffer(replica)
	end
	
end)

RemoteCreate.OnClientEvent:Connect(function(creation: {}, root_id: number?) -- (creation) or ({creation, ...})
	
	local announce_buffer = {} -- {replica, ...} -- Announce these
	
	BreadthCreationSort(creation, root_id, function(id: number, self_creation: {}) -- self_creation = {token, tags, data, parent_id, write_module}
		
		local parent_id = self_creation[4]
		local replica = ReplicaNew(id, self_creation)
		local is_bind_buffered = false
		
		if parent_id == 0 then -- Top replica
			
			if replica.Tags[BIND_TAG] == true then
				local bound_instance = BindInstances[id]
				replica.BoundInstance = bound_instance
				
				if bound_instance == nil then
					is_bind_buffered = true
				end
			end
			
		elseif BindReplicas[parent_id] ~= nil then
			
			is_bind_buffered = true
			
		end
		
		if is_bind_buffered == true then
			
			BindReplicas[id] = replica
			
		else
			
			local token = replica.Token
			local token_replicas = TokenReplicas[token]

			if token_replicas == nil then
				token_replicas = {}
				TokenReplicas[token] = token_replicas
			end

			token_replicas[replica] = true
			Replicas[id] = replica
			
			table.insert(announce_buffer, replica)
			
		end
		
	end)
	
	for _, replica in ipairs(announce_buffer) do
		local listeners = NewReplicaListeners[replica.Token]
		if listeners ~= nil then
			listeners:Fire(replica)
		end
	end

end)

RemoteBind.OnClientEvent:Connect(function(id: number)
	
	local replica = GetInternalReplica(id)
	replica.Tags[BIND_TAG] = true
	
	local bound_instance = BindInstances[id]
	replica.BoundInstance = bound_instance
	
	if bound_instance == nil then
		ReplicaToBindBuffer(replica)
	end
	
end)

RemoteDestroy.OnClientEvent:Connect(function(id: number)
	local replica = GetInternalReplica(id)
	DestroyReplica(replica)
end)

-- Replica bind system using CollectionService:

local function OnBindInstanceAdded(instance: NumberValue)
	
	local id = instance.Value
	local bound_instance = instance.Parent
	BindInstances[id] = bound_instance
	
	local replica = BindReplicas[id]
	
	if replica ~= nil then
		replica.BoundInstance = bound_instance
		ReplicaFromBindBuffer(replica)
	end
	
end

local function OnBindInstanceRemoved(instance: NumberValue)
	
	local id = instance.Value
	BindInstances[id] = nil
	
	local replica = Replicas[id]
	
	if replica ~= nil then
		ReplicaToBindBuffer(replica)
	end
	
end

CollectionService:GetInstanceAddedSignal(CS_TAG):Connect(function(instance: NumberValue)
	if instance:IsA("NumberValue") == true then
		OnBindInstanceAdded(instance)
	end
end)

CollectionService:GetInstanceRemovedSignal(CS_TAG):Connect(function(instance: NumberValue)
	if instance:IsA("NumberValue") == true then
		OnBindInstanceRemoved(instance)
	end
end)

for _, instance: NumberValue in pairs(CollectionService:GetTagged(CS_TAG)) do
	if instance:IsA("NumberValue") == true then
		OnBindInstanceAdded(instance)
	end
end

return Replica