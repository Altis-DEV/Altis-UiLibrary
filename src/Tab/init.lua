-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/init.lua

local Tab = {}

function Tab.new(
	Context,
	WindowConfig,
	WindowData,
	Config
)
	assert(Context, "Tab.new: Context is required")
	assert(Context.ImGui, "Tab.new: Context.ImGui is required")
	assert(Context.Core, "Tab.new: Context.Core is required")
	assert(Context.Prefabs, "Tab.new: Context.Prefabs is required")
	assert(Context.Load, "Tab.new: Context.Load is required")

	Config = Config or {}

	local ImGui = Context.ImGui
	local Core = Context.Core

	local Methods =
		Context.Load(
			"src/Tab/method.lua"
		)

	local Name =
		Config.Name or ""

	--==============================================================
	-- TAB BAR
	--==============================================================

	local TabBar =
		WindowData.TabBar

	if not TabBar then
		TabBar =
			Context.Prefabs.ScrollBox:Clone()

		TabBar.Name =
			"TabBar"

		TabBar.BackgroundTransparency =
			1

		TabBar.BorderSizePixel =
			0

		TabBar.Position =
			UDim2.fromScale(
				0,
				0
			)

		TabBar.Size =
			UDim2.new(
				1,
				0,
				0,
				WindowData.ToolBarHeight
			)

		TabBar.CanvasPosition =
			Vector2.zero

		TabBar.CanvasSize =
			UDim2.fromOffset(
				0,
				0
			)

		TabBar.AutomaticCanvasSize =
			Enum.AutomaticSize.None

		TabBar.ScrollingDirection =
			Enum.ScrollingDirection.X

		TabBar.ScrollingEnabled =
			true

		TabBar.HorizontalScrollBarInset =
			Enum.ScrollBarInset.None

		TabBar.VerticalScrollBarInset =
			Enum.ScrollBarInset.None

		TabBar.ScrollBarThickness =
			0

		TabBar.ClipsDescendants =
			true

		TabBar.Parent =
			WindowData.ToolBar

		--==========================================================
		-- TAB LAYOUT
		--==========================================================

		local Layout =
			Instance.new(
				"UIListLayout"
			)

		Layout.FillDirection =
			Enum.FillDirection.Horizontal

		Layout.HorizontalAlignment =
			Enum.HorizontalAlignment.Left

		Layout.VerticalAlignment =
			Enum.VerticalAlignment.Center

		Layout.SortOrder =
			Enum.SortOrder.LayoutOrder

		Layout.Padding =
			UDim.new(
				0,
				4
			)

		Layout.Parent =
			TabBar

		WindowData.TabBar =
			TabBar

		WindowData.TabBarLayout =
			Layout

		-- Original button is only a template.
		WindowData.ToolBar.TabButton.Visible =
			false

		--==========================================================
		-- UPDATE TOOLBAR SCROLL
		--==========================================================

		local function UpdateTabBar()
			if not TabBar.Parent then
				return
			end

			local ContentWidth =
				Layout.AbsoluteContentSize.X

			local ViewportWidth =
				TabBar.AbsoluteSize.X

			local CanScroll =
				ContentWidth
				> ViewportWidth + 1

			TabBar.CanvasSize =
				UDim2.fromOffset(
					math.max(
						ContentWidth,
						ViewportWidth
					),
					0
				)

			if CanScroll then
				TabBar.ScrollBarThickness =
					Config.TabBarScrollBarThickness
					or WindowConfig.TabBarScrollBarThickness
					or 4

				TabBar.HorizontalScrollBarInset =
					Enum.ScrollBarInset.ScrollBar
			else
				TabBar.ScrollBarThickness =
					0

				TabBar.HorizontalScrollBarInset =
					Enum.ScrollBarInset.None

				TabBar.CanvasPosition =
					Vector2.zero
			end
		end

		Layout:GetPropertyChangedSignal(
			"AbsoluteContentSize"
		):Connect(
			UpdateTabBar
		)

		TabBar:GetPropertyChangedSignal(
			"AbsoluteSize"
		):Connect(
			UpdateTabBar
		)

		task.defer(
			UpdateTabBar
		)
	end

	--==============================================================
	-- TAB BUTTON
	--==============================================================

	local Button =
		WindowData.ToolBar.TabButton:Clone()

	Button.Name =
		Name

	Button.Text =
		Name

	Button.Visible =
		true

	Button.Active =
		true

	Button.Selectable =
		true

	Button.LayoutOrder =
		#WindowData.Tabs + 1

	Button.Parent =
		TabBar

	--==============================================================
	-- TAB CONTENT
	--==============================================================

	local Template =
		WindowData.Body.Template

	local Content =
		Template:Clone()

	Content.Name =
		Name

	Content.Visible =
		false

	Content.Position =
		UDim2.fromOffset(
			0,
			0
		)

	Content.Size =
		UDim2.new(
			1,
			0,
			0,
			WindowData.Body.AbsoluteSize.Y
		)

	Content.AutomaticSize =
		Enum.AutomaticSize.None

	Content.Parent =
		WindowData.Body

	--==============================================================
	-- DATA
	--==============================================================

	local Data = {
		Context = Context,
		ImGui = ImGui,
		Core = Core,

		ParentWindow =
			WindowData,

		ParentWindowConfig =
			WindowConfig,

		Button =
			Button,

		Content =
			Content,

		Body =
			WindowData.Body,

		TabBar =
			TabBar,

		UIListLayout =
			Content:FindFirstChildOfClass(
				"UIListLayout"
			),

		UIPadding =
			Content:FindFirstChildOfClass(
				"UIPadding"
			),

		Active = false,
		Destroyed = false,

		NeedsScroll = false,

		ScrollBarThickness =
			Config.ScrollBarThickness
			or WindowConfig.ScrollBarThickness
			or 4,
	}

	Config.__TabData =
		Data

	table.insert(
		WindowData.Tabs,
		Config
	)

	Config.Button =
		Button

	Config.Content =
		Content

	Config.ParentWindow =
		WindowConfig

	Config.TabBar =
		TabBar

	-- Toolbar is owned by TabBar.
	if WindowConfig.RegisterInteraction then
		WindowConfig:RegisterInteraction(
			TabBar
		)
	end

	--==============================================================
	-- TEMPLATE
	--==============================================================

	Template.Visible =
		false

	--==============================================================
	-- METHODS
	--==============================================================

	Methods.Attach(
		Context,
		Config,
		Data
	)

	--==============================================================
	-- BODY
	--==============================================================

	if WindowConfig.UpdateBody then
		WindowConfig:UpdateBody()
	end

	--==============================================================
	-- INITIAL TAB
	--==============================================================

	if Config.Visible == true then
		WindowConfig:ShowTab(
			Config
		)
	elseif #WindowData.Tabs == 1 then
		WindowConfig:ShowTab(
			Config
		)
	end

	--==============================================================
	-- INITIAL SCROLL
	--==============================================================

	task.defer(
		function()
			if Data.Destroyed then
				return
			end

			if Config.UpdateScroll then
				Config:UpdateScroll()
			end
		end
	)

	return Config
end

return Tab
