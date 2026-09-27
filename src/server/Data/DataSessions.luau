--!strict

local PlayerData = require(script.Parent.PlayerData)

type Signal = { Connect: (self: any, callback: () -> ()) -> any }
type Profile = {
	Data: PlayerData.Data,
	LastSavedData: PlayerData.Data,
	IsActive: (self: any) -> boolean,
	AddUserId: (self: any, userId: number) -> (),
	Reconcile: (self: any) -> (),
	EndSession: (self: any) -> (),
	Save: (self: any) -> (),
	OnSessionEnd: Signal,
	OnSave: Signal,
}
type Store = {
	StartSessionAsync: (self: any, key: string, options: { Cancel: () -> boolean }) -> Profile?,
}

local DataSessions = {}
DataSessions.__index = DataSessions

function DataSessions.new(store: Store, isPresent: (Player) -> boolean)
	return setmetatable({
		_store = store,
		_isPresent = isPresent,
		_profiles = {} :: { [Player]: Profile },
		_loading = {} :: { [Player]: boolean },
		_closed = false,
	}, DataSessions)
end

function DataSessions.Load(self: DataSessions, player: Player)
	if self._closed or self._loading[player] or self._profiles[player] or not self._isPresent(player) then
		return
	end
	self._loading[player] = true
	local ok, result = pcall(function()
		return self._store:StartSessionAsync(`Player_{player.UserId}`, {
			Cancel = function()
				return self._closed or not self._isPresent(player)
			end,
		})
	end)
	self._loading[player] = nil
	if not ok or result == nil then
		if not ok then
			warn(`[DataService] Load failed for {player.UserId}: {tostring(result)}`)
		end
		if not self._closed and self._isPresent(player) then
			player:Kick("Your data couldn't be loaded. Please rejoin.")
		end
		return
	end
	local profile = result :: Profile
	if self._closed or not self._isPresent(player) then
		profile:EndSession()
		return
	end
	if not PlayerData.Validate(profile.Data) then
		warn(`[DataService] Unsupported or invalid data for {player.UserId}; progress was not reset`)
		profile:EndSession()
		player:Kick("Your saved data couldn't be opened. Please try again later.")
		return
	end
	profile:AddUserId(player.UserId)
	PlayerData.Migrate(profile.Data)
	profile:Reconcile()
	profile.OnSave:Connect(function()
		profile.Data.LastSeenAt = os.time()
	end)
	profile.OnSessionEnd:Connect(function()
		if self._profiles[player] ~= profile then
			return
		end
		self._profiles[player] = nil
		if not self._closed and self._isPresent(player) then
			player:Kick("Your data session ended. Please rejoin.")
		end
	end)
	if not profile:IsActive() then
		player:Kick("Your data session ended. Please rejoin.")
		return
	end
	self._profiles[player] = profile
end

function DataSessions.GetData(self: DataSessions, player: Player): PlayerData.Data?
	local profile = self._profiles[player]
	if self._closed or not self._isPresent(player) or not profile or not profile:IsActive() then
		return nil
	end
	return profile.Data
end

function DataSessions.RequestSave(self: DataSessions, player: Player): boolean
	if not self:GetData(player) then
		return false
	end
	self._profiles[player]:Save()
	return true
end

function DataSessions.Release(self: DataSessions, player: Player)
	local profile = self._profiles[player]
	self._profiles[player] = nil
	if profile then
		profile:EndSession()
	end
end

function DataSessions.WaitForSave(self: DataSessions, player: Player, saved: (any) -> boolean): boolean
	local profile = self._profiles[player]
	if not profile or not self:GetData(player) then
		return false
	end
	local deadline = os.clock() + 25
	local nextSave = 0
	repeat
		if saved(profile.LastSavedData) then
			return true
		end
		if self._profiles[player] ~= profile or not self:GetData(player) then
			return false
		end
		if os.clock() >= nextSave then
			profile:Save()
			nextSave = os.clock() + 5
		end
		if saved(profile.LastSavedData) then
			return true
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return saved(profile.LastSavedData)
end

function DataSessions.Destroy(self: DataSessions)
	self._closed = true
	for player in self._profiles do
		self:Release(player)
	end
end

export type DataSessions = typeof(DataSessions.new({} :: Store, function(_player: Player)
	return false
end))

return DataSessions
