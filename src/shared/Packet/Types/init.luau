--!strict
--!optimize 2

export type Cursor = {
	Buffer: buffer,
	BufferLength: number,
	BufferOffset: number,
	Instances: { Instance },
	InstancesOffset: number,
}

local activeCursor: Cursor
local activeBuffer: buffer
local bufferLength: number
local bufferOffset: number
local instances: { Instance }
local instancesOffset: number
local types = {}
local reads = {}
local writes = {}
local anyReads = {} :: { [any]: () -> any }
local anyWrites = {} :: { [any]: (any) -> () }

local function Allocate(bytes: number)
	local targetLength = bufferOffset + bytes
	if bufferLength < targetLength then
		while bufferLength < targetLength do
			bufferLength *= 2
		end
		local newBuffer = buffer.create(bufferLength)
		buffer.copy(newBuffer, 0, activeBuffer, 0, bufferOffset)
		activeCursor.Buffer = newBuffer
		activeBuffer = newBuffer
	end
end

local function ReadS8(): number
	local value = buffer.readi8(activeBuffer, bufferOffset)
	bufferOffset += 1
	return value
end
local function WriteS8(value: number)
	buffer.writei8(activeBuffer, bufferOffset, value)
	bufferOffset += 1
end
local function ReadS16(): number
	local value = buffer.readi16(activeBuffer, bufferOffset)
	bufferOffset += 2
	return value
end
local function WriteS16(value: number)
	buffer.writei16(activeBuffer, bufferOffset, value)
	bufferOffset += 2
end
local function ReadS24(): number
	local value = buffer.readbits(activeBuffer, bufferOffset * 8, 24) - 8388608
	bufferOffset += 3
	return value
end
local function WriteS24(value: number)
	buffer.writebits(activeBuffer, bufferOffset * 8, 24, value + 8388608)
	bufferOffset += 3
end
local function ReadS32(): number
	local value = buffer.readi32(activeBuffer, bufferOffset)
	bufferOffset += 4
	return value
end
local function WriteS32(value: number)
	buffer.writei32(activeBuffer, bufferOffset, value)
	bufferOffset += 4
end
local function ReadU8(): number
	local value = buffer.readu8(activeBuffer, bufferOffset)
	bufferOffset += 1
	return value
end
local function WriteU8(value: number)
	buffer.writeu8(activeBuffer, bufferOffset, value)
	bufferOffset += 1
end
local function ReadU16(): number
	local value = buffer.readu16(activeBuffer, bufferOffset)
	bufferOffset += 2
	return value
end
local function WriteU16(value: number)
	buffer.writeu16(activeBuffer, bufferOffset, value)
	bufferOffset += 2
end
local function ReadU24(): number
	local value = buffer.readbits(activeBuffer, bufferOffset * 8, 24)
	bufferOffset += 3
	return value
end
local function WriteU24(value: number)
	buffer.writebits(activeBuffer, bufferOffset * 8, 24, value)
	bufferOffset += 3
end
local function ReadU32(): number
	local value = buffer.readu32(activeBuffer, bufferOffset)
	bufferOffset += 4
	return value
end
local function WriteU32(value: number)
	buffer.writeu32(activeBuffer, bufferOffset, value)
	bufferOffset += 4
end
local function ReadF32(): number
	local value = buffer.readf32(activeBuffer, bufferOffset)
	bufferOffset += 4
	return value
end
local function WriteF32(value: number)
	buffer.writef32(activeBuffer, bufferOffset, value)
	bufferOffset += 4
end
local function ReadF64(): number
	local value = buffer.readf64(activeBuffer, bufferOffset)
	bufferOffset += 8
	return value
end
local function WriteF64(value: number)
	buffer.writef64(activeBuffer, bufferOffset, value)
	bufferOffset += 8
end
local function ReadString(length: number)
	local value = buffer.readstring(activeBuffer, bufferOffset, length)
	bufferOffset += length
	return value
end
local function WriteString(value: string)
	buffer.writestring(activeBuffer, bufferOffset, value)
	bufferOffset += #value
end
local function ReadBuffer(length: number)
	local value = buffer.create(length)
	buffer.copy(value, 0, activeBuffer, bufferOffset, length)
	bufferOffset += length
	return value
end
local function WriteBuffer(value: buffer)
	buffer.copy(activeBuffer, bufferOffset, value)
	bufferOffset += buffer.len(value)
end
local function ReadInstance()
	instancesOffset += 1
	return instances[instancesOffset]
end
local function WriteInstance(value)
	instancesOffset += 1
	instances[instancesOffset] = value
end

local function ReadF16(): number
	local bitOffset = bufferOffset * 8
	bufferOffset += 2
	local mantissa = buffer.readbits(activeBuffer, bitOffset + 0, 10)
	local exponent = buffer.readbits(activeBuffer, bitOffset + 10, 5)
	local sign = buffer.readbits(activeBuffer, bitOffset + 15, 1)
	if mantissa == 0b0000000000 then
		if exponent == 0b00000 then
			return 0
		end
		if exponent == 0b11111 then
			return if sign == 0 then math.huge else -math.huge
		end
	elseif exponent == 0b11111 then
		return 0 / 0
	end
	if sign == 0 then
		return (mantissa / 1024 + 1) * 2 ^ (exponent - 15)
	else
		return -(mantissa / 1024 + 1) * 2 ^ (exponent - 15)
	end
end
local function WriteF16(value: number)
	local bitOffset = bufferOffset * 8
	bufferOffset += 2
	if value == 0 then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b0_00000_0000000000)
	elseif value >= 65520 then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b0_11111_0000000000)
	elseif value <= -65520 then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b1_11111_0000000000)
	elseif value ~= value then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b0_11111_0000000001)
	else
		local sign = 0
		if value < 0 then
			sign = 1
			value = -value
		end
		local mantissa, exponent = math.frexp(value)
		buffer.writebits(activeBuffer, bitOffset + 0, 10, mantissa * 2048 - 1023.5)
		buffer.writebits(activeBuffer, bitOffset + 10, 5, exponent + 14)
		buffer.writebits(activeBuffer, bitOffset + 15, 1, sign)
	end
end

local function ReadF24(): number
	local bitOffset = bufferOffset * 8
	bufferOffset += 3
	local mantissa = buffer.readbits(activeBuffer, bitOffset + 0, 17)
	local exponent = buffer.readbits(activeBuffer, bitOffset + 17, 6)
	local sign = buffer.readbits(activeBuffer, bitOffset + 23, 1)
	if mantissa == 0b00000000000000000 then
		if exponent == 0b000000 then
			return 0
		end
		if exponent == 0b111111 then
			return if sign == 0 then math.huge else -math.huge
		end
	elseif exponent == 0b111111 then
		return 0 / 0
	end
	if sign == 0 then
		return (mantissa / 131072 + 1) * 2 ^ (exponent - 31)
	else
		return -(mantissa / 131072 + 1) * 2 ^ (exponent - 31)
	end
end
local function WriteF24(value: number)
	local bitOffset = bufferOffset * 8
	bufferOffset += 3
	if value == 0 then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b0_000000_00000000000000000)
	elseif value >= 4294959104 then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b0_111111_00000000000000000)
	elseif value <= -4294959104 then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b1_111111_00000000000000000)
	elseif value ~= value then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b0_111111_00000000000000001)
	else
		local sign = 0
		if value < 0 then
			sign = 1
			value = -value
		end
		local mantissa, exponent = math.frexp(value)
		buffer.writebits(activeBuffer, bitOffset + 0, 17, mantissa * 262144 - 131071.5)
		buffer.writebits(activeBuffer, bitOffset + 17, 6, exponent + 30)
		buffer.writebits(activeBuffer, bitOffset + 23, 1, sign)
	end
end

types.Any = "Any" :: any
reads.Any = function()
	return anyReads[ReadU8()]()
end
writes.Any = function(value: any)
	anyWrites[typeof(value)](value)
end

types.Nil = ("Nil" :: any) :: nil
reads.Nil = function()
	return nil
end
writes.Nil = function(value: nil) end

types.NumberS8 = ("NumberS8" :: any) :: number
reads.NumberS8 = function()
	return ReadS8()
end
writes.NumberS8 = function(value: number)
	Allocate(1)
	WriteS8(value)
end

types.NumberS16 = ("NumberS16" :: any) :: number
reads.NumberS16 = function()
	return ReadS16()
end
writes.NumberS16 = function(value: number)
	Allocate(2)
	WriteS16(value)
end

types.NumberS24 = ("NumberS24" :: any) :: number
reads.NumberS24 = function()
	return ReadS24()
end
writes.NumberS24 = function(value: number)
	Allocate(3)
	WriteS24(value)
end

types.NumberS32 = ("NumberS32" :: any) :: number
reads.NumberS32 = function()
	return ReadS32()
end
writes.NumberS32 = function(value: number)
	Allocate(4)
	WriteS32(value)
end

types.NumberU8 = ("NumberU8" :: any) :: number
reads.NumberU8 = function()
	return ReadU8()
end
writes.NumberU8 = function(value: number)
	Allocate(1)
	WriteU8(value)
end

types.NumberU16 = ("NumberU16" :: any) :: number
reads.NumberU16 = function()
	return ReadU16()
end
writes.NumberU16 = function(value: number)
	Allocate(2)
	WriteU16(value)
end

types.NumberU24 = ("NumberU24" :: any) :: number
reads.NumberU24 = function()
	return ReadU24()
end
writes.NumberU24 = function(value: number)
	Allocate(3)
	WriteU24(value)
end

types.NumberU32 = ("NumberU32" :: any) :: number
reads.NumberU32 = function()
	return ReadU32()
end
writes.NumberU32 = function(value: number)
	Allocate(4)
	WriteU32(value)
end

types.NumberF16 = ("NumberF16" :: any) :: number
reads.NumberF16 = function()
	return ReadF16()
end
writes.NumberF16 = function(value: number)
	Allocate(2)
	WriteF16(value)
end

types.NumberF24 = ("NumberF24" :: any) :: number
reads.NumberF24 = function()
	return ReadF24()
end
writes.NumberF24 = function(value: number)
	Allocate(3)
	WriteF24(value)
end

types.NumberF32 = ("NumberF32" :: any) :: number
reads.NumberF32 = function()
	return ReadF32()
end
writes.NumberF32 = function(value: number)
	Allocate(4)
	WriteF32(value)
end

types.NumberF64 = ("NumberF64" :: any) :: number
reads.NumberF64 = function()
	return ReadF64()
end
writes.NumberF64 = function(value: number)
	Allocate(8)
	WriteF64(value)
end

types.String = ("String" :: any) :: string
reads.String = function()
	return ReadString(ReadU8())
end
writes.String = function(value: string)
	local length = #value
	Allocate(1 + length)
	WriteU8(length)
	WriteString(value)
end

types.StringLong = ("StringLong" :: any) :: string
reads.StringLong = function()
	return ReadString(ReadU16())
end
writes.StringLong = function(value: string)
	local length = #value
	Allocate(2 + length)
	WriteU16(length)
	WriteString(value)
end

types.Buffer = ("Buffer" :: any) :: buffer
reads.Buffer = function()
	return ReadBuffer(ReadU8())
end
writes.Buffer = function(value: buffer)
	local length = buffer.len(value)
	Allocate(1 + length)
	WriteU8(length)
	WriteBuffer(value)
end

types.BufferLong = ("BufferLong" :: any) :: buffer
reads.BufferLong = function()
	return ReadBuffer(ReadU16())
end
writes.BufferLong = function(value: buffer)
	local length = buffer.len(value)
	Allocate(2 + length)
	WriteU16(length)
	WriteBuffer(value)
end

types.Instance = ("Instance" :: any) :: Instance

reads.Instance = function()
	return ReadInstance()
end
writes.Instance = function(value: Instance)
	WriteInstance(value)
end

types.Boolean8 = ("Boolean8" :: any) :: boolean
reads.Boolean8 = function()
	return ReadU8() == 1
end
writes.Boolean8 = function(value: boolean)
	Allocate(1)
	WriteU8(if value then 1 else 0)
end

types.NumberRange = ("NumberRange" :: any) :: NumberRange
reads.NumberRange = function()
	return NumberRange.new(ReadF32(), ReadF32())
end
writes.NumberRange = function(value: NumberRange)
	Allocate(8)
	WriteF32(value.Min)
	WriteF32(value.Max)
end

types.BrickColor = ("BrickColor" :: any) :: BrickColor
reads.BrickColor = function()
	return BrickColor.new(ReadU16())
end
writes.BrickColor = function(value: BrickColor)
	Allocate(2)
	WriteU16(value.Number)
end

types.Color3 = ("Color3" :: any) :: Color3
reads.Color3 = function()
	return Color3.fromRGB(ReadU8(), ReadU8(), ReadU8())
end
writes.Color3 = function(value: Color3)
	Allocate(3)
	WriteU8(value.R * 255 + 0.5)
	WriteU8(value.G * 255 + 0.5)
	WriteU8(value.B * 255 + 0.5)
end

types.UDim = ("UDim" :: any) :: UDim
reads.UDim = function()
	return UDim.new(ReadS16() / 1000, ReadS16())
end
writes.UDim = function(value: UDim)
	Allocate(4)
	WriteS16(value.Scale * 1000)
	WriteS16(value.Offset)
end

types.UDim2 = ("UDim2" :: any) :: UDim2
reads.UDim2 = function()
	return UDim2.new(ReadS16() / 1000, ReadS16(), ReadS16() / 1000, ReadS16())
end
writes.UDim2 = function(value: UDim2)
	Allocate(8)
	WriteS16(value.X.Scale * 1000)
	WriteS16(value.X.Offset)
	WriteS16(value.Y.Scale * 1000)
	WriteS16(value.Y.Offset)
end

types.Rect = ("Rect" :: any) :: Rect
reads.Rect = function()
	return Rect.new(ReadF32(), ReadF32(), ReadF32(), ReadF32())
end
writes.Rect = function(value: Rect)
	Allocate(16)
	WriteF32(value.Min.X)
	WriteF32(value.Min.Y)
	WriteF32(value.Max.X)
	WriteF32(value.Max.Y)
end

types.Vector2S16 = ("Vector2S16" :: any) :: Vector2
reads.Vector2S16 = function()
	return Vector2.new(ReadS16(), ReadS16())
end
writes.Vector2S16 = function(value: Vector2)
	Allocate(4)
	WriteS16(value.X)
	WriteS16(value.Y)
end

types.Vector2F24 = ("Vector2F24" :: any) :: Vector2
reads.Vector2F24 = function()
	return Vector2.new(ReadF24(), ReadF24())
end
writes.Vector2F24 = function(value: Vector2)
	Allocate(6)
	WriteF24(value.X)
	WriteF24(value.Y)
end

types.Vector2F32 = ("Vector2F32" :: any) :: Vector2
reads.Vector2F32 = function()
	return Vector2.new(ReadF32(), ReadF32())
end
writes.Vector2F32 = function(value: Vector2)
	Allocate(8)
	WriteF32(value.X)
	WriteF32(value.Y)
end

types.Vector3S16 = ("Vector3S16" :: any) :: Vector3
reads.Vector3S16 = function()
	return Vector3.new(ReadS16(), ReadS16(), ReadS16())
end
writes.Vector3S16 = function(value: Vector3)
	Allocate(6)
	WriteS16(value.X)
	WriteS16(value.Y)
	WriteS16(value.Z)
end

types.Vector3F24 = ("Vector3F24" :: any) :: Vector3
reads.Vector3F24 = function()
	return Vector3.new(ReadF24(), ReadF24(), ReadF24())
end
writes.Vector3F24 = function(value: Vector3)
	Allocate(9)
	WriteF24(value.X)
	WriteF24(value.Y)
	WriteF24(value.Z)
end

types.InstanceVector3F24Array = ("InstanceVector3F24Array" :: any) :: any
reads.InstanceVector3F24Array = function()
	local length = ReadU16()
	local result = table.create(length)
	for i = 1, length do
		result[i] = { ReadInstance() :: any, Vector3.new(ReadF24(), ReadF24(), ReadF24()) }
	end
	return result
end
writes.InstanceVector3F24Array = function(value: any)
	local length = #value
	if length > 65535 then
		length = 65535
	end
	Allocate(2)
	WriteU16(length)
	for i = 1, length do
		local update = value[i]
		WriteInstance(update[1])
		local pos = update[2]
		Allocate(9)
		WriteF24(pos.X)
		WriteF24(pos.Y)
		WriteF24(pos.Z)
	end
end

types.Vector3F32 = ("Vector3F32" :: any) :: Vector3
reads.Vector3F32 = function()
	return Vector3.new(ReadF32(), ReadF32(), ReadF32())
end
writes.Vector3F32 = function(value: Vector3)
	Allocate(12)
	WriteF32(value.X)
	WriteF32(value.Y)
	WriteF32(value.Z)
end

types.NumberU4 = ("NumberU4" :: any) :: { number }
reads.NumberU4 = function()
	local bitOffset = bufferOffset * 8
	bufferOffset += 1
	return {
		buffer.readbits(activeBuffer, bitOffset + 0, 4),
		buffer.readbits(activeBuffer, bitOffset + 4, 4),
	}
end
writes.NumberU4 = function(value: { number })
	Allocate(1)
	local bitOffset = bufferOffset * 8
	bufferOffset += 1
	buffer.writebits(activeBuffer, bitOffset + 0, 4, value[1])
	buffer.writebits(activeBuffer, bitOffset + 4, 4, value[2])
end

types.BooleanNumber = ("BooleanNumber" :: any) :: { Boolean: boolean, Number: number }
reads.BooleanNumber = function()
	local bitOffset = bufferOffset * 8
	bufferOffset += 1
	return {
		Boolean = buffer.readbits(activeBuffer, bitOffset + 0, 1) == 1,
		Number = buffer.readbits(activeBuffer, bitOffset + 1, 7),
	}
end
writes.BooleanNumber = function(value: { Boolean: boolean, Number: number })
	Allocate(1)
	local bitOffset = bufferOffset * 8
	bufferOffset += 1
	buffer.writebits(activeBuffer, bitOffset + 0, 1, if value.Boolean then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 1, 7, value.Number)
end

types.Boolean1 = ("Boolean1" :: any) :: { boolean }
reads.Boolean1 = function()
	local bitOffset = bufferOffset * 8
	bufferOffset += 1
	return {
		buffer.readbits(activeBuffer, bitOffset + 0, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 1, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 2, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 3, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 4, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 5, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 6, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 7, 1) == 1,
	}
end
writes.Boolean1 = function(value: { boolean })
	Allocate(1)
	local bitOffset = bufferOffset * 8
	bufferOffset += 1
	buffer.writebits(activeBuffer, bitOffset + 0, 1, if value[1] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 1, 1, if value[2] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 2, 1, if value[3] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 3, 1, if value[4] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 4, 1, if value[5] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 5, 1, if value[6] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 6, 1, if value[7] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 7, 1, if value[8] then 1 else 0)
end

types.CFrameF24U8 = ("CFrameF24U8" :: any) :: CFrame
reads.CFrameF24U8 = function()
	return CFrame.fromEulerAnglesXYZ(
		ReadU8() / 40.58451048843331,
		ReadU8() / 40.58451048843331,
		ReadU8() / 40.58451048843331
	) + Vector3.new(ReadF24(), ReadF24(), ReadF24())
end
writes.CFrameF24U8 = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	Allocate(12)
	WriteU8(rx * 40.58451048843331 + 0.5)
	WriteU8(ry * 40.58451048843331 + 0.5)
	WriteU8(rz * 40.58451048843331 + 0.5)
	WriteF24(value.X)
	WriteF24(value.Y)
	WriteF24(value.Z)
end

types.CFrameF32U8 = ("CFrameF32U8" :: any) :: CFrame
reads.CFrameF32U8 = function()
	return CFrame.fromEulerAnglesXYZ(
		ReadU8() / 40.58451048843331,
		ReadU8() / 40.58451048843331,
		ReadU8() / 40.58451048843331
	) + Vector3.new(ReadF32(), ReadF32(), ReadF32())
end
writes.CFrameF32U8 = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	Allocate(15)
	WriteU8(rx * 40.58451048843331 + 0.5)
	WriteU8(ry * 40.58451048843331 + 0.5)
	WriteU8(rz * 40.58451048843331 + 0.5)
	WriteF32(value.X)
	WriteF32(value.Y)
	WriteF32(value.Z)
end

types.CFrameF32U16 = ("CFrameF32U16" :: any) :: CFrame
reads.CFrameF32U16 = function()
	return CFrame.fromEulerAnglesXYZ(
		ReadU16() / 10430.219195527361,
		ReadU16() / 10430.219195527361,
		ReadU16() / 10430.219195527361
	) + Vector3.new(ReadF32(), ReadF32(), ReadF32())
end
writes.CFrameF32U16 = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	Allocate(18)
	WriteU16(rx * 10430.219195527361 + 0.5)
	WriteU16(ry * 10430.219195527361 + 0.5)
	WriteU16(rz * 10430.219195527361 + 0.5)
	WriteF32(value.X)
	WriteF32(value.Y)
	WriteF32(value.Z)
end

types.Region3 = ("Region3" :: any) :: Region3
reads.Region3 = function()
	return Region3.new(
		Vector3.new(ReadF32(), ReadF32(), ReadF32()),
		Vector3.new(ReadF32(), ReadF32(), ReadF32())
	)
end
writes.Region3 = function(value: Region3)
	local halfSize = value.Size / 2
	local minimum = value.CFrame.Position - halfSize
	local maximum = value.CFrame.Position + halfSize
	Allocate(24)
	WriteF32(minimum.X)
	WriteF32(minimum.Y)
	WriteF32(minimum.Z)
	WriteF32(maximum.X)
	WriteF32(maximum.Y)
	WriteF32(maximum.Z)
end

types.NumberSequence = ("NumberSequence" :: any) :: NumberSequence
reads.NumberSequence = function()
	local length = ReadU8()
	local keypoints = table.create(length)
	for index = 1, length do
		table.insert(keypoints, NumberSequenceKeypoint.new(ReadU8() / 255, ReadU8() / 255, ReadU8() / 255))
	end
	return NumberSequence.new(keypoints)
end
writes.NumberSequence = function(value: NumberSequence)
	local length = #value.Keypoints
	Allocate(1 + length * 3)
	WriteU8(length)
	for index, keypoint in value.Keypoints do
		WriteU8(keypoint.Time * 255 + 0.5)
		WriteU8(keypoint.Value * 255 + 0.5)
		WriteU8(keypoint.Envelope * 255 + 0.5)
	end
end

types.ColorSequence = ("ColorSequence" :: any) :: ColorSequence
reads.ColorSequence = function()
	local length = ReadU8()
	local keypoints = table.create(length)
	for index = 1, length do
		table.insert(
			keypoints,
			ColorSequenceKeypoint.new(ReadU8() / 255, Color3.fromRGB(ReadU8(), ReadU8(), ReadU8()))
		)
	end
	return ColorSequence.new(keypoints)
end
writes.ColorSequence = function(value: ColorSequence)
	local length = #value.Keypoints
	Allocate(1 + length * 4)
	WriteU8(length)
	for index, keypoint in value.Keypoints do
		WriteU8(keypoint.Time * 255 + 0.5)
		WriteU8(keypoint.Value.R * 255 + 0.5)
		WriteU8(keypoint.Value.G * 255 + 0.5)
		WriteU8(keypoint.Value.B * 255 + 0.5)
	end
end

local characterIndices = {}
local characters = require(script.Characters)
for index, value in characters do
	characterIndices[value] = index
end
local characterBits = math.ceil(math.log(#characters + 1, 2))
local characterBytes = characterBits / 8
types.Characters = ("Characters" :: any) :: string
reads.Characters = function()
	local length = ReadU8()
	local characterArray = table.create(length)
	local bitOffset = bufferOffset * 8
	bufferOffset += math.ceil(length * characterBytes)
	for index = 1, length do
		table.insert(characterArray, characters[buffer.readbits(activeBuffer, bitOffset, characterBits)])
		bitOffset += characterBits
	end
	return table.concat(characterArray)
end
writes.Characters = function(value: string)
	local length = #value
	local bytes = math.ceil(length * characterBytes)
	Allocate(1 + bytes)
	WriteU8(length)
	local bitOffset = bufferOffset * 8
	for index = 1, length do
		buffer.writebits(activeBuffer, bitOffset, characterBits, characterIndices[value:sub(index, index)])
		bitOffset += characterBits
	end
	bufferOffset += bytes
end

local enumIndices = {}
local enums = require(script.Enums)
for index, static in enums do
	enumIndices[static] = index
end
types.EnumItem = ("EnumItem" :: any) :: EnumItem
reads.EnumItem = function()
	return enums[ReadU8()]:FromValue(ReadU16())
end
writes.EnumItem = function(value: EnumItem)
	Allocate(3)
	WriteU8(enumIndices[value.EnumType])
	WriteU16(value.Value)
end

local staticIndices = {}
local statics = require(script.Static1)
for index, static in statics do
	staticIndices[static] = index
end
types.Static1 = ("Static1" :: any) :: any
reads.Static1 = function()
	return statics[ReadU8()]
end
writes.Static1 = function(value: any)
	Allocate(1)
	WriteU8(staticIndices[value] or 0)
end

local static2Indices = {}
local statics2 = require(script.Static2)
for index, static in statics2 do
	static2Indices[static] = index
end
types.Static2 = ("Static2" :: any) :: any
reads.Static2 = function()
	return statics2[ReadU8()]
end
writes.Static2 = function(value: any)
	Allocate(1)
	WriteU8(static2Indices[value] or 0)
end

local static3Indices = {}
local statics3 = require(script.Static3)
for index, static in statics3 do
	static3Indices[static] = index
end
types.Static3 = ("Static3" :: any) :: any
reads.Static3 = function()
	return statics3[ReadU8()]
end
writes.Static3 = function(value: any)
	Allocate(1)
	WriteU8(static3Indices[value] or 0)
end

anyReads[0] = function()
	return nil
end
anyWrites["nil"] = function(value: nil)
	Allocate(1)
	WriteU8(0)
end

anyReads[1] = function()
	return -ReadU8()
end
anyReads[2] = function()
	return -ReadU16()
end
anyReads[3] = function()
	return -ReadU24()
end
anyReads[4] = function()
	return -ReadU32()
end
anyReads[5] = function()
	return ReadU8()
end
anyReads[6] = function()
	return ReadU16()
end
anyReads[7] = function()
	return ReadU24()
end
anyReads[8] = function()
	return ReadU32()
end
anyReads[9] = function()
	return ReadF32()
end
anyReads[10] = function()
	return ReadF64()
end
anyWrites.number = function(value: number)
	if value % 1 == 0 then
		if value < 0 then
			if value > -256 then
				Allocate(2)
				WriteU8(1)
				WriteU8(-value)
			elseif value > -65536 then
				Allocate(3)
				WriteU8(2)
				WriteU16(-value)
			elseif value > -16777216 then
				Allocate(4)
				WriteU8(3)
				WriteU24(-value)
			elseif value > -4294967296 then
				Allocate(5)
				WriteU8(4)
				WriteU32(-value)
			else
				Allocate(9)
				WriteU8(10)
				WriteF64(value)
			end
		else
			if value < 256 then
				Allocate(2)
				WriteU8(5)
				WriteU8(value)
			elseif value < 65536 then
				Allocate(3)
				WriteU8(6)
				WriteU16(value)
			elseif value < 16777216 then
				Allocate(4)
				WriteU8(7)
				WriteU24(value)
			elseif value < 4294967296 then
				Allocate(5)
				WriteU8(8)
				WriteU32(value)
			else
				Allocate(9)
				WriteU8(10)
				WriteF64(value)
			end
		end
	elseif value > -1048576 and value < 1048576 then
		Allocate(5)
		WriteU8(9)
		WriteF32(value)
	else
		Allocate(9)
		WriteU8(10)
		WriteF64(value)
	end
end

anyReads[11] = function()
	return ReadString(ReadU8())
end
anyWrites.string = function(value: string)
	local length = #value
	Allocate(2 + length)
	WriteU8(11)
	WriteU8(length)
	WriteString(value)
end

anyReads[12] = function()
	return ReadBuffer(ReadU8())
end
anyWrites.buffer = function(value: buffer)
	local length = buffer.len(value)
	Allocate(2 + length)
	WriteU8(12)
	WriteU8(length)
	WriteBuffer(value)
end

anyReads[13] = function()
	return ReadInstance()
end
anyWrites.Instance = function(value: Instance)
	Allocate(1)
	WriteU8(13)
	WriteInstance(value)
end

anyReads[14] = function()
	return ReadU8() == 1
end
anyWrites.boolean = function(value: boolean)
	Allocate(2)
	WriteU8(14)
	WriteU8(if value then 1 else 0)
end

anyReads[15] = function()
	return NumberRange.new(ReadF32(), ReadF32())
end
anyWrites.NumberRange = function(value: NumberRange)
	Allocate(9)
	WriteU8(15)
	WriteF32(value.Min)
	WriteF32(value.Max)
end

anyReads[16] = function()
	return BrickColor.new(ReadU16())
end
anyWrites.BrickColor = function(value: BrickColor)
	Allocate(3)
	WriteU8(16)
	WriteU16(value.Number)
end

anyReads[17] = function()
	return Color3.fromRGB(ReadU8(), ReadU8(), ReadU8())
end
anyWrites.Color3 = function(value: Color3)
	Allocate(4)
	WriteU8(17)
	WriteU8(value.R * 255 + 0.5)
	WriteU8(value.G * 255 + 0.5)
	WriteU8(value.B * 255 + 0.5)
end

anyReads[18] = function()
	return UDim.new(ReadS16() / 1000, ReadS16())
end
anyWrites.UDim = function(value: UDim)
	Allocate(5)
	WriteU8(18)
	WriteS16(value.Scale * 1000)
	WriteS16(value.Offset)
end

anyReads[19] = function()
	return UDim2.new(ReadS16() / 1000, ReadS16(), ReadS16() / 1000, ReadS16())
end
anyWrites.UDim2 = function(value: UDim2)
	Allocate(9)
	WriteU8(19)
	WriteS16(value.X.Scale * 1000)
	WriteS16(value.X.Offset)
	WriteS16(value.Y.Scale * 1000)
	WriteS16(value.Y.Offset)
end

anyReads[20] = function()
	return Rect.new(ReadF32(), ReadF32(), ReadF32(), ReadF32())
end
anyWrites.Rect = function(value: Rect)
	Allocate(17)
	WriteU8(20)
	WriteF32(value.Min.X)
	WriteF32(value.Min.Y)
	WriteF32(value.Max.X)
	WriteF32(value.Max.Y)
end

anyReads[21] = function()
	return Vector2.new(ReadF32(), ReadF32())
end
anyWrites.Vector2 = function(value: Vector2)
	Allocate(9)
	WriteU8(21)
	WriteF32(value.X)
	WriteF32(value.Y)
end

anyReads[22] = function()
	return Vector3.new(ReadF32(), ReadF32(), ReadF32())
end
anyWrites.Vector3 = function(value: Vector3)
	Allocate(13)
	WriteU8(22)
	WriteF32(value.X)
	WriteF32(value.Y)
	WriteF32(value.Z)
end

anyReads[23] = function()
	return CFrame.fromEulerAnglesXYZ(
		ReadU16() / 10430.219195527361,
		ReadU16() / 10430.219195527361,
		ReadU16() / 10430.219195527361
	) + Vector3.new(ReadF32(), ReadF32(), ReadF32())
end
anyWrites.CFrame = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	Allocate(19)
	WriteU8(23)
	WriteU16(rx * 10430.219195527361 + 0.5)
	WriteU16(ry * 10430.219195527361 + 0.5)
	WriteU16(rz * 10430.219195527361 + 0.5)
	WriteF32(value.X)
	WriteF32(value.Y)
	WriteF32(value.Z)
end

anyReads[24] = function()
	return Region3.new(
		Vector3.new(ReadF32(), ReadF32(), ReadF32()),
		Vector3.new(ReadF32(), ReadF32(), ReadF32())
	)
end
anyWrites.Region3 = function(value: Region3)
	local halfSize = value.Size / 2
	local minimum = value.CFrame.Position - halfSize
	local maximum = value.CFrame.Position + halfSize
	Allocate(25)
	WriteU8(24)
	WriteF32(minimum.X)
	WriteF32(minimum.Y)
	WriteF32(minimum.Z)
	WriteF32(maximum.X)
	WriteF32(maximum.Y)
	WriteF32(maximum.Z)
end

anyReads[25] = function()
	local length = ReadU8()
	local keypoints = table.create(length)
	for index = 1, length do
		table.insert(keypoints, NumberSequenceKeypoint.new(ReadU8() / 255, ReadU8() / 255, ReadU8() / 255))
	end
	return NumberSequence.new(keypoints)
end
anyWrites.NumberSequence = function(value: NumberSequence)
	local length = #value.Keypoints
	Allocate(2 + length * 3)
	WriteU8(25)
	WriteU8(length)
	for index, keypoint in value.Keypoints do
		WriteU8(keypoint.Time * 255 + 0.5)
		WriteU8(keypoint.Value * 255 + 0.5)
		WriteU8(keypoint.Envelope * 255 + 0.5)
	end
end

anyReads[26] = function()
	local length = ReadU8()
	local keypoints = table.create(length)
	for index = 1, length do
		table.insert(
			keypoints,
			ColorSequenceKeypoint.new(ReadU8() / 255, Color3.fromRGB(ReadU8(), ReadU8(), ReadU8()))
		)
	end
	return ColorSequence.new(keypoints)
end
anyWrites.ColorSequence = function(value: ColorSequence)
	local length = #value.Keypoints
	Allocate(2 + length * 4)
	WriteU8(26)
	WriteU8(length)
	for index, keypoint in value.Keypoints do
		WriteU8(keypoint.Time * 255 + 0.5)
		WriteU8(keypoint.Value.R * 255 + 0.5)
		WriteU8(keypoint.Value.G * 255 + 0.5)
		WriteU8(keypoint.Value.B * 255 + 0.5)
	end
end

anyReads[27] = function()
	return enums[ReadU8()]:FromValue(ReadU16())
end
anyWrites.EnumItem = function(value: EnumItem)
	Allocate(4)
	WriteU8(27)
	WriteU8(enumIndices[value.EnumType])
	WriteU16(value.Value)
end

anyReads[28] = function()
	local value = {}
	while true do
		local typeId = ReadU8()
		if typeId == 0 then
			return value
		else
			value[anyReads[typeId]()] = anyReads[ReadU8()]()
		end
	end
end
anyWrites.table = function(value: { [any]: any })
	Allocate(1)
	WriteU8(28)
	for index, value in value do
		anyWrites[typeof(index)](index)
		anyWrites[typeof(value)](value)
	end
	Allocate(1)
	WriteU8(0)
end

return {
	Import = function(cursor: Cursor)
		activeCursor = cursor
		activeBuffer = cursor.Buffer
		bufferLength = cursor.BufferLength
		bufferOffset = cursor.BufferOffset
		instances = cursor.Instances
		instancesOffset = cursor.InstancesOffset
	end,

	Export = function()
		activeCursor.BufferLength = bufferLength
		activeCursor.BufferOffset = bufferOffset
		activeCursor.InstancesOffset = instancesOffset
		return activeCursor
	end,

	Truncate = function()
		local truncatedBuffer = buffer.create(bufferOffset)
		buffer.copy(truncatedBuffer, 0, activeBuffer, 0, bufferOffset)
		if instancesOffset == 0 then
			return truncatedBuffer
		else
			return truncatedBuffer, instances
		end
	end,

	Ended = function()
		return bufferOffset >= bufferLength
	end,

	Types = types,
	Reads = reads,
	Writes = writes,
}
