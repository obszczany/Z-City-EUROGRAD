-- Managed Workshop dependencies for the EUROGRAD community build.
-- Third-party files are not copied into this repository. Change the archived
-- convars in server.cfg and restart the server to enable optional profiles.

local gameplay = {
	"3782848810", -- Manhunt Executions
	"3793099213", -- FPS & Stability Boost (also exposed under Esc)
	"3767548087", -- Door Knock
	"3737887777", -- Bind Menu
	"3675753816", -- Clothing+
	"3690854231", -- Loadout Presets
	"3721806933", -- Explosive Vest (includes its content)
	"3701366943", -- Colorable Clothes + Accessories
	"3196355387", -- Remove Voice Chat Icons
	"3709219849", -- Unconsciousness Meter
	"3695822803", -- Better Mapvote
	"3695863063", -- Improved Scoreboard
	"3714182343", -- Shootable Door Handles
	"3712846898", -- Attach Anything
	"3737422346", -- First Spawn Appearance Fix
	"3740174900"  -- TTT Trap Activator
}

local compatibility = {
	"3780178294", -- original Viewfinder required by the Z-City fix
	"3785356208", -- Viewfinder FIX
	"3757876289"  -- Drop&Kick FIXED; overrides core fake-camera code
}

local performance = {
	"1620875048", -- Bucket's Optimizations
	"2982286549", -- Server & Client Optimization
	"3105962404", -- Performant Render
	"793317003",  -- Widgets Disabler (author marks it obsolete)
	"1762151370"  -- Improved FPS Booster
}

local developerTools = {
	"2403043112", -- Lua Patcher; changes Lua error behaviour
	"682765484",  -- Hook Lag Finder
	"368857085"   -- Hook Conflict Finder
}

local cvCompatibility = CreateConVar("eurograd_build_compatibility", "0", FCVAR_ARCHIVE, "Download optional camera compatibility addons")
local cvPerformance = CreateConVar("eurograd_build_performance", "0", FCVAR_ARCHIVE, "Download optional performance addons")
local cvDeveloper = CreateConVar("eurograd_build_developer_tools", "0", FCVAR_ARCHIVE, "Download invasive diagnostic addons")

local function addGroup(group)
	for _, workshopID in ipairs(group) do resource.AddWorkshop(workshopID) end
end

addGroup(gameplay)
if cvCompatibility:GetBool() then addGroup(compatibility) end
if cvPerformance:GetBool() then addGroup(performance) end
if cvDeveloper:GetBool() then addGroup(developerTools) end
