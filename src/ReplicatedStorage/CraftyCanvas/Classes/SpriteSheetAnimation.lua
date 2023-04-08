local Types = require(script.Parent.Parent:WaitForChild("Types"))

local Utils = script.Parent.Parent:WaitForChild("Utils")
local Signal = require(Utils:WaitForChild("Signal"))
local Janitor = require(Utils:WaitForChild("Janitor"))

local SpriteSheetAnimation = {}
SpriteSheetAnimation.__index = SpriteSheetAnimation

function SpriteSheetAnimation.new(AnimName: string, Object: ImageLabel, Image: string, SpriteSize: Vector2, SpriteOffset: Vector2, SheetOffset: Vector2): SpriteSheetAnimation
	local self = {}
	setmetatable(self, SpriteSheetAnimation)

	self.Name = AnimName
	self.Image = Image
	self.SpriteSizePixel = SpriteSize
	self.SpriteOffsetPixel = SpriteOffset
	self.EdgeOffsetPixel = SheetOffset

	self.Object = Object

	self.Janitor = Janitor.new()

	self.PlayThread = nil
	self.CurrentFrameIndex = 0
	self.Frames = {}

	return self
end

function SpriteSheetAnimation:AddFrame(FramePosition: Vector2, FrameTime: number, Flipped: boolean?, CustomSize: Vector2?): AnimationFrame
	local Frame: AnimationFrame = {
		Position = FramePosition,
		FrameTime = FrameTime,
		CustomSize = CustomSize,
		FlipX = Flipped or false
	}

	table.insert(self.Frames, Frame)
	return Frame
end

function SpriteSheetAnimation:Update(FrameIndex: number)
	if not FrameIndex then FrameIndex = self.CurrentFrameIndex else self.CurrentFrameIndex = FrameIndex end

	local Frame = self.Frames[FrameIndex]
	if not Frame then return false end

	local Position = Frame.Position
	local Custom = Frame.CustomSize

	local EdgeOffsetPixel = self.EdgeOffsetPixel
	local SpriteSizePixel = self.SpriteSizePixel
	local SpriteOffsetPixel = self.SpriteOffsetPixel

	local RectSize = Custom or SpriteSizePixel

	local RectOffsetX = Custom and Custom.X or EdgeOffsetPixel.X + (Position.X * SpriteSizePixel.X) + (Position.X * SpriteOffsetPixel.X)
	local RectOffsetY = Custom and Custom.Y or EdgeOffsetPixel.Y + (Position.Y * SpriteSizePixel.Y) + (Position.Y * SpriteOffsetPixel.Y)

	if Frame.FlipX then
		RectOffsetX = RectSize.X + RectOffsetX
		RectSize = Vector2.new(-RectSize.X, RectSize.Y)
	end

	local RectOffset = Vector2.new(RectOffsetX, RectOffsetY)
	self.Object.ImageRectOffset = RectOffset
	self.Object.ImageRectSize = RectSize
	self.Object.Image = self.Image

	return true
end

function SpriteSheetAnimation:SetFrame(FrameIndex)
	return self:Update(FrameIndex)
end

function SpriteSheetAnimation:Play(Continue: boolean?)
	local StartFrame = Continue and self.CurrentFrameIndex or 0
	self.CurrentFrameIndex = StartFrame

	if self.PlayThread then task.cancel(self.PlayThread) end
	self.PlayThread = task.spawn(function()
		while true do
			self:Increment()
			local Frame = self.Frames[self.CurrentFrameIndex]
			task.wait(Frame.FrameTime)
		end
	end)
	return self.PlayThread
end

function SpriteSheetAnimation:Stop()
	if self.PlayThread then task.cancel(self.PlayThread) self.PlayThread = nil end
	self:SetFrame(1)
end

function SpriteSheetAnimation:Increment()
	self.CurrentFrameIndex += 1
	if self.CurrentFrameIndex > #self.Frames then
		self.CurrentFrameIndex = 1
	end
	self:Update()
end

function SpriteSheetAnimation:Destroy()
	self.Room = nil
	if self.SpriteClip then self.SpriteClip:Destroy() end
	self.Janitor:Destroy()
end

return SpriteSheetAnimation