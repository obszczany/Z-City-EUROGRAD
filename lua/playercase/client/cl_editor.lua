CaseEditor = {}

CaseEditor.Panel = nil

-- All the panels/stuff
-- Listed here so i can refer back to them
CaseEditor.WeaponList = nil
CaseEditor.ApplyButton = nil
CaseEditor.ResetButton = nil
CaseEditor.Filter = nil
CaseEditor.Model = nil
CaseEditor.Scale = nil
CaseEditor.Offset = nil
CaseEditor.Size = nil
CaseEditor.Count = nil
CaseEditor.Blacklist = nil
CaseEditor.Rotation = nil
CaseEditor.Skin = nil
CaseEditor.UseSprite = nil

CaseEditor.WorldModel = nil
CaseEditor.ViewModel = nil

CaseEditor.CurrentID = 1

CaseEditor.IsWeapon = false

local CaseEditSpawnMenu = {
	IsWeapon = false,
	CurrentID = 1
}

local SPRITE_HELP_WEAPON = "Will either use the hud sprite, or the file located at materials/caseinv/%s.png"
local SPRITE_HELP_OTHER = "Will use the texture at materials/caseinv/%s.png"

function CaseEditor:Populate(panel)

	-- Add a combo box and slap all the weapon names in it
	self.WeaponList = vgui.Create("DComboBox")

	self.Filter = panel:TextEntry("Filter")
	self.Filter.OnTextChanged = function ()
		CaseEditor.FilterChanged(self, self.Filter:GetText())
	end



	self.WeaponList.OnSelect = function (_, _, _, data)
		CaseEditor.WeaponChanged(self, data, true)
		CaseEditor.CurrentID = data
	end

	panel:AddItem(self.WeaponList)


	self.ApplyButton = panel:Button("Apply")
	self.ApplyButton.DoClick = function()
		CaseEditor.ApplyChanges(self)
	end

	self.ResetButton = panel:Button("Reset")
	self.ResetButton.DoClick = function ()
		CaseEditor.ResetInfo(self)
	end

	self.CopyAsCode = panel:Button("Copy As Lua Code")
	self.CopyAsCode.DoClick = function ()
		CaseEditor.CopyToClipboard(self)
	end



	self.Model = panel:TextEntry("Model")
	self.Skin = panel:TextEntry("Model Skin")



	self.Size = panel:TextEntry("Size")
	self.Scale = panel:TextEntry("Scale")
	self.Offset = panel:TextEntry("Offset")
	self.Rotation = panel:TextEntry("Rotation")

	self.Blacklist = panel:CheckBox("Blacklisted")
	self.Count 	= panel:TextEntry("Max Count")
	self.UseSprite = panel:CheckBox("Use Sprite")

	self.SpriteHelp = panel:ControlHelp("")

	self.WorldModel = panel:Button("Set To World Model")
	self.WorldModel.DoClick = function ()
		local info = weapons.Get(CaseInventory:GetItemInfo(CaseEditor.CurrentID).Name)
		if info == nil then
			return
		end

		self.Model:SetText(info.WorldModel)
	end
	self.ViewModel = panel:Button("Set To View Model")
	self.ViewModel.DoClick = function ()
		local info = weapons.Get(CaseInventory:GetItemInfo(CaseEditor.CurrentID).Name)
		if info == nil then
			return
		end
		self.Model:SetText(info.ViewModel)
	end

	CaseEditor.FilterChanged(self, "")
end

local function GetValue(val, default)
	if val == nil then return default end
	return val
end

function CaseEditor:WeaponChanged(itemID, useGetItemInfo)
	local register = nil

	local realType = CaseInventory.ItemRegister[itemID].ItemType

	if useGetItemInfo then
		register = CaseInventory:GetItemInfo(itemID)
	else
		register = CaseInventory.ItemRegister[itemID]
	end

	if not register then
		return
	end
	self.CurrentID = itemID

	self.Model:SetText(register.RenderInfo.Model)
	self.Size:SetText("" .. GetValue(register.Size.W, 1) .. " " .. GetValue(register.Size.H, 1))
	self.Scale:SetText(GetValue(register.RenderInfo.Scale, 1.0))
	self.Offset:SetText("" .. GetValue(register.RenderInfo.Offset.X, 0) .. " " .. GetValue(register.RenderInfo.Offset.Y, 0) .. " " .. GetValue(register.RenderInfo.Offset.Z, 0))
	self.Rotation:SetText("" .. GetValue(register.RenderInfo.Rotations[1], 0) .. " " .. GetValue(register.RenderInfo.Rotations[2], 0) .. " " .. GetValue(register.RenderInfo.Rotations[3], 0))
	self.Skin:SetText("" .. GetValue(register.RenderInfo.Skin, 0))

	if realType == CASE_ITEM_WEAPON then
		self.Count:SetEnabled(false)
		self.Count:SetText("")
		self.WorldModel:SetEnabled(true)
		self.ViewModel:SetEnabled(true)

		self.IsWeapon = true
		self.SpriteHelp:SetText(string.format(SPRITE_HELP_WEAPON, register.Name))
	else
		self.Count:SetText("" .. GetValue(register.MaxCount))
		self.Count:SetEnabled(true)
		self.WorldModel:SetEnabled(false)
		self.ViewModel:SetEnabled(false)

		self.IsWeapon = false
		self.SpriteHelp:SetText(string.format(SPRITE_HELP_OTHER, register.Name))
	end



	self.Blacklist:SetChecked(register.ItemType == CASE_ITEM_DO_NOT_HANDLE)
	self.UseSprite:SetChecked(register.RenderInfo.UseSprite)
end

function CaseEditor:ApplyChanges()
	local i = 1

	local model = self.Model:GetText()
	local skin = tonumber(self.Skin:GetText())

	local size = {
		1,
		1
	}

	local offset = {
		0,
		0,
		0
	}

	local rotation = {
		0,
		0,
		0
	}

	local scale = tonumber(self.Scale:GetText())



	for word in string.gmatch(self.Size:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		size[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(self.Offset:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		offset[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(self.Rotation:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		rotation[i] = tonumber(word)
		i = i + 1
	end

	local maxCount = self.IsWeapon and 1 or tonumber(self.Count:GetText())
	local blacklist = self.Blacklist:GetChecked()
	local useSprite = self.UseSprite:GetChecked()

	CaseInventory.ClientNet.UpdateOverride(
		self.CurrentID,
		{
			Size=size,
			MaxCount=maxCount ~= nil and maxCount or 1,
			Blacklist=blacklist,
			RenderInfo=CaseRenderInfo(model, scale, rotation, offset, skin, useSprite)
		}
	)
end

function CaseEditor:CopyToClipboard()
	local i = 1

	local model = self.Model:GetText()
	local skin = tonumber(self.Skin:GetText())
	local size = {
		1,
		1
	}

	local offset = {
		0,
		0,
		0
	}

	local rotation = {
		0,
		0,
		0
	}

	local scale = tonumber(self.Scale:GetText())



	for word in string.gmatch(self.Size:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		size[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(self.Offset:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		offset[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(self.Rotation:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		rotation[i] = tonumber(word)
		i = i + 1
	end

	local maxCount = self.IsWeapon and 1 or tonumber(self.Count:GetText())
	local blacklist = self.Blacklist:GetChecked()
	local useSprite = self.IsSprite:GetChecked()

	local copyString = "no code for this item type yet :("
	local renderInfo = string.format("CaseRenderInfo(\"%s\", %g, {%g, %g, %g}, Vector(%g, %g, %g), 0, %g), ",
			model,
			scale,
			rotation[1],
			rotation[2],
			rotation[3],
			offset[1],
			offset[2],
			offset[3],
			skin,
			useSprite
		)


	local itemType = CaseInventory.ItemRegister[self.CurrentID].ItemType
	local itemName = CaseInventory.ItemRegister[self.CurrentID].Name

	if blacklist then
		itemType = CASE_ITEM_DO_NOT_HANDLE
	end

	if blacklist then
		copyString = "CaseDoNotHandle(\"" .. itemName .. "\")"
	end

	if itemType == CASE_ITEM_WEAPON then
		copyString = string.format("CaseWeapon(\"%s\", %s, %g, %g)", itemName, renderInfo, size[1], size[2])
	end

	if itemType == CASE_ITEM_AMMO then
		local ammoName = game.GetAmmoName(CaseInventory.ItemRegister[self.CurrentID].AmmoID)
		copyString = string.format("CaseAmmo(game.GetAmmoID(\"%s\"), %s, %g, %g, %g)", ammoName, renderInfo, size[1], size[2], maxCount)
	end

	-- TODO: Add grenade check, good luck with item check chucklefuck

	SetClipboardText(copyString)
end

function CaseEditor:ResetInfo()
	CaseEditor.WeaponChanged(self, self.CurrentID, false)

	-- Delete the item from the overrides
	CaseInventory.ClientNet.UpdateOverride(
		self.CurrentID,
		nil
	)
end

function CaseEditor:FilterChanged(filter, all)
	if all == nil then
		all = false
	end

	local foundWeapon = false
	self.WeaponList:CloseMenu()
	self.WeaponList:Clear()

	for i in pairs(CaseInventory.ItemRegister) do
		local type = CaseInventory.ItemRegister[i].ItemType

		if type == CASE_ITEM_GLOW_ONLY or type == CASE_ITEM_DO_NOT_HANDLE or type == CASE_ITEM_AMMO_SPECIAL then
			continue
		end

		local name = string.lower(CaseInventory.ItemRegister[i].Name ~= nil and CaseInventory.ItemRegister[i].Name or "")
		local printName = string.lower(CaseInventory.ItemRegister[i].PrintName ~= nil and CaseInventory.ItemRegister[i].PrintName or "")
		local fitlerLower = string.lower(filter)

		local found = all or (string.find(name, fitlerLower, 1, true) or string.find(printName, fitlerLower, 1, true))

		if found then
			foundWeapon = true
			local wepPrintName = CaseInventory.ItemRegister[i].PrintName
			if CaseInventory.ItemRegister[i].PrintName == nil then
				wepPrintName = ""
			end

			self.WeaponList:AddChoice(
				CaseInventory.ItemRegister[i].Name .. " (" .. wepPrintName .. ")",
				i -- Store the index just because
			)
		end
	end

	-- Wait we really found nothing...
	if not foundWeapon and all then
		self.ApplyButton:SetEnabled(false)
		self.ResetButton:SetEnabled(false)
	end

	-- nothing found, just throw everything back on
	if not foundWeapon then
		CaseEditor.FilterChanged(self, "", true)
	else
		self.WeaponList:ChooseOptionID(1)
		self.ApplyButton:SetEnabled(true)
		self.ResetButton:SetEnabled(true)
	end
end


hook.Add("AddToolMenuCategories", "CaseAddUtilCategory", function()
    spawnmenu.AddToolCategory("Utilities", "RE4 Case", "#RE4 Case")
end)

hook.Add("PopulateToolMenu", "CaseAddOption", function()
    spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseEditor", "#Item Editor", "", "", function(panel)
		CaseEditSpawnMenu.Panel = panel
		CaseEditor.Populate(CaseEditSpawnMenu, panel)
    end)
end)