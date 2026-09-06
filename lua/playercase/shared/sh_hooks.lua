
hook.Add("Initialize", "CASE_Initialize", function ()


end)


-- This is done later to make sure everything that can be auto-generated will be
-- I --ran into-- keep running into some issues with ammo generation at some point
hook.Add("InitPostEntity", "CASE_InitPostEntity", function ()
	hook.Run("CaseRegisterItems")



	if CLIENT then
		-- Time to burn a few CPU cycles
		while not CaseInventory.ObtainedAutoGenerate do
		end
	end


	CaseInventory:AutoGenerate()

	if CLIENT and not CaseInventory.ItemRegisterApply then
		return
	end
	-- Serverside stuff
	CaseInventory:FinalizeItemRegister()



	if SERVER then
		hook.Run("CaseRegisterRecipes")
		CaseInventory:LoadRecipes()
	end

	CaseInventory:UpdateLookups()

	if CLIENT then
		CaseInventory:RefreshLoadout(CaseInv())
	end
end)

