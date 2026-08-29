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
-- VIEWPORT HEIGHT
--==============================================================

function Methods.GetViewportHeight(Data)
	local Body = Data.Body

	if not Body then
		return 0
	end

	return Body.AbsoluteWindowSize.Y
end

--==============================================================
-- CONTENT SIZE
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

	Content.Size =
		UDim2.new(
			1,
			0,
			0,
			math.max(
				ContentHeight,
				ViewportHeight
			)
		)
end

--==============================================================
-- SCROLL
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

	-- CanvasSize determines the scrollable area.
	Body.CanvasSize =
		UDim2.fromOffset(
			0,
			math.max(
				ContentHeight,
				ViewportHeight
			)
		)

	-- Body is the actual scrolling container.
	Body.ScrollingEnabled = true

	Body.ScrollingDirection =
		Enum.ScrollingDirection.Y

	Body.VerticalScrollBarInset =
		Enum.ScrollBarInset.ScrollBar

	Body.HorizontalScrollBarInset =
		Enum.ScrollBarInset.None

	Body.ScrollBarThickness =
		Data.ScrollBarThickness

	-- Roblox automatically adjusts the scrollbar thumb size
	-- according to CanvasSize and the visible viewport.
	Data.NeedsScroll =
		ContentHeight
		> ViewportHeight + 1

	-- Keep the scroll position valid if the content shrinks.
	local Maximum =
		math.max(
			0,
			Body.AbsoluteCanvasSize.Y
			- Body.AbsoluteWindowSize.Y
		)

	if Body.CanvasPosition.Y > Maximum then
		Body.CanvasPosition =
			Vector2.new(
				0,
				Maximum
			)
	end

	return Data
end

--==============================================================
-- CONTENT SIZE API
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
		Data.Content.Visible =
			Visible == true
	end

	return Data
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

--==============================================================
-- GET SCROLL POSITION
--==============================================================

function Methods.GetScrollPosition(Data)
	if not Data.Body then
		return Vector2.zero
	end

	return Data.Body.CanvasPosition
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
	):Connect(Update)

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
