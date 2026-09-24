--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
}

return Packets
