local PANEL = {}
PANEL.Text = "bringus"
PANEL.Disabled = false
PANEL.Hover = false
PANEL.Sound = "ui/re4case/context_open.wav"
PANEL.OnClick = nil

function PANEL:Init()
    self:SetText("")
end

function PANEL:Think()
    if self:IsHovered() and not self.Hover then
        CaseGUI.PlaySound("ui/re4case/case_selection.wav")
    end

    self.Hover = self:IsHovered()
end

function PANEL:DoClick()
    CaseGUI.PlaySound(self.Sound)
    local info = CaseGUI:GenerateInfo()
    if info == nil then
        return
    end

    self.OnClick(info)
end

function PANEL:Paint(w, h)
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

    CaseInvBitmapTextDraw(self.Text, 0, 0, 35)
end

vgui.Register("CaseInvContextButton", PANEL, "DButton")