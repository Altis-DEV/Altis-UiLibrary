-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Core.lua

local Core = {}

--// Services
local cloneref = cloneref or function(Object)
	return Object
end

local function GetService(Name)
	return cloneref(game:GetService(Name))
end

Core.Services = {
	TweenService = GetService("TweenService"),
	UserInputService = GetService("UserInputService"),
	Players = GetService("Players"),
	RunService = GetService("RunService"),
	CoreGui = GetService("CoreGui"),
}

--// Player
Core.LocalPlayer = Core.Services.Players.LocalPlayer
Core.PlayerGui = Core.LocalPlayer:WaitForChild("PlayerGui")

--// Environment
Core.IsStudio = Core.Services.RunService:IsStudio()
Core.NoWarnings = not Core.IsStudio

--// Constants
Core.UIAssetId = "rbxassetid://76246418997296"
Core.Animation = TweenInfo.new(0.1)

--// Utilities
function Core:Warn(...)
	if self.NoWarnings then
		return
	end

	warn("[IMGUI]", ...)
end

function Core:CreateInstance(ClassName, Parent, Properties)
	local Object = Instance.new(ClassName)

	for Key, Value in next, Properties or {} do
		Object[Key] = Value
	end

	Object.Parent = Parent

	return Object
end

function Core:Concat(List, Separator)
	Separator = Separator or " "

	local Result = ""

	for Index, Value in next, List do
		Result ..= tostring(Value)

		if Index ~= #List then
			Result ..= Separator
		end
	end

	return Result
end

--// Pointer tracking
Core.LastTouchPosition = nil

Core.Services.UserInputService.InputChanged:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.Touch then
		Core.LastTouchPosition = Input.Position
	end
end)

Core.Services.UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.Touch then
		Core.LastTouchPosition = nil
	end
end)

function Core:GetPointerPosition()
	if self.LastTouchPosition then
		return Vector2.new(
			self.LastTouchPosition.X,
			self.LastTouchPosition.Y
		)
	end

	return self.Services.UserInputService:GetMouseLocation()
end

return Core
