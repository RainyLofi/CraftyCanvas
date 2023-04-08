local Types = require(script.Parent.Parent:WaitForChild("Types"))

local Utils = script.Parent.Parent:WaitForChild("Utils")
local Signal = require(Utils:WaitForChild("Signal"))
local Janitor = require(Utils:WaitForChild("Janitor"))

local Classes = script.Parent
local TileObject = require(Classes:WaitForChild("Tile"))
local SpriteObject = require(Classes:WaitForChild("Sprite"))

local Room = {}
Room.__index = Room

function Room.new(RoomName: string, AspectRatio: number, GridSize: Vector2, Size: UDim2?): Room
	local self = {}
	setmetatable(self, Room)

	self.Name = RoomName
	self.GridSize = GridSize

	self.Janitor = Janitor.new()

	if not Size then Size = UDim2.new(1, 0, 1, 0) end
	self.GoalSize = Size

	local Object = Instance.new("Frame")
	Object.Name = RoomName
	Object.BackgroundTransparency = 1
	Object.Size = Size
	Object.Position = UDim2.new(0.5, 0, 0.5, 0)
	Object.AnchorPoint = Vector2.new(0.5, 0.5)
	Object.Visible = false
	Object.ZIndex = 2
	self.Object = Object
	self.Janitor:Add(self.Object)

	self.Camera = Vector2.new(self.GridSize.X, self.GridSize.Y) / 2

	local AspectConstraint = Instance.new("UIAspectRatioConstraint")
	AspectConstraint.AspectRatio = AspectRatio
    AspectConstraint.Parent = Object
	self.AspectRatio = AspectConstraint

	self.Physics = false
	self.Contents = {}

	self.LastUpdate = 0

	return self
end

function Room:CreateBackgroundTile(TileName: string, Position: Vector2, Size: Vector2?): BackgroundTile
	if not Size then Size = Vector2.new(1, 1) end

	local Tile: Tile = TileObject.new(TileName, Position, Size, self)

	table.insert(self.Contents, Tile)
	Tile.Janitor:Add(function()
		local Found = table.find(self.Contents, Tile)
		if Found then table.remove(self.Contents, Found) end
	end)

	return Tile
end

function Room:CreateSpriteTile(TileName: string, Position: Vector2, Size: Vector2?): SpriteTile
	if not Size then Size = Vector2.new(1, 1) end

	local Sprite: Sprite = SpriteObject.new(TileName, Position, Size, self)

	table.insert(self.Contents, Sprite)
	Sprite.Janitor:Add(function()
		local Found = table.find(self.Contents, Sprite)
		if Found then table.remove(self.Contents, Found) end
	end)

	return Sprite
end

function Room:SetMinimumTileSize(MinSize: Vector2) -- the minimum size of a tile in pixels
	local GridSize = self.GridSize
	local RoomSizeX = MinSize.X * GridSize.X
	local RoomSizeY = MinSize.Y * GridSize.Y

	if not self.SizeConstraint then
		local Constraint = Instance.new("UISizeConstraint")
		Constraint.Parent = self.Object
		self.SizeConstraint = Constraint
	end

	self.SizeConstraint.MinSize = Vector2.new(RoomSizeX, RoomSizeY)
end

function Room:SetCameraPointFromGrid(CameraPointGrid: Vector2)
	self.Camera = CameraPointGrid
	for _, Content in ipairs(self.Contents) do Content:UpdateSizePosition() end
end

function Room:GridPositionToPosition(GridPosition: Vector2)
	local RoomSize = self.Object.AbsoluteSize
	local GridSize = self.GridSize

	local TileSizeX = RoomSize.X / GridSize.X
	local TileSizeY = RoomSize.Y / GridSize.Y

	local XPos = (GridPosition.X ) * TileSizeX
	local YPos = (GridPosition.Y ) * TileSizeY

	local CameraPos = self.Camera
	XPos -= ((CameraPos.X - 0.5) * TileSizeX) - (((GridSize.X - 1) / 2) * TileSizeX)
	YPos -= ((CameraPos.Y - 0.5) * TileSizeY) - (((GridSize.Y - 1) / 2) * TileSizeY)

	return Vector2.new(XPos, YPos)
end

function Room:Update()
	if tick() - self.LastUpdate <= 1 then task.wait(1) end
	self.LastUpdate = tick()

	self.Object.Size = self.GoalSize
	self.AspectRatio.Parent = self.Object

	task.defer(function()
		local NewSize: Vector2 = self.Object.AbsoluteSize
		local XSize: number = NewSize.X
		local YSize: number = NewSize.Y

		local GridSize = self.GridSize

		local XMod = XSize % GridSize.X
		if XMod ~= 0 then XSize -= XMod end

		local YMod = YSize % GridSize.Y
		if YMod ~= 0 then YSize -= YMod end

		self.AspectRatio.Parent = nil
		self.Object.Size = UDim2.new(0, XSize, 0, YSize)
		for _, Content in ipairs(self.Contents) do Content:UpdateSizePosition() end
	end)
end

function Room:GetFrame(): Frame return self.Object end

function Room:SetPhysics(PhysicsData: PhysicsConfig)
	self.Physics = PhysicsData
end

function Room:Destroy()
	for _, Content in ipairs(self.Contents) do Content:Destroy() end
	self.Janitor:Destroy()
end

return Room