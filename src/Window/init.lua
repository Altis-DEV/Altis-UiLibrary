-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/src/Window/init.lua

local Window = {}

function Window.new(Context, WindowConfig)
	assert(Context, "Window.new: Context is required")
	assert(Context.ImGui, "Window.new: Context.ImGui is required")
	assert(Context.Core, "Window.new: Context.Core is required")
	assert(Context.Prefabs, "Window.new: Context.Prefabs is required")

	WindowConfig = WindowConfig or {}

	local ImGui = Context.ImGui
	local Core = Context.Core
	local Prefabs = Context.Prefabs
	local UIS = Core.Services.UserInputService

	assert(
		Context.Load,
		"ImGui Window: Context.Load is missing"
	)

	local Methods = Context.Load(
		"src/Window/method.lua"
	)

	--==============================================================
	-- CREATE WINDOW
	--==============================================================

	local Frame: Frame = Prefabs.Window:Clone()

	Frame.Parent = ImGui.ScreenGui
	Frame.Visible = true

	WindowConfig.Window = Frame

	local Content = Frame.Content
	local Body = Content.Body

	local TitleBar = Content.TitleBar
	local ToolBar = Content.ToolBar
	local Toggle = TitleBar.Left.Toggle

	--==============================================================
	-- WINDOW STATE
	--==============================================================

	local Data = {
		Context = Context,
		ImGui = ImGui,
		Core = Core,

		Window = Frame,
		Content = Content,
		Body = Body,

		TitleBar = TitleBar,
		ToolBar = ToolBar,
		Toggle = Toggle,

		Resize = Frame.ResizeGrab,

		Interactions = {},

		Dragging = false,
		Resizing = false,

		ActiveDragInput = nil,
		ActiveResizeInput = nil,

		DragStart = nil,
		DragStartPosition = nil,

		ResizeStart = nil,
		ResizeStartSize = nil,

		Destroyed = false,
		DragEnabled = WindowConfig.NoDrag ~= true,
	}

	WindowConfig.__WindowData = Data

	--==============================================================
	-- POINT HIT TEST
	--==============================================================

	function Data:IsPointInside(GuiObject, Position)
		if not GuiObject then
			return false
		end

		if not GuiObject.Visible then
			return false
		end

		local ObjectPosition = GuiObject.AbsolutePosition
		local ObjectSize = GuiObject.AbsoluteSize

		return Position.X >= ObjectPosition.X
			and Position.X <= ObjectPosition.X + ObjectSize.X
			and Position.Y >= ObjectPosition.Y
			and Position.Y <= ObjectPosition.Y + ObjectSize.Y
	end

	--==============================================================
	-- INTERACTION REGISTRATION
	--==============================================================

	function Data:RegisterInteraction(GuiObject)
		if not GuiObject then
			return GuiObject
		end

		if table.find(self.Interactions, GuiObject) then
			return GuiObject
		end

		table.insert(self.Interactions, GuiObject)

		return GuiObject
	end

	function Data:IsInteractionPoint(Position)
		for Index = #self.Interactions, 1, -1 do
			local GuiObject = self.Interactions[Index]

			if not GuiObject
				or not GuiObject.Parent then

				table.remove(self.Interactions, Index)
				continue
			end

			if self:IsPointInside(GuiObject, Position) then
				return true
			end
		end

		return false
	end

	--==============================================================
	-- DRAG
	--==============================================================

	function Data:BeginDrag(Input)
		if self.Destroyed then
			return
		end

		if not self.DragEnabled then
			return
		end

		if self.Dragging or self.Resizing then
			return
		end

		self.Dragging = true
		self.ActiveDragInput = Input

		self.DragStart = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		self.DragStartPosition = self.Window.Position
	end

	function Data:UpdateDrag(Position)
		if not self.Dragging then
			return
		end

		if not self.DragStart
			or not self.DragStartPosition then
			return
		end

		local CurrentPosition = Vector2.new(
			Position.X,
			Position.Y
		)

		local Delta = CurrentPosition - self.DragStart

		self.Window.Position = UDim2.new(
			self.DragStartPosition.X.Scale,
			self.DragStartPosition.X.Offset + Delta.X,

			self.DragStartPosition.Y.Scale,
			self.DragStartPosition.Y.Offset + Delta.Y
		)
	end

	function Data:EndDrag(Input)
		if not self.Dragging then
			return
		end

		if Input and Input ~= self.ActiveDragInput then
			return
		end

		self.Dragging = false
		self.ActiveDragInput = nil

		self.DragStart = nil
		self.DragStartPosition = nil
	end

	--==============================================================
	-- RESIZE
	--==============================================================

	local MinSize =
		WindowConfig.MinSize
		or Vector2.new(160, 90)

	function Data:BeginResize(Input)
		if self.Destroyed then
			return
		end

		if self.Resizing or self.Dragging then
			return
		end

		self.Resizing = true
		self.ActiveResizeInput = Input

		self.ResizeStart = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		self.ResizeStartSize = self.Window.AbsoluteSize
	end

	function Data:UpdateResize(Position)
		if not self.Resizing then
			return
		end

		if not self.ResizeStart
			or not self.ResizeStartSize then
			return
		end

		local CurrentPosition = Vector2.new(
			Position.X,
			Position.Y
		)

		local Delta = CurrentPosition - self.ResizeStart

		local NewSize = UDim2.fromOffset(
			math.max(
				MinSize.X,
				self.ResizeStartSize.X + Delta.X
			),

			math.max(
				MinSize.Y,
				self.ResizeStartSize.Y + Delta.Y
			)
		)

		self.Window.Size = NewSize

		WindowConfig.Size = NewSize
	end

	function Data:EndResize(Input)
		if not self.Resizing then
			return
		end

		if Input and Input ~= self.ActiveResizeInput then
			return
		end

		self.Resizing = false
		self.ActiveResizeInput = nil

		self.ResizeStart = nil
		self.ResizeStartSize = nil
	end

	--==============================================================
	-- WINDOW CONFIGURATION
	--==============================================================

	TitleBar.Visible =
		WindowConfig.NoTitleBar ~= true

	ToolBar.Visible =
		WindowConfig.TabsBar ~= false

	Toggle.Visible =
		WindowConfig.NoCollapse ~= true

	Data.Resize.Visible =
		WindowConfig.NoResize ~= true

	-- Resize has priority over Window drag.
	Data:RegisterInteraction(Data.Resize)

	--==============================================================
	-- RESIZE INPUT
	--==============================================================

	Data.Resize.InputBegan:Connect(function(Input)
		local InputType = Input.UserInputType

		if InputType ~= Enum.UserInputType.MouseButton1
			and InputType ~= Enum.UserInputType.Touch then
			return
		end

		Data:BeginResize(Input)
	end)

	--==============================================================
	-- GLOBAL INPUT
	--
	-- PC:
	--   Window drag starts only on TitleBar.
	--
	-- MOBILE:
	--   Window drag can start anywhere inside Window.
	--
	-- Input is captured through UserInputService because a touch
	-- beginning on a child GuiObject does not reliably bubble to
	-- Window.InputBegan.
	--==============================================================

	UIS.InputBegan:Connect(function(Input)
		if Data.Destroyed then
			return
		end

		local InputType = Input.UserInputType

		if InputType ~= Enum.UserInputType.MouseButton1
			and InputType ~= Enum.UserInputType.Touch then
			return
		end

		local Position = Vector2.new(
			Input.Position.X,
			Input.Position.Y
		)

		-- Outside Window.
		if not Data:IsPointInside(Frame, Position) then
			return
		end

		-- Resize gets priority.
		if Data:IsPointInside(Data.Resize, Position) then
			return
		end

		-- Registered controls get priority.
		if Data:IsInteractionPoint(Position) then
			return
		end

		if not Data.DragEnabled then
			return
		end

		-- Mobile: any unregistered point inside Window.
		if InputType == Enum.UserInputType.Touch then
			Data:BeginDrag(Input)
			return
		end

		-- PC: only TitleBar.
		if Data:IsPointInside(TitleBar, Position) then
			Data:BeginDrag(Input)
		end
	end)

	--==============================================================
	-- GLOBAL INPUT CHANGED
	--==============================================================

	UIS.InputChanged:Connect(function(Input)
		if Data.Destroyed then
			return
		end

		if Data.Dragging then
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				Data:UpdateDrag(Input.Position)
				return
			end

			if Input.UserInputType == Enum.UserInputType.Touch
				and Input == Data.ActiveDragInput then

				Data:UpdateDrag(Input.Position)
				return
			end
		end

		if Data.Resizing then
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				Data:UpdateResize(Input.Position)
				return
			end

			if Input.UserInputType == Enum.UserInputType.Touch
				and Input == Data.ActiveResizeInput then

				Data:UpdateResize(Input.Position)
				return
			end
		end
	end)

	--==============================================================
	-- GLOBAL INPUT ENDED
	--==============================================================

	UIS.InputEnded:Connect(function(Input)
		if Data.Destroyed then
			return
		end

		if Input == Data.ActiveDragInput then
			Data:EndDrag(Input)
		end

		if Input == Data.ActiveResizeInput then
			Data:EndResize(Input)
		end
	end)

	--==============================================================
	-- ANIMATION
	--==============================================================

	ImGui:ApplyAnimations(
		Toggle.ToggleButton,
		"Tabs"
	)

	--==============================================================
	-- BODY SIZE
	--==============================================================

	WindowConfig.GetHeaderSizeY = function()
		return Methods.GetHeaderSizeY(Data)
	end

	WindowConfig.UpdateBody = function()
		return Methods.UpdateBody(Data)
	end

	WindowConfig.UpdateBody()

	--==============================================================
	-- METHODS
	--==============================================================

	Methods.Attach(
		Context,
		WindowConfig,
		Data
	)

	--==============================================================
	-- DEFAULT STATE
	--==============================================================

	WindowConfig:SetTitle(
		WindowConfig.Title or "Depso UI"
	)

	if WindowConfig.Open == false then
		WindowConfig:SetOpen(false, true)
	else
		WindowConfig.Open = true
	end

	--==============================================================
	-- STYLE
	--==============================================================

	ImGui:CheckStyles(
		Frame,
		WindowConfig,
		WindowConfig.Colors
	)

	--==============================================================
	-- REGISTER WINDOW
	--==============================================================

	ImGui.Windows[Frame] = WindowConfig

	--==============================================================
	-- RETURN
	--==============================================================

	return ImGui:MergeMetatables(
		WindowConfig,
		Frame
	)
end

return Window
