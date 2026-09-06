local ClientSettings = {}
ClientSettings.BlurBG = nil
ClientSettings.DrawWeaponNames = nil
ClientSettings.EnableSwapping = nil
ClientSettings.InvertPickup = nil
ClientSettings.MenuFPS = nil
ClientSettings.PlaySounds = nil
ClientSettings.PreferSprites = nil

local cvar_default_case_size = CreateConVar("case_sh_default_size", "s", {FCVAR_REPLICATED})

function ClientSettings:Populate(panel)
	self.BlurBG = panel:CheckBox("Blur Case Background", "case_cl_blur_bg")
	self.DrawWeaponNames = panel:CheckBox("Draw Weapon Names", "case_cl_draw_weapon_names")
	self.EnableSwapping = panel:CheckBox("Enable Swapping", "case_cl_enable_swapping")
	self.MenuFPS = panel:TextEntry("Menu FPS")
	self.MenuFPS.OnChange = function()
		local fps = tonumber(self.MenuFPS:GetText())
		if fps == nil then
			fps = 40
		end
		GetConVar("case_cl_menu_fps"):SetInt(fps)
	end

	self.MenuFPS:SetText(GetConVar("case_cl_menu_fps"):GetString())
	self.InvertPickup = panel:CheckBox("Invert Pickup Mode", "case_cl_invert_pickup")
	panel:ControlHelp("If off, using an item will use it otherwise holding walk (alt) will pick it up\nIf on, using an item will pick it up while holding walk will try to use it")

	self.PickupMode = panel:ComboBox("Pickup Mode", "case_cl_pickup_mode")
	self.PickupMode:AddChoice("Walk over to pickup items", 0)
	self.PickupMode:AddChoice("Use to pickup, unless in vehicle", 1)
	self.PickupMode:AddChoice("Use to pickup", 2)
	panel:ControlHelp("This setting can be overridden by the server\nAlso Walk over to pickup will only work with items that would do that normally without this mod")


	self.PlaySounds = panel:ComboBox("Play Sounds", "case_cl_play_sounds")
	self.PlaySounds:AddChoice("Disable Sounds", 0)
	self.PlaySounds:AddChoice("Enable Sounds", 1)
	self.PlaySounds:AddChoice("Enable Sounds (Alt. sounds)", 2)

	self.ShowEditButton = panel:CheckBox("Show edit button", "case_cl_show_edit")

	self.PreferSprites = panel:ComboBox("Show Sprites", "case_cl_prefer_sprites")
    self.PreferSprites:AddChoice("Mode A", 0)
    self.PreferSprites:AddChoice("Mode B", 1)
    self.PreferSprites:AddChoice("Always", 2)
	panel:ControlHelp("A) If an item is set to use a sprite it'll use either a sprite or hud icon if one exists\n")
	panel:ControlHelp("B) Items will always use a sprite ONLY if one exists regardless of the item's settings\n")
	panel:ControlHelp("Always) All items will try to use either a sprite if one exists or hud icon\n")

	panel:KeyBinder("Quick Drop", "case_quick_drop")
	panel:ControlHelp("Drops 1 at a time, hold shift to drop an entire stack")
	panel:KeyBinder("Quick Use", "case_quick_use")
	panel:KeyBinder("Quick Edit", "case_quick_edit")
	panel:ControlHelp("All of these binds for IN the inventory")
end

hook.Add("PopulateToolMenu", "CaseAddSettings", function()
	spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseSettings", "#Client Settings", "", "", function(panel)
		ClientSettings.Panel = panel
		ClientSettings:Populate(panel)
	end)
end)