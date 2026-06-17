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
	OptimizeStore:SaveBuffered(player.UserId, newState)
end)

NetStream:Connect(6, function(player)
	local saved = OptimizeStore:Load(player.UserId, defaultSettings)
	NetStream:FireToPlayer(player, 8, saved)
end)

game:BindToClose(function()
	task.wait(2)
end)