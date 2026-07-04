# AltisLib

AltisLib is a clean, lightweight Roblox UI library inspired by modern ImGui-style interfaces. It is designed to make it easy to build polished hubs, config panels, debug menus, and test interfaces with a simple, readable API.

> **Library name:** `AltisLib`  
> **Style:** Dear ImGui / ReGui-inspired  
> **Focus:** Clarity, speed, and easy-to-use UI building blocks

---

## Features

- Modern window layout
- Draggable main window
- Tabs and sections
- Label, Button, Toggle, Slider, Dropdown, TextBox, ColorPicker, Keybind, Divider
- Live refresh support for dropdowns
- Title updates for labels
- Main color customization
- Background image support
- Background and image transparency controls
- Notification system
- Simple API that is easy to remember

---

## Installation

```lua
local AltisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/refs/heads/main/Source"))()
```

---

## Quick Start

```lua
local AltisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/refs/heads/main/Source"))()

local Window = AltisLib.CreateWindow("AltisLib Example", UDim2.new(0, 600, 0, 450))
Window:SetMainColor(Color3.fromRGB(235, 90, 40))
Window:SendNotification("AltisLib", "Library loaded successfully!", 3)

local MainTab = Window:CreateTab("Main")

MainTab:CreateLabel("Hello from AltisLib")
MainTab:CreateButton("Click Me", function()
    print("Button pressed")
end)
```

---

## Full Example

This example shows the full feature set used in the demo script.

```lua
-- AltisLib Demo
local AltisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/refs/heads/main/Source"))()

local Window = AltisLib.CreateWindow("Dear ImGui (ReGui) Small Remake Example", UDim2.new(0, 600, 0, 450))
Window:SetMainColor(Color3.fromRGB(235, 90, 40))
Window:SendNotification("Test Library", "Running full stress-test script...", 4)

-- =========================================================
-- TAB 1: CORE SETTINGS
-- =========================================================
local CoreTab = Window:CreateTab("Core Settings")

local TestLabel = CoreTab:CreateLabel("--- TEST UI TRANSPARENCY AND BACKGROUND ---")

CoreTab:CreateButton("Rename label above", function()
    TestLabel:SetTitle("New Title!")
end)

CoreTab:CreateButton("Enable Sample Background", function()
    Window:SetBackgroundImage("rbxassetid://111612290258829")
    Window:SendNotification("Background Image", "Background applied successfully!", 2)
end)

CoreTab:CreateButton("Remove Background", function()
    Window:SetBackgroundImage("")
    Window:SendNotification("Background Image", "Background removed!", 2)
end)

CoreTab:CreateSlider("UI Opacity", "Core_UiOpacity", 0, 100, 0, function(value)
    Window:SetBackgroundTransparency(value / 100)
end)

CoreTab:CreateSlider("Background Image Opacity", "Core_ImgOpacity", 0, 100, 0, function(value)
    Window:SetBackgroundImageTransparency(value / 100)
end)

CoreTab:CreateDivider()

CoreTab:CreateColorPicker("Change Accent Color", "Core_ThemeColor", Color3.fromRGB(235, 90, 40), function(newColor)
    Window:SetMainColor(newColor)
end)

CoreTab:CreateButton("Send Test Notification", function()
    Window:SendNotification("Test Alert", "Notifications are working correctly.", 3)
end)

-- =========================================================
-- TAB 2: COMBAT & AIM
-- =========================================================
local CombatTab = Window:CreateTab("Combat & Aim")

local AimbotSection = CombatTab:CreateSection("Aimbot Settings")

AimbotSection:CreateToggle("Enable Aimbot", "Aim_Enabled", false, function(state)
    print("Aimbot:", state)
end)

AimbotSection:CreateKeybind("Aim Hold Key", "Aim_Bind", Enum.KeyCode.E, function(key, isPressed)
    if isPressed then
        print("Holding:", key.Name)
    else
        print("Released:", key.Name)
    end
end)

AimbotSection:CreateSlider("Smoothness", "Aim_Smooth", 1, 30, 5, function(v)
    print("Smoothness:", v)
end)

AimbotSection:CreateSlider("FOV Radius", "Aim_Fov", 10, 800, 150, function(v)
    print("FOV:", v)
end)

AimbotSection:CreateColorPicker("FOV Circle Color", "Aim_FovColor", Color3.fromRGB(255, 255, 255), function(color)
    print("FOV color changed")
end)

local TargetSection = CombatTab:CreateSection("Targeting")

TargetSection:CreateDropdown(
    "Target Mode",
    "Aim_TargetMode",
    {"Nearest", "Lowest HP", "Highest Level", "Damaged"},
    "Nearest",
    function(selected)
        print("Target mode:", selected)
    end
)

TargetSection:CreateToggle("Team Check", "Aim_TeamCheck", true, function(state) end)
TargetSection:CreateToggle("Wall Check", "Aim_WallCheck", false, function(state) end)

-- =========================================================
-- TAB 3: VISUALS & ESP
-- =========================================================
local VisualsTab = Window:CreateTab("Visuals & ESP")

VisualsTab:CreateLabel("Test transparency for dropdowns and color pickers.")

local PlayerEspSec = VisualsTab:CreateSection("Player ESP")

PlayerEspSec:CreateToggle("Box ESP", "Esp_Box", false, function(s) end)
PlayerEspSec:CreateColorPicker("Box Color", "Esp_BoxColor", Color3.fromRGB(255, 0, 0), function(c) end)

PlayerEspSec:CreateToggle("Name ESP", "Esp_Name", false, function(s) end)
PlayerEspSec:CreateColorPicker("Name Color", "Esp_NameColor", Color3.fromRGB(255, 255, 255), function(c) end)

PlayerEspSec:CreateToggle("Tracers", "Esp_Tracers", false, function(s) end)
PlayerEspSec:CreateDropdown(
    "Tracer Origin",
    "Esp_TracerOrigin",
    {"Bottom", "Middle", "Top"},
    "Bottom",
    function(sel) end
)
PlayerEspSec:CreateColorPicker("Tracer Color", "Esp_TracerColor", Color3.fromRGB(0, 255, 255), function(c) end)

local WorldSec = VisualsTab:CreateSection("World Mods")
WorldSec:CreateToggle("Fullbright", "World_Bright", false, function(s) end)
WorldSec:CreateSlider("Ambient Time", "World_Time", 0, 24, 12, function(v) end)

-- =========================================================
-- TAB 4: MISC & TELEPORT
-- =========================================================
local MiscTab = Window:CreateTab("Misc & Teleport")

local PlayerModSec = MiscTab:CreateSection("Character Stats")

PlayerModSec:CreateSlider("WalkSpeed", "Mod_Speed", 16, 250, 16, function(v)
    pcall(function()
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end)
end)

PlayerModSec:CreateSlider("JumpPower", "Mod_Jump", 50, 500, 50, function(v)
    pcall(function()
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
    end)
end)

PlayerModSec:CreateToggle("Infinite Jump", "Mod_InfJump", false, function(state) end)

local TeleportSec = MiscTab:CreateSection("Waypoints")

local currentWaypoints = {"Main House", "Mining Area", "Weapon Shop"}

local WaypointDropdown = TeleportSec:CreateDropdown(
    "Select Teleport Point",
    "Misc_WpList",
    currentWaypoints,
    "Main House",
    function(selected)
        print("Teleporting to:", selected)
    end
)

local NewWpName = ""
TeleportSec:CreateTextBox("Save New Point Name", "Misc_NewWpBox", "Type a waypoint name...", function(text, enterPressed)
    NewWpName = text
    print("Saved temp name:", text)
end)

TeleportSec:CreateButton("Save Current Position to List", function()
    if NewWpName ~= "" then
        table.insert(currentWaypoints, NewWpName)
        WaypointDropdown:Refresh(currentWaypoints)
        Window:SendNotification("Success", "Added '" .. NewWpName .. "' to the dropdown!", 2)
    else
        Window:SendNotification("Warning", "Please type a waypoint name first!", 3)
    end
end)

-- =========================================================
-- TAB 5: STRESS TEST & SEARCH
-- =========================================================
local StressTab = Window:CreateTab("Stress & Search")

StressTab:CreateLabel("This tab contains many repeated elements.")
StressTab:CreateLabel("It is used to test scrolling and search behavior.")
StressTab:CreateLabel("Try searching for words like 'Button' or 'TextBox'.")

for i = 1, 10 do
    StressTab:CreateButton("Test Button " .. tostring(i), function()
        print("Stress button:", i)
    end)
end

StressTab:CreateDivider()

for i = 1, 5 do
    StressTab:CreateToggle("Extra Toggle " .. tostring(i), "Stress_Toggle_" .. tostring(i), false, function(s) end)
    StressTab:CreateTextBox("Extra TextBox " .. tostring(i), "Stress_Box_" .. tostring(i), "Type here...", function(t) end)
end

StressTab:CreateLabel("--- END OF DEMO SCRIPT ---")
```

---

## API Reference

### `AltisLib.CreateWindow(title, size)`

Creates a new window.

**Parameters**
- `title` — `string`
- `size` — `UDim2`

**Returns**
- `Window`

**Example**
```lua
local Window = AltisLib.CreateWindow("My Hub", UDim2.new(0, 600, 0, 450))
```

---

## Window Methods

### `Window:SetMainColor(color)`

Changes the main accent color used by the library.

**Parameters**
- `color` — `Color3`

**Example**
```lua
Window:SetMainColor(Color3.fromRGB(235, 90, 40))
```

### `Window:SetBackgroundImage(imageId)`

Sets the window background image.

**Parameters**
- `imageId` — `string`

**Example**
```lua
Window:SetBackgroundImage("rbxassetid://111612290258829")
```

### `Window:SetBackgroundTransparency(value)`

Changes the main background transparency.

**Parameters**
- `value` — `number` from `0` to `1`

**Example**
```lua
Window:SetBackgroundTransparency(0.35)
```

### `Window:SetBackgroundImageTransparency(value)`

Changes the background image transparency.

**Parameters**
- `value` — `number` from `0` to `1`

**Example**
```lua
Window:SetBackgroundImageTransparency(0.2)
```

### `Window:SendNotification(title, message, duration)`

Shows a notification on screen.

**Parameters**
- `title` — `string`
- `message` — `string`
- `duration` — `number`

**Example**
```lua
Window:SendNotification("Saved", "Your settings were applied.", 3)
```

### `Window:CreateTab(name)`

Creates a new tab and returns it.

**Parameters**
- `name` — `string`

**Returns**
- `Tab`

**Example**
```lua
local Tab = Window:CreateTab("Main")
```

---

## Tab Methods

### `Tab:CreateSection(title)`

Creates a collapsible section.

**Returns**
- `Section`

**Example**
```lua
local Section = Tab:CreateSection("Settings")
```
#### You can make elements in a Section

The following elements are supported inside a Section:

- Label
- Button
- Toggle
- Slider
- Dropdown
- TextBox
- ColorPicker
- Keybind
- Divider

#### Complete Section Example

```lua
local Section = Tab:CreateSection("Example Section")

local Label = Section:CreateLabel("Example Label")

Section:CreateButton("Button", function()
    print("Clicked")
end)

Section:CreateToggle("Toggle", "ToggleKey", false, function(state)
    print(state)
end)

Section:CreateSlider("Slider", "SliderKey", 0, 100, 50, function(value)
    print(value)
end)

local Dropdown = Section:CreateDropdown(
    "Dropdown",
    "DropdownKey",
    {"Option 1", "Option 2", "Option 3"},
    "Option 1",
    function(selected)
        print(selected)
    end
)

Section:CreateTextBox(
    "TextBox",
    "TextBoxKey",
    "Type here...",
    function(text)
        print(text)
    end
)

Section:CreateColorPicker(
    "Color Picker",
    "ColorKey",
    Color3.fromRGB(255,255,255),
    function(color)
        print(color)
    end
)

Section:CreateKeybind(
    "Keybind",
    "KeybindKey",
    Enum.KeyCode.E,
    function(key, pressed)
        print(key.Name, pressed)
    end
)

Section:CreateDivider()

Label:SetTitle("Updated Label")
Dropdown:Refresh({"New 1","New 2","New 3"})
```
### `Tab:CreateLabel(text)`

Creates a label.

**Returns**
- `Label`

**Example**
```lua
local Label = Tab:CreateLabel("Hello world")
```

### `Tab:CreateButton(text, callback)`

Creates a button.

**Callback**
- Called when the button is pressed.

**Example**
```lua
Tab:CreateButton("Print Hello", function()
    print("Hello")
end)
```

### `Tab:CreateToggle(text, key, default, callback)`

Creates a toggle switch.

**Parameters**
- `text` — `string`
- `key` — `string`
- `default` — `boolean`
- `callback` — function(state)

**Example**
```lua
Tab:CreateToggle("Enabled", "MyToggle", false, function(state)
    print(state)
end)
```

### `Tab:CreateSlider(text, key, min, max, default, callback)`

Creates a slider.

**Parameters**
- `text` — `string`
- `key` — `string`
- `min` — `number`
- `max` — `number`
- `default` — `number`
- `callback` — function(value)

**Example**
```lua
Tab:CreateSlider("Speed", "SpeedSlider", 0, 100, 16, function(value)
    print(value)
end)
```

### `Tab:CreateDropdown(text, key, options, default, callback)`

Creates a dropdown.

**Parameters**
- `text` — `string`
- `key` — `string`
- `options` — `table`
- `default` — `string`
- `callback` — function(selected)

**Returns**
- `Dropdown`

**Example**
```lua
local Dropdown = Tab:CreateDropdown("Mode", "ModeDropdown", {"A", "B", "C"}, "A", function(selected)
    print(selected)
end)
```

### `Tab:CreateTextBox(text, key, placeholder, callback)`

Creates a textbox.

**Parameters**
- `text` — `string`
- `key` — `string`
- `placeholder` — `string`
- `callback` — function(text, enterPressed)

**Example**
```lua
Tab:CreateTextBox("Name", "NameBox", "Enter name...", function(text)
    print(text)
end)
```

### `Tab:CreateColorPicker(text, key, defaultColor, callback)`

Creates a color picker.

**Parameters**
- `text` — `string`
- `key` — `string`
- `defaultColor` — `Color3`
- `callback` — function(color)

**Example**
```lua
Tab:CreateColorPicker("Accent", "AccentColor", Color3.fromRGB(255, 0, 0), function(color)
    print(color)
end)
```

### `Tab:CreateKeybind(text, key, defaultKey, callback)`

Creates a keybind input.

**Parameters**
- `text` — `string`
- `key` — `string`
- `defaultKey` — `Enum.KeyCode`
- `callback` — function(keyCode, isPressed)

**Example**
```lua
Tab:CreateKeybind("Open Menu", "MenuBind", Enum.KeyCode.RightShift, function(key, pressed)
    print(key.Name, pressed)
end)
```

### `Tab:CreateDivider()`

Creates a separator line.

**Example**
```lua
Tab:CreateDivider()
```

---

## Element Methods

### `Label:SetTitle(text)`

Updates a label title after it has been created.

**Example**
```lua
local Label = Tab:CreateLabel("Old Title")
Label:SetTitle("New Title")
```

### `Dropdown:Refresh(options)`

Replaces the dropdown option list.

**Example**
```lua
local Dropdown = Tab:CreateDropdown("Waypoints", "WpList", {"Base", "Shop"}, "Base", function() end)
Dropdown:Refresh({"Base", "Shop", "Mine"})
```

---

## Usage Notes

- Use `BackgroundTransparency` values between `0` and `1`.
- Use `BackgroundImageTransparency` values between `0` and `1`.
- `CreateDropdown` returns a dropdown object so you can refresh its options later.
- `CreateLabel` returns a label object so you can update its title later.
- `SendNotification` is useful for status messages and confirmations.
- Keep callback logic short and safe inside UI handlers.

---

## Credits

- AltisLib by **Altis-DEV**
- Demo inspired by modern ImGui-style Roblox interfaces
- README structure written for clarity and easy reference

