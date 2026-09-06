local commands = {}



function commands.DropItem(ply, invID, count, sync)
	CaseInventory:DropItem(CaseInventory:Inv(ply), invID, count, ply, sync)
end

function commands.Use(ply, invID, sync)
	CaseInventory:UseItem(ply, invID, sync)
end

function commands.SyncLocations(ply, toPlace)
	local plyCopy = table.Copy(CaseInventory:Inv(ply))
	CaseInventory:ClearLoadout(plyCopy)



	for k, v in pairs(plyCopy.Items) do
		if toPlace[k] ~= nil then
			plyCopy.Items[k].X = toPlace[k].X
			plyCopy.Items[k].Y = toPlace[k].Y
			plyCopy.Items[k].Rotated = toPlace[k].Rotated
		end
	end

	for k, v in pairs(plyCopy.Items) do
		-- If a **SINGLE** item can't be placed bail
		if not CaseInventory:PlaceItem(plyCopy, k, v) then
			return false
		end
	end

	CaseInventory:Inv(ply).Items = plyCopy.Items
	CaseInventory:Inv(ply).Loadout = plyCopy.Loadout
end

function commands.MergeItems(ply, srcID, destID, sync)
	CaseInventory:MergeItem(CaseInv(ply), CaseInv(ply), srcID, destID, sync)
end
-- Client to server command packet structure
--[[
	uint4 command
]]--
net.Receive("CaseNetMsg", function (len, ply)
	local cmd = net.ReadUInt(8)

	if cmd == CASE_COMMAND_DROP then
		local invID = net.ReadUInt(16)
		local count = net.ReadInt(16)
		local sync = net.ReadBool()
		commands.DropItem(ply, invID, count, sync)
	end

	if cmd == CASE_COMMAND_SYNC then
		local newItems = {}
		local count = math.min(net.ReadUInt(16), table.Count(CaseInventory:Inv(ply).Items))
		for i=1, count do
			local invId = net.ReadUInt(16)
			local x = net.ReadUInt(8)
			local y = net.ReadUInt(8)
			local rotated = net.ReadBool()


			if CaseInventory:Inv(ply).Items[invId] == nil then
				return
			end

			newItems[invId] = {
				X=x,
				Y=y,
				Rotated=rotated
			}
		end

		commands.SyncLocations(ply, newItems)
		CaseInventory:Sync(ply)
	end

	if cmd == CASE_COMMAND_USE then
		local invID = net.ReadUInt(16)
		local sync = net.ReadBool()
		commands.Use(ply, invID, sync)
	end

	if cmd == CASE_COMMAND_MERGE then
		local srcID = net.ReadUInt(16)
		local destID = net.ReadUInt(16)
		local sync = net.ReadBool()
		commands.MergeItems(ply, srcID, destID, sync)
	end

	if cmd == CASE_COMMAND_SYNC_OVERRIDES then
		-- Admin only thing, now die
		if not ply:IsAdmin() then
			return
		end

		local itemID = net.ReadUInt(16)
		local delete = net.ReadBool()

		if delete then
			CaseInventory:SetOverride(itemID, nil)
		else
			local model = net.ReadString()

			local size = {
				net.ReadUInt(16),
				net.ReadUInt(16)
			}

			-- Only size needs to be checked as the others are visual only
			if size[1] <= 0 then
				size[1] = 1
			end

			if size[2] <= 0 then
				size[2] = 1
			end

			local scale = net.ReadDouble()

			local offset = {
				net.ReadDouble(),
				net.ReadDouble(),
				net.ReadDouble()
			}

			local rotation = {
				net.ReadDouble(),
				net.ReadDouble(),
				net.ReadDouble()
			}

			local maxCount = net.ReadUInt(16)
			local blacklist = net.ReadBool()

			local skin = net.ReadUInt(8)

			local useSprite = net.ReadBool()

			-- Store it away
			CaseInventory:SetOverride(itemID, {
				Size=size,
				MaxCount=maxCount,
				Blacklist=blacklist,
				RenderInfo=CaseRenderInfo(model, scale, rotation, offset, skin, useSprite)
			})
		end -- END NO DELETE

		-- Now time to replicate this to all clients
		CaseInventory:SendOverride(itemID)

		-- Rearrange inventory for fun
		for k, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) then
				continue
			end

			CaseInventory:ClearLoadout(CaseInventory:Inv(ply))

			for invID, invInfo in pairs(CaseInventory:Inv(ply).Items) do
				if not CaseInventory:PlaceItem(CaseInventory:Inv(ply), k, invInfo) then
					local found, x, y = CaseInventory:FindValidSpot(CaseInventory:Inv(ply), invInfo.ItemID)
					if not found then
						CaseInventory:DropItem(CaseInventory:Inv(ply), k, -1, ply, false)
					else
						invInfo.X = x
						invInfo.Y = y
						CaseInventory:PlaceItem(CaseInventory:Inv(ply), k, invInfo)
					end
				end
			end

			CaseInventory:Sync(ply, true)
		end

		-- Save everything to disk
		CaseInventory:SaveOverrides()
	end

	if cmd == CASE_COMMAND_SYNC_ITEM then
		-- Admin only thing (again), now die (again)
		if not ply:IsAdmin() then
			return
		end

		local itemName = net.ReadString()
		local mode = net.ReadUInt(4)

		if mode == CASE_ITEM_CREATE then
			local printName = net.ReadString()
			local model = net.ReadString()
			CaseInventory:CreateCustomItem(itemName, printName, model)
			return
		end

		if mode == CASE_ITEM_EDIT then
			local printName = net.ReadString()
			local itemType = net.ReadUInt(8)
			local useCondition = net.ReadUInt(8)

			CaseInventory:UpdateCustomItem(itemName, printName, itemType, useCondition)
		end

		if mode == CASE_ITEM_REMOVE then
			CaseInventory:RemoveCustomItem(itemName)
			return
		end
	end

	if cmd == CASE_COMMAND_CRAFT then
		local rID = net.ReadUInt(16)
		local count = net.ReadUInt(16)

		for i = 1, count do
			if not CaseInventory:Craft(ply, rID) then
				break
			end
		end

	end

	if cmd == CASE_COMMAND_MODIFY_RECIPE then
		local function NotifyPlayer(player, id)
			net.Start("CaseNetMsg")
				net.WriteUInt(CASE_EVENT_FINISH_MODIFY_RECIPE, 8)
				net.WriteInt(id, 16)
			net.Send(player)
		end

		if not ply:IsAdmin() then
			NotifyPlayer(ply, 0)
			return
		end

		local recipe = CaseInventory:Recipe()
		local recipeID = net.ReadUInt(16)

		-- We're looking to add a new one
		if recipeID == 0 then
			local usedID = 1
			while true do
				local rec = CaseInventory:GetRecipe(usedID)
				if rec == nil then
					break
				end

				usedID = usedID + 1
			end
			recipeID = usedID
		end

		local delete = net.ReadBool()
		if delete then
			CaseInventory:DeleteRecipe(recipeID)
			CaseInventory:SaveRecipes()
			NotifyPlayer(ply, -1)
			return
		end

		recipe.Disabled = net.ReadBool()


		local _recipe = CaseInventory:GetRecipe(recipeID)
		-- Quick lookup
		if _recipe ~= nil and not _recipe.IsCustom then
			_recipe.Disabled = recipe.Disabled

			CaseInventory:SyncRecipe(recipeID)
			CaseInventory:SaveRecipes()
			NotifyPlayer(ply, recipeID)
			return
		end



		recipe.Result = net.ReadUInt(16)
		recipe.DisplayName = CaseInventory:GetValidRecipeName(net.ReadString(), recipeID)
		recipe.Count = net.ReadUInt(16)
		recipe.Input = {}

		local inputCount = net.ReadUInt(4)

		for i = 1, math.min(8, inputCount) do
			local inputID = net.ReadUInt(16)
			local count = net.ReadUInt(16)

			recipe.Input[inputID] = count
		end

		recipe.IsCustom = true

		-- and finally, do a little validation
		local toValidate = table.Copy(recipe.Input)
		toValidate[recipe.Result] = 1 -- Also just plonk that in there

		for itemID, _ in pairs(toValidate) do
			local itemInfo = CaseInventory:GetItemInfo(itemID)
			if itemInfo == nil then
				NotifyPlayer(ply, 0)
				return
			end

			if itemInfo.ItemType == CASE_ITEM_DO_NOT_HANDLE or itemInfo.ItemType == CASE_ITEM_GLOW_ONLY then
				NotifyPlayer(ply, 0)
				return
			end
		end

		-- All good!

		CaseInventory.CraftingRecipes[recipeID] = recipe

		-- Send this stuff away
		CaseInventory:SyncRecipe(recipeID)

		-- Finally save it to disk
		CaseInventory:SaveRecipes()

		NotifyPlayer(ply, recipeID)
	end

	--[[
	if cmd == CASE_COMMAND_REQUEST_OVERRIDES then
		if ply.HasSyncedOverrides == nil or not ply.HasSyncedOverrides then
			-- Only allow this once
			ply.HasSyncedOverrides = true
			for k, v in pairs(CaseInventory.RegisterOverrides) do
				CaseInventory:SendOverride(k, ply)
			end
		end
	end
	]]
end)