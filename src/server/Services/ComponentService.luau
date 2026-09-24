--!strict

local ComponentService = { Name = "ComponentService" }
local factories: { (services: { [string]: any }) -> any } = {}
local registry: { [string]: any } = {}
local components: { any } = {}

function ComponentService.Init(_self: any, services: { [string]: any })
	registry = services
end

function ComponentService.Start(_self: any)
	for _, create in factories do
		table.insert(components, create(registry))
	end
end

function ComponentService.Destroy(_self: any)
	for index = #components, 1, -1 do
		components[index]:Destroy()
	end
	table.clear(components)
end

return ComponentService
