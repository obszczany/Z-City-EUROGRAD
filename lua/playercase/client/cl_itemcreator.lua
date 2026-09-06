CaseItemCreator = {}
CaseItemCreator.Current = {
	Class = "",
	PrintName = "",
	Model = ""
}

function CaseItemCreator:Populate(panel)
	if panel == nil then
		return
	end
	panel:Clear()

	panel:Help("Editing: " .. CaseItemCreator.Current.Class)


	CaseItemCreator.Filter = panel:TextEntry("Filter")
	CaseItemCreator.Filter.OnTextChanged = function ()
		CaseItemCreator:FilterChanged(self.Filter:GetText())
	end

	CaseItemCreator.Selector = vgui.Create("DComboBox")
	panel:AddItem(CaseItemCreator.Selector)
	CaseItemCreator.Selector.OnSelect = CaseItemCreator.EntSelected
	CaseItemCreator:FilterChanged("")


	if CaseItemCreator.Current.Class ~= "" then
		self:SelectEntity(self.Current.Class, true)
		return
	end
	panel:ControlHelp("Use the toolgun to pick an entity :)")
end

function CaseItemCreator:EntSelected(index, text, data)
	--- ??? was selected
	if data == nil then
		return
	end

	-- Already chosen
	if data.Class == CaseItemCreator.Current.Class then
		return
	end

	CaseItemCreator:SelectEntity(data.Class, false)
end

function CaseItemCreator:FilterChanged(filter)
	CaseItemCreator.Selector:Clear()
	--CaseItemCreator.Selector:AddChoice("???", nil)
	local id = 0
	local sel = -1

	for k, v in pairs(CaseInventory.CustomItems) do
		local name = v.Class
		local printName = v.PrintName
		local fitlerLower = string.lower(filter)

		local found = (filter == "") or (string.find(name, fitlerLower, 1, true) or string.find(printName, fitlerLower, 1, true))
		if not found then
			continue
		end


		CaseItemCreator.Selector:AddChoice(
				v.Class .. " (" .. v.PrintName .. ")",
				{Class = v.Class, Index = k})

		id = id + 1

		if v.Class == CaseItemCreator.Current.Class then
			sel = id
		end
	end

	if sel ~= -1 then
		CaseItemCreator.Selector:ChooseOptionID( sel )
	end
end

function CaseItemCreator:PopulateCreate(panel)
	if panel == nil then
		return
	end

	CaseItemCreator.CreateButton = panel:Button("Create...")
	CaseItemCreator.CreateButton.DoClick = function ()
		CaseInventory.ClientNet.CreateItem(CaseItemCreator.Current.Class, CaseItemCreator.Current.Model, CaseItemCreator.Current.PrintName)
	end
end


function CaseItemCreator:PopulateEdit(panel)
	if panel == nil then
		return
	end

	CaseItemCreator.PrintName = panel:TextEntry("Print Name")
	CaseItemCreator.PrintName:SetText(self.Current.PrintName)

	CaseItemCreator.Type = panel:ComboBox( "Item Type" )
	CaseItemCreator.Type:AddChoice( "Generic" )
	CaseItemCreator.Type:AddChoice( "Consumable" )
	CaseItemCreator.Type:AddChoice( "Glow Only" )


	CaseItemCreator.Type.OnSelect = function( self, index, value )
		if index ~= 2 then
			CaseItemCreator.CanUse:ChooseOptionID( 1 )
			CaseItemCreator.CanUse:SetEnabled(false)
		else
			CaseItemCreator.CanUse:SetEnabled(true)
		end
	end

	CaseItemCreator.CanUse = panel:ComboBox( "Use Condition" )
	CaseItemCreator.CanUse:AddChoice( "Always" )
	CaseItemCreator.CanUse:AddChoice( "< 100% Health" )
	CaseItemCreator.CanUse:AddChoice( "< 100% Armor" )

	CaseItemCreator.Type:ChooseOptionID( 1 )
	CaseItemCreator.CanUse:ChooseOptionID( 1 )

	CaseItemCreator.ApplyButton = panel:Button("Apply")
	CaseItemCreator.ApplyButton.DoClick = function ()
		CaseInventory.ClientNet.UpdateItem(
			CaseItemCreator.Current.Class,
			CaseItemCreator.PrintName:GetText(),
			CaseItemCreator.Type:GetSelectedID(),
			CaseItemCreator.CanUse:GetSelectedID()
		)
	end

	CaseItemCreator.RemoveButton = panel:Button("Remove")
	CaseItemCreator.RemoveButton.DoClick = function ()
		CaseInventory.ClientNet.RemoveItem(CaseItemCreator.Current.Class)
	end
end

function CaseItemCreator:SelectEntity(class, fromPopulate)
	CaseItemCreator.Current.Class = class
	CaseItemCreator:FilterChanged("")


	if not fromPopulate then
		CaseItemCreator:Populate(CaseItemCreator.Panel)
		return
	end

	local itemID = CaseInventory:GetItemID(class)
	if itemID ~= -1 and not CaseInventory:IsCustom(itemID) then
		CaseItemCreator.Panel:Help("Can't edit built-in items")
		CaseItemCreator.Panel:ControlHelp("https://tenor.com/bW5F1.gif")
		return
	end


	-- Item doesn't exist, tell to populate
	if itemID == -1 then
		CaseItemCreator:PopulateCreate(CaseItemCreator.Panel)
		return
	end

	if itemID ~= -1 then
		local info = CaseInventory.ItemRegister[itemID]

		self.Current.PrintName = info.PrintName
		CaseItemCreator:PopulateEdit(CaseItemCreator.Panel)

		CaseItemCreator.Type:ChooseOptionID( CaseInventory.CustomItems[itemID].Type )
		CaseItemCreator.CanUse:ChooseOptionID( CaseInventory.CustomItems[itemID].CanUse )
	end

end