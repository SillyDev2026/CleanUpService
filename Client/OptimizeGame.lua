--!native
--!optimize 2

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService('TeleportService')
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local NetworkHandler = ReplicatedStorage.NetworkHandler
local EventBus = require(NetworkHandler.EventBus)
local NetStream = EventBus.ReliableEvent()

local ToggleApply = {}
local ServerCache = {}

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

local MAIN_COLOR = Color3.fromRGB(32, 32, 36)
local HEADER_COLOR = Color3.fromRGB(26, 26, 30)
local PANEL_COLOR = Color3.fromRGB(40, 40, 45)
local TEXT_COLOR = Color3.fromRGB(235, 235, 240)
local SUBTEXT_COLOR = Color3.fromRGB(170, 170, 175)
local ACCENT_COLOR = Color3.fromRGB(0, 162, 255)
local BORDER_COLOR = Color3.fromRGB(60, 60, 65)

local State = {
	GlobalShadows = true,
	VFX = true,
	PartLOD = true,
	SoundDistance = true,
	PhysicsSleep = false,
	AutoOptimize = true,
	SmartFog = true,
	PlayerVisibility = true,
	PlayerCollision = true
}

local Presets = {
	UltraLow = {
		GlobalShadows = false,
		VFX = true,
		PartLOD = true,
		SoundDistance = true,
		PhysicsSleep = true,
		AutoOptimize = true,
		SmartFog = true,
		PlayerVisibility = true,
		PlayerCollision = true,
	},

	Balanced = {
		GlobalShadows = true,
		VFX = true,
		PartLOD = true,
		SoundDistance = true,
		PhysicsSleep = true,
		AutoOptimize = true,
		SmartFog = true,
		PlayerVisibility = true,
		PlayerCollision = true,
	},

	High = {
		GlobalShadows = true,
		VFX = true,
		PartLOD = false,
		SoundDistance = false,
		PhysicsSleep = false,
		AutoOptimize = false,
		SmartFog = false,
		PlayerVisibility = false,
		PlayerCollision = false,
	}
}

local Registry = {
	VFX = {},
	Sounds = {},
	Parts = {},
}

function track(inst)
	if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
		table.insert(Registry.VFX, inst)
	end
	if inst:IsA("Sound") and inst.Parent and inst.Parent:IsA("BasePart") then
		table.insert(Registry.Sounds, inst)
	end
	if inst:IsA("BasePart") and not inst:IsA("Terrain") then
		table.insert(Registry.Parts, inst)
	end
end

for _, d in ipairs(Workspace:GetDescendants()) do
	track(d)
end

Workspace.DescendantAdded:Connect(track)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LemonadeOptimizer"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local mainFrame = Instance.new("ScrollingFrame")
mainFrame.Size = UDim2.fromOffset(420, 480)
mainFrame.Position = UDim2.new(0.5, 0, 1.1, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = MAIN_COLOR
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.BackgroundTransparency = 0.1
mainFrame.ScrollBarThickness = 4
mainFrame.ScrollBarImageColor3 = ACCENT_COLOR
mainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
mainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
mainFrame.ScrollingDirection = Enum.ScrollingDirection.Y
mainFrame.Parent = screenGui

local serverFrame = Instance.new("ScrollingFrame")
serverFrame.Size = UDim2.new(0.55, 0, 0.75, 0)
serverFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
serverFrame.AnchorPoint = Vector2.new(0.5, 0.5)

serverFrame.BackgroundColor3 = MAIN_COLOR
serverFrame.BorderSizePixel = 0
serverFrame.Visible = false
serverFrame.BackgroundTransparency = 0.1
serverFrame.ScrollBarThickness = 4
serverFrame.ScrollBarImageColor3 = ACCENT_COLOR
serverFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
serverFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
serverFrame.ScrollingDirection = Enum.ScrollingDirection.Y
serverFrame.Parent = screenGui

local serverCorner = Instance.new("UICorner")
serverCorner.CornerRadius = UDim.new(0, 8)
serverCorner.Parent = serverFrame

local serverGrid = Instance.new("UIGridLayout")
serverGrid.CellSize = UDim2.new(1, -20, 0, 70)
serverGrid.CellPadding = UDim2.new(0, 0, 0, 6)
serverGrid.SortOrder = Enum.SortOrder.LayoutOrder
serverGrid.FillDirection = Enum.FillDirection.Vertical
serverGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
serverGrid.VerticalAlignment = Enum.VerticalAlignment.Top
serverGrid.Parent = serverFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = BORDER_COLOR
mainStroke.Thickness = 1
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = mainFrame

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mainFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = HEADER_COLOR
header.BorderSizePixel = 0
header.LayoutOrder = 1
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = header

local headerStroke = Instance.new("UIStroke")
headerStroke.Color = BORDER_COLOR
headerStroke.Thickness = 1
headerStroke.Transparency = 0.4
headerStroke.Parent = header

local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0, 10)
headerPadding.PaddingRight = UDim.new(0, 10)
headerPadding.Parent = header

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerLayout.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "In-Game Optimizer"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.TextColor3 = TEXT_COLOR
titleLabel.LayoutOrder = 1
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = SUBTEXT_COLOR
closeBtn.LayoutOrder = 2
closeBtn.Parent = header

local serverBtn = Instance.new("TextButton")
serverBtn.BackgroundTransparency = 1
serverBtn.Size = UDim2.fromOffset(24, 24)
serverBtn.Text = "🌐"
serverBtn.Font = Enum.Font.SourceSansBold
serverBtn.TextSize = 18
serverBtn.TextColor3 = SUBTEXT_COLOR
serverBtn.LayoutOrder = 3
serverBtn.Parent = header

local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(1, 0, 0, 90)

statsPanel.BackgroundColor3 = PANEL_COLOR
statsPanel.BorderSizePixel = 0
statsPanel.LayoutOrder = 2
statsPanel.Parent = mainFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 6)
statsCorner.Parent = statsPanel

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = BORDER_COLOR
statsStroke.Thickness = 1
statsStroke.Transparency = 0.4
statsStroke.Parent = statsPanel

local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statsLayout.Padding = UDim.new(0, 2)

statsLayout.Parent = statsPanel

local function createStatBlock(name)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1/3, -12, 1, -6)

	local vLayout = Instance.new("UIListLayout")
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	vLayout.Padding = UDim.new(0, 4)
	vLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vLayout.Parent = holder

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Text = name
	label.Font = Enum.Font.SourceSans
	label.TextSize = 13
	label.TextColor3 = SUBTEXT_COLOR
	label.LayoutOrder = 1
	label.Parent = holder

	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Size = UDim2.new(1, 0, 0, 24)
	value.Text = "--"
	value.Font = Enum.Font.SourceSansBold
	value.TextSize = 18
	value.TextColor3 = TEXT_COLOR
	value.LayoutOrder = 2
	value.Parent = holder

	holder.Parent = statsPanel
	return value
end

local fpsVal = createStatBlock("FPS")
local pingVal = createStatBlock("Ping")
local memVal = createStatBlock("Memory")

local fpsGraphPanel = Instance.new("Frame")
fpsGraphPanel.Size = UDim2.new(1, 0, 0, 40)
fpsGraphPanel.BackgroundColor3 = PANEL_COLOR
fpsGraphPanel.BorderSizePixel = 0
fpsGraphPanel.LayoutOrder = 2.5
fpsGraphPanel.Parent = mainFrame

local fpsGraphCorner = Instance.new("UICorner")
fpsGraphCorner.CornerRadius = UDim.new(0, 6)
fpsGraphCorner.Parent = fpsGraphPanel

local fpsGraphStroke = Instance.new("UIStroke")
fpsGraphStroke.Color = BORDER_COLOR
fpsGraphStroke.Thickness = 1
fpsGraphStroke.Transparency = 0.4
fpsGraphStroke.Parent = fpsGraphPanel

local fpsGraphPadding = Instance.new("UIPadding")
fpsGraphPadding.PaddingTop = UDim.new(0, 6)
fpsGraphPadding.PaddingBottom = UDim.new(0, 6)
fpsGraphPadding.PaddingLeft = UDim.new(0, 6)
fpsGraphPadding.PaddingRight = UDim.new(0, 6)
fpsGraphPadding.Parent = fpsGraphPanel

local fpsGraphHolder = Instance.new("Frame")
fpsGraphHolder.BackgroundTransparency = 1
fpsGraphHolder.Size = UDim2.new(1, 0, 1, 0)
fpsGraphHolder.Parent = fpsGraphPanel

local fpsGraphLayout = Instance.new("UIListLayout")
fpsGraphLayout.FillDirection = Enum.FillDirection.Horizontal
fpsGraphLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
fpsGraphLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
fpsGraphLayout.Padding = UDim.new(0, 1)
fpsGraphLayout.Parent = fpsGraphHolder

local FPS_HISTORY_LENGTH = 60
local fpsHistory = {}

local fpsBars = {}
for i = 1, FPS_HISTORY_LENGTH do
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = ACCENT_COLOR
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(0, 3, 0, 2)
	bar.Parent = fpsGraphHolder

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	fpsBars[i] = bar
end

local function updateFPSGraph()
	if #fpsHistory == 0 then return end

	local maxFps = 120
	for i = 1, FPS_HISTORY_LENGTH do
		local value = fpsHistory[i] or 0
		local heightScale = math.clamp(value / maxFps, 0, 1)
		local heightPixels = 2 + math.floor(heightScale * 28)
		fpsBars[i].Size = UDim2.new(0, 3, 0, heightPixels)
		fpsBars[i].BackgroundTransparency = value == 0 and 0.8 or 0
	end
end


local presetPanel = Instance.new("Frame")
presetPanel.Size = UDim2.new(1, 0, 0, 40)
presetPanel.BackgroundColor3 = PANEL_COLOR
presetPanel.BorderSizePixel = 0
presetPanel.LayoutOrder = 3
presetPanel.Parent = mainFrame

local presetCorner = Instance.new("UICorner")
presetCorner.CornerRadius = UDim.new(0, 6)
presetCorner.Parent = presetPanel

local presetStroke = Instance.new("UIStroke")
presetStroke.Color = BORDER_COLOR
presetStroke.Thickness = 1
presetStroke.Transparency = 0.4
presetStroke.Parent = presetPanel

local presetLayout = Instance.new("UIListLayout")
presetLayout.FillDirection = Enum.FillDirection.Horizontal
presetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
presetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
presetLayout.Padding = UDim.new(0, 8)
presetLayout.Parent = presetPanel

local function createPresetButton(name, data)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(110, 26)
	btn.BackgroundColor3 = MAIN_COLOR
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.TextColor3 = TEXT_COLOR
	btn.AutoButtonColor = false
	btn.Parent = presetPanel

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color = BORDER_COLOR
	s.Thickness = 1
	s.Transparency = 0.5
	s.Parent = btn

	local function hover(on)
		local goal = on and 0 or 0.5
		TweenService:Create(s, TweenInfo.new(0.15), {Transparency = goal}):Play()
	end

	btn.MouseEnter:Connect(function() hover(true) end)
	btn.MouseLeave:Connect(function() hover(false) end)

	btn.MouseButton1Click:Connect(function()
		for k, v in pairs(data) do
			if k ~= "PlayerCollision" then
				State[k] = v
				if ToggleApply[k] then ToggleApply[k](v) end
			end
		end
	end)
end

function setCollisionEnabled(enabled)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = enabled
				end
			end
		end
	end
end

local togglesPanel = Instance.new("Frame")
togglesPanel.AutomaticSize = Enum.AutomaticSize.Y
togglesPanel.Size = UDim2.new(1, 0, 0, 0)
togglesPanel.BackgroundColor3 = PANEL_COLOR
togglesPanel.BorderSizePixel = 0
togglesPanel.LayoutOrder = 4
togglesPanel.Parent = mainFrame

local togglesCorner = Instance.new("UICorner")
togglesCorner.CornerRadius = UDim.new(0, 6)
togglesCorner.Parent = togglesPanel

local togglesStroke = Instance.new("UIStroke")
togglesStroke.Color = BORDER_COLOR
togglesStroke.Thickness = 1
togglesStroke.Transparency = 0.4
togglesStroke.Parent = togglesPanel

local togglesPadding = Instance.new("UIPadding")
togglesPadding.PaddingTop = UDim.new(0, 6)
togglesPadding.PaddingBottom = UDim.new(0, 6)
togglesPadding.PaddingLeft = UDim.new(0, 6)
togglesPadding.PaddingRight = UDim.new(0, 6)
togglesPadding.Parent = togglesPanel

local togglesList = Instance.new("UIListLayout")
togglesList.FillDirection = Enum.FillDirection.Vertical
togglesList.Padding = UDim.new(0, 4)
togglesList.SortOrder = Enum.SortOrder.LayoutOrder
togglesList.Parent = togglesPanel

local function createToggle(key, labelText, descText)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.LayoutOrder = #ToggleApply + 1
	row.Parent = togglesPanel

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local textHolder = Instance.new("Frame")
	textHolder.BackgroundTransparency = 1
	textHolder.Size = UDim2.new(1, -70, 1, 0)
	textHolder.LayoutOrder = 1
	textHolder.Parent = row

	local vLayout = Instance.new("UIListLayout")
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	vLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	vLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vLayout.Parent = textHolder

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Text = labelText
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 14
	title.TextColor3 = TEXT_COLOR
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.Parent = textHolder

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Size = UDim2.new(1, 0, 0, 16)
	desc.Text = descText
	desc.Font = Enum.Font.SourceSans
	desc.TextSize = 12
	desc.TextColor3 = SUBTEXT_COLOR
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.LayoutOrder = 2
	desc.Parent = textHolder

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.fromOffset(50, 22)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = false
	toggleBtn.LayoutOrder = 2
	toggleBtn.Parent = row

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(18, 18)
	knob.Position = UDim2.new(0, 2, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
	knob.BorderSizePixel = 0
	knob.Parent = toggleBtn

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local function apply(v)
		local goalPos = v and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local goalColor = v and ACCENT_COLOR or Color3.fromRGB(60, 60, 65)
		TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = goalColor}):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), {Position = goalPos}):Play()
	end

	ToggleApply[key] = apply
	apply(State[key])

	toggleBtn.MouseButton1Click:Connect(function()
		State[key] = not State[key]
		apply(State[key])

		if key == "PlayerCollision" then
			if ToggleApply.PlayerCollision then
				ToggleApply.PlayerCollision(State[key])
			end
		elseif key == 'PlayerVisibility' then
			if ToggleApply.PlayerVisibility then
				ToggleApply.PlayerVisibility(State[key])
			end
		end
	end)
end

createToggle("GlobalShadows", "Global Shadows", "Toggle world shadow rendering.")
createToggle("VFX", "VFX / Particles", "Scale particle density based on FPS.")
createToggle("PartLOD", "Part Detail (LOD)", "Lower material quality at distance.")
createToggle("SoundDistance", "Sound Distance", "Pause far away sounds.")
createToggle("PhysicsSleep", "Physics Sleeping", "Anchor far physics parts.")
createToggle("AutoOptimize", "Auto Optimize", "Auto adjust shadows & fog.")
createToggle("SmartFog", "Smart Fog", "Fog tuning based on FPS.")
createToggle("PlayerVisibility", "Player Visibility", "Hide all other players on your screen.")
createToggle("PlayerCollision", "Player Collision", "Walk through other players.")

createPresetButton("Ultra Low", Presets.UltraLow)
createPresetButton("Balanced", Presets.Balanced)
createPresetButton("High Fidelity", Presets.High)

local hotkeyBtn = Instance.new("TextButton")
hotkeyBtn.Size = UDim2.fromOffset(40, 40)
hotkeyBtn.Position = UDim2.new(1, -16, 1, -16)
hotkeyBtn.AnchorPoint = Vector2.new(1, 1)
hotkeyBtn.BackgroundColor3 = MAIN_COLOR
hotkeyBtn.BorderSizePixel = 0
hotkeyBtn.Text = "⚙"
hotkeyBtn.Font = Enum.Font.SourceSansBold
hotkeyBtn.TextSize = 20
hotkeyBtn.TextColor3 = TEXT_COLOR
hotkeyBtn.AutoButtonColor = false
hotkeyBtn.Parent = screenGui

local hotkeyCorner = Instance.new("UICorner")
hotkeyCorner.CornerRadius = UDim.new(1, 0)
hotkeyCorner.Parent = hotkeyBtn

local hotkeyStroke = Instance.new("UIStroke")
hotkeyStroke.Color = BORDER_COLOR
hotkeyStroke.Thickness = 1
hotkeyStroke.Transparency = 0.4
hotkeyStroke.Parent = hotkeyBtn

hotkeyBtn.MouseEnter:Connect(function()
	TweenService:Create(hotkeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = PANEL_COLOR}):Play()
end)

hotkeyBtn.MouseLeave:Connect(function()
	TweenService:Create(hotkeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = MAIN_COLOR}):Play()
end)

local open = false
local animBusy = false

local function setOpen(state)
	if animBusy or open == state then return end
	open = state
	animBusy = true

	if open then
		mainFrame.Visible = true
		TweenService:Create(blur, TweenInfo.new(0.25), {Size = 12}):Play()
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	else
		TweenService:Create(blur, TweenInfo.new(0.2), {Size = 0}):Play()
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1.1, 0)
		}):Play()
		task.delay(0.22, function()
			if not open then
				mainFrame.Visible = false
			end
		end)
	end

	task.delay(0.26, function()
		animBusy = false
	end)
end

local serverOpen = false
local function setServerOpen(state)
	if animBusy or serverOpen == state then return end
	serverOpen = state
	animBusy = true

	if serverOpen then
		serverFrame.Visible = true
		TweenService:Create(serverFrame, TweenInfo.new(0.25), {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	else
		TweenService:Create(serverFrame, TweenInfo.new(0.25), {
			Position = UDim2.new(0.5, 0, 1.1, 0)
		}):Play()
		task.delay(0.26, function()
			if not serverOpen then
				serverFrame.Visible = false
			end
		end)
	end

	task.delay(0.26, function()
		animBusy = false
	end)
end

function requestServers()
	NetStream:Fire(4)
end

serverBtn.MouseButton1Click:Connect(function()
	setServerOpen(not serverOpen)
	if serverOpen then
		requestServers()
	end
end)

requestServers()

local function createServerRow(info)
	local row = Instance.new("Frame")
	row.Name = info.id
	row.Size = UDim2.new(1, 0, 1, 0)
	row.BackgroundColor3 = PANEL_COLOR
	row.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "ServerLabel"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.75, 0, 1, 0)
	label.Position = UDim2.new(0.02, 0, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 14
	label.TextColor3 = TEXT_COLOR
	label.Parent = row

	row:SetAttribute("ServerId", info.id)

	local tpBtn = Instance.new("TextButton")
	tpBtn.Size = UDim2.new(0.18, 0, 0.6, 0)
	tpBtn.Position = UDim2.new(0.98, 0, 0.5, 0)
	tpBtn.AnchorPoint = Vector2.new(1, 0.5)
	tpBtn.BackgroundColor3 = ACCENT_COLOR
	tpBtn.BorderSizePixel = 0
	tpBtn.Text = "Join"
	tpBtn.Font = Enum.Font.SourceSansBold
	tpBtn.TextSize = 14
	tpBtn.TextColor3 = Color3.new(1, 1, 1)
	tpBtn.Parent = row

	local tpCorner = Instance.new("UICorner")
	tpCorner.CornerRadius = UDim.new(0, 4)
	tpCorner.Parent = tpBtn

	tpBtn.MouseButton1Click:Connect(function()
		TeleportService:TeleportToPlaceInstance(
			game.PlaceId,
			info.id,
			player
		)
	end)

	return row
end

function updateServerList(list)
	ServerCache = {}

	local servers = {}

	for id, data in pairs(list) do
		local ping = math.random(20, 200)

		local entry = {
			id = id,
			players = data.players,
			region = data.region,
			timestamp = data.timestamp,
			ping = ping
		}

		table.insert(servers, entry)
		ServerCache[id] = entry
	end
	table.sort(servers, function(a, b)
		return a.ping < b.ping
	end)

	local seen = {}

	for _, info in ipairs(servers) do
		local row = serverFrame:FindFirstChild(info.id)

		if not row then
			row = createServerRow(info)
			row.Name = info.id
			row.Parent = serverFrame
		end

		local label = row:FindFirstChild("ServerLabel")
		if label then
			local age = os.time() - info.timestamp
			local seconds = age % 60
			local minutes = math.floor(age / 60) % 60
			local hours = math.floor(age / 3600)

			local ageText = string.format("%dh %dm %ds", hours, minutes, seconds)

			label.Text = string.format(
				"Server: %s | Players: %d | Region: %s | Ping: %d ms | Age: %s",
				info.id:sub(1, 6),
				info.players,
				info.region,
				info.ping,
				ageText
			)
		end

		seen[info.id] = true
	end

	for _, row in ipairs(serverFrame:GetChildren()) do
		if row:IsA("Frame") then
			if not seen[row.Name] then
				row:Destroy()
			end
		end
	end
end

local regionVal = createStatBlock('Region')
regionVal.Text = 'N/A'

NetStream:Connect(5, function(player, list)
	updateServerList(list)
	local thisServer = list[game.JobId]
	if thisServer then
		regionVal.Text = thisServer.region or 'Unknown'
	end
end)

hotkeyBtn.MouseButton1Click:Connect(function()
	setOpen(not open)
end)

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F4 then
		setOpen(not open)
	end
end)

local function applyMaterialLOD(part, dist)
	if not State.PartLOD then
		local original = part:GetAttribute("OriginalMaterial")
		if original then
			part.Material = original
		end
		return
	end

	if dist > 200 then
		if not part:GetAttribute("OriginalMaterial") then
			part:SetAttribute("OriginalMaterial", part.Material)
		end
		part.Material = Enum.Material.SmoothPlastic
	else
		local original = part:GetAttribute("OriginalMaterial")
		if original then
			part.Material = original
		end
	end
end

local function scaleEmitter(e, fps)
	if not e:IsA("ParticleEmitter") then return end
	if not State.VFX then
		e.Enabled = false
		return
	end

	if not e:GetAttribute("BaseRate") then
		e:SetAttribute("BaseRate", e.Rate)
	end

	local baseRate = e:GetAttribute("BaseRate")

	if fps < 35 then
		e.Rate = math.max(1, baseRate * 0.25)
	elseif fps < 50 then
		e.Rate = baseRate * 0.5
	else
		e.Rate = baseRate
	end

	e.Enabled = true
end

local function applySmartFog(fps)
	if not State.SmartFog then
		Lighting.FogEnd = 1000
		Lighting.FogStart = 300
		return
	end

	if fps < 35 then
		Lighting.FogEnd = 80
		Lighting.FogStart = 20
	elseif fps < 50 then
		Lighting.FogEnd = 150
		Lighting.FogStart = 50
	else
		Lighting.FogEnd = 500
		Lighting.FogStart = 100
	end
end

RunService.Heartbeat:Connect(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end

	local camPos = cam.CFrame.Position

	for i = #Registry.Parts, 1, -1 do
		local p = Registry.Parts[i]
		if p and p.Parent then
			local dist = (p.Position - camPos).Magnitude
			applyMaterialLOD(p, dist)

			if State.PhysicsSleep and not p.Anchored then
				if dist > 500 then
					p.Anchored = true
					p:SetAttribute("WasUnanchored", true)
				else
					if p:GetAttribute("WasUnanchored") then
						p.Anchored = false
						p:SetAttribute("WasUnanchored", nil)
					end
				end
			end
		else
			table.remove(Registry.Parts, i)
		end
	end

	if State.SoundDistance then
		for i = #Registry.Sounds, 1, -1 do
			local s = Registry.Sounds[i]
			if s and s.Parent and s.Parent:IsA("BasePart") then
				local dist = (s.Parent.Position - camPos).Magnitude
				if dist > 300 then
					if s.Playing then
						s:Pause()
						s:SetAttribute("WasPlaying", true)
					end
				else
					if s:GetAttribute("WasPlaying") then
						s:Resume()
						s:SetAttribute("WasPlaying", nil)
					end
				end
			else
				table.remove(Registry.Sounds, i)
			end
		end
	end
end)

local frameCount = 0
local lastUpdate = os.clock()

RunService.RenderStepped:Connect(function()
	frameCount += 1
	local now = os.clock()

	if now - lastUpdate >= 1 then
		local fps = math.floor(frameCount / (now - lastUpdate))
		fpsVal.Text = tostring(fps)
		table.insert(fpsHistory, fps)
		if #fpsHistory > FPS_HISTORY_LENGTH then
			table.remove(fpsHistory, 1)
		end
		updateFPSGraph()

		local pingMs = 0
		pcall(function()
			pingMs = math.floor(player:GetNetworkPing() * 1000)
			pingVal.Text = pingMs .. " ms"
		end)

		local memMb = math.floor(Stats:GetTotalMemoryUsageMb())
		memVal.Text = memMb .. " MB"

		if State.AutoOptimize then
			if fps < 35 then
				Lighting.GlobalShadows = false
			elseif fps > 55 then
				Lighting.GlobalShadows = true
			end
			applySmartFog(fps)
		end

		for _, v in ipairs(Registry.VFX) do
			scaleEmitter(v, fps)
		end
		
		
		NetStream:FireToPlayer(player, 1, {
			fps = fps,
			ping = pingMs,
			mem = memMb
		})

		frameCount = 0
		lastUpdate = now
	end
end)

local function setCharacterVisible(character, visible)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = visible and 0 or 1
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = visible and 0 or 1
		elseif obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = visible and 0 or 1
			end
		elseif obj:IsA("BillboardGui") then
			obj.Enabled = visible
		elseif obj:IsA("SurfaceGui") then
			obj.Enabled = visible
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if visible then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
			humanoid.NameDisplayDistance = 100
		else
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.NameDisplayDistance = 0
		end
	end
end

local function updateAllPlayerVisibility()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			setCharacterVisible(plr.Character, State.PlayerVisibility)
		end
	end
end

ToggleApply.PlayerVisibility = function(v)
	State.PlayerVisibility = v
	updateAllPlayerVisibility()
end

Players.PlayerAdded:Connect(function(plr)
	if plr ~= player then
		plr.CharacterAdded:Connect(function(char)
			task.wait(0.1)
			setCharacterVisible(char, State.PlayerVisibility)
		end)
		updateAllPlayerVisibility()
	end
end)

ToggleApply.PlayerCollision = function(v)
	State.PlayerCollision = v
	NetStream:FireToPlayer(player, 2, { collision = v })
end

local AUTO_REFRESH = 10

task.spawn(function()
	while true do
		if serverOpen then
			requestServers()
		end
		task.wait(AUTO_REFRESH)
	end
end)

task.spawn(function()
	while true do
		if serverOpen then
			for _, row in ipairs(serverFrame:GetChildren()) do
				if row:IsA("Frame") then
					local id = row:GetAttribute("ServerId")
					local label = row:FindFirstChild("ServerLabel")

					if id and label and ServerCache[id] then
						local info = ServerCache[id]
						local age = os.time() - info.timestamp

						local seconds = age % 60
						local minutes = math.floor(age / 60) % 60
						local hours = math.floor(age / 3600)

						local ageText = string.format("%dh %dm %ds", hours, minutes, seconds)

						label.Text = string.format(
							"Server: %s | Players: %d | Region: %s | Ping: %d ms | Age: %s",
							info.id:sub(1, 6),
							info.players,
							info.region,
							info.ping,
							ageText
						)
					end
				end
			end
		end
		task.wait(1)
	end
end)