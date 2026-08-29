-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/init.lua

local Tab = {}

function Tab.new(Context, WindowConfig, WindowData, Config)
	assert(Context, "Tab.new: Context is required")
	assert(Context.ImGui, "Tab.new: Context.ImGui is required")
	assert(Context.Core, "Tab.new: Context.Core is required")
	assert(Context.Prefabs, "Tab.new: Context.Prefabs is required")

	Config = Config or {}

	local ImGui = Context.ImGui
	local Prefabs = Context.Prefabs

	local Methods = Context.Load(
		"src/Tab/method.lua"
	)

	--==============================================================
	-- TAB BUTTON
	--==============================================================

	local Button =
		WindowData.ToolBar.TabButton:Clone()

	Button.Name =
		Config.Name or ""

	Button.Text =
		Config.Name or ""

	Button.Visible = true
	Button.Parent =
		WindowData.ToolBar

	--==============================================================
	-- TAB CONTENT
	--==============================================================

	local Content =
		WindowData.Body.Template:Clone()

	Content.Name =
		Config.Name or ""

	Content.Visible =
		Config.Visible == true

	Content.Parent =
		WindowData.Body

	--==============================================================
	-- AUTO SIZE
	--==============================================================

	local AutoSizeAxis =
		WindowConfig.AutoSize
		or "Y"

	Content.AutomaticSize =
		Enum.AutomaticSize[AutoSizeAxis]

	if AutoSizeAxis == "Y" then
		Content.Size =
			UDim2.fromScale(1, 0)

	elseif AutoSizeAxis == "X" then
		Content.Size =
			UDim2.fromScale(0, 1)
	end

	--==============================================================
	-- DATA
	--==============================================================

	local Data = {
		Context = Context,

		ImGui = ImGui,

		ParentWindow = WindowData,

		Button = Button,
		Content = Content,
	}

	--==============================================================
	-- CONFIG REFERENCES
	--==============================================================

	Config.Button = Button
	Config.Content = Content
	Config.ParentWindow = WindowConfig

	--==============================================================
	-- METHODS
	--==============================================================

	Methods.Attach(
		Context,
		Config,
		Data
	)

	--==============================================================
	-- INITIAL BODY UPDATE
	--==============================================================

	if WindowConfig.UpdateBody then
		WindowConfig:UpdateBody()
	end

	--==============================================================
	-- AUTO WINDOW SIZE
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
	-- RETURN
	--==============================================================

	return Config
end

return Tab
