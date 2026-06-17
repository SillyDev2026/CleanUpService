--!optimize 2
--!native
local DataStoreService = game:GetService("DataStoreService")
local Store = DataStoreService:GetDataStore("OptimizeUI")

local Serializer = require(script.Parent.OptimizeSerializer)

local BUFFER_TIME = 1.5
local MAX_RETRIES = 5

local pending = {}
local lastSaved = {}
local saveScheduled = false

local function deepCopy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = typeof(v) == "table" and deepCopy(v) or v
	end
	return new
end

local function tablesEqual(a, b)
	for k, v in pairs(a) do
		if b[k] ~= v then return false end
	end
	for k, v in pairs(b) do
		if a[k] ~= v then return false end
	end
	return true
end

local function saveNow(userId)
	if not pending[userId] then return end

	local state = pending[userId]
	local buf = Serializer.Encode(state)

	local success, err
	for i = 1, MAX_RETRIES do
		success, err = pcall(function()
			Store:SetAsync(userId, buf)
		end)

		if success then
			lastSaved[userId] = deepCopy(state)
			pending[userId] = nil
			return true
		end

		task.wait(0.5 * i)
	end

	warn("OptimizeStore failed to save:", err)
	return false
end

local function scheduleSave()
	if saveScheduled then return end
	saveScheduled = true

	task.delay(BUFFER_TIME, function()
		saveScheduled = false
		for userId in pairs(pending) do
			saveNow(userId)
		end
	end)
end

local OptimizeStore = {}

function OptimizeStore:Load(userId, defaults)
	local raw
	pcall(function()
		raw = Store:GetAsync(userId)
	end)

	local decoded = Serializer.Decode(raw, defaults)
	lastSaved[userId] = deepCopy(decoded)
	return decoded
end

function OptimizeStore:SaveBuffered(userId, newState)
	if tablesEqual(newState, lastSaved[userId]) then
		return
	end

	pending[userId] = deepCopy(newState)
	scheduleSave()
end

return OptimizeStore
