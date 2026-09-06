local PANEL = {}
PANEL.Menus = util.Stack()


local BUTTON_SIZE = 35

function PANEL:Init()
    self:NewMenu()
end

function PANEL:AddOption(text, onClick, availCheck, sound)
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local button = vgui.Create("CaseInvContextButton", self)
    button.Text = text
    button.OnClick = onClick
    button.Disabled = availCheck ~= nil and not availCheck(CaseGUI:GenerateInfo()) or false
    if sound ~= nil then
        button.Sound = sound
    end

    local cW = self:GetSize()
    button:SetSize(cW, BUTTON_SIZE * scaleH)
    table.insert(self.Menus:Top(), {Button=button, AvailCheck=availCheck})

    self:SetSize(cW, (#self.Menus:Top() * BUTTON_SIZE * scaleH) + (#self.Menus:Top()*scaleH) + (2*scaleH))
    self:PlaceItems()
end

function PANEL:PlaceItems()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    for i = #self.Menus:Top(), 1, -1 do
        self.Menus:Top()[i].Button:SetPos(
            0, (1*scaleH) + (i-1)*BUTTON_SIZE*scaleH + (i*scaleH)
        )
    end
end

function PANEL:Think()

    -- Make sure the item we're looking at is still valid
    if CaseGUI.Context.InvID == -1 or
        CaseGUI.Context.Parent == nil or
        CaseGUI.Context.Parent:Inv().Items[CaseGUI.Context.InvID] == nil then
        return
    end

    for k, v in pairs(self.Menus:Top()) do
        if v.AvailCheck ~= nil then
            v.Button:SetEnabled( v.AvailCheck(CaseGUI:GenerateInfo()))
        end
    end
end

function PANEL:NewMenu()
    local menu = {}
    self.Menus:Push(menu)
end

function PANEL:GoBack()

end

function PANEL:Paint(w, h)
    --surface.SetDrawColor(60, 60, 55, 255)
    surface.SetDrawColor(90, 90, 85, 255)
    surface.DrawRect( 0, 0, w, h)



end


vgui.Register("CaseInvContext", PANEL, "DPanel")