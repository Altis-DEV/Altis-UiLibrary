-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/init.lua

local BASE_URL =
	"https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/main/"

local Cache = {}

local function Load(Path)
	if Cache[Path] ~= nil then
		return Cache[Path]
	end

	local Source = game:HttpGet(BASE_URL .. Path)

	local Chunk, CompileError = loadstring(Source)

	assert(
		Chunk,
		"Failed to compile module: "
			.. Path
			.. "\n"
			.. tostring(CompileError)
	)

	local Success, Result = pcall(Chunk)

	assert(
		Success,
		"Failed to execute module: "
			.. Path
			.. "\n"
			.. tostring(Result)
	)

	Cache[Path] = Result

	return Result
end

--// Core
local Core = Load("src/Core.lua")

--// Main API
local ImGui = {
	Core = Core,
	Windows = {},

	Load = Load,

	Animations = {
		Buttons = {
			MouseEnter = {
				BackgroundTransparency = 0.5,
			},

			MouseLeave = {
				BackgroundTransparency = 0.7,
			},
		},

		Tabs = {
			MouseEnter = {
				BackgroundTransparency = 0.5,
			},

			MouseLeave = {
				BackgroundTransparency = 1,
			},
		},

		Inputs = {
			MouseEnter = {
				BackgroundTransparency = 0,
			},

			MouseLeave = {
				BackgroundTransparency = 0.5,
			},
		},

		WindowBorder = {
			Selected = {
				Transparency = 0,
				Thickness = 1,
			},

			Deselected = {
				Transparency = 0.7,
				Thickness = 1,
			},
		},
	},

	Animation = Core.Animation,
	UIAssetId = Core.UIAssetId,

	NoWarnings = Core.NoWarnings,
}

--// Helpers
function ImGui:Warn(...)
	return Core:Warn(...)
end

function ImGui:CreateInstance(ClassName, Parent, Properties)
	return Core:CreateInstance(
		ClassName,
		Parent,
		Properties
	)
end

function ImGui:Concat(List, Separator)
	return Core:Concat(List, Separator)
end

function ImGui:GetPointerPosition()
	return Core:GetPointerPosition()
end

--// Prefab loading
function ImGui:FetchUI()
	local CacheName = "DepsoImGui"

	if _G[CacheName] then
		self:Warn("Prefabs loaded from Cache")

		return _G[CacheName]
	end

	local UI

	if not Core.IsStudio then
		UI = game:GetObjects(self.UIAssetId)[1]
	else
		local UIName = "DepsoImGui"

		UI =
			Core.PlayerGui:FindFirstChild(UIName)
			or script:FindFirstChild(UIName)
	end

	assert(
		UI,
		"ImGui: Failed to load DepsoImGui prefab"
	)

	_G[CacheName] = UI

	return UI
end

local UI = ImGui:FetchUI()

local Prefabs = UI:WaitForChild("Prefabs")

Prefabs.Visible = false

ImGui.Prefabs = Prefabs

--// ScreenGui
local Parent =
	Core.IsStudio
	and Core.PlayerGui
	or Core.Services.CoreGui

ImGui.ScreenGui = ImGui:CreateInstance(
	"ScreenGui",
	Parent,
	{
		DisplayOrder = 9999,
		ResetOnSpawn = false,
	}
)

ImGui.FullScreenGui = ImGui:CreateInstance(
	"ScreenGui",
	Parent,
	{
		DisplayOrder = 99999,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
	}
)

--// Window
local WindowModule =
	Load("src/Window/init.lua")

ImGui.CreateWindow = function(self, Config)
	return WindowModule.new(
		{
			ImGui = self,
			Core = Core,
			Prefabs = self.Prefabs,
			Load = Load,
		},
		Config
	)
end

return ImGui
