--!strict

local ComponentController = { Name = "ComponentController" }
local factories: { (controllers: { [string]: any }) -> any } = {
	require(script.Parent.Parent.Components.Spinner),
}
local registry: { [string]: any } = {}
local components: { any } = {}

function ComponentController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
end

function ComponentController.Start(_self: any)
	for _, create in factories do
		table.insert(components, create(registry))
	end
end

function ComponentController.Destroy(_self: any)
	for index = #components, 1, -1 do
		components[index]:Destroy()
	end
	table.clear(components)
end

return ComponentController
