-- ZoneConfig
-- Shared configuration for the zone manager.

local Config = {}

Config.ZoneTag = "Zone"
Config.CheckInterval = 0.15
Config.CreateExampleZones = true
Config.DefaultZoneShape = "Box"

Config.DebugVisualsEnabled = true
Config.DebugToggleKey = Enum.KeyCode.F6
Config.DebugRefreshSeconds = 1

Config.DefaultZoneTransparency = 0.82
Config.DefaultZoneColor = Color3.fromRGB(72, 218, 155)

Config.ZoneTypeColors = {
	Safe = Color3.fromRGB(72, 218, 155),
	Damage = Color3.fromRGB(255, 112, 112),
	Teleport = Color3.fromRGB(91, 166, 255),
	Music = Color3.fromRGB(178, 132, 255),
	Quest = Color3.fromRGB(255, 196, 87),
	Custom = Color3.fromRGB(235, 241, 247),
}

Config.DefaultDamagePerSecond = 10
Config.TeleportCooldownSeconds = 2

return Config
