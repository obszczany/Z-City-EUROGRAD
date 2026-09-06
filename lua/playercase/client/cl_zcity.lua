-- Z-City client integration: a compact case inventory styled after EUROGRAD.

-- Workshop installations can report "sandbox" while Z-City is active, so the
-- presentation layer intentionally does not depend on the active gamemode name.
timer.Remove("CASE_WaitForZCityClient")
if CASE_ZCITY_CLIENT_ACTIVE then return end
CASE_ZCITY_CLIENT_ACTIVE = true

hook.Remove("PreDrawHalos", "CASE_PreDrawHalos")
CaseGUI.ZCityStyle = true

-- Rendering and hit-testing share these values: this is the real inventory.
__CASE_UI_CELL_SIZE = 40
__CASE_UI_BORDER = 16

local showAppearance = CreateClientConVar("case_zcity_appearance", "1", true, false,
	"Show the Z-City character preview next to the case.", 0, 1)
local maxWeight = CreateClientConVar("case_zcity_max_weight", "35", true, false,
	"Fallback Z-City inventory capacity in kilograms.", 1, 250)

local theme = CASE_ZCITY_THEME or {}
local themeBrand = theme.Brand or {}
local themeLabels = theme.Labels or {}
local themeFonts = theme.Fonts or {}
local themeColors = theme.Colors or {}

local function themedColor(key, fallback)
	local value = themeColors[key]
	if IsColor(value) then return value end
	if istable(value) then return Color(value[1] or fallback.r, value[2] or fallback.g, value[3] or fallback.b, value[4] or fallback.a) end
	return fallback
end

local fontScale = math.Clamp(ScrH() / 1080, 0.8, 1.45)
local function scaledFont(size)
	return math.floor(size * fontScale + 0.5)
end

local interfaceFont = themeFonts.Interface or "Roboto"
local zcityFont = themeFonts.Character or "Bahnschrift"
local configuredFont = GetConVar("hg_font")
if configuredFont and configuredFont:GetString() ~= "" then zcityFont = configuredFont:GetString() end

surface.CreateFont("CaseZCityHero", {
	font = interfaceFont, size = scaledFont(27), weight = 500, antialias = true, extended = true
})
surface.CreateFont("CaseZCityTitle", {
	font = interfaceFont, size = scaledFont(18), weight = 500, antialias = true, extended = true
})
surface.CreateFont("CaseZCityBody", {
	font = interfaceFont, size = scaledFont(14), weight = 500, antialias = true, extended = true
})
surface.CreateFont("CaseZCityTiny", {
	font = interfaceFont, size = scaledFont(10), weight = 400, antialias = true, extended = true
})
surface.CreateFont("CaseZCityMicro", {
	font = interfaceFont, size = scaledFont(8), weight = 500, antialias = true, extended = true
})
surface.CreateFont("CaseZCityName", {
	font = zcityFont, size = scaledFont(34), weight = 1100, antialias = true, extended = true
})
surface.CreateFont("CaseZCityNameSub", {
	font = zcityFont, size = scaledFont(12), weight = 700, antialias = true, extended = true
})

local colText = themedColor("Text", Color(242, 245, 248, 245))
local colDim = themedColor("Dim", Color(173, 183, 196, 205))
local colBlue = themedColor("Primary", Color(22, 132, 255, 235))
local colBlueSoft = themedColor("PrimarySoft", Color(69, 157, 255, 205))
local colPink = themedColor("Secondary", Color(230, 72, 132, 220))
local colDanger = themedColor("Danger", Color(244, 83, 93, 235))
local colPanel = themedColor("Panel", Color(13, 18, 28, 178))
local colBorder = themedColor("Border", Color(185, 199, 215, 80))

local materialCache = {}
local function smoothMaterial(path)
	if not path or path == "" then return nil end
	if materialCache[path] == nil then
		local mat = Material(path, "smooth")
		materialCache[path] = mat and not mat:IsError() and mat or false
	end
	return materialCache[path] or nil
end

local moodleIconPaths = {
	pain = "vgui/hud/status_pain_icon.png",
	conscious = "vgui/hud/status_conscious_icon.png",
	stamina = "vgui/hud/status_stamina_icon.png",
	bleeding = "vgui/hud/status_bleeding_icon.png",
	internal_bleed = "vgui/hud/status_internal_bleed_icon.png",
	organ_damage = "vgui/hud/status_organ_damage.png",
	dislocation = "vgui/hud/status_dislocation.png",
	spine_fracture = "vgui/hud/status_spine_fracture.png",
	fracture = "vgui/hud/status_leg_fracture.png",
	blood_loss = "vgui/hud/status_blood_loss.png",
	cardiac_arrest = "vgui/hud/status_cardiac_arrest.png",
	cold = "vgui/hud/status_cold.png",
	heat = "vgui/hud/status_heat.png",
	hemothorax = "vgui/hud/status_hemothorax.png",
	lungs_failure = "vgui/hud/status_lungs_failure.png",
	overdose = "vgui/hud/status_overdose.png",
	oxygen = "vgui/hud/status_oxygen.png",
	vomit = "vgui/hud/status_vomit.png",
	brain_damage = "vgui/hud/status_brain_damage.png",
	adrenaline = "vgui/hud/status_adrenaline.png",
	shock = "vgui/hud/status_shock.png",
	trauma = "vgui/hud/status_trauma.png",
	death = "vgui/hud/status_death.png",
	berserk = "vgui/hud/status_berserk.png",
	amputant = "vgui/hud/status_amputant.png",
	bleedartery = "vgui/hud/status_bleedartery.png",
	arrhythmia = "vgui/hud/status_arrhythmia.png",
	fibrillation = "vgui/hud/status_fibrillation.png"
}

local bodySpritePaths = {
	head = "vgui/hud/health_head.png",
	torso = "vgui/hud/health_torso.png",
	right_arm = "vgui/hud/health_right_arm.png",
	left_arm = "vgui/hud/health_left_arm.png",
	right_leg = "vgui/hud/health_right_leg.png",
	left_leg = "vgui/hud/health_left_leg.png"
}

local function getCapacity(ply)
	local fallback = maxWeight:GetFloat()
	if not IsValid(ply) then return fallback end
	return math.max(ply:GetNW2Float("ZCityInventoryMaxWeight", fallback), 1)
end

local function getDisplayedInventory()
	if CaseGUI.IsOpen and CaseGUI.FakePlayerInv and CaseGUI.FakePlayerInv.Items then
		return CaseGUI.FakePlayerInv
	end
	return IsValid(LocalPlayer()) and CaseInv(LocalPlayer()) or nil
end

function CaseGUI.GetZCityWeight()
	return CaseInventory:GetInventoryWeight(getDisplayedInventory())
end

local removePreviewArmors
local function copyPlayerAppearance(viewer, ent)
	local ply = LocalPlayer()
	if not IsValid(ply) or not IsValid(ent) then return end

	local model = ply:GetModel()
	if model and model ~= "" and util.IsValidModel(model) and ent:GetModel() ~= model then
		removePreviewArmors(viewer)
		viewer:SetModel(model)
		ent = viewer.Entity
		if not IsValid(ent) then return end
	end

	ent:SetSkin(ply:GetSkin())
	ent:SetColor(ply:GetColor())
	ent:SetMaterial(ply:GetMaterial() or "")
	ent:SetNWVector("PlayerColor", ply:GetNWVector("PlayerColor", Vector(1, 1, 1)))
	ent.GetPlayerColor = function(modelEntity)
		return modelEntity:GetNWVector("PlayerColor", Vector(1, 1, 1))
	end
	viewer.ZCityArmors = ply.GetNetVar and (ply:GetNetVar("Armor") or ply.armors) or ply.armors

	for _, bodygroup in ipairs(ply:GetBodyGroups()) do
		ent:SetBodygroup(bodygroup.id, ply:GetBodygroup(bodygroup.id))
	end

	local materials = ply:GetMaterials()
	for index = 0, #materials - 1 do
		ent:SetSubMaterial(index, ply:GetSubMaterial(index) or "")
	end

	local sequence = ent:LookupSequence("idle_suitcase")
	if sequence < 0 then sequence = ent:LookupSequence("idle_all") end
	if sequence >= 0 and ent:GetSequence() ~= sequence then ent:ResetSequence(sequence) end
	viewer.ZCityAccessories = ply.GetNetVar and (ply:GetNetVar("Accessories") or ply.PredictedAccessories) or nil
end

local function getCharacterName(ply)
	if not IsValid(ply) then return "NIEZNANY" end
	local name = ply:GetNWString("PlayerName", "")
	if name == "" and ply.GetPlayerName then name = ply:GetPlayerName() or "" end
	if name == "" then name = ply:Nick() end
	return string.upper(name)
end

local function getZCityEquipment(ply)
	local inventory = IsValid(ply) and ply.GetNetVar and ply:GetNetVar("Inventory", {}) or {}
	local weapons = istable(inventory) and inventory.Weapons or {}
	local armors = IsValid(ply) and ply.GetNetVar and ply:GetNetVar("Armor", {}) or {}
	if not istable(armors) then armors = {} end

	local headKey = armors.head or armors.face or armors.ears
	local torsoKey = armors.torso
	local armorNames = hg and hg.armorNames or {}
	local armorIcons = hg and hg.armorIcons or {}

	return {
		{label = "SLING", value = weapons and weapons.hg_sling and "ZAŁOŻONY" or "PUSTO", active = weapons and weapons.hg_sling, icon = "vgui/inventory/tactical_sling"},
		{label = "LATARKA", value = weapons and weapons.hg_flashlight and "ZAŁOŻONA" or "PUSTO", active = weapons and weapons.hg_flashlight, icon = "vgui/hud/hmcd_flash"},
		{label = "GŁOWA", value = headKey and (armorNames[headKey] or language.GetPhrase(headKey)) or "PUSTO", active = headKey ~= nil, icon = headKey and armorIcons[headKey] or "vgui/icons/helmet.png"},
		{label = "PANCERZ", value = torsoKey and (armorNames[torsoKey] or language.GetPhrase(torsoKey)) or "PUSTO", active = torsoKey ~= nil, icon = torsoKey and armorIcons[torsoKey] or "vgui/icons/armor01.png"}
	}
end

local function orgNumber(org, key, fallback)
	local value = org and org[key]
	return isnumber(value) and value or (fallback or 0)
end

local function getOxygen(org)
	local oxygen = org and org.o2
	if istable(oxygen) then return tonumber(oxygen[1]) or 30 end
	return tonumber(oxygen) or 30
end

local function severityHigh(value, two, three, four, reversed)
	if reversed then
		if value <= four then return 4 elseif value <= three then return 3 elseif value <= two then return 2 end
	else
		if value >= four then return 4 elseif value >= three then return 3 elseif value >= two then return 2 end
	end
	return 1
end

local function collectMoodles(ply)
	local org = IsValid(ply) and ply.organism or nil
	if not org then return {{name = "conscious", level = 1, title = "OCZEKIWANIE NA DANE", description = "Moodles synchronizuje stan organizmu.", priority = 999}} end

	local effects = {}
	local function add(name, level, title, description, priority)
		effects[#effects + 1] = {name = name, level = level or 1, title = title, description = description, priority = priority or 50}
	end

	if not ply:Alive() or org.alive == false then
		add("death", 4, "ŚMIERĆ", "Brak oznak życia.", -100)
		return effects
	end

	local blood = orgNumber(org, "blood", 5000)
	local pulse = orgNumber(org, "pulse", orgNumber(org, "heartbeat", 70))
	local heartbeat = orgNumber(org, "heartbeat", 70)
	local temperature = orgNumber(org, "temperature", 36.7)
	local oxygen = getOxygen(org)
	local pain = orgNumber(org, "pain", 0)

	local arterial = org.arteria == 1 or org.rarmarteria == 1 or org.larmarteria == 1 or org.rlegarteria == 1 or org.llegarteria == 1
	local arterialWounds = ply.GetNetVar and ply:GetNetVar("arterialwounds")
	if arterial or (istable(arterialWounds) and next(arterialWounds)) then add("bleedartery", 4, "KRWOTOK TĘTNICZY", "Uszkodzona tętnica — natychmiast zatamuj krwawienie.", 1) end
	if org.heartstop == true or heartbeat < 1 then add("cardiac_arrest", 4, "ZATRZYMANIE SERCA", "Serce nie pompuje krwi. Wymagana natychmiastowa pomoc.", 2) end
	if blood < 4700 then add("blood_loss", severityHigh(blood, 4500, 3600, 2500, true), "UTRATA KRWI", string.format("Pozostało około %.0f ml krwi.", blood), 3) end
	if orgNumber(org, "bleed", 0) > 0.1 then add("bleeding", 2, "KRWAWIENIE", "Krew wypływa z otwartych ran.", 4) end
	if orgNumber(org, "internalBleed", 0) > 0.1 then add("internal_bleed", 3, "KRWAWIENIE WEWNĘTRZNE", "Krew gromadzi się wewnątrz organizmu.", 5) end
	if pain > 10 and not org.berserkActive2 then add("pain", severityHigh(pain, 25, 40, 60), "BÓL", string.format("Poziom bólu: %.0f.", pain), 6) end
	if pulse <= 20 and heartbeat >= 200 then add("fibrillation", 4, "MIGOTANIE", "Chaotyczna praca serca i krytycznie niski puls.", 7)
	elseif pulse <= 40 and heartbeat >= 170 then add("arrhythmia", 3, "ARYTMIA", "Rytm serca jest niebezpiecznie zaburzony.", 7) end

	if temperature < 36 then add("cold", severityHigh(temperature, 35, 33, 31, true), "WYCHŁODZENIE", "Organizm traci ciepło i działa coraz wolniej.", 8)
	elseif temperature > 37 then add("heat", severityHigh(temperature, 38, 39, 40), "PRZEGRZANIE", "Temperatura ciała jest zbyt wysoka.", 8) end
	if oxygen < 28 then add("oxygen", severityHigh(oxygen, 23, 14, 8, true), "NIEDOTLENIENIE", string.format("Poziom tlenu: %.0f.", oxygen), 9) end
	if org.lungsfunction == false then add("lungs_failure", 4, "NIEWYDOLNOŚĆ PŁUC", "Płuca przestały prawidłowo pracować.", 10) end
	if orgNumber(org, "pneumothorax", 0) > 0.01 then add("hemothorax", 3, "URAZ KLATKI PIERSIOWEJ", "Oddychanie jest utrudnione przez uszkodzenie płuc.", 11) end
	if orgNumber(org, "brain", 0) > 0.01 then add("brain_damage", 3, "URAZ MÓZGU", "Funkcje poznawcze i świadomość są zaburzone.", 12) end
	if orgNumber(org, "shock", 0) > 20 then add("shock", 3, "WSTRZĄS", "Organizm reaguje na ciężki uraz i ból.", 13) end
	if orgNumber(org, "disorientation", 0) > 0.2 then add("trauma", 2, "DEZORIENTACJA", "Zawroty głowy i zaburzona orientacja.", 14) end
	if orgNumber(org, "wantToVomit", 0) > 0.2 then add("vomit", 2, "NUDNOŚCI", "Silny dyskomfort i odruch wymiotny.", 15) end
	if orgNumber(org, "analgesia", 0) > 0.1 then add("overdose", 2, "ŚRODKI PRZECIWBÓLOWE", "Wysokie stężenie substancji obciąża organizm.", 16) end
	if orgNumber(org, "adrenaline", 0) > 0.3 then add("adrenaline", 1, "ADRENALINA", "Podwyższona gotowość, tętno i odporność na ból.", 17) end
	if org.berserkActive2 then add("berserk", 4, "???", "Instynkt przejmuje kontrolę nad organizmem.", 0) end

	local amputated = org.llegamputated or org.rlegamputated or org.larmamputated or org.rarmamputated
	if amputated then add("amputant", 4, "AMPUTACJA", "Brakuje jednej lub kilku kończyn.", 18) end
	local fractured = orgNumber(org, "lleg", 0) >= 0.95 or orgNumber(org, "rleg", 0) >= 0.95 or orgNumber(org, "larm", 0) >= 0.95 or orgNumber(org, "rarm", 0) >= 0.95
	if fractured then add("fracture", 3, "ZŁAMANIE", "Uszkodzona kończyna ma ograniczoną sprawność.", 19) end
	local spine = math.max(orgNumber(org, "spine1", 0), orgNumber(org, "spine2", 0), orgNumber(org, "spine3", 0))
	if spine >= 0.95 then add("spine_fracture", 4, "URAZ KRĘGOSŁUPA", "Kręgosłup został poważnie uszkodzony.", 20) end
	if org.llegdislocation or org.rlegdislocation or org.larmdislocation or org.rarmdislocation or org.jawdislocation then add("dislocation", 2, "ZWICHNIĘCIE", "Staw wymaga nastawienia.", 21) end

	local consciousness = orgNumber(org, "consciousness", 1) * 100
	if consciousness < 90 then add("conscious", severityHigh(consciousness, 74, 49, 24, true), "ŚWIADOMOŚĆ", string.format("Świadomość: %.0f%%.", consciousness), 22) end
	local stamina = org.stamina
	if istable(stamina) then
		local staminaMax = tonumber(stamina.max) or 180
		local staminaPercent = staminaMax > 0 and (tonumber(stamina[1]) or staminaMax) / staminaMax * 100 or 100
		if staminaPercent < 75 then add("stamina", severityHigh(staminaPercent, 74, 49, 24, true), "WYCZERPANIE", string.format("Kondycja: %.0f%%.", staminaPercent), 23) end
	end

	if #effects == 0 then add("conscious", 1, "STAN STABILNY", "Brak wykrytych dolegliwości.", 999) end
	table.sort(effects, function(a, b) return a.priority < b.priority end)
	return effects
end

local function drawLine(points, color, width)
	surface.SetDrawColor(color)
	for i = 1, #points - 1 do
		surface.DrawLine(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2])
		if width and width > 1 then
			surface.DrawLine(points[i][1], points[i][2] + 1, points[i + 1][1], points[i + 1][2] + 1)
		end
	end
end

local function drawTileIcon(kind, cx, cy, size, color)
	surface.SetDrawColor(color)
	draw.NoTexture()

	if kind == "blood" then
		surface.DrawPoly({
			{x = cx, y = cy - size * 0.52},
			{x = cx - size * 0.34, y = cy + size * 0.04},
			{x = cx - size * 0.27, y = cy + size * 0.34},
			{x = cx, y = cy + size * 0.48},
			{x = cx + size * 0.27, y = cy + size * 0.34},
			{x = cx + size * 0.34, y = cy + size * 0.04}
		})
	elseif kind == "temperature" then
		surface.DrawOutlinedRect(cx - size * 0.1, cy - size * 0.48, size * 0.2, size * 0.64, 2)
		surface.DrawRect(cx - size * 0.045, cy - size * 0.13, size * 0.09, size * 0.39)
		surface.DrawCircle(cx, cy + size * 0.3, size * 0.18, color.r, color.g, color.b, color.a)
	elseif kind == "pulse" then
		drawLine({
			{cx - size * 0.55, cy}, {cx - size * 0.22, cy},
			{cx - size * 0.09, cy - size * 0.28}, {cx + size * 0.04, cy + size * 0.34},
			{cx + size * 0.17, cy - size * 0.13}, {cx + size * 0.29, cy},
			{cx + size * 0.55, cy}
		}, color, 2)
	elseif kind == "pain" then
		surface.DrawCircle(cx, cy - size * 0.06, size * 0.35, color.r, color.g, color.b, color.a)
		drawLine({{cx + size * 0.2, cy + size * 0.18}, {cx + size * 0.34, cy + size * 0.45}}, color, 2)
		drawLine({{cx - size * 0.11, cy - size * 0.13}, {cx + size * 0.04, cy - size * 0.03}, {cx - size * 0.02, cy + size * 0.13}}, color, 2)
	elseif kind == "face" then
		surface.DrawCircle(cx - size * 0.23, cy, size * 0.2, color.r, color.g, color.b, color.a)
		surface.DrawCircle(cx + size * 0.23, cy, size * 0.2, color.r, color.g, color.b, color.a)
		surface.DrawLine(cx - size * 0.03, cy, cx + size * 0.03, cy)
		surface.DrawLine(cx - size * 0.44, cy - size * 0.08, cx - size * 0.58, cy - size * 0.18)
		surface.DrawLine(cx + size * 0.44, cy - size * 0.08, cx + size * 0.58, cy - size * 0.18)
	elseif kind == "head" then
		surface.DrawOutlinedRect(cx - size * 0.35, cy - size * 0.28, size * 0.7, size * 0.45, 2)
		surface.DrawRect(cx - size * 0.48, cy + size * 0.15, size * 0.96, size * 0.1)
	elseif kind == "body" then
		surface.DrawPoly({
			{x = cx - size * 0.48, y = cy + size * 0.42},
			{x = cx - size * 0.34, y = cy - size * 0.24},
			{x = cx - size * 0.1, y = cy - size * 0.4},
			{x = cx, y = cy - size * 0.18},
			{x = cx + size * 0.1, y = cy - size * 0.4},
			{x = cx + size * 0.34, y = cy - size * 0.24},
			{x = cx + size * 0.48, y = cy + size * 0.42}
		})
	end
end

local function fitValue(value)
	value = tostring(value or "PUSTO")
	if #value > 15 then return string.upper(string.Left(value, 13)) .. "..." end
	return string.upper(value)
end

local function drawInfoTile(x, y, w, h, label, value, accent, icon, materialPath, active)
	draw.RoundedBox(5, x, y, w, h, colPanel)
	surface.SetDrawColor(colBorder)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(active and accent or Color(105, 116, 132, 105))
	surface.DrawRect(x, y, 2, h)
	draw.SimpleText(label, "CaseZCityMicro", x + 9, y + 7, colDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	local mat = smoothMaterial(materialPath)
	if mat then
		surface.SetDrawColor(255, 255, 255, active and 235 or 72)
		surface.SetMaterial(mat)
		local iconSize = math.floor(math.min(w, h) * 0.47)
		surface.DrawTexturedRect(x + (w - iconSize) * 0.5, y + h * 0.18, iconSize, iconSize)
	else
		drawTileIcon(icon, x + w * 0.5, y + h * 0.47, math.min(w, h) * 0.32, Color(235, 240, 246, active and 225 or 70))
	end
	draw.SimpleText(fitValue(value), "CaseZCityTiny", x + w * 0.5, y + h - 8, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

local function severityColor(level)
	if level >= 4 then return Color(245, 64, 80, 235) end
	if level == 3 then return Color(239, 109, 62, 230) end
	if level == 2 then return Color(232, 169, 65, 225) end
	return Color(77, 185, 126, 225)
end

local function drawMoodleRow(effect, x, y, w, h)
	local accent = severityColor(effect.level or 1)
	draw.RoundedBox(5, x, y, w, h, Color(12, 17, 27, 188))
	surface.SetDrawColor(colBorder)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(accent)
	surface.DrawRect(x, y, 2, h)

	local iconSize = math.floor(h - 8)
	local iconX = x + 7
	local iconY = y + 4
	local background = smoothMaterial("vgui/hud/status_level" .. tostring(math.Clamp(effect.level or 1, 1, 4)) .. "_bg.png")
	if background then
		surface.SetDrawColor(255, 255, 255, 215)
		surface.SetMaterial(background)
		surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
	end
	local icon = smoothMaterial(moodleIconPaths[effect.name])
	if icon then
		surface.SetDrawColor(255, 255, 255, 245)
		surface.SetMaterial(icon)
		surface.DrawTexturedRect(iconX + 2, iconY + 2, iconSize - 4, iconSize - 4)
	end

	local textX = iconX + iconSize + 10
	draw.SimpleText(effect.title, "CaseZCityTiny", textX, y + 7, colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(effect.description, "CaseZCityMicro", textX, y + h - 9, colDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end

local bodyLayout = {
	{name = "head", x = 55, y = -15, w = 40, h = 40, keys = {"skull", "jaw"}, amput = "headamputated"},
	{name = "torso", x = 54, y = 33, w = 56, h = 72, keys = {"chest", "spine1", "spine2", "spine3", "pelvis"}},
	{name = "right_arm", x = 83, y = 36, w = 40, h = 80, keys = {"rarm"}, amput = "rarmamputated"},
	{name = "left_arm", x = 24, y = 38, w = 40, h = 80, keys = {"larm"}, amput = "larmamputated"},
	{name = "right_leg", x = 66, y = 92, w = 48, h = 140, keys = {"rleg"}, amput = "rlegamputated"},
	{name = "left_leg", x = 35, y = 106, w = 48, h = 108, keys = {"lleg"}, amput = "llegamputated"}
}

local function getLimbDamage(org, keys)
	local damage = 0
	for _, key in ipairs(keys) do damage = math.max(damage, orgNumber(org, key, 0)) end
	return math.Clamp(damage, 0, 1)
end

local function limbColor(damage, amputated)
	if amputated then return Color(245, 64, 80, 52) end
	if damage <= 0.01 then return Color(205, 216, 226, 138) end
	if damage < 0.5 then return Color(255, 205 - damage * 80, 58, 225) end
	return Color(255, math.floor(145 * (1 - damage)), 40, 240)
end

local function drawBodyMonitor(ply, w, h)
	local org = IsValid(ply) and ply.organism or nil
	local scale = math.Clamp(h / 940, 0.82, 1.45)
	local panelW = math.floor(148 * scale)
	local panelH = math.floor(245 * scale)
	local panelX = w - panelW - scaledFont(34)
	local panelY = scaledFont(112)

	draw.RoundedBox(6, panelX, panelY, panelW, panelH, Color(10, 15, 24, 112))
	surface.SetDrawColor(Color(163, 187, 216, 35))
	surface.DrawOutlinedRect(panelX, panelY, panelW, panelH, 1)
	draw.SimpleText(themeLabels.Body or "MOODLES / CIAŁO", "CaseZCityMicro", panelX + panelW - 10, panelY + 9, colDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local originX = panelX + math.floor(20 * scale)
	local originY = panelY + math.floor(58 * scale)
	for _, limb in ipairs(bodyLayout) do
		local path = bodySpritePaths[limb.name]
		if IsValid(ply) and ply.PlayerClassName == "furry" then path = string.Replace(path, ".png", "furry.png") end
		local mat = smoothMaterial(path)
		if mat then
			local damage = org and getLimbDamage(org, limb.keys) or 0
			local amputated = org and limb.amput and org[limb.amput] == true
			surface.SetDrawColor(limbColor(damage, amputated))
			surface.SetMaterial(mat)
			local drawW = math.floor(limb.w * scale)
			local drawH = math.floor(limb.h * scale)
			local drawX = originX + math.floor(limb.x * scale) - drawW * 0.5
			local drawY = originY + math.floor(limb.y * scale) - drawH * 0.5
			surface.DrawTexturedRect(drawX, drawY, drawW, drawH)
		end
	end
end

removePreviewArmors = function(viewer)
	if not viewer or not viewer.PreviewArmorModels then return end
	for _, record in pairs(viewer.PreviewArmorModels) do
		local model = istable(record) and record.model or record
		if IsValid(model) then model:Remove() end
	end
	viewer.PreviewArmorModels = {}
end

local function playerLooksFemale(ent)
	if isfunction(ThatPlyIsFemale) then return ThatPlyIsFemale(ent) end
	return string.find(string.lower(ent:GetModel() or ""), "female", 1, true) ~= nil
end

local function drawPreviewArmors(viewer, ent)
	if not hg or not hg.armor or not istable(viewer.ZCityArmors) then return end
	viewer.PreviewArmorModels = viewer.PreviewArmorModels or {}
	local activePlacements = {}
	local sourcePly = LocalPlayer()

	for placement, armorKey in pairs(viewer.ZCityArmors) do
		local armorData = hg.armor[placement] and hg.armor[placement][armorKey]
		if armorData and armorData.model and armorData.model ~= "" then
			activePlacements[placement] = true

			local record = viewer.PreviewArmorModels[placement]
			if record and record.key ~= armorKey then
				if IsValid(record.model) then record.model:Remove() end
				record = nil
			end
			if not record or not IsValid(record.model) then
				local previewModel = ClientsideModel(armorData.model, RENDERGROUP_OPAQUE)
				if IsValid(previewModel) then
					previewModel:SetNoDraw(true)
					record = {key = armorKey, model = previewModel}
					viewer.PreviewArmorModels[placement] = record
				end
			end

			if record and IsValid(record.model) then
				local model = record.model
				local female = playerLooksFemale(ent)
				model:SetModelScale((female and armorData.femscale) or armorData.scale or 1, 0)
				local fallbackMaterial = istable(armorData.material) and armorData.material[1] or armorData.material
				local selectedMaterial = IsValid(sourcePly) and sourcePly:GetNWString("ArmorMaterials" .. armorKey, fallbackMaterial or "") or (fallbackMaterial or "")
				model:SetSubMaterial(0, selectedMaterial ~= "" and selectedMaterial or nil)
				if IsValid(sourcePly) then model:SetSkin(sourcePly:GetNWInt("ArmorSkins" .. armorKey, 0)) end

				if armorData.nobonemerge then
					model:RemoveEffects(EF_BONEMERGE)
					model:SetParent(nil)
					local boneID = armorData.bone and ent:LookupBone(armorData.bone)
					local matrix = boneID and ent:GetBoneMatrix(boneID)
					if matrix then
						local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
						local femPos = female and armorData.femPos or nil
						if femPos then bonePos:Add(boneAng:Forward() * femPos[1] + boneAng:Up() * femPos[2] + boneAng:Right() * femPos[3]) end
						local pos, ang = LocalToWorld(armorData[3] or vector_origin, armorData[4] or angle_zero, bonePos, boneAng)
						model:SetRenderOrigin(pos)
						model:SetRenderAngles(ang)
						model:DrawModel()
					end
				else
					if model:GetParent() ~= ent then model:SetParent(ent) end
					model:AddEffects(EF_BONEMERGE)
					model:DrawModel()
				end
			end
		end
	end

	for placement, record in pairs(viewer.PreviewArmorModels) do
		if not activePlacements[placement] then
			if IsValid(record.model) then record.model:Remove() end
			viewer.PreviewArmorModels[placement] = nil
		end
	end
end

local function drawBackdrop(panel, w, h)
	-- PaintManual bypasses DFrame's normal blur pass, so draw it explicitly.
	if IsValid(panel) and Derma_DrawBackgroundBlur then
		Derma_DrawBackgroundBlur(panel, CaseGUI.ZCityBlurStarted or SysTime())
	end

	-- Soft, hand-interpolated washes avoid the hard vertical seams produced by
	-- Source's stock gradient materials at ultrawide/high-DPI resolutions.
	surface.SetDrawColor(3, 6, 11, 84)
	surface.DrawRect(0, 0, w, h)

	local steps = 128
	local stripW = math.ceil(w / steps)
	for i = 0, steps - 1 do
		local progress = i / (steps - 1)
		local alpha = math.floor(Lerp(progress, 76, 6))
		surface.SetDrawColor(8, 43, 96, alpha)
		surface.DrawRect(i * stripW, 0, stripW + 1, h)
	end

	local stripH = math.ceil(h * 0.52 / 64)
	for i = 0, 63 do
		local progress = i / 63
		surface.SetDrawColor(2, 5, 10, math.floor(Lerp(progress, 0, 145)))
		surface.DrawRect(0, h * 0.48 + i * stripH, w, stripH + 1)
	end
end

local function isPauseMenuVisible()
	return gui.IsGameUIVisible() or (MainMenu and IsValid(MainMenu))
end

local function paintOverlay(_, w, h)
	local ply = LocalPlayer()
	local main = CaseGUI.MainWindow
	if not IsValid(main) then return end

	local invX, invY = main:GetPos()
	local invW, invH = main:GetSize()
	local weight = CaseGUI.GetZCityWeight()
	local capacity = getCapacity(ply)
	local fraction = math.Clamp(weight / capacity, 0, 1)
	local weightColor = fraction >= 0.9 and colDanger or (fraction >= 0.7 and colPink or colBlueSoft)

	draw.SimpleText(themeLabels.Inventory or "EKWIPUNEK", "CaseZCityHero", invX, invY - scaledFont(58), colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(themeLabels.InventorySubtitle or "PRZEDMIOTY OSOBISTE", "CaseZCityTiny", invX + 2, invY - scaledFont(28), colDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(string.format("%.1f / %.1f KG", weight, capacity), "CaseZCityBody", invX + invW, invY - scaledFont(32), weightColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local barY = invY - scaledFont(10)
	draw.RoundedBox(2, invX, barY, invW, 3, Color(209, 221, 232, 38))
	draw.RoundedBox(2, invX, barY, math.max(3, math.floor(invW * fraction)), 3, weightColor)
	surface.SetDrawColor(colPink)
	surface.DrawRect(invX, barY, math.floor(invW * 0.16), 2)

	local characterName = getCharacterName(ply)
	local roleName = IsValid(ply) and ply.role and ply.role.name or (themeBrand.RoleFallback or "Z-CITY / EUROGRAD")
	draw.SimpleText(characterName, "CaseZCityName", w - scaledFont(34), scaledFont(25), Color(5, 8, 14, 185), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(characterName, "CaseZCityName", w - scaledFont(36), scaledFont(23), colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(string.upper(tostring(roleName)), "CaseZCityNameSub", w - scaledFont(36), scaledFont(61), colBlueSoft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	surface.SetDrawColor(Color(60, 151, 255, 135))
	surface.DrawRect(w - math.floor(w * 0.22), scaledFont(84), math.floor(w * 0.22) - scaledFont(36), 2)
	drawBodyMonitor(ply, w, h)

	local rightX = math.floor(w * 0.655)
	local infoY = math.floor(h * 0.64)
	local gap = math.max(8, math.floor(w * 0.005))
	local tileH = math.floor(h * 0.075)
	local tileW = tileH
	local equipment = getZCityEquipment(ply)

	draw.SimpleText(themeLabels.Equipment or "WYPOSAŻENIE", "CaseZCityTitle", rightX, infoY - scaledFont(31), colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	for index, item in ipairs(equipment) do
		local accent = index % 2 == 0 and colPink or colBlueSoft
		drawInfoTile(rightX + (tileW + gap) * (index - 1), infoY, tileW, tileH, item.label, item.value, accent, index <= 2 and "body" or "head", item.icon, item.active)
	end

	local org = IsValid(ply) and ply.organism or nil
	local temperature = org and tonumber(org.temperature) or nil
	local statusY = infoY + tileH + scaledFont(48)
	draw.SimpleText(themeLabels.Status or "STATUS", "CaseZCityTitle", rightX, statusY - scaledFont(31), colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	local tempText = temperature and string.format("TEMP.  %.1f °C", temperature) or "TEMP.  SYNC"
	draw.SimpleText(tempText, "CaseZCityBody", rightX + (tileW + gap) * 4 - gap, statusY - scaledFont(28), temperature and (temperature < 36 or temperature > 37) and colDanger or colBlueSoft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local moodles = collectMoodles(ply)
	local statusWidth = math.min(math.floor(w * 0.31), scaledFont(430))
	local rowHeight = math.max(43, scaledFont(48))
	for index = 1, math.min(3, #moodles) do
		drawMoodleRow(moodles[index], rightX, statusY + (index - 1) * (rowHeight + 6), statusWidth, rowHeight)
	end
	if #moodles > 3 then
		draw.SimpleText("+ " .. tostring(#moodles - 3) .. " DALSZE OBJAWY", "CaseZCityMicro", rightX + statusWidth, statusY + rowHeight * 3 + 12, colDanger, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	end

	local brandPrefix = tostring(themeBrand.Prefix or "EURO")
	local brandSuffix = tostring(themeBrand.Suffix or "GRAD")
	local brandX = scaledFont(36)
	draw.SimpleText(brandPrefix, "CaseZCityTitle", brandX, scaledFont(32), colBlue, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	surface.SetFont("CaseZCityTitle")
	local prefixWidth = surface.GetTextSize(brandPrefix)
	draw.SimpleText(brandSuffix, "CaseZCityTitle", brandX + prefixWidth, scaledFont(32), colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(themeLabels.CloseHint or "[I] ZAMKNIJ    [RMB] OPCJE    [R] OBRÓĆ", "CaseZCityTiny", invX, invY + invH + scaledFont(15), colDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function styleInventoryWindow()
	local main = CaseGUI.MainWindow
	if not IsValid(main) then return end

	local _, invH = main:GetSize()
	main:SetPos(math.floor(ScrW() * 0.285), ScrH() - invH - math.floor(ScrH() * 0.085))
	main.Paint = function() end
	main:SetTitle("")
	main:ShowCloseButton(false)

	if IsValid(CaseGUI.SortingWindow) then CaseGUI.SortingWindow:SetVisible(false) end
	for _, child in ipairs(main:GetChildren()) do
		if child:GetWide() < 100 and child:GetTall() < 100 then child:SetVisible(false) end
	end
end

local function createAppearancePanel()
	if not showAppearance:GetBool() or not CaseGUI.IsOpen or not IsValid(CaseGUI.MainWindow) then return end
	if IsValid(CaseGUI.AppearancePanel) then CaseGUI.AppearancePanel:Remove() end

	local panel = vgui.Create("DPanel")
	panel:SetPos(0, 0)
	panel:SetSize(ScrW(), ScrH())
	panel:SetPaintedManually(true)
	panel:SetMouseInputEnabled(false)
	panel:SetKeyboardInputEnabled(false)
	panel.Paint = drawBackdrop
	panel.PaintOver = paintOverlay

	local viewer = vgui.Create("DModelPanel", panel)
	viewer:SetPos(math.floor(ScrW() * 0.535), 0)
	viewer:SetSize(math.floor(ScrW() * 0.45), ScrH())
	viewer:SetFOV(24)
	viewer:SetCamPos(Vector(72, 0, 55))
	viewer:SetLookAt(Vector(0, 0, 52))
	viewer:SetAmbientLight(Color(58, 63, 72))
	viewer:SetDirectionalLight(BOX_FRONT, Color(238, 229, 218))
	viewer:SetDirectionalLight(BOX_RIGHT, Color(52, 125, 224))
	viewer:SetDirectionalLight(BOX_LEFT, Color(112, 45, 77))
	viewer:SetModel(IsValid(LocalPlayer()) and LocalPlayer():GetModel() or "models/player/group01/male_01.mdl")
	viewer:SetMouseInputEnabled(false)

	function viewer:LayoutEntity(ent)
		if not IsValid(ent) then return end
		if (self.NextAppearanceCopy or 0) <= CurTime() then
			copyPlayerAppearance(self, ent)
			self.NextAppearanceCopy = CurTime() + 0.2
			ent = self.Entity
			if not IsValid(ent) then return end
		end
		ent:SetAngles(Angle(0, math.sin(RealTime() * 0.3) * 1.5, 0))
		ent:FrameAdvance(FrameTime())
	end

	function viewer:PostDrawModel(ent)
		if not IsValid(ent) then return end
		ent:SetupBones()
		if istable(self.ZCityAccessories) and isfunction(DrawAccesories) then
			for _, accessory in ipairs(self.ZCityAccessories) do
				local data = hg and hg.Accessories and hg.Accessories[accessory]
				if data then DrawAccesories(ent, ent, accessory, data, false, true) end
			end
		end
		drawPreviewArmors(self, ent)
	end

	function viewer:OnRemove()
		removePreviewArmors(self)
	end

	copyPlayerAppearance(viewer, viewer.Entity)
	CaseGUI.ZCityBlurStarted = SysTime()
	panel:SetAlpha(0)
	panel:AlphaTo(255, 0.18, 0)
	CaseGUI.AppearancePanel = panel
end

-- Manual paint order avoids Linux VGUI clipping. Hide it under the ESC menu.
hook.Remove("PostDrawHUD", "CASE_PostDrawHUD")
hook.Remove("PostDrawHUD", "CASE_ZCityAppearancePaint")
hook.Add("PostDrawHUD", "CASE_ZCityCompositeHUD", function()
	if not CaseGUI.IsOpen or isPauseMenuVisible() then return end
	cam.Start2D()
		if IsValid(CaseGUI.AppearancePanel) then CaseGUI.AppearancePanel:PaintManual() end
		if IsValid(CaseGUI.MainWindow) then CaseGUI.MainWindow:PaintManual() end
	cam.End2D()
end)

local originalOpenInventory = CaseGUI.OpenInventory
function CaseGUI.OpenInventory(silent)
	originalOpenInventory(silent)
	if not CaseGUI.IsOpen then return end
	styleInventoryWindow()
	createAppearancePanel()
end

local originalClose = CaseGUI.Close
function CaseGUI:Close(silent)
	if IsValid(self.AppearancePanel) then self.AppearancePanel:Remove() end
	self.AppearancePanel = nil
	return originalClose(self, silent)
end

local originalDropItem = CaseInventory.ClientNet.DropItem
function CaseInventory.ClientNet.DropItem(invID, count, sync)
	local inv = CaseGUI.IsOpen and CaseGUI.FakePlayerInv or CaseInv(LocalPlayer())
	local invInfo = inv and inv.Items and inv.Items[invID]
	local itemInfo = invInfo and CaseInventory:GetItemInfo(invInfo.ItemID)

	if itemInfo and itemInfo.ItemType == CASE_ITEM_AMMO and itemInfo.AmmoID >= 0 then
		local amount = count == -1 and invInfo.Count or math.min(count, invInfo.Count)
		if amount > 0 then
			net.Start("drop_ammo")
			net.WriteFloat(itemInfo.AmmoID)
			net.WriteFloat(amount)
			net.SendToServer()
		end
		return
	end

	return originalDropItem(invID, count, sync)
end

hook.Remove("PlayerButtonDown", "CASE_ZCityOpenOnI")
concommand.Add("case_zcity_toggle", function()
	if isPauseMenuVisible() then return end
	if CaseGUI.IsOpen then CaseGUI:Close() else CaseGUI.OpenInventory() end
end)

local inventoryKeyWasDown = false
hook.Add("Think", "CASE_ZCityInventoryKey", function()
	local isDown = input.IsKeyDown(KEY_I)
	if isDown and not inventoryKeyWasDown and not isPauseMenuVisible() then
		if CaseGUI.IsOpen then CaseGUI:Close() else CaseGUI.OpenInventory() end
	end
	inventoryKeyWasDown = isDown
end)

hook.Add("PlayerBindPress", "CASE_ZCityKeepRadialOffInventoryKey", function(_, bind, pressed)
	if pressed and input.IsKeyDown(KEY_I) and string.find(bind, "+menu", 1, true) then return true end
end)

print("[RE4 Case] EUROGRAD inventory HUD enabled. Press I to open.")
