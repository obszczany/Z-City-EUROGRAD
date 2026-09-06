local cvar_blur_bg = GetConVar("case_cl_blur_bg")

local craftpanel = {
    RecipeList = nil,
	ExitButton = nil,
	CraftZone = nil,
	InputFilter = -1
}

function craftpanel:Init()
	local sizeX, sizeY = _CaseUIScale(1280, 720)
    self:SetSize(sizeX, sizeY)
    --self:Center()
	--self:MakePopup()
	--self:NoClipping(true)
	--self:SetBackgroundBlur(true)

    self.RecipeList = self:Add("CaseRecipeList")
    self:Add(self.RecipeList)
    self.RecipeList:SetSize(_CaseUIScale(500, 675))
	self.RecipeList:SetPos(_CaseUIScale(1280 - 510, 35))


	self.CraftZone = self:Add("CaseCraftZone")
	self.CraftZone:SetPos(_CaseUIScale(10, 10))
	self.CraftZone:SetSize(_CaseUIScale(750, 700))


	self.ExitButton = self:Add("CaseInvExitButton")
	self.ExitButton:SetText("")
	self.ExitButton:SetSize(_CaseUIScale(25, 25))
	self.ExitButton:SetPos(_CaseUIScale(1280 - 25 - 10, 5))
	self.ExitButton.DoClick = function()
		CaseCraftGUI:Close()
	end

	self.InventoryButton = self:Add("CaseButton")
	self.InventoryButton:SetString("I")
	self.InventoryButton:SetSize(_CaseUIScale(25, 25))
	self.InventoryButton:SetPos(_CaseUIScale(1280 - 50 - 15, 5))
	self.InventoryButton.OnClick = function ()
		CaseCraftGUI:Close()
		CaseGUI.OpenInventory(true)
	end

	self.SearchFilter = self:Add("CaseTextBox")
	self.SearchFilter:SetPos(_CaseUIScale(1280 - 510, 5))
	self.SearchFilter:SetSize(_CaseUIScale(425, 25))
	self.SearchFilter:SetPlaceholderText("Filter...")

	self.SearchFilter.OnChange = function (this)
		self.RecipeList:Filter(self.RecipeList.ItemID, this:GetValue())
	end
end

function craftpanel:Filter(itemID)
	self.RecipeList:Filter(itemID)
end

function craftpanel:Paint(w, h)
	--DFrame.Paint(self, w, h)
	surface.SetDrawColor(Color(42, 41, 37))
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("CaseCraftPanel", craftpanel, "EditablePanel")