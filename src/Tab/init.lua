-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/init.lua

local Tab = {}

function Tab.new(Context, WindowConfig, WindowData, Config)
	assert(Context, "Tab.new: Context is required")
	assert(Context.ImGui, "Tab.new: Context.ImGui is required")
	assert(Context.Core, "Tab.new: Context.Core is required")
	assert(Context.Prefabs, "Tab.new: Context.Prefabs is required")
	assert(Context.Load, "Tab.new: Context.Load is required")

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
	--
	-- IMPORTANT:
	-- Body is already a ScrollingFrame.
	-- We therefore keep the original ImGui architecture and place
	-- the tab content directly inside Body.
	--==============================================================

	local Template = WindowData.Body.Template

	local Content = Template:Clone()

	Content.Name = Name
	Content.Visible = Config.Visible == true
	Content.Parent = WindowData.Body

	--==============================================================
	-- CONTENT LAYOUT
	--==============================================================

	local UIListLayout =
		Content:FindFirstChildOfClass("UIListLayout")

	local UIPadding =
		Content:FindFirstChildOfClass("UIPadding")

	-- Let the tab content grow vertically according to its children.
	Content.AutomaticSize = Enum.AutomaticSize.None

	Content.Size =
		UDim2.new(
			1,
			0,
			0,
			WindowData.Body.AbsoluteSize.Y
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
		Content = Content,

		UIListLayout = UIListLayout,
		UIPadding = UIPadding,

		Body = WindowData.Body,

		Active = false,
		Destroyed = false,

		NeedsScroll = false,
	}

	Config.__TabData = Data

	--==============================================================
	-- TAB REGISTRY
	--==============================================================

	WindowData.Tabs = WindowData.Tabs or {}

	table.insert(
		WindowData.Tabs,
		Config
	)

	--==============================================================
	-- CONFIG REFERENCES
	--==============================================================

	Config.Button = Button
	Config.Content = Content
	Config.ParentWindow = WindowConfig

	--==============================================================
	-- WINDOW DRAG PROTECTION
	--==============================================================

	if WindowConfig.RegisterInteraction then
		WindowConfig:RegisterInteraction(Button)
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
	-- TEMPLATE
	--==============================================================

	Template.Visible = false

	--==============================================================
	-- BODY SIZE
	--==============================================================

	if WindowConfig.UpdateBody then
		WindowConfig:UpdateBody()
	end

	--==============================================================
	-- INITIAL SELECTION
	--==============================================================

	if Config.Visible == true then
		if WindowConfig.ShowTab then
			WindowConfig:ShowTab(Config)
		end
	elseif #WindowData.Tabs == 1 then
		-- First tab becomes the default tab when no tab was
		-- explicitly marked Visible.
		if WindowConfig.ShowTab then
			WindowConfig:ShowTab(Config)
		end
	end

	--==============================================================
	-- FIRST SCROLL UPDATE
	--==============================================================

	task.defer(function()
		if Data.Destroyed then
			return
		end

		if Config.UpdateScroll then
			Config:UpdateScroll()
		end
	end)

	return Config
end

return Tab
