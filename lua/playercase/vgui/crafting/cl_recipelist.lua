local recipelist = {
	Buttons = {

	},
	ItemID = -1
}

function recipelist:Init()
    self:GetVBar().Paint = self.VBarPaint
    self:GetVBar().btnDown.Paint = self.btnDownPaint
    self:GetVBar().btnUp.Paint = self.btnUpPaint
    self:GetVBar().btnGrip.Paint = self.GripPaint

    local sizeX = _CaseUIScale(25, 0)
    local _, sizeY = self:GetVBar():GetSize()
    self:GetVBar():SetSize(sizeX, sizeY )
end

function recipelist:AddRecipe(rID)
	local button = self:Add("CaseRecipeButton")
	button:SetRecipeID(rID)
	button:SetSize(_CaseUIScale(1, 75))
	button:Dock(TOP)
	button:DockMargin(0, 0, 0, 2)
	button.OnClick = function (this)
		CaseCraftGUI.CraftPanel.CraftZone:SetRecipe(this.RecipeID)
	end

	table.insert(self.Buttons, button)
	return button
end

function recipelist:Filter(itemID, filterText)
	local recipeCollection = {}
	self.ItemID = itemID
	local first = true

	for k, v in ipairs(self.Buttons) do
		v:Remove()
	end

	if itemID == -1 then
		-- Load up the recipes
		for rID, rInfo in pairs(CaseInventory.CraftingRecipes) do
			if rInfo.Disabled or not CaseInventory:ValidateRecipe(rID) then
				continue
			end

			table.insert(recipeCollection, rID)
		end
	else
		if CaseInventory.CraftingLookup[itemID] == nil then
			self:Filter(-1, filterText)
			return
		end

		for _, rID in ipairs(CaseInventory.CraftingLookup[itemID]) do
			table.insert(recipeCollection, rID)
		end
	end


	-- Ok time to filter for text!

	-- Or don't...
	if filterText == "" or filterText == nil then
		for _, rID in ipairs(recipeCollection) do
			local button = self:AddRecipe(rID)
			if first then
				button:OnClick()
				first = false
			end
		end

		return
	end

	for _, rID in ipairs(recipeCollection) do
		local found = false
		local recipeInfo = CaseInventory:GetRecipe(rID)

		if recipeInfo == nil then
			self:Filter(itemID, "")
		end

		local function GetItemText(itemID)
			local info = CaseInventory:GetItemInfo(itemID)
			if info == nil then
				return nil, nil
			end

			return info.Name, info.PrintName
		end


		-- Try to find it in the display name
		if string.find(recipeInfo.DisplayName, filterText, 1, true) then
			found = true
		end

		-- Try to find it in the result class + name
		if not found then
			local name, printName = GetItemText(recipeInfo.Result)
			if name == nil or printName == nil then
				continue
			end

			if string.find(name, filterText, 1, true) or string.find(printName, filterText, 1, true) then
				found = true
			end
		end

		-- Ok try to find it in an input
		if not found then
			for itemID, _ in pairs(recipeInfo.Input) do
				local name, printName = GetItemText(itemID)
				if name == nil or printName == nil then
					continue
				end

				if string.find(name, filterText, 1, true) or string.find(printName, filterText, 1, true) then
					found = true
					break
				end
			end
		end

		if found then
			local button = self:AddRecipe(rID)
			if first then
				button:OnClick()
				first = false
			end
		end
	end
end

function recipelist:Paint(w, h)
    surface.SetDrawColor(Color(52, 51, 47))
	surface.DrawRect(0, 0, w, h)
end

function recipelist.VBarPaint(self, w, h)
    surface.SetDrawColor(Color(52, 51, 47))
	surface.DrawRect(0, 0, w, h)
end

function recipelist.btnUpPaint(self, w, h)
    if self:IsEnabled() then
		if not self:IsHovered() then
			surface.SetDrawColor(0x06, 0x40, 0x2B, 255)
		else
			surface.SetDrawColor(0x40, 0x82, 0x6D, 255)
		end
	else
		surface.SetDrawColor(30, 30, 27, 255)
	end

	surface.DrawRect( 0, 0, w, h)
end

function recipelist.btnDownPaint(self, w, h)
    if self:IsEnabled() then
		if not self:IsHovered() then
			surface.SetDrawColor(0x055, 0x00, 0x00, 255)
		else
			surface.SetDrawColor(0xAD, 0x28, 0x31, 255)
		end
	else
		surface.SetDrawColor(30, 30, 27, 255)
	end
	surface.DrawRect( 0, 0, w, h)
end

function recipelist.GripPaint(self , w, h)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect( 0, 0, w, h)

    if self:IsEnabled() then
		if self:IsHovered() then
            surface.SetDrawColor(80, 80, 75, 255)
		else
			surface.SetDrawColor(60, 60, 55, 255)
		end
	else
		surface.SetDrawColor(30, 30, 27, 255)
	end

	surface.DrawRect( 2, 2, w-4, h-4)
end

vgui.Register("CaseRecipeList", recipelist, "DScrollPanel")