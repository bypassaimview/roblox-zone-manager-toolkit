-- ZoneDebugClient
-- Lightweight local visualizer for zone parts. Press F6 by default.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("ZoneToolkit"):WaitForChild("ZoneConfig"))

local remotes = ReplicatedStorage:WaitForChild("ZoneToolkitRemotes")
local requestZones = remotes:WaitForChild("RequestZones")

local enabled = false
local refreshRunning = false
local adornments = {}
local debugParts = {}

local gui = Instance.new("ScreenGui")
gui.Name = "ZoneDebugGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 900
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0, 1)
label.Position = UDim2.new(0, 16, 1, -16)
label.Size = UDim2.fromOffset(420, 34)
label.BackgroundColor3 = Color3.fromRGB(10, 14, 21)
label.BackgroundTransparency = 0.15
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(246, 249, 252)
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "Zone debug disabled"
label.Visible = false
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = label

local function clearAdornments()
	for _, adornment in ipairs(adornments) do
		adornment:Destroy()
	end
	table.clear(adornments)

	for _, part in ipairs(debugParts) do
		part:Destroy()
	end
	table.clear(debugParts)
end

local function makeAdornment(zone)
	local part = Instance.new("Part")
	part.Name = "ZoneDebugPart_" .. zone.name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = zone.size
	part.CFrame = zone.cframe
	part.Parent = workspace
	table.insert(debugParts, part)

	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ZoneDebug_" .. zone.name
	box.Adornee = part
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Size = zone.size
	box.Color3 = zone.color
	box.Transparency = 0.62
	box.Parent = gui
	table.insert(adornments, box)

	local outline = Instance.new("SelectionBox")
	outline.Name = "ZoneDebugOutline_" .. zone.name
	outline.Adornee = part
	outline.Color3 = zone.color
	outline.LineThickness = 0.04
	outline.SurfaceTransparency = 1
	outline.Parent = gui
	table.insert(adornments, outline)
end

local function refresh()
	if refreshRunning or not enabled then
		return
	end
	refreshRunning = true

	local ok, result = pcall(function()
		return requestZones:InvokeServer()
	end)

	clearAdornments()

	if ok and type(result) == "table" then
		for _, zone in ipairs(result.zones or {}) do
			makeAdornment(zone)
		end
		label.Text = string.format("Zone debug: %d zone(s) | You are in: %s", #(result.zones or {}), table.concat(result.playerZones or {}, ", "))
	else
		label.Text = "Zone debug refresh failed"
	end

	refreshRunning = false
end

local function setEnabled(nextEnabled)
	if not config.DebugVisualsEnabled then
		return
	end

	enabled = nextEnabled
	label.Visible = enabled
	if enabled then
		refresh()
	else
		clearAdornments()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == (config.DebugToggleKey or Enum.KeyCode.F6) then
		setEnabled(not enabled)
	end
end)

task.spawn(function()
	while gui.Parent do
		task.wait(config.DebugRefreshSeconds or 1)
		refresh()
	end
end)

print("[ZoneToolkit] Debug visualizer ready. Press F6 to toggle.")
