-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/example.lua

local ImGui = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/main/src/ImGui.lua"
))()

local Window = ImGui:CreateWindow({
	Title = "Altis UI - Mobile Test",
	Size = UDim2.fromOffset(520, 380),
})

--==============================================================
-- MANY TABS
--==============================================================

for TabIndex = 1, 20 do
	local Tab = Window:CreateTab({
		Name = "Tab " .. TabIndex,
		Visible = TabIndex == 1,
	})

	-- Header test
	Tab:Label({
		Label = "Tab " .. TabIndex,
		Size = UDim2.new(1, 0, 0, 28),
	})

	-- Give every tab a different amount of content.
	for ItemIndex = 1, TabIndex * 8 do
		Tab:Label({
			Label = string.format(
				"Tab %d  |  Item %d / %d",
				TabIndex,
				ItemIndex,
				TabIndex * 8
			),
			Size = UDim2.new(1, 0, 0, 26),
		})
	end
end

print("========================================")
print("ALTIS UI MOBILE REWORK TEST")
print("========================================")
print("Window:", Window.Window)
print("Window AbsoluteSize:", Window.Window.AbsoluteSize)
print("Toolbar AbsoluteSize:", Window.Window.Content.ToolBar.AbsoluteSize)
print("Body AbsoluteSize:", Window.Window.Content.Body.AbsoluteSize)
print("Tabs: 20")
print("========================================")
print("PC:")
print("- Drag from the title bar")
print("- Resize from the bottom-right corner")
print("- Scroll the toolbar horizontally")
print("- Scroll tab content vertically")
print("========================================")
print("MOBILE:")
print("- Drag from an empty area of the title bar")
print("- Swipe the toolbar horizontally")
print("- Swipe the tab content vertically")
print("- Resize from the bottom-right corner")
print("- Slider/Button/TextBox interactions must not move the window")
print("========================================")
