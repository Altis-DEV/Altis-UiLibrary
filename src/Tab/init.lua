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

	local Methods = Context.Load(
		"src/Tab/method.lua"
	)

	--==============================================================
	-- CONFIG
	--==============================================================

	local Name = Config.Name or ""

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
	-- TAB CONTENT
	--==============================================================

	local Template = WindowData.Body.Template

	-- Use the prefab ScrollBox instead of creating a new one.
	local ScrollBox =
		Context.Prefabs.ScrollBox:Clone()

	ScrollBox.Name = Name
	ScrollBox.Visible = Config.Visible == true
	ScrollBox.Parent = WindowData.Body

	--==============================================================
	-- CONTENT FRAME
	--==============================================================

	local Content =
		Template:Clone()

	Content.Name = Name
	Content.Visible = true
	Content.Parent = ScrollBox

	--==============================================================
	-- SCROLLBOX CONFIGURATION
	--==============================================================

	ScrollBox.CanvasPosition = Vector2.zero

	ScrollBox.CanvasSize =
		UDim2.new(0, 0, 0, 0)

	ScrollBox.ScrollBarThickness =
		ScrollBarThickness

	ScrollBox.ScrollingDirection =
		Enum.ScrollingDirection.Y

	ScrollBox.VerticalScrollBarInset =
		Enum.ScrollBarInset.ScrollBar

	ScrollBox.HorizontalScrollBarInset =
		Enum.ScrollBarInset.None

	ScrollBox.AutomaticCanvasSize =
		Enum.AutomaticSize.None

	ScrollBox.ScrollingEnabled = false

	--==============================================================
	-- CONTENT SIZE
	--==============================================================

	Content.AutomaticSize =
		Enum.AutomaticSize.Y

	Content.Size =
		UDim2.new(
			1,
			-ScrollBarThickness,
			0,
			0
		)

	--==============================================================
	-- DATA
	--==============================================================

	local Data = {
		Context = Context,
		ImGui = ImGui,
		Core = Core,

		ParentWindow = WindowData,
		ParentWindowConfig = WindowConfig,

		Button = Button,

		ScrollBox = ScrollBox,
		Content = Content,

		ScrollBarThickness =
			ScrollBarThickness,

		Destroyed = false,
	}

	--==============================================================
	-- CONFIG REFERENCES
	--==============================================================

	Config.Button = Button
	Config.Content = Content
	Config.ScrollBox = ScrollBox
	Config.ParentWindow = WindowConfig

	--==============================================================
	-- WINDOW DRAG PROTECTION
	--==============================================================

	if WindowConfig.RegisterInteraction then
		WindowConfig:RegisterInteraction(Button)
		WindowConfig:RegisterInteraction(ScrollBox)
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
	-- WINDOW BODY
	--==============================================================

	if WindowConfig.UpdateBody then
		WindowConfig:UpdateBody()
	end

	--==============================================================
	-- HIDE ORIGINAL TEMPLATE
	--==============================================================

	Template.Visible = false

	--==============================================================
	-- INITIAL UPDATE
	--==============================================================

	task.defer(function()
		if Data.Destroyed then
			return
		end

		Config:UpdateScroll()
	end)

	return Config
end

return Tab
