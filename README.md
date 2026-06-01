# Roblox Zone Manager Toolkit

A Rojo-based Roblox zone system for detecting when players enter and leave configured areas.

## Features

- Tag-based zone discovery with `CollectionService`
- Enter and exit events for server scripts
- Zone types for safe areas, damage zones, music zones, teleport zones, and custom gameplay areas
- Player zone tracking
- Debug visualizer toggled with `F6`
- Optional example zones for quick testing
- Runtime API for creating zones from scripts

## How Zones Work

Create a `BasePart` in `Workspace`, size it to cover the area, and tag it with:

```text
Zone
```

Then add attributes:

```text
ZoneName = "Shop"
ZoneType = "Safe"
ZoneShape = "Box"
DamagePerSecond = 10
TeleportTo = "0, 8, 0"
MusicId = "rbxassetid://123456"
```

Only `ZoneName` is required. `ZoneShape` can be `Box`, `Sphere`, or `Cylinder`. Zone parts are expected to be transparent, anchored, and non-colliding.

## Server API

```lua
local ZoneService = require(game.ServerScriptService.ZoneToolkit.ZoneService)

ZoneService.ZoneEntered:Connect(function(player, zone)
	print(player.Name, "entered", zone.name)
end)

ZoneService.ZoneExited:Connect(function(player, zone)
	print(player.Name, "exited", zone.name)
end)

ZoneService:Start()
```

## Project Structure

```text
src/
  ReplicatedStorage/
    ZoneToolkit/
      ZoneConfig.lua
  ServerScriptService/
    ZoneToolkit/
      ZoneService.lua
      ZoneToolkitServer.server.lua
  StarterPlayer/
    StarterPlayerScripts/
      ZoneDebugClient.client.lua
```

## Usage

1. Install Rojo.
2. Run `rojo serve` from this folder.
3. Connect Roblox Studio to the Rojo server.
4. Press `F6` in Play mode to toggle zone debug visuals.
