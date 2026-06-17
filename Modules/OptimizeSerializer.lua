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

function Serializer.Encode(state)
	local buf = buffer.create(TOTAL_BYTES)
	local offset = 0

	for _, key in ipairs(ORDER) do
		buffer.writeu8(buf, offset, state[key] and 1 or 0)
		offset += 1
	end

	buffer.writeu16(buf, offset, state.RenderDistance)
	offset += 2

	buffer.writeu16(buf, offset, state.RenderFPS)

	return buf
end

function Serializer.Decode(buf, defaults)
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