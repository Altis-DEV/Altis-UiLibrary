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
local GuiService: GuiService = GetService("GuiService")
local RunService: RunService = GetService("RunService")

--// LocalPlayer
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Mouse = LocalPlayer:GetMouse()

--// ImGui Config
local IsStudio = RunService:IsStudio()
ImGui.NoWarnings = not IsStudio

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

		--// Unpack config
		local Value = Config.Value
		if Value == nil then
			Value = 0
		end

		local ValueFormat = Config.Format or "%.d"
		local IsProgress = Config.Progress

		Config.Name = Config.Label or ""

		--// Slider element
		local Slider: TextButton = Prefabs.Slider:Clone()
		local UIPadding = Slider:FindFirstChildOfClass("UIPadding")
		local Grab: Frame = Slider.Grab
		local ValueText = Slider.ValueText
		local Label = Slider.Label

		local Dragging = false
		local ActiveInput = nil

		local ObjectClass = self:NewInstance(Slider, Config)

		local function Callback(...)
			local func = Config.Callback or NullFunction
			return func(ObjectClass, ...)
		end

		--// Apply Progress styles
		if IsProgress then
			local UIGradient = Grab:FindFirstChildOfClass("UIGradient")

			local PaddingSides = UDim.new(0,2)
			local Diff = UIPadding.PaddingLeft - PaddingSides

			Grab.AnchorPoint = Vector2.new(0, 0.5)

			if UIGradient then
				UIGradient.Enabled = true
			end

			UIPadding.PaddingLeft = PaddingSides
			UIPadding.PaddingRight = PaddingSides

			Label.Position =
				UDim2.new(
					1,
					15 - Diff.Offset,
					0,
					0
				)
		end

		function Config:SetValue(Value: number, SliderMode: boolean)
			local MinValue = Config.MinValue
			local MaxValue = Config.MaxValue

			local Difference =
				MaxValue - MinValue

			if Difference == 0 then
				Difference = 1
			end

			local Percentage

			if SliderMode then
				Percentage =
					math.clamp(
						tonumber(Value) or 0,
						0,
						1
					)

				Value =
					MinValue
					+ (Difference * Percentage)
			else
				Value =
					tonumber(Value)
					or MinValue

				Percentage =
					(Value - MinValue)
					/ Difference

				Percentage =
					math.clamp(
						Percentage,
						0,
						1
					)
			end

			local Props = {
				Position =
					UDim2.fromScale(
						Percentage,
						0.5
					)
			}

			if IsProgress then
				Props = {
					Size =
						UDim2.fromScale(
							Percentage,
							1
						)
				}
			end

			ImGui:Tween(
				Grab,
				Props
			)

			Config.Value = Value

			ValueText.Text =
				ValueFormat:format(
					Value,
					MaxValue
				)

			Callback(Value)

			return Config
		end

		local function UpdateFromInput(Input)
			if Config.ReadOnly then
				return
			end

			local PositionX =
				Input.Position.X

			local Left =
				Slider.AbsolutePosition.X

			local Width =
				Slider.AbsoluteSize.X

			if Width <= 0 then
				return
			end

			local Percentage =
				(PositionX - Left)
				/ Width

			Percentage =
				math.clamp(
					Percentage,
					0,
					1
				)

			Config:SetValue(
				Percentage,
				true
			)
		end

		local function Begin(Input)
			if Config.ReadOnly
				or Dragging then
				return
			end

			Dragging = true
			ActiveInput = Input

			UpdateFromInput(Input)
		end

		local function End(Input)
			if not Dragging then
				return
			end

			if Input
				and Input ~= ActiveInput then
				return
			end

			Dragging = false
			ActiveInput = nil
		end

		-- Desktop + Mobile.
		Slider.InputBegan:Connect(function(Input)
			local InputType =
				Input.UserInputType

			if InputType ~= Enum.UserInputType.MouseButton1
				and InputType ~= Enum.UserInputType.Touch then
				return
			end

			Begin(Input)
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if not Dragging then
				return
			end

			if Input.UserInputType
				== Enum.UserInputType.MouseMovement then

				if ActiveInput
					and ActiveInput.UserInputType
						== Enum.UserInputType.MouseButton1 then

					UpdateFromInput(Input)
				end

				return
			end

			if Input.UserInputType
				== Enum.UserInputType.Touch
				and Input == ActiveInput then

				UpdateFromInput(Input)
			end
		end)

		UserInputService.InputEnded:Connect(function(Input)
			End(Input)
		end)

		Config:SetValue(
			Value
		)

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
	local Animatons = ImGui.Animations
	local ColorProps = Animatons[Class]

	if not ColorProps then 
		return warn("No colors for", Class)
	end

	--// Apply tweens for connections
	local Connections = {}
	for Connection, Props in next, ColorProps do
		if typeof(Props) ~= "table" then continue end
		local Target = Target or Instance
		local Callback = function()
			ImGui:Tween(Target, Props)
		end

		--// Connections
		Connections[Connection] = Callback
		Instance[Connection]:Connect(Callback)
	end

	--// Reset colors
	if Connections["MouseLeave"] then
		Connections["MouseLeave"]()
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

function ImGui:ApplyDraggable(Frame: Frame, Header: GuiObject?)
	local Dragging = false
	local ActiveInput = nil
	local DragStart = nil
	local StartPosition = nil

	Header = Header or Frame

	local function IsInside(GuiObject: GuiObject, Position: Vector2)
		local AbsolutePosition = GuiObject.AbsolutePosition
		local AbsoluteSize = GuiObject.AbsoluteSize

		return Position.X >= AbsolutePosition.X
			and Position.X <= AbsolutePosition.X + AbsoluteSize.X
			and Position.Y >= AbsolutePosition.Y
			and Position.Y <= AbsolutePosition.Y + AbsoluteSize.Y
	end

	-- Controls that should consume the touch instead of moving the window.
	local function IsProtectedInteraction(Position: Vector2)
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

			-- Interactive Roblox controls should keep their own input.
			if Object:IsA("GuiButton")
				or Object:IsA("TextBox")
				or Object:IsA("ScrollingFrame") then
				return true
			end

			if Object.Active or Object.Selectable then
				return true
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

		DragStart = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		StartPosition = Frame.Position
	end

	local function End(Input)
		if not Dragging then
			return
		end

		if Input and Input ~= ActiveInput then
			return
		end

		Dragging = false
		ActiveInput = nil
		DragStart = nil
		StartPosition = nil
	end

	local function Update(Position)
		if not Dragging then
			return
		end

		if not DragStart or not StartPosition then
			return
		end

		local CurrentPosition = Vector2.new(
			Position.X,
			Position.Y
		)

		local Delta = CurrentPosition - DragStart

		Frame.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end

	-- Global capture fixes touch started on child GUI objects.
	UserInputService.InputBegan:Connect(function(Input)
		local InputType = Input.UserInputType

		if InputType ~= Enum.UserInputType.MouseButton1
			and InputType ~= Enum.UserInputType.Touch then
			return
		end

		if not Frame.Visible then
			return
		end

		local Position = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		if not IsInside(Frame, Position) then
			return
		end

		-- Never steal input from resize or other interactive controls.
		if IsProtectedInteraction(Position) then
			return
		end

		-- Mouse = title bar only.
		if InputType == Enum.UserInputType.MouseButton1 then
			if IsInside(Header, Position) then
				Begin(Input)
			end

			return
		end

		-- Touch = anywhere else inside the window.
		Begin(Input)
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end

		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			if ActiveInput and ActiveInput.UserInputType == Enum.UserInputType.MouseButton1 then
				Update(Input.Position)
			end

			return
		end

		if Input.UserInputType == Enum.UserInputType.Touch
			and Input == ActiveInput then
			Update(Input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		End(Input)
	end)
end

function ImGui:ApplyResizable(MinSize, Frame: Frame, Dragger: GuiObject, Config)
	local DragStart = nil
	local OriginalSize = nil
	local ActiveInput = nil

	MinSize = MinSize or Vector2.new(160, 90)

	local function Begin(Input)
		if DragStart then
			return
		end

		ActiveInput = Input

		OriginalSize =
			Frame.AbsoluteSize

		DragStart = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)
	end

	local function Update(Position)
		if not DragStart or not OriginalSize then
			return
		end

		local CurrentPosition =
			Vector2.new(
				Position.X,
				Position.Y
			)

		local Delta =
			CurrentPosition
			- DragStart

		local NewSize =
			OriginalSize + Delta

		local Size =
			UDim2.fromOffset(
				math.max(
					MinSize.X,
					NewSize.X
				),
				math.max(
					MinSize.Y,
					NewSize.Y
				)
			)

		Frame.Size = Size

		if Config then
			Config.Size = Size
		end
	end

	local function End(Input)
		if not DragStart then
			return
		end

		if Input and Input ~= ActiveInput then
			return
		end

		DragStart = nil
		OriginalSize = nil
		ActiveInput = nil
	end

	Dragger.InputBegan:Connect(function(Input)
		local InputType =
			Input.UserInputType

		if InputType ~= Enum.UserInputType.MouseButton1
			and InputType ~= Enum.UserInputType.Touch then
			return
		end

		Begin(Input)
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not DragStart then
			return
		end

		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			if ActiveInput and ActiveInput.UserInputType == Enum.UserInputType.MouseButton1 then
				Update(Input.Position)
			end

			return
		end

		if Input.UserInputType == Enum.UserInputType.Touch
			and Input == ActiveInput then
			Update(Input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		End(Input)
	end)
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

	--// Normalize Vector2 window size before applying it.
	if typeof(WindowConfig.Size) == "Vector2" then
		WindowConfig.Size = UDim2.fromOffset(
			WindowConfig.Size.X,
			WindowConfig.Size.Y
		)
	end

	--// Create Window frame
	local Window: Frame = Prefabs.Window:Clone()
	Window.Parent = WindowConfig.Parent or ImGui.ScreenGui
	Window.Visible = true
	WindowConfig.Window = Window

	-- Apply requested size immediately.
	if typeof(WindowConfig.Size) == "UDim2" then
		Window.Size = WindowConfig.Size
	end

	local Content = Window.Content
	local Body = Content.Body

	--// Window Resize
	local Resize = Window.ResizeGrab
	Resize.Visible = WindowConfig.NoResize ~= true

	-- Modern resize handle.
	pcall(function()
		Resize.Size = UDim2.fromOffset(25, 25)
	end)

	pcall(function()
		Resize.TextSize = 24
	end)

	local MinSize =
		WindowConfig.MinSize
		or Vector2.new(160, 90)

	ImGui:ApplyResizable(
		MinSize,
		Window,
		Resize,
		WindowConfig
	)

	--// Title Bar
	local TitleBar: Frame = Content.TitleBar
	TitleBar.Visible =
		WindowConfig.NoTitleBar ~= true

	local Toggle =
		TitleBar.Left.Toggle

	Toggle.Visible =
		WindowConfig.NoCollapse ~= true

	ImGui:ApplyAnimations(
		Toggle.ToggleButton,
		"Tabs"
	)

	--// Toolbar
	local ToolBar =
		Content.ToolBar

	ToolBar.Visible =
		WindowConfig.TabsBar ~= false

	-- Save the toolbar's prefab height before inserting
	-- the horizontal scrolling container.
	local ToolBarHeight =
		ToolBar.AbsoluteSize.Y

	if ToolBarHeight <= 0 then
		ToolBarHeight = 32
	end

	ToolBar.Size =
		UDim2.new(
			1,
			0,
			0,
			ToolBarHeight
		)

	-- Horizontal tab ScrollingFrame.
	local TabBar: ScrollingFrame =
		Instance.new(
			"ScrollingFrame"
		)

	TabBar.Name = "TabBar"
	TabBar.BackgroundTransparency = 1
	TabBar.BorderSizePixel = 0
	TabBar.Position = UDim2.fromScale(0, 0)
	TabBar.Size = UDim2.fromScale(1, 1)

	TabBar.CanvasPosition = Vector2.zero
	TabBar.CanvasSize = UDim2.fromScale(0, 0)

	TabBar.AutomaticCanvasSize =
		Enum.AutomaticSize.X

	TabBar.ScrollingDirection =
		Enum.ScrollingDirection.X

	TabBar.ScrollingEnabled = true

	-- Modern look: scrollbar remains usable through touch
	-- but visually invisible.
	TabBar.ScrollBarThickness = 0

	TabBar.HorizontalScrollBarInset =
		Enum.ScrollBarInset.None

	TabBar.VerticalScrollBarInset =
		Enum.ScrollBarInset.None

	TabBar.Parent = ToolBar

	local TabLayout: UIListLayout =
		Instance.new(
			"UIListLayout"
		)

	TabLayout.FillDirection =
		Enum.FillDirection.Horizontal

	TabLayout.HorizontalAlignment =
		Enum.HorizontalAlignment.Left

	TabLayout.VerticalAlignment =
		Enum.VerticalAlignment.Center

	TabLayout.SortOrder =
		Enum.SortOrder.LayoutOrder

	TabLayout.Padding =
		UDim.new(0, 4)

	TabLayout.Parent =
		TabBar

	-- Original TabButton is only a prefab now.
	ToolBar.TabButton.Visible = false

	WindowConfig.__TabBar = TabBar
	WindowConfig.__TabLayout = TabLayout
	WindowConfig.__ToolBarHeight =
		ToolBarHeight

	--// Mobile + desktop Window drag.
	if not WindowConfig.NoDrag then
		ImGui:ApplyDraggable(
			Window,
			TitleBar
		)
	end

	--// Close Window
	local CloseButton: GuiObject =
		TitleBar.Close

	CloseButton.Visible =
		WindowConfig.NoClose ~= true

	-- New close icon.
	pcall(function()
		CloseButton.Image =
			"rbxassetid://127173792845658"
	end)

	-- Slightly larger close button.
	pcall(function()
		local CurrentSize =
			CloseButton.Size

		CloseButton.Size =
			UDim2.new(
				CurrentSize.X.Scale,
				CurrentSize.X.Offset + 4,
				CurrentSize.Y.Scale,
				CurrentSize.Y.Offset + 4
			)
	end)

	function WindowConfig:Close()
		local Callback =
			WindowConfig.CloseCallback

		WindowConfig:SetVisible(false)

		if Callback then
			Callback(
				WindowConfig
			)
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
			self:GetHeaderSizeY()

		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-HeaderSizeY
			)
	end

	WindowConfig:UpdateBody()

	--// Open/Close
	WindowConfig.Open = true

	function WindowConfig:SetOpen(
		Open: boolean,
		NoAnimation: boolean
	)
		local WindowAbSize =
			Window.AbsoluteSize

		local TitleBarSize =
			TitleBar.AbsoluteSize

		self.Open = Open

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
				TextTransparency =
					Open and 0.6 or 1,

				Interactable =
					Open
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Window,
			{
				Size =
					Open
					and self.Size
					or UDim2.fromOffset(
						WindowAbSize.X,
						TitleBarSize.Y
					)
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Body,
			{
				Visible = Open
			},
			nil,
			NoAnimation
		)

		return self
	end

	function WindowConfig:SetVisible(
		Visible: boolean
	)
		Window.Visible =
			Visible

		return self
	end

	function WindowConfig:SetTitle(Text)
		TitleBar.Left.Title.Text =
			tostring(Text)

		return self
	end

	function WindowConfig:Remove()
		Window:Remove()

		return self
	end

	Toggle.ToggleButton.Activated:Connect(
		function()
			local Open =
				not WindowConfig.Open

			WindowConfig.Open =
				Open

			return WindowConfig:SetOpen(
				Open
			)
		end
	)

	function WindowConfig:CreateTab(Config)
		Config =
			Config
			or {}

		local Name =
			Config.Name
			or ""

		local TabButton =
			ToolBar.TabButton:Clone()

		TabButton.Name =
			Name

		TabButton.Text =
			Name

		TabButton.Visible =
			true

		TabButton.Parent =
			TabBar

		Config.Button =
			TabButton

		local AutoSizeAxis =
			WindowConfig.AutoSize
			or "Y"

		local TabContent: Frame =
			Body.Template:Clone()

		TabContent.AutomaticSize =
			Enum.AutomaticSize[
				AutoSizeAxis
			]

		TabContent.Visible =
			Config.Visible
			or false

		TabContent.Name =
			Name

		TabContent.Parent =
			Body

		Config.Content =
			TabContent

		if AutoSizeAxis == "Y" then
			TabContent.Size =
				UDim2.fromScale(
					1,
					0
				)

		elseif AutoSizeAxis == "X" then
			TabContent.Size =
				UDim2.fromScale(
					0,
					1
				)
		end

		TabButton.Activated:Connect(
			function()
				WindowConfig:ShowTab(
					Config
				)
			end
		)

		function Config:GetContentSize()
			return TabContent.AbsoluteSize
		end

		-- Apply existing element/container system.
		Config =
			ImGui:ContainerClass(
				TabContent,
				Config,
				Window
			)

		ImGui:ApplyAnimations(
			TabButton,
			"Tabs"
		)

		WindowConfig:UpdateBody()

		if WindowConfig.AutoSize then
			TabContent:GetPropertyChangedSignal(
				"AbsoluteSize"
			):Connect(
				function()
					local Size =
						Config:GetContentSize()

					WindowConfig:SetSize(
						Size
					)
				end
			)
		end

		-- Keep toolbar auto width up to date.
		TabLayout:GetPropertyChangedSignal(
			"AbsoluteContentSize"
		):Connect(
			function()
				-- AutomaticCanvasSize = X does the actual work.
				-- This connection intentionally only triggers a
				-- layout refresh for older executor runtimes.
				TabBar.CanvasPosition =
					Vector2.new(
						TabBar.CanvasPosition.X,
						0
					)
			end
		)

		return Config
	end

	function WindowConfig:SetPosition(Position)
		Window.Position =
			Position

		return self
	end

	function WindowConfig:SetSize(Size)
		local HeaderSizeY =
			self:GetHeaderSizeY()

		if typeof(Size) == "Vector2" then
			Size =
				UDim2.fromOffset(
					Size.X,
					Size.Y
				)
		end

		local NewSize =
			UDim2.new(
				Size.X.Scale,
				Size.X.Offset,
				Size.Y.Scale,
				Size.Y.Offset
					+ HeaderSizeY
			)

		self.Size =
			NewSize

		Window.Size =
			NewSize

		return self
	end

	--// Tab change system
	function WindowConfig:ShowTab(
		TabClass: SharedTable
	)
		if not TabClass
			or not TabClass.Content then
			return self
		end

		local TargetPage =
			TabClass.Content

		if not TargetPage.Visible
			and not TabClass.NoAnimation then

			TargetPage.Position =
				UDim2.fromOffset(
					0,
					5
				)
		end

		for _, Page in next,
			Body:GetChildren() do

			if not Page:IsA("GuiObject") then
				continue
			end

			-- Don't hide the Body's prefab.
			if Page == Body.Template then
				continue
			end

			Page.Visible =
				Page == TargetPage
		end

		WindowConfig.ActiveTab =
			TabClass

		if TabBar then
			-- Keep selected tab visible if it has moved off-screen.
			task.defer(
				function()
					local Button =
						TabClass.Button

					if not Button then
						return
					end

					local ButtonX =
						Button.AbsolutePosition.X
						- TabBar.AbsolutePosition.X

					local Left =
						TabBar.CanvasPosition.X

					local Right =
						Left
						+ TabBar.AbsoluteSize.X

					local Width =
						Button.AbsoluteSize.X

					if ButtonX < Left then
						TabBar.CanvasPosition =
							Vector2.new(
								math.max(
									0,
									ButtonX - 8
								),
								0
							)
					elseif ButtonX + Width > Right then
						TabBar.CanvasPosition =
							Vector2.new(
								ButtonX
								+ Width
								- TabBar.AbsoluteSize.X
								+ 8,
								0
							)
					end
				end
			)
		end

		ImGui:Tween(
			TargetPage,
			{
				Position =
					UDim2.fromOffset(
						0,
						0
					)
			}
		)

		return self
	end

	function WindowConfig:Center()
		local Size =
			Window.AbsoluteSize

		local Position =
			UDim2.new(
				0.5,
				-Size.X / 2,
				0.5,
				-Size.Y / 2
			)

		self:SetPosition(
			Position
		)

		return self
	end

	--// Load Style Configs
	WindowConfig:SetTitle(
		WindowConfig.Title
		or "Depso UI"
	)

	-- Keep default size from the prefab if none was provided.
	if typeof(WindowConfig.Size)
		~= "UDim2" then

		WindowConfig.Size =
			Window.Size
	end

	-- Do not accidentally force "false" to open.
	if WindowConfig.Open == false then
		WindowConfig:SetOpen(
			false,
			true
		)
	else
		WindowConfig.Open =
			true
	end

	ImGui.Windows[Window] =
		WindowConfig

	ImGui:CheckStyles(
		Window,
		WindowConfig,
		WindowConfig.Colors
	)

	-- Restore the requested dimensions after style application.
	if typeof(WindowConfig.Size)
		== "UDim2" then

		Window.Size =
			WindowConfig.Size
	end

	-- Restore the modern resize handle after styles.
	pcall(function()
		Resize.Size =
			UDim2.fromOffset(
				25,
				25
			)

		Resize.TextSize = 24
	end)

	-- Restore toolbar geometry after styles.
	if ToolBar.Visible then
		ToolBar.Size =
			UDim2.new(
				1,
				0,
				0,
				ToolBarHeight
			)

		TabBar.Size =
			UDim2.fromScale(
				1,
				1
			)
	end

	--// Window section events
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