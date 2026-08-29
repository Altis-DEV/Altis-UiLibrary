-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/ImGui.lua
--// MIT License
--// Copyright (c) 2024 Depso

local ImGui = {
	Animations = {
		Buttons = {
			MouseEnter = {
				BackgroundTransparency = 0.5,
			},
			MouseLeave = {
				BackgroundTransparency = 0.7,
			} 
		},
		Tabs = {
			MouseEnter = {
				BackgroundTransparency = 0.5,
			},
			MouseLeave = {
				BackgroundTransparency = 1,
			} 
		},
		Inputs = {
			MouseEnter = {
				BackgroundTransparency = 0,
			},
			MouseLeave = {
				BackgroundTransparency = 0.5,
			} 
		},
		WindowBorder = {
			Selected = {
				Transparency = 0,
				Thickness = 1
			},
			Deselected = {
				Transparency = 0.7,
				Thickness = 1
			}
		},
	},

	Windows = {},
	Animation = TweenInfo.new(0.1),
	UIAssetId = "rbxassetid://76246418997296"
}


--// Universal functions
local NullFunction = function() end
local CloneRef = cloneref or function(_)return _ end
local function GetService(...): ServiceProvider
	return CloneRef(game:GetService(...))
end

function ImGui:Warn(...)
	if self.NoWarnings then return end
	return warn("[IMGUI]", ...)
end

--// Services 
local TweenService: TweenService = GetService("TweenService")
local UserInputService: UserInputService = GetService("UserInputService")
local Players: Players = GetService("Players")
local CoreGui = GetService("CoreGui")
local RunService: RunService = GetService("RunService")

--// LocalPlayer
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Mouse = LocalPlayer:GetMouse()

--// ImGui Config

local IsStudio = RunService:IsStudio()
ImGui.NoWarnings = not IsStudio

--// Theme system
--// Theme format:
--// {
--//     Name = "theme-name",
--//     Colors = { ... },
--//     Animations = { ... } -- optional
--// }
local DefaultAnimations = ImGui.Animations
local Themes = {}
ImGui.Themes = Themes
ImGui.CurrentTheme = "default"

local function DeepMerge(Base, Override)
    local Result = {}

    for Key, Value in next, Base or {} do
        if typeof(Value) == "table" then
            Result[Key] = DeepMerge(Value, nil)
        else
            Result[Key] = Value
        end
    end

    for Key, Value in next, Override or {} do
        if typeof(Value) == "table" and typeof(Result[Key]) == "table" then
            Result[Key] = DeepMerge(Result[Key], Value)
        elseif typeof(Value) == "table" then
            Result[Key] = DeepMerge(Value, nil)
        else
            Result[Key] = Value
        end
    end

    return Result
end

local DefaultTheme = {
    Name = "default",
    Colors = {},
    Animations = DefaultAnimations,
}

local LightTheme = {
    Name = "light",
    Colors = {
        Window = {
            Content = {
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
            },
            TitleBar = {
                BackgroundColor3 = Color3.fromRGB(232, 232, 232),
            },
            ToolBar = {
                BackgroundColor3 = Color3.fromRGB(238, 238, 238),
            },
        },
        Button = {
            BackgroundColor3 = Color3.fromRGB(225, 225, 225),
            Label = {
                TextColor3 = Color3.fromRGB(30, 30, 30),
            },
        },
        Image = {
            BackgroundColor3 = Color3.fromRGB(225, 225, 225),
        },
        CheckBox = {
            BackgroundColor3 = Color3.fromRGB(225, 225, 225),
            Label = {
                TextColor3 = Color3.fromRGB(30, 30, 30),
            },
        },
        Label = {
            TextColor3 = Color3.fromRGB(35, 35, 35),
        },
        Slider = {
            BackgroundColor3 = Color3.fromRGB(220, 220, 220),
            ValueText = {
                TextColor3 = Color3.fromRGB(35, 35, 35),
            },
            Label = {
                TextColor3 = Color3.fromRGB(35, 35, 35),
            },
        },
        TextInput = {
            BackgroundColor3 = Color3.fromRGB(235, 235, 235),
            Input = {
                TextColor3 = Color3.fromRGB(30, 30, 30),
            },
        },
        Keybind = {
            BackgroundColor3 = Color3.fromRGB(225, 225, 225),
            ValueText = {
                TextColor3 = Color3.fromRGB(30, 30, 30),
            },
        },
        Combo = {
            BackgroundColor3 = Color3.fromRGB(225, 225, 225),
            ValueText = {
                TextColor3 = Color3.fromRGB(30, 30, 30),
            },
        },
    },
    Animations = DefaultAnimations,
}

Themes.default = DefaultTheme
Themes.light = LightTheme

local function ResolveTheme(Name)
    if typeof(Name) ~= "string" or Name == "" then
        Name = "default"
    end

    local Key = Name:lower()
    return Themes[Key], Key
end

function ImGui:AddTheme(Theme)
    assert(typeof(Theme) == "table", "ImGui:AddTheme expects a table")
    assert(typeof(Theme.Name) == "string" and Theme.Name ~= "", "Theme.Name is required")

    local Name = Theme.Name:lower()
    local Existing = Themes[Name]

    local NewTheme = {
        Name = Name,
        Colors = DeepMerge(Existing and Existing.Colors or {}, Theme.Colors or {}),
        Animations = DeepMerge(DefaultAnimations, Theme.Animations or {}),
    }

    Themes[Name] = NewTheme
    return NewTheme
end

local function GetWindowTheme(WindowConfig)
    local ThemeName = WindowConfig.Theme or "default"
    local Theme, Key = ResolveTheme(ThemeName)

    if not Theme then
        Theme = Themes.default
        Key = "default"
    end

    return Theme, Key
end

function ImGui:SetTheme(Name)
	local Theme, Key = ResolveTheme(Name)

	if not Theme then
		self:Warn("Theme not found:", Name)
		return false
	end

	self.CurrentTheme = Key
	self.Animations = Theme.Animations

	-- Apply the global theme to windows that do not have an explicit theme.
	for Window, Config in next, self.Windows do
		if not Config.__ExplicitTheme then
			Config.Theme = Key
			Config.Colors = DeepMerge(
				Theme.Colors,
				Config.__CustomColors or {}
			)

			self:CheckStyles(
				Window,
				Config,
				Config.Colors
			)

			-- Update already-created elements without renaming them again.
			for _, Descendant in next, Window:GetDescendants() do
				if not Descendant:IsA("GuiObject") then
					continue
				end

				local ElementType = Descendant.Name:gsub("_$", "")
				local Colors = Config.Colors[ElementType]

				if Colors then
					self:ApplyColors(
						Colors,
						Descendant,
						ElementType
					)
				end
			end
		end
	end

	return true
end

--// Prefabs
function ImGui:FetchUI()
	--// Cache check 
	local CacheName = "DepsoImGui"
	if _G[CacheName] then
		self:Warn("Prefabs loaded from Cache")
		return _G[CacheName]
	end

	local UI = nil

	--// Universal
	if not IsStudio then
		local UIAssetId = ImGui.UIAssetId
		UI = game:GetObjects(UIAssetId)[1]
	else --// Studio
		local UIName = "DepsoImGui"
		UI = PlayerGui:FindFirstChild(UIName) or script.DepsoImGui
	end

	_G[CacheName] = UI
	return UI
end

local UI = ImGui:FetchUI()
local Prefabs = UI.Prefabs
ImGui.Prefabs = Prefabs
Prefabs.Visible = false

--// Styles
local AddionalStyles = {
	[{
		Name="Border"
	}] = function(GuiObject: GuiObject, Value, Class)
		local Outline = GuiObject:FindFirstChildOfClass("UIStroke")
		if not Outline then return end

		local BorderThickness = Class.BorderThickness
		if BorderThickness then
			Outline.Thickness = BorderThickness
		end

		Outline.Enabled = Value
	end,

	[{
		Name="Ratio"
	}] = function(GuiObject: GuiObject, Value, Class)
		local RatioAxis = Class.RatioAxis or "Height"
		local AspectRatio = Class.Ratio or 4/3
		local AspectType = Class.AspectType or Enum.AspectType.ScaleWithParentSize

		local Ratio = GuiObject:FindFirstChildOfClass("UIAspectRatioConstraint")
		if not Ratio then
			Ratio = ImGui:CreateInstance("UIAspectRatioConstraint", GuiObject)
		end

		Ratio.DominantAxis = Enum.DominantAxis[RatioAxis]
		Ratio.AspectType = AspectType
		Ratio.AspectRatio = AspectRatio
	end,

	[{
		Name="CornerRadius",
		Recursive=true
	}] = function(GuiObject: GuiObject, Value, Class)
		local UICorner = GuiObject:FindFirstChildOfClass("UICorner")
		if not UICorner then
			UICorner = ImGui:CreateInstance("UICorner", GuiObject)
		end

		UICorner.CornerRadius = Class.CornerRadius
	end,

	[{
		Name="Label"
	}] = function(GuiObject: GuiObject, Value, Class)
		local Label = GuiObject:FindFirstChild("Label")
		if not Label then return end

		Label.Text = Class.Label
		function Class:SetLabel(Text)
			Label.Text = Text
			return Class
		end
	end,

	[{
		Name="NoGradient",
		Aliases = {"NoGradientAll"},
		Recursive=true
	}] = function(GuiObject: GuiObject, Value, Class)
		local UIGradient = GuiObject:FindFirstChildOfClass("UIGradient")
		if not UIGradient then return end
		UIGradient.Enabled = not Value
	end,

	--// Addional functions for classes
	[{
		Name="Callback"
	}] = function(GuiObject: GuiObject, Value, Class)
		function Class:SetCallback(NewCallback)
			Class.Callback = NewCallback
			return Class
		end
		function Class:FireCallback(NewCallback)
			return Class.Callback(GuiObject)
		end
	end,

	[{
		Name="Value"
	}] = function(GuiObject: GuiObject, Value, Class)
		function Class:GetValue()
			return Class.Value
		end
	end,
}

function ImGui:GetName(Name: string)
	local Format = "%s_"
	return Format:format(Name)
end

function ImGui:CreateInstance(Class, Parent, Properties)
	local Instance = Instance.new(Class, Parent)
	for Key, Value in next, Properties or {} do
		Instance[Key] = Value
	end
	return Instance
end

function ImGui:ApplyColors(ColorOverwrites, GuiObject: GuiObject, ElementType: string)
	for Info, Value in next, ColorOverwrites do
		local Key = Info
		local Recursive = false

		if typeof(Info) == "table" then
			Key = Info.Name or ""
			Recursive = Info.Recursive or false
		end

		--// Child object
		if typeof(Value) == "table" then
			local Element = GuiObject:FindFirstChild(Key, Recursive)

			if not Element then 
				if ElementType == "Window" then
					Element = GuiObject.Content:FindFirstChild(Key, Recursive)
					if not Element then continue end
				else 
					warn(Key, "was not found in", GuiObject)
					warn("Table:", Value)

					continue
				end
			end

			ImGui:ApplyColors(Value, Element)
			continue
		end

		--// Set property
		GuiObject[Key] = Value
	end
end

function ImGui:CheckStyles(GuiObject: GuiObject, Class, Colors)
	--// Addional styles
	for Info, Callback in next, AddionalStyles do
		local Value = Class[Info.Name]
		local Aliases = Info.Aliases

		if Aliases and not Value then
			for _, Alias in Info.Aliases do
				Value = Class[Alias]
				if Value then break end
			end
		end
		if Value == nil then continue end

		--// Stylise children
		Callback(GuiObject, Value, Class)
		if Info.Recursive then
			for _, Child in next, GuiObject:GetChildren() do
				Callback(Child, Value, Class)
			end
		end
	end

	--// Label functions/Styliser
	local ElementType = GuiObject.Name
	GuiObject.Name = self:GetName(ElementType)

	--// Apply Colors
	local Colors = Colors or {}
	local ColorOverwrites = Colors[ElementType]

	if ColorOverwrites then
		ImGui:ApplyColors(ColorOverwrites, GuiObject, ElementType)
	end

	--// Set properties
	for Key, Value in next, Class do
		pcall(function() --// If the property does not exist
			GuiObject[Key] = Value
		end)
	end
end

function ImGui:MergeMetatables(Class, Instance: GuiObject)
	local Metadata = {}
	Metadata.__index = function(self, Key)
		local suc, Value = pcall(function()
			local Value = Instance[Key]
			if typeof(Value) == "function" then
				return function(...)
					return Value(Instance, ...)
				end
			end
			return Value
		end)
		return suc and Value or Class[Key]
	end

	Metadata.__newindex = function(self, Key, Value)
		local Key2 = Class[Key]
		if Key2 ~= nil or typeof(Value) == "function" then
			Class[Key] = Value
		else
			Instance[Key] = Value
		end
	end

	return setmetatable({}, Metadata)
end

function ImGui:Concat(Table, Separator: " ") 
	local Concatenated = ""
	for Index, String in next, Table do
		Concatenated ..= tostring(String) .. (Index ~= #Table and Separator or "")
	end
	return Concatenated
end

function ImGui:ContainerClass(Frame: Frame, Class, Window)
	local ContainerClass = Class or {}
	local WindowConfig = ImGui.Windows[Window]

	function ContainerClass:NewInstance(Instance: Frame, Class, Parent)
		--// Config
		Class = Class or {}

		--// Set Parent
		Instance.Parent = Parent or Frame
		Instance.Visible = true

		--// TODO
		if WindowConfig.NoGradientAll then
			Class.NoGradient = true
		end

		local Colors = WindowConfig.Colors
		ImGui:CheckStyles(Instance, Class, Colors)

		--// External callback check
		if Class.NewInstanceCallback then
			Class.NewInstanceCallback(Instance)
		end

		--// Merge the class with the properties of the instance
		return ImGui:MergeMetatables(Class, Instance)
	end

	function ContainerClass:Button(Config)
		Config = Config or {}
		local Button = Prefabs.Button:Clone()
		local ObjectClass = self:NewInstance(Button, Config)

		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end
		Button.Activated:Connect(Callback)

		--// Apply animations
		ImGui:ApplyAnimations(Button, "Buttons")
		return ObjectClass
	end

	function ContainerClass:Image(Config)
		Config = Config or {}
		local Image = Prefabs.Image:Clone()

		--// Check for rbxassetid
		if tonumber(Config.Image) then
			Config.Image = `rbxassetid://{Config.Image}`
		end

		local ObjectClass = self:NewInstance(Image, Config)
		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end
		Image.Activated:Connect(Callback)

		--// Apply animations
		ImGui:ApplyAnimations(Image, "Buttons")
		return ObjectClass
	end

	function ContainerClass:ScrollingBox(Config)
		Config = Config or {}
		local Box = Prefabs.ScrollBox:Clone()
		local ContainClass = ImGui:ContainerClass(Box, Config, Window) 
		return self:NewInstance(Box, ContainClass)
	end

	function ContainerClass:Label(Config)
		Config = Config or {}
		local Label = Prefabs.Label:Clone()
		return self:NewInstance(Label, Config)
	end

	function ContainerClass:Checkbox(Config)
		Config = Config or {}
		local IsRadio = Config.IsRadio

		local CheckBox = Prefabs.CheckBox:Clone()
		local Tickbox: ImageButton = CheckBox.Tickbox
		local Tick: ImageLabel = Tickbox.Tick
		local Label = CheckBox.Label
		local ObjectClass = self:NewInstance(CheckBox, Config)

		--// Stylise to correct type
		if IsRadio then
			Tick.ImageTransparency = 1
			Tick.BackgroundTransparency = 0
		else
			Tickbox:FindFirstChildOfClass("UIPadding"):Remove()
			Tickbox:FindFirstChildOfClass("UICorner"):Remove()
		end

		--// Apply animations
		ImGui:ApplyAnimations(CheckBox, "Buttons", Tickbox)

		local Value = Config.Value or false

		--// Callback
		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end

		function Config:SetTicked(NewValue: boolean, NoAnimation: false)
			Value = NewValue
			Config.Value = Value

			--// Animations
			local Size = Value and UDim2.fromScale(1,1) or UDim2.fromScale(0,0)
			ImGui:Tween(Tick, {
				Size = Size
			}, nil, NoAnimation)
			ImGui:Tween(Label, {
				TextTransparency = Value and 0 or 0.3
			}, nil, NoAnimation)

			--// Fire callback
			Callback(Value)

			return Config
		end
		Config:SetTicked(Value, true)

		function Config:Toggle()
			Config:SetTicked(not Value)
			return Config
		end

		--// Connect functions
		local function Clicked()
			Value = not Value
			Config:SetTicked(Value)
		end
		CheckBox.Activated:Connect(Clicked)
		Tickbox.Activated:Connect(Clicked)

		return ObjectClass
	end

	function ContainerClass:RadioButton(Config)
		Config = Config or {}
		Config.IsRadio = true
		return self:Checkbox(Config)
	end

	function ContainerClass:Viewport(Config)
		Config = Config or {}
		local Model = Config.Model

		local Holder = Prefabs.Viewport:Clone()
		local Viewport: ViewportFrame = Holder.Viewport
		local WorldModel: WorldModel = Viewport.WorldModel
		Config.WorldModel = WorldModel
		Config.Viewport = Viewport

		function Config:SetCamera(Camera)
			Viewport.CurrentCamera = Camera
			Config.Camera = Camera
			Camera.CFrame = CFrame.new(0,0,0)
			return Config
		end

		local Camera = Config.Camera or ImGui:CreateInstance("Camera", Viewport)
		Config:SetCamera(Camera)

		function Config:SetModel(Model: Model, PivotTo: CFrame)
			WorldModel:ClearAllChildren()

			--// Set new model
			if Config.Clone then
				Model = Model:Clone()
			end
			if PivotTo then
				Model:PivotTo(PivotTo)
			end

			Model.Parent = WorldModel
			Config.Model = Model
			return Model
		end

		--// Set model
		if Model then
			Config:SetModel(Model)
		end

		local ContainClass = ImGui:ContainerClass(Holder, Config, Window) 
		return self:NewInstance(Holder, ContainClass)
	end

	function ContainerClass:InputText(Config)
		Config = Config or {}
		local TextInput = Prefabs.TextInput:Clone()
		local TextBox: TextBox = TextInput.Input
		local ObjectClass = self:NewInstance(TextInput, Config)

		TextBox.Text = Config.Value or ""
		TextBox.PlaceholderText = Config.PlaceHolder
		TextBox.MultiLine = Config.MultiLine == true

		--// Apply animations
		ImGui:ApplyAnimations(TextInput, "Inputs")

		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end
		TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local Value = TextBox.Text
			Config.Value = Value
			return Callback(Value)
		end)

		function Config:SetValue(Text)
			TextBox.Text = tostring(Text)
			Config.Value = Text
			return Config
		end

		function Config:Clear()
			TextBox.Text = ""
			return Config
		end

		return ObjectClass
	end

	function ContainerClass:InputTextMultiline(Config)
		Config = Config or {}
		Config.Label = ""
		Config.Size = UDim2.new(1, 0, 0, 38)
		Config.MultiLine = true
		return ContainerClass:InputText(Config)
	end

	function ContainerClass:GetRemainingHeight()
		local Padding = Frame:FindFirstChildOfClass("UIPadding")
		local UIListLayout = Frame:FindFirstChildOfClass("UIListLayout")

		local LayoutPaddding = UIListLayout.Padding
		local PaddingTop = Padding.PaddingTop
		local PaddingBottom = Padding.PaddingBottom

		local PaddingSizeY = PaddingTop+PaddingBottom+LayoutPaddding
		local OccupiedY = Frame.AbsoluteSize.Y+PaddingSizeY.Offset+3

		return UDim2.new(1, 0, 1, -OccupiedY) 
	end

	function ContainerClass:Console(Config)
		Config = Config or {}
		local Console: ScrollingFrame = Prefabs.Console:Clone()
		local Source: TextBox = Console.Source
		local Lines = Console.Lines

		if Config.Fill then
			Console.Size = ContainerClass:GetRemainingHeight()
		end

		--// Set values from config
		Source.TextEditable = Config.ReadOnly ~= true
		Source.Text = Config.Text or ""
		Source.TextWrapped = Config.TextWrapped == true
		Source.RichText = Config.RichText == true
		Lines.Visible = Config.LineNumbers == true

		function Config:UpdateLineNumbers()
			if not Config.LineNumbers then return end

			local LinesCount = #Source.Text:split("\n")
			local Format = Config.LinesFormat or "%s"

			--// Update lines text
			Lines.Text = ""
			for i = 1, LinesCount do
				Lines.Text ..= `{Format:format(i)}{i ~= LinesCount and '\n' or ''}`
			end

			Source.Size = UDim2.new(1, -Lines.AbsoluteSize.X, 0, 0)
			return Config
		end

		function Config:UpdateScroll()
			local CanvasSizeY = Console.AbsoluteCanvasSize.Y
			Console.CanvasPosition = Vector2.new(0, CanvasSizeY)
			return Config
		end

		function Config:SetText(Text)
			if not Config.Enabled then return end
			Source.Text = Text
			Config:UpdateLineNumbers()
			return Config
		end

		function Config:GetValue()
			return Source.Text
		end

		function Config:Clear(Text)
			Source.Text = ""
			Config:UpdateLineNumbers()
			return Config
		end

		function Config:AppendText(...)
			if not Config.Enabled then return end

			local MaxLines = Config.MaxLines or 100
			local NewString = "\n" .. ImGui:Concat({...}, " ") 

			Source.Text ..= NewString
			Config:UpdateLineNumbers()

			if Config.AutoScroll then
				Config:UpdateScroll()
			end

			local Lines = Source.Text:split("\n")
			if #Lines > MaxLines then
				Source.Text = Source.Text:sub(#Lines[1]+2)
			end
			return Config
		end

		--// Connect events
		Source.Changed:Connect(Config.UpdateLineNumbers)

		return self:NewInstance(Console, Config)
	end

	function ContainerClass:Table(Config)
		Config = Config or {}
		local Table: Frame = Prefabs.Table:Clone()
		local TableChildCount = #Table:GetChildren() --// Performance

		--// Configure Table style
		if Config.Fill then
			Table.Size = ContainerClass:GetRemainingHeight()
		end
		local RowName = "Row"

		local RowsCount = 0
		function Config:CreateRow()
			local RowClass = {}

			local Row: Frame = Table.RowTemp:Clone()
			local UIListLayout = Row:FindFirstChildOfClass("UIListLayout")
			UIListLayout.VerticalAlignment = Enum.VerticalAlignment[Config.Align or "Center"]

			local RowChildCount = #Row:GetChildren() --// Performance
			Row.Name = RowName
			Row.Visible = true

			--// Background colors
			if Config.RowBackground then
				Row.BackgroundTransparency = RowsCount % 2 == 1 and 0.92 or 1
			end

			function RowClass:CreateColumn(CConfig)
				CConfig = CConfig or {}
				local Column: Frame = Row.ColumnTemp:Clone()
				Column.Visible = true
				Column.Name = "Column"

				local Stroke = Column:FindFirstChildOfClass("UIStroke")
				Stroke.Enabled = Config.Border ~= false

				local ContainClass = ImGui:ContainerClass(Column, CConfig, Window) 
				return ContainerClass:NewInstance(Column, ContainClass, Row)
			end

			function RowClass:UpdateColumns()
				if not Row or not Table then return end
				local Columns = Row:GetChildren()
				local RowsCount = #Columns - RowChildCount

				for _, Column: Frame in next, Columns do
					if not Column:IsA("Frame") then continue end
					Column.Size = UDim2.new(1/RowsCount, 0, 0, 0)
				end
				return RowClass
			end
			Row.ChildAdded:Connect(RowClass.UpdateColumns)
			Row.ChildRemoved:Connect(RowClass.UpdateColumns)

			RowsCount += 1
			return ContainerClass:NewInstance(Row, RowClass, Table)
		end

		function Config:UpdateRows()
			local Rows = Table:GetChildren()
			local PaddingY = Table.UIListLayout.Padding.Offset + 2
			local RowsCount = #Rows - TableChildCount

			for _, Row: Frame in next, Rows do
				if not Row:IsA("Frame") then continue end
				Row.Size = UDim2.new(1, 0, 1/RowsCount, -PaddingY)
			end
			return Config
		end

		if Config.RowsFill then
			Table.AutomaticSize = Enum.AutomaticSize.None
			Table.ChildAdded:Connect(Config.UpdateRows)
			Table.ChildRemoved:Connect(Config.UpdateRows)
		end

		function Config:ClearRows()
			RowsCount = 0
			local PostRowName = ImGui:GetName(RowName)
			for _, Row: Frame in next, Table:GetChildren() do
				if not Row:IsA("Frame") then continue end

				if Row.Name == PostRowName then
					Row:Remove()
				end
			end
			return Config
		end

		return self:NewInstance(Table, Config) 
	end

	function ContainerClass:Grid(Config)
		Config = Config or {}
		Config.Grid = true

		return self:Table(Config)
	end

	function ContainerClass:CollapsingHeader(Config)
		Config = Config or {}
		local Title = Config.Title or ""
		Config.Name = Title

		local Header = Prefabs.CollapsingHeader:Clone()
		local Titlebar: TextButton = Header.TitleBar
		local Container: Frame = Header.ChildContainer
		Titlebar.Title.Text = Title

		--// Apply animations
		if Config.IsTree then
			ImGui:ApplyAnimations(Titlebar, "Tabs")
		else
			ImGui:ApplyAnimations(Titlebar, "Buttons")
		end

		--// Open Animations
		function Config:SetOpen(Open)
			local Animate = Config.NoAnimation ~= true
			Config.Open = Open
			ImGui:HeaderAnimate(Header, Animate, Open, Titlebar)
			return self
		end

		--// Toggle
		local ToggleButton = Titlebar.Toggle.ToggleButton
		local function Toggle()
			Config:SetOpen(not Config.Open)
		end
		Titlebar.Activated:Connect(Toggle)
		ToggleButton.Activated:Connect(Toggle)

		--// Custom toggle image
		if Config.Image then
			ToggleButton.Image = Config.Image 
		end

		--// Open
		Config:SetOpen(Config.Open or false)

		local ContainClass = ImGui:ContainerClass(Container, Config, Window) 
		return self:NewInstance(Header, ContainClass)
	end

	function ContainerClass:TreeNode(Config)
		Config = Config or {}
		Config.IsTree = true
		return self:CollapsingHeader(Config)
	end

	function ContainerClass:Separator(Config)
		Config = Config or {}
		local Separator = Prefabs.SeparatorText:Clone()
		local HeaderLabel = Separator.TextLabel
		HeaderLabel.Text = Config.Text or ""

		if not Config.Text then
			HeaderLabel.Visible = false
		end

		return self:NewInstance(Separator, Config)
	end

	function ContainerClass:Row(Config)
		Config = Config or {}
		local Row: Frame = Prefabs.Row:Clone()
		local UIListLayout = Row:FindFirstChildOfClass("UIListLayout")
		local UIPadding = Row:FindFirstChildOfClass("UIPadding")

		if Config.Spacing then
			UIListLayout.Padding = UDim.new(0, Config.Spacing)
		end

		function Config:Fill()
			local Children = Row:GetChildren()
			local Rows = #Children - 2 --// -UIListLayout + UIPadding

			--// Change layout
			local Padding = UIListLayout.Padding.Offset * 2
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

			--// Apply correct margins
			UIPadding.PaddingLeft = UIListLayout.Padding
			UIPadding.PaddingRight = UIListLayout.Padding

			for _, Child: Instance in next, Children do
				local YScale = 0
				if Child:IsA("ImageButton") then
					YScale = 1
				end
				pcall(function()
					Child.Size = UDim2.new(1/Rows, -Padding, YScale, 0)
				end)
			end
			return Config
		end

		local ContainClass = ImGui:ContainerClass(Row, Config, Window) 
		return self:NewInstance(Row, ContainClass)
	end

	--TODO
	-- Vertical 
	-- :SetPercentage
	-- This will use UIDragdetectors in the upcoming release, please do not report this!
	function ContainerClass:Slider(Config)
		Config = Config or {}

		local Value = Config.Value or 0
		local ValueFormat = Config.Format or "%.d"
		local IsProgress = Config.Progress
		Config.Name = Config.Label or ""

		local Slider: TextButton = Prefabs.Slider:Clone()
		local UIPadding = Slider:FindFirstChildOfClass("UIPadding")
		local Grab: Frame = Slider.Grab
		local ValueText = Slider.ValueText
		local Label = Slider.Label

		local ObjectClass = self:NewInstance(Slider, Config)

		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end

		if IsProgress then
			local UIGradient = Grab:FindFirstChildOfClass("UIGradient")
			local PaddingSides = UDim.new(0, 2)
			local Diff = UIPadding.PaddingLeft - PaddingSides

			Grab.AnchorPoint = Vector2.new(0, 0.5)
			if UIGradient then
				UIGradient.Enabled = true
			end

			UIPadding.PaddingLeft = PaddingSides
			UIPadding.PaddingRight = PaddingSides
			Label.Position = UDim2.new(1, 15 - Diff.Offset, 0, 0)
		end

		function Config:SetValue(NewValue: number, FromSlider: boolean)
			local MinValue = Config.MinValue
			local MaxValue = Config.MaxValue

			assert(MinValue ~= nil, "Slider: MinValue is required")
			assert(MaxValue ~= nil, "Slider: MaxValue is required")

			local Difference = MaxValue - MinValue
			if Difference == 0 then
				Difference = 1
			end

			local Percentage
			local ResultValue

			if FromSlider then
				Percentage = math.clamp(
					type(NewValue) == "number"
						and NewValue
						or tonumber(NewValue)
						or 0,
					0,
					1
				)
				ResultValue = MinValue + Difference * Percentage
			else
				ResultValue = tonumber(NewValue) or MinValue
				Percentage = (ResultValue - MinValue) / Difference
			end

			Percentage = math.clamp(Percentage, 0, 1)
			ResultValue = math.clamp(ResultValue, MinValue, MaxValue)

			local Props = IsProgress
				and {Size = UDim2.fromScale(Percentage, 1)}
				or {Position = UDim2.fromScale(Percentage, 0.5)}

			ImGui:Tween(Grab, Props)

			Config.Value = ResultValue
			ValueText.Text = ValueFormat:format(ResultValue, MaxValue)

			Callback(ResultValue)
			return Config
		end

		local function ApplyPointerPosition(PositionX)
			if Config.ReadOnly then
				return
			end

			local Left = Slider.AbsolutePosition.X
			local Width = Slider.AbsoluteSize.X

			if Width <= 0 then
				return
			end

			local Percentage = math.clamp(
				(PositionX - Left) / Width,
				0,
				1
			)

			Config:SetValue(Percentage, true)
		end

		local function IsInside(Position)
			local AbsolutePosition = Slider.AbsolutePosition
			local AbsoluteSize = Slider.AbsoluteSize

			return Position.X >= AbsolutePosition.X
				and Position.X <= AbsolutePosition.X + AbsoluteSize.X
				and Position.Y >= AbsolutePosition.Y
				and Position.Y <= AbsolutePosition.Y + AbsoluteSize.Y
		end

		local Dragging = false
		local ActiveInput = nil
		local MouseDragging = false

		local function Begin(Input)
			if Config.ReadOnly then
				return
			end

			Dragging = true
			ActiveInput = Input
			MouseDragging =
				Input.UserInputType
				== Enum.UserInputType.MouseButton1

			ApplyPointerPosition(
				Input.Position.X
			)
		end

		UserInputService.InputBegan:Connect(function(Input)
			local InputType = Input.UserInputType

			if InputType ~= Enum.UserInputType.MouseButton1
				and InputType ~= Enum.UserInputType.Touch then
				return
			end

			local Position = Vector2.new(
				Input.Position.X,
				Input.Position.Y
			)

			if IsInside(Position) then
				Begin(Input)
			end
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if not Dragging then
				return
			end

			if MouseDragging
				and Input.UserInputType == Enum.UserInputType.MouseMovement then
				ApplyPointerPosition(Input.Position.X)
				return
			end

			if ActiveInput
				and Input.UserInputType == Enum.UserInputType.Touch
				and Input == ActiveInput then
				ApplyPointerPosition(Input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(Input)
			if MouseDragging
				and Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = false
				MouseDragging = false
				ActiveInput = nil
				return
			end

			if ActiveInput
				and Input == ActiveInput then
				Dragging = false
				ActiveInput = nil
			end
		end)

		Config:SetValue(Value)
		return ObjectClass
	end

	function ContainerClass:ProgressSlider(Config)
		Config = Config or {}
		Config.Progress = true
		return self:Slider(Config)
	end

	function ContainerClass:ProgressBar(Config)
		Config = Config or {}
		Config.Progress = true
		Config.ReadOnly = true
		Config.MinValue = 0
		Config.MaxValue = 100
		Config.Format = "% i%%"
		Config = self:Slider(Config)

		function Config:SetPercentage(Value: number)
			Config:SetValue(Value)
		end

		return Config
	end

	function ContainerClass:Keybind(Config)
		Config = Config or {}

		local Key = Config.Value
		local TobeNullKey = Config.NullKey or Enum.KeyCode.Backspace

		local Keybind: TextButton = Prefabs.Keybind:Clone()
		local ValueText: TextButton = Keybind.ValueText

		local ObjectClass = nil
		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end

		function Config:SetValue(NewKey: Enum.KeyCode)
			if not NewKey then return end

			if NewKey == TobeNullKey then
				ValueText.Text = "Not set"
				Config.Value = nil
			else
				ValueText.Text = NewKey.Name
				Config.Value = NewKey
			end
		end

		Keybind.Activated:Connect(function()
			ValueText.Text = "..."

			local NewKey = UserInputService.InputBegan:Wait()
			if not UserInputService.WindowFocused then return end 

			--// Reset back to previous if unknown
			local Previous = Config.Value
			if NewKey.KeyCode.Name == "Unknown" then
				return Config:SetValue(Previous)
			end

			wait(.1) --// 👍
			Config:SetValue(NewKey.KeyCode)
		end)

		Config.Connection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
			if not Config.IgnoreGameProcessed and GameProcessed then return end
			local KeyCode = Input.KeyCode
			local Match = Config.Value

			if KeyCode == TobeNullKey then return end
			if KeyCode ~= Match then return end 

			return Callback(Input.KeyCode)
		end)

		--// Update UI
		Config:SetValue(Key)

		ObjectClass = self:NewInstance(Keybind, Config)
		return ObjectClass
	end

	function ContainerClass:Combo(Config)
		Config = Config or {}
		Config.Open = false
		Config.Value = ""

		local Combo: TextButton = Prefabs.Combo:Clone()
		local Toggle: ImageButton = Combo.Toggle.ToggleButton
		local ValueText = Combo.ValueText
		ValueText.Text = Config.Placeholder or ""

		local Dropdown = nil
		local ObjectClass = self:NewInstance(Combo, Config)

		local ComboHovering = ImGui:ConnectHover({
			Parent = Combo
		})

		local function Callback(Value, ...)
			local func = Config.Callback or NullFunction
			Config:SetOpen(false)
			return func(ObjectClass, Value, ...)
		end

		function Config:SetValue(Value, ...)
			local Items = Config.Items or {}
			local DictValue = Items[Value]
			ValueText.Text = tostring(Value)
			Config.Value = Value

			return Callback(DictValue or Value) 
		end

		function Config:SetOpen(Open: true)
			local Animate = Config.NoAnimation ~= true
			ImGui:HeaderAnimate(Combo, Animate, Open, Combo, Toggle)
			Config.Open = Open

			if Open then
				Dropdown = ImGui:Dropdown({
					Parent = Combo,
					Items = Config.Items or {},
					SetValue = Config.SetValue,
					Closed = function()
						if not ComboHovering.Hovering then 
							Config:SetOpen(false)
						end
					end,
				})
			end

			return self
		end

		local function ToggleOpen()
			if Dropdown then
				Dropdown:Close()
			end
			Config:SetOpen(not Config.Open)
		end

		--// Connect events
		Combo.Activated:Connect(ToggleOpen)
		Toggle.Activated:Connect(ToggleOpen)
		ImGui:ApplyAnimations(Combo, "Buttons")

		if Config.Selected then
			Config:SetValue(Config.Selected)
		end

		return ObjectClass 
	end

	return ContainerClass
end

function ImGui:Dropdown(Config)
	local Parent: GuiObject = Config.Parent
	if not Parent then return end

	local Selection: ScrollingFrame = Prefabs.Selection:Clone()
	local UIStroke = Selection:FindFirstChildOfClass("UIStroke")

	local Padding = UIStroke.Thickness*2
	local Position = Parent.AbsolutePosition
	local Size = Parent.AbsoluteSize

	Selection.Parent = self.ScreenGui
	Selection.Position = UDim2.fromOffset(Position.X+Padding, Position.Y+Size.Y)

	local Hover = self:ConnectHover({
		Parent = Selection,
		OnInput = function(MouseHovering, Input)
			if not Input.UserInputType.Name:find("Mouse") then return end

			if not MouseHovering then
				Config:Close()
			end
		end,
	})

	function Config:Close()
		local CloseCallback = Config.Closed
		if CloseCallback then
			CloseCallback()
		end

		Hover:Disconnect()
		Selection:Remove()
	end

	local function SetValue(Value)
		Config:Close()
		Config:SetValue(Value)
	end

	--// Append items
	local ItemTemplate: TextButton = Selection.Template
	ItemTemplate.Visible = false

	for Index, Index2 in next, Config.Items do
		local Value = typeof(Index) ~= "number" and Index or Index2

		local NewItem: TextButton = ItemTemplate:Clone()
		NewItem.Text = tostring(Value)
		NewItem.Parent = Selection
		NewItem.Visible = true
		NewItem.Activated:Connect(function()
			return SetValue(Value)
		end)

		self:ApplyAnimations(NewItem, "Tabs")
	end

	--// Configure size of the frame
	-- Roblox does not support UISizeConstraint on a scrolling frame grr

	local MaxSizeY = Config.MaxSizeY or 200
	local YSize = math.clamp(Selection.AbsoluteCanvasSize.Y, Size.Y, MaxSizeY)
	Selection.Size = UDim2.fromOffset(Size.X-Padding, YSize)

	return Config
end

function ImGui:GetAnimation(Animation: boolean?)
	return Animation and self.Animation or TweenInfo.new(0)
end

function ImGui:Tween(Instance: GuiObject, Props: SharedTable, tweenInfo, NoAnimation: false)
	local tweenInfo = tweenInfo or ImGui:GetAnimation(not NoAnimation)
	local Tween = TweenService:Create(Instance, 
		tweenInfo,
		Props
	)
	Tween:Play()
	return Tween
end

function ImGui:ApplyAnimations(Instance: GuiObject, Class: string, Target: GuiObject?)
    local Connections = {}
    Target = Target or Instance

    local AnimationClass = self.Animations[Class]
    if not AnimationClass then
        return warn("No animations for", Class)
    end

    for Connection in next, AnimationClass do
        Connections[Connection] = function()
            local Props = self.Animations[Class]
                and self.Animations[Class][Connection]

            if typeof(Props) ~= "table" then
                return
            end

            self:Tween(Target, Props)
        end

        Instance[Connection]:Connect(Connections[Connection])
    end

    if Connections.MouseLeave then
        Connections.MouseLeave()
    end

    return Connections
end

function ImGui:HeaderAnimate(Header: Instance, Animation, Open, TitleBar: Instance, Toggle)
	local ToggleButtion = Toggle or TitleBar.Toggle.ToggleButton

	--// Togle animation
	ImGui:Tween(ToggleButtion, {
		Rotation = Open and 90 or 0,
	}):Play()

	--// Container animation
	local Container: Frame = Header:FindFirstChild("ChildContainer")
	if not Container then return end

	local UIListLayout: UIListLayout = Container.UIListLayout
	local UIPadding: UIPadding = Container:FindFirstChildOfClass("UIPadding")
	local ContentSize = UIListLayout.AbsoluteContentSize

	if UIPadding then
		local Top = UIPadding.PaddingTop.Offset
		local Bottom = UIPadding.PaddingBottom.Offset
		ContentSize = Vector2.new(ContentSize.X, ContentSize.Y+Top+Bottom)
	end

	Container.AutomaticSize = Enum.AutomaticSize.None
	if not Open then
		Container.Size = UDim2.new(1, -10, 0, ContentSize.Y)
	end

	--// Animate
	local Tween = ImGui:Tween(Container, {
		Size = UDim2.new(1, -10, 0, Open and ContentSize.Y or 0),
		Visible = Open
	})
	Tween.Completed:Connect(function()
		if not Open then return end
		Container.AutomaticSize = Enum.AutomaticSize.Y
		Container.Size = UDim2.new(1, -10, 0, 0)
	end)
end

function ImGui:ApplyDraggable(Frame: Frame, Header: Frame)
	local HeaderObject = Header or Frame
	local Body = Frame:FindFirstChild("Content")
		and Frame.Content:FindFirstChild("Body")

	local Dragging = false
	local ActiveInput = nil
	local StartInputPosition = nil
	local StartFramePosition = nil

	local function GetPosition(Input)
		return Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)
	end

	local function IsInside(Object, Position)
		if not Object or not Object.Visible then
			return false
		end

		local AbsolutePosition = Object.AbsolutePosition
		local AbsoluteSize = Object.AbsoluteSize

		return Position.X >= AbsolutePosition.X
			and Position.X <= AbsolutePosition.X + AbsoluteSize.X
			and Position.Y >= AbsolutePosition.Y
			and Position.Y <= AbsolutePosition.Y + AbsoluteSize.Y
	end

	local function IsScrollable(ScrollingFrame)
		return ScrollingFrame.AbsoluteCanvasSize.X
			> ScrollingFrame.AbsoluteWindowSize.X + 1
			or ScrollingFrame.AbsoluteCanvasSize.Y
			> ScrollingFrame.AbsoluteWindowSize.Y + 1
	end

	local function TouchBelongsToControl(Position)
		local Objects = GuiService:GetGuiObjectsAtPosition(
			Position.X,
			Position.Y
		)

		for _, Object in ipairs(Objects) do
			if Object == Frame then
				continue
			end

			if not Object:IsDescendantOf(Frame) then
				continue
			end

			local Current = Object

			while Current and Current ~= Frame do
				if Current:IsA("GuiButton")
					or Current:IsA("TextBox") then
					return true
				end

				if Body and Current == Body then
					return IsScrollable(Body)
				end

				-- The tab Content itself is a valid background drag area.
				if Frame.Content and Current == Frame.Content then
					return false
				end

				if Current:IsDescendantOf(Body or Current) then
					-- Any actual element inside Body should own the touch.
					if Current ~= Body then
						return true
					end
				end

				if Current:IsA("ScrollingFrame") then
					return IsScrollable(Current)
				end

				Current = Current.Parent
			end
		end

		return false
	end

	local function Begin(Input)
		if Dragging then
			return
		end

		Dragging = true
		ActiveInput = Input
		StartInputPosition = GetPosition(Input)
		StartFramePosition = Frame.Position
	end

	local function Finish(Input)
		if not Dragging then
			return
		end

		if Input and Input ~= ActiveInput then
			return
		end

		Dragging = false
		ActiveInput = nil
		StartInputPosition = nil
		StartFramePosition = nil
	end

	UserInputService.InputBegan:Connect(function(Input)
		local InputType = Input.UserInputType

		if InputType ~= Enum.UserInputType.MouseButton1
			and InputType ~= Enum.UserInputType.Touch then
			return
		end

		local Position = GetPosition(Input)

		-- PC: TitleBar only.
		-- Mobile: anywhere in Window, except active controls.
		local Allowed =
			(InputType == Enum.UserInputType.Touch
				and IsInside(Frame, Position))
			or IsInside(HeaderObject, Position)

		if not Allowed then
			return
		end

		if TouchBelongsToControl(Position) then
			return
		end

		Begin(Input)
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end

		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			if not ActiveInput
				or ActiveInput.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
		elseif Input.UserInputType == Enum.UserInputType.Touch then
			if Input ~= ActiveInput then
				return
			end
		else
			return
		end

		local Delta =
			GetPosition(Input)
			- StartInputPosition

		Frame.Position = UDim2.new(
			StartFramePosition.X.Scale,
			StartFramePosition.X.Offset + Delta.X,
			StartFramePosition.Y.Scale,
			StartFramePosition.Y.Offset + Delta.Y
		)
	end)

	UserInputService.InputEnded:Connect(Finish)
end


function ImGui:ApplyResizable(MinSize, Frame: Frame, Dragger: TextButton, Config)
	local DragStart = nil
	local OriginalSize = nil
	local ActiveInput = nil
	local Resizing = false
	local MouseResizing = false

	MinSize = MinSize or Vector2.new(160, 90)

	local function IsInside(Position)
		local AbsolutePosition = Dragger.AbsolutePosition
		local AbsoluteSize = Dragger.AbsoluteSize

		return Position.X >= AbsolutePosition.X
			and Position.X <= AbsolutePosition.X + AbsoluteSize.X
			and Position.Y >= AbsolutePosition.Y
			and Position.Y <= AbsolutePosition.Y + AbsoluteSize.Y
	end

	local function Begin(Input)
		if Resizing then
			return
		end

		Resizing = true
		ActiveInput = Input
		MouseResizing =
			Input.UserInputType
			== Enum.UserInputType.MouseButton1

		DragStart = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		OriginalSize = Frame.AbsoluteSize
	end

	local function Update(Input)
		if not Resizing or not DragStart or not OriginalSize then
			return
		end

		local Position = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		local Delta = Position - DragStart

		local NewSize = UDim2.fromOffset(
			math.max(
				MinSize.X,
				OriginalSize.X + Delta.X
			),
			math.max(
				MinSize.Y,
				OriginalSize.Y + Delta.Y
			)
		)

		Frame.Size = NewSize

		if Config then
			Config.Size = NewSize
		end
	end

	local function Finish(Input)
		if not Resizing then
			return
		end

		if Input and Input ~= ActiveInput then
			return
		end

		Resizing = false
		MouseResizing = false
		ActiveInput = nil
		DragStart = nil
		OriginalSize = nil
	end

	-- Use UIS rather than only Dragger.InputBegan so a touch that
	-- starts on a child of the resize handle still begins resizing.
	UserInputService.InputBegan:Connect(function(Input)
		local InputType = Input.UserInputType

		if InputType ~= Enum.UserInputType.MouseButton1
			and InputType ~= Enum.UserInputType.Touch then
			return
		end

		local Position = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		if IsInside(Position) then
			Begin(Input)
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Resizing then
			return
		end

		if MouseResizing
			and Input.UserInputType == Enum.UserInputType.MouseMovement then
			Update(Input)
			return
		end

		if ActiveInput
			and Input.UserInputType == Enum.UserInputType.Touch
			and Input == ActiveInput then
			Update(Input)
		end
	end)

	UserInputService.InputEnded:Connect(Finish)
end

function ImGui:ConnectHover(Config)
	local Parent = Config.Parent
	local Connections = {}
	Config.Hovering = false

	--// Connect Events
	table.insert(Connections, Parent.MouseEnter:Connect(function()
		Config.Hovering = true
	end))
	table.insert(Connections, Parent.MouseLeave:Connect(function()
		Config.Hovering = false
	end))

	if Config.OnInput then
		table.insert(Connections, UserInputService.InputBegan:Connect(function(Input)
			return Config.OnInput(Config.Hovering, Input)
		end))
	end

	function Config:Disconnect()
		for _, Connection in next, Connections do
			Connection:Disconnect()
		end
	end

	return Config
end

function ImGui:ApplyWindowSelectEffect(Window: GuiObject, TitleBar)
	local UIStroke = Window:FindFirstChildOfClass("UIStroke")

	local Colors = {
		Selected = {
			BackgroundColor3 = TitleBar.BackgroundColor3
		},
		Deselected = {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		}
	}

	local function SetSelected(Selected)
		local Animations = ImGui.Animations
		local Type = Selected and "Selected" or "Deselected"
		local TweenInfo = ImGui:GetAnimation(true) 

		ImGui:Tween(TitleBar, Colors[Type])
		ImGui:Tween(UIStroke, Animations.WindowBorder[Type])
	end

	self:ConnectHover({
		Parent = Window,
		OnInput = function(MouseHovering, Input)
			if Input.UserInputType.Name:find("Mouse") then
				SetSelected(MouseHovering)
			end
		end,
	})
end

function ImGui:SetWindowProps(Properties, IgnoreWindows)
	local Module = {
		OldProperties = {}
	}

	--// Collect windows & set properties
	for Window in next, ImGui.Windows do
		if table.find(IgnoreWindows, Window) then continue end

		local OldValues = {}
		Module.OldProperties[Window] = OldValues

		for Key, Value in next, Properties do
			OldValues[Key] = Window[Key]
			Window[Key] = Value
		end
	end

	--// Revert to previous values
	function Module:Revert()
		for Window in next, ImGui.Windows do
			local OldValues = Module.OldProperties[Window]
			if not OldValues then continue end

			for Key, Value in next, OldValues do
				Window[Key] = Value
			end
		end
	end

	return Module
end

function ImGui:CreateWindow(WindowConfig)
	WindowConfig = WindowConfig or {}

	--==============================================================
	-- THEME
	--==============================================================

	local RequestedTheme = WindowConfig.Theme
	local Theme, ThemeName = ResolveTheme(RequestedTheme)
	local ExplicitTheme = RequestedTheme ~= nil

	WindowConfig.Theme = ThemeName
	WindowConfig.__ExplicitTheme = ExplicitTheme
	WindowConfig.__CustomColors = WindowConfig.Colors or {}
	WindowConfig.Colors = DeepMerge(
		Theme.Colors,
		WindowConfig.__CustomColors
	)

	--==============================================================
	-- SIZE
	--==============================================================

	if typeof(WindowConfig.Size) == "Vector2" then
		WindowConfig.Size = UDim2.fromOffset(
			WindowConfig.Size.X,
			WindowConfig.Size.Y
		)
	end

	--==============================================================
	-- CREATE
	--==============================================================

	local Window: Frame = Prefabs.Window:Clone()
	Window.Parent = ImGui.ScreenGui
	Window.Visible = true
	WindowConfig.Window = Window

	if typeof(WindowConfig.Size) == "UDim2" then
		Window.Size = WindowConfig.Size
	else
		WindowConfig.Size = Window.Size
	end

	local Content = Window.Content
	local Body = Content.Body

	-- Body is the original vertical scrolling container.
	Body.ScrollingDirection = Enum.ScrollingDirection.Y
	Body.HorizontalScrollBarInset = Enum.ScrollBarInset.None

	--==============================================================
	-- RESIZE
	--==============================================================

	local Resize: TextButton = Window.ResizeGrab
	Resize.Visible = WindowConfig.NoResize ~= true
	Resize.Size = UDim2.fromOffset(25, 25)
	pcall(function()
		Resize.TextSize = 24
	end)

	local MinSize = WindowConfig.MinSize or Vector2.new(160, 90)

	ImGui:ApplyResizable(
		MinSize,
		Window,
		Resize,
		WindowConfig
	)

	--==============================================================
	-- TITLE BAR
	--==============================================================

	local TitleBar: Frame = Content.TitleBar
	TitleBar.Visible = WindowConfig.NoTitleBar ~= true

	local Toggle = TitleBar.Left.Toggle
	Toggle.Visible = WindowConfig.NoCollapse ~= true
	ImGui:ApplyAnimations(Toggle.ToggleButton, "Tabs")

	--==============================================================
	-- CLOSE BUTTON
	--==============================================================

	local CloseButton = TitleBar.Close
	CloseButton.Visible = WindowConfig.NoClose ~= true

	pcall(function()
		CloseButton.Image = "rbxassetid://127173792845658"
	end)

	local CloseImage = CloseButton:FindFirstChildWhichIsA("ImageLabel", true)
		or CloseButton:FindFirstChildWhichIsA("ImageButton", true)

	if CloseImage then
		pcall(function()
			CloseImage.Image = "rbxassetid://127173792845658"
		end)
	end

	--==============================================================
	-- TOOLBAR
	--==============================================================

	local ToolBar = Content.ToolBar
	ToolBar.Visible = WindowConfig.TabsBar ~= false

	-- Preserve a real pixel height from the prefab before moving its layout.
	local TemplateTabButton = ToolBar.TabButton
	local ToolBarHeight = math.max(
		ToolBar.AbsoluteSize.Y,
		TemplateTabButton.AbsoluteSize.Y,
		ToolBar.Size.Y.Offset,
		TitleBar.AbsoluteSize.Y
	)

	if ToolBarHeight <= 0 then
		ToolBarHeight = 32
	end
	ToolBarHeight = math.max(ToolBarHeight, 25)

	ToolBar.Size = UDim2.new(
		ToolBar.Size.X.Scale,
		ToolBar.Size.X.Offset,
		0,
		ToolBarHeight
	)

	--==============================================================
	-- HORIZONTAL TOOLBAR SCROLLER
	--==============================================================

	local TabBar = Instance.new("ScrollingFrame")
	TabBar.Name = "TabBar"
	TabBar.BackgroundTransparency = 1
	TabBar.BorderSizePixel = 0
	TabBar.Position = UDim2.fromScale(0, 0)
	TabBar.Size = UDim2.fromScale(1, 1)

	-- The toolbar canvas grows automatically from the tab buttons.
	TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	TabBar.CanvasSize = UDim2.new(0, 0, 1, 0)
	TabBar.CanvasPosition = Vector2.zero

	TabBar.ScrollingDirection = Enum.ScrollingDirection.X
	TabBar.ScrollingEnabled = true
	TabBar.ScrollBarThickness =
		WindowConfig.TabBarScrollBarThickness or 4

	-- Overlay the scrollbar so it never changes the toolbar height.
	TabBar.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	TabBar.VerticalScrollBarInset = Enum.ScrollBarInset.None

	TabBar.ElasticBehavior =
		Enum.ElasticBehavior.WhenScrollable

	TabBar.ClipsDescendants = true
	TabBar.Parent = ToolBar

	-- Use the prefab layout when available.
	local TabLayout =
		ToolBar:FindFirstChildOfClass("UIListLayout")

	if not TabLayout then
		TabLayout = Instance.new("UIListLayout")
	end

	TabLayout.FillDirection =
		Enum.FillDirection.Horizontal

	TabLayout.HorizontalAlignment =
		Enum.HorizontalAlignment.Left

	TabLayout.VerticalAlignment =
		Enum.VerticalAlignment.Center

	TabLayout.SortOrder =
		Enum.SortOrder.LayoutOrder

	TabLayout.Parent = TabBar

	WindowConfig.TabBar = TabBar
	WindowConfig.TabBarLayout = TabLayout

	-- Original button is only a template.
	TemplateTabButton.Visible = false

	--==============================================================
	-- WINDOW DRAG
	--==============================================================

	if not WindowConfig.NoDrag then
		ImGui:ApplyDraggable(
			Window,
			TitleBar
		)
	end

	--==============================================================
	-- WINDOW METHODS
	--==============================================================

	function WindowConfig:Close()
		local Callback = WindowConfig.CloseCallback
		WindowConfig:SetVisible(false)

		if Callback then
			Callback(WindowConfig)
		end

		return WindowConfig
	end

	CloseButton.Activated:Connect(
		WindowConfig.Close
	)

	function WindowConfig:GetHeaderSizeY(): number
		local ToolbarY =
			ToolBar.Visible
			and ToolBar.AbsoluteSize.Y
			or 0

		local TitlebarY =
			TitleBar.Visible
			and TitleBar.AbsoluteSize.Y
			or 0

		return ToolbarY + TitlebarY
	end

	function WindowConfig:UpdateBody()
		local HeaderSizeY =
			WindowConfig:GetHeaderSizeY()

		Body.Size = UDim2.new(
			1,
			0,
			1,
			-HeaderSizeY
		)
	end

	WindowConfig:UpdateBody()
	WindowConfig.Tabs = {}
	WindowConfig.ActiveTab = nil

	--==============================================================
	-- OPEN / CLOSE
	--==============================================================

	WindowConfig.Open = true

	function WindowConfig:SetOpen(Open: boolean, NoAnimation: boolean)
		local WindowAbsoluteSize = Window.AbsoluteSize
		local TitleBarSize = TitleBar.AbsoluteSize

		WindowConfig.Open = Open

		ImGui:HeaderAnimate(
			TitleBar,
			true,
			Open,
			TitleBar,
			Toggle.ToggleButton
		)

		ImGui:Tween(
			Resize,
			{
				TextTransparency = Open and 0.6 or 1,
				Interactable = Open,
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Window,
			{
				Size = Open
					and WindowConfig.Size
					or UDim2.fromOffset(
						WindowAbsoluteSize.X,
						TitleBarSize.Y
					),
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Body,
			{
				Visible = Open,
			},
			nil,
			NoAnimation
		)

		return WindowConfig
	end

	function WindowConfig:SetVisible(Visible: boolean)
		Window.Visible = Visible
		return WindowConfig
	end

	function WindowConfig:SetTitle(Text)
		TitleBar.Left.Title.Text = tostring(Text)
		return WindowConfig
	end

	function WindowConfig:Remove()
		Window:Destroy()
		return WindowConfig
	end

	Toggle.ToggleButton.Activated:Connect(function()
		WindowConfig:SetOpen(
			not WindowConfig.Open
		)
	end)

	--==============================================================
	-- CREATE TAB
	--==============================================================

	function WindowConfig:CreateTab(Config)
		Config = Config or {}

		local Name = Config.Name or ""

		local TabButton =
			ToolBar.TabButton:Clone()

		TabButton.Name = Name
		TabButton.Text = Name
		TabButton.Visible = true
		TabButton.Parent = TabBar
		TabButton.LayoutOrder = #TabBar:GetChildren()
		Config.Button = TabButton

		local AutoSizeAxis =
			WindowConfig.AutoSize
			or "Y"

		local Template = Body.Template
		local Content: Frame = Template:Clone()

		Content.AutomaticSize =
			Enum.AutomaticSize[AutoSizeAxis]

		Content.Visible =
			Config.Visible or false

		Content.Name = Name
		Content.Parent = Body
		Config.Content = Content

		if AutoSizeAxis == "Y" then
			Content.Size =
				UDim2.fromScale(1, 0)
		elseif AutoSizeAxis == "X" then
			Content.Size =
				UDim2.fromScale(0, 1)
		end

		function Config:GetContentSize()
			return Content.AbsoluteSize
		end

		local function RecalculateBody()
			if WindowConfig.ActiveTab ~= Config then
				return
			end

			local Layout =
				Content:FindFirstChildOfClass("UIListLayout")

			local Padding =
				Content:FindFirstChildOfClass("UIPadding")

			local Height =
				Body.AbsoluteWindowSize.Y

			if Layout then
				Height = math.max(
					Height,
					Layout.AbsoluteContentSize.Y
						+ (Padding
							and Padding.PaddingTop.Offset + Padding.PaddingBottom.Offset
							or 0)
				)
			end

			Content.Size = UDim2.new(
				1,
				0,
				0,
				Height
			)

			Body.CanvasSize = UDim2.fromOffset(
				0,
				Height
			)
		end

		local function Activate()
			for _, Page in next, Body:GetChildren() do
				if Page:IsA("GuiObject")
					and Page ~= Body.Template then
					Page.Visible = Page == Content
				end
			end

			WindowConfig.ActiveTab = Config
			Body.CanvasPosition = Vector2.zero

			if not Config.NoAnimation then
				Content.Position =
					UDim2.fromOffset(0, 5)

				ImGui:Tween(
					Content,
					{
						Position =
							UDim2.fromOffset(0, 0),
					}
				)
			else
				Content.Position =
					UDim2.fromOffset(0, 0)
			end

			RecalculateBody()
		end

		TabButton.Activated:Connect(Activate)

		Config =
			ImGui:ContainerClass(
				Content,
				Config,
				Window
			)

		ImGui:ApplyAnimations(
			TabButton,
			"Tabs"
		)

		-- Rebuild the scrollbar size whenever this tab's content changes.
		local Layout =
			Content:FindFirstChildOfClass("UIListLayout")

		if Layout then
			Layout:GetPropertyChangedSignal(
				"AbsoluteContentSize"
			):Connect(RecalculateBody)
		end

		Content.ChildAdded:Connect(RecalculateBody)
		Content.ChildRemoved:Connect(RecalculateBody)
		Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(RecalculateBody)

		-- If this is the requested initial tab, select it.
		if Config.Visible then
			Activate()
		elseif not WindowConfig.ActiveTab then
			Activate()
		end

		if WindowConfig.AutoSize then
			Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local Size = Config:GetContentSize()
				WindowConfig:SetSize(Size)
			end)
		end

		if WindowConfig.UpdateTabBar then
			task.defer(WindowConfig.UpdateTabBar)
		end

		return Config
	end

	--==============================================================
	-- POSITION / SIZE
	--==============================================================

	function WindowConfig:SetPosition(Position)
		Window.Position = Position
		return WindowConfig
	end

	function WindowConfig:SetSize(Size)
		if typeof(Size) == "Vector2" then
			Size = UDim2.fromOffset(Size.X, Size.Y)
		end

		if typeof(Size) ~= "UDim2" then
			return WindowConfig
		end

		local HeaderSizeY =
			WindowConfig:GetHeaderSizeY()

		local NewSize = UDim2.new(
			Size.X.Scale,
			Size.X.Offset,
			Size.Y.Scale,
			Size.Y.Offset + HeaderSizeY
		)

		WindowConfig.Size = NewSize
		Window.Size = NewSize

		return WindowConfig
	end

	--==============================================================
	-- TAB SYSTEM
	--==============================================================

	function WindowConfig:ShowTab(TabClass)
		if not TabClass or not TabClass.Content then
			return WindowConfig
		end

		local TargetPage = TabClass.Content

		if not TargetPage.Visible and not TabClass.NoAnimation then
			TargetPage.Position = UDim2.fromOffset(0, 5)
		end

		for _, Page in next, Body:GetChildren() do
			if Page:IsA("GuiObject")
				and Page ~= Body.Template then
				Page.Visible = Page == TargetPage
			end
		end

		WindowConfig.ActiveTab = TabClass
		Body.CanvasPosition = Vector2.zero

		ImGui:Tween(
			TargetPage,
			{
				Position = UDim2.fromOffset(0, 0),
			}
		)

		return WindowConfig
	end

	function WindowConfig:GetActiveTab()
		return WindowConfig.ActiveTab
	end

	function WindowConfig:Center()
		local Size = Window.AbsoluteSize
		local Position = UDim2.new(
			0.5,
			-Size.X / 2,
			0.5,
			-Size.Y / 2
		)

		WindowConfig:SetPosition(Position)
		return WindowConfig
	end

	--==============================================================
	-- INITIALIZATION
	--==============================================================

	WindowConfig:SetTitle(
		WindowConfig.Title or "Depso UI"
	)

	if WindowConfig.Open == false then
		WindowConfig:SetOpen(false, true)
	end

	-- Theme/style is applied after all relevant window properties are set.
	ImGui.Windows[Window] = WindowConfig

	ImGui:CheckStyles(
		Window,
		WindowConfig,
		WindowConfig.Colors
	)

	-- Required geometry must be restored after styles.
	if typeof(WindowConfig.Size) == "UDim2" then
		Window.Size = WindowConfig.Size
	end

	ToolBar.Size = UDim2.new(
		ToolBar.Size.X.Scale,
		ToolBar.Size.X.Offset,
		0,
		ToolBarHeight
	)

	Resize.Size = UDim2.fromOffset(25, 25)
	pcall(function()
		Resize.TextSize = 24
	end)

	WindowConfig:UpdateBody()

	if WindowConfig.UpdateTabBar then
		task.defer(WindowConfig.UpdateTabBar)
	end

	if not WindowConfig.NoSelectEffect then
		ImGui:ApplyWindowSelectEffect(
			Window,
			TitleBar
		)
	end

	return ImGui:MergeMetatables(
		WindowConfig,
		Window
	)
end

function ImGui:CreateModal(Config)
	local ModalEffect = Prefabs.ModalEffect:Clone()
	ModalEffect.BackgroundTransparency = 1
	ModalEffect.Parent = ImGui.FullScreenGui
	ModalEffect.Visible = true

	ImGui:Tween(ModalEffect, {
		BackgroundTransparency = 0.6
	})

	--// Config
	Config = Config or {}
	Config.TabsBar = Config.TabsBar ~= nil and Config.TabsBar or false
	Config.NoCollapse = true
	Config.NoResize = true
	Config.NoClose = true
	Config.NoSelectEffect = true
	Config.Parent = ModalEffect

	--// Center
	Config.AnchorPoint = Vector2.new(0.5, 0.5)
	Config.Position = UDim2.fromScale(0.5, 0.5)

	--// Create Window
	local Window = self:CreateWindow(Config)
	Config = Window:CreateTab({
		Visible = true
	})

	--// Disable other windows
	local WindowManger = ImGui:SetWindowProps({
		Interactable = false
	}, {Window.Window})

	--// Close functions
	local WindowClose = Window.Close
	function Config:Close()
		local Tween = ImGui:Tween(ModalEffect, {
			BackgroundTransparency = 1
		})
		Tween.Completed:Connect(function()
			ModalEffect:Remove()
		end)

		WindowManger:Revert()
		WindowClose()
	end

	return Config
end

local GuiParent = IsStudio and PlayerGui or CoreGui
ImGui.ScreenGui = ImGui:CreateInstance("ScreenGui", GuiParent, {
	DisplayOrder = 9999,
	ResetOnSpawn = false
})
ImGui.FullScreenGui = ImGui:CreateInstance("ScreenGui", GuiParent, {
	DisplayOrder = 99999,
	ResetOnSpawn = false,
	ScreenInsets = Enum.ScreenInsets.None
})

return ImGui
