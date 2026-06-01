-- ZoneService
-- Server-side area detection service for Roblox experiences.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("ZoneToolkit"):WaitForChild("ZoneConfig"))

local ZoneService = {}

local zoneEnteredEvent = Instance.new("BindableEvent")
local zoneExitedEvent = Instance.new("BindableEvent")
local zoneUpdatedEvent = Instance.new("BindableEvent")

ZoneService.ZoneEntered = zoneEnteredEvent.Event
ZoneService.ZoneExited = zoneExitedEvent.Event
ZoneService.ZoneUpdated = zoneUpdatedEvent.Event

local zonesByPart = {}
local zonesByName = {}
local playerZones = {}
local teleportCooldowns = {}
local started = false
local accumulator = 0

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

local function parseVector3(text)
	if typeof(text) == "Vector3" then
		return text
	end
	if type(text) ~= "string" then
		return nil
	end

	local x, y, z = string.match(text, "^%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*$")
	if not x then
		return nil
	end

	return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

local function pathFor(instance)
	local names = {}
	local current = instance
	while current and current ~= game do
		table.insert(names, 1, current.Name)
		current = current.Parent
	end
	return "game." .. table.concat(names, ".")
end

local function readZone(part)
	local zoneType = part:GetAttribute("ZoneType") or "Custom"
	local zoneName = part:GetAttribute("ZoneName") or part.Name
	local zoneShape = part:GetAttribute("ZoneShape") or Config.DefaultZoneShape or "Box"

	return {
		part = part,
		name = zoneName,
		type = zoneType,
		shape = zoneShape,
		damagePerSecond = tonumber(part:GetAttribute("DamagePerSecond")) or Config.DefaultDamagePerSecond,
		teleportTo = parseVector3(part:GetAttribute("TeleportTo")),
		musicId = part:GetAttribute("MusicId"),
		path = pathFor(part),
	}
end

local function rememberZone(part)
	if not part:IsA("BasePart") then
		return
	end

	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true

	local zone = readZone(part)
	zonesByPart[part] = zone
	zonesByName[zone.name] = zone
	zoneUpdatedEvent:Fire(zone)
end

local function forgetZone(part)
	local zone = zonesByPart[part]
	if not zone then
		return
	end

	zonesByPart[part] = nil
	if zonesByName[zone.name] == zone then
		zonesByName[zone.name] = nil
	end
	zoneUpdatedEvent:Fire(zone)
end

local function getRootPart(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function isRootInsideZone(rootPart, zone)
	if zone.shape == "Sphere" then
		local radius = math.max(zone.part.Size.X, zone.part.Size.Y, zone.part.Size.Z) * 0.5
		return (rootPart.Position - zone.part.Position).Magnitude <= radius
	elseif zone.shape == "Cylinder" then
		local localPosition = zone.part.CFrame:PointToObjectSpace(rootPart.Position)
		local radius = math.max(zone.part.Size.X, zone.part.Size.Z) * 0.5
		local halfHeight = zone.part.Size.Y * 0.5
		return Vector2.new(localPosition.X, localPosition.Z).Magnitude <= radius and math.abs(localPosition.Y) <= halfHeight
	end

	overlapParams.FilterDescendantsInstances = { rootPart }
	local parts = Workspace:GetPartBoundsInBox(zone.part.CFrame, zone.part.Size, overlapParams)
	return #parts > 0
end

local function applyZoneEffect(player, zone, deltaTime)
	if zone.type == "Damage" then
		local humanoid = getHumanoid(player)
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(zone.damagePerSecond * deltaTime)
		end
	elseif zone.type == "Teleport" and zone.teleportTo then
		local key = player.UserId .. ":" .. zone.name
		local now = os.clock()
		if not teleportCooldowns[key] or now - teleportCooldowns[key] >= Config.TeleportCooldownSeconds then
			teleportCooldowns[key] = now
			local root = getRootPart(player)
			if root then
				root.CFrame = CFrame.new(zone.teleportTo)
			end
		end
	end
end

local function setContains(set, value)
	return set[value] == true
end

local function scanPlayer(player, deltaTime)
	local rootPart = getRootPart(player)
	if not rootPart then
		playerZones[player] = {}
		return
	end

	local previous = playerZones[player] or {}
	local current = {}

	for _, zone in pairs(zonesByPart) do
		if zone.part.Parent and isRootInsideZone(rootPart, zone) then
			current[zone.name] = true
			applyZoneEffect(player, zone, deltaTime)
			if not setContains(previous, zone.name) then
				zoneEnteredEvent:Fire(player, zone)
			end
		end
	end

	for zoneName in pairs(previous) do
		if not current[zoneName] then
			local zone = zonesByName[zoneName] or { name = zoneName, type = "Unknown" }
			zoneExitedEvent:Fire(player, zone)
		end
	end

	playerZones[player] = current
end

local function scanAll(deltaTime)
	for _, player in ipairs(Players:GetPlayers()) do
		scanPlayer(player, deltaTime)
	end
end

local function registerExistingZones()
	for _, instance in ipairs(CollectionService:GetTagged(Config.ZoneTag)) do
		rememberZone(instance)
	end
end

function ZoneService:Start()
	if started then
		return
	end
	started = true

	registerExistingZones()

	CollectionService:GetInstanceAddedSignal(Config.ZoneTag):Connect(rememberZone)
	CollectionService:GetInstanceRemovedSignal(Config.ZoneTag):Connect(forgetZone)

	Players.PlayerRemoving:Connect(function(player)
		playerZones[player] = nil
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		accumulator += deltaTime
		if accumulator < Config.CheckInterval then
			return
		end
		local elapsed = accumulator
		accumulator = 0
		scanAll(elapsed)
	end)
end

function ZoneService:GetZones()
	local zones = {}
	for _, zone in pairs(zonesByPart) do
		table.insert(zones, {
			name = zone.name,
			type = zone.type,
			shape = zone.shape,
			path = zone.path,
			size = zone.part.Size,
			cframe = zone.part.CFrame,
			color = Config.ZoneTypeColors[zone.type] or Config.DefaultZoneColor,
		})
	end
	table.sort(zones, function(a, b)
		return a.name < b.name
	end)
	return zones
end

function ZoneService:GetPlayerZones(player)
	local zones = {}
	for zoneName in pairs(playerZones[player] or {}) do
		table.insert(zones, zoneName)
	end
	table.sort(zones)
	return zones
end

function ZoneService:GetZone(zoneName)
	return zonesByName[zoneName]
end

function ZoneService:CreateZone(options)
	assert(type(options) == "table", "CreateZone expects an options table")

	local part = Instance.new("Part")
	part.Name = options.name or "Zone"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Transparency = options.transparency or Config.DefaultZoneTransparency
	part.Color = options.color or Config.ZoneTypeColors[options.zoneType or "Custom"] or Config.DefaultZoneColor
	part.Material = Enum.Material.ForceField
	part.Shape = options.shape == "Sphere" and Enum.PartType.Ball or (options.shape == "Cylinder" and Enum.PartType.Cylinder or Enum.PartType.Block)
	part.Size = options.size or Vector3.new(16, 8, 16)
	part.CFrame = options.cframe or CFrame.new(0, 4, 0)
	part:SetAttribute("ZoneName", options.name or part.Name)
	part:SetAttribute("ZoneType", options.zoneType or "Custom")
	part:SetAttribute("ZoneShape", options.shape or Config.DefaultZoneShape or "Box")

	if options.damagePerSecond then
		part:SetAttribute("DamagePerSecond", options.damagePerSecond)
	end
	if options.teleportTo then
		part:SetAttribute("TeleportTo", string.format("%s, %s, %s", options.teleportTo.X, options.teleportTo.Y, options.teleportTo.Z))
	end
	if options.musicId then
		part:SetAttribute("MusicId", options.musicId)
	end

	part.Parent = options.parent or Workspace
	CollectionService:AddTag(part, Config.ZoneTag)
	rememberZone(part)
	return part
end

return ZoneService
