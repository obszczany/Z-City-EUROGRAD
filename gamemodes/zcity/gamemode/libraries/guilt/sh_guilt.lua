zb = zb or {}
zb.MaximumHarm = 10
zb.MaxKarma = zb.MaxKarma or 150
zb.GroupMaxKarma = zb.GroupMaxKarma or {}
zb.PlayerMaxKarma = zb.PlayerMaxKarma or {}

function karmaGetMaxForPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then
        return zb.MaxKarma or 150
    end
    local sid = nil
    if ply.SteamID64 then
        sid = ply:SteamID64()
    end
    if sid and zb.PlayerMaxKarma and zb.PlayerMaxKarma[sid] and tonumber(zb.PlayerMaxKarma[sid]) then
        return tonumber(zb.PlayerMaxKarma[sid])
    end
    local grp
    if ply.GetUserGroup then
        grp = ply:GetUserGroup()
    end
    if grp and zb.GroupMaxKarma and zb.GroupMaxKarma[grp] and tonumber(zb.GroupMaxKarma[grp]) then
        return tonumber(zb.GroupMaxKarma[grp])
    end
    return zb.MaxKarma or 150
end
