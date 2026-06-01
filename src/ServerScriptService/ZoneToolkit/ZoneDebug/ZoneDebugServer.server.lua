-- ZoneDebugServer
-- Optional debug remote API for zone visualization clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneService = require(script.Parent.Parent:WaitForChild("ZoneService"))
local Config = require(ReplicatedStorage:WaitForChild("ZoneToolkit"):WaitForChild("ZoneConfig"))

if not Config.DebugVisualsEnabled then
	return
end

local remotes = ReplicatedStorage:FindFirstChild("ZoneToolkitRemotes") or Instance.new("Folder")
remotes.Name = "ZoneToolkitRemotes"
remotes.Parent = ReplicatedStorage

local requestZones = remotes:FindFirstChild("RequestZones") or Instance.new("RemoteFunction")
requestZones.Name = "RequestZones"
requestZones.Parent = remotes

requestZones.OnServerInvoke = function(player)
	return {
		debugEnabled = Config.DebugVisualsEnabled,
		zones = ZoneService:GetZones(),
		playerZones = ZoneService:GetPlayerZones(player),
	}
end

print("[ZoneToolkit] Debug server ready.")
