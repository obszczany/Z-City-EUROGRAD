AddCSLuaFile()

CASE_INVENTORY = true
CASE_INVENTORY_STACK = 32
CASE_INVENTORY_DEBUG = false

CASE_SIZES = {
	S = {10, 6},
	M = {11, 7},
	L = {12, 8},
	XL = {15, 8},
	XXL = {15, 10}
}

CASE_INVENTORY_SIZE_DEFAULT = table.Copy(CASE_SIZES.S)
--[[
	For each item stored in inventory (in order)
	uint8 X
	uint8 Y
	uint1 Rotated
]]
CASE_COMMAND_SYNC = 1

--[[
	uint16 invId
	uint16 count
	uint1 sync
]]
CASE_COMMAND_DROP = 2
--[[
	uint16 invId
	uint1 sync
]]
CASE_COMMAND_USE = 3
--[[
	uint16 srcID
	uint16 destID
]]
CASE_COMMAND_MERGE = 4
--[[
	uint16 itemID
	bool delete
	string modelName
	int16 sizeW
	int16 sizeH
	float scale
	float offsetX
	float offsetY
	float offsetZ
	float rotationX
	float rotationY
	float rotationZ
	int8 skin
]]
CASE_COMMAND_SYNC_OVERRIDES = 5

--[[
	No args :)
	Is resticted to one time per player
	(Player.HasSyncedOverrides)
]]
CASE_COMMAND_REQUEST_OVERRIDES = 6

--[[
	string itemName
	int8 mode

	FOR CASE_ITEM_CREATE
	string printName
	string modelName

	FOR CASE_ITEM_EDIT only
	string printName
	uint8 itemType
	uint8 useCondition
]]
CASE_COMMAND_SYNC_ITEM = 7

--[[
	uint16 recipeID
]]
CASE_COMMAND_CRAFT = 8

--[[
	uint16 recipeID (0 == New Recipe)
	table recipe
]]
CASE_COMMAND_MODIFY_RECIPE = 9




-- Server -> Client commands
CASE_EVENT_SYNC = 1
CASE_EVENT_SYNC_IDS = 2
CASE_EVENT_SYNC_OVERRIDE = 3
CASE_EVENT_ON_PICKUP = 4
CASE_EVENT_SYNC_CUSTOM_ITEMS = 5
CASE_EVENT_AUTO_GEN_WEAPONS = 6
CASE_EVENT_SYNC_RECIPE = 7
CASE_EVENT_FINISH_MODIFY_RECIPE = 8

-- Modes for SYNC_ITEM
CASE_ITEM_CREATE = 0
CASE_ITEM_REMOVE = 1
CASE_ITEM_EDIT = 2
--

CaseInventory = {}
CaseInventory.ItemRegister = {}
CaseInventory.RegisterOverrides = {}
CaseInventory.Inventories = {}
CaseInventory.PickupQueue = {}
CaseInventory.CraftingRecipes = {}
CaseInventory.GhostRecipes = {}


if CLIENT then
	CaseInventory.CraftingLookup = {}
	CaseInventory.CraftEdit = {
		Panel = nil,
		NeedsUpdating = false,
		UpdateHash = ""
	}
end

CASE_AUTOGEN_WEAPON = 1
CASE_AUTOGEN_AMMO = 2

--[[[
	Key/Values:
		Type = uint4
		Name = string
		PrintName = string
		Model = string
		Scale = float
		Rotation = 3x float
		Size = 2x int8
		Count = uint16
		AmmoID = int16
]]
CaseInventory.AutoGenerateInfo = {}

if CLIENT then
	CaseInventory.ObtainedAutoGenerate = false
end
---Types:
---1 -> Generic
---2 -> Consumable
---3 -> Glow Only
CaseInventory.CustomItems = {}

if SERVER then
	CaseInventory.CustomItemOrder = {}
end


CASE_CUSTOM_GENERIC = 1
CASE_CUSTOM_CONSUMABLE = 2
CASE_CUSTOM_GLOW_ONLY = 3

CASE_CUSTOM_USE_ALWAYS = 1
CASE_CUSTOM_USE_HEALTH = 2
CASE_CUSTOM_USE_ARMOR = 3

CaseInventory.CustomItemStart = -1

if SERVER then
	-- To allow saving overrides that don't exist any more
	CaseInventory.GhostOverrides = {}
end

if CLIENT then
	CaseInventory.ItemRegisterLayout = {}
	CaseInventory.ItemRegisterApply = false
	CaseInventory.Ready = false
end



local server = {
	"server/sv_cvar.lua",
	"server/sv_hooks.lua",
	"server/sv_player.lua",
	"server/sv_network.lua",
	"server/sv_zcity.lua"
}

local client = {
	"client/cl_theme.lua",
	"client/cl_player.lua",
	--"client/vgui/cl_gui.lua",
	--"client/vgui/cl_invpanel.lua",
	"client/cl_network.lua",
	"client/cl_guifont.lua",
	"client/cl_editor.lua",
	"client/cl_settings.lua",
	"client/cl_sv_settings.lua",
	"client/cl_itemcreator.lua",
	"client/cl_crafteditor.lua",


	"vgui/cl_gui.lua",
	"vgui/inventory/cl_invpanel.lua",
	"vgui/inventory/cl_contextbutton.lua",
	"vgui/inventory/cl_contextmenu.lua",
	"vgui/inventory/cl_editbutton.lua",
	"vgui/inventory/cl_exitbutton.lua",

	"vgui/cl_gui_crafting.lua",
	"vgui/crafting/cl_craftpanel.lua",
	"vgui/crafting/cl_recipebutton.lua",
	"vgui/crafting/cl_recipelist.lua",
	"vgui/crafting/cl_craftzone.lua",
	"vgui/cl_button_generic.lua",
	"vgui/cl_textbox.lua",



	"vgui/cl_font.lua",
	"client/cl_zcity.lua"
}

local shared = {
	"shared/sh_api.lua",
	"shared/sh_items.lua",
	"shared/sh_hooks.lua",
	"item_list.lua",
	"crafting_list.lua"
}

local function _client(files)

	for _, v in ipairs(files) do
		if CLIENT then
			include("playercase/" .. v)
		end

		if SERVER then
			AddCSLuaFile("playercase/" .. v)
		end

		if CASE_INVENTORY_DEBUG then
			print("Adding client file " .. v)
		end
	end
end

local function _server(files)
	for _, v in ipairs(files) do
		if SERVER then
			include("playercase/" .. v)
		end


		if CASE_INVENTORY_DEBUG then
			print("Adding server file " .. v)
		end
	end
end


if SERVER then
	_server(server)
	_server(shared)
end

_client(client)
_client(shared)

if SERVER then
	-- uh remind me to merge these all into like one string please
	util.AddNetworkString("CaseNetMsg") -- The thing

	resource.AddSingleFile( "resource/fonts/RedHatMono-SemiBold.ttf" )
end
