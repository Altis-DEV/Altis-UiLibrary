# Altis UI Library

A Roblox UI library for building modern hubs with a clean structure, reusable elements, and full method coverage.

---

# Installations

## Loadstring

```lua
local AltisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/refs/heads/main/Source"))()
```

---

# Window

## Create Window

```lua
local Window = AltisLib.CreateWindow("My Cool Hub", UDim2.new(0, 550, 0, 400))
```

## Window Methods

```lua
Window:SetBackgroundImage("") -- optional, raw url https:// or rbxassetid://
Window:SetBackgroundImageTransparency() -- optional, number 0 - 1
Window:SetBackgroundTransparency() -- optional, number 0 - 1
Window:SetMainColor() -- optional, Color3.fromRGB()
Window:SendNotification("Title", "Text", 5)
Window:Toggle() -- dynamic show / hide ui
Window:Destroy() -- destroy the ui library
```

## Window Example

```lua
local Window = AltisLib.CreateWindow("My Cool Hub", UDim2.new(0, 550, 0, 400))
Window:SetMainColor(Color3.fromRGB(0, 150, 255))
Window:SetBackgroundTransparency(0.6)
Window:SetBackgroundImage("rbxassetid://111612290258829")
Window:SetBackgroundImageTransparency(0.4)
Window:SendNotification("Loaded", "UI library initialized", 5)
```

---

# Tab

## Create Tab

```lua
local Tab = Window:CreateTab("Tab Title")
```

## Tab Can Create

```lua
Tab:CreateButton()
Tab:CreateToggle()
Tab:CreateSlider()
Tab:CreateDropdown()
Tab:CreateMultiDropdown()
Tab:CreateTextBox()
Tab:CreateKeybind()
Tab:CreateColorPicker()
Tab:CreateImage()
Tab:CreateLabel()
Tab:CreateParagraph()
Tab:CreateDivider()
Tab:CreateSection()
```

## Tab Example

```lua
local MainTab = Window:CreateTab("Main")
local CombatTab = Window:CreateTab("Combat")
local MiscTab = Window:CreateTab("Misc")
```

---

# Section

## Create Section

```lua
local Section = Tab:CreateSection("Title")
```

## Section Can Create

```lua
Section:CreateButton()
Section:CreateToggle()
Section:CreateSlider()
Section:CreateDropdown()
Section:CreateMultiDropdown()
Section:CreateTextBox()
Section:CreateKeybind()
Section:CreateColorPicker()
Section:CreateImage()
Section:CreateLabel()
Section:CreateParagraph()
Section:CreateDivider()
```

## Section Example

```lua
local Section = Tab:CreateSection("Main Section")
```

---

# Element

## Button

### Create

```lua
local Button = Tab:CreateButton("title", function()
    print("clicked")
end)
```

### Button Methods

```lua
Button:Destroy()
```

### Button Method Test

```lua
local Button = Tab:CreateButton("Destroy Button", function()
    print("Button clicked")
end)

Tab:CreateButton("Call Destroy()", function()
    Button:Destroy()
end)
```

---

## Toggle

### Create

```lua
local Toggle = Tab:CreateToggle("Title", false, function(state)
    print(state)
end)
```

### Toggle Methods

```lua
Toggle:Destroy()
```

### Toggle Method Test

```lua
local Toggle = Tab:CreateToggle("Auto Farm", false, function(state)
    print("Toggle:", state)
end)

Tab:CreateButton("Call Destroy()", function()
    Toggle:Destroy()
end)
```

---

## Slider

### Create

```lua
local Slider = Tab:CreateSlider("Title", 0, 100, 10, function(value)
    print(value)
end)
```

### Slider Methods

```lua
Slider:Destroy()
```

### Slider Method Test

```lua
local Slider = Tab:CreateSlider("WalkSpeed", 0, 100, 16, function(value)
    print("Value:", value)
end)

Tab:CreateButton("Call Destroy()", function()
    Slider:Destroy()
end)
```

---

## Dropdown

### Create

```lua
local Dropdown = Tab:CreateDropdown("Title", {"1", "2", "3"}, "1", function(option)
    print(option)
end)
```

### Dropdown Methods

```lua
Dropdown:Destroy()
Dropdown:Refresh({"4", "5", "6"})
```

### Dropdown Method Test

```lua
local Dropdown = Tab:CreateDropdown("Weapon", {"Sword", "Gun", "Bow"}, "Sword", function(option)
    print("Selected:", option)
end)

Tab:CreateButton("Call Refresh()", function()
    Dropdown:Refresh({"Axe", "Spear", "Shield"})
end)

Tab:CreateButton("Call Destroy()", function()
    Dropdown:Destroy()
end)
```

---

## Multi Dropdown

### Create

```lua
local MultiDropdown = Tab:CreateMultiDropdown("Title", {"1", "2", "3", "4"}, {"1", "2"}, function(options)
    for _, value in ipairs(options) do
        print(value)
    end
end)
```

### Multi Dropdown Methods

```lua
MultiDropdown:Destroy()
MultiDropdown:Refresh({"5", "6", "7"})
```

### Multi Dropdown Method Test

```lua
local MultiDropdown = Tab:CreateMultiDropdown("Skills", {"Slash", "Dash", "Heal", "Jump"}, {"Slash", "Dash"}, function(options)
    for _, value in ipairs(options) do
        print(value)
    end
end)

Tab:CreateButton("Call Refresh()", function()
    MultiDropdown:Refresh({"Fireball", "Ice", "Wind"})
end)

Tab:CreateButton("Call Destroy()", function()
    MultiDropdown:Destroy()
end)
```

---

## TextBox

### Create

```lua
local TextBox = Tab:CreateTextBox("Title", "Text", function(text)
    print(text)
end)
```

### TextBox Methods

```lua
TextBox:Destroy()
```

### TextBox Method Test

```lua
local TextBox = Tab:CreateTextBox("Player Name", "Enter a username", function(text)
    print("Text:", text)
end)

Tab:CreateButton("Call Destroy()", function()
    TextBox:Destroy()
end)
```

---

## Keybind

### Create

```lua
local Keybind = Tab:CreateKeybind("Title", Enum.KeyCode.RightShift, function(key)
    print(key)
end)
```

### Keybind Methods

```lua
Keybind:Destroy()
```

### Keybind Method Test

```lua
local Keybind = Tab:CreateKeybind("Toggle UI", Enum.KeyCode.RightShift, function(key)
    print("Pressed:", key)
end)

Tab:CreateButton("Call Destroy()", function()
    Keybind:Destroy()
end)
```

---

## ColorPicker

### Create

```lua
local ColorPicker = Tab:CreateColorPicker("Title", Color3.fromRGB(0, 0, 0), function(color)
    print(color)
end)
```

### ColorPicker Methods

```lua
ColorPicker:Destroy()
```

### ColorPicker Method Test

```lua
local ColorPicker = Tab:CreateColorPicker("Theme Color", Color3.fromRGB(170, 85, 255), function(color)
    Window:SetMainColor(color)
end)

Tab:CreateButton("Call Destroy()", function()
    ColorPicker:Destroy()
end)
```

---

## Image

### Create

```lua
local Image = Tab:CreateImage("rbxassetid://", UDim2.new(0, 50, 0, 50))
```

> You can also use a raw URL (`https://`) or `rbxassetid://`.  
> Size is optional. If you skip size, the image will auto scale.

### Image Methods

```lua
Image:Destroy()
Image:SetImage("") -- raw url https:// or rbxassetid://
Image:SetSize(UDim2.new(0, 100, 0, 100))
```

### Image Method Test

```lua
local Image = Tab:CreateImage("rbxassetid://95605701610484", UDim2.new(0, 50, 0, 50))

Tab:CreateButton("Call SetImage()", function()
    Image:SetImage("rbxassetid://121183386818512")
end)

Tab:CreateButton("Call SetSize()", function()
    Image:SetSize(UDim2.new(0, 100, 0, 100))
end)

Tab:CreateButton("Call Destroy()", function()
    Image:Destroy()
end)
```

---

## Label

### Create

```lua
local Label = Tab:CreateLabel("Title")
```

### Label Methods

```lua
Label:Destroy()
Label:SetText("New Title")
```

### Label Method Test

```lua
local Label = Tab:CreateLabel("Status: Ready")

Tab:CreateButton("Call SetText()", function()
    Label:SetText("Status: Loaded")
end)

Tab:CreateButton("Call Destroy()", function()
    Label:Destroy()
end)
```

---

## Paragraph

### Create

```lua
local Paragraph = Tab:CreateParagraph("Title", "Text")
```

> Text is optional. You can also create a paragraph with only a title:
>
> ```lua
> local Paragraph = Tab:CreateParagraph("Title")
> ```

> You can create elements inside Paragraph like this:
>
> ```lua
> local ButtonInParagraph = Paragraph:CreateButton("title", function()
>     print("clicked")
> end)
> ```

### Paragraph Methods

```lua
Paragraph:Destroy()
Paragraph:SetTitle("New Title")
Paragraph:SetText("New Text")
```

### Paragraph Method Test

```lua
local Paragraph = Tab:CreateParagraph("Patch Notes", "- Added new UI
- Fixed layout
- Improved wrapping")

Tab:CreateButton("Call SetTitle()", function()
    Paragraph:SetTitle("Updated Patch Notes")
end)

Tab:CreateButton("Call SetText()", function()
    Paragraph:SetText("- New text content
- More notes")
end)

Tab:CreateButton("Call Destroy()", function()
    Paragraph:Destroy()
end)
```

### Elements Inside Paragraph

```lua
local Paragraph = Tab:CreateParagraph("Tools", "Buttons inside paragraph")

local InnerButton = Paragraph:CreateButton("Inner Button", function()
    print("clicked")
end)

local InnerToggle = Paragraph:CreateToggle("Inner Toggle", false, function(state)
    print(state)
end)

local InnerLabel = Paragraph:CreateLabel("Inner Label")
```

---

## Divider

### Create

```lua
local Divider = Tab:CreateDivider()
```

### Divider Methods

```lua
Divider:Destroy()
```

### Divider Method Test

```lua
local Divider = Tab:CreateDivider()

Tab:CreateButton("Call Destroy()", function()
    Divider:Destroy()
end)
```

---

# Full Example

This example includes all elements, all section elements, and buttons that call every method available in the UI.

```lua
local AltisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/refs/heads/main/Source"))()

local Window = AltisLib.CreateWindow("My Cool Hub", UDim2.new(0, 550, 0, 400))
Window:SetMainColor(Color3.fromRGB(0, 150, 255))
Window:SetBackgroundTransparency(0.6)
Window:SetBackgroundImage("rbxassetid://111612290258829")
Window:SetBackgroundImageTransparency(0.4)

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("Section")

local Button = Tab:CreateButton("Button", function()
    print("clicked")
end)

local Toggle = Tab:CreateToggle("Toggle", false, function(state)
    print(state)
end)

local Slider = Tab:CreateSlider("Slider", 0, 100, 10, function(value)
    print(value)
end)

local Dropdown = Tab:CreateDropdown("Dropdown", {"1", "2", "3"}, "1", function(option)
    print(option)
end)

local MultiDropdown = Tab:CreateMultiDropdown("Multi Dropdown", {"1", "2", "3", "4"}, {"1", "2"}, function(options)
    for _, value in ipairs(options) do
        print(value)
    end
end)

local TextBox = Tab:CreateTextBox("TextBox", "Text", function(text)
    print(text)
end)

local Keybind = Tab:CreateKeybind("Keybind", Enum.KeyCode.RightShift, function(key)
    print(key)
end)

local ColorPicker = Tab:CreateColorPicker("ColorPicker", Color3.fromRGB(0, 0, 0), function(color)
    print(color)
end)

local Image = Tab:CreateImage("rbxassetid://95605701610484", UDim2.new(0, 50, 0, 50))
local Label = Tab:CreateLabel("Longgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg Label")
local Paragraph = Tab:CreateParagraph("Longggggggggggggggggggggggggggggggggggggggggggggggggg Paragraph Title", "Longggggggggggggggggggggggggggggggggggggggggggggggggg Paragraph Text")
local Divider = Tab:CreateDivider()

local SectionButton = Section:CreateButton("Section Button", function()
    print("section button clicked")
end)

local SectionToggle = Section:CreateToggle("Section Toggle", false, function(state)
    print(state)
end)

local SectionSlider = Section:CreateSlider("Section Slider", 0, 100, 25, function(value)
    print(value)
end)

local SectionDropdown = Section:CreateDropdown("Section Dropdown", {"A", "B", "C"}, "A", function(option)
    print(option)
end)

local SectionMultiDropdown = Section:CreateMultiDropdown("Section Multi Dropdown", {"A", "B", "C"}, {"A"}, function(options)
    for _, value in ipairs(options) do
        print(value)
    end
end)

local SectionTextBox = Section:CreateTextBox("Section TextBox", "Type here", function(text)
    print(text)
end)

local SectionKeybind = Section:CreateKeybind("Section Keybind", Enum.KeyCode.RightShift, function(key)
    print(key)
end)

local SectionColorPicker = Section:CreateColorPicker("Section ColorPicker", Color3.fromRGB(255, 0, 0), function(color)
    print(color)
end)

local SectionImage = Section:CreateImage("rbxassetid://121183386818512", UDim2.new(0, 50, 0, 50))
local SectionLabel = Section:CreateLabel("Section Label")
local SectionParagraph = Section:CreateParagraph("Section Paragraph", "Text inside section")
local SectionDivider = Section:CreateDivider()

Tab:CreateButton("Window:Toggle()", function()
    Window:Toggle()
end)

Tab:CreateButton("Window:SendNotification()", function()
    Window:SendNotification("Notice", "This is a test notification", 5)
end)

Tab:CreateButton("Window:SetMainColor()", function()
    Window:SetMainColor(Color3.fromRGB(170, 85, 255))
end)

Tab:CreateButton("Window:SetBackgroundTransparency()", function()
    Window:SetBackgroundTransparency(0.2)
end)

Tab:CreateButton("Window:SetBackgroundImage()", function()
    Window:SetBackgroundImage("rbxassetid://121183386818512")
end)

Tab:CreateButton("Window:SetBackgroundImageTransparency()", function()
    Window:SetBackgroundImageTransparency(0.2)
end)

Tab:CreateButton("Dropdown:Refresh()", function()
    Dropdown:Refresh({"4", "5", "6"})
end)

Tab:CreateButton("MultiDropdown:Refresh()", function()
    MultiDropdown:Refresh({"5", "6", "7"})
end)

Tab:CreateButton("Label:SetText()", function()
    Label:SetText("New Title")
end)

Tab:CreateButton("Paragraph:SetTitle()", function()
    Paragraph:SetTitle("New Paragraph Title")
end)

Tab:CreateButton("Paragraph:SetText()", function()
    Paragraph:SetText("New Paragraph Text")
end)

Tab:CreateButton("Image:SetImage()", function()
    Image:SetImage("rbxassetid://121183386818512")
end)

Tab:CreateButton("Image:SetSize()", function()
    Image:SetSize(UDim2.new(0, 100, 0, 100))
end)

Tab:CreateButton("Destroy Button", function() Button:Destroy() end)
Tab:CreateButton("Destroy Toggle", function() Toggle:Destroy() end)
Tab:CreateButton("Destroy Slider", function() Slider:Destroy() end)
Tab:CreateButton("Destroy Dropdown", function() Dropdown:Destroy() end)
Tab:CreateButton("Destroy MultiDropdown", function() MultiDropdown:Destroy() end)
Tab:CreateButton("Destroy TextBox", function() TextBox:Destroy() end)
Tab:CreateButton("Destroy Keybind", function() Keybind:Destroy() end)
Tab:CreateButton("Destroy ColorPicker", function() ColorPicker:Destroy() end)
Tab:CreateButton("Destroy Image", function() Image:Destroy() end)
Tab:CreateButton("Destroy Label", function() Label:Destroy() end)
Tab:CreateButton("Destroy Paragraph", function() Paragraph:Destroy() end)
Tab:CreateButton("Destroy Divider", function() Divider:Destroy() end)
Tab:CreateButton("Destroy Section", function() Section:Destroy() end)
Tab:CreateButton("Destroy Window", function()
    Window:Destroy()
end)

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local function CreateFloatingToggle()
    if getgenv().AltisToggleGui then
        pcall(function()
            getgenv().AltisToggleGui:Destroy()
        end)
    end

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "AltisToggleGui"
    toggleGui.ResetOnSpawn = false
    toggleGui.IgnoreGuiInset = true
    toggleGui.DisplayOrder = 999999
    toggleGui.Parent = CoreGui

    getgenv().AltisToggleGui = toggleGui

    local toggle = Instance.new("ImageButton")
    toggle.Name = "AltisToggleButton"
    toggle.Parent = toggleGui
    toggle.Size = UDim2.fromOffset(48, 48)
    toggle.Position = UDim2.new(0, 16, 0.5, -24)
    toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggle.BorderSizePixel = 0
    toggle.AutoButtonColor = false
    toggle.Image = "rbxassetid://95605701610484"
    toggle.Active = true
    toggle.Selectable = true
    toggle.ZIndex = 999999

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggle

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.72
    stroke.Thickness = 1.2
    stroke.Parent = toggle

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        toggle.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggle.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    toggle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            updateDrag(input)
        end
    end)

    toggle.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
end

CreateFloatingToggle()
 
```

---

# Notes

- `CreateParagraph()` can be used with title only.
- `CreateImage()` can use `https://` or `rbxassetid://`.
- `CreateDropdown()` and `CreateMultiDropdown()` support refresh.
- `Window:Toggle()` is useful for dynamic UI buttons.
- Sections are useful for organizing big hubs cleanly.
- The full example above includes buttons for every important method, not only `Destroy()`.

---

# Method List

## Window
- `SetBackgroundImage(image)`
- `SetBackgroundImageTransparency(value)`
- `SetBackgroundTransparency(value)`
- `SetMainColor(color)`
- `SendNotification(title, text, duration)`
- `Toggle()`
- `Destroy()`

## Button
- `Destroy()`

## Toggle
- `Destroy()`

## Slider
- `Destroy()`

## Dropdown
- `Destroy()`
- `Refresh(options)`

## Multi Dropdown
- `Destroy()`
- `Refresh(options)`

## TextBox
- `Destroy()`

## Keybind
- `Destroy()`

## ColorPicker
- `Destroy()`

## Image
- `Destroy()`
- `SetImage(image)`
- `SetSize(size)`

## Label
- `Destroy()`
- `SetText(text)`

## Paragraph
- `Destroy()`
- `SetTitle(title)`
- `SetText(text)`
- `CreateButton()`
- `CreateToggle()`
- `CreateSlider()`
- `CreateDropdown()`
- `CreateMultiDropdown()`
- `CreateTextBox()`
- `CreateKeybind()`
- `CreateColorPicker()`
- `CreateImage()`
- `CreateLabel()`
- `CreateParagraph()`
- `CreateDivider()`

## Divider
- `Destroy()`

## Section
- `Destroy()`
- `CreateButton()`
- `CreateToggle()`
- `CreateSlider()`
- `CreateDropdown()`
- `CreateMultiDropdown()`
- `CreateTextBox()`
- `CreateKeybind()`
- `CreateColorPicker()`
- `CreateImage()`
- `CreateLabel()`
- `CreateParagraph()`
- `CreateDivider()`

---

# License

For personal use and UI development only.

