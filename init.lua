--[[
    ReGui Rework
    init.lua

    Source-loader entry point.

    Usage:

    local ReGui = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/USERNAME/REPO/main/init.lua"
    ))()

    local Window = ReGui:CreateWindow({
        Title = "My Window",
        Size = UDim2.fromOffset(500, 350),
    })
]]

local ReGui = {}

--==================================================
-- Configuration
--==================================================

local BASE_URL =
    "https://raw.githubusercontent.com/USERNAME/REPO/main/"

--==================================================
-- Internal loader
--==================================================

local function Load(path)
    local url = BASE_URL .. path

    local success, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        error(
            ("ReGui: Failed to download '%s'\n%s")
            :format(path, tostring(source)),
            2
        )
    end

    if typeof(source) ~= "string" or source == "" then
        error(
            ("ReGui: '%s' returned empty source")
            :format(path),
            2
        )
    end

    local chunk, compileError = loadstring(source)

    if not chunk then
        error(
            ("ReGui: Failed to compile '%s'\n%s")
            :format(path, tostring(compileError)),
            2
        )
    end

    local ok, result = pcall(chunk)

    if not ok then
        error(
            ("ReGui: Failed to execute '%s'\n%s")
            :format(path, tostring(result)),
            2
        )
    end

    return result
end

--==================================================
-- Load modules
--==================================================

local Theme = Load("src/Theme.lua")
local Window = Load("src/Window.lua")

--==================================================
-- Public properties
--==================================================

ReGui.Theme = Theme
ReGui.Window = Window

--==================================================
-- CreateWindow
--==================================================

function ReGui:CreateWindow(config)
    return Window.CreateWindow(Theme, config)
end

--==================================================
-- Theme helpers
--==================================================

function ReGui:GetTheme(name)
    name = name or "Default"

    local theme = Theme[name]

    if typeof(theme) ~= "table" then
        error(
            ("ReGui: Theme '%s' does not exist")
            :format(tostring(name)),
            2
        )
    end

    return theme
end

--==================================================
-- Version
--==================================================

ReGui.Version = "0.1.0"

--==================================================
-- Return
--==================================================

return ReGui
