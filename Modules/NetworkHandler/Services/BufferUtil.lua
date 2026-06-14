--!native
--!optimize 2

--[[
    created by SillyDev2026
    Buffer Utility Module (Luau / Roblox)

    Purpose:
    - Provide fast, low-level helpers for working with Roblox buffers
    - Support typed reads/writes (i8, u8, i16, u16, i32, u32, f32, f64)
    - Support sequential cursor-based access with automatic advancement
    - Support compiled layouts (struct-like buffers) with named fields
    - Slice, clone, reverse, fill, and compare buffers
    - Convert buffers to hex or binary strings for debugging
    - Efficient for hot paths and memory-sensitive systems
    - Fully optimized for --!native and --!optimize 2

    Design Philosophy:
    - Unsafe by design (no bounds checks)
    - Predictable constant-time operations
    - Composable for building higher-level serializers, ECS storage, or numeric systems

    This module is intended for:
    - Serialization and binary packet building
    - Custom numeric systems (BN, layered numbers, scientific)
    - ECS / archetype storage
    - Networking or performance-critical data formats

    Caller is responsible for buffer size, offsets, and type correctness.
]]

local module = {}

export type IntType = "i8"|"u8"|"i16"|"u16"|"i32"|"u32"
export type FloatType = "f32"|"f64"
export type ValueType = IntType | FloatType

export type Cursor = {
	buff: buffer,
	pos: number
}

export type LayoutField = {
	off: number,
	typ: ValueType
}

export type Layout = {
	size: number,
	fields: {[string]: LayoutField}
}

module.Size = {
	i8  = 1,  u8  = 1,
	i16 = 2,  u16 = 2,
	i32 = 4,  u32 = 4,
	f32 = 4,
	f64 = 8,
}

local writers = {
	i8 = buffer.writei8,
	u8 = buffer.writeu8,
	i16 = buffer.writei16,
	u16 = buffer.writeu16,
	i32 = buffer.writei32,
	u32 = buffer.writeu32,
	f32 = buffer.writef32,
	f64 = buffer.writef64,
}

local readers = {
	i8 = buffer.readi8,
	u8 = buffer.readu8,
	i16 = buffer.readi16,
	u16 = buffer.readu16,
	i32 = buffer.readi32,
	u32 = buffer.readu32,
	f32 = buffer.readf32,
	f64 = buffer.readf64,
}

--[[ Creates a new buffer with a fixed byte size
Example: module.new(12)
-- 1 byte i8 + 8 bytes f64 + 3 bytes padding
]]
function module.new(size: number): buffer
	return buffer.create(size)
end

-- Returns the length of a buffer in bytes
function module.len(buff: buffer): number
	return buffer.len(buff)
end

-- Zero-fills the entire buffer
function module.clear(buff: buffer): ()
	buffer.fill(buff, 0, 0, buffer.len(buff))
end

-- Copies raw bytes between buffers
function module.copy(dst: buffer, doff: number, src: buffer, soff: number, len: number): ()
	buffer.copy(dst, doff, src, soff, len)
end

--[[ Writes a value of the given type at a byte offset.
	⚠ No bounds checking.
	⚠ Caller must ensure offset + sizeof(type) is valid.
]]
function module.write(buff: buffer, typ: ValueType, off: number, val: any)
	writers[typ](buff, off, val)
end

--[[ Reads a value of the given type at a byte offset.
	⚠ No bounds checking.
]]
function module.read(buff: buffer, typ: ValueType, off: number)
	return readers[typ](buff, off)
end

--[[ Creates a cursor object for sequential reading/writing.
	The cursor tracks a mutable byte position.
]]
function module.cursor(buff: buffer, pos: number): Cursor
	return {buff = buff, pos = pos}
end

--[[ Writes a value at the cursor position
	and automatically advances the cursor.
	Used for sequential packing.
]]
function module.writeNext(cur: Cursor, typ: ValueType, val: any)
	writers[typ](cur.buff, cur.pos, val)
	cur.pos += module.Size[typ]
end

--[[ Reads a value at the cursor position
	and automatically advances the cursor.
]]
function module.readNext(cur: Cursor, typ: ValueType)
	local val = readers[typ](cur.buff, cur.pos)
	cur.pos += module.Size[typ]
	return val
end

-- Returns the byte size of a given primitive type
function module.sizeOf(typ: ValueType): number
	return module.Size[typ]
end

-- useful for padding or skipping fields
function module.advance(cur: Cursor, typ: ValueType)
	cur.pos += module.Size[typ]
end

--[[ Compiles a layout into fixed offsets.

	Input:
		{
			x = "f32",
			y = "f32",
			id = "u32"
		}

	Output:
		{
			size = total byte size,
			fields = {
				x = {off=0, typ="f32"},
				y = {off=4, typ="f32"},
				id = {off=8, typ="u32"}
			}
		}

	Run once, reuse forever.
]]
function module.compileLayout(lay): Layout
	local fields, cursor = {}, 0
	for i = 1, #lay do
		local entry = lay[i]
		local name, typ = entry[1], entry[2]
		fields[name] = {
			off = cursor,
			typ = typ
		}
		cursor += module.Size[typ]
	end
	return {
		size = cursor,
		fields = fields
	}
end

-- Creates a buffer sized exactly for a compiled layout
function module.structNew(lay: Layout): buffer
	return buffer.create(lay.size)
end

-- Reads a field from a structured buffer
function module.structGet(buff: buffer, lay: Layout, field: string)
	local f = lay.fields[field]
	return readers[f.typ](buff, f.off)
end

-- Writes a field into a structured buffer
function module.structSet(buff: buffer, lay: Layout, field: string, val: any)
	local f = lay.fields[field]
	writers[f.typ](buff, f.off, val)
end

-- Copies a portion of a buffer into a new buffer
function module.slice(buff: buffer, start: number, len: number): buffer
	local out = buffer.create(len)
	buffer.copy(out, 0, buff, start, len)
	return out
end

-- fill a range of buffer with a single value
function module.fillRange(buff: buffer, start: number, len: number, val: number)
	buffer.fill(buff, val, start, len)
end

-- Reverse the bytes in a buffer
function module.reverse(buff: buffer): ()
	local len = buffer.len(buff)
	for i = 0, (len // 2) - 1 do
		local a = buffer.readu8(buff, i)
		local b = buffer.readu8(buff, len - i - 1)
		buffer.writeu8(buff, i, b)
		buffer.writeu8(buff, len - i - 1, a)
	end
end

-- Compare two buffers (returns -1 if a < b, 0 if equal, 1 if a > b)
function module.compare(a: buffer, b: buffer): number
	local lenA = buffer.len(a)
	local lenB = buffer.len(b)
	local len = math.min(lenA, lenB)

	for i = 0, len - 1 do
		local va = buffer.readu8(a, i)
		local vb = buffer.readu8(b, i)
		if va < vb then return -1 end
		if va > vb then return 1 end
	end

	if lenA < lenB then return -1
	elseif lenA > lenB then return 1 end

	return 0
end

-- Clone a buffer
function module.clone(buff: buffer): buffer
	local len = buffer.len(buff)
	local out = buffer.create(len)
	buffer.copy(out, 0, buff, 0, len)
	return out
end

-- Convert a numeric buffer to hex string (useful for debugging)
function module.toHex(buff: buffer): string
	local len = buffer.len(buff)
	local s = table.create(len)

	for i = 0, len - 1 do
		s[i + 1] = string.format('%02X', buffer.readu8(buff, i))
	end

	return table.concat(s)
end

-- Convert a buffer to binary string (debugging or serialization)
function module.toBinaryString(buff: buffer): string
	local len = buffer.len(buff)
	local s = table.create(len)

	for i = 0, len - 1 do
		local byte = buffer.readu8(buff, i)
		local bits = table.create(8)

		for b = 7, 0, -1 do
			bits[8 - b] = (bit32.extract(byte, b) == 1) and "1" or "0"
		end

		s[i + 1] = table.concat(bits)
	end

	return table.concat(s)
end

return module