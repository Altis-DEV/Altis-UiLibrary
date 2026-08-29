--[[
    ReGui Rework
    Window.lua

    Expected Theme structure:

    Theme.Default = {
        Text = Color3,
        Topbar = Color3,
        TabContainer = Color3,
        Background = Color3,
        ResizeCorner = Color3,
    }

    Theme.Light = {
        Text = Color3,
        Topbar = Color3,
        TabContainer = Color3,
        Background = Color3,
        ResizeCorner = Color3,
    }
]]

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local WindowModule = {}

local TOPBAR_HEIGHT = 32
local TABBAR_HEIGHT = TOPBAR_HEIGHT

local BUTTON_SIZE = 32
local RESIZE_SIZE = 20

local MIN_WIDTH = 150
local MIN_HEIGHT = 100

local function getTheme(Themes, themeName)
    if typeof(Themes) ~= "table" then
        error("Window.lua: Theme must be a table")
    end

    themeName = themeName or "Default"

    local theme = Themes[themeName]

    if typeof(theme) ~= "table" then
        theme = Themes.Default
    end

    if typeof(theme) ~= "table" then
        error("Window.lua: Default theme does not exist")
    end

    return theme
end

local function create(instanceType, properties, parent)
    local object = Instance.new(instanceType)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function clampSize(size)
    return Vector2.new(
        math.max(size.X, MIN_WIDTH),
        math.max(size.Y, MIN_HEIGHT)
    )
end

function WindowModule.CreateWindow(Themes, config)
    config = config or {}

    if typeof(config.Title) ~= "string" then
        config.Title = "Window"
    end

    if typeof(config.Size) ~= "UDim2" then
        config.Size = UDim2.fromOffset(500, 350)
    end

    local theme = getTheme(Themes, config.Theme)

    local textAlignment = config.TextAlignment

    if textAlignment ~= "Left"
        and textAlignment ~= "Center"
        and textAlignment ~= "Right"
    then
        textAlignment = "Left"
    end

    local state = {
        Title = config.Title,
        ThemeName = config.Theme or "Default",

        NoToggle = config.NoToggle == true,
        NoClose = config.NoClose == true,
        NoTabbar = config.NoTabbar == true,
        NoResize = config.NoResize == true,
        NoTopbar = config.NoTopbar == true,

        WindowVisible = true,
        OpenSize = config.Size,

        DragInput = nil,
        ResizeInput = nil,
        Dragging = false,
        Resizing = false,
        DragStart = nil,
        ResizeStart = nil,
        StartPosition = nil,
        StartSize = nil,

        Destroyed = false,
    }

    --==================================================
    -- Root
    --==================================================

    local ScreenGui = CoreGui:FindFirstChild("ReGui")

    if not ScreenGui then
        ScreenGui = create("ScreenGui", {
            Name = "ReGui",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })

        ScreenGui.Parent = CoreGui
    end

    local root = create("Frame", {
        Name = "Window",
        Size = state.OpenSize,
        Position = UDim2.fromOffset(100, 100),

        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,

        Active = true,
        ClipsDescendants = true,
    }, ScreenGui)

    --==================================================
    -- Topbar
    --==================================================

    local topbar = create("Frame", {
        Name = "Topbar",

        Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        Position = UDim2.fromOffset(0, 0),

        BackgroundColor3 = theme.Topbar,
        BorderSizePixel = 0,

        Active = true,
    }, root)

    --==================================================
    -- Toggle Button
    --==================================================

    local toggleButton = create("TextButton", {
        Name = "ToggleButton",

        Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        Position = UDim2.fromOffset(0, 0),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Text = "▼",
        TextColor3 = theme.Text,

        TextSize = 18,
        Font = Enum.Font.GothamBold,

        AutoButtonColor = false,
    }, topbar)

    toggleButton.Rotation = 0

    --==================================================
    -- Close Button
    --==================================================

    local closeButton = create("ImageButton", {
        Name = "CloseButton",

        Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        Position = UDim2.new(1, -BUTTON_SIZE, 0, 0),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Image = "rbxassetid://127173792845658",
        ImageColor3 = theme.Text,

        AutoButtonColor = false,
    }, topbar)

    --==================================================
    -- Title Frame
    --==================================================

    local titleFrame = create("Frame", {
        Name = "TitleFrame",

        Size = UDim2.new(1, -(BUTTON_SIZE * 2), 1, 0),
        Position = UDim2.fromOffset(BUTTON_SIZE, 0),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, topbar)

    local titleLabel = create("TextLabel", {
        Name = "Title",

        Size = UDim2.fromScale(1, 1),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Text = state.Title,
        TextColor3 = theme.Text,

        TextSize = 14,
        Font = Enum.Font.Gotham,

        TextXAlignment =
            textAlignment == "Left" and Enum.TextXAlignment.Left
            or textAlignment == "Center" and Enum.TextXAlignment.Center
            or Enum.TextXAlignment.Right,

        TextYAlignment = Enum.TextYAlignment.Center,

        TextTruncate = Enum.TextTruncate.AtEnd,
    }, titleFrame)

    --==================================================
    -- Tab Bar
    --==================================================

    local tabbar = create("ScrollingFrame", {
        Name = "TabBar",

        Size = UDim2.new(
            1,
            0,
            0,
            state.NoTabbar and 0 or TABBAR_HEIGHT
        ),

        Position = UDim2.fromOffset(
            0,
            state.NoTopbar and 0 or TOPBAR_HEIGHT
        ),

        BackgroundColor3 = theme.TabContainer,
        BorderSizePixel = 0,

        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,

        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 0,

        Active = true,
    }, root)

    local tabLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,

        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,

        SortOrder = Enum.SortOrder.LayoutOrder,

        Padding = UDim.new(0, 2),
    }, tabbar)

    --==================================================
    -- Background
    --==================================================

    local backgroundTopOffset =
        (state.NoTopbar and 0 or TOPBAR_HEIGHT)
        + (state.NoTabbar and 0 or TABBAR_HEIGHT)

    local background = create("Frame", {
        Name = "Background",

        Size = UDim2.new(
            1,
            0,
            1,
            -backgroundTopOffset
        ),

        Position = UDim2.fromOffset(
            0,
            backgroundTopOffset
        ),

        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,

        Active = true,
    }, root)

    --==================================================
    -- Resize Corner
    --==================================================

    local resizeCorner = create("TextButton", {
        Name = "ResizeCorner",

        Size = UDim2.fromOffset(
            RESIZE_SIZE,
            RESIZE_SIZE
        ),

        Position = UDim2.new(
            1,
            -RESIZE_SIZE,
            1,
            -RESIZE_SIZE
        ),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Text = "◢",
        TextColor3 = theme.ResizeCorner,

        TextSize = RESIZE_SIZE,
        Font = Enum.Font.GothamBold,

        AutoButtonColor = false,
    }, background)

    --==================================================
    -- Internal helpers
    --==================================================

    local function updateLayout()
        local topbarHeight =
            state.NoTopbar and 0 or TOPBAR_HEIGHT

        local tabbarHeight =
            state.NoTabbar and 0 or TABBAR_HEIGHT

        topbar.Visible = not state.NoTopbar

        tabbar.Visible = not state.NoTabbar

        topbar.Size = UDim2.new(
            1,
            0,
            0,
            topbarHeight
        )

        tabbar.Position = UDim2.fromOffset(
            0,
            topbarHeight
        )

        tabbar.Size = UDim2.new(
            1,
            0,
            0,
            tabbarHeight
        )

        background.Position = UDim2.fromOffset(
            0,
            topbarHeight + tabbarHeight
        )

        background.Size = UDim2.new(
            1,
            0,
            1,
            -(topbarHeight + tabbarHeight)
        )

        resizeCorner.Visible = not state.NoResize
        resizeCorner.Position = UDim2.new(
            1,
            -RESIZE_SIZE,
            1,
            -RESIZE_SIZE
        )

        toggleButton.Visible = not state.NoToggle
        closeButton.Visible = not state.NoClose
    end

    local function setWindowOpen(open)
        if state.Destroyed then
            return
        end

        state.WindowVisible = open
        root.Visible = open

        if open then
            root.Size = state.OpenSize
            toggleButton.Rotation = 0
        else
            state.OpenSize = root.Size

            root.Size = UDim2.new(
                state.OpenSize.X,
                0,
                0,
                TOPBAR_HEIGHT
            )

            toggleButton.Rotation = -90
        end
    end

    --==================================================
    -- Drag
    --==================================================

    topbar.InputBegan:Connect(function(input)
        if state.Destroyed then
            return
        end

        if state.Dragging or state.Resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        state.Dragging = true
        state.DragInput = input

        state.DragStart = input.Position
        state.StartPosition = root.Position
    end)

    topbar.InputEnded:Connect(function(input)
        if input ~= state.DragInput then
            return
        end

        state.Dragging = false
        state.DragInput = nil
    end)

    UserInputService.InputChanged:Connect(function(input)
        if state.Destroyed then
            return
        end

        if not state.Dragging then
            return
        end

        if input ~= state.DragInput
            and input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        local delta =
            input.Position - state.DragStart

        root.Position = UDim2.new(
            state.StartPosition.X.Scale,
            state.StartPosition.X.Offset + delta.X,

            state.StartPosition.Y.Scale,
            state.StartPosition.Y.Offset + delta.Y
        )
    end)

    --==================================================
    -- Resize
    --==================================================

    resizeCorner.InputBegan:Connect(function(input)
        if state.Destroyed then
            return
        end

        if state.NoResize then
            return
        end

        if state.Dragging or state.Resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        state.Resizing = true
        state.ResizeInput = input

        state.ResizeStart = input.Position
        state.StartSize = root.AbsoluteSize
    end)

    resizeCorner.InputEnded:Connect(function(input)
        if input ~= state.ResizeInput then
            return
        end

        state.Resizing = false
        state.ResizeInput = nil
    end)

    UserInputService.InputChanged:Connect(function(input)
        if state.Destroyed then
            return
        end

        if not state.Resizing then
            return
        end

        if input ~= state.ResizeInput
            and input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        local delta =
            input.Position - state.ResizeStart

        local newSize = clampSize(Vector2.new(
            state.StartSize.X + delta.X,
            state.StartSize.Y + delta.Y
        ))

        root.Size = UDim2.fromOffset(
            newSize.X,
            newSize.Y
        )

        state.OpenSize = root.Size
    end)

    --==================================================
    -- Toggle Button
    --==================================================

    toggleButton.Activated:Connect(function()
        if state.Destroyed or state.NoToggle then
            return
        end

        if state.WindowVisible then
            setWindowOpen(false)
        else
            setWindowOpen(true)
        end
    end)

    --==================================================
    -- Close Button
    --==================================================

    closeButton.Activated:Connect(function()
        if state.Destroyed or state.NoClose then
            return
        end

        Window:Destroy()
    end)

    --==================================================
    -- Public Window object
    --==================================================

    local Window = {}

    --==================================================
    -- Close
    --==================================================

    function Window:Close()
        setWindowOpen(false)
    end

    --==================================================
    -- Open
    --==================================================

    function Window:Open()
        setWindowOpen(true)
    end

    --==================================================
    -- SetTitle
    --==================================================

    function Window:SetTitle(newTitle)
        if state.Destroyed then
            return
        end

        if typeof(newTitle) ~= "string" then
            return
        end

        state.Title = newTitle
        titleLabel.Text = newTitle
    end

    --==================================================
    -- Destroy
    --==================================================

    function Window:Destroy()
        if state.Destroyed then
            return
        end

        state.Destroyed = true

        state.Dragging = false
        state.Resizing = false

        state.DragInput = nil
        state.ResizeInput = nil

        root:Destroy()
    end

    --==================================================
    -- Toggle Window Visibility
    --==================================================

    function Window:Toggle()
        if state.Destroyed then
            return
        end

        setWindowOpen(not state.WindowVisible)
    end

    --==================================================
    -- NoToggle Runtime
    --==================================================

    function Window:NoToggle(value)
        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoToggle = not state.NoToggle
        else
            state.NoToggle = value == true
        end

        toggleButton.Visible = not state.NoToggle
    end

    --==================================================
    -- NoClose Runtime
    --==================================================

    function Window:NoClose(value)
        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoClose = not state.NoClose
        else
            state.NoClose = value == true
        end

        closeButton.Visible = not state.NoClose
    end

    --==================================================
    -- NoTabbar Runtime
    --==================================================

    function Window:NoTabbar(value)
        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoTabbar = not state.NoTabbar
        else
            state.NoTabbar = value == true
        end

        updateLayout()
    end

    --==================================================
    -- NoResize Runtime
    --==================================================

    function Window:NoResize(value)
        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoResize = not state.NoResize
        else
            state.NoResize = value == true
        end

        resizeCorner.Visible = not state.NoResize
    end

    --==================================================
    -- NoTopbar Runtime
    --==================================================

    function Window:NoTopbar(value)
        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoTopbar = not state.NoTopbar
        else
            state.NoTopbar = value == true
        end

        updateLayout()
    end

    --==================================================
    -- Exposed references
    --==================================================

    Window.Instance = root

    Window.Topbar = topbar
    Window.TabBar = tabbar
    Window.Background = background

    Window.TitleFrame = titleFrame
    Window.Title = titleLabel

    Window.ToggleButton = toggleButton
    Window.CloseButton = closeButton
    Window.ResizeCorner = resizeCorner

    Window.Theme = theme

    --==================================================
    -- Initial layout
    --==================================================

    updateLayout()

    return Window
end

return WindowModule
