CraftingEditor = {
	AwaitingUpdate = false,
	PanelThink = nil,
	NeedsUpdating = false,
	UpdateID = nil,
	CurrentRecipeID = 0,
	EditPanels = {

	},
	InputPanels = {

	}
}


function CraftingEditor:Populate(panel)
	self.Panel = panel
	self.PanelThink = panel.Think
	panel.Think = self.Think

	self.RecipeFilter = panel:TextEntry("Filter")

	self.RecipeSelector = panel:ComboBox("Recipes")
	self.RecipeSelector:SetSortItems(false)
	self:UpdateRecipes()

	self.RecipeSelector.OnSelect = function (this, index, value, data)
		CraftingEditor:SelectRecipe(data)
	end

	self.CreateNew = panel:Button("New")
	self.CreateNew.DoClick = function ()
		CraftingEditor.Recipe = {
			Count = 1,
			DisplayName = CaseInventory:GetValidRecipeName("My New Recipe"),
			Input = {},
			Result = 1,
			IsCustom = true,
			Disabled = false
		}
		CraftingEditor.CurrentRecipeID = 0
		CraftingEditor:UpdateFields()
	end
end

function CraftingEditor:UpdateRecipes()
	self.RecipeSelector:Clear()
	for rID, recipe in pairs(CaseInventory.CraftingRecipes) do
		local name = ""
		if recipe.Disabled then
			name = "(D) " .. recipe.DisplayName
		else
			name = recipe.DisplayName
		end

		self.RecipeSelector:AddChoice(name, rID)
	end

	self:SetupFilter(self.RecipeFilter, self.RecipeSelector)
end

function CraftingEditor:SelectRecipe(rID)
	local recipe = CaseInventory:GetRecipe(rID)
	if recipe == nil then
		return
	end

	self.CurrentRecipeID = rID
	self.Recipe = table.Copy(recipe)
	self:UpdateFields()
end

function CraftingEditor:AddEditPanel(name, panel, label)
	self.EditPanels[name] = panel
	self.EditPanels[name .. "Label"] = label
end

function CraftingEditor:UpdateFields()
	for k, pnl in pairs(self.EditPanels) do
		pnl:Remove()
		self.EditPanels[k] = nil
	end

	if self.Recipe.IsCustom then
		CraftingEditor:AddEditPanel("Name", self.Panel:TextEntry("Name"))
		CraftingEditor.EditPanels.Name.OnValueChange = function (this, value)
			local validName = CaseInventory:GetValidRecipeName(value, self.CurrentRecipeID)
			this:SetText(validName)
			self.Recipe.DisplayName = validName
		end

		CraftingEditor.EditPanels.Name:SetValue(self.Recipe.DisplayName)

		CraftingEditor:AddEditPanel("ResultFilter", self.Panel:TextEntry("Filter"))

		CraftingEditor:AddEditPanel("Result", self.Panel:ComboBox("Result"))
		self:PopulateItems(self.EditPanels.Result)
		self.EditPanels.Result.OnSelect = function (this, index, value, data)
			self.Recipe.Result = data
		end

		self:SetupFilter(self.EditPanels.ResultFilter, self.EditPanels.Result)

		local i = 1
		while true do
			local itemID = self.EditPanels.Result:GetOptionData(i)
			if itemID == nil then
				break
			end

			if itemID == self.Recipe.Result then
				self.EditPanels.Result:ChooseOptionID(i)
				break
			end

			i = i + 1
		end


		CraftingEditor:AddEditPanel("Count", self.Panel:TextEntry("Count"))

		self.EditPanels.Count.OnChange = function (this)
			local count = tonumber(this:GetValue())
			if count == nil or count <= 0 then
				count = 1
			end

			self.Recipe.Count = count
		end

		self.EditPanels.Count:SetText(tostring(self.Recipe.Count))

		self.EditPanels.InputPanel = vgui.Create("DForm")
		self.EditPanels.InputPanel:SetLabel("Inputs")
		self.Panel:AddItem(self.EditPanels.InputPanel)

		CraftingEditor:AddEditPanel("AddItem", self.Panel:Button("Add Input"))

		self.EditPanels.AddItem.DoClick = function (this, itemID)
			if table.Count(CraftingEditor.Recipe.Input) == 8 then
				return
			end

			if itemID == nil then
				-- Add a new input
				-- Find the first free ID we can use
				local freeID = 1
				while CraftingEditor.Recipe.Input[freeID] ~= nil do
					freeID = freeID + 1
				end
				CraftingEditor.Recipe.Input[freeID] = 1
				itemID = freeID
			end

			self:AddInput(self.EditPanels.InputPanel, itemID)
		end

		if CaseInventory:GetRecipe(self.CurrentRecipeID) ~= nil then
			CraftingEditor:AddEditPanel("Delete", self.Panel:Button("Delete"))
			self.EditPanels.Delete.DoClick = function (this)
				CaseInventory.ClientNet.SubmitRecipe(self.CurrentRecipeID, nil)
				self:UpdateRecipes()
				self.RecipeSelector:ChooseOptionID(1)
			end
		end

		local itemIDS = {}
		for itemID, _ in pairs(CraftingEditor.Recipe.Input) do
			table.insert(itemIDS, itemID)
		end

		table.sort(itemIDS)

		for _, itemID in ipairs(itemIDS) do
			self.EditPanels.AddItem.DoClick(self.EditPanels.AddItem, itemID)
		end

	end

	CraftingEditor:AddEditPanel("Disabled", self.Panel:CheckBox("Disabled"))
	self.EditPanels.Disabled.OnChange = function (this)
		self.Recipe.Disabled = this:GetChecked()
	end
	self.EditPanels.Disabled:SetValue(self.Recipe.Disabled)

	self.EditPanels.Save = self.Panel:Button("Save")
	self.EditPanels.Save.DoClick = function ()

		-- Waiting for a response from the server
		if self.AwaitingUpdate then
			return
		end

		if self.EditPanels.Name ~= nil then
			local validName = CaseInventory:GetValidRecipeName(self.EditPanels.Name:GetValue(), self.CurrentRecipeID)
			self.EditPanels.Name:SetText(validName)
			self.Recipe.DisplayName = validName
		end

		CaseInventory.ClientNet.SubmitRecipe(self.CurrentRecipeID, self.Recipe)
		self.AwaitingUpdate = true

		-- Give up after 3 seconds
		timer.Simple(3, function()
			self.AwaitingUpdate = false
		end)
	end
end

function CraftingEditor:AddInput(inputPanel, itemID)

	local inputPanels = {

	}

	 inputPanels.Filter, inputPanels.FilterText = inputPanel:TextEntry("Filter")

	inputPanels.InputItem = vgui.Create("DComboBox")
	inputPanels.InputItem.ItemID = itemID
	inputPanel:AddItem(inputPanels.InputItem)

	self:PopulateItems(inputPanels.InputItem, itemID)
	inputPanels.InputItem.OnSelect = function (this, index, value, data)
		local oldCount = self.Recipe.Input[this.ItemID]
		self.Recipe.Input[this.ItemID] = nil
		self.Recipe.Input[data] = oldCount
		self.InputPanels[data] = self.InputPanels[this.ItemID]
		self.InputPanels[data].Button.ItemID = data
		self.InputPanels[data].Count.ItemID = data

		this.ItemID = data
	end

	self:SetupFilter(inputPanels.Filter, inputPanels.InputItem)

	inputPanels.Count, inputPanels.CountLabel = inputPanel:TextEntry("Count")
	inputPanels.Count:SetText(tostring(self.Recipe.Input[itemID]))
	inputPanels.Count.ItemID = itemID

	inputPanels.Count.OnChange = function (this)
		local count = tonumber(this:GetValue())
		if count == nil or count <= 0 then
			count = 1
		end

		self.Recipe.Input[this.ItemID] = count
	end

	inputPanels.Button = inputPanel:Button("Remove")
	inputPanels.Button.ItemID = itemID
	inputPanels.Button.DoClick = function (this)
		for _, pnl in pairs(self.InputPanels[this.ItemID]) do
			pnl:Remove()
		end

		self.InputPanels[this.ItemID] = nil
		self.Recipe.Input[this.ItemID] = nil
	end

	inputPanels.Divider = vgui.Create("DHorizontalDivider")
	inputPanel:AddItem(inputPanels.Divider)

	self.InputPanels[itemID] = inputPanels

end

function CraftingEditor:PopulateItems(combobox, desiredItemID)
	if desiredItemID == nil then

	end

	local setIndex = 1
	local index = 1

	for itemID, itemInfo in pairs(CaseInventory.ItemRegister) do
		if itemInfo.ItemType == CASE_ITEM_DO_NOT_HANDLE or itemInfo.ItemType == CASE_ITEM_GLOW_ONLY then
			continue
		end

		combobox:AddChoice(string.format("%s (%s)", itemInfo.Name, itemInfo.PrintName), itemID)

		if itemID == desiredItemID then
			setIndex = index
		end

		index = index + 1
	end

	combobox:ChooseOptionID(setIndex)
end

function CraftingEditor:SetupFilter(filter, combobox)
	filter.Items = {}

	filter.OnChange = nil
	filter:SetText("")

	local i = 1
	while true do
		local text = combobox:GetOptionText(i)
		local data = combobox:GetOptionData(i)

		if data == nil then
			break
		end

		table.insert(filter.Items, {
			Text=text,
			Data=data
		})

		i = i + 1
	end

	filter.OnChange = function (this)

		local chosenOption = 1
		local found = false
		local noFilter = this:GetValue() == ""
		local currentData = combobox:GetOptionData(combobox:GetSelectedID())

		combobox:Clear()
		local index = 1
		for _, info in ipairs(filter.Items) do
			if noFilter or string.find(string.lower(info.Text), string.lower(this:GetValue()), 0, true) then
				combobox:AddChoice(info.Text, info.Data)
				found = true
				if currentData == info.Data then
					chosenOption = index
				end

				index = index + 1
			end
		end

		index = 1
		if not found then
			for _, info in ipairs(filter.Items) do
				combobox:AddChoice(info.Text, info.Data)
				if currentData == info.Data then
					chosenOption = index
				end
			end
			index = index + 1
		end

		combobox:ChooseOptionID(chosenOption)
	end
end

function CraftingEditor.Think(self)
	if CraftingEditor.NeedsUpdating then
		CraftingEditor.NeedsUpdating = false

		-- Update the recipe list first off
		CraftingEditor.UpdateRecipes(CraftingEditor)

		-- What happened

		-- -1 = Item was deleted
		-- 0 = Invalid item or something
		-- 1+ = Switch to this id


		-- Item was deleted, just pick the first thing
		if CraftingEditor.UpdateID == -1 then
			CraftingEditor.RecipeSelector:ChooseOptionID(1)
		end

		-- Skill issue
		if CraftingEditor.UpdateID == 0 then
			CraftingEditor.AwaitingUpdate = false
		end

		-- YES! YES! YES! YES!
		if CraftingEditor.UpdateID >= 1 then
			local i = 1
			while true do
				local rID = CraftingEditor.RecipeSelector:GetOptionData(i)
				if rID == nil then
					break
				end

				-- We've found our man
				if rID == CraftingEditor.UpdateID then
					CraftingEditor.AwaitingUpdate = false
					CraftingEditor.RecipeSelector:ChooseOptionID(i)
					break
				end

				i = i + 1
			end
		end


	end
	CraftingEditor.PanelThink(self)
end

hook.Add("PopulateToolMenu", "CaseAddCraftEditor", function()
	spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseCraftEditor", "#Crafting Editor", "", "", function(panel)
		CraftingEditor.Panel = panel
		CraftingEditor:Populate(panel)
	end)
end)