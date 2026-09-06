--[[

	The built in compat list
	Hooray

]]--


local function _registerItemTable(tbl)
	for k, v in pairs(tbl) do
		CaseInventory:RegisterItem(v)
	end
end

local function _canUseHealth(ply)
	if ply:Health() >= ply:GetMaxHealth() then
		return false
	end
	return true
end

local function _canUseArmor(ply)
	if ply:Armor() >= ply:GetMaxArmor() then
		return false
	end
	return true
end

local function _canUseAlways()
	return true
end

local function _useGeneric(ply, itemID)
	if CLIENT then
		return true
	end

	local info = CaseInventory:GetItemInfo(itemID)

	local kit = ents.Create(info.Name)
	kit:Spawn()
	ply.CasePickup = kit
	kit:SetPos(ply:GetPos())
	kit:Use(ply, ply)

	return true
end

-- Each entry should be setup like this
-- List of workshop ids that trigger it, function to call
local ItemList = {
}


local itemsHL2 = {
	-- Ammo
	CaseAmmo(game.GetAmmoID("AR2"),CaseRenderInfo("models/Items/combine_rifle_cartridge01.mdl", 2.7), 2, 1, 60),
	CaseAmmo(game.GetAmmoID("AR2AltFire"),CaseRenderInfo("models/Items/combine_rifle_ammo01.mdl", 2.1), 1, 2, 3),
	CaseAmmo(game.GetAmmoID("Pistol"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 1), 2, 1, 50),
	CaseAmmo(game.GetAmmoID("SMG1"),CaseRenderInfo("models/Items/BoxMRounds.mdl", 1.7), 2, 1, 90),
	CaseAmmo(game.GetAmmoID("357"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 10),
	CaseAmmo(game.GetAmmoID("XBowBolt"), CaseRenderInfo("models/Items/CrossbowRounds.mdl", 5), 4, 1, 20),
	CaseAmmo(game.GetAmmoID("Buckshot"), CaseRenderInfo("models/Items/BoxBuckshot.mdl", 1.3, {15, 180, 0}), 2, 1, 25),
	CaseAmmo(game.GetAmmoID("RPG_Round"),CaseRenderInfo("models/weapons/w_missile_closed.mdl", 4), 4, 1, 3),
	CaseAmmo(game.GetAmmoID("SMG1_Grenade"),CaseRenderInfo("models/Items/AR2_Grenade.mdl", 4), 2, 1, 5),
	CaseAmmo(game.GetAmmoID("AlyxGun"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 3), 2, 1, 90),

	-- Mods like to use these ones :(
	CaseAmmo(game.GetAmmoID("SniperRound"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 15),
	CaseAmmo(game.GetAmmoID("SniperPenetratedRound"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 15),

	-- Melee + Other
	CaseWeapon("weapon_crowbar",CaseRenderInfo("models/weapons/w_crowbar.mdl", 5, {90, 0, 90}), 2, 3, "Crowbar"),
	CaseWeapon("weapon_stunstick",CaseRenderInfo("models/weapons/w_stunbaton.mdl", 5, {90, 0, 90}, Vector(0, -1, -1.5)), 2, 3, "Stunstick"),
	CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 4, {0, 180, 0}, Vector(0, 22)), 5, 2, "Gravity Gun"),
	CaseWeapon("weapon_crossbow",CaseRenderInfo("models/weapons/w_crossbow.mdl", 4.9, {0, 180,0}, Vector(0, 16.5)), 5, 2, "Crossbow"),
	CaseWeapon("weapon_rpg",CaseRenderInfo("models/weapons/w_rocket_launcher.mdl", 5, {0,0,0}, Vector(0,0,1)), 8, 2, "RPG Launcher"),

	-- Thrown
	CaseWeapon("weapon_bugbait", CaseRenderInfo("models/weapons/w_bugbait.mdl", 4), 1, 1),
	CaseGrenade("weapon_frag", CaseRenderInfo("models/Items/grenadeAmmo.mdl", 1.6), 1, 2, 3, game.GetAmmoID("Grenade")),
	CaseGrenade("weapon_slam",CaseRenderInfo("models/weapons/w_slam.mdl", 3, {0,90,-90}), 1, 2, 3, game.GetAmmoID("slam")),

	-- Pistol
	CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 4.5, {5, 180, 0}, Vector(0, 13)), 3, 2, ".357 Magnum"),
	CaseWeapon("weapon_pistol",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2, "9mm Pistol"),


	-- Shotgun
	CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 5.5, {}, Vector(0, 0, -1)), 6, 2, "Shotgun"),
	CaseWeapon("weapon_annabelle",CaseRenderInfo("models/weapons/w_annabelle.mdl", 7, {}, Vector(0, 0, -1)), 8, 2, "Annabelle"), -- tee hee


	-- Auto
	CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-3,0)), 3, 2, "SMG"),
	CaseWeapon("weapon_ar2",CaseRenderInfo("models/weapons/w_irifle.mdl", 5.6), 5, 2, "Pulse-Rifle"),
	CaseWeapon("weapon_alyxgun",CaseRenderInfo("models/weapons/w_alyx_gun.mdl", 0.5), 3, 2, "Alyx's Gun"), -- tee hee 2

	-- Consumables (yummers)
	CaseConsumable("item_healthkit", "Health Kit", CaseRenderInfo("models/Items/HealthKit.mdl", 3.2, {90,90,0}, Vector(0,5,8)), 2, 3, 3,
	function (ply, tbl) -- OnUse
		if CLIENT then
			return true
		end

		local kit = ents.Create("item_healthkit")
		kit:Spawn()
		ply.CasePickup = kit
		kit:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
		return true
	end, {CASE_TAG_HEALTH}),

	CaseConsumable("item_healthvial", "Health Vial", CaseRenderInfo("models/healthvial.mdl", 1.9, {0,125}, Vector(0,0.2)),  1, 2, 3,
	function (ply, tbl) -- OnUse
		if CLIENT then
			return true
		end
		local vial = ents.Create("item_healthvial")
		vial:Spawn()
		ply.CasePickup = vial
		vial:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
		return true
	end, {CASE_TAG_HEALTH}),

	CaseConsumable("item_battery", "Suit Battery", CaseRenderInfo("models/items/battery.mdl", 2.1, {0,-60,180}, Vector(0,-0.2,10)), 1, 2, 3,
	function (ply) -- OnUse
		if CLIENT then
			return true
		end

		local battery = ents.Create("item_battery")
		battery:Spawn()
		ply.CasePickup = battery
		battery:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Armor() >= ply:GetMaxArmor() then
			return false
		end
		return true
	end, {CASE_TAG_ARMOR}),

	-- Forgot this was a thing until i was playing EP2
	-- All of these will probably only restore 4 health
	-- Mostly just cus yeah
	-- ent_dump reveals they can do more but i'm lazy
	CaseConsumable("item_grubnugget", "Grub Nugget", CaseRenderInfo("models/grub_nugget_small.mdl", 3),  1, 1, 5,
	function (ply, tbl) -- OnUse
		if CLIENT then
			return true
		end
		local vial = ents.Create("item_grubnugget")
		vial:Spawn()
		ply.CasePickup = vial
		vial:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
		return true
	end, {CASE_TAG_HEALTH}),


	CaseGlowOnly("ent_caseammo"),
	CaseGlowOnly("ent_caseupgrade"),
	CaseGlowOnly("ent_caseupgrade_s"),
	CaseGlowOnly("ent_caseupgrade_m"),
	CaseGlowOnly("ent_caseupgrade_l"),
	CaseGlowOnly("ent_caseupgrade_xl"),
	CaseGlowOnly("ent_caseupgrade_xxl"),

	CaseGlowOnly("item_ammo_357"),
	CaseGlowOnly("item_ammo_357_large"),

	CaseGlowOnly("item_ammo_ar2"),
	CaseGlowOnly("item_ammo_ar2_altfire"),
	CaseGlowOnly("item_ammo_ar2_large"),

	CaseGlowOnly("item_ammo_pistol"),
	CaseGlowOnly("item_ammo_pistol_large"),

	CaseGlowOnly("item_ammo_crossbow"),

	CaseGlowOnly("item_ammo_smg1"),
	CaseGlowOnly("item_ammo_smg1_large"),
	CaseGlowOnly("item_ammo_smg1_grenade"),

	CaseGlowOnly("item_box_buckshot"),

	CaseGlowOnly("item_rpg_round"),



	--[[
		Some generic ammo types :shrug:
	]]
	CaseAmmo(game.GetAmmoID("Thumper"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Gravity"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Battery"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("GaussEnergy"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("CombineCannon"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("AirboatGun"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("StriderMinigun"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("HelicopterGun"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("StriderMinigunDirect"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("CombineHeavyCannon"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),

	--[[
		HL:S Ammo
	]]
	CaseAmmo(game.GetAmmoID("9mmRound"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("357Round"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("BuckshotHL1"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("XBowBoltHL1"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("MP5_Grenade"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("RPG_Rocket"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Uranium"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("GrenadeHL1"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Hornet"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Snark"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("TripMine"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Satchel"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("12mmRound"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30)
}

local itemsGMOD = {
	CaseDoNotHandle("weapon_fists"),
	CaseWeapon("gmod_tool", CaseRenderInfo("models/weapons/w_toolgun.mdl", 3.5, {0, -90, 0}, Vector(0, 12)), 3, 2, "Tool Gun"),
	CaseWeapon("gmod_camera", CaseRenderInfo("models/maxofs2d/camera.mdl", 3.5, {0, 210, 0}), 3, 2, "Camera"),
	CaseWeapon("weapon_physgun", CaseRenderInfo("models/weapons/w_physics.mdl", 4, {0, 0, 0}), 3, 2, "Physgun"),
	CaseWeapon("weapon_medkit",  CaseRenderInfo("models/Items/HealthKit.mdl", 3.2, {90,90,0}, Vector(0,5,8)), 2, 3, "Medkit"),
	CaseWeapon("manhack_welder",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2, "Manhack Welder"),
	CaseWeapon("weapon_flechettegun",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-8,0)), 3, 2, "Flechette Gun"),
	CaseWeapon("weapon_base", CaseRenderInfo("models/weapons/w_357.mdl"), 3, 2, "Weapon Base"),
}

-- https://steamcommunity.com/sharedfiles/filedetails/?id=1606822274
-- MMod Weapon Replacement #1
table.insert(ItemList, {{"1606822274"}, function()
	return {
		CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-8,0)), 3, 2, "SMG"),
		CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 6), 6, 2, "Shotgun")
	}
end})

-- https://steamcommunity.com/sharedfiles/filedetails/?id=2035609495
-- MMod Weapon Replacement #2
table.insert(ItemList, {{"2035609495"}, function()
	return {
		CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 3.5, {0, 0, 0}, Vector(0, 5)), 5, 2, "Gravity Gun"),
		CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl",6, {0,180,0}, Vector(0,-7,0)), 3, 2, "SMG"),
		CaseWeapon("weapon_rpg",CaseRenderInfo("models/weapons/w_rocket_launcher.mdl", 5.5, {0,0,40}, Vector(0,0,4.5)), 8, 2, "RPG Launcher"),
		CaseWeapon("weapon_ar2",CaseRenderInfo("models/weapons/w_irifle.mdl", 6, {}, Vector(0, -3, 0.25)), 5, 2, "Pulse-Rifle"),
		CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 4.5, {0, 0, 0}, Vector(0, 0)), 3, 2, ".357 Magnum"),
		CaseAmmo(game.GetAmmoID("RPG_Round"),CaseRenderInfo("models/weapons/w_missile_closed.mdl", 4, {0, 180}), 4, 1, 3),
	}
end})

-- ARC9 Base
table.insert(ItemList, {{"2910505837"}, function()
	return {
		CaseWeapon("arc9_base", CaseRenderInfo(""), 3, 2),
		CaseWeapon("arc9_base_nade", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("arc9_uplp_grenade_base", CaseRenderInfo("models/weapons/w_eq_fraggrenade.mdl"), 3, 2),
	}
end})

-- TFA Base
table.insert(ItemList, {{"2840031720"}, function()
	return {
		CaseWeapon("tfa_sword_advanced_base", CaseRenderInfo(""), 3, 2),
		CaseWeapon("tfa_3dbash_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_shotty_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_gun_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_cssnade_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_nade_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_knife_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_bash_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_melee_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_scoped_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_bow_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_akimbo_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_3dscoped_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2)
	}
end})

local function __NMRINH()
	return {
		CaseWeapon("tfa_nmrimelee_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_nmrih_base_3d", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_nmrih_base_fa", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),

		-- Melee
		CaseWeapon("tfa_nmrih_fists", CaseRenderInfo(""), 1, 1),
		CaseWeapon("tfa_nmrih_hatchet", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_hatchet.mdl", 3.5, {0,-90}, Vector(0,1.5)), 2, 3),
		CaseWeapon("tfa_nmrih_bat", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_bat_metal.mdl", 0.75, {}, Vector(0,-0.5)), 1, 4),
		CaseWeapon("tfa_nmrih_bcd", CaseRenderInfo("models/weapons/tfa_nmrih/w_tool_barricade.mdl", 1.5, {0, 180}, Vector(0, 0, -2)), 1, 3),
		CaseWeapon("tfa_nmrih_wrench", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_wrench.mdl", 4, {0, 180}, Vector(0, 1, -1)), 1, 2),
		CaseWeapon("tfa_nmrih_chainsaw", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_chainsaw.mdl", 5, {-9, 180, 0}, Vector(0,45, -2)), 4, 2),
		CaseWeapon("tfa_nmrih_sledge", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_sledge.mdl", 1.2), 2, 4),
		CaseWeapon("tfa_nmrih_machete", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_machete.mdl", 2.7, {0,180}), 1, 3),
		CaseWeapon("tfa_nmrih_etool", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_etool.mdl", 0.5), 2, 3),
		CaseWeapon("tfa_nmrih_spade", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_spade.mdl", 1.3),2, 4),
		CaseWeapon("tfa_nmrih_fireaxe", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_axe_fire.mdl", 2.5, {0, 180}, Vector(0, 2)), 2, 3),
		CaseWeapon("tfa_nmrih_crowbar", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_crowbar.mdl", 2.5, {0, 180}), 2, 3),
		CaseWeapon("tfa_nmrih_kknife", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_kitknife.mdl", 5, {0, 180}), 1, 2),
		CaseWeapon("tfa_nmrih_lpipe", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_pipe_lead.mdl", 2.7, {0, 180}), 2, 3),
		CaseWeapon("tfa_nmrih_fubar", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_fubar.mdl", 1.3, {0, 180}, Vector(0, 7)), 2, 4),
		CaseWeapon("tfa_nmrih_pickaxe", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_pickaxe.mdl", 2.8, {0, 180}, Vector(0, 5.5)), 2, 3),
		CaseWeapon("tfa_nmrih_cleaver", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_cleaver.mdl", 3.9, {0, 180}, Vector(0, 6, -1)), 1, 2),
		CaseWeapon("tfa_nmrih_asaw", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_abrasivesaw.mdl", 4, {0, 180}, Vector(0, 29)), 4, 2),

		-- Pistol
		CaseWeapon("tfa_nmrih_m92fs", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_m92fs.mdl", 15, {0, -90}, Vector(0,15, -1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_1911", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_1911.mdl",6, {0, -90}, Vector(0, 2, 1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_g17", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_glock17.mdl", 6, {0, -90}, Vector(0, 1, 1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_mkiii", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_mkiii.mdl", 6, {0, -90}, Vector(0, 2, 1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_sw686", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sw686.mdl", 6, {0, -90}, Vector(0, 22, -1.5)), 3, 2),

		-- AR
		CaseWeapon("tfa_nmrih_m16_ch", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_m16a4_carryhandle.mdl", 5, {0, 180}, Vector(0, 18.5)), 5, 2),
		CaseWeapon("tfa_nmrih_m16_rt", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_m16a4.mdl", 5, {0, 180}, Vector(0, 18.5)), 5, 2),
		CaseWeapon("tfa_nmrih_cz", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_cz858.mdl", 5, {0, 180}, Vector(0, 10.5)), 5, 2),
		CaseWeapon("tfa_nmrih_fal", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_fnfal.mdl",4 , {0, -90}), 6, 2),

		-- SMG
		CaseWeapon("tfa_nmrih_mp5", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_mp5.mdl", 5, {0, 180}, Vector(0, 3.5)), 3, 2),
		CaseWeapon("tfa_nmrih_mac10", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_mac10.mdl", 5, {0, -90}, Vector(0,-2)), 2, 2),

		-- Shogun (funny)
		CaseWeapon("tfa_nmrih_sv10", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sv10.mdl", 5, {0, 180}, Vector(0, 3)), 6, 2),
		CaseWeapon("tfa_nmrih_500a", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_500a.mdl", 5, {0, 180}, Vector(0, 23, -1)), 6, 2),
		CaseWeapon("tfa_nmrih_870", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_870.mdl", 5, {0, 180}, Vector(0, 15, 0)), 6, 2),
		CaseWeapon("tfa_nmrih_superx3", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_superx3.mdl", 4, {0, -90}, Vector(0, 0, 0)), 7, 2),


		-- Rifle (no A?????)
		CaseWeapon("tfa_nmrih_jae700", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_jae700.mdl", 4.5, {0, 180, -50}, Vector(0, 25, 0.4)), 7, 1),
		CaseWeapon("tfa_nmrih_rug1022", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_ruger1022.mdl", 4, {0, -90, -50}), 6, 1),
		CaseWeapon("tfa_nmrih_rug1022_25", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_ruger1022_25mag.mdl", 4, {0, -90, -50}), 6, 2),
		CaseWeapon("tfa_nmrih_sako", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sako85.mdl", 4, {0, -90}, Vector(0, -1)), 6, 2),
		CaseWeapon("tfa_nmrih_sako_is", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sako85_ironsights.mdl", 4, {0, -90, -50}, Vector(0, -1.9, 0.5)), 6, 1),
		CaseWeapon("tfa_nmrih_sks", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sks.mdl", 5, {0, 180, -50}, Vector(0, 30)), 7, 1),
		CaseWeapon("tfa_nmrih_sks_nb", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sks_nobayo.mdl", 6, {0, 180, -50}, Vector(0, 25)), 6, 1),
		CaseWeapon("tfa_nmrih_1892", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_win1892.mdl", 3.5, {0, -90}, Vector(0, 0, 0)), 6, 2),


		-- Ammo
		-- This should probably be pretty universal for any other mods that want to use it
		CaseAmmo("gasoline", CaseRenderInfo("models/props_junk/gascan001a.mdl", 1), 2, 3, 300),
	}
end

-- No more room in hell melee + guns
table.insert(ItemList, {{"828059724", "2849966415"}, __NMRINH})

-- Poly Arms
table.insert(ItemList, {{"3098824960"}, function ()
	return {
		CaseWeapon("arc9_uplp_knife", CaseRenderInfo("models/weapons/arc9/w_uplp_knife.mdl", 2, {}, Vector(0,-1,0)), 1 , 3),
		CaseGrenade("arc9_uplp_grenade_flash", CaseRenderInfo("models/weapons/arc9/w_uplp_m84.mdl"),1,2,1, game.GetAmmoID("arc9_uplp_grenade_flash")),
		CaseGrenade("arc9_uplp_grenade_frag", CaseRenderInfo("models/weapons/arc9/w_uplp_m26.mdl"),1,2,1, game.GetAmmoID("arc9_uplp_grenade_frag")),



		-- SMG
		CaseWeapon("arc9_uplp_ak_smg", CaseRenderInfo("models/weapons/arc9/w_uplp_ak_smol.mdl", 7, {0, 180}, Vector(0,-7)), 4, 2),
		CaseWeapon("arc9_uplp_mac", CaseRenderInfo("models/weapons/arc9/w_uplp_mac11.mdl", 5, {0, 180}, Vector(0, 2)), 2, 2),
		CaseWeapon("arc9_uplp_mp9", CaseRenderInfo("models/weapons/arc9/w_uplp_mp9.mdl", 10, {0, 180}, Vector(0,-14)), 3, 2),
		CaseWeapon("arc9_uplp_mp5", CaseRenderInfo("models/weapons/arc9/w_uplp_mp5.mdl", 7, {0, 180}, Vector(0,-9)), 4, 2),
		CaseWeapon("arc9_uplp_mp7", CaseRenderInfo("models/weapons/arc9/w_uplp_mp7.mdl", 9, {0, 180}, Vector(0,-14)), 3, 2),
		CaseWeapon("arc9_uplp_g36", CaseRenderInfo("models/weapons/arc9/w_uplp_g36.mdl", 7, {0, 180, 0}, Vector(0, -5, 0)), 3, 2),
		CaseWeapon("arc9_uplp_ar57", CaseRenderInfo("models/weapons/arc9/w_uplp_ar57.mdl", 7.5, {0, 180, 0}, Vector(0, -5.2, 0)), 4, 2),

		-- Sniper
		CaseWeapon("arc9_uplp_awp", CaseRenderInfo("models/weapons/arc9/w_uplp_awp.mdl", 5.2, {0, 180}, Vector(0, 2)), 7, 2),
		CaseWeapon("arc9_uplp_orsis", CaseRenderInfo("models/weapons/arc9/w_uplp_orsis.mdl", 5 ,{0, 180}, Vector(0, 10)), 7, 2),
		CaseWeapon("arc9_uplp_mjolnir", CaseRenderInfo("models/weapons/arc9/w_uplp_mjolnir.mdl", 6, {0, 180, 0}, Vector(0, 3, -2)), 7, 2),
		CaseWeapon("arc9_uplp_sr25", CaseRenderInfo("models/weapons/arc9/w_uplp_sr25.mdl", 5.5, {0, 180, 0}, Vector(0, -2.5, 0)), 6, 2),
		CaseWeapon("arc9_uplp_marlin", CaseRenderInfo("models/weapons/arc9/w_uplp_marlin.mdl", 5.5, {0, 180, 0}, Vector(0, -1.5, 0)), 6, 2),

		-- Shotguns
		CaseWeapon("arc9_uplp_molot", CaseRenderInfo("models/weapons/arc9/w_uplp_molot.mdl", 5.2, {0, 180}, Vector(0, -2)),6 ,2 ),
		CaseWeapon("arc9_uplp_spas", CaseRenderInfo("models/weapons/arc9/w_uplp_spas.mdl", 5.2, {0, 180}, Vector(0,-2)),6 ,2 ),
		CaseWeapon("arc9_uplp_m590", CaseRenderInfo("models/weapons/arc9/w_uplp_590.mdl", 5.2, {0, 180}, Vector(0, -2)),6 ,2 ),
		CaseWeapon("arc9_uplp_r870", CaseRenderInfo("models/weapons/arc9/w_uplp_870.mdl", 5.2, {0, 180}, Vector(0, -2)),6 ,2 ),
		CaseWeapon("arc9_uplp_dbs", CaseRenderInfo("models/weapons/arc9/w_uplp_db.mdl", 5.2, {0, 180, 0}, Vector(0, -4, 0)), 6, 2),
		CaseWeapon("arc9_uplp_ks23", CaseRenderInfo("models/weapons/arc9/w_uplp_ks23.mdl", 5.2, {0, 180, 0}, Vector(0, 0, 0)), 6, 2),

		-- funny guns
		CaseWeapon("arc9_uplp_deagle", CaseRenderInfo("models/weapons/arc9/w_uplp_deagle.mdl", 4.5, {0, 180}, Vector(0, 4.5)), 3, 2),
		CaseWeapon("arc9_uplp_fn57", CaseRenderInfo("models/weapons/arc9/w_uplp_fn57.mdl", 4.5, {0, 180}, Vector(0,3.5)), 3, 2),
		CaseWeapon("arc9_uplp_m9", CaseRenderInfo("models/weapons/arc9/w_uplp_beretta.mdl", 4.5, {0, 180}, Vector(0, 4.5)), 3, 2),
		CaseWeapon("arc9_uplp_rsh12", CaseRenderInfo("models/weapons/arc9/w_uplp_rsh12.mdl", 5, {0, 180}, Vector(0, 10)), 3, 2),
		CaseWeapon("arc9_uplp_usp", CaseRenderInfo("models/weapons/arc9/w_uplp_usp.mdl", 5, {0, 180, 0}, Vector(0, 4.5, 0)), 3, 2),


		-- ARs
		CaseWeapon("arc9_uplp_ak", CaseRenderInfo("models/weapons/arc9/w_uplp_ak.mdl",6, {0, 180}, Vector(0, -3)), 5, 2),
		CaseWeapon("arc9_uplp_ak12", CaseRenderInfo("models/weapons/arc9/w_uplp_ak12.mdl",6, {0, 180}, Vector(0, -3)), 5, 2),
		CaseWeapon("arc9_uplp_ar15", CaseRenderInfo("models/weapons/arc9/w_uplp_ar15.mdl",8, {0, 180}, Vector(0, -6)), 5, 2),
		CaseWeapon("arc9_uplp_aug", CaseRenderInfo("models/weapons/arc9/w_uplp_aug.mdl",7.5, {0, 180}, Vector(0, -8.5)), 5, 2),
		CaseWeapon("arc9_uplp_fal", CaseRenderInfo("models/weapons/arc9/w_uplp_fal.mdl",5.25, {0, 180}, Vector(0, 2)), 6, 2),
		CaseWeapon("arc9_uplp_ar18", CaseRenderInfo("models/weapons/arc9/w_uplp_ar18.mdl",6, {0, 180}, Vector(0, -3)), 5, 2),
		CaseWeapon("arc9_uplp_asval", CaseRenderInfo("models/weapons/arc9/w_uplp_asval.mdl",6, {0, 180}, Vector(0, -5)), 5, 2),
		CaseWeapon("arc9_uplp_scar", CaseRenderInfo("models/weapons/arc9/w_uplp_scar.mdl",5.7, {0, 180}, Vector(0, -4)), 6, 2),
		CaseWeapon("arc9_uplp_mutant", CaseRenderInfo("models/weapons/arc9/w_uplp_mutant.mdl", 6.7, {0, 180, 0}, Vector(0, -5, 0)), 5, 2),
		CaseWeapon("arc9_uplp_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),

		-- big gun
		CaseWeapon("arc9_uplp_pkm", CaseRenderInfo("models/weapons/arc9/w_uplp_pkm.mdl", 5.6, {0, 180, 0}, Vector(0, 0, 0)), 5, 2),
		CaseWeapon("arc9_uplp_minigun", CaseRenderInfo("models/weapons/arc9/w_uplp_minigun.mdl", 6, {0, 180, 0}, Vector(0, 18, 0)), 6, 3)
	}
end})

-- Crunchy
table.insert(ItemList, {{"2690914262"}, function ()
	local function _canUseCrunchyHealth(ply)
		if ply:Health() >= 250 then
			return false
		end
		return true
	end

	local function _canUseCrunchyArmor(ply)
		if ply:Armor() >= 250 then
			return false
		end
		return true
	end

	local function _canUseZombie(ply)
		if ply:Armor() >= 500 then
			return false
		end
		return true
	end

	return {

		-- Armor
		CaseConsumable("csgo_armor_full", "Armor - Full", CaseRenderInfo("models/crunchy/props/csgo_props/upgrade_dz_armor_helmet.mdl", 3, {20, 45}, Vector(0, -2.5, 3), 0), 3, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("csgo_armor_medium", "Armor - Medium", CaseRenderInfo("models/crunchy/props/csgo_props/upgrade_dz_armor.mdl", 3, {180}), 2, 3, 1,  _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("contagion_armor_heavy", "Armor - Heavy", CaseRenderInfo("models/crunchy/props/contagion_props/armor/gjel.mdl", 2.5, {0, 180}), 2, 3, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("contagion_armor_helmet", "Armor - Helmet", CaseRenderInfo("models/crunchy/props/contagion_props/armor/ulach.mdl", 4, {0, 45}), 2, 2, 2, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("contagion_armor_light", "Armor - Light", CaseRenderInfo("models/crunchy/props/contagion_props/armor/ar_thorcrv.mdl", 2.7, {0, 180}, Vector(0, 0, 2)), 2, 3, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("eft_armor_pack", "Armor Booster", CaseRenderInfo("models/crunchy/props/eft_props/armorrepair.mdl", 3.5, {0, 180}, Vector(0, 0, 1.5)), 3, 2, 2, _useGeneric, _canUseCrunchyArmor, {CASE_TAG_ARMOR, "crunchy_armor"}),
		CaseConsumable("fear_armor", "Armor", CaseRenderInfo("models/crunchy/props/fear_props/armor.mdl", 3.5, {70, 90}, Vector(0, -2, 9)), 2, 3, 2, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("fear_armor_injector", "Armor Injector", CaseRenderInfo("models/crunchy/props/fear_props/armor_injector.mdl", 4, {0, 180}, Vector(0, 5, 2.4)), 2, 2, 2, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("nmrih_armor_police", "Police Vest", CaseRenderInfo("models/crunchy/props/nmrih_props/police_vest.mdl", 0.425, {0, 180, 90}, Vector(0, -10, 11)), 3, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("stalker_armor_exo", "Armor Exosuit", CaseRenderInfo("models/crunchy/props/stalker_props/lone_exo.mdl", 3, {90, 90}, Vector(0, -1, 7)), 4, 5, 1, _useGeneric, _canUseAlways, {CASE_TAG_ARMOR}),
		CaseConsumable("stalker_armor_small", "Helmet", CaseRenderInfo("models/crunchy/props/stalker_props/hardhat.mdl", 3.2, {25,180,0}, Vector(0, 0.25, 0)), 2, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("stalker_armor_small_2", "Helmet (Tactical)", CaseRenderInfo("models/crunchy/props/stalker_props/mili_battlehelm.mdl", 3.2, {25,180,0}, Vector(0, 0.25, 1)), 2, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("stalker_armor_medium", "Armor Medium", CaseRenderInfo("models/crunchy/props/stalker_props/cs_light.mdl", 3.5, {0, 0, -90}, Vector(0, -2, 2)), 3, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("stalker_armor_large", "Armor Large", CaseRenderInfo("models/crunchy/props/stalker_props/cs_heavy.mdl", 4, {0, 0, -90}, Vector(0, 0, 1)), 3, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("uh_battery", "Battery", CaseRenderInfo("models/crunchy/props/underhell_props/pg_battery.mdl", 2), 1, 1, 4, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("uh_battery_pack", "Battery Pack", CaseRenderInfo("models/crunchy/props/underhell_props/pg_battery_pack.mdl", 5, {90, 90, 0}, Vector(0, 0, 1)), 1, 1, 2, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("uh_helmet", "Armor - Helmet", CaseRenderInfo("models/crunchy/props/underhell_props/helmet.mdl", 4, {0, 180}, Vector(0, -6)), 2, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("uh_kevlar", "Armor - Vest", CaseRenderInfo("models/crunchy/props/underhell_props/kevlar.mdl", 2.5, {0, 180}), 2, 3, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("zps_kevlar", "Kevlar Vest", CaseRenderInfo("models/crunchy/props/zps_props/kevlar.mdl", 2.8, {0, 90, -90}, Vector(0, -1.1, 3)), 2, 3, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),

		-- Health

		CaseConsumable("contagion_medical_kit", "Medkit", CaseRenderInfo("models/crunchy/props/contagion_props/w_first_aid.mdl", 4, {270}), 2, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("contagion_medical_pain_reliever", "Pain Reliever", CaseRenderInfo("models/crunchy/props/contagion_props/medicine_bottle_0.mdl", 9, {0, 45}), 1, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("contagion_medical_stimulants", "Stimulants", CaseRenderInfo("models/crunchy/props/contagion_props/medicine_bottle_2.mdl", 7.9, {0, 120}, Vector(0, 0, -2)), 1, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("contagion_medical_bag", "Surgeon's Bag", CaseRenderInfo("models/crunchy/props/contagion_props/health_pack.mdl", 1.9, {0, 0}, Vector(0, 0, 1)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("eft_bandage", "Medical Bandage", CaseRenderInfo("models/crunchy/props/eft_props/bandage.mdl", 1.9, {0, 270, 90}, Vector(0, 0, 0.75)), 1, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("eft_bandage_army", "Army Bandage", CaseRenderInfo("models/crunchy/props/eft_props/armybandage.mdl", 1.9, {0, 270, 90}, Vector(0, 0, 0.75)), 1, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("eft_medical_pile", "Medical Booster", CaseRenderInfo("models/crunchy/props/eft_props/medpile.mdl", 4, {-45, 0}, Vector(0, 0, 1)), 2, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("eft_medkit", "Medkit", CaseRenderInfo("models/crunchy/props/eft_props/carmedkit.mdl", 3.5, {90}, Vector(0, 0.4, 1.5)), 2, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("eft_medkit_army", "Medkit - Army", CaseRenderInfo("models/crunchy/props/eft_props/ifak.mdl", 3, {0, 270, 90}, Vector(0, 0,2.5)), 2, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("eft_medkit_grizzly", "Medkit - Grizzly", CaseRenderInfo("models/crunchy/props/eft_props/grizzly.mdl", 3.75, {90, 0}, Vector(0, 0, 4.4)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("fear_health_injector", "Health Injector", CaseRenderInfo("models/crunchy/props/fear_props/health_injector.mdl", 4, {0, 180}, Vector(0, 5, 2.4)), 2, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("fear_medkit", "Medkit", CaseRenderInfo("models/crunchy/props/fear_props/healthkit.mdl",2, {-90 ,0}, Vector(0, 0, 0)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("nmrih_medical_bandages", "Medical Bandages", CaseRenderInfo("models/crunchy/props/nmrih_props/item_bandages.mdl", 1.7, {0, 160}, Vector(0, 1, 0)), 1, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("nmrih_medical_pills", "Medical Painkillers", CaseRenderInfo("models/crunchy/props/nmrih_props/item_phalanx.mdl", 1.7, {}, Vector(0, -.25)), 1, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("nmrih_medkit", "Medkit", CaseRenderInfo("models/crunchy/props/nmrih_props/item_firstaid.mdl", 3.25, {}, Vector(0, 0, 2)), 3, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_bandages", "Bandages", CaseRenderInfo("models/crunchy/props/random_props/bandages.mdl", 3, {90, 90}, Vector(0, 0, 2)), 1, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_blood_bag", "Blood Bag", CaseRenderInfo("models/crunchy/props/random_props/medical_blood.mdl", 4.6, {-90, 0, 90}, Vector(0, 5, -2.8)), 1, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_medkit_green", "Medkit (Green)", CaseRenderInfo("models/crunchy/props/random_props/healthkit.mdl", 2.5, {-90}, Vector(0, 0, 3)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_medkit_hdtf", "Medkit (Red)", CaseRenderInfo("models/crunchy/props/underhell_props/healthkit.mdl", 2.5, {-90}, Vector(0, 0, 3) ), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_medkit_pack_large", "Medpack (Large)", CaseRenderInfo("models/crunchy/props/random_props/backpack_2_m.mdl", 2.5, {180, 0, 180}, Vector(0, 2.5)), 2, 3, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_medkit_pack_medium", "Medpack (Medium)", CaseRenderInfo("models/crunchy/props/random_props/backpack_1_m.mdl", 2.5, {180, 0, 180}, Vector(0, 2.5)), 2, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_morphine", "Morphine Shot", CaseRenderInfo("models/crunchy/props/random_props/prop_morphine.mdl", 0.75, {0, 0, 90}, Vector(0, -5, 4)), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_pills", "Painkillers", CaseRenderInfo("models/crunchy/props/random_props/hdtf_pills.mdl", 2, {0,90}), 1, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("other_splint", "Splint", CaseRenderInfo("models/crunchy/props/random_props/splint.mdl", 3.5, {-90, -90}, Vector(0, -2.5, 3)), 1, 2, 3, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re2_first_aid_med", "First-Aid Med", CaseRenderInfo("models/crunchy/props/re8_props/re8_village_first_aid_med.mdl", 2, {0, 80}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re2_aid_spray", "First-Aid Spray", CaseRenderInfo("models/crunchy/props/re4_props/firstaidspray.mdl", 1.15, {0, 90}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re2_herb", "Green Herb", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_herbs.mdl", 2.5, {0, 90}, Vector(0, 1)), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re4_aid_spray", "First-Aid Spray", CaseRenderInfo("models/crunchy/props/re4_props/firstaidspray.mdl", 1.25, {0, 90}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re4_herb_green", "Herb (Green)", CaseRenderInfo("models/crunchy/props/re4_props/herb.mdl", 1.5), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH, CASE_TAG_CRAFTING}),
		CaseConsumable("re4_herb_red", "Herb (Red)", CaseRenderInfo("models/crunchy/props/re4_props/herb_red.mdl", 1.5), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH, CASE_TAG_CRAFTING}),
		CaseConsumable("re4_herb_yellow", "Herb (Yellow)", CaseRenderInfo("models/crunchy/props/re4_props/herb_yellow.mdl", 1.5), 1, 2, 1, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, CASE_TAG_CRAFTING, "crunchy_health"}),
		CaseConsumable("re4_herb_green_mix", "Mixed Herb (G + G)", CaseRenderInfo("models/crunchy/props/re4_props/herb_green_mix.mdl", 4, {-90}), 1,1 , 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re4_herb_triple_mix", "Mixed Herb (G + R + B)", CaseRenderInfo("models/crunchy/props/re4_props/herb_mix_triple.mdl", 4, {-90}), 1, 1, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re4_herb_green_red_mix", "Mixed Herb (G + R)", CaseRenderInfo("models/crunchy/props/re4_props/herb_green_red_mix.mdl", 4, {-90}), 1, 1, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("serious_sam_health_bag", "Medical Bag", CaseRenderInfo("models/crunchy/props/serioussam_props/health_large.mdl", 3), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("serious_sam_health_bandages", "Medical Bandages", CaseRenderInfo("models/crunchy/props/serioussam_props/health_small.mdl", 4), 2, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("serious_sam_health_case", "Medical Case", CaseRenderInfo("models/crunchy/props/serioussam_props/health_extralarge.mdl", 2.5, {25, 180, 0}, Vector(0, 0, 2)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("serious_sam_health_kit", "Medical Kit", CaseRenderInfo("models/crunchy/props/serioussam_props/health_medium.mdl", 2.5), 2, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("serious_sam_health_pills", "Medical Pills", CaseRenderInfo("models/crunchy/props/serioussam_props/health_extrasmall.mdl", 2, {0, 90}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("stalker_medical_bandage", "Medical Bandage", CaseRenderInfo("models/crunchy/props/stalker_props/bint.mdl", 2.5, {0, 90, 90}, Vector(0, 1.2)), 1, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("stalker_medkit_large", "Medkit (Large)", CaseRenderInfo("models/crunchy/props/stalker_props/medkit_high.mdl", 4, {270, 0, 90}, Vector(0, 0, 1)), 2, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("stalker_medkit_medium", "Medkit (Medium)", CaseRenderInfo("models/crunchy/props/stalker_props/medkit_med.mdl", 4, {270, 0, 90}, Vector(0, 0, 1)), 2, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("stalker_medkit_small", "Medkit (Small)", CaseRenderInfo("models/crunchy/props/stalker_props/medkit_low.mdl", 4, {270, 0, 90}, Vector(0, 0, 1)), 2, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("uh_bandages", "Bandages", CaseRenderInfo("models/crunchy/props/underhell_props/pg_bandage.mdl", 2), 1, 2, 2, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("uh_medspray", "Medical Spray", CaseRenderInfo("models/crunchy/props/underhell_props/medspray.mdl", 1.5, {0, 100}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("uh_medkit", "Medkit", CaseRenderInfo("models/crunchy/props/underhell_props/healthkit.mdl", 2, {-90}, Vector(0, 0, 3)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("uh_painkillers", "Painkillers", CaseRenderInfo("models/crunchy/props/underhell_props/painkillers.mdl", 1.7, {0, -90}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("zps_medkit", "Medkit", CaseRenderInfo("models/crunchy/props/zps_props/healthkit.mdl", 2.4, {-90}, Vector(0, 0, 2)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("zps_medkit_classic", "Medkit (Classic)", CaseRenderInfo("models/crunchy/props/zps_props/healkit.mdl", 2.4, {-90}, Vector(0, 0, 2)), 3, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("zps_painkillers", "Painkillers", CaseRenderInfo("models/crunchy/props/zps_props/pills.mdl", 1.5, {0, -140}), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),

		-- Food (Max 250 HP)
		CaseConsumable("contagion_food_gin", "Gin", CaseRenderInfo("models/crunchy/props/contagion_props/food/gin_bottle.mdl", 2, {0, 180}), 1, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_beans", "Can of Beans", CaseRenderInfo("models/crunchy/props/contagion_props/food/baked_beans.mdl", 2, {0, 180, 0}), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_soup", "Can of Soup", CaseRenderInfo("models/crunchy/props/contagion_props/food/canned_soup.mdl", 2, {0, 0, 0}), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_chips", "Chips", CaseRenderInfo("models/crunchy/props/contagion_props/food/bag_of_chips.mdl", 4, {-90, 00, -90}, Vector(0, 1.75, -1)), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_peanuts", "Peanuts", CaseRenderInfo("models/crunchy/props/contagion_props/food/bag_of_peanuts.mdl", 2.25, {0, -90, 90}, Vector(0, 0.25, 2)), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_rations", "Ration Kit", CaseRenderInfo("models/crunchy/props/contagion_props/food/food_ration.mdl", 4, {0, 180, 25}, Vector(0, 1, 1)), 2, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_sardines", "Sardines", CaseRenderInfo("models/crunchy/props/contagion_props/food/sardine_can_open.mdl", 2.75, {90, 90}, Vector(0, 0, 1)), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("contagion_food_water", "Water", CaseRenderInfo("models/crunchy/props/contagion_props/plastic_bottle_1.mdl", 4, {0, 180}, {0, 0, -1.5}), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_mre", "Army MRE", CaseRenderInfo("models/crunchy/props/eft_props/mre.mdl", 3.5, {90, 90}, Vector(0, 0, 1)), 1, 2, 1, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_mre_white", "Army MRE", CaseRenderInfo("models/crunchy/props/eft_props/mre.mdl", 3.5, {90, 90}, Vector(0, 0, 1), 1), 1, 2, 1, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_beefstew", "Beef Stew", CaseRenderInfo("models/crunchy/props/eft_props/beefstew.mdl", 2.2, {0, -20}), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_beefstew_family", "Beef Stew (Family Size)", CaseRenderInfo("models/crunchy/props/eft_props/beefstew2.mdl", 3.5, {0, 180}), 2, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_canned_fish", "Canned Herring", CaseRenderInfo("models/crunchy/props/eft_props/herring.mdl", 2.5, {0, 120}), 2, 1, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_peas", "Canned Peas", CaseRenderInfo("models/crunchy/props/eft_props/peas.mdl", 2.3, {0, -55}, Vector(0)), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_squash", "Canned Squash", CaseRenderInfo("models/crunchy/props/eft_props/squash.mdl", 2, {0, 80}, Vector(0, 0.25)), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_hotrod", "Hotrod Energy Drink", CaseRenderInfo("models/crunchy/props/eft_props/hotrod.mdl", 1.5, {0, 70}), 1, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_juice", "Juice", CaseRenderInfo("models/crunchy/props/eft_props/juice.mdl", 1.5, {0, 180}), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_oatmeal", "Oatmeal", CaseRenderInfo("models/crunchy/props/eft_props/oatmeal.mdl", 2.5, {0, 180}, Vector(0, -1.25)), 1, 2, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("eft_food_water", "Water Bottle", CaseRenderInfo("models/crunchy/props/eft_props/waterbottle.mdl", 1.5, {0, 180}), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("nmrih_food_candy", "Candy Bars", CaseRenderInfo("models/crunchy/props/nmrih_props/food/nmrih_grocery_food1c.mdl", 0.9, {0, 0}), 2, 1, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("nmrih_food_oatmeal", "Oatmeal", CaseRenderInfo("models/crunchy/props/nmrih_props/food/nmrih_grocery_food1b.mdl", 0.9, {0, 0}), 2, 2, 6, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("nmrih_food_pasta", "Pasta", CaseRenderInfo("models/crunchy/props/nmrih_props/food/nmrih_grocery_food1i.mdl", 1.2, {0, 0}), 2, 2, 6, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("nmrih_food_pasta_small", "Pasta (Small)", CaseRenderInfo("models/crunchy/props/nmrih_props/food/nmrih_grocery_food1f.mdl", 0.7, {0, 0}), 2, 1, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("nmrih_food_protein", "Protein Bars", CaseRenderInfo("models/crunchy/props/nmrih_props/food/nmrih_grocery_food1h.mdl", 1.1, {0, 0}), 2, 2, 6, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("nmrih_food_tea", "Tea", CaseRenderInfo("models/crunchy/props/nmrih_props/food/nmrih_grocery_food1e.mdl", 1.5, {0, 0}), 1, 2, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("other_coffee_thermos", "Thermos (Coffee)", CaseRenderInfo("models/crunchy/props/random_props/thermos.mdl", 1.5, {0, -30}), 1, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("stalker_food_bread", "Bread", CaseRenderInfo("models/crunchy/props/stalker_props/bread.mdl", 3), 2, 1, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("stalker_food_energydrink", "Energy Drink", CaseRenderInfo("models/crunchy/props/stalker_props/energy-drink.mdl", 1.5), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("stalker_food_energydrink_water", "Water", CaseRenderInfo("models/crunchy/props/stalker_props/energy-drink.mdl", 1.5, {0, -25}, Vector(), 1), 1, 2, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("stalker_food_ration", "Ration", CaseRenderInfo("models/crunchy/props/stalker_props/konservi.mdl", 2.9, {-25}, Vector(2, 0, 0.25)), 2, 1, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("stalker_food_sausage", "Sausage", CaseRenderInfo("models/crunchy/props/stalker_props/kolbasa.mdl", 2.5, {25, 0, 240}, Vector(0, 1, 3)), 2, 1, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("uh_food_apple", "Apple", CaseRenderInfo("models/crunchy/props/underhell_props/pg_apple.mdl", 4), 1, 1, 3, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("uh_food_burrito", "Burrito Pack", CaseRenderInfo("models/crunchy/props/underhell_props/pg_burrito_pack.mdl", 3.5, {90, 90, 0}), 1, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("uh_food_choco", "Chocolate", CaseRenderInfo("models/crunchy/props/underhell_props/pg_choco_bar.mdl", 1.5, {90, 180}), 2, 1, 4, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("uh_food_sandwich", "Sandwich", CaseRenderInfo("models/crunchy/props/underhell_props/pg_sandwich.mdl", 3.5, {0, 0, 90}, Vector(0, 0, -1)), 2, 1, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("uh_food_tortellini", "Tortellini", CaseRenderInfo("models/crunchy/props/underhell_props/pg_tortellinis.mdl", 0.8, {180, 0, 180}), 1, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),
		CaseConsumable("uh_food_water", "Water", CaseRenderInfo("models/crunchy/props/underhell_props/water_bottle.mdl", 1.5), 1, 2, 2, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),

		--Not Actually food but it gets you to 250
		CaseConsumable("zps_inoculator", "Inoculator Booster Shot", CaseRenderInfo("models/crunchy/props/zps_props/w_inoculator.mdl", 5, {0, 180}, Vector(0, 6.7)), 2, 2, 1, _useGeneric, _canUseCrunchyHealth, {CASE_TAG_HEALTH, "crunchy_health"}),

		-- Hello, we are about to launch an all-out attack on your houze. (Max 500 health)
		CaseConsumable("meat_arm1", "Arm 1", CaseRenderInfo("models/crunchy/props/fallout_props/arm1.mdl", 1.1, {180, 180}, Vector(0, 0, 15)), 1, 3, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_arm2", "Arm 2", CaseRenderInfo("models/crunchy/props/fallout_props/gorearm.mdl", 1.1, {180, 90}, Vector(0, 0, 25)), 1, 3, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_chunk1", "Meat Chunk 1", CaseRenderInfo("models/crunchy/props/fallout_props/gorelegb02.mdl", 3, {}, Vector(0, 0, -5)), 2, 2, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_chunk2", "Meat Chunk 2", CaseRenderInfo("models/crunchy/props/fallout_props/gorelegb03.mdl", 2, {}, Vector(0, 0, -9)), 2, 2, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_head", "Head", CaseRenderInfo("models/crunchy/props/fallout_props/gorehead.mdl", 3.2, {0, 67}), 2, 2, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_leg1" , "Leg 1", CaseRenderInfo("models/crunchy/props/fallout_props/leg1.mdl", 1.1), 1, 3, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_leg2", "Leg 2", CaseRenderInfo("models/crunchy/props/fallout_props/goreleg.mdl", 1.5), 1, 3, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),
		CaseConsumable("meat_torso", "Torso", CaseRenderInfo("models/crunchy/props/fallout_props/goretorso.mdl", 1.75), 2, 3, 1, _useGeneric, _canUseZombie, {CASE_TAG_HEALTH, "crunchy_health", "crunchy_zombie_health"}),

		-- Ammo
		CaseGlowOnly("contagion_ammo_magnum"),
		CaseGlowOnly("contagion_ammo_magnum_large"),
		CaseGlowOnly("contagion_ammo_shotgun"),
		CaseGlowOnly("contagion_ammo_rifle"),
		CaseGlowOnly("contagion_ammo_arrows"),
		CaseGlowOnly("contagion_ammo_m79"),
		CaseGlowOnly("contagion_ammo_m79_pack"),
		CaseGlowOnly("contagion_ammo_pistol"),
		CaseGlowOnly("contagion_ammo_smg"),
		CaseGlowOnly("contagion_ammo_sniper"),
		CaseGlowOnly("loose_ammo_shotgun"),
		CaseGlowOnly("loose_ammo_rifle"),
		CaseGlowOnly("loose_ammo_m79"),
		CaseGlowOnly("loose_ammo_magnum_pistol"),
		CaseGlowOnly("loose_ammo_magnum_revolver"),
		CaseGlowOnly("loose_ammo_pistol"),
		CaseGlowOnly("loose_ammo_pistol_alt"),
		CaseGlowOnly("loose_ammo_smg"),
		CaseGlowOnly("loose_ammo_smg_alt"),
		CaseGlowOnly("nmrih_pistol_ammo"),
		CaseGlowOnly("nmrih_crossbow_ammo"),
		CaseGlowOnly("nmrih_magnum_ammo"),
		CaseGlowOnly("nmrih_rifle_ammo"),
		CaseGlowOnly("nmrih_rifle_ammo_mag"),
		CaseGlowOnly("nmrih_shotgun_ammo"),
		CaseGlowOnly("nmrih_smg_ammo"),
		CaseGlowOnly("nmrih_sniper_ammo"),
		CaseGlowOnly("pouch_magnum_ammo"),
		CaseGlowOnly("pouch_pistol_ammo"),
		CaseGlowOnly("pouch_rifle_ammo"),
		CaseGlowOnly("pouch_shotgun_ammo"),
		CaseGlowOnly("pouch_smg_ammo"),
		CaseGlowOnly("pouch_sniper_ammo"),
		CaseGlowOnly("re2_40mm_ammo"),
		CaseGlowOnly("re2_grenade_rounds"),
		CaseGlowOnly("re2_grenade_rounds"),
		CaseGlowOnly("re2_magnum_ammo_alt"),
		CaseGlowOnly("re2_magnum_ammo"),
		CaseGlowOnly("re2_pistol_ammo"),
		CaseGlowOnly("re2_rifle_ammo"),
		CaseGlowOnly("re2_shotgun_ammo"),
		CaseGlowOnly("re2_smg_ammo"),
		CaseGlowOnly("re2_sniper_ammo"),
		CaseGlowOnly("re4_grenade_ammo"),
		CaseGlowOnly("re4_magnum_ammo"),
		CaseGlowOnly("re4_pistol_ammo"),
		CaseGlowOnly("re4_rifle_ammo"),
		CaseGlowOnly("re4_shotgun_ammo"),
		CaseGlowOnly("re4_smg_ammo"),
		CaseGlowOnly("smod_buckshot"),
		CaseGlowOnly("smod_magnum_revolver"),
		CaseGlowOnly("smod_magnum"),
		CaseGlowOnly("smod_pistol"),
		CaseGlowOnly("smod_rifle"),
		CaseGlowOnly("smod_smg"),
		CaseGlowOnly("smod_sniper"),
		CaseGlowOnly("stalker_pistol_ammo"),
		CaseGlowOnly("stalker_rifle_ammo"),
		CaseGlowOnly("stalker_rpg_ammo"),
		CaseGlowOnly("stalker_shotgun_ammo"),
		CaseGlowOnly("stalker_smg_ammo"),
		CaseGlowOnly("stalker_sniper_ammo"),
		CaseGlowOnly("stalker_magnum_ammo"),
		CaseGlowOnly("stalker_pistol_ammo"),
		CaseGlowOnly("stalker_rifle_ammo"),
		CaseGlowOnly("stalker_rpg_ammo"),
		CaseGlowOnly("stalker_shotgun_ammo"),
		CaseGlowOnly("stalker_smg_ammo"),
		CaseGlowOnly("stalker_sniper_ammo"),
		CaseGlowOnly("uh_ammo_357"),
		CaseGlowOnly("uh_ammo_pistol"),
		CaseGlowOnly("uh_ammo_rifle"),
		CaseGlowOnly("uh_ammo_shotgun"),
		CaseGlowOnly("uh_ammo_sniper"),
		CaseGlowOnly("uh_ammo_smg"),
		CaseGlowOnly("zps_ammo_sniper"),
		CaseGlowOnly("zps_ammo_357"),
		CaseGlowOnly("zps_ammo_buckshot"),
		CaseGlowOnly("zps_ammo_pistol"),
		CaseGlowOnly("zps_ammo_rifle"),
		CaseGlowOnly("zps_ammo_smg"),

		-- Stuff
		CaseGeneric("re2_chem_fluid", "Chem Fluid", CaseRenderInfo("models/crunchy/props/re8_props/re8_village_chem_fluid.mdl", 2, {0, -90}, Vector(0, -1)), 1, 2, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_a", "Gunpowder (A)", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_gunpowder.mdl", 4.8), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_b", "Gunpowder (B)", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_gunpowder_b.mdl", 4.8), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_c", "Gunpowder (C)", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_high_grade_gunpowder.mdl", 2.3, {}, Vector()), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_d", "Gunpowder (D)", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_gunpowder_large.mdl", 4), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_e", "Gunpowder (E)", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_gunpowder_e.mdl", 4.), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_f", "Gunpowder (F)", CaseRenderInfo("models/crunchy/props/re2_props/re2_remake_gunpowder_f.mdl", 2.3), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_g", "Gunpowder (G)", CaseRenderInfo("models/crunchy/props/re3_props/re3_remake_explosives.mdl", 1.9, {0, 90}), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re2_gunpowder_x", "Gunpowder (X)", CaseRenderInfo("models/crunchy/props/re8_props/re8_village_gunpowder.mdl", 5, {-45, 200, 20}, Vector(0, 2, 0)), 1, 1, 1, {CASE_TAG_CRAFTING}),
		CaseGeneric("re4_herb_blue", "Herb (Blue)", CaseRenderInfo("models/crunchy/props/re4_props/herb_blue.mdl", 1.5), 1, 2, 1, {CASE_TAG_CRAFTING}),

		CaseGeneric("universal_ammo_huge", "Universal Ammo (100 Mags)", CaseRenderInfo("models/crunchy/props/random_props/ammo_crate_army.mdl", 4.5, {90, 0 ,180}, Vector(0, 2, 120)), 6, 3, 1),
		CaseGeneric("universal_ammo_case",  "Universal Ammo (2 Mags)",CaseRenderInfo("models/crunchy/props/csgo_props/coop_ammo_stash_full.mdl", 4, {0, 180}, Vector(0,-5, 3) ), 2, 2, 1),
		CaseGeneric("universal_ammo_crate_lg",  "Universal Ammo (4 Mags)", CaseRenderInfo("models/crunchy/props/nmrih_props/ammo_crate.mdl", 3), 2, 2, 1),
		CaseGeneric("universal_ammo_backpack", "Universal Ammo (6 Mags)", CaseRenderInfo("models/crunchy/props/l4d_props/pg_army_backpack.mdl", 2.4, {0, 180}, Vector(0, 0, 2)), 2, 3, 1)
	}
end})

-- Crunchy Resident Evil Requiem
table.insert(ItemList, {{"3708241490"}, function ()

	return {

		-- Armor items
		CaseConsumable("re9_armor_injector", "Armor Injector", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_med_injector.mdl", 3.8, {-90, 0, 0}, Vector(0, 1.65, -2), 2), 1, 2, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),
		CaseConsumable("re9_armor_kit", "Armor Kit", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_hip_pouch.mdl", 3, {0, 90, 0}, Vector(0, -2.5, 0)), 2, 1, 1, _useGeneric, _canUseArmor, {CASE_TAG_ARMOR}),

		-- Healing items
		CaseConsumable("re9_med_injector", "Med Injector", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_med_injector.mdl", 3.8, {-90, 0, 0}, Vector(0, 1.65, -2)), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re9_green_herb", "Green Herb", CaseRenderInfo("models/ultimate_items_re9/green_herb.mdl", 2.3), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),
		CaseConsumable("re9_mixed_herb", "Mixed Herb", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_green_herb.mdl", 0.75), 1, 2, 1, _useGeneric, _canUseHealth, {CASE_TAG_HEALTH}),

		-- Random stuff
		CaseGeneric("re9_crafting_gunpowder_a", "Gunpowder A", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_gunpowder_small.mdl", 2, {0, 180, 0}, Vector(), 3), 1, 1, 1),
		CaseGeneric("re9_crafting_gunpowder_b", "Gunpowder B", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_gunpowder_small.mdl", 2, {0, 180, 0}, Vector(), 2), 1, 1, 1),
		CaseGeneric("re9_crafting_gunpowder_c", "Gunpowder C", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_gunpowder_small.mdl", 2, {0, 180, 0}, Vector(), 6), 1, 1, 1),
		CaseGeneric("re9_crafting_gunpowder_d", "Gunpowder D", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_gunpowder_large.mdl", 2, {0, 180, 0}, Vector(), 3), 1, 1, 1),
		CaseGeneric("re9_crafting_gunpowder_e", "Gunpowder E", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_gunpowder_large.mdl", 2, {0, 180, 0}, Vector(), 4), 1, 1, 1),
		CaseGeneric("re9_crafting_gunpowder_f", "Gunpowder F", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_gunpowder_large.mdl", 2, {0, 180, 0}, Vector(), 5), 1, 1, 1),
		CaseGeneric("re9_crafting_list", "Crafting Recipe List", CaseRenderInfo("models/ultimate_items_re9/re9_crafting_list.mdl", 3, {0, 0, -90}), 2, 1, 1),
		CaseGeneric("re9_crafting_scrap", "Scrap", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_metal_scrap.mdl", 2.9, {0, 0, 90}, Vector(0, 0, 1)), 2, 1, 1),
		CaseGeneric("re9_crafting_scrap_rare", "Rare Scrap", CaseRenderInfo("models/ultimate_items_re9/re9_requiem_metal_rare.mdl", 3.3), 2, 1, 1),
		CaseGeneric("re9_red_herb", "Red Herb", CaseRenderInfo("models/ultimate_items_re9/green_herb.mdl", 2.3, {}, {}, 1), 1, 2, 1),

		-- Ammo
		CaseGlowOnly("re9_ammo_assault_rifle"),
		CaseGlowOnly("re9_ammo_pistol"),
		CaseGlowOnly("re9_ammo_machine_gun"),
		CaseGlowOnly("re9_ammo_revolver"),
		CaseGlowOnly("re9_ammo_sniper"),
		CaseGlowOnly("re9_ammo_shotgun")
	}

end})

local function _RegisterItems()
	_registerItemTable(itemsGMOD)
	_registerItemTable(itemsHL2)

	-- We wanna do something FREAKY here
	-- For the server, only add the stuff that is actually mounted
	-- For the clinet, we mount everything and then let the sort system just clean out everything that isn't actually used
	if SERVER then
		for _, addon in ipairs(engine.GetAddons()) do
			if not addon.mounted then
				continue
			end
			local workshopID = addon.wsid

			for _, item in ipairs(ItemList) do
				if item.Used ~= nil and item.Used then
					continue
				end

				for _, wID in ipairs(item[1]) do
					if wID == workshopID then
						item.Used = true
						_registerItemTable(item[2]()) -- Register stuff
					end
				end
			end
		end
	else -- Client
		for _, item in ipairs(ItemList) do
			_registerItemTable(item[2]())
		end
	end
end

hook.Add("CaseRegisterItems", "CaseDefaultItemRegister", function ()
	_RegisterItems()
end)