local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkHandler = ReplicatedStorage.NetworkHandler
local EventBus = require(NetworkHandler.EventBus)
local NetStream = EventBus.ReliableEvent()
local PhysicsService = game:GetService("PhysicsService")

local playerBillboards = {}

local function createBillboardForCharacter(player, character)
	local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
	if not head then return end

	if playerBillboards[player] then
		playerBillboards[player]:Destroy()
		playerBillboards[player] = nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LemonadeStatsBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	billboard.Parent = character

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bg

	local label = Instance.new("TextLabel")
	label.Name = "StatsLabel"
	label.Size = UDim2.new(1, -8, 1, -8)
	label.Position = UDim2.fromOffset(4, 4)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "FPS: -- | Ping: -- | Mem: --"
	label.Parent = bg

	playerBillboards[player] = billboard
end

local NORMAL = "PlayerCharacters"
local PASS = "PlayerPass"

pcall(function()
	PhysicsService:RegisterCollisionGroup(NORMAL)
	PhysicsService:RegisterCollisionGroup(PASS)
end)

PhysicsService:CollisionGroupSetCollidable(NORMAL, NORMAL, true)

PhysicsService:CollisionGroupSetCollidable(PASS, NORMAL, false)
PhysicsService:CollisionGroupSetCollidable(PASS, PASS, false)

local function applyCollisionGroup(character, group)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		createBillboardForCharacter(player, character)

		local collision = player:GetAttribute("CollisionEnabled")
		applyCollisionGroup(character, collision and PASS or NORMAL)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if playerBillboards[player] then
		playerBillboards[player]:Destroy()
		playerBillboards[player] = nil
	end
end)

NetStream:Connect(1, function(player, data)
	local billboard = playerBillboards[player]
	if not billboard or not billboard.Parent then return end

	local bg = billboard:FindFirstChild("BG")
	if not bg then return end

	local statsLabel = bg:FindFirstChild("StatsLabel")
	if not statsLabel then return end

	statsLabel.Text = string.format(
		"FPS: %d | Ping: %dms | Mem: %dMB",
		data.fps or 0,
		data.ping or 0,
		data.mem or 0
	)
end)

NetStream:Connect(2, function(player, data)
	player:SetAttribute("CollisionEnabled", data.collision)

	local char = player.Character
	if not char then return end

	applyCollisionGroup(char, data.collision and PASS or NORMAL)
end)
