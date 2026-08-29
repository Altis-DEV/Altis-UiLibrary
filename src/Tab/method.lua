-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/method.lua

local Methods = {}

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
-- SCROLL UPDATE
--==============================================================

function Methods.UpdateScroll(Data)
	local ScrollFrame = Data.ScrollFrame
	local Content = Data.Content

	if not ScrollFrame or not Content then
		return Data
	end

	local ViewportHeight = ScrollFrame.AbsoluteSize.Y
	local ContentHeight = Content.AbsoluteSize.Y

	if ViewportHeight <= 0 then
		return Data
	end

	-- Keep the native Roblox scrollbar accurate.
	ScrollFrame.CanvasSize = UDim2.new(
		0,
		0,
		0,
		math.max(ContentHeight, ViewportHeight)
	)

	-- The native scrollbar automatically scales its thumb
	-- according to CanvasSize / viewport size.
	local CanScroll = ContentHeight > ViewportHeight + 0.5

	ScrollFrame.ScrollBarThickness =
		CanScroll
		and Data.ScrollBarThickness
		or 0

	ScrollFrame.ScrollingEnabled = CanScroll

	return Data
end

--==============================================================
-- VISIBILITY
--==============================================================

function Methods.SetVisible(Data, Visible)
	if Data.ScrollFrame then
		Data.ScrollFrame.Visible = Visible == true
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

	local ParentWindow = Config.ParentWindow

	if ParentWindow
		and ParentWindow.ShowTab then

		ParentWindow:ShowTab(Config)
	end

	return Config
end

--==============================================================
-- DESELECT
--==============================================================

function Methods.Deselect(Data)
	if Data.ScrollFrame then
		Data.ScrollFrame.Visible = false
	end

	return Data
end

--==============================================================
-- SCROLL TO TOP
--==============================================================

function Methods.ScrollToTop(Data)
	if Data.ScrollFrame then
		Data.ScrollFrame.CanvasPosition = Vector2.zero
	end

	return Data
end

--==============================================================
-- SCROLL TO BOTTOM
--==============================================================

function Methods.ScrollToBottom(Data)
	if not Data.ScrollFrame then
		return Data
	end

	local CanvasHeight =
		Data.ScrollFrame.AbsoluteCanvasSize.Y

	local ViewportHeight =
		Data.ScrollFrame.AbsoluteWindowSize.Y

	Data.ScrollFrame.CanvasPosition = Vector2.new(
		0,
		math.max(0, CanvasHeight - ViewportHeight)
	)

	return Data
end

--==============================================================
-- SCROLL POSITION
--==============================================================

function Methods.SetScrollPosition(Data, Position)
	if not Data.ScrollFrame then
		return Data
	end

	local Y

	if typeof(Position) == "Vector2" then
		Y = Position.Y
	else
		Y = tonumber(Position) or 0
	end

	Data.ScrollFrame.CanvasPosition = Vector2.new(
		0,
		math.max(0, Y)
	)

	return Data
end

function Methods.GetScrollPosition(Data)
	if not Data.ScrollFrame then
		return Vector2.zero
	end

	return Data.ScrollFrame.CanvasPosition
end

--==============================================================
-- ATTACH
--==============================================================

function Methods.Attach(Context, Config, Data)
	local ImGui = Context.ImGui
	local WindowConfig = Config.ParentWindow

	--============================================================
	-- BASIC REFERENCES
	--============================================================

	Config.Button = Data.Button
	Config.Content = Data.Content
	Config.ScrollFrame = Data.ScrollFrame
	Config.ParentWindow = WindowConfig

	--============================================================
	-- BASIC METHODS
	--============================================================

	function Config:GetContentSize()
		return Methods.GetContentSize(Data)
	end

	function Config:SetVisible(Visible)
		Methods.SetVisible(Data, Visible)

		return self
	end

	function Config:Select()
		return Methods.Select(
			Context,
			self
		)
	end

	function Config:Deselect()
		Methods.Deselect(Data)

		return self
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
	-- INITIAL STATE
	--============================================================

	Data.ScrollFrame.Visible =
		Config.Visible == true

	Data.Content.Visible = true

	--============================================================
	-- TAB BUTTON
	--============================================================

	Data.Button.Activated:Connect(function()
		if WindowConfig
			and WindowConfig.ShowTab then

			WindowConfig:ShowTab(Config)
		end
	end)

	--============================================================
	-- TAB ANIMATION
	--============================================================

	ImGui:ApplyAnimations(
		Data.Button,
		"Tabs"
	)

	--============================================================
	-- AUTO SCROLL UPDATE
	--============================================================

	local function Update()
		if Data.Destroyed then
			return
		end

		Methods.UpdateScroll(Data)
	end

	Data.Content:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(Update)

	Data.ScrollFrame:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(Update)

	-- Child changes can affect UIListLayout size.
	Data.Content.ChildAdded:Connect(Update)
	Data.Content.ChildRemoved:Connect(Update)

	--============================================================
	-- INITIAL UPDATE
	--============================================================

	task.defer(Update)

	return Config
end

return Methods
