CaseInventory.ClientNet = {
	DropItem = function (invId, count, sync)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_DROP, 8)
		net.WriteUInt(invId, 16)
		net.WriteInt(count, 16)
		net.WriteBool(sync)
		net.SendToServer()
	end,
	UseItem = function (invId, sync)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_USE, 8)
		net.WriteUInt(invId, 16)
		net.WriteBool(sync)
		net.SendToServer()
	end,
	MergeItems = function (srcID, destID, sync)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_MERGE, 8)
		net.WriteUInt(srcID, 16)
		net.WriteUInt(destID, 16)
		net.WriteBool(sync)
		net.SendToServer()
	end,
	SyncItems = function ()
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_SYNC, 8)
		net.WriteUInt(table.Count(CaseInventory:Inv().Items), 16)
		for k, v in pairs(CaseInventory:Inv().Items) do
			net.WriteUInt(k, 16)
			net.WriteUInt(v.X, 8)
			net.WriteUInt(v.Y, 8)
			net.WriteBool(v.Rotated)
		end
		net.SendToServer()
	end,
	UpdateOverride = function (itemID, info)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_SYNC_OVERRIDES, 8)
			net.WriteUInt(itemID, 16)
			net.WriteBool(info == nil)

			-- Break the packet off here
			if info == nil then
				net.SendToServer()
				return
			end


			net.WriteString(info.RenderInfo.Model)

			-- Write size
			net.WriteUInt(info.Size[1] ~= nil and info.Size[1] or 1, 16)
			net.WriteUInt(info.Size[2] ~= nil and info.Size[2] or 1, 16)

			-- Write scale
			net.WriteDouble(info.RenderInfo.Scale)

			-- Write offset
			net.WriteDouble(info.RenderInfo.Offset.X)
			net.WriteDouble(info.RenderInfo.Offset.Y)
			net.WriteDouble(info.RenderInfo.Offset.Z)

			-- Write rotation
			net.WriteDouble(info.RenderInfo.Rotations[1])
			net.WriteDouble(info.RenderInfo.Rotations[2])
			net.WriteDouble(info.RenderInfo.Rotations[3])

			-- Write max count
			net.WriteUInt(info.MaxCount, 16)

			-- Write blacklist
			net.WriteBool(info.Blacklist)

			-- Write model skin
			net.WriteUInt(info.RenderInfo.Skin, 8)

			-- Write Sprite thingy
			net.WriteBool(info.RenderInfo.UseSprite)

		net.SendToServer()
	end,
	RequestOverrides = function ()
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_REQUEST_OVERRIDES, 8)
		net.SendToServer()
	end,
	CreateItem = function (name, model, printName)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_SYNC_ITEM, 8)
			net.WriteString(name)
			net.WriteUInt(CASE_ITEM_CREATE, 4)

			net.WriteString(printName)
			net.WriteString(model)

		net.SendToServer()
	end,
	UpdateItem = function (name, printName, itemType, useCondition)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_SYNC_ITEM, 8)
			net.WriteString(name)
			net.WriteUInt(CASE_ITEM_EDIT, 4)
			net.WriteString(printName)
			net.WriteUInt(itemType, 8)
			net.WriteUInt(useCondition, 8)
		net.SendToServer()
	end,
	RemoveItem = function (name)
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_SYNC_ITEM, 8)
			net.WriteString(name)
			net.WriteUInt(CASE_ITEM_REMOVE, 4)
		net.SendToServer()
	end,
	Craft = function (recipeID, count)
		if count == nil then
			count = 1
		end

		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_COMMAND_CRAFT, 8)
			net.WriteUInt(recipeID, 16)
			net.WriteUInt(count, 16)
		net.SendToServer()
	end,
	-- Set recipeID to 0 to indicate a new recipe
	SubmitRecipe = function (recipeID, recipe)
		net.Start("CaseNetMsg")
			net.WriteUInt(CASE_COMMAND_MODIFY_RECIPE, 8)
			net.WriteUInt(recipeID, 16)
			local delete = recipe == nil
			net.WriteBool(delete) -- Delete?

			if delete then
				net.SendToServer()
				return
			end

			net.WriteBool(recipe.Disabled)

			-- Disabled is the only thing that non-custom recipes will take
			if not recipe.IsCustom then
				net.SendToServer()
				return
			end


			net.WriteUInt(recipe.Result, 16)
			net.WriteString(recipe.DisplayName)
			net.WriteUInt(recipe.Count, 16)
			net.WriteUInt(table.Count(recipe.Input), 4)
			for itemID, count in pairs(recipe.Input) do
				net.WriteUInt(itemID, 16)
				net.WriteUInt(count, 16)
			end
		net.SendToServer()
	end,
	SyncTemp = nil

}



-- Packet structure :)
--[[
	uint8 SizeX
	uint8 SizeY
	uint16 ItemCount
	for ItemCount
		uint16   index
		uint16   itemID
		uint32   count
		uint1    rotated
		uint8    X
		uint8    Y
]]--
local function CaseSync()
	local ply = LocalPlayer()
	local ready = IsValid(ply) -- uh oh

	if not ready then
		CaseInventory.ClientNet.SyncTemp = {
			W=net.ReadUInt(8),
			H=net.ReadUInt(8),
			Items={}
		}
		local itemCount = net.ReadUInt(16)
		for i=1, itemCount do
			local index = net.ReadUInt(16)
			local newItem = CaseInventory:CreateItemInfo(
				net.ReadUInt(16),   -- ItemID
				net.ReadUInt(32),   -- Count
				net.ReadBool(),     -- Rotated
				net.ReadUInt(8),    -- X
				net.ReadUInt(8)     -- Y

			)

			CaseInventory.ClientNet.SyncTemp.Items[index] = newItem
		end
		return
	end

	CaseInv(LocalPlayer(), CaseInventory:GenerateInventory(net.ReadUInt(8), net.ReadUInt(8), LocalPlayer())) -- Setup local thing
	CaseInventory:ClearLoadout(CaseInv(LocalPlayer()))


	local itemCount = net.ReadUInt(16)
	--print("Recv item count:", itemCount)
	for i=1, itemCount do
		local index = net.ReadUInt(16)
		local newItem = CaseInventory:CreateItemInfo(
			net.ReadUInt(16),   -- ItemID
			net.ReadUInt(32),   -- Count
			net.ReadBool(),     -- Rotated
			net.ReadUInt(8),    -- X
			net.ReadUInt(8)     -- Y

		)


		CaseInventory:Inv().Items[index] = newItem
		CaseInventory:PlaceItem(CaseInventory:Inv(), index, newItem)
	end


	if CaseGUI.IsOpen then
		local realInv = CaseInv(LocalPlayer())
		local fakeInv = CaseGUI.InvTargets["MainWindow"]:Inv()
		local sortingInv = CaseGUI.InvTargets["SortingWindow"]:Inv()

		-- Nuke any items that don't exist in the actual inventory any more
		for invID, invInfo in pairs(fakeInv.Items) do
			if realInv.Items[invID] == nil then
				fakeInv.Items[invID] = nil
			end
		end

		for invID, invInfo in pairs(sortingInv.Items) do
			if realInv.Items[invID] == nil then
				sortingInv.Items[invID] = nil
			end
		end

		local resyncSorting = false
		-- Sync up items
		for invID, invInfo in pairs(realInv.Items) do
			local exists = fakeInv.Items[invID] ~= nil or sortingInv.Items[invID] ~= nil
			local usedInvInfo = nil

			-- Doesn't actually exist at all :(
			-- This means the item was added while the inventory was open
			if not exists then
				resyncSorting = true
				fakeInv.Items = table.Copy(realInv.Items)
				break
			end

			if fakeInv.Items[invID] ~= nil then
				usedInvInfo = fakeInv.Items[invID]
			end

			if sortingInv.Items[invID] ~= nil then
				usedInvInfo = sortingInv.Items[invID]
			end

			--????
			if usedInvInfo == nil then
				continue
			end

			usedInvInfo.Count = invInfo.Count
		end

		-- This will only happen if a new item was picked up while the inventory was open
		-- like 100% chance it's ammo so yay
		if resyncSorting then
			for invID, sortInvInfo in pairs(sortingInv.Items) do
				local invInfo = CaseInv(LocalPlayer()).Items[invID]

				-- If an item was removed from the left, remove it from the sorting window
				if invInfo == nil then
					sortingInv.Items[invID] = nil
					continue
				end

				-- An item exists both on both sides, make sure it's the same type
				-- then remove it from the main case
				-- Also sync the new count if something happened to it
				if invInfo ~= nil and invInfo.ItemID == sortInvInfo.ItemID then
					sortInvInfo.Count = invInfo.Count
					fakeInv.Items[invID] = nil
				end
			end
		end

		-- Finally apply what we've done
		CaseInventory:RefreshLoadout(fakeInv)
		CaseInventory:RefreshLoadout(sortingInv)
	end

end

local function CaseSyncIDs()
	local count = net.ReadUInt(8)
	if count == 0 then
		CaseInventory.ItemRegisterApply = true
		return
	end

	for id=1, count do
		local id = net.ReadUInt(32)
		local name = net.ReadString()
		CaseInventory.ItemRegisterLayout[id] = name
	end
end

local function CaseSyncOverride()
	local itemID = net.ReadUInt(16)
	local delete = net.ReadBool()

	if delete then
		CaseInventory:SetOverride(itemID, nil)
		return
	end

	local model = net.ReadString()

	local size = {
		net.ReadInt(16),
		net.ReadInt(16)
	}

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

	CaseInventory:SetOverride(itemID, {
		Size=size,
		MaxCount=maxCount,
		Blacklist=blacklist,
		RenderInfo=CaseRenderInfo(model, scale, rotation, offset, skin, useSprite)
	})

	CaseInventory:UpdateLookups()
end

local function CaseOnPickup()
	local itemID = net.ReadUInt(16)
	local info = CaseInventory:GetItemInfo(itemID)


	if info ~= nil then
		if info.ItemType == CASE_ITEM_GENERIC then
			CaseGUI.PlaySound("ui/re4case/case_pickup_item.wav")
		end
	end
end

--[[
	bool isToolSelect
		(if true)
		string name
		string model

	(if false)
		uint16 itemID
		string name
		string printName
		string model
		uint8 type
		uint8 canUseCondition
]]
local function CaseSyncCustomItems()
	local isToolSelect = net.ReadBool()
	if isToolSelect then
		local class = net.ReadString()
		local name = net.ReadString()
		local model = net.ReadString()

		CaseItemCreator.Current.Model = model
		CaseItemCreator.Current.PrintName = name
		CaseItemCreator:SelectEntity(class)
		return
	else

		local itemID = net.ReadUInt(16)
		local delete = net.ReadBool()

		if delete then
			local name = CaseInventory.ItemRegister[itemID].Name
			CaseInventory.CustomItems[itemID] = nil

			CaseInventory.ItemRegister[itemID] = nil
			CaseInventory.RegisterOverrides[itemID] = nil

			if CaseItemCreator.Current.Class == name then
				CaseItemCreator:SelectEntity(CaseItemCreator.Current.Class)
			end

			CaseInventory:UpdateLookups()
			return
		end

		local name = net.ReadString()
		local printName = net.ReadString()
		local model = net.ReadString()
		local type = net.ReadUInt(8)
		local useMode = net.ReadUInt(8)



		CaseInventory.CustomItems[itemID] = {
			Class = name,
			PrintName = printName,
			Type = type,
			CanUse = useMode,
			Model = model
		}

		local item = CaseInventory:GenerateCustomItemInfo(name, printName, model, type)
		item.ItemID = itemID

		CaseInventory:UpdateCustomTags(item, type, useMode)

		CaseInventory.ItemRegister[itemID] = item

		-- As a treat, check the override register
		if CaseInventory.RegisterOverrides[itemID] ~= nil then
			CaseInventory.RegisterOverrides[itemID].PrintName = printName
			CaseInventory.RegisterOverrides[itemID].OnUse = item.OnUse
			CaseInventory.RegisterOverrides[itemID].CanUse = item.CanUse
		end

		-- Reselect to update stuff
		if CaseItemCreator.Current.Class == name then
			CaseItemCreator:SelectEntity(name)
		end

		-- finally after everything, update the lookups
		CaseInventory:UpdateLookups()

	end
end

local function CaseAutoGenWeapons()
	local done = net.ReadBool()
	if done then
		CaseInventory.ObtainedAutoGenerate = true
		return
	end

	local count = net.ReadUInt(8)
	for i=1, count do

		local autoGen = {
			Type = net.ReadUInt(4),
			Name = net.ReadString(),
			PrintName = net.ReadString(),
			Model = net.ReadString(),
			Scale = net.ReadDouble(),
			Rotation = {net.ReadDouble(), net.ReadDouble(), net.ReadDouble()},
			Size = {net.ReadInt(8), net.ReadInt(8)},
			Count = net.ReadUInt(16),
			AmmoID = net.ReadInt(16)
		}
		table.insert(CaseInventory.AutoGenerateInfo, autoGen)
	end

end

local function CaseSyncRecipe()
	local recipe = CaseInventory:Recipe()
	local recipeID = net.ReadUInt(16)
	local delete = net.ReadBool()

	if delete then
		CaseInventory.CraftingRecipes[recipeID] = nil
		CraftingEditor.NeedsUpdating = true
		CaseInventory:UpdateLookups()
		return
	end

	recipe.IsCustom = net.ReadBool()
	recipe.Disabled = net.ReadBool()
	recipe.Result = net.ReadUInt(16)
	recipe.DisplayName = net.ReadString()
	recipe.Count = net.ReadUInt(16)
	recipe.Input = {}


	local inputCount = net.ReadUInt(4)

	for i = 1, math.min(8, inputCount) do
		local inputID = net.ReadUInt(16)
		local count = net.ReadUInt(16)

		recipe.Input[inputID] = count
	end

	CaseInventory.CraftingRecipes[recipeID] = recipe
	CaseInventory:UpdateLookups()


end

local function CaseSyncFinishEdit()
	local id = net.ReadInt(16)

	-- Editor doesn't need to be updated so why bother :)
	if IsValid(CraftingEditor.Panel) then
		CraftingEditor.NeedsUpdating = true
		CraftingEditor.UpdateID = id
	end
end


net.Receive("CaseNetMsg", function ()
	local msg = net.ReadUInt(8)
	if msg == CASE_EVENT_SYNC then
		return CaseSync()
	end

	if msg == CASE_EVENT_SYNC_IDS then
		return CaseSyncIDs()
	end

	if msg == CASE_EVENT_SYNC_CUSTOM_ITEMS then
		return CaseSyncCustomItems()
	end

	if msg == CASE_EVENT_AUTO_GEN_WEAPONS then
		return CaseAutoGenWeapons()
	end

	if msg == CASE_EVENT_SYNC_OVERRIDE then
		return CaseSyncOverride()
	end

	if msg == CASE_EVENT_ON_PICKUP then
		return CaseOnPickup()
	end

	if msg == CASE_EVENT_SYNC_RECIPE then
		return CaseSyncRecipe()
	end

	if msg == CASE_EVENT_FINISH_MODIFY_RECIPE then
		return CaseSyncFinishEdit()
	end
end)
