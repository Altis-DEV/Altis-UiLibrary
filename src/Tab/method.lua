-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/method.lua

local Methods = {}

--==============================================================
-- PADDING
--==============================================================

function Methods.GetPaddingY(Data)
	local Padding = Data.UIPadding

	if not Padding then
		return 0
	end

	return
		Padding.PaddingTop.Offset
		+ Padding.PaddingBottom.Offset
end

--==============================================================
-- CONTENT HEIGHT
--==============================================================

function Methods.GetContentHeight(Data)
	local Content = Data.Content
	local Layout = Data.UIListLayout

	if not Content then
		return 0
	end

	if Layout then
		return
			Layout.AbsoluteContentSize.Y
			+ Methods.GetPaddingY(Data)
	end

	return Content.AbsoluteSize.Y
end

--==============================================================
-- VIEWPORT
--==============================================================

function Methods.GetViewportHeight(Data)
	if not Data.Body then
		return 0
	end

	return Data.Body.AbsoluteSize.Y
end

--==============================================================
-- UPDATE CONTENT SIZE
--==============================================================

function Methods.UpdateContentSize(Data)
	local Content = Data.Content

	if not Content then
		return
	end

	local ContentHeight =
		Methods.GetContentHeight(Data)

	local ViewportHeight =
		Methods.GetViewportHeight(Data)

	local Height =
		math.max(
			ContentHeight,
			ViewportHeight
		)

	Content.Size =
		UDim2.new(
			1,
			0,
			0,
			Height
		)
end

--==============================================================
-- UPDATE SCROLL
--==============================================================

function Methods.UpdateScroll(Data)
	if Data.Destroyed then
		return
	end

	local Body = Data.Body

	if not Body or not Data.Content then
		return
	end

	Methods.UpdateContentSize(Data)

	local ContentHeight =
		Methods.GetContentHeight(Data)

	local ViewportHeight =
		Methods.GetViewportHeight(Data)

	if ViewportHeight <= 0 then
		return
	end

	local CanvasHeight =
		math.max(
			ContentHeight,
			ViewportHeight
		)

	Body.CanvasSize =
		UDim2.new(
			0,
			0,
			0,
			CanvasHeight
		)

	local CanScroll =
		ContentHeight
		> ViewportHeight + 1

	Data.NeedsScroll = CanScroll

	if CanScroll then
		Body.ScrollingEnabled = true

		Body.ScrollBarThickness =
			Data.ScrollBarThickness

		Body.ScrollingDirection =
			Enum.ScrollingDirection.Y

		Body.VerticalScrollBarInset =
			Enum.ScrollBarInset.ScrollBar

		Body.HorizontalScrollBarInset =
			Enum.ScrollBarInset.None

		if Data.ParentWindowConfig
			and Data.ParentWindowConfig.RegisterInteraction then

			Data.ParentWindowConfig:RegisterInteraction(
				Body
			)
		end
	else
		Body.ScrollingEnabled = false
		Body.ScrollBarThickness = 0
		Body.CanvasPosition = Vector2.zero

		if Data.ParentWindowConfig
			and Data.ParentWindowConfig.UnregisterInteraction then

			Data.ParentWindowConfig:UnregisterInteraction(
				Body
			)
		end
	end

	return Data
end

--==============================================================
-- CONTENT SIZE
--==============================================================

function Methods.GetContentSize(Data)
	if not Data.Content then
		return Vector2.zero
	end

	return Data.Content.AbsoluteSize
end

--==============================================================
-- VISIBILITY
--==============================================================

function Methods.SetVisible(Data, Visible)
	if Data.Content then
		Data.Content.Visible = Visible == true
	end

	return Data
end

--==============================================================
-- SCROLL TOP
--==============================================================

function Methods.ScrollToTop(Data)
	if Data.Body then
		Data.Body.CanvasPosition =
			Vector2.zero
	end

	return Data
end

--==============================================================
-- SCROLL BOTTOM
--==============================================================

function Methods.ScrollToBottom(Data)
	local Body = Data.Body

	if not Body then
		return Data
	end

	local Maximum =
		math.max(
			0,
			Body.AbsoluteCanvasSize.Y
			- Body.AbsoluteWindowSize.Y
		)

	Body.CanvasPosition =
		Vector2.new(
			0,
			Maximum
		)

	return Data
end

--==============================================================
-- SCROLL POSITION
--==============================================================

function Methods.SetScrollPosition(Data, Position)
	local Body = Data.Body

	if not Body then
		return Data
	end

	local Y

	if typeof(Position) == "Vector2" then
		Y = Position.Y
	else
		Y = tonumber(Position) or 0
	end

	local Maximum =
		math.max(
			0,
			Body.AbsoluteCanvasSize.Y
			- Body.AbsoluteWindowSize.Y
		)

	Body.CanvasPosition =
		Vector2.new(
			0,
			math.clamp(
				Y,
				0,
				Maximum
			)
		)

	return Data
end

function Methods.GetScrollPosition(Data)
	if not Data.Body then
		return Vector2.zero
	end

	return Data.Body.CanvasPosition
end

--==============================================================
-- SELECT
--==============================================================

function Methods.Select(Context, Config)
	if not Config then
		return Config
	end

	local Window =
		Config.ParentWindow

	if Window and Window.ShowTab then
		Window:ShowTab(Config)
	end

	return Config
end

--==============================================================
-- ATTACH
--==============================================================

function Methods.Attach(Context, Config, Data)
	local ImGui = Context.ImGui

	Config.Button =
		Data.Button

	Config.Content =
		Data.Content

	Config.ParentWindow =
		Data.ParentWindowConfig

	--============================================================
	-- CONTENT
	--============================================================

	function Config:GetContentSize()
		return Methods.GetContentSize(Data)
	end

	--============================================================
	-- VISIBILITY
	--============================================================

	function Config:SetVisible(Visible)
		Methods.SetVisible(
			Data,
			Visible
		)

		return self
	end

	--============================================================
	-- SELECT
	--============================================================

	function Config:Select()
		return Methods.Select(
			Context,
			self
		)
	end

	--============================================================
	-- SCROLL METHODS
	--============================================================

	function Config:UpdateScroll()
		Methods.UpdateScroll(Data)

		return self
	end

	function Config:ScrollToTop()
		Methods.ScrollToTop(Data)

		return self
	end

	function Config:ScrollToBottom()
		Methods.ScrollToBottom(Data)

		return self
	end

	function Config:SetScrollPosition(Position)
		Methods.SetScrollPosition(
			Data,
			Position
		)

		return self
	end

	function Config:GetScrollPosition()
		return Methods.GetScrollPosition(Data)
	end

	--============================================================
	-- TAB BUTTON
	--============================================================

	Data.Button.Activated:Connect(function()
		if Data.Destroyed then
			return
		end

		if Data.ParentWindowConfig
			and Data.ParentWindowConfig.ShowTab then

			Data.ParentWindowConfig:ShowTab(
				Config
			)
		end
	end)

	--============================================================
	-- ANIMATION
	--============================================================

	ImGui:ApplyAnimations(
		Data.Button,
		"Tabs"
	)

	--============================================================
	-- CONTENT WATCHER
	--============================================================

	local function Update()
		if Data.Destroyed then
			return
		end

		Methods.UpdateContentSize(Data)

		if Data.Active then
			Methods.UpdateScroll(Data)
		end
	end

	if Data.UIListLayout then
		Data.UIListLayout:GetPropertyChangedSignal(
			"AbsoluteContentSize"
		):Connect(Update)
	end

	Data.Content.ChildAdded:Connect(Update)
	Data.Content.ChildRemoved:Connect(Update)

	Data.Content:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(function()
		if Data.Active then
			Methods.UpdateScroll(Data)
		end
	end)

	Data.Body:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(function()
		if Data.Active then
			Methods.UpdateScroll(Data)
		end
	end)

	return Config
end

--==============================================================
-- ACTIVATE
--==============================================================

function Methods.Activate(Data)
	Data.Active = true
	Data.Content.Visible = true

	Methods.UpdateScroll(Data)

	return Data
end

--==============================================================
-- DEACTIVATE
--==============================================================

function Methods.Deactivate(Data)
	Data.Active = false
	Data.Content.Visible = false

	return Data
end

return Methods
