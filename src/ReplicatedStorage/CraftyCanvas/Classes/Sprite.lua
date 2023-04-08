local Types = require(script.Parent.Parent:WaitForChild("Types"))
local Utils = script.Parent.Parent:WaitForChild("Utils")
local Signal = require(Utils:WaitForChild("Signal"))

local Classes = script.Parent
local Tile = require(Classes:WaitForChild("Tile"))

local Sprite = {}
Sprite.__index = Sprite
setmetatable(Sprite, Tile)

function Sprite.new(TileName: string, GridPosition: Vector2, TileSize: Vector2, Room: Room): SpriteTile
	local self = Tile.new(TileName, GridPosition, TileSize, Room)
	setmetatable(self, Sprite)

	self.Type = "Sprite"
	self.Colliders = {}
	self.HitboxSize = Vector2.new(1, 1)

	self.Janitor:Add(function() if self.Touched then self.Touched:Destroy() end end) -- touched signal is only created if colliders are set.
	return self
end

function Sprite:AddCollider(ColliderName: string)
	table.insert(self.Colliders, ColliderName)
	if not self.Touched then self.Touched = Signal.new() end
end

function Sprite:SetColliders(Colliders: table)
	self.Colliders = Colliders
	if not self.Touched then self.Touched = Signal.new() end
end

function Sprite:GetColliders(): table
	return self.Colliders
end

function Sprite:SetHitboxSize(HitboxSize: Vector2) self.HitboxSize = HitboxSize end

local function AreUIColliding(UI1: GuiBase2d, UI2: GuiBase2d, DP1: Vector2?, DP2: Vector2?)
	local UI1P, UI1S = UI1.AbsolutePosition, UI1.AbsoluteSize
	local UI2P, UI2S = UI2.AbsolutePosition, UI2.AbsoluteSize
	local UI1R, UI2R = math.rad(UI1.AbsoluteRotation), math.rad(UI2.AbsoluteRotation)

	local DX, DY = 0, 0

	-- Decrease the size of guiObject1's collider by the given percentage
	if DP1 then
		DX = UI1S.X * DP1.X
		DY = UI1S.Y * DP1.Y
		UI1P = UI1P + Vector2.new(DX, DY)
		UI1S = UI1S - Vector2.new(DX * 2, DY * 2)
	end

	-- Decrease the size of guiObject2's collider by the given percentage
	if DP2 then
		DX = UI2S.X * DP2.X
		DY = UI2S.Y * DP2.Y
		UI2P = UI2P + Vector2.new(DX, DY)
		UI2S = UI2S - Vector2.new(DX * 2, DY * 2)
	end

	-- Check if the two colliders are overlapping
	if UI1P.X < UI2P.X + UI2S.X and
		UI1P.X + UI1S.X > UI2P.X and
		UI1P.Y < UI2P.Y + UI2S.Y and
		UI1P.Y + UI1S.Y > UI2P.Y then
		return true
	end

	return false
end

function Sprite:MoveByGrid(MoveDirection: Vector2)
	local CurrentGridPos = self.GridPosition
	local NewGridPos = Vector2.new(CurrentGridPos.X + MoveDirection.X, CurrentGridPos.Y + MoveDirection.Y)
	local NewPos = self.Room:GridPositionToPosition(NewGridPos)

	local CollideObject = Instance.new("ImageLabel")
	CollideObject.BackgroundTransparency = 1
	CollideObject.Size = self.Object.Size
	CollideObject.AnchorPoint = self.Object.AnchorPoint
	CollideObject.Position = UDim2.new(0, NewPos.X, 0, NewPos.Y)
	CollideObject.Rotation = self.Object.Rotation
	CollideObject.Parent = self.Room.Object

	local Touched = false
	for _, OtherSprite in ipairs(self.Room.Contents) do
		if OtherSprite.Type == "Sprite" and table.find(self.Colliders, OtherSprite.Name) then
			if AreUIColliding(CollideObject, OtherSprite.Object, Vector2.new(1, 1) - self.HitboxSize, Vector2.new(1, 1) - OtherSprite.HitboxSize) then
				if OtherSprite.Touched then OtherSprite.Touched:Fire(self) end
				Touched = OtherSprite
				break
			end
		end
	end

	CollideObject:Destroy()

	if not Touched then -- move if no touch occurred
		self.Object.Position = UDim2.new(0, NewPos.X, 0, NewPos.Y)
		self.GridPosition = NewGridPos
	elseif self.Touched then
		self.Touched:Fire(Touched)
	end

	return Touched
end

return Sprite
