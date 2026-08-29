-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Window/method.lua

local Methods = {}

--==============================================================
-- HEADER SIZE
--==============================================================

function Methods.GetHeaderSizeY(Data)
	local ToolBar = Data.ToolBar
	local TitleBar = Data.TitleBar

	local ToolbarY =
		ToolBar.Visible
		and ToolBar.AbsoluteSize.Y
		or 0

	local TitlebarY =
		TitleBar.Visible
		and TitleBar.AbsoluteSize.Y
		or 0

	return ToolbarY + TitlebarY
end

--==============================================================
-- BODY SIZE
--==============================================================

function Methods.UpdateBody(Data)
	local HeaderSizeY =
		Methods.GetHeaderSizeY(Data)

	Data.Body.Size =
		UDim2.new(
			1,
			0,
			1,
			-HeaderSizeY
		)

	return Data
end

--==============================================================
-- ATTACH
--==============================================================

function Methods.Attach(Context, Config, Data)
	local ImGui = Context.ImGui

	Config.Open =
		Config.Open ~= false

	Data.DragEnabled =
		Config.NoDrag ~= true

	Data.Destroyed = false

	Data.Tabs =
		Data.Tabs or {}

	--============================================================
	-- CLOSE
	--============================================================

	function Config:Close()
		if Data.Destroyed then
			return self
		end

		local Callback =
			self.CloseCallback

		self:SetVisible(false)

		if Callback then
			Callback(self)
		end

		return self
	end

	--============================================================
	-- REMOVE
	--============================================================

	function Config:Remove()
		if Data.Destroyed then
			return self
		end

		Data.Destroyed = true

		ImGui.Windows[Data.Window] = nil

		Data.Window:Destroy()

		return self
	end

	--============================================================
	-- VISIBLE
	--============================================================

	function Config:SetVisible(Visible)
		if Data.Destroyed then
			return self
		end

		Data.Window.Visible =
			Visible == true

		return self
	end

	--============================================================
	-- TITLE
	--============================================================

	function Config:SetTitle(Text)
		if Data.Destroyed then
			return self
		end

		Data.TitleBar.Left.Title.Text =
			tostring(Text)

		return self
	end

	--============================================================
	-- POSITION
	--============================================================

	function Config:SetPosition(Position)
		if Data.Destroyed then
			return self
		end

		Data.Window.Position =
			Position

		return self
	end

	--============================================================
	-- SIZE
	--============================================================

	function Config:SetSize(Size)
		if Data.Destroyed then
			return self
		end

		if typeof(Size) == "Vector2" then
			Size =
				UDim2.fromOffset(
					Size.X,
					Size.Y
				)
		end

		if typeof(Size) ~= "UDim2" then
			return self
		end

		local HeaderSizeY =
			Methods.GetHeaderSizeY(Data)

		local NewSize =
			UDim2.new(
				Size.X.Scale,
				Size.X.Offset,

				Size.Y.Scale,
				Size.Y.Offset + HeaderSizeY
			)

		self.Size = NewSize
		Data.Window.Size = NewSize

		return self
	end

	--============================================================
	-- OPEN / CLOSE
	--============================================================

	function Config:SetOpen(Open, NoAnimation)
		if Data.Destroyed then
			return self
		end

		Open = Open == true
		self.Open = Open

		local WindowSize =
			Data.Window.AbsoluteSize

		local TitleBarSize =
			Data.TitleBar.AbsoluteSize

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
				TextTransparency =
					Open and 0.6 or 1,

				Interactable =
					Open,
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Data.Window,
			{
				Size =
					Open
					and self.Size
					or UDim2.fromOffset(
						WindowSize.X,
						TitleBarSize.Y
					),
			},
			nil,
			NoAnimation
		)

		ImGui:Tween(
			Data.Body,
			{
				Visible = Open,
			},
			nil,
			NoAnimation
		)

		return self
	end

	--============================================================
	-- CREATE TAB
	--============================================================

	function Config:CreateTab(TabConfig)
		local TabModule =
			Context.Load(
				"src/Tab/init.lua"
			)

		return TabModule.new(
			Context,
			self,
			Data,
			TabConfig or {}
		)
	end

	--============================================================
	-- SHOW TAB
	--============================================================

	function Config:ShowTab(TabConfig)
		if Data.Destroyed then
			return self
		end

		if not TabConfig then
			return self
		end

		local TargetData =
			TabConfig.__TabData

		if not TargetData then
			return self
		end

		--========================================================
		-- DEACTIVATE EVERY OTHER TAB
		--========================================================

		for _, OtherConfig in next, Data.Tabs do
			local OtherData =
				OtherConfig.__TabData

			if OtherData
				and OtherData ~= TargetData then

				OtherData.Active = false
				OtherData.Content.Visible = false
			end
		end

		--========================================================
		-- ACTIVATE TARGET
		--========================================================

		TargetData.Active = true
		TargetData.Content.Visible = true

		--========================================================
		-- RESET SCROLL
		--========================================================

		Data.Body.CanvasPosition =
			Vector2.zero

		--========================================================
		-- POSITION
		--========================================================

		TargetData.Content.Position =
			UDim2.fromOffset(0, 5)

		--========================================================
		-- ANIMATION
		--========================================================

		if not TabConfig.NoAnimation then
			ImGui:Tween(
				TargetData.Content,
				{
					Position =
						UDim2.fromOffset(0, 0),
				}
			)
		else
			TargetData.Content.Position =
				UDim2.fromOffset(0, 0)
		end

		--========================================================
		-- UPDATE SCROLL
		--========================================================

		local TabMethod =
			Context.Load(
				"src/Tab/method.lua"
			)

		TabMethod.UpdateScroll(
			TargetData
		)

		--========================================================
		-- KEEP ACTIVE TAB REACHABLE
		--========================================================

		self.ActiveTab =
			TabConfig

		return self
	end

	--============================================================
	-- CENTER
	--============================================================

	function Config:Center()
		if Data.Destroyed then
			return self
		end

		local Size =
			Data.Window.AbsoluteSize

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

	--============================================================
	-- PROPERTIES
	--============================================================

	function Config:SetProperties(Properties)
		if Data.Destroyed then
			return self
		end

		for Key, Value in next,
			Properties or {} do

			pcall(function()
				Data.Window[Key] =
					Value
			end)
		end

		return self
	end

	--============================================================
	-- DRAG
	--============================================================

	function Config:SetDragEnabled(Enabled)
		Data.DragEnabled =
			Enabled == true

		return self
	end

	function Config:IsDragEnabled()
		return Data.DragEnabled
	end

	--============================================================
	-- INTERACTION
	--============================================================

	function Config:RegisterInteraction(GuiObject)
		if Data.Destroyed then
			return self
		end

		Data:RegisterInteraction(
			GuiObject
		)

		return self
	end

	function Config:UnregisterInteraction(GuiObject)
		if not GuiObject then
			return self
		end

		for Index =
			#Data.Interactions,
			1,
			-1 do

			if Data.Interactions[Index]
				== GuiObject then

				table.remove(
					Data.Interactions,
					Index
				)
			end
		end

		return self
	end

	--============================================================
	-- CLOSE BUTTON
	--============================================================

	local CloseButton =
		Data.TitleBar.Close

	CloseButton.Visible =
		Config.NoClose ~= true

	Data:RegisterInteraction(
		CloseButton
	)

	CloseButton.Activated:Connect(
		function()
			Config:Close()
		end
	)

	--============================================================
	-- COLLAPSE
	--============================================================

	Data.Toggle.ToggleButton.Activated:Connect(
		function()
			Config:SetOpen(
				not Config.Open
			)
		end
	)

	--============================================================
	-- SELECT EFFECT
	--============================================================

	if not Config.NoSelectEffect then
		ImGui:ApplyWindowSelectEffect(
			Data.Window,
			Data.TitleBar
		)
	end

	return Config
end

return Methods
