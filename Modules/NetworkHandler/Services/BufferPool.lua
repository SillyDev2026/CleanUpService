--!native
--!optimize 2

local BitBuffer = require(script.Parent.BitBuffer)
local BufferPool = {}
BufferPool.__index = BufferPool

export type BufferPool = {
	pool: {any},
	intialSize: number,
	acquire: (self: BufferPool) -> BitBuffer.BitBuffer,
	release: (self: BufferPool, buff: buffer) -> ()
}

function BufferPool.new(initialSize: number): BufferPool
	local self = {
		pool = {},
		initialSize = initialSize or 64
	}
	return setmetatable(self, BufferPool)
end

function BufferPool:acquire()
	local buff = table.remove(self.pool)
	if buff then
		buff:reset()
		return buff
	end
	return BitBuffer.new(self.initialSize)
end

function BufferPool:release(buff)
	if not buff then return end
	buff:reset()
	table.insert(self.pool, buff)
end

return BufferPool