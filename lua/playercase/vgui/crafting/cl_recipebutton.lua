local recipebutton = {
	ItemID = 0,
	RecipeID = 0,
	Text = "",
	Hovered = false,
	OnClick = function ()

	end,
	Sound = "ui/re4case/context_open.wav",
	PlaySound = true
}

function recipebutton:Init()
	self:SetText("")
end

function recipebutton:Think()
	if self:IsHovered() and not self.Hover then
		CaseGUI.PlaySound("ui/re4case/case_selection.wav")
	end

	self.Hover = self:IsHovered()
end

function recipebutton:DoClick()
	if self.PlaySound then
    	CaseGUI.PlaySound(self.Sound)
	end

    self:OnClick()
end

function recipebutton:SetRecipeID(rID)
	local rec = CaseInventory:GetRecipe(rID)
	if rec == nil then
		return
	end
	self.ItemID = rec.Result
	self.Text = rec.DisplayName
	self.RecipeID = rID
end

function recipebutton:Paint(w, h)
	local scaleW = _CaseUIGetScaledDiff()

	if self:IsEnabled() then
		if not self:IsHovered() then
			surface.SetDrawColor(60, 60, 55, 255)
		else
			surface.SetDrawColor(80, 80, 75, 255)
		end
	else
		surface.SetDrawColor(30, 30, 27, 255)
	end
	surface.DrawRect( 0, 0, w, h)

	if self:IsEnabled() then
		surface.SetDrawColor(255,255,255, 255)
	else
		surface.SetDrawColor(110, 110, 105, 255)
	end



	surface.SetDrawColor(255,255,255, 255)
	surface.DrawRect(0, 0, h, h)

	local x, y = self:LocalToScreen(0, 0)

	local offsetX = h + (5 * scaleW)
	local oXS, oYS = _CaseUIScale(1, 1)

	local icon = CaseCraftGUI:GetIcon(self.ItemID)
	surface.SetMaterial(icon.Material)
	surface.DrawTexturedRect(oXS, oYS, h-oXS, h-oYS)

	local _, textH = _CaseUIScale(0, 35)

	CaseInvBitmapTextDraw(self.Text, offsetX, h/2 - (textH / 2), 35 )
end

vgui.Register("CaseRecipeButton", recipebutton, "DButton")