--!strict

export type Task = {
	Type: "Task",
	Spawn: (self: Task, func: (...any) -> (), ...any) -> thread,
	Defer: (self: Task, func: (...any) -> (), ...any) -> thread,
	Delay: (self: Task, duration: number, func: (...any) -> (), ...any) -> thread,
}

local Call, Thread
local Task = {} :: Task
local threads = {} :: { thread }

Task.Type = "Task"

function Task:Spawn(func, ...)
	return task.spawn(table.remove(threads) or task.spawn(Thread), func, ...)
end

function Task:Defer(func, ...)
	return task.defer(table.remove(threads) or task.spawn(Thread), func, ...)
end

function Task:Delay(duration, func, ...)
	return task.delay(duration, table.remove(threads) or task.spawn(Thread), func, ...)
end

function Call(func: (...any) -> (), ...)
	func(...)
	table.insert(threads, coroutine.running())
end

function Thread()
	while true do
		Call(coroutine.yield())
	end
end

return Task
