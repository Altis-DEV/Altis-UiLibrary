-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Tab/method.lua

local Methods = {}

--==============================================================
-- CONTENT / SCROLL
--==============================================================

function Methods.GetContentSize(Data)
	if not Data.Content then
		return Vector2.zero
	end

	return Data.Content.AbsoluteSize
end

function Methods.UpdateScroll(Data)
	local ScrollBox = Data.ScrollBox
	local Content = Data.Content

	if not ScrollBox or not Content then
		return
	end

	local ViewportHeight = ScrollBox.AbsoluteSize.Y
	local ContentHeight = Content.AbsoluteSize.Y

	if ViewportHeight <= 0 then
		return
	end

	-- The content itself determines the canvas height.
	ScrollBox.CanvasSize = UDim2.new(
		0,
		0,
		0,
		math.max(ContentHeight, ViewportHeight)
	)

	-- Hide the scrollbar when there is nothing to scroll.
	if ContentHeight > ViewportHeight + 1 then
		ScrollBox.ScrollingEnabled = true
		ScrollBox.ScrollBarThickness = Data.ScrollBarThickness
	else
		ScrollBox.ScrollingEnabled = false
		ScrollBox.ScrollBarThickness = 0
	end
end

--==============================================================
-- VISIBILITY
--==============================================================

function Methods.SetVisible(Data, Visible)
	if Data.ScrollBox then
		Data.ScrollBox.Visible = Visible == true
	end

	return Data
end

--==============================================================
-- SELECTION
--==============================================================

function Methods.Select(Context, Config)
	if not Config then
		return Config
	end

	local ParentWindow = Config.ParentWindow

	if ParentWindow and ParentWindow.ShowTab then
		ParentWindow:ShowTab(Config)
	end

	return Config
end

function Methods.Deselect(Data)
	if Data.ScrollBox then
		Data.ScrollBox.Visible = false
	end

	return Data
end

--==============================================================
-- SCROLL CONTROL
--==============================================================

function Methods.ScrollToTop(Data)
	if Data.ScrollBox then
		Data.ScrollBox.CanvasPosition = Vector2.zero
	end

	return Data
end

function Methods.ScrollToBottom(Data)
	local ScrollBox = Data.ScrollBox

	if not ScrollBox then
		return Data
	end

	local CanvasHeight = ScrollBox.AbsoluteCanvasSize.Y
	local ViewportHeight = ScrollBox.AbsoluteWindowSize.Y

	ScrollBox.CanvasPosition = Vector2.new(
		0,
		math.max(0, CanvasHeight - ViewportHeight)
	)

	return Data
end

function Methods.SetScrollPosition(Data, Position)
	local ScrollBox = Data.ScrollBox

	if not ScrollBox then
		return Data
	end

	local Y

	if typeof(Position) == "Vector2" then
		Y = Position.Y
	else
		Y = tonumber(Position) or 0
	end

	ScrollBox.CanvasPosition = Vector2.new(
		0,
		math.max(0, Y)
	)

	return Data
end

function Methods.GetScrollPosition(Data)
	if not Data.ScrollBox then
		return Vector2.zero
	end

	return Data.ScrollBox.CanvasPosition
end

--==============================================================
-- ATTACH METHODS
--==============================================================

function Methods.Attach(Context, Config, Data)
	local ImGui = Context.ImGui

	--============================================================
	-- REFERENCES
	--============================================================

	Config.Button = Data.Button
	Config.Content = Data.Content
	Config.ScrollBox = Data.ScrollBox
	Config.ParentWindow = Data.ParentWindowConfig

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
		Methods.SetVisible(Data, Visible)

		return self
	end

	--============================================================
	-- SELECTION
	--============================================================

	function Config:Select()
		return Methods.Select(Context, self)
	end

	function Config:Deselect()
		Methods.Deselect(Data)

		return self
	end

	--============================================================
	-- SCROLL
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
		if Data.ParentWindowConfig
			and Data.ParentWindowConfig.ShowTab then

			Data.ParentWindowConfig:ShowTab(self)
		end
	end)

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

	Data.ScrollBox:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(Update)

	Data.Content.ChildAdded:Connect(Update)
	Data.Content.ChildRemoved:Connect(Update)

	task.defer(Update)

	return Config
end

return Methods
