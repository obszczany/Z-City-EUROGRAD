hook.Add("CaseRegisterRecipes", "CaseDefaultRecipes", function ()

	CaseInventory:RegisterCraftingRecipe("Health Kit", "item_healthkit", 1, {item_healthvial = 2})

	CaseInventory:RegisterCraftingRecipe("Pistol Ammo x15", "ammo_Pistol", 15, {re9_crafting_gunpowder_a = 1, re9_crafting_scrap = 1})
	CaseInventory:RegisterCraftingRecipe("Shotgun Shells x10", "ammo_Buckshot", 10, {re9_crafting_gunpowder_b = 1, re9_crafting_scrap = 1})
	CaseInventory:RegisterCraftingRecipe("SMG Ammo x30", "ammo_SMG1", 30, {re9_crafting_gunpowder_c = 1, re9_crafting_scrap = 1})


	CaseInventory:RegisterCraftingRecipe("Assault Rifle Ammo x30", "ammo_AR2", 30, {re9_crafting_gunpowder_d = 1, re9_crafting_scrap_rare = 1})
	CaseInventory:RegisterCraftingRecipe("Rifle Ammo x10", "ammo_SniperPenetratedRound", 10, {re9_crafting_gunpowder_e = 1, re9_crafting_scrap_rare = 1})
	CaseInventory:RegisterCraftingRecipe("Revolver Ammo x5", "ammo_357", 5, {re9_crafting_gunpowder_f = 1, re9_crafting_scrap_rare = 1})

	CaseInventory:RegisterCraftingRecipe("Mixed Herb (G+G+G)", "re9_mixed_herb", 1, {re9_green_herb = 3})
	CaseInventory:RegisterCraftingRecipe("Mixed Herb (G+R)", "re9_mixed_herb", 1, {re9_green_herb = 1, re9_red_herb = 1})
end)