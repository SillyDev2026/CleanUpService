local State = {
	GlobalShadows = true,
	VFX = true,
	PartLOD = true,
	SoundDistance = true,
	PhysicsSleep = false,
	AutoOptimize = true,
	SmartFog = true,
	PlayerVisibility = true,
	PlayerCollision = true,
	DynamicRender = false,
	RenderDistance = 10,
	OcclusionCulling = true,
	RenderFPS = 25,
}

local defaultSettings = State
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Modules = ReplicatedStorage.Modules
local OptimizeStore = require(Modules.OptimizeStore)
local Players = game:GetService('Players')
local NetworkHandler = ReplicatedStorage.NetworkHandler
local EventBus = require(NetworkHandler.EventBus)
local NetStream = EventBus.ReliableEvent()

NetStream:Connect(7, function(player, newState)
    if typeof(newState) ~= "table" then return end
	OptimizeStore:SaveBuffered(player.UserId, newState)
end)

NetStream:Connect(6, function(player)
	local saved = OptimizeStore:Load(player.UserId, defaultSettings)
	NetStream:FireToPlayer(player, 8, saved)
end)

Players.PlayerRemoving:Connect(function(player)
    OptimizeStore:Flush(player.UserId)
end)

game:BindToClose(function()
    local completed = OptimizeStore:FlushAll(20)
    if not completed then warn("OptimizeStore shutdown flush exceeded timeout") end
end)