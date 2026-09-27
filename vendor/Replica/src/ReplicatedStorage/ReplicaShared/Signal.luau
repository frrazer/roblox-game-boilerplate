--[[
MAD STUDIO

-[Signal]---------------------------------------
		
	WARNING: Always assume undefined listener invocation order for [Signal] class; Current implementation invokes
		In the backwards order of connection time.

	Functions:
			
		Signal.New() --> [Signal]
		
	Methods [Signal]:
	
		Signal:Connect(listener) --> [Connection] listener(...)
			listener              [function]
			
		Signal:Fire(...)
		
		Signal:Wait()
		
		Signal:FireUntil(continue_callback, ...)
			continue_callback   [function] () --> continue [bool] (Stops firing if "true" is not returned)
		
	Methods [Connection]:
	
		Connection:Disconnect()
	
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

----- Public -----

export type Connection = {
	Disconnect: (self: Connection) -> (),
	IsConnected: boolean,
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	FireUntil: (self: Signal<T...>, continue_callback: () -> boolean, T...) -> (),
}

local Connection = {}
Connection.__index = Connection

local Signal = {}
Signal.__index = Signal

function Connection:Disconnect()

	if self.IsConnected == false then
		return
	end
	
	local signal = self.signal
	self.IsConnected = false
	
	if signal.head == self then
		signal.head = self.next
	else
		local prev = signal.head
		while prev ~= nil and prev.next ~= self do
			prev = prev.next
		end
		if prev ~= nil then
			prev.next = self.next
		end
	end

end

function Signal.New<T...>(): Signal<T...>

	local self = {
		head = nil,
	}
	setmetatable(self, Signal)

	return self

end

function Signal:Connect(listener: (...any) -> ())
	
	if type(listener) ~= "function" then
		error(`[{script.Name}]: \"listener\" must be a function; Received {typeof(listener)}`)
	end

	local connection = {
		listener = listener,
		signal = self,
		next = self.head,
		IsConnected = true,
	}
	setmetatable(connection, Connection)

	self.head = connection

	return connection

end

function Signal:Fire(...)
	local item = self.head
	while item ~= nil do
		if item.IsConnected == true then
			if not FreeRunnerThread then
				FreeRunnerThread = coroutine.create(RunEventHandlerInFreeThread)
			end
			task.spawn(FreeRunnerThread :: thread, item.listener, ...)
		end
		item = item.next
	end
end

function Signal:Wait()
	local co = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(co, ...)
	end)
	return coroutine.yield()
end

function Signal:FireUntil(continue_callback: () -> boolean, ...)
	
	if type(continue_callback) ~= "function" then
		error(`[{script.Name}]: \"continue_callback\" must be a function; Received {typeof(continue_callback)}`)
	end
	
	local items = {}
	local args = table.pack(...)
	
	local item = self.head
	while item ~= nil do
		table.insert(items, item)
		item = item.next
	end
	
	task.spawn(function()
		for _, check_item in ipairs(items) do
			if check_item.IsConnected == true then
				check_item.listener(table.unpack(args))
				if continue_callback() ~= true then
					return
				end
			end
		end
	end)
	
end

return table.freeze({
	New = Signal.New,
})