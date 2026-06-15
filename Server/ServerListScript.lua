local MessageService = game:GetService('MessagingService')
local HttpService = game:GetService('HttpService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local NetworkHandler = ReplicatedStorage.NetworkHandler
local EventBus = require(NetworkHandler.EventBus)
local NetStream = EventBus.ReliableEvent()
local serverId = game.JobId
local region = game:GetService('LocalizationService').RobloxLocaleId or "Unknown"
local servers = {}

function publish()
	MessageService:PublishAsync('ServerList', {
		id = serverId,
		players = #game.Players:GetPlayers(),
		region = region,
		timestamp = os.time()
	})
end

MessageService:SubscribeAsync("ServerList", function(msg)
	local data = msg.Data
	servers[data.id] = data
end)

task.spawn(function()
	while true do
		publish()
		task.wait(5)
	end
end)

NetStream:Connect(4, function(player)
	for id, info in pairs(servers) do
		if os.time() - info.timestamp > 10 then
			servers[id] = nil
		end
	end
	NetStream:FireToPlayer(player, 5, servers)
end)