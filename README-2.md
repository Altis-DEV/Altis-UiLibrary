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
- Label, Button, Toggle, Slider, Dropdown, MultiDropdown, TextBox, ColorPicker, Keybind, Divider
- Live refresh support for Dropdown and MultiDropdown
- Dynamic label updates
- TextBox text clearing support
- Main color customization
- Background image support
- Background and image transparency controls
- Notification system
- Clean API that is easy to remember


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

This example follows the **AltisLib V3.7 Showcase** style and demonstrates the current API surface, including labels, buttons, toggles, sliders, dropdowns, sections, color pickers, keybinds, textboxes, background settings, and scrollbar stress testing.

```lua
-- AltisLib V3.7 - Official Full Showcase & Testing Script
local AltisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/refs/heads/main/Source"))()

local Window = AltisLib.CreateWindow("AltisLib Showcase V3.7", UDim2.new(0, 550, 0, 400))
Window:SetMainColor(Color3.fromRGB(85, 170, 255))
Window:SetBackgroundTransparency(0.15)
Window:SendNotification("AltisLib Loaded", "Welcome to the V3.7 Showcase!", 5)

local BasicTab = Window:CreateTab("Basic Elements")

local StatusLabel = BasicTab:CreateLabel("Status: Waiting for input...")
BasicTab:CreateDivider()

BasicTab:CreateButton("Update Status Label", function()
    StatusLabel:SetText("Status: Button clicked at " .. tostring(os.date("%X")))
    Window:SendNotification("Button Clicked", "The label above has been updated.", 3)
    print("[AltisLib] Button was clicked.")
end)

BasicTab:CreateToggle("Enable Auto-Farm", false, function(state)
    print("[AltisLib] Toggle state changed to:", state)
end)

BasicTab:CreateSlider("WalkSpeed", 16, 100, 16, function(value)
    print("[AltisLib] Slider value changed to:", value)
    pcall(function()
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end)
end)

local NameInput = BasicTab:CreateTextBox("Target Player", "Enter name...", function(text, enterPressed)
    if enterPressed then
        print("[AltisLib] TextBox submitted:", text)
        Window:SendNotification("Target Selected", "Locked on: " .. text, 3)
    end
end)

BasicTab:CreateButton("Clear TextBox", function()
    NameInput:SetText("")
end)

local SelectionTab = Window:CreateTab("Selectors")

SelectionTab:CreateLabel("Standard Dropdown Testing:")

local Weapons = {"Sword", "Pistol", "Shotgun", "Sniper", "Rocket", "Knife"}
local WeaponDropdown = SelectionTab:CreateDropdown("Equip Weapon", Weapons, "Sword", function(selected)
    print("[AltisLib] Dropdown selected:", selected)
end)

SelectionTab:CreateButton("Refresh Weapon List", function()
    WeaponDropdown:Refresh({"Updated_Gun1", "Updated_Gun2", "Updated_Gun3"})
    Window:SendNotification("Refreshed", "Single Dropdown updated.", 2)
end)

SelectionTab:CreateDivider()
SelectionTab:CreateLabel("Multi-Dropdown Testing:")

local ESPFeatures = {"Boxes", "Names", "Health", "Distance", "Tracers", "Skeleton"}
local ESPDropdown = SelectionTab:CreateMultiDropdown("ESP Settings", ESPFeatures, {"Boxes", "Names"}, function(selectedTable)
    print("[AltisLib] Current MultiDropdown selections:")
    for _, feature in ipairs(selectedTable) do
        print(" - " .. feature)
    end
end)

SelectionTab:CreateButton("Refresh ESP List", function()
    ESPDropdown:Refresh({"Enemies", "Teammates", "Loot", "Vehicles"})
    Window:SendNotification("Refreshed", "Multi Dropdown updated.", 2)
end)

local AdvancedTab = Window:CreateTab("Advanced")

local VisualSection = AdvancedTab:CreateSection("Visual Settings")
VisualSection:CreateColorPicker("Accent Color", Color3.fromRGB(85, 170, 255), function(color)
    print("[AltisLib] ColorPicker changed to:", color)
    Window:SetMainColor(color)
end)

VisualSection:CreateColorPicker("ESP Box Color", Color3.fromRGB(255, 50, 50), function(color)
    print("[AltisLib] ESP Color changed.")
end)

local CombatSection = AdvancedTab:CreateSection("Combat Settings")
CombatSection:CreateKeybind("Aimbot Hotkey", Enum.KeyCode.E, function(key, isPressed)
    if isPressed then
        print("[AltisLib] Aimbot triggered by key:", key.Name)
    else
        print("[AltisLib] Aimbot keybind changed to:", key.Name)
    end
end)

local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateLabel("Background Configuration:")

SettingsTab:CreateSlider("UI Transparency", 0, 100, 15, function(value)
    Window:SetBackgroundTransparency(value / 100)
end)

SettingsTab:CreateDivider()

SettingsTab:CreateTextBox("Image Asset ID", "rbxassetid://10459322831", function(text, enterPressed)
    if enterPressed then
        Window:SetBackgroundImage(text)
        Window:SendNotification("Background Updated", "Loaded image asset.", 3)
    end
end)

SettingsTab:CreateSlider("Image Transparency", 0, 100, 50, function(value)
    Window:SetBackgroundImageTransparency(value / 100)
end)

SettingsTab:CreateDivider()
SettingsTab:CreateLabel("Scrollbar Stress Test:")

for i = 1, 20 do
    SettingsTab:CreateButton("Dummy Button " .. tostring(i), function()
        print("Clicked dummy button", i)
    end)
end
```


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

Creates a **Section**, a container used to organize related UI elements inside a tab.

Sections are useful when a tab has many controls. They keep the interface clean by grouping related options together. A Section is not just visual spacing — it is a container where you can create UI elements exactly like you would inside a tab.

**Returns**
- `Section`

**Example**
```lua
local Section = Tab:CreateSection("Combat Settings")
```

#### You can make elements in a Section

Everything below can be created inside a Section:

- Label
- Button
- Toggle
- Slider
- Dropdown
- MultiDropdown
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

Section:CreateToggle("Toggle", false, function(state)
    print(state)
end)

Section:CreateSlider("Slider", 0, 100, 50, function(value)
    print(value)
end)

local Dropdown = Section:CreateDropdown(
    "Dropdown",
    {"Option 1", "Option 2", "Option 3"},
    "Option 1",
    function(selected)
        print(selected)
    end
)

local MultiDropdown = Section:CreateMultiDropdown(
    "MultiDropdown",
    {"A", "B", "C"},
    {"A", "C"},
    function(selectedTable)
        print("Multi selections:")
        for _, item in ipairs(selectedTable) do
            print(item)
        end
    end
)

Section:CreateTextBox(
    "TextBox",
    "Type here...",
    function(text, enterPressed)
        print(text, enterPressed)
    end
)

Section:CreateColorPicker(
    "Color Picker",
    Color3.fromRGB(255, 255, 255),
    function(color)
        print(color)
    end
)

Section:CreateKeybind(
    "Keybind",
    Enum.KeyCode.E,
    function(key, pressed)
        print(key.Name, pressed)
    end
)

Section:CreateDivider()

Label:SetText("Updated Label")
Dropdown:Refresh({"New 1", "New 2", "New 3"})
MultiDropdown:Refresh({"X", "Y", "Z"})
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

### `Tab:CreateToggle(text, default, callback)`

Creates a toggle switch.

**Parameters**
- `text` — `string`
- `default` — `boolean`
- `callback` — function(state)

**Example**
```lua
Tab:CreateToggle("Enabled", false, function(state)
    print(state)
end)
```

### `Tab:CreateSlider(text, min, max, default, callback)`

Creates a slider.

**Parameters**
- `text` — `string`
- `min` — `number`
- `max` — `number`
- `default` — `number`
- `callback` — function(value)

**Example**
```lua
Tab:CreateSlider("Speed", 0, 100, 16, function(value)
    print(value)
end)
```

### `Tab:CreateDropdown(text, options, default, callback)`

Creates a dropdown.

**Parameters**
- `text` — `string`
- `options` — `table`
- `default` — `string`
- `callback` — function(selected)

**Returns**
- `Dropdown`

**Example**
```lua
local Dropdown = Tab:CreateDropdown("Mode", {"A", "B", "C"}, "A", function(selected)
    print(selected)
end)
```

### `Tab:CreateMultiDropdown(text, options, defaultSelections, callback)`

Creates a multi-select dropdown.

**Parameters**
- `text` — `string`
- `options` — `table`
- `defaultSelections` — `table`
- `callback` — function(selectedTable)

**Returns**
- `MultiDropdown`

**Example**
```lua
local MultiDropdown = Tab:CreateMultiDropdown(
    "ESP Settings",
    {"Boxes", "Names", "Health"},
    {"Boxes", "Names"},
    function(selectedTable)
        for _, item in ipairs(selectedTable) do
            print(item)
        end
    end
)
```

**Refresh Example**
```lua
MultiDropdown:Refresh({"Enemies", "Teammates", "Loot"})
```

### `Tab:CreateTextBox(text, placeholder, callback)`

Creates a textbox.

**Parameters**
- `text` — `string`
- `placeholder` — `string`
- `callback` — function(text, enterPressed)

**Example**
```lua
Tab:CreateTextBox("Name", "Enter name...", function(text, enterPressed)
    print(text)
end)
```

### `Tab:CreateColorPicker(text, defaultColor, callback)`

Creates a color picker.

**Parameters**
- `text` — `string`
- `defaultColor` — `Color3`
- `callback` — function(color)

**Example**
```lua
Tab:CreateColorPicker("Accent", Color3.fromRGB(255, 0, 0), function(color)
    print(color)
end)
```

### `Tab:CreateKeybind(text, defaultKey, callback)`

Creates a keybind input.

**Parameters**
- `text` — `string`
- `defaultKey` — `Enum.KeyCode`
- `callback` — function(keyCode, isPressed)

**Example**
```lua
Tab:CreateKeybind("Open Menu", Enum.KeyCode.RightShift, function(key, pressed)
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

### `Label:SetText(text)`

Updates the text of a label after it has been created.

**Example**
```lua
local Label = Tab:CreateLabel("Old Title")
Label:SetText("New Title")
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

---

## Version 3.7 Notes

The README is written to match the **AltisLib V3.7 showcase style**.

Important UI patterns used in V3.7:

- `Label:SetText(...)` updates label text dynamically.
- `Dropdown:Refresh(...)` replaces dropdown options at runtime.
- `MultiDropdown:Refresh(...)` replaces multi-select options at runtime.
- `Section` works as a container for all standard elements.
- Background transparency and image transparency accept values from `0` to `1`.
- `SendNotification(...)` is useful for runtime feedback and testing.
