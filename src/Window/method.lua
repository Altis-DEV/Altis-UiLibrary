-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Window/method.lua

local Methods = {}

function Methods.GetHeaderSizeY(Data)
	local Toolbar = Data.ToolBar
	local TitleBar = Data.TitleBar

	local ToolbarY = Toolbar.Visible and Toolbar.AbsoluteSize.Y or 0
	local TitleBarY = TitleBar.Visible and TitleBar.AbsoluteSize.Y or 0

	return ToolbarY + TitleBarY
end

function Methods.UpdateBody(Data)
	local HeaderSizeY = Methods.GetHeaderSizeY(Data)

	Data.Body.Size = UDim2.new(
		1,
		0,
		1,
		-HeaderSizeY
	)

	return Data
end

function Methods.Attach(Context, Config, Data)
	local ImGui = Context.ImGui

	--==============================================================
	-- STATE
	--==============================================================

	Config.Open = Config.Open ~= false
	Data.DragEnabled = Config.NoDrag ~= true
	Data.Destroyed = false

	--==============================================================
	-- CLOSE
	--==============================================================

	function Config:Close()
		if Data.Destroyed then
			return self
		end

		local Callback = self.CloseCallback

		self:SetVisible(false)

		if Callback then
			Callback(self)
		end

		return self
	end

	--==============================================================
	-- REMOVE
	--==============================================================

	function Config:Remove()
		if Data.Destroyed then
			return self
		end

		Data.Destroyed = true

		if ImGui.Windows[Data.Window] then
			ImGui.Windows[Data.Window] = nil
		end

		Data.Window:Destroy()

		return self
	end

	--==============================================================
	-- VISIBLE
	--==============================================================

	function Config:SetVisible(Visible)
		if Data.Destroyed then
			return self
		end

		Data.Window.Visible = Visible == true

		return self
	end

	--==============================================================
	-- TITLE
	--==============================================================

	function Config:SetTitle(Text)
		if Data.Destroyed then
			return self
		end

		Data.TitleBar.Left.Title.Text = tostring(Text)

		return self
	end

	--==============================================================
	-- POSITION
	--==============================================================

	function Config:SetPosition(Position)
		if Data.Destroyed then
			return self
		end

		Data.Window.Position = Position

		return self
	end

	--==============================================================
	-- SIZE
	--==============================================================

	function Config:SetSize(Size)
		if Data.Destroyed then
			return self
		end

		if typeof(Size) == "Vector2" then
			Size = UDim2.fromOffset(Size.X, Size.Y)
		end

		if typeof(Size) ~= "UDim2" then
			return self
		end

		local HeaderSizeY = Methods.GetHeaderSizeY(Data)

		local NewSize = UDim2.new(
			Size.X.Scale,
			Size.X.Offset,
			Size.Y.Scale,
			Size.Y.Offset + HeaderSizeY
		)

		self.Size = NewSize
		Data.Window.Size = NewSize

		return self
	end

	--==============================================================
	-- OPEN / CLOSE
	--==============================================================

	function Config:SetOpen(Open, NoAnimation)
		if Data.Destroyed then
			return self
		end

		Open = Open == true
		self.Open = Open

		local WindowSize = Data.Window.AbsoluteSize
		local TitleBarSize = Data.TitleBar.AbsoluteSize

		ImGui:HeaderAnimate(
			Data.TitleBar,
			true,
			Open,
			Data.TitleBar,
			Data.Toggle.ToggleButton
		)

		ImGui:Tween(
			Data.Resize,
			{
				TextTransparency = Open and 0.6 or 1,
				Interactable = Open
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Data.Window,
			{
				Size = Open
					and self.Size
					or UDim2.fromOffset(
						WindowSize.X,
						TitleBarSize.Y
					)
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Data.Body,
			{
				Visible = Open
			},
			nil,
			NoAnimation
		)

		return self
	end

	--==============================================================
	-- TAB
	--==============================================================

	function Config:CreateTab(TabConfig)
		TabConfig = TabConfig or {}

		assert(
			Context.Load,
			"ImGui Window: Context.Load is missing"
		)

		local TabModule = Context.Load(
			"src/Tab/init.lua"
		)

		return TabModule.new(
			Context,
			self,
			Data,
			TabConfig
		)
	end

	--==============================================================
	-- SHOW TAB
	--==============================================================

	function Config:ShowTab(TabClass)
		if Data.Destroyed then
			return self
		end

		if not TabClass or not TabClass.Content then
			return self
		end

		local TargetPage = TabClass.Content

		if not TargetPage.Visible
			and not TabClass.NoAnimation then

			TargetPage.Position = UDim2.fromOffset(0, 5)
		end

		for _, Page in next, Data.Body:GetChildren() do
			if Page:IsA("GuiObject") then
				Page.Visible = Page == TargetPage
			end
		end

		ImGui:Tween(
			TargetPage,
			{
				Position = UDim2.fromOffset(0, 0)
			}
		)

		return self
	end

	--==============================================================
	-- CENTER
	--==============================================================

	function Config:Center()
		if Data.Destroyed then
			return self
		end

		local Size = Data.Window.AbsoluteSize

		self:SetPosition(
			UDim2.new(
				0.5,
				-Size.X / 2,
				0.5,
				-Size.Y / 2
			)
		)

		return self
	end

	--==============================================================
	-- WINDOW PROPERTIES
	--==============================================================

	function Config:SetProperties(Properties)
		if Data.Destroyed then
			return self
		end

		for Key, Value in next, Properties or {} do
			pcall(function()
				Data.Window[Key] = Value
			end)
		end

		return self
	end

	--==============================================================
	-- DRAG CONTROL
	--==============================================================

	function Config:SetDragEnabled(Enabled)
		Data.DragEnabled = Enabled == true

		return self
	end

	function Config:IsDragEnabled()
		return Data.DragEnabled
	end

	--==============================================================
	-- INTERACTION REGISTRATION
	--
	-- Controls such as Slider, TextBox and ResizeGrab can register
	-- themselves here. A touch beginning on a registered object will
	-- not begin a Window drag.
	--==============================================================

	function Config:RegisterInteraction(GuiObject)
		if Data.Destroyed then
			return self
		end

		Data:RegisterInteraction(GuiObject)

		return self
	end

	--==============================================================
	-- CLOSE BUTTON
	--==============================================================

	local CloseButton = Data.TitleBar.Close

	CloseButton.Visible = Config.NoClose ~= true

	Data:RegisterInteraction(CloseButton)

	CloseButton.Activated:Connect(function()
		Config:Close()
	end)

	--==============================================================
	-- COLLAPSE BUTTON
	--==============================================================

	Data.Toggle.ToggleButton.Activated:Connect(function()
		local Open = not Config.Open

		Config:SetOpen(Open)
	end)

	--==============================================================
	-- SELECT EFFECT
	--==============================================================

	if not Config.NoSelectEffect then
		ImGui:ApplyWindowSelectEffect(
			Data.Window,
			Data.TitleBar
		)
	end

	return Config
end

return Methods
