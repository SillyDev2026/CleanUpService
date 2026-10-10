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
local writing = {}

local function equalValues(a, b)
    if typeof(a) ~= typeof(b) then return false end
    if typeof(a) ~= "table" then return a == b end
    for k, v in pairs(a) do
        if not equalValues(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local scheduleSave

local function deepCopy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = typeof(v) == "table" and deepCopy(v) or v
	end
	return new
end

local function tablesEqual(a, b)
    return equalValues(a, b)
end

local function saveNow(userId)
    if writing[userId] then return false end
	if not pending[userId] then return true end

    writing[userId] = true
	local state = pending[userId]
    local encoded, buf = pcall(Serializer.Encode, state)
    if not encoded then
        writing[userId] = nil
        warn("OptimizeStore rejected invalid settings:", buf)
        return false
    end

	local success, err
	for i = 1, MAX_RETRIES do
		success, err = pcall(function()
			Store:SetAsync(tostring(userId), buf)
		end)

		if success then
			lastSaved[userId] = deepCopy(state)
            if pending[userId] == state then
                pending[userId] = nil
            end
            writing[userId] = nil
            if pending[userId] then scheduleSave() end
			return true
		end

		task.wait(0.5 * i)
	end

	warn("OptimizeStore failed to save:", err)
    writing[userId] = nil
	return false
end

scheduleSave = function()
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
	local ok, err = pcall(function()
		raw = Store:GetAsync(tostring(userId))
	end)
    if not ok then warn("OptimizeStore load failed:", err) end

	local decoded = Serializer.Decode(raw, defaults)
	lastSaved[userId] = deepCopy(decoded)
	return decoded
end

function OptimizeStore:SaveBuffered(userId, newState)
    assert(typeof(newState) == "table", "OptimizeStore:SaveBuffered expects settings table")
	if lastSaved[userId] ~= nil and tablesEqual(newState, lastSaved[userId]) and not writing[userId] then
        pending[userId] = nil
		return
	end

	pending[userId] = deepCopy(newState)
	scheduleSave()
end

-- Explicit persistence for PlayerRemoving and server shutdown.
-- FlushAll runs independent user saves concurrently to avoid serial shutdown delays.
function OptimizeStore:Flush(userId)
    return saveNow(userId)
end

function OptimizeStore:FlushAll(timeout)
    local limit = if type(timeout) == "number" and timeout > 0 then math.min(timeout, 25) else 20
    local deadline = os.clock() + limit
    for userId in pairs(pending) do
        task.spawn(saveNow, userId)
    end
    while os.clock() < deadline do
        local active = false
        for userId in pairs(pending) do
            if not writing[userId] then task.spawn(saveNow, userId) end
            active = true
        end
        for _ in pairs(writing) do active = true end
        if not active then return true end
        task.wait(0.1)
    end
    return false
end

return OptimizeStore
