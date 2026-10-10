--!strict
-- Roblox Studio Script placed next to OptimizeSerializer.
local Serializer = require(script.Parent:WaitForChild("OptimizeSerializer"))
local defaults = {
    GlobalShadows = true, VFX = true, PartLOD = false, SoundDistance = true,
    PhysicsSleep = false, AutoOptimize = true, SmartFog = false,
    PlayerVisibility = true, PlayerCollision = true, DynamicRender = false,
    OcclusionCulling = true, RenderDistance = 65535, RenderFPS = 25,
}
local packet = Serializer.Encode(defaults)
assert(typeof(packet) == "buffer" and buffer.len(packet) == 15)
local result = Serializer.Decode(packet, defaults)
assert(result.RenderDistance == 65535 and result.RenderFPS == 25)
assert(result.GlobalShadows and not result.PartLOD and not result.SmartFog)
local malformed = table.clone(defaults)
malformed.RenderFPS = math.huge
assert(not pcall(Serializer.Encode, malformed), "Infinity accepted")
malformed.RenderFPS = -1
assert(not pcall(Serializer.Encode, malformed), "Negative RenderFPS accepted")
malformed.RenderFPS = 1.5
assert(not pcall(Serializer.Encode, malformed), "Fractional RenderFPS accepted")
local fallback = Serializer.Decode(buffer.create(0), defaults)
assert(fallback.RenderFPS == defaults.RenderFPS, "Short payload fallback failed")
print("CleanUpService serializer regression PASS")
