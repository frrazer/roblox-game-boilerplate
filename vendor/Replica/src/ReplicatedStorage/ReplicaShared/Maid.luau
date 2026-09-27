--!strict
--[[
MAD STUDIO

-[Maid]---------------------------------------

	WARNING: Order of cleanup is undefined!
	
	Functions:
	
		Maid.New(key [any]) --> [Maid]
			-- If "key" is passed, ":Cleanup()" method will be locked
	
	Methods [Maid]:
	
		Maid:IsActive() --> [bool] -- Returns true if maid was not cleaned up
		Maid:Add(any) --> maid_token [MaidToken]
		Maid:Cleanup(...) -- Added functions will receive the tuple arguments;
			After :Cleanup() is called, all successive objects added to the maid will be instantly cleaned up!
			
		Maid:Unlock(key [any]) -- Unlocks ":Cleanup()"
		
	Methods [MaidToken]:
	
		-- Passing a [MaidToken] to "Maid:Add()" will call "MaidToken:Destroy()" on maid cleanup!
	
		MaidToken:Destroy() -- Dissociates object from maid; Cleanup will not be performed
		MaidToken:Cleanup(...) -- Performs cleanup for this object
	
--]]

----- Private -----

local FreeRunnerThread: thread?

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

local function Cleanup(object : any, ...)
	
	local object_type = typeof(object)
	
	if object_type == "function" then
		object(...)
	elseif object_type == "RBXScriptConnection" then
		object:Disconnect()
	elseif object_type == "Instance" then
		object:Destroy()
	elseif object_type == "table" then
		if type(object.Destroy) == "function" then
			object:Destroy()
		elseif type(object.Disconnect) == "function" then
			object:Disconnect()
		end
	end
	
end

local function CleanupInThread(...)
	if not FreeRunnerThread then
		FreeRunnerThread = coroutine.create(RunEventHandlerInFreeThread)
	end
	task.spawn(assert(FreeRunnerThread), Cleanup, ...)
end

----- Public -----

--[[
export type MaidToken = {
	Destroy: (self: MaidToken) -> (),
	Cleanup: (self: MaidToken, ...any) -> (),
}

export type Maid = {
	IsActive: (self: Maid) -> (boolean),
	Add: (self: Maid, object: any) -> MaidToken,
	Cleanup: (...any) -> (),
}
--]]

local MaidToken = {}
MaidToken.__index = MaidToken

function MaidToken.New(maid, object : any)
	
	local self = {
		maid = maid,
		object = object,
	}
	
	setmetatable(self, MaidToken)
	
	return self
	
end

function MaidToken:Destroy()
	self.maid.tokens[self] = nil
end

function MaidToken:Cleanup(...)
	
	if self.object == nil then
		return
	end
	
	self.maid.tokens[self] = nil
	CleanupInThread(self.object, ...)
	self.object = nil

end

local Maid = {}
Maid.__index = Maid

function Maid.New(key: any)
	
	local self = {
		tokens = {}, -- [Token] = true, ...
		is_cleaned = false,
		key = key,
	}
	
	setmetatable(self, Maid)
	
	return self
	
end

function Maid:IsActive()
	return not self.is_cleaned
end

function Maid:Add(object: any)
	
	if self.is_cleaned == true then
		CleanupInThread(object)
	end
	
	local object_type = typeof(object)
	
	if object_type == "table" then
		if type(object.Destroy) ~= "function" and type(object.Disconnect) ~= "function" then
			error(`[{script.Name}]: Received table as cleanup object, but couldn't detect a :Destroy() or :Disconnect() method`)
		end
	elseif object_type ~= "function" and object_type ~= "RBXScriptConnection" and object_type ~= "Instance" then
		error(`[{script.Name}]: Cleanup of type \"{object_type}\" not supported`)
	end
	
	local token = MaidToken.New(self, object)
	self.tokens[token] = true
	
	return token
	
end

function Maid:Cleanup(...)
	
	if self.key ~= nil then
		error(`[{script.Name}]: "Cleanup()" is locked for this Maid`)
	end
	
	self.is_cleaned = true
	
	for token in pairs(self.tokens) do
		token:Cleanup(...)
	end
	
end

function Maid:Unlock(key: any)
	if self.key ~= nil and self.key ~= key then
		error(`[{script.Name}]: Invalid lock key`)
	end
	self.key = nil
end

return Maid