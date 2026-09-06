local textbox = {
	ThinkOld = nil,
	PaintOld = nil
}

function textbox:Init()
	self.ThinkOld = self.Think
	self.Think = self.Update

	self.PaintOld = self.Paint
	self.Paint = self.Draw


	self:SetFont("RedHatMono")
	self:SetTextColor(Color(255, 255, 255))
	self:SetPaintBackground(false)
	self:SetCursorColor(Color(255, 255, 255))
end



function textbox:Update()
	self:ThinkOld()

end

function textbox:Draw(w, h)

	if not self:IsEditing() then
		surface.SetDrawColor(Color(0x38, 0x38, 0x38))
	else
		surface.SetDrawColor(Color(0x3D, 0x3D, 0x3D))
	end

	surface.DrawRect(0, 0, w, h)

	self:PaintOld(w, h)
end


vgui.Register("CaseTextBox", textbox, "DTextEntry")