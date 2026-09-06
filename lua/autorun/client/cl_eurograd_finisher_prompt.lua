-- EUROGRAD presentation/input adapter for Workshop item 3782848810.
-- The execution addon and its animation content remain a managed dependency.

local enabled = CreateClientConVar("eurograd_finisher_prompt", "1", true, false, "Show the EUROGRAD execution prompt", 0, 1)
local executeKey = KEY_E
local rangeSqr = 200 * 200

local function themeValue(group, key, fallback)
	local theme = CASE_ZCITY_THEME or {}
	local values = theme[group] or {}
	return values[key] or fallback
end

local function themeColor(key, fallback)
	local value = themeValue("Colors", key, nil)
	if IsColor(value) then return value end
	if istable(value) then return Color(value[1] or fallback.r, value[2] or fallback.g, value[3] or fallback.b, value[4] or fallback.a) end
	return fallback
end

surface.CreateFont("EurogradFinisher", {
	font = themeValue("Fonts", "Finisher", "Impact"),
	size = math.Clamp(math.floor(ScrH() * 0.041), 34, 64),
	weight = 1000,
	antialias = true,
	extended = true
})

surface.CreateFont("EurogradFinisherSub", {
	font = themeValue("Fonts", "Character", "Bahnschrift"),
	size = math.Clamp(math.floor(ScrH() * 0.014), 14, 24),
	weight = 900,
	antialias = true,
	extended = true
})

local function executionWeaponAvailable(ply)
	if not MH or not istable(MH.Kills) then return false end
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return false end
	local class = weapon:GetClass()
	return (istable(MH.KillsFor) and istable(MH.KillsFor[class]) and #MH.KillsFor[class] > 0)
		or (istable(MH.ByWeapon) and istable(MH.ByWeapon[class]) and #MH.ByWeapon[class] > 0)
end

local function resolveTarget(ent, ply)
	if not IsValid(ent) then return nil end
	if not ent:IsPlayer() and hg and isfunction(hg.RagdollOwner) then ent = hg.RagdollOwner(ent) or ent end
	if not IsValid(ent) or ent == ply then return nil end
	if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return ent end
end

local function findTarget(ply)
	local target = resolveTarget(ply:GetEyeTrace().Entity, ply)
	if IsValid(target) then return target end

	local eye = ply:EyePos()
	local aim = ply:GetAimVector()
	local best, bestDot
	for _, candidate in ipairs(ents.FindInSphere(eye, 200)) do
		candidate = resolveTarget(candidate, ply)
		if IsValid(candidate) then
			local offset = candidate:WorldSpaceCenter() - eye
			local length = offset:Length()
			local dot = length > 1 and aim:Dot(offset / length) or -1
			if dot > 0.75 and (not bestDot or dot > bestDot) then best, bestDot = candidate, dot end
		end
	end
	return best
end

local function canExecute()
	if not enabled:GetBool() then return false end
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or ply:GetNWFloat("MH_Kill", 0) > CurTime() then return false end
	if not executionWeaponAvailable(ply) then return false end

	local target = findTarget(ply)
	if not IsValid(target) or target:GetPos():DistToSqr(ply:GetPos()) > rangeSqr then return false end
	if target:IsPlayer() and (not target:Alive() or target:GetNWFloat("MH_Kill", 0) > CurTime()) then return false end
	if target.organism and target.organism.otrub then return false end

	local behind = ply:GetPos() - target:GetPos()
	behind.z = 0
	if behind:LengthSqr() < 1 then return false end
	local facing = Angle(0, target:EyeAngles().yaw, 0):Forward()
	if behind:GetNormalized():Dot(facing) > -0.4 then return false end
	return true, target
end

hook.Add("HUDPaint", "Eurograd.FinisherPrompt", function()
	local available = canExecute()
	if not available then return end

	local pulse = 0.5 + 0.5 * math.abs(math.sin(CurTime() * 7.5))
	local red = themeColor("Finisher", Color(255, 24, 36))
	local alpha = math.floor(120 + pulse * 135)
	local x, y = ScrW() * 0.5, ScrH() * 0.72
	local width, height = math.min(ScrW() * 0.46, 720), 92

	draw.RoundedBox(3, x - width * 0.5, y - height * 0.5, width, height, Color(5, 5, 7, 145 + pulse * 45))
	surface.SetDrawColor(red.r, red.g, red.b, alpha)
	surface.DrawOutlinedRect(x - width * 0.5, y - height * 0.5, width, height, 2)
	surface.DrawRect(x - width * 0.5, y - 2, width, 3)

	for offset = 3, 1, -1 do
		draw.SimpleText("[E]  EGZEKUCJA", "EurogradFinisher", x + math.random(-offset, offset), y - 8, Color(red.r, red.g, red.b, math.floor(alpha / offset)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	draw.SimpleText("CEL W ZASIĘGU  •  ATAK OD TYŁU", "EurogradFinisherSub", x, y + 28, Color(245, 235, 236, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("PlayerButtonDown", "Eurograd.FinisherInput", function(ply, button)
	if ply ~= LocalPlayer() or button ~= executeKey then return end
	if canExecute() then RunConsoleCommand("mh_kill") end
end)
