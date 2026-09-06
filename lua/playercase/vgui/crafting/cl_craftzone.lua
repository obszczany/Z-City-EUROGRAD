local craftzone = {
    RecipeID = 0,
	RecipeInfo = nil
}

local CRAFT_ICON_SIZE = 100
local CRAFT_RESULT_ICON_SIZE = 150
local CRAFT_ICON_ROW_SEPERATOR = 25
local CRAFT_ICON_COLUMN_SEPERATOR = 80
local CRAFT_ROW_MAX = 5

local CRAFT_NAME_SIZE = 18
local CRAFT_COUNT_SIZE = 30

function craftzone:Init()

end

function craftzone:Paint(w, h)
	local scaleW, scaleH = _CaseUIGetScaledDiff()

	surface.SetDrawColor(Color(52, 51, 47))
	surface.DrawRect(0, 0, w, h)

	if self.RecipeInfo == nil then
		return
	end


	local rowCount = 0
	local totalCount = 0
	local rowIndex = 0
	local rowBase = 0
	local col = 1

	local y = math.ceil(table.Count(self.RecipeInfo.Input) / 4) * (CRAFT_ICON_SIZE)

	-- Start off by figuring out how far up we need to go
	--y = math.ceil(table.Count(self.RecipeInfo.Input) / 4) * (CRAFT_ICON_SIZE + CRAFT_ICON_COLUMN_SEPERATOR)

	surface.SetDrawColor(Color(255, 255, 255))
	--surface.DrawLine( w / 2, 0, w / 2, h )


	-- Draw the output item
	if true then
		local resultInfo = CaseInventory:GetItemInfo(self.RecipeInfo.Result)


		local nameW, nameH = CaseInvBitmapTextSize(resultInfo.PrintName, 35)
		CaseInvBitmapTextDraw(resultInfo.PrintName, (w / 2) - (nameW / 2), 0,35)

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(CaseCraftGUI:GetIcon(self.RecipeInfo.Result).Material)


		-- Draw the icon
		local iconX = w/2 - (CRAFT_RESULT_ICON_SIZE * scaleW) / 2
		local iconY = 40 * scaleH
		surface.DrawTexturedRect(iconX, iconY, CRAFT_RESULT_ICON_SIZE * scaleW, CRAFT_RESULT_ICON_SIZE * scaleH)

		local countStr = string.format("x%i", self.RecipeInfo.Count)
		local countW, countH = CaseInvBitmapTextSize(countStr, 25)
		CaseInvBitmapTextDraw(countStr, (w / 2) - (countW / 2), iconY + (CRAFT_RESULT_ICON_SIZE* scaleH), 25)
	end

	local btnW, btnH = self.CraftButton:GetSize()

	-- Draw all the input items
	local function _GetInputOrder(inputs)
		local keys = {}

		for k in pairs(inputs) do
			table.insert(keys, k)
		end

		table.sort(keys)

		return keys
	end

	local inputOrder = _GetInputOrder(self.RecipeInfo.Input)

	for _, itemID in ipairs(inputOrder) do
		local count = self.RecipeInfo.Input[itemID]

		local itemInfo = CaseInventory:GetItemInfo(itemID)

		if rowCount == 0 then
			rowCount = math.min(CRAFT_ROW_MAX, table.Count(self.RecipeInfo.Input) - totalCount)
			rowBase = ((rowCount * CRAFT_ICON_SIZE) + ((rowCount - 1) * CRAFT_ICON_ROW_SEPERATOR)) / 2
		end
		local sW, sH = _CaseUIScale(CRAFT_ICON_SIZE, CRAFT_ICON_SIZE)
		local iconX = ((w / 2) - (rowBase * scaleW)) +
			((rowIndex * (CRAFT_ICON_SIZE + CRAFT_ICON_ROW_SEPERATOR)) * scaleW)
		local iconY = h - ((col * (CRAFT_ICON_COLUMN_SEPERATOR + CRAFT_ICON_SIZE)) * scaleH) - (5*scaleH) - btnH

		-- Star off by drawing the border
		surface.SetDrawColor(57, 57, 52, 255)
		surface.DrawRect(iconX - (5 * scaleW), iconY - (30 * scaleH), (CRAFT_ICON_SIZE + 10) * scaleW, (CRAFT_ICON_SIZE + 70) * scaleH)

		-- Now draw
		-- Inventory Count / Required Amount
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(CaseCraftGUI:GetIcon(itemID).Material)


		-- Draw the icon
		surface.DrawTexturedRect(iconX, iconY, sW, sH)

		totalCount = totalCount + 1
		rowIndex = rowIndex + 1
		if rowIndex == CRAFT_ROW_MAX then
			rowIndex = 0
			rowCount = 0
			col = col + 1
		end

		-- Draw item name text
		local nameWidth, nameHeight = CaseInvBitmapTextSize(itemInfo.PrintName, CRAFT_NAME_SIZE)
		CaseInvBitmapTextDraw(itemInfo.PrintName, iconX + ((CRAFT_ICON_SIZE*scaleW) / 2) - (nameWidth / 2), (iconY - (nameHeight / 2)) - ((30 * scaleH) / 2),CRAFT_NAME_SIZE)

		local invCount = CaseInventory:ItemCount(CaseInv(LocalPlayer()), itemID)
		local countString = ""
		if invCount <= 99 then
			countString = string.format("%i/%i", invCount, count)
		else
			countString = string.format("99+/%i", count)
		end
		local countWidth, countHeight = CaseInvBitmapTextSize(countString, CRAFT_COUNT_SIZE)

		if invCount < count then
			surface.SetDrawColor(0x9B, 0x10, 0x03, 255)
		else
			surface.SetDrawColor(0x48, 0xA8, 0x60, 255)
		end
		CaseInvBitmapTextDraw(countString, (iconX + (CRAFT_ICON_SIZE * scaleW / 2)) - (countWidth / 2), iconY + (CRAFT_ICON_SIZE*scaleH), CRAFT_COUNT_SIZE)


	end
end

function craftzone:Think()
	if self.CraftButton ~= nil then
		local enabled = CaseInventory:CanCraft(LocalPlayer(), self.RecipeID)
		self.CraftButton:SetEnabled(enabled)
		self.CraftMaxButton:SetEnabled(enabled)
	end
end

function craftzone:GetMaxCraft(recipeID)
	-- Find out the max amount we can make

	local recipe = CaseInventory:GetRecipe(recipeID)
	local ids = CaseInventory:GetInvIDsForCraft(LocalPlayer(), recipeID)
	if ids == nil then
		return 0
	end
	local inv = CaseInv(LocalPlayer())

	local maxCount = 256


	for invID, count in pairs(ids) do

		local invCount = CaseInventory:ItemCount(inv, inv.Items[invID].ItemID)
		local recCount = recipe.Input[inv.Items[invID].ItemID]

		maxCount = math.min(maxCount, math.floor(invCount / recCount))
	end
	return maxCount
end

function craftzone:UpdateMaxCraft(recipeID, takeOne)
	if takeOne == nil then
		takeOne = false
	end

	local maxCraft =  self:GetMaxCraft(recipeID)
	if takeOne then
		maxCraft = maxCraft - 1
	end


	if maxCraft <= 99 then
		self.CraftMaxButton:SetString(string.format("Craft %i", maxCraft))
	else
		self.CraftMaxButton:SetString("Craft 99+")
	end
end

function craftzone:SetRecipe(recipeID)
	local scaleW, scaleH = _CaseUIGetScaledDiff()
	self.RecipeInfo = CaseInventory:GetRecipe(recipeID)
	self.RecipeID = recipeID

	if self.CraftButton ~= nil then
		self.CraftButton:Remove()
		self.CraftMaxButton:Remove()
	end
	self.CraftButton = self:Add("CaseButton")
	self.CraftButton:SetString("Craft")
	self.CraftButton:SetSize(_CaseUIScale(125, 75))
	self.CraftButton:SetFontSize(40)

	--local btnY = (math.ceil(table.Count(self.RecipeInfo.Input) / CRAFT_ROW_MAX) * (CRAFT_ICON_COLUMN_SEPERATOR + CRAFT_ICON_SIZE)) * scaleH
	local btnW, btnH = self.CraftButton:GetSize()
	local pnlW, pnlH = self:GetSize()

	self.CraftButton:SetPos(
		(self:GetSize() / 2) - (btnW) - (15 * scaleW),
		pnlH - btnH - ( 15 * scaleH)
	)


	self.CraftButton:SetEnabled(CaseInventory:CanCraft(LocalPlayer(), recipeID))
	self.CraftButton.RecipeID = recipeID

	self.CraftButton.OnClick = function (this)
		CaseInventory.ClientNet.Craft(this.RecipeID)
		self:UpdateMaxCraft(this.RecipeID, true)
	end


	self.CraftMaxButton = self:Add("CaseButton")

	local maxCraft =  self:GetMaxCraft(recipeID)
	if maxCraft <= 99 then
		self.CraftMaxButton:SetString(string.format("Craft %i", maxCraft))
	else
		self.CraftMaxButton:SetString("Craft 99+")
	end

	self.CraftMaxButton:SetSize(_CaseUIScale(125, 75))
	self.CraftMaxButton:SetFontSize(28)

	--local btnY = (math.ceil(table.Count(self.RecipeInfo.Input) / CRAFT_ROW_MAX) * (CRAFT_ICON_COLUMN_SEPERATOR + CRAFT_ICON_SIZE)) * scaleH
	local btnW, btnH = self.CraftMaxButton:GetSize()
	local pnlW, pnlH = self:GetSize()

	self.CraftMaxButton:SetPos(
		(self:GetSize() / 2) + (15 * scaleW),
		pnlH - btnH - ( 15 * scaleH)
	)


	self.CraftMaxButton:SetEnabled(CaseInventory:CanCraft(LocalPlayer(), recipeID))
	self.CraftMaxButton.RecipeID = recipeID

	self.CraftMaxButton.OnClick = function (this)
		CaseInventory.ClientNet.Craft(this.RecipeID, self:GetMaxCraft(this.RecipeID))

		-- Just assume it's 0 ig
		this:SetString(string.format("Craft 0", maxCraft))
	end

	--self.EditRecipe = self:Add("CaseButton")
	--self.EditRecipe:SetString("E")
	--self.EditRecipe:SetSize(_CaseUIScale(25, 25))
	--self.EditRecipe:SetPos(_CaseUIScale(5, 5))
end

vgui.Register("CaseCraftZone", craftzone, "DPanel")