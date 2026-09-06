local PANEL = {}

function PANEL:Paint(w, h)
	local scaleW, scaleH = _CaseUIGetScaledDiff()

	surface.SetDrawColor(0xCC, 0x58, 0x01)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(255, 255, 255)

	local marginX = 3 * scaleW
	local lineHeight = 2 * scaleH
	local spacing = 4 * scaleH

	local totalHeight = (lineHeight * 3) + (spacing * 2)
	local startY = (h - totalHeight) / 2

	for i = 0, 2 do
		local y = startY + i * (lineHeight + spacing)
		surface.DrawRect(marginX, y, w - (marginX * 2), lineHeight)
	end
end


vgui.Register("CaseInvEditButton", PANEL, "DButton")