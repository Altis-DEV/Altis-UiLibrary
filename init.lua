-- https://github.com/Altis-DEV/Altis-UiLibrary/blob/main/init.lua

local BASE_URL =
	"https://raw.githubusercontent.com/Altis-DEV/Altis-UiLibrary/main/"

local Cache = {}

--==============================================================
-- MODULE LOADER
--==============================================================

local function Load(Path)
	if Cache[Path] ~= nil then
		return Cache[Path]
	end

	local Source =
		game:HttpGet(
			BASE_URL .. Path
		)

	local Chunk, CompileError =
		loadstring(Source)

	assert(
		Chunk,
		"Failed to compile module: "
			.. Path
			.. "\n"
			.. tostring(CompileError)
	)

	local Success, Result =
		pcall(Chunk)

	assert(
		Success,
		"Failed to execute module: "
			.. Path
			.. "\n"
			.. tostring(Result)
	)

	Cache[Path] =
		Result

	return Result
end

--==============================================================
-- CORE
--==============================================================

local Core =
	Load("src/Core.lua")

--==============================================================
-- IMGUI
--==============================================================

local ImGui = {
	Core = Core,

	Windows = {},

	Load = Load,

	Animations =
		Core.Animations,

	Animation =
		Core.Animation,

	UIAssetId =
		Core.UIAssetId,

	NoWarnings =
		Core.NoWarnings,
}

--==============================================================
-- CORE API
--==============================================================

function ImGui:Warn(...)
	return Core:Warn(...)
end

function ImGui:CreateInstance(...)
	return Core:CreateInstance(...)
end

function ImGui:Concat(...)
	return Core:Concat(...)
end

function ImGui:GetName(...)
	return Core:GetName(...)
end

function ImGui:GetPointerPosition(...)
	return Core:GetPointerPosition(...)
end

function ImGui:GetAnimation(...)
	return Core:GetAnimation(...)
end

function ImGui:Tween(...)
	return Core:Tween(...)
end

function ImGui:ApplyAnimations(...)
	return Core:ApplyAnimations(...)
end

function ImGui:HeaderAnimate(...)
	return Core:HeaderAnimate(...)
end

function ImGui:ApplyColors(...)
	return Core:ApplyColors(...)
end

function ImGui:CheckStyles(...)
	return Core:CheckStyles(...)
end

function ImGui:MergeMetatables(...)
	return Core:MergeMetatables(...)
end

function ImGui:ConnectHover(...)
	return Core:ConnectHover(...)
end

function ImGui:ApplyWindowSelectEffect(...)
	return Core:ApplyWindowSelectEffect(...)
end

function ImGui:SetWindowProps(...)
	return Core:SetWindowProps(
		self.Windows,
		...
	)
end

--==============================================================
-- PREFABS
--==============================================================

function ImGui:FetchUI()
	local CacheName =
		"DepsoImGui"

	if _G[CacheName] then
		self:Warn(
			"Prefabs loaded from Cache"
		)

		return _G[CacheName]
	end

	local UI

	if not Core.IsStudio then
		UI =
			game:GetObjects(
				self.UIAssetId
			)[1]
	else
		local UIName =
			"DepsoImGui"

		UI =
			Core.PlayerGui:FindFirstChild(
				UIName
			)
			or script:FindFirstChild(
				UIName
			)
	end

	assert(
		UI,
		"ImGui: Failed to load DepsoImGui prefab"
	)

	_G[CacheName] =
		UI

	return UI
end

local UI =
	ImGui:FetchUI()

local Prefabs =
	UI:WaitForChild("Prefabs")

Prefabs.Visible =
	false

ImGui.Prefabs =
	Prefabs

--==============================================================
-- SCREEN GUI
--==============================================================

local GuiParent =
	Core.IsStudio
	and Core.PlayerGui
	or Core.Services.CoreGui

ImGui.ScreenGui =
	ImGui:CreateInstance(
		"ScreenGui",
		GuiParent,
		{
			DisplayOrder = 9999,
			ResetOnSpawn = false,
		}
	)

ImGui.FullScreenGui =
	ImGui:CreateInstance(
		"ScreenGui",
		GuiParent,
		{
			DisplayOrder = 99999,
			ResetOnSpawn = false,
			ScreenInsets =
				Enum.ScreenInsets.None,
		}
	)

--==============================================================
-- WINDOW
--==============================================================

local WindowModule =
	Load("src/Window/init.lua")

function ImGui:CreateWindow(Config)
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
