--!strict
--[[
MAD STUDIO

-[RateLimit]---------------------------------------
	Can be used to prevent RemoteEvent spamming; Player references are automatically removed as they leave
	
	Functions:
	
		RateLimit.New(rate, is_full_wait) --> [RateLimit]
			rate           [number] -- Events per second allowed; Excessive events are dropped
			is_full_wait   [bool] -- (Optional) If set to true, allows the next event to happen after the full rate period has passed
			
	Methods [RateLimit]:
	
		RateLimit:CheckRate(source) --> is_to_be_processed [bool] -- Whether event should be processed
			source   [any]
			
		RateLimit:CleanSource(source) -- Forgets about the source - must be called for any object that
			has been passed to RateLimit:CheckRate() after that object is no longer going to be used;
			Does not have to be called for Player instances!
			
		RateLimit:Cleanup() -- Forgets all sources
		
		RateLimit:Destroy() -- Make the RateLimit module forget about this RateLimit object
	
--]]

----- Private -----

local Players = game:GetService("Players")

local PlayerReference = {} -- {player = true}
local RateLimits = {} -- {rate_limit = true, ...}

----- Public -----

local RateLimit = {}
RateLimit.__index = RateLimit

function RateLimit.New(rate : number, is_full_wait : boolean?) --> [RateLimit]
	if rate <= 0 then
		error("[RateLimit]: Invalid rate")
	end

	local self = {
		sources = {},
		rate_period = 1 / rate,
		is_full_wait = is_full_wait == true,
	}
	setmetatable(self, RateLimit)

	RateLimits[self] = true

	return self
end

function RateLimit:CheckRate(source) : boolean --> is_to_be_processed [bool] -- Whether event should be processed
	
	local sources = self.sources
	local os_clock = os.clock()
	
	if source == nil then
		source = "nil"
	end
	
	local rate_time: number = sources[source]
	
	if rate_time ~= nil then
		if self.is_full_wait ~= true then
			rate_time = math.max(os_clock, rate_time + self.rate_period)
			if rate_time - os_clock < 1 then
				sources[source] = rate_time
				return true
			else
				return false
			end
		else
			if rate_time <= os_clock then
				sources[source] = os_clock + self.rate_period
				return true
			else
				return false
			end
		end
	else
		-- Preventing from remembering players that already left:
		if typeof(source) == "Instance" and source:IsA("Player")
			and PlayerReference[source] == nil then
			return false
		end
		sources[source] = os_clock + self.rate_period
		return true
	end
	
end

function RateLimit:CleanSource(source) -- Forgets about the source - must be called for any object that
	self.sources[source] = nil
end

function RateLimit:Cleanup() -- Forgets all sources
	self.sources = {}
end

function RateLimit:Destroy() -- Make the RateLimit module forget about this RateLimit object
	RateLimits[self] = nil
end

----- Init -----

for _, player in ipairs(Players:GetPlayers()) do
	PlayerReference[player] = true
end

Players.PlayerAdded:Connect(function(player)
	PlayerReference[player] = true
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerReference[player] = nil
	-- Automatic player reference cleanup:
	for rate_limit in pairs(RateLimits) do
		rate_limit.sources[player] = nil
	end
end)

return RateLimit