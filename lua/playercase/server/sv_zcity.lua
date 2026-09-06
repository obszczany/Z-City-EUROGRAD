-- Z-City compatibility layer.
-- The case is a visual mirror in Z-City; the gamemode remains authoritative
-- for pickups, weapon limits, ammo conversion and death inventory handling.

-- Workshop gamemodes are sometimes mounted after the initial addon pass.
local function zcityAvailable()
	return engine.ActiveGamemode() == "zcity" or (hg and hg.loaded)
end

if not zcityAvailable() then
	timer.Create("CASE_WaitForZCityServer", 1, 0, function()
		if not zcityAvailable() then return end
		timer.Remove("CASE_WaitForZCityServer")
		include("playercase/server/sv_zcity.lua")
	end)
	return
end


timer.Remove("CASE_WaitForZCityServer")
if CASE_ZCITY_SERVER_ACTIVE then return end
CASE_ZCITY_SERVER_ACTIVE = true

local ignoredWeapons = {
	weapon_hands_sh = true,
	weapon_zombclaws = true
}

local invasiveHooks = {
	{"PlayerCanPickupItem", "CASE_PlayerCanPickupItem"},
	{"PlayerCanPickupWeapon", "CASE_PlayerCanPickupWeapon"},
	{"OnPlayerPhysicsPickup", "CASE_OnPlayerPhysicsPickup"},
	{"StartCommand", "CASE_StartCommand"},
	{"PlayerAmmoChanged", "CASE_PlayerAmmoChanged"},
	{"DoPlayerDeath", "CASE_PlayerDeath"},
	{"PlayerSilentDeath", "CASE_PlayerSilentDeath"},
	{"PlayerUse", "CASE_PlayerUse"},
	{"WeaponEquip", "CASE_WeaponEquip"},
	{"PlayerDroppedWeapon", "CASE_PlayerDroppedWeapon"}
}

for _, hookInfo in ipairs(invasiveHooks) do
	hook.Remove(hookInfo[1], hookInfo[2])
end

local function getInventory(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return nil end
	local inv = CaseInventory:Inv(ply)
	if not inv or not inv.Items then return nil end
	return inv
end

local function mirrorWeapon(ply, weapon)
	if not IsValid(weapon) or ignoredWeapons[weapon:GetClass()] then return end

	local inv = getInventory(ply)
	if not inv then return end

	local itemID = CaseInventory:GetItemID(weapon:GetClass())
	if itemID == -1 then return end

	local itemInfo = CaseInventory:GetItemInfo(itemID)
	if not itemInfo or itemInfo.ItemType == CASE_ITEM_DO_NOT_HANDLE then return end
	if CaseInventory:HasItem(inv, itemID) then return end

	-- A full case must never make Z-City throw away a real weapon. If there is
	-- no room, it simply stays managed by Z-City and is omitted from the view.
	CaseInventory:AddItemToInventory(inv, itemID, 1, true)
end

local function mirrorAllWeapons(ply)
	if not IsValid(ply) then return end
	for _, weapon in ipairs(ply:GetWeapons()) do
		mirrorWeapon(ply, weapon)
	end
end

local function mirrorAmmo(ply)
	local inv = getInventory(ply)
	if not inv then return end

	local currentAmmo = ply:GetAmmo()
	local changed = false

	for itemID, itemInfo in pairs(CaseInventory.ItemRegister) do
		if itemInfo.ItemType == CASE_ITEM_AMMO and itemInfo.AmmoID and itemInfo.AmmoID >= 0 then
			local wanted = currentAmmo[itemInfo.AmmoID] or 0
			local present = CaseInventory:ItemCount(inv, itemID)

			if wanted > present then
				CaseInventory:AddItemToInventory(inv, itemID, wanted - present, false)
				changed = CaseInventory:ItemCount(inv, itemID) ~= present or changed
			elseif present > wanted then
				CaseInventory:RemoveItem(inv, itemID, present - wanted)
				changed = true
			end
		end
	end

	if changed then
		CaseInventory:RefreshLoadout(inv)
		CaseInventory:Sync(ply)
	end
end

local function queueFullMirror(ply, delay)
	if not IsValid(ply) then return end
	local timerName = "CASE_ZCityMirror_" .. ply:EntIndex()
	timer.Create(timerName, delay or 0, 1, function()
		if not IsValid(ply) then return end
		mirrorAllWeapons(ply)
		mirrorAmmo(ply)
	end)
end

hook.Add("WeaponEquip", "CASE_WeaponEquip", function(weapon, ply)
	timer.Simple(0, function()
		if IsValid(ply) and IsValid(weapon) and weapon:GetOwner() == ply then
			mirrorWeapon(ply, weapon)
		end
	end)
end)

hook.Add("PlayerDroppedWeapon", "CASE_PlayerDroppedWeapon", function(ply, weapon)
	local inv = getInventory(ply)
	if not inv or not IsValid(weapon) then return end

	local itemID = CaseInventory:GetItemID(weapon:GetClass())
	if itemID ~= -1 and CaseInventory:HasItem(inv, itemID) then
		CaseInventory:RemoveItem(inv, itemID, 1)
		CaseInventory:RefreshLoadout(inv)
	end
end)

hook.Add("PlayerAmmoChanged", "CASE_ZCityAmmoMirror", function(ply)
	queueFullMirror(ply, 0)
end)

hook.Add("PlayerSpawn", "CASE_ZCitySpawnMirror", function(ply)
	queueFullMirror(ply, 0.5)
end)

hook.Add("InitPostEntity", "CASE_ZCityInitialMirror", function()
	for _, ply in ipairs(player.GetAll()) do
		queueFullMirror(ply, 1)
	end
end)

print("[RE4 Case] Z-City compatibility enabled; Z-City owns gameplay inventory.")
