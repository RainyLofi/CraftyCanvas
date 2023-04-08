local Types = require(script.Parent.Parent:WaitForChild("Types"))

local Utils = script.Parent.Parent:WaitForChild("Utils")
local Signal = require(Utils:WaitForChild("Signal"))
local Janitor = require(Utils:WaitForChild("Janitor"))
local SpriteClip = require(Utils:WaitForChild("SpriteClip"))

local Classes = script.Parent
local SpriteSheetAnimation = require(Classes:WaitForChild("SpriteSheetAnimation"))

local Tile = {}
Tile.__index = Tile

function Tile.new(TileName: string, GridPosition: Vector2, TileSize: Vector2, Room: Room): BackgroundTile
	local self = {}
	setmetatable(self, Tile)

	self.Name = TileName
	self.Type = "Background"
	self.TileSize = TileSize
	self.Room = Room
	self.GridPosition = GridPosition

	self.Janitor = Janitor.new()

	local Object = Instance.new("ImageLabel")
	Object.Name = TileName
	Object.BackgroundTransparency = 1
	Object.BorderSizePixel = 0
	Object.AnchorPoint = Vector2.new(0.5, 0.5)
	Object.ZIndex = 3
	Object.Parent = self.Room.Object
	self.Object = Object
	self.Janitor:Add(self.Object)

	self.Physics = false
	self.Animations = {}

	self:UpdateSizePosition()

	return self
end

function Tile:CreateSheetAnimation(AnimName: string, Image: string, SpriteSize: Vector2, SpriteOffset: Vector2, SheetOffset: Vector2): SpriteSheetAnimation
	local Anim: SpriteSheetAnimation = SpriteSheetAnimation.new(AnimName, self.Object, Image, SpriteSize, SpriteOffset, SheetOffset)

	table.insert(self.Animations, Anim)
	Anim.Janitor:Add(function()
		local Found = table.find(self.Animations, Anim)
		if Found then table.remove(self.Animations, Found) end
	end)

	return Anim
end

function Tile:UpdateSizePosition()
	local RoomSize = self.Room.Object.AbsoluteSize
	self.Object.Size = UDim2.new(0, (RoomSize.X / self.Room.GridSize.X) * self.TileSize.X, 0, (RoomSize.Y / self.Room.GridSize.Y) * self.TileSize.Y)
	self:SetPositionByGrid(self.GridPosition)
end

function Tile:SetPositionByGrid(GridPosition: Vector2)
	local NewPosition = self.Room:GridPositionToPosition(GridPosition)
	self.Object.Position = UDim2.new(0, NewPosition.X, 0, NewPosition.Y)
	self.GridPosition = GridPosition
	return NewPosition
end

function Tile:Destroy()
	self.Room = nil
	if self.SpriteClip then self.SpriteClip:Destroy() end
	self.Janitor:Destroy()
end

return Tile