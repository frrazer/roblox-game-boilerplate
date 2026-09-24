--!strict

type Bucket = {
	Tokens: number,
	UpdatedAt: number,
}

local RateLimit = {}
RateLimit.__index = RateLimit

function RateLimit.new(count: number, window: number)
	assert(count >= 1 and count % 1 == 0, "RateLimit count must be a positive integer")
	assert(window > 0, "RateLimit window must be positive")
	return setmetatable({
		Count = count,
		Window = window,
		_buckets = {} :: { [any]: Bucket },
	}, RateLimit)
end

function RateLimit.Allow(self: RateLimit, key: any): boolean
	local now = os.clock()
	local bucket = self._buckets[key]
	if not bucket then
		bucket = { Tokens = self.Count, UpdatedAt = now }
		self._buckets[key] = bucket
	end
	bucket.Tokens = math.min(self.Count, bucket.Tokens + (now - bucket.UpdatedAt) * self.Count / self.Window)
	bucket.UpdatedAt = now
	if bucket.Tokens < 1 then
		return false
	end
	bucket.Tokens -= 1
	return true
end

function RateLimit.Remove(self: RateLimit, key: any)
	self._buckets[key] = nil
end

export type RateLimit = typeof(RateLimit.new(1, 1))

return RateLimit
