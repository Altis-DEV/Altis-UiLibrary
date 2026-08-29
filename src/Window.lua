local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Window = {}
Window.__index = Window

local TOPBAR_HEIGHT = 30
local TABBAR_HEIGHT = 25
local BUTTON_SIZE = 25
local RESIZE_SIZE = 25
local MIN_SIZE = Vector2.new(200, 120)

local CLOSE_IMAGE = "rbxassetid://127173792845658"
local TOGGLE_TEXT = "▼"
local RESIZE_TEXT = "◢"

local function make(className, props, parent)
    local object = Instance.new(className)

    for key, value in pairs(props or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function getTheme(themes, name)
    name = name or "Default"

    local theme = themes and themes[name]
    if type(theme) ~= "table" then
        theme = themes and themes.Default
    end

    assert(type(theme) == "table", "Window: Default theme was not found")
    return theme, name
end

local function alignment(value)
    if value == "Center" then
        return Enum.TextXAlignment.Center
    elseif value == "Right" then
        return Enum.TextXAlignment.Right
    end

    return Enum.TextXAlignment.Left
end

function Window.CreateWindow(themes, config)
    config = config or {}

    local theme, themeName = getTheme(themes, config.Theme)
    local size = typeof(config.Size) == "UDim2" and config.Size or UDim2.fromOffset(500, 350)

    local self = setmetatable({}, Window)

    self.ThemeName = themeName
    self.Theme = theme
    self._destroyed = false
    self._open = true
    self._openSize = size
    self._dragInput = nil
    self._dragging = false
    self._dragStart = nil
    self._startPosition = nil
    self._resizeInput = nil
    self._resizing = false
    self._resizeStart = nil
    self._startSize = nil

    self.NoToggleState = config.NoToggle == true
    self.NoCloseState = config.NoClose == true
    self.NoTabbarState = config.NoTabbar == true
    self.NoResizeState = config.NoResize == true
    self.NoTopbarState = config.NoTopbar == true

    local gui = CoreGui:FindFirstChild("imgui")
    if not gui then
        gui = make("ScreenGui", {
            Name = "imgui",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, CoreGui)
    end

    self.Gui = gui

    self.Instance = make("ImageLabel", {
        Name = "Window",
        Size = size,
        Position = UDim2.fromOffset(100, 100),
        BackgroundTransparency = 1,
        Image = "rbxassetid://2851926732",
        ImageColor3 = theme.Background,
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 0.1,
        SliceCenter = Rect.new(12, 12, 12, 12),
        Active = true,
        ClipsDescendants = true,
    }, gui)

    self.Topbar = make("Frame", {
        Name = "Topbar",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        BackgroundColor3 = theme.Topbar,
        BorderSizePixel = 0,
        Active = true,
    }, self.Instance)

    self.ToggleButton = make("TextButton", {
        Name = "ToggleButton",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = TOGGLE_TEXT,
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = BUTTON_SIZE,
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
    }, self.Topbar)

    self.CloseButton = make("ImageButton", {
        Name = "CloseButton",
        Position = UDim2.new(1, -BUTTON_SIZE, 0, 0),
        Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = CLOSE_IMAGE,
        ImageColor3 = theme.Text,
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
    }, self.Topbar)

    self.TitleFrame = make("Frame", {
        Name = "TitleFrame",
        Position = UDim2.fromOffset(BUTTON_SIZE, 0),
        Size = UDim2.new(1, -(BUTTON_SIZE * 2), 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, self.Topbar)

    self.Title = make("TextLabel", {
        Name = "Title",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(config.Title or "Window"),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = alignment(config.TextAlignment),
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, self.TitleFrame)

    self.TabBar = make("ImageLabel", {
        Name = "TabBar",
        Position = UDim2.fromOffset(5, TOPBAR_HEIGHT),
        Size = UDim2.new(1, -10, 0, TABBAR_HEIGHT),
        BackgroundTransparency = 1,
        Image = "rbxassetid://2851929490",
        ImageColor3 = theme.TabContainer,
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 0.1,
        SliceCenter = Rect.new(4, 4, 4, 4),
    }, self.Instance)

    self.TabButtons = make("ScrollingFrame", {
        Name = "TabButtons",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 0,
        ScrollingEnabled = true,
        Active = true,
    }, self.TabBar)

    self.TabLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, self.TabButtons)

    self.Background = make("Frame", {
        Name = "Background",
        Position = UDim2.fromOffset(5, TOPBAR_HEIGHT + TABBAR_HEIGHT),
        Size = UDim2.new(1, -10, 1, -(TOPBAR_HEIGHT + TABBAR_HEIGHT) - 5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, self.Instance)

    self.ResizeCorner = make("TextButton", {
        Name = "ResizeCorner",
        Position = UDim2.new(1, -RESIZE_SIZE, 1, -RESIZE_SIZE),
        Size = UDim2.fromOffset(RESIZE_SIZE, RESIZE_SIZE),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = RESIZE_TEXT,
        TextColor3 = theme.ResizeCorner,
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
    }, self.Background)

    self:_updateLayout()
    self:_connectInteractions()

    return self
end

function Window:_updateLayout()
    if self._destroyed then
        return
    end

    local topbarHeight = self.NoTopbarState and 0 or TOPBAR_HEIGHT
    local tabbarHeight = self.NoTabbarState and 0 or TABBAR_HEIGHT

    self.Topbar.Visible = not self.NoTopbarState
    self.TabBar.Visible = not self.NoTabbarState
    self.ToggleButton.Visible = not self.NoToggleState
    self.CloseButton.Visible = not self.NoCloseState
    self.ResizeCorner.Visible = not self.NoResizeState

    self.TabBar.Position = UDim2.fromOffset(5, topbarHeight)
    self.TabBar.Size = UDim2.new(1, -10, 0, tabbarHeight)

    self.Background.Position = UDim2.fromOffset(5, topbarHeight + tabbarHeight)
    self.Background.Size = UDim2.new(1, -10, 1, -(topbarHeight + tabbarHeight) - 5)

    self.ResizeCorner.Position = UDim2.new(1, -RESIZE_SIZE, 1, -RESIZE_SIZE)
end

function Window:_connectInteractions()
    self.ToggleButton.Activated:Connect(function()
        self:Toggle()
    end)

    self.CloseButton.Activated:Connect(function()
        self:Destroy()
    end)

    self.Topbar.InputBegan:Connect(function(input)
        if self._destroyed or self._resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        self._dragInput = input
        self._dragging = true
        self._dragStart = input.Position
        self._startPosition = self.Instance.Position
    end)

    self.Topbar.InputEnded:Connect(function(input)
        if input == self._dragInput then
            self._dragInput = nil
            self._dragging = false
        end
    end)

    self.ResizeCorner.InputBegan:Connect(function(input)
        if self._destroyed or self._dragging or self.NoResizeState then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        self._resizeInput = input
        self._resizing = true
        self._resizeStart = input.Position
        self._startSize = self.Instance.AbsoluteSize
    end)

    self.ResizeCorner.InputEnded:Connect(function(input)
        if input == self._resizeInput then
            self._resizeInput = nil
            self._resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if self._destroyed then
            return
        end

        if self._dragging then
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            if self._dragInput
                and input.UserInputType == Enum.UserInputType.Touch
                and input ~= self._dragInput then
                return
            end

            local delta = input.Position - self._dragStart

            self.Instance.Position = UDim2.new(
                self._startPosition.X.Scale,
                self._startPosition.X.Offset + delta.X,
                self._startPosition.Y.Scale,
                self._startPosition.Y.Offset + delta.Y
            )
        elseif self._resizing then
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            if self._resizeInput
                and input.UserInputType == Enum.UserInputType.Touch
                and input ~= self._resizeInput then
                return
            end

            local delta = input.Position - self._resizeStart
            local width = math.max(MIN_SIZE.X, self._startSize.X + delta.X)
            local height = math.max(MIN_SIZE.Y, self._startSize.Y + delta.Y)

            self.Instance.Size = UDim2.fromOffset(width, height)
            self._openSize = self.Instance.Size
        end
    end)
end

function Window:Close()
    if self._destroyed then return end
    self._openSize = self.Instance.Size
    self.Instance.Size = UDim2.new(self._openSize.X, 0, 0, TOPBAR_HEIGHT)
    self._open = false
    self.ToggleButton.Rotation = -90
end

function Window:Open()
    if self._destroyed then return end
    self.Instance.Size = self._openSize
    self._open = true
    self.ToggleButton.Rotation = 0
end

function Window:Toggle()
    if self._destroyed then return end
    if self._open then
        self:Close()
    else
        self:Open()
    end
end

function Window:SetTitle(title)
    if self._destroyed then return end
    self.Title.Text = tostring(title)
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self._dragging = false
    self._resizing = false
    self._dragInput = nil
    self._resizeInput = nil
    self.Instance:Destroy()
end

function Window:NoToggle(value)
    if value == nil then
        self.NoToggleState = not self.NoToggleState
    else
        self.NoToggleState = value == true
    end
    self.ToggleButton.Visible = not self.NoToggleState
end

function Window:NoClose(value)
    if value == nil then
        self.NoCloseState = not self.NoCloseState
    else
        self.NoCloseState = value == true
    end
    self.CloseButton.Visible = not self.NoCloseState
end

function Window:NoTabbar(value)
    if value == nil then
        self.NoTabbarState = not self.NoTabbarState
    else
        self.NoTabbarState = value == true
    end
    self:_updateLayout()
end

function Window:NoResize(value)
    if value == nil then
        self.NoResizeState = not self.NoResizeState
    else
        self.NoResizeState = value == true
    end
    self.ResizeCorner.Visible = not self.NoResizeState
end

function Window:NoTopbar(value)
    if value == nil then
        self.NoTopbarState = not self.NoTopbarState
    else
        self.NoTopbarState = value == true
    end
    self:_updateLayout()
end

function Window:SetTheme(name, themes)
    local theme, themeName = getTheme(themes, name)

    self.ThemeName = themeName
    self.Theme = theme

    self.Instance.ImageColor3 = theme.Background
    self.Topbar.BackgroundColor3 = theme.Topbar
    self.TabBar.ImageColor3 = theme.TabContainer
    self.ToggleButton.TextColor3 = theme.Text
    self.CloseButton.ImageColor3 = theme.Text
    self.Title.TextColor3 = theme.Text
    self.ResizeCorner.TextColor3 = theme.ResizeCorner
end

return Window
