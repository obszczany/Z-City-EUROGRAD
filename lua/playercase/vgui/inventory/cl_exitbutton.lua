local PANEL = {}

function PANEL:Paint(w, h)
    local scaleW, scaleH = _CaseUIGetScaledDiff()

    surface.SetDrawColor(220, 53, 69)
    --surface.SetDrawColor(120, 120, 120)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(255, 255, 255)
    --surface.SetDrawColor(255, 0, 0)
    surface.DrawLine(3 * scaleW, 3 * scaleH, w - (3*scaleW), h - (3*scaleH))
    surface.DrawLine(3 * scaleW, h - (3*scaleH), w - (3*scaleW), 3 * scaleH)
end


vgui.Register("CaseInvExitButton", PANEL, "DButton")