-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Core.lua

local Core = {}

--==============================================================
-- SERVICES
--==============================================================

local cloneref = cloneref or function(Object)
	return Object
end

function Core:GetService(Name)
	return cloneref(game:GetService(Name))
end

Core.Services = {
	TweenService = Core:GetService("TweenService"),
	UserInputService = Core:GetService("UserInputService"),
	Players = Core:GetService("Players"),
	RunService = Core:GetService("RunService"),
	CoreGui = Core:GetService("CoreGui"),
}

--==============================================================
-- PLAYER
--==============================================================

Core.LocalPlayer = Core.Services.Players.LocalPlayer
Core.PlayerGui = Core.LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- ENVIRONMENT
--==============================================================

Core.IsStudio = Core.Services.RunService:IsStudio()
Core.NoWarnings = not Core.IsStudio

--==============================================================
-- CONFIG
--==============================================================

Core.UIAssetId = "rbxassetid://76246418997296"
Core.Animation = TweenInfo.new(0.1)

--==============================================================
-- UTILITIES
--==============================================================

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

function Core:Concat(Table, Separator)
	Separator = Separator or " "

	local Result = ""

	for Index, Value in next, Table do
		Result ..= tostring(Value)

		if Index ~= #Table then
			Result ..= Separator
		end
	end

	return Result
end

function Core:GetName(Name)
	return string.format("%s_", Name)
end

--==============================================================
-- POINTER
--==============================================================

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

--==============================================================
-- ANIMATIONS
--==============================================================

Core.Animations = {
	Buttons = {
		MouseEnter = {
			BackgroundTransparency = 0.5,
		},

		MouseLeave = {
			BackgroundTransparency = 0.7,
		},
	},

	Tabs = {
		MouseEnter = {
			BackgroundTransparency = 0.5,
		},

		MouseLeave = {
			BackgroundTransparency = 1,
		},
	},

	Inputs = {
		MouseEnter = {
			BackgroundTransparency = 0,
		},

		MouseLeave = {
			BackgroundTransparency = 0.5,
		},
	},

	WindowBorder = {
		Selected = {
			Transparency = 0,
			Thickness = 1,
		},

		Deselected = {
			Transparency = 0.7,
			Thickness = 1,
		},
	},
}

function Core:GetAnimation(Animation)
	if Animation then
		return self.Animation
	end

	return TweenInfo.new(0)
end

function Core:Tween(Instance, Properties, TweenInfoValue, NoAnimation)
	local Info =
		TweenInfoValue
		or self:GetAnimation(not NoAnimation)

	local Tween = self.Services.TweenService:Create(
		Instance,
		Info,
		Properties
	)

	Tween:Play()

	return Tween
end

function Core:ApplyAnimations(Instance, AnimationType, Target)
	local AnimationConfig =
		self.Animations[AnimationType]

	if not AnimationConfig then
		self:Warn(
			"No animation configuration for",
			AnimationType
		)

		return
	end

	Target = Target or Instance

	local Connections = {}

	for EventName, Properties in next, AnimationConfig do
		if typeof(Properties) ~= "table" then
			continue
		end

		local Callback = function()
			self:Tween(
				Target,
				Properties
			)
		end

		Connections[EventName] = Callback

		Instance[EventName]:Connect(Callback)
	end

	if Connections.MouseLeave then
		Connections.MouseLeave()
	end

	return Connections
end

function Core:HeaderAnimate(
	Header,
	Animation,
	Open,
	TitleBar,
	Toggle
)
	local ToggleButton =
		Toggle
		or TitleBar.Toggle.ToggleButton

	self:Tween(
		ToggleButton,
		{
			Rotation = Open and 90 or 0,
		}
	)

	local Container =
		Header:FindFirstChild("ChildContainer")

	if not Container then
		return
	end

	local UIListLayout =
		Container:FindFirstChildOfClass("UIListLayout")

	if not UIListLayout then
		return
	end

	local UIPadding =
		Container:FindFirstChildOfClass("UIPadding")

	local ContentSize =
		UIListLayout.AbsoluteContentSize

	if UIPadding then
		ContentSize = Vector2.new(
			ContentSize.X,
			ContentSize.Y
				+ UIPadding.PaddingTop.Offset
				+ UIPadding.PaddingBottom.Offset
		)
	end

	Container.AutomaticSize =
		Enum.AutomaticSize.None

	if not Open then
		Container.Size =
			UDim2.new(
				1,
				-10,
				0,
				ContentSize.Y
			)
	end

	local Tween =
		self:Tween(
			Container,
			{
				Size =
					UDim2.new(
						1,
						-10,
						0,
						Open and ContentSize.Y or 0
					),

				Visible = Open,
			}
		)

	Tween.Completed:Connect(function()
		if not Open then
			return
		end

		Container.AutomaticSize =
			Enum.AutomaticSize.Y

		Container.Size =
			UDim2.new(
				1,
				0,
				0,
				0
			)
	end)
end

--==============================================================
-- STYLES
--==============================================================

Core.AdditionalStyles = {
	[{
		Name = "Border",
	}] = function(GuiObject, Value, Class)
		local Outline =
			GuiObject:FindFirstChildOfClass("UIStroke")

		if not Outline then
			return
		end

		if Class.BorderThickness then
			Outline.Thickness =
				Class.BorderThickness
		end

		Outline.Enabled = Value
	end,

	[{
		Name = "Ratio",
	}] = function(GuiObject, Value, Class)
		local RatioAxis =
			Class.RatioAxis or "Height"

		local AspectRatio =
			Class.Ratio or 4 / 3

		local AspectType =
			Class.AspectType
			or Enum.AspectType.ScaleWithParentSize

		local Ratio =
			GuiObject:FindFirstChildOfClass(
				"UIAspectRatioConstraint"
			)

		if not Ratio then
			Ratio = Core:CreateInstance(
				"UIAspectRatioConstraint",
				GuiObject
			)
		end

		Ratio.DominantAxis =
			Enum.DominantAxis[RatioAxis]

		Ratio.AspectType =
			AspectType

		Ratio.AspectRatio =
			AspectRatio
	end,

	[{
		Name = "CornerRadius",
		Recursive = true,
	}] = function(GuiObject, Value, Class)
		local Corner =
			GuiObject:FindFirstChildOfClass(
				"UICorner"
			)

		if not Corner then
			Corner = Core:CreateInstance(
				"UICorner",
				GuiObject
			)
		end

		Corner.CornerRadius =
			Class.CornerRadius
	end,

	[{
		Name = "Label",
	}] = function(GuiObject, Value, Class)
		local Label =
			GuiObject:FindFirstChild("Label")

		if not Label then
			return
		end

		Label.Text =
			Class.Label

		function Class:SetLabel(Text)
			Label.Text = Text

			return Class
		end
	end,

	[{
		Name = "NoGradient",
		Aliases = {
			"NoGradientAll",
		},
		Recursive = true,
	}] = function(GuiObject, Value)
		local Gradient =
			GuiObject:FindFirstChildOfClass(
				"UIGradient"
			)

		if not Gradient then
			return
		end

		Gradient.Enabled = not Value
	end,

	[{
		Name = "Callback",
	}] = function(GuiObject, Value, Class)
		function Class:SetCallback(NewCallback)
			Class.Callback = NewCallback
			return Class
		end

		function Class:FireCallback(...)
			if Class.Callback then
				return Class.Callback(
					GuiObject,
					...
				)
			end
		end
	end,

	[{
		Name = "Value",
	}] = function(GuiObject, Value, Class)
		function Class:GetValue()
			return Class.Value
		end
	end,
}

function Core:ApplyColors(
	ColorOverwrites,
	GuiObject,
	ElementType
)
	for Info, Value in next, ColorOverwrites or {} do
		local Key = Info
		local Recursive = false

		if typeof(Info) == "table" then
			Key = Info.Name or ""
			Recursive = Info.Recursive or false
		end

		if typeof(Value) == "table" then
			local Element =
				GuiObject:FindFirstChild(
					Key,
					Recursive
				)

			if not Element
				and ElementType == "Window"
				and GuiObject:FindFirstChild("Content") then

				Element =
					GuiObject.Content:FindFirstChild(
						Key,
						Recursive
					)
			end

			if Element then
				self:ApplyColors(
					Value,
					Element
				)
			end

			continue
		end

		pcall(function()
			GuiObject[Key] = Value
		end)
	end
end

function Core:CheckStyles(
	GuiObject,
	Class,
	Colors
)
	for Info, Callback in next, self.AdditionalStyles do
		local Value =
			Class[Info.Name]

		if Value == nil
			and Info.Aliases then

			for _, Alias in next, Info.Aliases do
				Value = Class[Alias]

				if Value ~= nil then
					break
				end
			end
		end

		if Value == nil then
			continue
		end

		Callback(
			GuiObject,
			Value,
			Class
		)

		if Info.Recursive then
			for _, Child in next, GuiObject:GetChildren() do
				Callback(
					Child,
					Value,
					Class
				)
			end
		end
	end

	local ElementType =
		GuiObject.Name

	GuiObject.Name =
		self:GetName(ElementType)

	local ColorConfig =
		(Colors or {})[ElementType]

	if ColorConfig then
		self:ApplyColors(
			ColorConfig,
			GuiObject,
			ElementType
		)
	end

	for Key, Value in next, Class do
		pcall(function()
			GuiObject[Key] = Value
		end)
	end
end

--==============================================================
-- INSTANCE / CLASS BRIDGE
--==============================================================

function Core:MergeMetatables(Class, Instance)
	local Metadata = {}

	Metadata.__index = function(_, Key)
		local Success, Value =
			pcall(function()
				local Result = Instance[Key]

				if typeof(Result) == "function" then
					return function(...)
						return Result(
							Instance,
							...
						)
					end
				end

				return Result
			end)

		if Success then
			return Value
		end

		return Class[Key]
	end

	Metadata.__newindex = function(_, Key, Value)
		local ClassValue =
			Class[Key]

		if ClassValue ~= nil
			or typeof(Value) == "function" then

			Class[Key] = Value
		else
			Instance[Key] = Value
		end
	end

	return setmetatable({}, Metadata)
end

--==============================================================
-- HOVER
--==============================================================

function Core:ConnectHover(Config)
	local Parent = Config.Parent
	local Connections = {}

	Config.Hovering = false

	table.insert(
		Connections,
		Parent.MouseEnter:Connect(function()
			Config.Hovering = true
		end)
	)

	table.insert(
		Connections,
		Parent.MouseLeave:Connect(function()
			Config.Hovering = false
		end)
	)

	if Config.OnInput then
		table.insert(
			Connections,
			self.Services.UserInputService.InputBegan:Connect(
				function(Input)
					return Config.OnInput(
						Config.Hovering,
						Input
					)
				end
			)
		)
	end

	function Config:Disconnect()
		for _, Connection in next, Connections do
			Connection:Disconnect()
		end
	end

	return Config
end

--==============================================================
-- WINDOW SELECT
--==============================================================

function Core:ApplyWindowSelectEffect(
	Window,
	TitleBar
)
	local UIStroke =
		Window:FindFirstChildOfClass(
			"UIStroke"
		)

	if not UIStroke then
		return
	end

	local Colors = {
		Selected = {
			BackgroundColor3 =
				TitleBar.BackgroundColor3,
		},

		Deselected = {
			BackgroundColor3 =
				Color3.fromRGB(0, 0, 0),
		},
	}

	local function SetSelected(Selected)
		local Type =
			Selected
			and "Selected"
			or "Deselected"

		self:Tween(
			TitleBar,
			Colors[Type]
		)

		self:Tween(
			UIStroke,
			self.Animations.WindowBorder[Type]
		)
	end

	self:ConnectHover({
		Parent = Window,

		OnInput = function(
			MouseHovering,
			Input
		)
			if Input.UserInputType.Name:find("Mouse") then
				SetSelected(MouseHovering)
			end
		end,
	})
end

--==============================================================
-- WINDOW PROPERTY MANAGER
--==============================================================

function Core:SetWindowProps(
	Windows,
	Properties,
	IgnoreWindows
)
	local Module = {
		OldProperties = {},
	}

	IgnoreWindows =
		IgnoreWindows or {}

	for Window, Config in next, Windows do
		if table.find(
			IgnoreWindows,
			Window
		) then
			continue
		end

		local OldValues = {}

		Module.OldProperties[Window] =
			OldValues

		for Key, Value in next, Properties do
			OldValues[Key] =
				Window[Key]

			Window[Key] =
				Value
		end
	end

	function Module:Revert()
		for Window, OldValues in next,
			self.OldProperties do

			for Key, Value in next, OldValues do
				Window[Key] =
					Value
			end
		end
	end

	return Module
end

return Core
