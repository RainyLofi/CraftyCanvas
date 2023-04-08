local Types = require(script.Parent.Parent:WaitForChild("Types"))

local Utils = script.Parent.Parent:WaitForChild("Utils")
local Signal = require(Utils:WaitForChild("Signal"))
local Janitor = require(Utils:WaitForChild("Janitor"))

local Classes = script.Parent
local RoomObject = require(Classes:WaitForChild("Room"))

local CanvasObject = {}
CanvasObject.__index = CanvasObject

function CanvasObject.new(CanvasName: string): Canvas
	local self = {}
	setmetatable(self, CanvasObject)

	self.Name = CanvasName

	self.Janitor = Janitor.new()

	local Object = Instance.new("ScreenGui")
	Object.Name = CanvasName
	Object.IgnoreGuiInset = true
	Object.ResetOnSpawn = false
	Object.ZIndexBehavior = Enum.ZIndexBehavior.Global
	Object.Enabled = false
	self.Object = Object
	self.Janitor:Add(self.Object)

	self.BackFillFrame = nil

	self.ActiveRoom = nil
	self.Rooms = {}

	self.OnActiveRoomChanged = Signal.new()
	self.Janitor:Add(self.OnActiveRoomChanged)

	local SizeUpdateCon = nil
	local UpdateSize = nil
	UpdateSize = function()
		if SizeUpdateCon then SizeUpdateCon:Disconnect() end
		for _, Room in ipairs(self.Rooms) do Room:Update() end
		SizeUpdateCon = self.Object:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateSize)
	end
	UpdateSize()
	self.Janitor:Add(function() if SizeUpdateCon then SizeUpdateCon:Disconnect() end end)

	return self
end

function CanvasObject:CreateRoom(RoomName: string, AspectRatio: number, GridSize: Vector2, Size: UDim2?): Room
	local Room: Room = RoomObject.new(RoomName, AspectRatio, GridSize, Size)
	Room.Object.Parent = self.Object

	table.insert(self.Rooms, Room)
	Room.Janitor:Add(function()
		local Found = table.find(self.Rooms, Room)
		if Found then table.remove(self.Rooms, Found) end

		if self.ActiveRoom == Room then
			self.ActiveRoom = nil
			self.OnActiveRoomChanged:Fire(self.ActiveRoom)
		end
	end)

	return Room
end

function CanvasObject:GetRoomFromName(RoomName: string): Room?
	for _, Room in ipairs(self.Rooms) do
		if Room.Name == RoomName then return Room end
	end
end

function CanvasObject:SetActiveRoom(Room: Room)
	self.ActiveRoom = Room
	Room.Object.Visible = true
	for _, otherRoom in ipairs(self.Rooms) do
		if otherRoom ~= Room then
			otherRoom.Object.Visible = false
		end
	end
	self.OnActiveRoomChanged:Fire(self.ActiveRoom)
end

function CanvasObject:GetActiveRoom(): Room?
	return self.ActiveRoom
end

function CanvasObject:SetBackFill(Color: Color3)
	if not self.BackFillFrame then
		local Frame = Instance.new("Frame")
		Frame.Name = "BackFill"
		Frame.AnchorPoint = Vector2.new(0.5, 0.5)
		Frame.Size = UDim2.new(2, 0, 2, 0)
		Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		Frame.BackgroundColor3 = Color
		Frame.BorderSizePixel = 0
		Frame.ZIndex = 1
		Frame.Parent = self.Object
		self.BackFillFrame = Frame
	else
		self.BackFillFrame.BackgroundColor3 = Color3
	end
end

function CanvasObject:GetBackFill(): Frame? return self.BackFillFrame end

function CanvasObject:Destroy()
	for _, Room in ipairs(self.Rooms) do Room:Destroy() end
	self.Janitor:Destroy()
end

return CanvasObject