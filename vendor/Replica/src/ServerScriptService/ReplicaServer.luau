--[[
MAD STUDIO

-[Replica]---------------------------------------
	
	State replication with life cycle handling and individual client subscription control.
	
	WARNING: Avoid numeric tables with gaps & non string/numeric keys - They can't be replicated!
			
	Members:
	
		Replica.ReadyPlayers:        {[Player]: true}
		Replica.NewReadyPlayer:      Signal<Player>
		Replica.RemovingReadyPlayer: Signal<Player>
	
	Functions:
	
		Replica.Token(token: string): ReplicaToken -- Only one token object can be created for each unique "token: string"
	
		Replica.New(params): Replica
			params: {
					Token: ReplicaToken,
					-- Optional:
					Tags: {}?, -- Immutable dictionary meant for identifying the Replica (e.g. UserId = 2312310)
					Data: {}?, -- Initial replica state
					WriteLib: ModuleScript?,
				}
		
		Replica.FromId(id: number): Replica?
		
	Members [Replica]:
	
		Replica.Tags:          {} -- Secondary Replica identifiers; Can only be set on creation
		Replica.Data:          {} -- Table which is replicated; Can only be written to through setter methods server-side
		
		Replica.Id:            number -- Unique identifier
		Replica.Token:         string -- Primary Replica identifier
		
		Replica.Parent:        Replica?
		Replica.Children:      {[Replica]: true}
		
		Replica.BoundInstance: Instance?
		
		Replica.OnServerEvent: Signal<Player, ...>
		
		Replica.Maid:          Maid?
	
	Methods [Component]:
	
		-- (EXAMPLE) path: {"Players", "2312310", "Health"} -- A path defines a key branch within Replica.Data
	
		Replica:Set(path: {string | number}, value: any)
		Replica:SetValues(path: {string | number}, values: {[string]: any})
			
		Replica:TableInsert(path: {string | number}, value: any, index: number?): number (new index) -- Performs table.insert(path, value)
		Replica:TableRemove(path: {string | number}, index: number): any (removed value) -- Performs table.remove(path, index)
		
		Replica:Write(function_name: string, ...): ... -- Run WriteLib function with given parameters
		
		Replica:FireClient(player: Player, ...) -- Will not replicate to unsubscribed players
		Replica:FireAllClients(...) -- Will not replicate to unsubscribed players
		Replica:UFireClient(player: Player, ...) -- Same as "Replica:FireClient()", but using UnreliableRemoteEvent
		Replica:UFireAllClients(...) -- Same as "Replica:FireAllClients()", but using UnreliableRemoteEvent
		
		Replica:SetParent(replica: Replica) -- Replication will be inherited from parent replica; Replication and bind methods will be locked.
		
		Replica:BindToInstance(instance: Instance) -- Players who observe the instance stream in
			-- will be subscribed to this component; Observing the instance stream out
			-- will destroy the component for the observing player; Replicas should be bound
			-- to instances first and then ":Replicate()" or ":Subscribe()" should be called
			-- after. A replica can only be bound once.
			
		Replica:Replicate() -- Subscribes all existing and future players; ":Subscribe()" and ":Unsubscribe()" will become locked
		Replica:DontReplicate() -- Resets all previous subscription settings;
		Replica:Subscribe(player) -- Replicates to player; WILL NOT subscribe to players that are not ready & will throw a warning for trying to do so.
		Replica:Unsubscribe(player) -- Destroys Replica for player
		
		Replica:Identify(): string -- Debug

		Replica:IsActive(): boolean
		
		Replica:Destroy() -- Destroys replica and all of its descendants (Depth-first)
	
--]]

----- Dependencies -----

local ReplicaShared = game.ReplicatedStorage.ReplicaShared
local RateLimit = require(ReplicaShared.RateLimit)
local Remote = require(ReplicaShared.Remote)
local Signal = require(ReplicaShared.Signal)
local Maid = require(ReplicaShared.Maid)

----- Private -----

local BIND_TAG = "Bind"
local CS_TAG = "REPLICA" -- CollectionService tag
local REPLICATION_ALL = "ALL"
local MAID_LOCK = {}
local EMPTY_TABLE = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GlobalRateLimit = RateLimit.New(120)

local ReadyPlayers: {[Player]: boolean} = {}

local Replicas = {} -- {[id]: Replica}
local TopReplicas = {} -- {[Replica]: true} -- Replicas with active subscription settings
local ReplicationAllReplicas = {} -- {[Replica]: true} -- Replicas that had the method :Replicate() called on them
local SelectiveSubscriptions = {} -- {[Player]: {[replica]: true}}

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

local Index = 0

local WriteLibCache: {[ModuleScript]: {[string | number]: {Id: number, fn: (...any) -> (...any)}}} = {}
local WriteFlag = false
local Tokens: {[string]: boolean} = {}
local TokenValidate = {}

local BindValuePrefab = Instance.new("NumberValue")
BindValuePrefab.Name = "ReplicaBind"
CollectionService:AddTag(BindValuePrefab, CS_TAG)

local function IterateGroup(replica, fn) -- fn(replica)
	fn(replica)
	for child in pairs(replica.Children) do
		IterateGroup(child, fn)
	end
end

local function LoadWriteLib(module: ModuleScript)
	
	local write_lib = WriteLibCache[module]
	
	if write_lib ~= nil then
		return write_lib -- WriteLib module was previously loaded
	end
	
	if typeof(module) ~= "Instance" or module:IsA("ModuleScript") ~= true then
		error(`[{script.Name}]: "WriteLib" is not a ModuleScript`)
	elseif module:IsDescendantOf(ReplicatedStorage) == false then
		error(`[{script.Name}]: "WriteLib" module must be a descendant of ReplicatedStorage`)
	end

	local loaded_module = require(module)
	
	if type(loaded_module) ~= "table" then
		error(`[{script.Name}]: A "WriteLib" ModuleScript must return a table`)
	end

	local function_list = {} -- fn_id = {fn_name, fn}
	
	for key, value in pairs(loaded_module) do
		if type(key) ~= "string" then
			error(`[{script.Name}]: "WriteLib" table keys must be strings`)
		elseif type(value) ~= "function" then
			error(`[{script.Name}]: "WriteLib" table values must be functions`)
		end
		table.insert(function_list, {key, value})
	end

	table.sort(function_list, function(item1, item2)
		return item1[1] < item2[1] -- Sort functions by their names - this creates a consistent indexing on server and client-side
	end)

	write_lib = {} -- {["fn_name" | fn_id] = {Id = fn_id, fn = fn}, ...}

	for fn_id, fn_entry in ipairs(function_list) do
		local entry_table = {Id = fn_id, fn = fn_entry[2]}
		write_lib[fn_entry[1]] = entry_table
		write_lib[fn_id] = entry_table
	end

	WriteLibCache[module] = write_lib

	return write_lib
	
end

function GenerateCreation(replica)
	local replication = {}
	local creation = {}
	IterateGroup(replica, function(group_replica)
		local self_creation = group_replica.self_creation
		self_creation[4] = if group_replica.Parent == nil then 0 else group_replica.Parent.Id
		creation[tostring(group_replica.Id)] = self_creation
		group_replica.creation = creation
		group_replica.replication = replication
	end)
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
	OnServerEvent: {Connect: (self: any, listener: (Player, ...any) -> ()) -> ({Disconnect: (self: any) -> ()})},
	Maid: typeof(Maid),

	Set: (self: any, path: {string}, value: any) -> (),
	SetValues: (self: any, path: {string}, values: {[string]: any}) -> (),
	TableInsert: (self: any, path: {string}, value: any, index: number?) -> (number),
	TableRemove: (self: any, path: {string}, index: number) -> (any),
	Write: (self: any, function_name: string, ...any) -> (...any),
	FireClient: (self: any, player: Player, ...any) -> (),
	FireAllClients: (self: any, ...any) -> (),
	UFireClient: (self: any, player: Player, ...any) -> (),
	UFireAllClients: (self: any, ...any) -> (),
	SetParent: (self: any, new_parent: Replica) -> (),
	BindToInstance: (self: any, instance: Instance) -> (),
	Replicate: (self: any) -> (),
	DontReplicate: (self: any) -> (),
	Subscribe: (self: any, player: Player) -> (),
	Unsubscribe: (self: any, player: Player) -> (),
	Identify: (self: any) -> (string),
	IsActive: (self: any) -> (boolean),
	Destroy: (self: any) -> (),
}

local Replica = {
	ReadyPlayers = ReadyPlayers,
	NewReadyPlayer = Signal.New(),
	RemovingReadyPlayer = Signal.New(),
}
Replica.__index = Replica

local ReplicaToken = {}
ReplicaToken.__index = ReplicaToken

local LockedReplica = {}
LockedReplica.__index = LockedReplica

function Replica.Token(name: string)
	
	if type(name) ~= "string" then
		error(`[{script.Name}]: name must be a string`)
	end
	
	if Tokens[name] == true then
		error(`[{script.Name}]: Token "{name}" duplicate`)
	end
	
	Tokens[name] = true
	
	local self = setmetatable({
		Name = name,
	}, ReplicaToken)
	
	TokenValidate[self] = true
	
	return self
	
end

function Replica.New(params: {Token: typeof(ReplicaToken), Tags: {}?, Data: {}?, WriteLib: ModuleScript?}): Replica
	
	local token = params.Token
	local tags = params.Tags or {}
	local data = params.Data or {}
	local write_lib = nil
	
	if TokenValidate[token] == nil then
		error(`[{script.Name}]: "Token" is not valid ({tostring(token)})`)
	elseif type(tags) ~= "table" then
		error(`[{script.Name}]: "Tags" is not a table`)
	elseif type(data) ~= "table" then
		error(`[{script.Name}]: "Data" is not a table`)
	elseif tags[BIND_TAG] ~= nil then
		error(`[{script.Name}]: "Tags.{BIND_TAG}" key is reserved`)
	end
	
	if params.WriteLib ~= nil then
		write_lib = LoadWriteLib(params.WriteLib)
	end
	
	Index += 1
	
	local self = setmetatable({
		Tags = tags,
		Data = data,
		Id = Index,
		Token = token.Name,
		Parent = nil,
		Children = {},
		BoundInstance = nil,
		OnServerEvent = Signal.New(),
		Maid = Maid.New(MAID_LOCK),
		
		self_creation = {token.Name, tags, data, 0, params.WriteLib},
		creation = nil, -- ["replica_id"] = {token, tags, data, parent_id, write_lib}, ...	
		replication = nil, -- {REPLICATION_ALL = true} or {[Player] = true, ...}
		
		write_lib = write_lib,
		write_lib_module = params.WriteLib,
		bind_value = nil,
		
	}, Replica)
	
	Replicas[Index] = self
	
	return self
	
end

function Replica.FromId(id: number): Replica
	return Replicas[id]
end

function Replica.Test()
	return {
		Replicas = Replicas, -- [id] = Replica, ...
		TopReplicas = TopReplicas, -- [Replica] = true, ... -- Replicas with active subsciption settings
		ReplicationAllReplicas = ReplicationAllReplicas, -- [Replica] = true, ... -- Replicas that had the method :Replicate() called on them
		SelectiveSubscriptions = SelectiveSubscriptions, -- [Player] = {[replica] = true, ...}
	}
end

function Replica:Set(path: {string}, value: any)
	
	-- Apply local change:
	
	local pointer = self.Data
	for i = 1, #path - 1 do
		pointer = pointer[path[i]]
	end
	pointer[path[#path]] = value
	
	-- Replicate change:
	
	if WriteFlag == false then
		local self_id = self.Id
		if self.replication ~= nil then
			if self.replication[REPLICATION_ALL] == true then
				for player in pairs(ReadyPlayers) do
					RemoteSet:FireClient(player, self_id, path, value)
				end
			else
				for player in pairs(self.replication) do
					RemoteSet:FireClient(player, self_id, path, value)
				end
			end
		end
	end
	
end

function Replica:SetValues(path: {string}, values: {[string]: any})

	-- Apply local change:
	
	local pointer = self.Data
	for _, key in ipairs(path) do
		pointer = pointer[key]
	end
	for key, value in pairs(values) do
		pointer[key] = value
	end
	
	-- Replicate change:
	
	if WriteFlag == false then
		local self_id = self.Id
		if self.replication ~= nil then
			if self.replication[REPLICATION_ALL] == true then
				for player in pairs(ReadyPlayers) do
					RemoteSetValues:FireClient(player, self_id, path, values)
				end
			else
				for player in pairs(self.replication) do
					RemoteSetValues:FireClient(player, self_id, path, values)
				end
			end
		end
	end
	
end

function Replica:TableInsert(path: {string}, value: any, index: number?): number
	
	-- Apply local change:
	
	local pointer = self.Data
	for _, key in ipairs(path) do
		pointer = pointer[key]
	end
	if index ~= nil then
		table.insert(pointer, index, value)
	else
		table.insert(pointer, value)
	end
	
	-- Replicate change:
	
	if WriteFlag == false then
		local self_id = self.Id
		if self.replication ~= nil then
			if self.replication[REPLICATION_ALL] == true then
				for player in pairs(ReadyPlayers) do
					RemoteTableInsert:FireClient(player, self_id, path, value, index)
				end
			else
				for player in pairs(self.replication) do
					RemoteTableInsert:FireClient(player, self_id, path, value, index)
				end
			end
		end
	end
	
	return index or #pointer
	
end

function Replica:TableRemove(path: {string}, index: number): any
	
	-- Apply local change:
	
	local pointer = self.Data
	for _, key in ipairs(path) do
		pointer = pointer[key]
	end
	local removed_value = table.remove(pointer, index)
	
	-- Replicate change:
	
	if WriteFlag == false then
		local self_id = self.Id
		if self.replication ~= nil then
			if self.replication[REPLICATION_ALL] == true then
				for player in pairs(ReadyPlayers) do
					RemoteTableRemove:FireClient(player, self_id, path, index)
				end
			else
				for player in pairs(self.replication) do
					RemoteTableRemove:FireClient(player, self_id, path, index)
				end
			end
		end
	end
	
	return removed_value
	
end

function Replica:Write(function_name: string, ...): ...any
	
	local write_lib_entry = self.write_lib[function_name]
	
	if WriteFlag == true then -- Chained :Write()
		return write_lib_entry.fn(self, ...)
	end
	
	-- Apply local change:
	
	WriteFlag = true
	local return_params = table.pack(pcall(write_lib_entry.fn, self, ...))
	WriteFlag = false
	
	if return_params[1] ~= true then
		error(`[{script.Name}]: (WriteLib) ` .. tostring(return_params[2]))
	end
	
	table.remove(return_params, 1)
	
	-- Replicate change:
	
	local self_id = self.Id
	local fn_id = write_lib_entry.Id
	
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				RemoteWrite:FireClient(player, self_id, fn_id, ...)
			end
		else
			for player in pairs(self.replication) do
				RemoteWrite:FireClient(player, self_id, fn_id, ...)
			end
		end
	end
	
	return table.unpack(return_params)
	
end

function Replica:FireClient(player, ...)
	if self.replication ~= nil then
		if (self.replication[REPLICATION_ALL] == true and ReadyPlayers[player] == true) or self.replication[player] ~= nil then
			RemoteSignal:FireClient(player, self.Id, ...)
		end
	end
end

function Replica:FireAllClients(...)
	local self_id = self.Id
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				RemoteSignal:FireClient(player, self_id, ...)
			end
		else
			for player in pairs(self.replication) do
				RemoteSignal:FireClient(player, self_id, ...)
			end
		end
	end
end

function Replica:UFireClient(player, ...)
	if self.replication ~= nil then
		if (self.replication[REPLICATION_ALL] == true and ReadyPlayers[player] == true) or self.replication[player] ~= nil then
			RemoteSignalUnreliable:FireClient(player, self.Id, ...)
		end
	end
end

function Replica:UFireAllClients(...)
	local self_id = self.Id
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				RemoteSignalUnreliable:FireClient(player, self_id, ...)
			end
		else
			for player in pairs(self.replication) do
				RemoteSignalUnreliable:FireClient(player, self_id, ...)
			end
		end
	end
end

function Replica:SetParent(new_parent)
	
	if type(new_parent) ~= "table" or getmetatable(new_parent) ~= Replica then
		error(`[{script.Name}]: new_parent is not a Replica ({tostring(new_parent)})`)
	elseif Replicas[new_parent.Id] == nil then
		error(`[{script.Name}]: Can't set destroyed Replica as parent`)
	end
	
	-- Top Replica / Bind check:
	
	if TopReplicas[self] ~= nil then
		error(`[{script.Name}]: Can't change parent for top level Replica`)
	end
	
	if self.BoundInstance ~= nil then
		error(`[{script.Name}]: Can't change parent for bound Replica`)
	end
	
	-- Recursion check:
	
	local recursion_check = new_parent
	
	while recursion_check ~= nil do
		recursion_check = recursion_check.Parent
		if recursion_check == self then
			error(`[{script.Name}]: Can't set descendant Replica as parent`)
		end
	end
	
	-- Hierarchy:
	
	local old_parent = self.Parent
	
	if old_parent == new_parent then
		return
	end
	
	self.Parent = new_parent
	
	if old_parent ~= nil then
		old_parent.Children[self] = nil
	end
	
	new_parent.Children[self] = true
	
	-- Altering creation and replication tables:
	
	IterateGroup(self, function(group_replica)
		local string_id = tostring(group_replica.Id)
		if old_parent ~= nil and old_parent.creation ~= nil then
			old_parent.creation[string_id] = nil
		end
		if new_parent.creation ~= nil then
			local self_creation = group_replica.self_creation
			self_creation[4] = group_replica.Parent.Id
			new_parent.creation[string_id] = self_creation
		end
		group_replica.creation = new_parent.creation
		group_replica.replication = new_parent.replication
	end)
	
	-- Subscriptions:
	
	local self_id = self.Id
	local parent_id = new_parent.Id
	local parent_creation = new_parent.creation
	
	local old_subscriptions = EMPTY_TABLE
	
	if old_parent ~= nil and old_parent.replication ~= nil then
		if old_parent.replication[REPLICATION_ALL] == true then
			old_subscriptions = ReadyPlayers
		else
			old_subscriptions = old_parent.replication
		end
	end

	local new_subscriptions = EMPTY_TABLE
	
	if new_parent ~= nil and new_parent.replication ~= nil then
		if new_parent.replication[REPLICATION_ALL] == true then
			new_subscriptions = ReadyPlayers
		else
			new_subscriptions = new_parent.replication
		end
	end
	
	-- Informing clients who lost subscription to replica group:
	
	if old_parent ~= nil and old_parent.replication ~= nil then
		if new_parent.replication ~= old_parent.replication and new_subscriptions ~= ReadyPlayers then
			
			for player in pairs(old_subscriptions) do
				if new_subscriptions[player] == nil then
					RemoteDestroy:FireClient(player, self_id)
				end
			end
			
		end
	end
	
	-- Informing clients who gained subscription to replica group / who retained the subscription:
	
	if new_parent.replication ~= nil then
		
		local custom_creation
		
		for player in pairs(new_subscriptions) do
			
			if old_subscriptions[player] == true then
				RemoteParent:FireClient(player, self_id, parent_id) -- Subscription was retained
			else
				if custom_creation == nil then -- Generating custom_creation if at least one new subscription was made
					custom_creation = {}
					IterateGroup(self, function(group_replica)
						local string_id = tostring(group_replica.Id)
						custom_creation[string_id] = parent_creation[string_id]
					end)
				end
				RemoteCreate:FireClient(player, custom_creation, self_id)
			end
			
		end
		
	end
	
end

function Replica:BindToInstance(instance: Instance)
	
	if typeof(instance) ~= "Instance" then
		error(`[{script.Name}]: "instance" argument is not an Instance ({tostring(instance)})`)
	end
	
	if self.Parent ~= nil then
		error(`[{script.Name}]: Can't bind Replica parented to another Replica`)
	end
	
	if self.BoundInstance ~= nil then
		error(`[{script.Name}]: Can't change Replica bind to another Instance`)
	end
	
	if instance:IsA("Model") == true and (instance.ModelStreamingMode == Enum.ModelStreamingMode.Default or instance.ModelStreamingMode == Enum.ModelStreamingMode.Nonatomic) then
		warn(`[{script.Name}]: Bound Replica to a model that has improper "ModelStreamingMode" setup; Traceback:\n` .. debug.traceback())
	end
	
	local bind_value = BindValuePrefab:Clone()
	bind_value.Value = self.Id
	
	self.Tags[BIND_TAG] = true
	self.BoundInstance = instance
	self.bind_value = bind_value
	
	bind_value.Parent = instance
	
	local self_id = self.Id
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				RemoteBind:FireClient(player, self_id)
			end
		else
			for player in pairs(self.replication) do
				RemoteBind:FireClient(player, self_id)
			end
		end
	end
	
end

function Replica:Replicate()
	
	if self.Parent ~= nil then
		error(`[{script.Name}]: Can't selectively replicate Replica parented to another Replica`)
	end
	
	if self.creation == nil then
		GenerateCreation(self)
		TopReplicas[self] = true
	elseif self.replication[REPLICATION_ALL] == true then
		return
	end
	
	local creation = self.creation
	local replication = self.replication
	
	for player in pairs(ReadyPlayers) do
		if replication[player] == nil then
			RemoteCreate:FireClient(player, creation)
		else
			local selective_lookup = SelectiveSubscriptions[player]
			selective_lookup[self] = nil
		end
	end
	
	table.clear(replication)
	replication[REPLICATION_ALL] = true
	ReplicationAllReplicas[self] = true
	
end

function Replica:DontReplicate()
	
	if self.Parent ~= nil then
		error(`[{script.Name}]: Can't selectively replicate Replica parented to another Replica`)
	end
	
	local replication = self.replication
	
	if replication == nil or next(replication) == nil then
		return
	end
	
	ReplicationAllReplicas[self] = nil
	
	local self_id = self.Id
	
	if replication[REPLICATION_ALL] == true then
		for player in pairs(ReadyPlayers) do
			RemoteDestroy:FireClient(player, self_id)
		end
	else
		for player in pairs(replication) do
			RemoteDestroy:FireClient(player, self_id)
			SelectiveSubscriptions[player][self] = nil
		end
	end
	
	table.clear(replication)
	
end

function Replica:Subscribe(player: Player)
	
	if self.Parent ~= nil then
		error(`[{script.Name}]: Can't selectively replicate Replica parented to another Replica`)
	end
	
	if self.creation == nil then
		GenerateCreation(self)
		TopReplicas[self] = true
	elseif self.replication[REPLICATION_ALL] == true then
		error(`[{script.Name}]: "Subscribe()" is locked after calling "Replicate()"`)
	end
	
	if ReadyPlayers[player] == nil then
		warn(`[{script.Name}]: Called "Subscribe()" on a non-ready player; Traceback:\n` .. debug.traceback())
		return
	end
	
	local creation = self.creation
	local replication = self.replication
	
	if replication[player] ~= nil then
		return -- Already subscribed
	end
	
	replication[player] = true
	SelectiveSubscriptions[player][self] = true
	RemoteCreate:FireClient(player, creation)
	
end

function Replica:Unsubscribe(player: Player)
	
	if self.Parent ~= nil then
		error(`[{script.Name}]: Can't selectively replicate Replica parented to another Replica`)
	end
	
	local replication = self.replication
	
	if replication == nil then
		return
	end
	
	if replication[REPLICATION_ALL] == true then
		error(`[{script.Name}]: "Unsubscribe()" is locked after calling "Replicate()"`)
	end
	
	if replication[player] ~= nil then
		replication[player] = nil
		SelectiveSubscriptions[player][self] = nil
		RemoteDestroy:FireClient(player, self.Id)
	end
	
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

local function DestroyReplica(replica)
	-- Scan children replicas:
	for child in pairs(replica.Children) do
		DestroyReplica(child)
	end

	local id = replica.Id
	-- Clear replica entry:
	Replicas[id] = nil
	-- Cleanup:
	replica.Maid:Unlock(MAID_LOCK)
	replica.Maid:Cleanup()
	-- Bind cleanup:
	if replica.BoundInstance ~= nil then
		replica.BoundInstance = nil
		replica.bind_value:Destroy()
		replica.bind_value = nil
	end
	-- Remove creation data:
	if replica.creation ~= nil then
		replica.creation[tostring(id)] = nil
	end
	-- Swap metatables:
	setmetatable(replica, LockedReplica)
end

function Replica:Destroy()
	
	local self_id = self.Id
	
	if Replicas[self_id] == nil then
		return
	end
	
	local is_top = TopReplicas[self] == true
	
	-- Destroy replica for all clients who were replicated to:
	
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				RemoteDestroy:FireClient(player, self_id)
			end
		else
			for player in pairs(self.replication) do
				RemoteDestroy:FireClient(player, self_id)
				if is_top == true then
					SelectiveSubscriptions[player][self] = nil
				end
			end
		end
	end
	
	-- Clearing hierarchy:
	
	TopReplicas[self] = nil
	ReplicationAllReplicas[self] = nil
	
	if self.Parent ~= nil then
		self.Parent.Children[self] = nil
	end
	
	-- Recursive destruction:
	
	DestroyReplica(self)
	
end

----- Init -----

do -- Destroyed replica metatable:

	local keep_methods = {
		Identify = true,
		Destroy = true,
	}

	for name, fn in pairs(Replica) do
		if name ~= "__index" then
			if keep_methods[name] == true then
				LockedReplica[name] = fn
			else
				LockedReplica[name] = function(self)
					error(`[{script.Name}]: Tried to call method "{name}" for a destroyed replica; {self:Identify()}`)
				end
			end
		end
	end

end

-- New player data replication:

RemoteRequestData.OnServerEvent:Connect(function(player: Player)
	
	if ReadyPlayers[player] ~= nil and player:IsDescendantOf(Players) == true then
		return
	end
	
	-- Make the client create all replicas that are initially replicated to the client;
	-- Pack up and send initially replicated replicas:
	
	local creation = {}
	
	for replica in pairs(ReplicationAllReplicas) do
		table.insert(creation, replica.creation)
	end
	RemoteCreate:FireClient(player, creation)
	
	-- Let the client know that all replica data has been sent:
	RemoteRequestData:FireClient(player)
	
	-- Set player to active:
	ReadyPlayers[player] = true
	SelectiveSubscriptions[player] = {}
	Replica.NewReadyPlayer:Fire(player)
	
end)

-- Client-invoked replica signals:

local function RemoteSignalHandle(player: Player, id: number, ...)
	
	-- Missing player prevention, spam prevention and exploit prevention:
	if ReadyPlayers[player] == nil or GlobalRateLimit:CheckRate(player) == false
		or type(id) ~= "number" then
		return
	end

	local replica = Replicas[id]

	if replica ~= nil then
		if replica.replication ~= nil and (replica.replication[REPLICATION_ALL] == true or replica.replication[player] ~= nil) then
			replica.OnServerEvent:Fire(player, ...)
		end
	end
	
end

RemoteSignal.OnServerEvent:Connect(RemoteSignalHandle)
RemoteSignalUnreliable.OnServerEvent:Connect(RemoteSignalHandle)

-- Player leave handling:

Players.PlayerRemoving:Connect(function(player)
	
	if ReadyPlayers[player] == nil then
		return
	end
	
	-- Remove player from subscription settings:
	
	for replica in pairs(SelectiveSubscriptions[player]) do
		replica.replication[player] = nil
	end
	
	-- Remove player from ready players list:
	
	ReadyPlayers[player] = nil
	SelectiveSubscriptions[player] = nil
	Replica.RemovingReadyPlayer:Fire(player)
	
end)

return Replica