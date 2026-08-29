-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/init.lua

local Tab = {}

function Tab.new(Context, WindowConfig, WindowData, Config)
	assert(
		Context,
		"Tab.new: Context is required"
	)

	assert(
		Context.ImGui,
		"Tab.new: Context.ImGui is required"
	)

	assert(
		Context.Core,
		"Tab.new: Context.Core is required"
	)

	assert(
		Context.Prefabs,
		"Tab.new: Context.Prefabs is required"
	)

	assert(
		Context.Load,
		"Tab.new: Context.Load is required"
	)

	Config = Config or {}

	local ImGui = Context.ImGui
	local Core = Context.Core
	local UIS = Core.Services.UserInputService

	local Methods = Context.Load(
		"src/Tab/method.lua"
	)

	--==============================================================
	-- CONFIG
	--==============================================================

	local Name = Config.Name or ""

	local AutoSizeAxis =
		WindowConfig.AutoSize
		or "Y"

	-- Default scrollbar thickness.
	local ScrollBarThickness =
		Config.ScrollBarThickness
		or WindowConfig.ScrollBarThickness
		or 4

	--==============================================================
	-- TAB BUTTON
	--==============================================================

	local Button =
		WindowData.ToolBar.TabButton:Clone()

	Button.Name = Name
	Button.Text = Name
	Button.Visible = true
	Button.Parent = WindowData.ToolBar

	--==============================================================
	-- SCROLL FRAME
	--
	-- We do not replace the original Template.
	-- Instead, it is placed inside a ScrollingFrame.
	--
	-- This keeps the original content Frame structure intact
	-- for ContainerClass and future Elements.
	--==============================================================

	local ScrollFrame =
		Instance.new("ScrollingFrame")

	ScrollFrame.Name = Name
	ScrollFrame.BackgroundTransparency = 1
	ScrollFrame.BorderSizePixel = 0

	ScrollFrame.Size =
		UDim2.fromScale(1, 1)

	ScrollFrame.Position =
		UDim2.fromScale(0, 0)

	ScrollFrame.CanvasSize =
		UDim2.new(0, 0, 0, 0)

	ScrollFrame.CanvasPosition =
		Vector2.zero

	ScrollFrame.AutomaticCanvasSize =
		Enum.AutomaticSize.None

	ScrollFrame.ScrollBarThickness =
		ScrollBarThickness

	ScrollFrame.ScrollingEnabled =
		false

	ScrollFrame.ScrollingDirection =
		Enum.ScrollingDirection.Y

	ScrollFrame.VerticalScrollBarInset =
		Enum.ScrollBarInset.ScrollBar

	ScrollFrame.HorizontalScrollBarInset =
		Enum.ScrollBarInset.None

	ScrollFrame.Parent =
		WindowData.Body

	--==============================================================
	-- ORIGINAL CONTENT FRAME
	--==============================================================

	local Template =
		WindowData.Body.Template

	local Content =
		Template:Clone()

	Content.Name = Name
	Content.Visible = true
	Content.Parent = ScrollFrame

	--==============================================================
	-- CONTENT SIZE
	--==============================================================

	Content.AutomaticSize =
		Enum.AutomaticSize.None

	if AutoSizeAxis == "Y" then
		Content.Size =
			UDim2.new(
				1,
				-ScrollBarThickness,
				0,
				0
			)

	elseif AutoSizeAxis == "X" then
		Content.Size =
			UDim2.new(
				0,
				0,
				1,
				0
			)

	else
		Content.Size =
			UDim2.fromScale(1, 1)
	end

	--==============================================================
	-- DATA
	--==============================================================

	local Data = {
		Context = Context,

		ImGui = ImGui,
		Core = Core,

		ParentWindow = WindowData,

		Button = Button,

		ScrollFrame = ScrollFrame,
		Content = Content,

		ScrollBarThickness =
			ScrollBarThickness,

		Destroyed = false,
	}

	--==============================================================
	-- DEFAULT VISIBILITY
	--==============================================================

	ScrollFrame.Visible =
		Config.Visible == true

	--==============================================================
	-- CONFIG REFERENCES
	--==============================================================

	Config.Button = Button
	Config.Content = Content
	Config.ScrollFrame = ScrollFrame
	Config.ParentWindow = WindowConfig

	--==============================================================
	-- TAB BUTTON INTERACTION
	--
	-- Prevent Window mobile drag from starting when the user
	-- presses the Tab button.
	--==============================================================

	if WindowConfig.RegisterInteraction then
		WindowConfig:RegisterInteraction(Button)
	end

	--==============================================================
	-- SCROLLBAR INTERACTION
	--
	-- Prevent Window dragging when directly touching the native
	-- scrollbar.
	--==============================================================

	if WindowConfig.RegisterInteraction then
		WindowConfig:RegisterInteraction(ScrollFrame)
	end

	--==============================================================
	-- METHODS
	--==============================================================

	Methods.Attach(
		Context,
		Config,
		Data
	)

	--==============================================================
	-- BODY UPDATE
	--==============================================================

	if WindowConfig.UpdateBody then
		WindowConfig:UpdateBody()
	end

	--==============================================================
	-- WINDOW AUTO SIZE
	--==============================================================

	if WindowConfig.AutoSize then
		Content:GetPropertyChangedSignal(
			"AbsoluteSize"
		):Connect(function()
			if Config.GetContentSize
				and WindowConfig.SetSize then

				local Size =
					Config:GetContentSize()

				WindowConfig:SetSize(Size)
			end
		end)
	end

	--==============================================================
	-- CLEAN TEMPLATE
	--
	-- The original Template is only a prefab.
	-- It should never remain visible as a real tab.
	--==============================================================

	Template.Visible = false

	--==============================================================
	-- FIRST UPDATE
	--==============================================================

	task.defer(function()
		if Data.Destroyed then
			return
		end

		Config:UpdateScroll()
	end)

	--==============================================================
	-- RETURN
	--==============================================================

	return Config
end

return Tab
