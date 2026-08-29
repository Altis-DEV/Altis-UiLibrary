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
		return Layout.AbsoluteContentSize.Y
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

	return Body.AbsoluteSize.Y
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

	-- A tab should always cover at least the visible Body area.
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
-- SCROLL UPDATE
--==============================================================

function Methods.UpdateScroll(Data)
	local Body = Data.Body

	if not Body or not Data.Content then
		return
	end

	-- Update the content's physical height first.
	Methods.UpdateContentSize(Data)

	local ContentHeight =
		Methods.GetContentHeight(Data)

	local ViewportHeight =
		Methods.GetViewportHeight(Data)

	if ViewportHeight <= 0 then
		return
	end

	--============================================================
	-- CANVAS SIZE
	--============================================================

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

	--============================================================
	-- SCROLLBAR VISIBILITY
	--============================================================

	local CanScroll =
		ContentHeight
		> ViewportHeight + 1

	Data.NeedsScroll = CanScroll

	if CanScroll then
		Body.ScrollingEnabled = true

		Body.ScrollingDirection =
			Enum.ScrollingDirection.Y

		Body.VerticalScrollBarInset =
			Enum.ScrollBarInset.ScrollBar

		Body.HorizontalScrollBarInset =
			Enum.ScrollBarInset.None

		Body.ScrollBarThickness =
			Data.ScrollBarThickness or 4

		-- The native Roblox scrollbar automatically changes
		-- its thumb size from CanvasSize / viewport size.

		-- While the Body is scrollable, its touch interaction
		-- gets priority over Window dragging.
		if Data.ParentWindowConfig
			and Data.ParentWindowConfig.RegisterInteraction then

			Data.ParentWindowConfig:RegisterInteraction(
				Body
			)
		end
	else
		Body.ScrollingEnabled = false

		Body.ScrollBarThickness = 0

		Body.CanvasPosition =
			Vector2.zero

		-- Remove the Body from the Window drag protection
		-- when there is nothing to scroll.
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
	Data.Content.Visible =
		Visible == true

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

	local CanvasHeight =
		Body.AbsoluteCanvasSize.Y

	local ViewportHeight =
		Body.AbsoluteWindowSize.Y

	Body.CanvasPosition =
		Vector2.new(
			0,
			math.max(
				0,
				CanvasHeight - ViewportHeight
			)
		)

	return Data
end

--==============================================================
-- SET SCROLL
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

	local MaxY =
		math.max(
			0,
			Body.AbsoluteCanvasSize.Y
			- Body.AbsoluteWindowSize.Y
		)

	Body.CanvasPosition =
		Vector2.new(
			0,
			math.clamp(Y, 0, MaxY)
		)

	return Data
end

--==============================================================
-- GET SCROLL
--==============================================================

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

	--============================================================
	-- REFERENCES
	--============================================================

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
		if Data.Destroyed then
			return self
		end

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
	-- SCROLL
	--============================================================

	function Config:UpdateScroll()
		if Data.Destroyed then
			return self
		end

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
		if Data.ParentWindowConfig
			and Data.ParentWindowConfig.ShowTab then

			Data.ParentWindowConfig:ShowTab(
				self
			)
		end
	end)

	ImGui:ApplyAnimations(
		Data.Button,
		"Tabs"
	)

	--============================================================
	-- CONTENT SIZE WATCH
	--============================================================

	local function Update()
		if Data.Destroyed then
			return
		end

		-- Only the active tab controls Body.CanvasSize.
		if not Data.Active then
			Methods.UpdateContentSize(Data)
			return
		end

		Methods.UpdateScroll(Data)
	end

	-- UIListLayout changes whenever children change size/count.
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

	--============================================================
	-- RETURN
	--============================================================

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
