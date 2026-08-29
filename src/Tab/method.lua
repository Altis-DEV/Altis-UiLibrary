-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/method.lua

local Methods = {}

function Methods.GetContentSize(Data)
	if not Data.Content then
		return Vector2.zero
	end

	return Data.Content.AbsoluteSize
end

function Methods.SetVisible(Data, Visible)
	if not Data.Content then
		return Data
	end

	Data.Content.Visible = Visible == true

	if Data.Button then
		Data.Button.Visible = Data.Button.Visible
	end

	return Data
end

function Methods.Select(Context, Config)
	if not Config or not Config.ParentWindow then
		return Config
	end

	Config.ParentWindow:ShowTab(Config)

	return Config
end

function Methods.Deselect(Data)
	if Data.Content then
		Data.Content.Visible = false
	end

	return Data
end

function Methods.Attach(Context, Config, Data)
	local ImGui = Context.ImGui

	--==============================================================
	-- BASIC METHODS
	--==============================================================

	function Config:GetContentSize()
		return Methods.GetContentSize(Data)
	end

	function Config:SetVisible(Visible)
		return Methods.SetVisible(
			Data,
			Visible
		)
	end

	function Config:Select()
		return Methods.Select(
			Context,
			Config
		)
	end

	function Config:Deselect()
		return Methods.Deselect(Data)
	end

	--==============================================================
	-- INTERNAL REFERENCES
	--==============================================================

	Config.Button = Data.Button
	Config.Content = Data.Content
	Config.ParentWindow = Data.ParentWindow

	--==============================================================
	-- INITIAL VISIBILITY
	--==============================================================

	Data.Content.Visible =
		Config.Visible == true

	--==============================================================
	-- TAB BUTTON
	--==============================================================

	Data.Button.Activated:Connect(function()
		if Data.ParentWindow
			and Data.ParentWindow.ShowTab then

			Data.ParentWindow:ShowTab(Config)
		end
	end)

	--==============================================================
	-- ANIMATION
	--==============================================================

	ImGui:ApplyAnimations(
		Data.Button,
		"Tabs"
	)

	return Config
end

return Methods
