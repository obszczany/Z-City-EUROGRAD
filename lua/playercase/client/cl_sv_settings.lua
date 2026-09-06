local ServerSettings = {}
ServerSettings.DropExtraAmmo = nil
ServerSettings.DropOnDeath = nil
ServerSettings.Frame0Pickup = nil
ServerSettings.PickupMode = nil
ServerSettings.DefaultCaseSize = nil
ServerSettings.CustomCaseSize = nil
ServerSettings.AutoGenerate = nil


function ServerSettings:Populate(panel)
	ServerSettings.DropExtraAmmo = panel:CheckBox("Drop Excess Ammo", "case_sv_drop_excess_ammo")
	ServerSettings.DropOnDeath = panel:CheckBox("Drop Items On Death", "case_sv_drop_on_death")
	ServerSettings.Frame0Pickup = panel:CheckBox("Pickup Items Frame 0", "case_sv_frame_0_pickup")
	ServerSettings.PickupCompat = panel:CheckBox("Pickup Hook Compatibility", "case_sv_pickup_compat")
	panel:ControlHelp("This setting will help with weapon replacer mods and maybe some others, but could mess up other stuff")

	ServerSettings.PickupMode = panel:ComboBox("Pickup Mode", "case_sv_pickup_mode")
	self.PickupMode:AddChoice("Allow the client to decide", -1)
	self.PickupMode:AddChoice("Walk over to pickup items", 0)
	self.PickupMode:AddChoice("Use to pickup, unless in vehicle", 1)
	self.PickupMode:AddChoice("Use to pickup", 2)

	ServerSettings.DefaultCaseSize = panel:ComboBox("Default Case Size")
	self.DefaultCaseSize:AddChoice("Small")
	self.DefaultCaseSize:AddChoice("Medium")
	self.DefaultCaseSize:AddChoice("Large")
	self.DefaultCaseSize:AddChoice("Extra Large")
	self.DefaultCaseSize:AddChoice("Extra Extra Large")
	self.DefaultCaseSize:AddChoice("Custom")



	ServerSettings.CustomCaseSize = panel:TextEntry("Custom Case Size")
	ServerSettings.CustomCaseSize:SetText("10 6")
	ServerSettings.CustomCaseSize.OnChange = function()
        RunConsoleCommand("case_sh_default_size", ServerSettings.CustomCaseSize:GetText())
    end

	ServerSettings.AutoGenerate = nil



	local caseSize = string.lower(GetConVar("case_sh_default_size"):GetString())
	if caseSize == "s" then
		self.DefaultCaseSize:ChooseOptionID(1)
	elseif caseSize == "m" then
		self.DefaultCaseSize:ChooseOptionID(2)
	elseif caseSize == "l" then
		self.DefaultCaseSize:ChooseOptionID(3)
	elseif caseSize == "xl" then
		self.DefaultCaseSize:ChooseOptionID(4)
	elseif caseSize == "xxl" then
		self.DefaultCaseSize:ChooseOptionID(5)
	else
		self.DefaultCaseSize:ChooseOptionID(6)
		self.CustomCaseSize:SetText(caseSize)
	end


	self.DefaultCaseSize.OnSelect = function( _, index, _ )
		local sizes = {
			"s",
			"m",
			"l",
			"xl",
			"xxl"
		}

		if index ~= 6 then
			RunConsoleCommand("case_sh_default_size", sizes[index])
			ServerSettings.CustomCaseSize:SetEnabled(false)
		else
			ServerSettings.CustomCaseSize:SetEnabled(true)
			RunConsoleCommand("case_sh_default_size", ServerSettings.CustomCaseSize:GetText())
		end
	end
end

hook.Add("PopulateToolMenu", "CaseAddServerSettings", function()
	spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseServerSettings", "#Server Settings", "", "", function(panel)
		ServerSettings.Panel = panel
		ServerSettings:Populate(panel)
	end)
end)