# CleanUpService — Roblox client optimization settings

This repository contains a Roblox visual/performance-settings UI, a client-side world scanner, networking utilities, a 15-byte settings serializer, and a DataStore-backed settings queue.

> **Scope:** The scripts are a prototype toolkit, not a verified drop-in FPS booster. Features that hide or disable effects may affect gameplay presentation. Benchmarks must compare equal scenes on the same client/device.

## Repository layout

```text
Client/OptimizeGame.lua                   -- LocalScript: UI, local visual settings
Server/DataStore.lua                      -- Script: settings fetch/save remote handlers
Server/ServerListScript.lua               -- Script: optional server list
Server/OptimizeGameScript.lua             -- Script: server utilities
Modules/OptimizeSerializer.lua            -- ModuleScript: fixed 15-byte codec
Modules/OptimizeStore.lua                 -- ModuleScript: buffered DataStore writes
Modules/NetworkHandler/                    -- Additional networking modules
```

## Integration prerequisites

The scripts expect `ReplicatedStorage.Modules`, `ReplicatedStorage.NetworkHandler`, and their dependent ModuleScripts. They are not packaged as one immediately installable Roblox model. Place scripts according to their `require` references before testing. Enable Studio API Services when testing actual DataStore requests.

Do **not** run server code on the client. Keep persistence and any administrative server-state modifications server authoritative.

## Persistence correctness changes

- Convert numeric UserIds to string DataStore keys for `GetAsync` and `SetAsync`.
- Compare settings recursively rather than failing on missing `lastSaved` records.
- Avoid dropping newer pending settings when a slow write completes after another edit.
- Expose `OptimizeStore:Flush(userId)` and `:FlushAll(timeout)`, and use them on player departure and `BindToClose`.
- Validate `RenderDistance` and `RenderFPS` as finite integer `uint16` values before encoding; malformed settings are warned and not saved.
- Keep the serialized payload format exactly 15 bytes, preserving the old option order.

The settings buffer schema is **not versioned**. To avoid data corruption, do not reorder its fields without a migration. The present queue has bounded retries; DataStore access can still fail, especially during shutdown.

## Example: serializer

```luau
local Serializer = require(game.ReplicatedStorage.Modules.OptimizeSerializer)
local settings = {
    GlobalShadows = true, VFX = true, PartLOD = true, SoundDistance = true,
    PhysicsSleep = false, AutoOptimize = true, SmartFog = true,
    PlayerVisibility = true, PlayerCollision = true, DynamicRender = false,
    OcclusionCulling = true, RenderDistance = 10, RenderFPS = 25,
}
local bytes = Serializer.Encode(settings)
assert(buffer.len(bytes) == 15)
local decoded = Serializer.Decode(bytes, settings)
print(decoded.RenderDistance)
```

## Testing and profiling

Run `tests/OptimizeSerializerRegression.server.lua` inside Studio with `OptimizeSerializer` accessible as a sibling. For the full persistence path, use a separate nonproduction test place with Studio API services enabled and verify roundtrip persistence, deliberate DataStore failures, rapid consecutive updates, departure, and shutdown.

`--!strict` is enabled only on the serializer here. Other modules still need separate Script Analysis/typecheck passes, not merely annotation changes.

Performance work should measure script time, memory, and frame time using Studio MicroProfiler/Script Profiler; `--!native` alone does not guarantee better speed.
