--!strict

export type Grant = (player: Player, services: { [string]: any }) -> boolean

local Products: { [number]: Grant } = {}

return Products
