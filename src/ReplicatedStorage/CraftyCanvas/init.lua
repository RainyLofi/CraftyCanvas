--[[
	  ___              __  _    _  _   ___
	 / __| _ _  __ _  / _|| |_ | || | / __| __ _  _ _  __ __ __ _  ___
	| (__ | '_|/ _` ||  _||  _| \_. || (__ / _` || ' \ \ V // _` |(_-/
	 \___||_|  \__/_||_|   \__| |__/  \___|\__/_||_||_| \_/ \__/_|/__/

	 CraftyCanvas

	 Author: RainyLofi
	 Start date: 03/04/23
	 Takes inspiration and functionality from Nature2D by jaipack17.
]]--

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Types = require(script:WaitForChild("Types"))

local Classes = script:WaitForChild("Classes")
local CanvasObject = require(Classes:WaitForChild("Canvas"))

local Utils = script:WaitForChild("Utils")
local Signal = require(Utils:WaitForChild("Signal"))

----------------------------------------------------------------

local CraftyCanvas: CraftyCanvas = {}
CraftyCanvas.ActiveCanvas = nil
CraftyCanvas.Canvases = {}
CraftyCanvas.OnActiveCanvasChanged = Signal.new()

CraftyCanvas.SetActiveCanvas = function(Canvas: Canvas)
	CraftyCanvas.ActiveCanvas = Canvas
	Canvas.Object.Enabled = true
	for _, OtherCanvas in ipairs(CraftyCanvas.Canvases) do
		if OtherCanvas ~= Canvas then
			Canvas.Object.Enabled = false
		end
	end
	CraftyCanvas.OnActiveCanvasChanged:Fire(CraftyCanvas.ActiveCanvas)
end

CraftyCanvas.GetActiveCanvas = function(): Canvas?
	return CraftyCanvas.ActiveCanvas
end

CraftyCanvas.GetCanvasFromName = function(CanvasName: string): Canvas?
	for _, Canvas in ipairs(CraftyCanvas.Canvases) do
		if Canvas.Name == CanvasName then return Canvas end
	end
end

CraftyCanvas.CreateCanvas = function(CanvasName: string): Canvas
	local Canvas: Canvas = CanvasObject.new(CanvasName)
	Canvas.Object.Parent = PlayerGui

	table.insert(CraftyCanvas.Canvases, Canvas)
	Canvas.Janitor:Add(function()
		local Found = table.find(CraftyCanvas.Canvases, Canvas)
		if Found then table.remove(CraftyCanvas.Canvases, Found) end

		if CraftyCanvas.ActiveCanvas == Canvas then
			CraftyCanvas.ActiveCanvas = nil
			CraftyCanvas.OnActiveCanvasChanged:Fire(CraftyCanvas.ActiveCanvas)
		end
	end)

	return Canvas
end

return CraftyCanvas