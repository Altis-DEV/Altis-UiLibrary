local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local WindowModule = {}

--==================================================
-- Constants
--==================================================

local TOPBAR_HEIGHT = 32
local TABBAR_HEIGHT = TOPBAR_HEIGHT

local CONTROL_SIZE = 32

local RESIZE_SIZE = 25
local RESIZE_TEXT_SIZE = 24

local DEFAULT_MIN_WIDTH = 300
local DEFAULT_MIN_HEIGHT = 200

local CLOSE_ICON = "rbxassetid://127173792845658"

--==================================================
-- Utility
--==================================================

local function Create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local function GetTheme(Themes, name)
    name = name or "Default"

    local theme = Themes[name]

    if typeof(theme) ~= "table" then
        theme = Themes.Default
    end

    assert(
        typeof(theme) == "table",
        "Window.lua: Default theme is missing."
    )

    return theme
end

local function ConvertAlignment(value)
    if value == "Center" then
        return Enum.TextXAlignment.Center
    elseif value == "Right" then
        return Enum.TextXAlignment.Right
    end

    return Enum.TextXAlignment.Left
end

--==================================================
-- Create Window
--==================================================

function WindowModule.CreateWindow(Themes, config)

    config = config or {}

    local title = config.Title or "Window"

    local size = config.Size

    if typeof(size) ~= "UDim2" then
        size = UDim2.fromOffset(500, 350)
    end

    local textAlignment = ConvertAlignment(
        config.TextAlignment or "Left"
    )

    local themeName = config.Theme or "Default"
    local theme = GetTheme(Themes, themeName)

    local minimumSize = config.MinimumSize

    if typeof(minimumSize) ~= "Vector2" then
        minimumSize = Vector2.new(
            DEFAULT_MIN_WIDTH,
            DEFAULT_MIN_HEIGHT
        )
    end

    --==================================================
    -- State
    --==================================================

    local state = {
        Title = title,

        ThemeName = themeName,

        IsOpen = true,
        Destroyed = false,

        NoToggle = config.NoToggle == true,
        NoClose = config.NoClose == true,
        NoTabbar = config.NoTabbar == true,
        NoResize = config.NoResize == true,
        NoTopbar = config.NoTopbar == true,

        OpenSize = size,

        Dragging = false,
        DragInput = nil,

        Resizing = false,
        ResizeInput = nil,

        DragStart = nil,
        ResizeStart = nil,

        StartPosition = nil,
        StartSize = nil,
    }

    --==================================================
    -- ScreenGui
    --==================================================

    local ScreenGui = CoreGui:FindFirstChild("imgui")

    if not ScreenGui then
        ScreenGui = Create("ScreenGui", {
            Name = "imgui",

            ResetOnSpawn = false,

            ZIndexBehavior =
                Enum.ZIndexBehavior.Sibling,
        }, CoreGui)
    end

    --==================================================
    -- Window
    --==================================================

    local WindowFrame = Create("Frame", {
        Name = "Window",

        Size = size,

        Position =
            UDim2.fromOffset(100, 100),

        BackgroundColor3 =
            theme.Background,

        BorderSizePixel = 0,

        Active = true,

        ClipsDescendants = true,
    }, ScreenGui)

    --==================================================
    -- Topbar
    --==================================================

    local Topbar = Create("Frame", {
        Name = "Topbar",

        Size = UDim2.new(
            1,
            0,
            0,
            TOPBAR_HEIGHT
        ),

        Position = UDim2.fromOffset(
            0,
            0
        ),

        BackgroundColor3 =
            theme.Topbar,

        BorderSizePixel = 0,

        Active = true,
    }, WindowFrame)

    --==================================================
    -- Toggle Button
    --==================================================

    local ToggleButton = Create("TextButton", {
        Name = "ToggleButton",

        Size = UDim2.fromOffset(
            CONTROL_SIZE,
            TOPBAR_HEIGHT
        ),

        Position = UDim2.fromOffset(
            0,
            0
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Text = "▼",

        TextColor3 =
            theme.Text,

        TextSize = 18,

        Font =
            Enum.Font.GothamBold,

        AutoButtonColor = false,
    }, Topbar)

    --==================================================
    -- Close Button
    --==================================================

    local CloseButton = Create("ImageButton", {
        Name = "CloseButton",

        Size = UDim2.fromOffset(
            CONTROL_SIZE,
            TOPBAR_HEIGHT
        ),

        Position = UDim2.new(
            1,
            -CONTROL_SIZE,
            0,
            0
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Image = CLOSE_ICON,

        ImageColor3 =
            theme.Text,

        AutoButtonColor = false,
    }, Topbar)

    --==================================================
    -- Title Frame
    --==================================================

    local TitleFrame = Create("Frame", {
        Name = "TitleFrame",

        Size = UDim2.new(
            1,
            -(CONTROL_SIZE * 2),
            1,
            0
        ),

        Position = UDim2.fromOffset(
            CONTROL_SIZE,
            0
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,
    }, Topbar)

    local TitleLabel = Create("TextLabel", {
        Name = "Title",

        Size = UDim2.fromScale(
            1,
            1
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Text = title,

        TextColor3 =
            theme.Text,

        TextSize = 14,

        Font =
            Enum.Font.Gotham,

        TextXAlignment =
            textAlignment,

        TextYAlignment =
            Enum.TextYAlignment.Center,

        TextTruncate =
            Enum.TextTruncate.AtEnd,
    }, TitleFrame)

    --==================================================
    -- Tab Selection
    --==================================================

    local TabSelection = Create("Frame", {
        Name = "TabSelection",

        Size = UDim2.new(
            1,
            0,
            0,
            TABBAR_HEIGHT
        ),

        Position = UDim2.fromOffset(
            0,
            TOPBAR_HEIGHT
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,
    }, WindowFrame)

    --==================================================
    -- Tab Buttons
    --==================================================

    local TabButtons = Create("ScrollingFrame", {
        Name = "TabButtons",

        Size = UDim2.fromScale(
            1,
            1
        ),

        Position = UDim2.fromOffset(
            0,
            0
        ),

        BackgroundColor3 =
            theme.TabContainer,

        BorderSizePixel = 0,

        CanvasSize =
            UDim2.new(0, 0, 0, 0),

        AutomaticCanvasSize =
            Enum.AutomaticSize.X,

        ScrollingDirection =
            Enum.ScrollingDirection.X,

        ScrollingEnabled = true,

        ScrollBarThickness = 0,

        HorizontalScrollBarInset =
            Enum.ScrollBarInset.None,

        VerticalScrollBarInset =
            Enum.ScrollBarInset.None,

        Active = true,

        ClipsDescendants = true,
    }, TabSelection)

    local TabLayout = Create("UIListLayout", {
        FillDirection =
            Enum.FillDirection.Horizontal,

        HorizontalAlignment =
            Enum.HorizontalAlignment.Left,

        VerticalAlignment =
            Enum.VerticalAlignment.Center,

        SortOrder =
            Enum.SortOrder.LayoutOrder,

        Padding =
            UDim.new(0, 2),
    }, TabButtons)

    --==================================================
    -- Background
    --==================================================

    local Background = Create("Frame", {
        Name = "Background",

        Size = UDim2.new(
            1,
            0,
            1,
            -(
                TOPBAR_HEIGHT
                + TABBAR_HEIGHT
            )
        ),

        Position = UDim2.fromOffset(
            0,
            TOPBAR_HEIGHT
            + TABBAR_HEIGHT
        ),

        BackgroundColor3 =
            theme.Background,

        BorderSizePixel = 0,

        Active = true,

        ClipsDescendants = true,
    }, WindowFrame)

    --==================================================
    -- Resize Corner
    --==================================================

    local ResizeCorner = Create("TextButton", {
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

        TextColor3 =
            theme.ResizeCorner,

        TextSize =
            RESIZE_TEXT_SIZE,

        Font =
            Enum.Font.GothamBold,

        AutoButtonColor = false,

        Visible =
            not state.NoResize,
    }, Background)

    --==================================================
    -- Window Object
    --==================================================

    local Window = {}

    Window.Instance = WindowFrame

    Window.Topbar = Topbar
    Window.TabSelection = TabSelection
    Window.TabButtons = TabButtons
    Window.Background = Background

    Window.TitleFrame = TitleFrame
    Window.Title = TitleLabel

    Window.ToggleButton = ToggleButton
    Window.CloseButton = CloseButton
    Window.ResizeCorner = ResizeCorner

    Window.Theme = theme

    --==================================================
    -- Layout
    --==================================================

    local function UpdateLayout()

        if state.Destroyed then
            return
        end

        local topbarHeight =
            state.NoTopbar
            and 0
            or TOPBAR_HEIGHT

        local tabbarHeight =
            state.NoTabbar
            and 0
            or TABBAR_HEIGHT

        -- Topbar

        Topbar.Visible =
            not state.NoTopbar

        Topbar.Size =
            UDim2.new(
                1,
                0,
                0,
                topbarHeight
            )

        -- Tab selection

        TabSelection.Visible =
            not state.NoTabbar

        TabSelection.Position =
            UDim2.fromOffset(
                0,
                topbarHeight
            )

        TabSelection.Size =
            UDim2.new(
                1,
                0,
                0,
                tabbarHeight
            )

        -- Background

        Background.Position =
            UDim2.fromOffset(
                0,
                topbarHeight
                + tabbarHeight
            )

        Background.Size =
            UDim2.new(
                1,
                0,
                1,
                -(
                    topbarHeight
                    + tabbarHeight
                )
            )

        -- Buttons

        ToggleButton.Visible =
            not state.NoToggle

        CloseButton.Visible =
            not state.NoClose

        ResizeCorner.Visible =
            not state.NoResize

    end

    --==================================================
    -- Pointer helpers
    --==================================================

    local function IsPrimaryPointer(input)

        return input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
            Enum.UserInputType.Touch

    end

    --==================================================
    -- Drag Start
    --==================================================

    Topbar.InputBegan:Connect(function(input)

        if state.Destroyed then
            return
        end

        if state.Dragging
            or state.Resizing
        then
            return
        end

        if not IsPrimaryPointer(input) then
            return
        end

        state.Dragging = true

        state.DragInput = input

        state.DragStart =
            input.Position

        state.StartPosition =
            WindowFrame.Position

    end)

    --==================================================
    -- Drag End
    --==================================================

    Topbar.InputEnded:Connect(function(input)

        if input ~= state.DragInput then
            return
        end

        state.Dragging = false
        state.DragInput = nil

    end)

    --==================================================
    -- Resize Start
    --==================================================

    ResizeCorner.InputBegan:Connect(function(input)

        if state.Destroyed then
            return
        end

        if state.NoResize then
            return
        end

        if state.Dragging
            or state.Resizing
        then
            return
        end

        if not IsPrimaryPointer(input) then
            return
        end

        state.Resizing = true

        state.ResizeInput = input

        state.ResizeStart =
            input.Position

        state.StartSize =
            WindowFrame.AbsoluteSize

    end)

    --==================================================
    -- Resize End
    --==================================================

    ResizeCorner.InputEnded:Connect(function(input)

        if input ~= state.ResizeInput then
            return
        end

        state.Resizing = false
        state.ResizeInput = nil

    end)

    --==================================================
    -- Movement
    --==================================================

    UserInputService.InputChanged:Connect(function(input)

        if state.Destroyed then
            return
        end

        -- Drag

        if state.Dragging then

            if input ~= state.DragInput
                and input.UserInputType
                    ~= Enum.UserInputType.MouseMovement
                and input.UserInputType
                    ~= Enum.UserInputType.Touch
            then
                return
            end

            local delta =
                input.Position
                - state.DragStart

            WindowFrame.Position =
                UDim2.new(
                    state.StartPosition.X.Scale,
                    state.StartPosition.X.Offset
                        + delta.X,

                    state.StartPosition.Y.Scale,
                    state.StartPosition.Y.Offset
                        + delta.Y
                )

            return
        end

        -- Resize

        if state.Resizing then

            if input ~= state.ResizeInput
                and input.UserInputType
                    ~= Enum.UserInputType.MouseMovement
                and input.UserInputType
                    ~= Enum.UserInputType.Touch
            then
                return
            end

            local delta =
                input.Position
                - state.ResizeStart

            local width =
                math.max(
                    state.StartSize.X + delta.X,
                    minimumSize.X
                )

            local height =
                math.max(
                    state.StartSize.Y + delta.Y,
                    minimumSize.Y
                )

            WindowFrame.Size =
                UDim2.fromOffset(
                    width,
                    height
                )

            state.OpenSize =
                WindowFrame.Size

        end

    end)

    --==================================================
    -- Open
    --==================================================

    function Window:Open()

        if state.Destroyed then
            return
        end

        state.IsOpen = true

        WindowFrame.Visible = true

        WindowFrame.Size =
            state.OpenSize

        ToggleButton.Rotation = 0

    end

    --==================================================
    -- Close
    --==================================================

    function Window:Close()

        if state.Destroyed then
            return
        end

        state.IsOpen = false

        state.OpenSize =
            WindowFrame.Size

        WindowFrame.Visible = true

        WindowFrame.Size =
            UDim2.new(
                state.OpenSize.X.Scale,
                state.OpenSize.X.Offset,

                0,
                TOPBAR_HEIGHT
            )

        ToggleButton.Rotation = -90

    end

    --==================================================
    -- Toggle
    --==================================================

    function Window:Toggle()

        if state.Destroyed then
            return
        end

        if state.IsOpen then
            self:Close()
        else
            self:Open()
        end

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

        TitleLabel.Text = newTitle

    end

    --==================================================
    -- NoToggle
    --==================================================

    function Window:NoToggle(value)

        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoToggle =
                not state.NoToggle
        else
            state.NoToggle =
                value == true
        end

        ToggleButton.Visible =
            not state.NoToggle

    end

    --==================================================
    -- NoClose
    --==================================================

    function Window:NoClose(value)

        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoClose =
                not state.NoClose
        else
            state.NoClose =
                value == true
        end

        CloseButton.Visible =
            not state.NoClose

    end

    --==================================================
    -- NoTabbar
    --==================================================

    function Window:NoTabbar(value)

        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoTabbar =
                not state.NoTabbar
        else
            state.NoTabbar =
                value == true
        end

        UpdateLayout()

    end

    --==================================================
    -- NoResize
    --==================================================

    function Window:NoResize(value)

        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoResize =
                not state.NoResize
        else
            state.NoResize =
                value == true
        end

        ResizeCorner.Visible =
            not state.NoResize

    end

    --==================================================
    -- NoTopbar
    --==================================================

    function Window:NoTopbar(value)

        if state.Destroyed then
            return
        end

        if value == nil then
            state.NoTopbar =
                not state.NoTopbar
        else
            state.NoTopbar =
                value == true
        end

        UpdateLayout()

    end

    --==================================================
    -- SetTheme
    --==================================================

    function Window:SetTheme(themeName)

        if state.Destroyed then
            return
        end

        local newTheme =
            GetTheme(
                Themes,
                themeName
            )

        state.ThemeName =
            themeName or "Default"

        theme =
            newTheme

        Window.Theme =
            newTheme

        WindowFrame.BackgroundColor3 =
            newTheme.Background

        Topbar.BackgroundColor3 =
            newTheme.Topbar

        TabButtons.BackgroundColor3 =
            newTheme.TabContainer

        Background.BackgroundColor3 =
            newTheme.Background

        TitleLabel.TextColor3 =
            newTheme.Text

        ToggleButton.TextColor3 =
            newTheme.Text

        CloseButton.ImageColor3 =
            newTheme.Text

        ResizeCorner.TextColor3 =
            newTheme.ResizeCorner

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

        WindowFrame:Destroy()

    end

    --==================================================
    -- Button Events
    --==================================================

    ToggleButton.Activated:Connect(function()

        if state.NoToggle then
            return
        end

        Window:Toggle()

    end)

    CloseButton.Activated:Connect(function()

        if state.NoClose then
            return
        end

        Window:Destroy()

    end)

    --==================================================
    -- Initial State
    --==================================================

    UpdateLayout()

    return Window
end

return WindowModule
