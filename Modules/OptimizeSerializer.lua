--!strict
--!native
--!optimize 2

local Serializer = {}

local ORDER = {
	"GlobalShadows",
	"VFX",
	"PartLOD",
	"SoundDistance",
	"PhysicsSleep",
	"AutoOptimize",
	"SmartFog",
	"PlayerVisibility",
	"PlayerCollision",
	"DynamicRender",
	"OcclusionCulling",
}

local TOTAL_BYTES = 15

local function validU16(value: any, name: string): number
    assert(type(value) == "number" and value == value and value >= 0 and value <= 65535
        and value % 1 == 0, name .. " must be a uint16 integer")
    return value
end

function Serializer.Encode(state: {[string]: any}): buffer
	local buf = buffer.create(TOTAL_BYTES)
	local offset = 0

	for _, key in ipairs(ORDER) do
		buffer.writeu8(buf, offset, state[key] and 1 or 0)
		offset += 1
	end

	buffer.writeu16(buf, offset, validU16(state.RenderDistance, "RenderDistance"))
	offset += 2

	buffer.writeu16(buf, offset, validU16(state.RenderFPS, "RenderFPS"))

	return buf
end

function Serializer.Decode(buf: buffer?, defaults: {[string]: any}): {[string]: any}
	if not buf or buffer.len(buf) < TOTAL_BYTES then
		return table.clone(defaults)
	end

	local state = table.clone(defaults)
	local offset = 0

	for _, key in ipairs(ORDER) do
		state[key] = buffer.readu8(buf, offset) == 1
		offset += 1
	end

	state.RenderDistance = buffer.readu16(buf, offset)
	offset += 2

	state.RenderFPS = buffer.readu16(buf, offset)

	return state
end

return Serializer