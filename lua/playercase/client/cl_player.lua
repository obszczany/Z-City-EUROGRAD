-- CVars that are checked serverside, but are client vars
local case_pickup_on_hold = CreateConVar("case_cl_pickup_on_hold", "1", {FCVAR_ARCHIVE, FCVAR_USERINFO}, [[0 -> Holding an item doesn't pick it up
1 -> Holding an item picks it up if walk isn't held
2 -> Holding an item picks it up]], 0, 2)

local case_pickup_mode = CreateConVar("case_cl_pickup_mode", "1", {FCVAR_ARCHIVE, FCVAR_USERINFO}, [[0 -> Items can be walked over to be picked up
1 -> Items must be +used to pickup (will still be picked up if in a vehicle)
2 -> Items must be +used no matter what]], 0, 2)


local cvar_invert_pickup = CreateConVar("case_cl_invert_pickup", "0", {FCVAR_ARCHIVE, FCVAR_USERINFO}, [[0 -> Items will be used unless walk is held,
1 -> Items will be stored unless walk is held]])

local cvar_quick_drop = CreateClientConVar("case_quick_drop", input.GetKeyCode("q"), true, false, "Button to quickly drop stuff")
local cvar_quick_use = CreateClientConVar("case_quick_use", input.GetKeyCode("e"), true, false, "Button to quickly use stuff")
local cvar_quick_edit = CreateClientConVar("case_quick_edit", input.GetKeyCode("r"), true, false, "Button to quickly edit stuff")

local mStatus = {
	Left = 0,
	Right = 0,
	Up = 0,
	Down = 0
}

local function _checkInput(name, thing)

	if mStatus[name] < 0 then
		mStatus[name] = mStatus[name] + 1
	end

	if input.IsMouseDown(thing) and mStatus[name] ~= 2 then
		mStatus[name] = mStatus[name] + 1
	else
		mStatus[name] = 0
	end
end

hook.Add("PreDrawHalos", "CASE_PreDrawHalos", function ()
	local lookTarget = LocalPlayer():GetEyeTrace().Entity

	if IsValid(lookTarget) and
		LocalPlayer():GetPos():Distance(lookTarget:GetPos()) < 75
	then
		local itemID = CaseInventory:GetItemID(lookTarget:GetClass())
		if itemID == -1 then
			return
		end

		local itemInfo = CaseInventory:GetItemInfo(itemID)
		local drawColor = Color(0, 255, 0)

		-- Weapons will just give ammo if we already have one
		if itemInfo.ItemType == CASE_ITEM_WEAPON and not CaseInventory:HasItem(CaseInv(), itemID) then
			if not CaseInventory:FindValidSpot(CaseInv(), itemID) then
				drawColor = Color(255, 0, 0)
			end
		end

		if itemInfo.ItemType == CASE_ITEM_GENERIC or itemInfo.ItemType == CASE_ITEM_GRENADE then
			local canUse = itemInfo.OnUse ~= nil and CaseInventory:CanUse(LocalPlayer(), itemID)

			local invertWalk = cvar_invert_pickup:GetBool()
			local performUse = false

			local hasValid = false

			if not invertWalk then
				performUse = not LocalPlayer():KeyDown(IN_WALK)
			else
				performUse = LocalPlayer():KeyDown(IN_WALK)
			end

			if itemInfo.ItemType == CASE_ITEM_GENERIC and performUse and canUse then
				drawColor = Color(0, 0, 255)
				hasValid = true
			end

			if not hasValid then
				for k, v in pairs(CaseInv().Items) do
					if v.ItemID == itemID and v.Count < itemInfo.MaxCount then
						hasValid = true
						break
					end
				end
			end

			if not hasValid and CaseInventory:FindValidSpot(CaseInv(), itemID) then
				hasValid = true
			end

			if not hasValid then
				drawColor = Color(255, 0, 0)
			end
		end

		halo.Add({lookTarget}, drawColor, 2, 2, 2)
	end
end)

-- Very fancy way of doing this
hook.Add("CreateMove", "testMouseWheel", function(cmd)
	if input.WasMousePressed(MOUSE_WHEEL_UP) then
		mStatus.Up = 1
	end

	if input.WasMousePressed(MOUSE_WHEEL_DOWN) then
		mStatus.Down = 1
	end

	local keyLeft = nil
	local keyRight= nil

	local bind = input.LookupBinding( "+moveleft")
	if bind ~= nil then
		keyLeft = input.GetKeyCode(bind)
	else
		keyLeft = KEY_A
	end

	bind = input.LookupBinding( "+moveright")
	if bind ~= nil then
		keyRight = input.GetKeyCode(bind)
	else
		keyRight = KEY_D
	end

	if input.WasKeyPressed(keyLeft) or input.WasKeyPressed(KEY_A) then
		mStatus.Up = 1
	end

	if input.WasKeyPressed(keyRight) or input.WasKeyPressed(KEY_D) then
		mStatus.Down = 1
	end


	-- Allow closing the case with the same button used to open it
	local doClose = false

	local bind = input.LookupBinding("case_open")
	if bind ~= nil then
		bind = input.GetKeyCode(bind)
		if input.WasKeyPressed(bind) or input.WasMousePressed(bind) then
			doClose = true
		end
	end

	bind = input.LookupBinding("case_open_crafting")
	if not doClose and bind ~= nil then
		bind = input.GetKeyCode(bind)
		if input.WasKeyPressed(bind) or input.WasMousePressed(bind) then
			doClose = true
		end
	end


	if CaseGUI.IsOpen and CaseGUI.ReadyToClose and doClose then
		CaseGUI:Close()
	end

	if CaseCraftGUI:IsOpen() and doClose then
		CaseCraftGUI:Close()
	end

	-- Handle the quick use / quick drop commands / whatever i may add in the future
	if CaseGUI.IsOpen then

		if input.WasKeyPressed(cvar_quick_use:GetInt()) or input.WasMousePressed(cvar_quick_use:GetInt()) then
			local invID, item = CaseGUI:GetHoveredItem()
			if item ~= nil then

				-- Swap to a weapon if it was used instead of an item
				if CaseInventory:IsWeapon(item.ItemID) then
					local wep = LocalPlayer():GetWeapon(CaseInventory:GetItemInfo(item.ItemID).Name)
					if wep ~= nil then
						input.SelectWeapon(wep)
					end
				else
					CaseInventory.ClientNet.UseItem(invID, true)
				end
			end
		end

		if input.WasKeyPressed(cvar_quick_drop:GetInt()) or input.WasMousePressed(cvar_quick_drop:GetInt()) then
			local invID, item = CaseGUI:GetHoveredItem()
			if item ~= nil then
				local count = 1
				if input.IsKeyDown(KEY_LSHIFT) then
					count = item.Count
				end
				CaseInventory.ClientNet.DropItem(invID, count, true)
			end
		end

		if input.WasKeyPressed(cvar_quick_edit:GetInt()) or input.WasMousePressed(cvar_quick_edit:GetInt()) then
			local invID, item = CaseGUI:GetHoveredItem()
			if item ~= nil then
				if not IsValid(CaseGUI.EditWindow.Window) then
					CaseGUI:OpenEditMenu()
				end

				CaseGUI.EditWindow.Filter:SetText("")

				-- gonna be so real these should be sorted but like idc
				local i = 1
				while true do
					local data = CaseGUI.EditWindow.WeaponList:GetOptionData(i)
					if data == nil then
						break
					end
					if data == item.ItemID then
						CaseGUI.EditWindow.WeaponList:ChooseOptionID(i)
						break
					end

					i = i + 1
				end

			end
		end
	end
end)

-- This hook is only really for the GUI
hook.Add("Think", "CASE_Think", function ()

	-- Doing this frame one because trying to populate the names anywhere else kinda doesn't work
	if not CaseInventory.Ready then
		CaseInventory.Ready = true
		CaseInventory:PopulateNames()

		-- Force update all items
		for k, v in pairs(CaseInventory.ItemRegister) do
			CaseInventory:GetItemInfo(k)
		end
	end

	_checkInput("Left", MOUSE_LEFT)
	_checkInput("Right", MOUSE_RIGHT)



	if CaseGUI.IsOpen then
		-- Reset the held item back to its last position
		if mStatus.Right == 1 and CaseGUI.HeldItem.InvID ~= -1 then
			CaseGUI.HeldItem.InvID = -1
			CaseGUI.PlaySound("ui/re4case/case_unequip.wav")
		end

		if mStatus.Up == 1 or mStatus.Down == 1 then
			mStatus.Up = 0
			mStatus.Down = 0

			if CaseGUI.HeldItem.InvID ~= -1 then
				CaseGUI.HeldItem.Rotated = not CaseGUI.HeldItem.Rotated
				CaseGUI.PlaySound("ui/re4case/case_selection.wav")
			end
		end

	end


	if CaseGUI.SortingWindow ~= nil then
		-- Move the second window to the front so it's not obscured by the blur
		CaseGUI.SortingWindow:MoveToFront()
		local hasItem = false
		for k, v in pairs(CaseGUI.InvTargets["SortingWindow"]:Inv().Items) do
			if v ~= nil then
				hasItem = true
				break
			end
		end

		if CaseGUI.HeldItem.InvID == -1 and not hasItem then-- and  then
			CaseGUI.SortingWindow:Hide()
		else
			CaseGUI.SortingWindow:Show()
		end
	end

	if CaseGUI.Context.Panel ~= nil then
		if CaseGUI.Context.Parent:Inv().Items[CaseGUI.Context.InvID] == nil then
			CaseGUI:CloseContext()
			return
		end
		CaseGUI.Context.Panel:MoveToFront()
		if CaseGUI.Context.Parent == CaseGUI.InvTargets["SortingWindow"] and not CaseGUI.SortingWindow:IsVisible() then
			CaseGUI.Context.Panel:Remove()
			CaseGUI.Context.Panel = nil
		else
			CaseGUI.Context.Panel:MoveToFront()
		end
	end

	if CaseGUI.IsOpen and not CaseGUI.ReadyToClose then
		CaseGUI.ReadyToClose = true
	end
end)


hook.Add( "InitPostEntity", "CASE_PostInit", function()
	-- A sync event happened before the client was ready, apply it now
	if CaseInventory.ClientNet.SyncTemp ~= nil then
		local ply = LocalPlayer()
		CaseInventory.ClientInventory = CaseInventory:GenerateInventory(
			CaseInventory.ClientNet.SyncTemp.W,
			CaseInventory.ClientNet.SyncTemp.H, ply)

		for k, v in pairs(CaseInventory.ClientNet.SyncTemp.Items) do
			CaseInventory:Inv().Items[k] = v
			CaseInventory:PlaceItem(CaseInventory:Inv(), k, v)
		end
		CaseInventory.ClientNet.SyncTemp = nil
	end
end )

-- Hook into the pause menu (ESC) so we can close the case if it's open
hook.Add( "OnPauseMenuShow", "CASE_OnyPauseMenuShow", function()
	if CaseGUI.IsOpen then
		CaseGUI:Close()
		return false
	end
	return true
end )


concommand.Add("case_print_inv", function(ply)
	PrintTable(CaseInventory:Inv(ply))
end)

concommand.Add("case_print_registry", function(ply, cmd, args, argStr)
	if argStr ~= "" then
		local items = {}
		for k, v in pairs(CaseInventory.ItemRegister) do
			if string.find(v.Name, argStr, 1, true) then
				items[k] = v
			end
		end

		PrintTable(items)
	else
		PrintTable(CaseInventory.ItemRegister)
	end
end)

concommand.Add("case_print_overrides", function(ply)
	PrintTable(CaseInventory.RegisterOverrides)
end)

concommand.Add("case_print_custom", function(ply)
	PrintTable(CaseInventory.CustomItems)
end)

concommand.Add("case_print_recipes", function (ply)
	PrintTable(CaseInventory.CraftingRecipes)
end)

concommand.Add("case_print_lookups", function ()
	PrintTable(CaseInventory.CraftingLookup)
end)

-- This just kinda has to be here so the client can see it
concommand.Add( "case_pickup", function(ply, cmd, args, argStr)
end )