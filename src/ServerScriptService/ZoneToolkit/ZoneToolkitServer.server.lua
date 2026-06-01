-- ZoneToolkitServer
-- Boots the zone service and exposes debug data to clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZoneService = require(script.Parent:WaitForChild("ZoneService"))
local Config = require(ReplicatedStorage:WaitForChild("ZoneToolkit"):WaitForChild("ZoneConfig"))

local remotes = ReplicatedStorage:FindFirstChild("ZoneToolkitRemotes") or Instance.new("Folder")
remotes.Name = "ZoneToolkitRemotes"
remotes.Parent = ReplicatedStorage

local requestZones = remotes:FindFirstChild("RequestZones") or Instance.new("RemoteFunction")
requestZones.Name = "RequestZones"
requestZones.Parent = remotes

local function createExamples()
	local folder = Workspace:FindFirstChild("ExampleZones") or Instance.new("Folder")
	folder.Name = "ExampleZones"
	folder.Parent = Workspace

	if folder:FindFirstChild("SafeZone") then
		return
	end

	ZoneService:CreateZone({
		name = "SafeZone",
		zoneType = "Safe",
		size = Vector3.new(22, 8, 22),
		cframe = CFrame.new(-28, 4, 0),
		parent = folder,
	})

	ZoneService:CreateZone({
		name = "DamageZone",
		zoneType = "Damage",
		damagePerSecond = 15,
		size = Vector3.new(18, 8, 18),
		cframe = CFrame.new(0, 4, 0),
		parent = folder,
	})

	ZoneService:CreateZone({
		name = "TeleportZone",
		zoneType = "Teleport",
		teleportTo = Vector3.new(-28, 8, 0),
		size = Vector3.new(16, 8, 16),
		cframe = CFrame.new(28, 4, 0),
		parent = folder,
	})
end

ZoneService.ZoneEntered:Connect(function(player, zone)
	print(string.format("[ZoneToolkit] %s entered %s (%s)", player.Name, zone.name, zone.type))
end)

ZoneService.ZoneExited:Connect(function(player, zone)
	print(string.format("[ZoneToolkit] %s exited %s", player.Name, zone.name))
end)

ZoneService:Start()

if Config.CreateExampleZones then
	createExamples()
end

requestZones.OnServerInvoke = function(player)
	return {
		debugEnabled = Config.DebugVisualsEnabled,
		zones = ZoneService:GetZones(),
		playerZones = ZoneService:GetPlayerZones(player),
	}
end

print("[ZoneToolkit] Zone service ready.")
