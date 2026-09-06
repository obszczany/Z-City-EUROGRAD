local cvar_drop_excess_ammo = 0
local cvar_inventory_mode = 0
local cvar_auto_generate = 0
local cvar_enable_swap = 0
local cvar_default_case_size = 0

local MARKED_FOR_PICKUP_DELAY = 5

if SERVER then
	--[[
	local case_sync_mode = CreateConVar("case_sync_mode", "0", {FCVAR_ARCHIVE},
	[[Determines if weapons/ammo should be given or taken if they are not in the inventory on sync
	0 -> Weapons/ammo should be given if they are in the inventory but not held
	1 -> Weapons/ammo should be removed from the inventory if they aren't also held
	, 0, 1)
	]]
	cvar_inventory_mode = CaseInventory:GetCVAR("case_inventory_mode")
	cvar_drop_excess_ammo = CaseInventory:GetCVAR("case_drop_excess_ammo")
	cvar_auto_generate = CaseInventory:GetCVAR("case_auto_generate")
	cvar_default_case_size = CaseInventory:GetCVAR("case_default_size")
end

if CLIENT then
	cvar_inventory_mode = CreateConVar("case_sh_inventory_mode", "0", {FCVAR_REPLICATED})
	cvar_auto_generate = CreateConVar("case_sh_auto_generate", "1", {FCVAR_REPLICATED})
	cvar_enable_swap = CreateConVar("case_cl_enable_swapping", "1", {FCVAR_ARCHIVE})
	cvar_default_case_size = CreateConVar("case_sh_default_size", "s", {FCVAR_REPLICATED})

end


---Converts a source/lua weapon into a usable item in the inventory
---@param ply table
---@param wpn table
---@return boolean added Was the weapon added to the inventory of the player?
function CaseInventory:PickupWeapon(ply, wpn)
	if not wpn:IsWeapon() and not wpn:IsScripted() then
		return false
	end

	if SERVER then
		-- We need to see if any other mods would try to deal with the weapon we're about to pickup
		if CaseInventory:GetCVAR("case_pickup_compat"):GetBool() then

			CASE_PASS_PICKUP_HOOK = true
			local result = hook.Run("PlayerCanPickupWeapon", ply, wpn)
			CASE_PASS_PICKUP_HOOK = false


			-- We only need to bail on false, nil or true and we can continue
			if result == false then
				return false
			end
		end
	end

	local wpnId = CaseInventory:GetItemID(wpn:GetClass())
	local info = CaseInventory:GetItemInfo(wpnId)
	local count = CaseInventory:ItemCount(CaseInventory:Inv(ply), wpnId)

	-- Do a count check here just for grenades :)
	if count == 0 or info.ItemType == CASE_ITEM_GRENADE then
		if not CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), wpnId, 1) then
			return false
		end
	end


	local excessAmmo1 = math.max(0, wpn:Clip1() - wpn:GetMaxClip1())
	local excessAmmo2 = math.max(0, wpn:Clip2() - wpn:GetMaxClip2())

	wpn:SetClip1(math.min(wpn:Clip1(), wpn:GetMaxClip1()))
	wpn:SetClip2(math.min(wpn:Clip2(), wpn:GetMaxClip2()))
	ply:PickupWeapon(wpn, count > 0)



	self:PickupAmmo(ply, wpn:GetPrimaryAmmoType(), excessAmmo1, cvar_drop_excess_ammo:GetBool())
	self:PickupAmmo(ply, wpn:GetSecondaryAmmoType(), excessAmmo2, cvar_drop_excess_ammo:GetBool())


	return true
end

---Generic pickup for ents
---@param ply table
---@param ent table
---@param doUse boolean
function CaseInventory:PickupEntity(ply, ent, doUse)
	if not IsValid(ply) or not IsValid(ent) then
		return false
	end


	if ent.MarkedForPickup ~= nil and ent.MarkedForPickup > 0 then
		ent.MarkedForPickup = ent.MarkedForPickup - 1
		return
	end

	local itemID = CaseInventory:GetItemID(ent:GetClass())
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	if itemID == -1 or itemInfo == nil then
		return false
	end


	-- It's an ammo type, also just absorb it
	if itemInfo.ItemType == CASE_ITEM_GLOW_ONLY or itemInfo.ItemType == CASE_ITEM_DO_NOT_HANDLE then
		ply.CasePickup = ent
		ent:Use(ply, ply)
		ent.MarkedForPickup = MARKED_FOR_PICKUP_DELAY
		return
	end

	-- An actual item
	if itemInfo.ItemType == CASE_ITEM_GENERIC then
		local use = false

		if not doUse then
			use = false
		else
			use = CaseInventory:CanUse(ply, itemID)
		end

		if use then
			if itemInfo.OnUse ~= nil then
				ply.CasePickup = ent
				ent:SetPos(ply:GetPos())
			end
			ent:Use(ply, ply)
		else
			if CaseInventory:PickupItem(ply, itemID, 1) then
				ent:Remove()
				ent.MarkedForPickup = MARKED_FOR_PICKUP_DELAY

				net.Start("CaseNetMsg")
				net.WriteUInt(CASE_EVENT_ON_PICKUP, 8)
					net.WriteUInt(itemID, 16)
				net.Send(ply)
			end

		end
		return
	end

	-- Weapons are the easiest to deal with
	if ent:IsWeapon() then
		-- If we already have the weapon
		if CaseInventory:PickupWeapon(ply, ent) then
			ent.MarkedForPickup = MARKED_FOR_PICKUP_DELAY

			net.Start("CaseNetMsg")
			net.WriteUInt(CASE_EVENT_ON_PICKUP, 8)
				net.WriteUInt(itemID, 16)
			net.Send(ply)
		end
		return
	end

end

---TODO
---@param ply table
---@param itmId integer
---@param count integer
function CaseInventory:PickupItem(ply, itmId, count)
	return CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), itmId, count)
end

---Converts source ammo into a usable item in the inventory
---@param ply table
---@param ammoID integer
---@param count integer
---@return boolean, integer
function CaseInventory:PickupAmmo(ply, ammoID, count, dropIfCantPickup)
	if dropIfCantPickup == nil then
		dropIfCantPickup = true
	end
	if ammoID == -1 then
		return false, count
	end

	local rem = count
	local res = true
	local id = self:GetItemFromAmmo(ammoID)
	local info = CaseInventory:GetItemInfo(id)

	if id == -1 then
		return false, 0
	end

	-- well uh
	if info.ItemType == CASE_ITEM_DO_NOT_HANDLE then
		return false, 0
	end

	while res and rem > 0 do
		res, rem = self:AddItemToInventory(CaseInventory:Inv(ply), id, rem, false) -- Hold off on syncing for now
	end


	-- Give an instance of the weapon if grenade :)
	-- (And we didn't have one before)
	if rem ~= count and info.ItemType == CASE_ITEM_GRENADE then
		local hasGrenade = false
		for k, v in ipairs(ply:GetWeapons()) do
			if v:GetName() == info.Name then
				hasGrenade = true
				break
			end
		end
			if not hasGrenade then
			local wpn = ents.Create(info.Name)
			wpn:Spawn()
			wpn:SetClip1(0)
			wpn:SetClip2(0)

			if not ply:PickupWeapon(wpn) then
				wpn:Remove()
			end
		end
	end

	if rem > 0 and dropIfCantPickup then
		local ent = ents.Create("ent_caseammo")
		ent:SetInfo(
			info.RenderInfo.Model, -- Use the model provided in the inventory
			info.AmmoID, -- AmmoID
			rem -- Count
		)
		ent:SetPos(ply:GetPos())
		ent:Spawn()
	end

	CaseInventory:SyncAmmo(ply)
	return true, rem
end


---Don't use this one directly :)<br>
---Tries to find a suitable spot to place an item in the inventory
---@param inv table
---@param itemId integer
---@param count integer
---@param sync boolean?
---@return boolean itemAdded, integer remainingItems Any items added?, Items remaining
function CaseInventory:AddItemToInventory(inv, itemId, count, sync)
	if CLIENT then
		return false, 0
	end
	local valid = false
	local rem = count
	local max = 0
	if sync == nil then
		sync = true
	end

	for k, v in pairs(self.ItemRegister) do
		if k == itemId then
			valid = true
		end
	end

	if not valid then
		return false, 0
	end

	max = CaseInventory:GetItemInfo(itemId).MaxCount


	-- Check to see if we already have an instance of this item
	for k, v in pairs(inv.Items) do
		if v.ItemID == itemId then
			if v.Count < max then
				local toAdd = math.min(max - v.Count, rem)
				v.Count = v.Count + toAdd
				rem = rem - toAdd

				if rem == 0 then
					break
				end
			end
		end
	end

	while rem > 0 do
		local newItem = CaseInventory:CreateItemInfo(
			itemId, math.min(max, rem), false, 1, 1
		)
		local newItemId = self:FindFreeId(inv)

		newItem.Name = CaseInventory:GetItemInfo(itemId).Name

		local placedItem, x, y, rotated = CaseInventory:FindValidSpot(inv, itemId)


		if not placedItem then
			return false, rem
		end

		newItem.X = x
		newItem.Y = y
		newItem.Rotated = rotated

		inv.Items[newItemId] = newItem
		rem = rem - newItem.Count

		-- Update every time :)
		CaseInventory:RefreshLoadout(inv)
	end

	if sync and inv.Player ~= nil then
		CaseInventory:Sync(inv.Player)
	else
		CaseInventory:RefreshLoadout(inv) -- Still need to apply the loadout
	end
	return true, rem
end

---Finds a valid spot for an item (if any)
---@param inv table
---@param itemID integer
---@return boolean found, number? x, number? y, boolean? rotated
function CaseInventory:FindValidSpot(inv, itemID)
	local info = CaseInventory:GetItemInfo(itemID)
	for y=1, inv.Size[2] do
		for x=1, inv.Size[1] do
			for r=1,2 do -- Attempt both rotations per slot, first horiz then vert
				local width = 0
				local height = 0
				if r == 1 then
					width = info.Size.W
					height = info.Size.H
				else
					width = info.Size.H
					height = info.Size.W
				end
				if CaseInventory:CheckLocation(inv, x, y, width, height) then
					return true, x, y, r == 2
				end
			end
		end
	end


	return false
end

---Returns the total count of all items of a certain type
---@param inv table
---@param id integer
---@return integer
function CaseInventory:ItemCount(inv, id)
	local count = 0
	for k, v in pairs(inv.Items) do
		if v.ItemID == id then
			count = count + v.Count
		end
	end
	return count
end

---Checks to see if the player has an item
---@param inv table
---@param id integer
---@return boolean
function CaseInventory:HasItem(inv, id)
	for k, v in pairs(inv.Items) do
		if v.ItemID == id then
			return true
		end
	end
	return false
end

---comment
---@param itemId integer
function CaseInventory:ShouldHandle(itemId)

end


---Returns what would kinda just be #ply.CaseInv.Items, but that doesn't work properly :(
---@param inv table
---@return integer
function CaseInventory:ItemSize(inv)
	local count = 0
	for _, _ in pairs(inv.Items) do
		count = count + 1
	end
	return count
end


---Removes X amount of items of a certain itemId
---@param inv table
---@param id integer
---@param count integer
---@return boolean allRemoved, integer remaining Were all items removed and if not the remaining count
function CaseInventory:RemoveItem(inv, id, count)
	local rem = count
	if rem == nil then
		rem = 1
	end

	-- Take from the lowest count rather than first in the inventory
	while rem ~= 0 do
		local lowest = -1
		local curID = -1
		-- Locate the instance of the item with the lowest count
		-- Or just use the first one we get
		for k, v in pairs(inv.Items) do
			if v.ItemID == id and (lowest == -1 and true or v.Count < lowest) then
				curID = k
				lowest = v.Count
			end
		end
		-- No instances found :(
		if curID == -1 then
			break
		end

		local toTake = math.min(inv.Items[curID].Count, rem)
		inv.Items[curID].Count = inv.Items[curID].Count - toTake
		rem = rem - toTake

		if inv.Items[curID].Count == 0 then
			inv.Items[curID] = nil
		end
	end

	if SERVER and inv.Player ~= nil then
		CaseInventory:Sync(inv.Player)
	end
	return rem ~= count, rem
end

---Spawns an item based off its type
---@param ply table
---@param itemID number
---@param count number
---@return table
function CaseInventory:SpawnItemAtPlayer(ply, itemID, count)

	-- Set the pickup delay so it's not just absorbed
	ply.CasePickupDelay = ( 1 / FrameTime() ) * 1.5

	local function GetRandomOffset()
		local hMin, hMax = ply:GetHull()
		local offset =  Vector(
			math.Rand( hMin.X, hMax.X ),
			math.Rand( hMin.Y, hMax.Y ),
			0)

		return offset
	end

	return self:SpawnItemAtPos(ply:GetPos(), itemID, count, GetRandomOffset)
end

---Spawns an item based off its type
---@param pos table
---@param itemID number
---@return table
function CaseInventory:SpawnItemAtPos(pos, itemID, count, randomOffsetFunc)
	local spawnTable = {}
	local RandomOffset = randomOffsetFunc

	if randomOffsetFunc == nil then
		RandomOffset = function ()
			return Vector(0, 0, 0)
		end
	end
	local itemInfo = CaseInventory:GetItemInfo(itemID)

	if itemInfo == nil then
		return {}
	end

	local function GetEntFloorOffset(ent)
		local bounds = ent:GetModelBounds()
		if bounds == nil then
			return Vector(0, 0, 0)
		end
		return Vector(0, 0, math.abs(ent:GetModelBounds().Z * ent:GetModelScale()))
	end

	-- For generic items just spawn the entity on the floor and that should be it
	if itemInfo.ItemType == CASE_ITEM_GENERIC then
		for i = 1, count do
			local ent = ents.Create(itemInfo.Name)
			if not IsValid(ent) then
				continue
			end

			ent:SetPos(pos)
			ent:Spawn()
			ent:SetPos( pos + RandomOffset() + GetEntFloorOffset(ent))
			table.insert(spawnTable, ent)
		end
	end

	-- For weapons call player:DropWeapon
	-- If the player is dead spawn one in with the old clips
	-- We'll also ignore dropCount as you can only have one weapon at a time :)
	if itemInfo.ItemType == CASE_ITEM_WEAPON  then
		for i = 1, count do
			local wpn = ents.Create(itemInfo.Name)
			if not IsValid(wpn) then
				continue
			end

			wpn:SetPos(pos + RandomOffset())
			wpn:Spawn()
			table.insert(spawnTable, wpn)
		end
	end

	-- For ammo we create a caseammo
	if itemInfo.ItemType == CASE_ITEM_AMMO or itemInfo.ItemType == CASE_ITEM_GRENADE then
		local ent = ents.Create("ent_caseammo")
		ent:SetInfo(
			itemInfo.RenderInfo.Model, -- Use the model provided in the inventory
			itemInfo.AmmoID, -- AmmoID
			count -- Count
		)
		ent:SetPos(pos + RandomOffset())
		ent:Spawn()

		ent:SetPos(pos + RandomOffset() + GetEntFloorOffset(ent))

		table.insert(spawnTable, ent)
	end

	return spawnTable
end

---Drops a player's item on the ground
---@param inv table
---@param invId integer
---@param count integer Set to a negative number to indicate all items
---@param player table
---@param sync boolean
---@return boolean
function CaseInventory:DropItem(inv, invId, count, player, sync)
	if invId < 1 then
		return false
	end

	if count == 0 then
		return false
	end

	if player == nil then
		return false
	end

	if inv.Items[invId] == nil then
		return false
	end

	local dropCount = count ~= -1 and math.min(count, inv.Items[invId].Count) or inv.Items[invId].Count

	local itemInfo = CaseInventory:GetItemInfo(inv.Items[invId].ItemID)
	local invInfo = inv.Items[invId]

	-- Player tried to drop a weapon they don't have
	-- I've found that Zhina of all things has some """weapons""" that can cause this
	-- So it can have its own edge-case :)
	if IsValid(player) and CaseInventory:IsWeapon(invInfo.ItemID) and not player:HasWeapon(itemInfo.Name) then
		return false
	end

	if inv.Items[invId].Count - dropCount == 0 or count == -1 then
		inv.Items[invId] = nil
	else
		inv.Items[invId].Count = inv.Items[invId].Count - dropCount
	end

	if sync then
		CaseInventory:Sync(player)
	end

	CaseInventory:RefreshLoadout(CaseInventory:Inv(player))

	-- Hopefully this is about 1 1/2 seconds
	player.CasePickupDelay = ( 1 / FrameTime() ) * 1.5


	-- Drop different stuff based on item type

	local function GetRandomOffset()
		local hMin, hMax = player:GetHull()
		local offset =  Vector(
			math.Rand( hMin.X, hMax.X ),
			math.Rand( hMin.Y, hMax.Y ),
			0)

		return offset
	end

	local function GetEntFloorOffset(ent)
		local bounds = ent:GetModelBounds()
		if bounds == nil then
			return Vector(0, 0, 0)
		end
		return Vector(0, 0, math.abs(ent:GetModelBounds().Z * ent:GetModelScale()))
	end

	-- For generic items just spawn the entity on the floor and that should be it
	if itemInfo.ItemType == CASE_ITEM_GENERIC then
		for i=1, dropCount do
			local ent = ents.Create(itemInfo.Name)
			if not IsValid(ent) then
				continue
			end

			ent:SetPos(player:GetPos())
			ent:Spawn()
			ent:SetPos( player:GetPos() + GetRandomOffset() + GetEntFloorOffset(ent))
		end
	end

	-- For weapons call player:DropWeapon
	-- If the player is dead spawn one in with the old clips
	-- We'll also ignore dropCount as you can only have one weapon at a time :)
	if itemInfo.ItemType == CASE_ITEM_WEAPON  then
		local found = false
		local clip1 = 0
		local clip2 = 0
		for _, wep in ipairs( player:GetWeapons() ) do
			if wep:GetClass() == itemInfo.Name then
				player:DropWeapon( wep , player:GetPos(), Vector(0, 0, 0))
				wep:SetPos(player:GetPos() + GetRandomOffset() + GetEntFloorOffset(wep))
				wep.MarkedForPickup = 0
				found = true
				break
			end
		end



		if not found then
			local wpn = ents.Create(itemInfo.Name)
			if not IsValid(wpn) then
				return true
			end

			wpn:SetPos(player:GetPos())
			wpn:Spawn()

			wpn:SetClip1(clip1)
			wpn:SetClip2(clip2)
		end

	end

	-- For ammo we create a caseammo
	if itemInfo.ItemType == CASE_ITEM_AMMO or itemInfo.ItemType == CASE_ITEM_GRENADE then
		local ent = ents.Create("ent_caseammo")
		ent:SetInfo(
			itemInfo.RenderInfo.Model, -- Use the model provided in the inventory
			itemInfo.AmmoID, -- AmmoID
			dropCount-- Count
		)
		ent:SetOwner(player) -- Probably useful for limiting ammo drops or something
		ent:SetPos(player:GetPos())
		ent:Spawn()

		ent:SetPos(player:GetPos() + GetRandomOffset() + GetEntFloorOffset(ent))
		self:SyncAmmo(player, sync)

		if itemInfo.ItemType == CASE_ITEM_GRENADE and not CaseInventory:HasItem(inv, itemInfo.ItemID) then
		   player:StripWeapon(itemInfo.Name)
		end
	end
	return true
end

---Uses an item from a player's inventory
---@param ply table
---@param invId integer
---@param sync boolean?
---@param runCanUse boolean?
---@param runHook boolean?
---@return boolean used, integer amountUsed
function CaseInventory:UseItem(ply, invId, sync, runCanUse, runHook)

	if sync == nil then
		sync = SERVER
	end

	if runHook == nil then
		runHook = true
	end

	if runCanUse == nil then
		runCanUse = true
	end

	if CaseInventory:Inv(ply).Items[invId] == nil then
		return false, 0
	end

	local item = CaseInventory:GetItemInfo(CaseInventory:Inv(ply).Items[invId].ItemID)

	if item == nil then
		return false, 0
	end

	if item.OnUse == nil then
		return false, 0
	end

	if runCanUse and not CaseInventory:CanUse(ply, item.ItemID) then
		return false, 0
	end

	local used, amount

	if runHook then
		used, amount = hook.Run(
			"CaseOnUse",
			ply, item.ItemID, invId
		)
	end

	if used == nil then
		used, amount = item.OnUse(ply, item.ItemID, invId)
	end

	if not used then
		return false, 0
	end

	if amount == nil then
		amount = 1
	end

	amount = math.max(1, amount)

	if SERVER then
		CaseInventory:Inv(ply).Items[invId].Count = CaseInventory:Inv(ply).Items[invId].Count - amount
		if CaseInventory:Inv(ply).Items[invId].Count <= 0 then
			CaseInventory:Inv(ply).Items[invId] = nil
		end

		if sync then
			CaseInventory:Sync(ply)
		end
		local caseCount = CaseInventory:Inv(ply).Items[invId] ~= nil and CaseInventory:Inv(ply).Items[invId].Count or 1
		return true, math.min(amount, caseCount)
	end

	return true, amount
end

---Convenience function
---Skips hook and canUse
---@param ply table
---@param invId integer
---@param sync boolean?
function CaseInventory:ForceUseItem(ply, invId, sync)
	return CaseInventory:UseItem(ply, invId, sync, false, false)
end

---Returns the itemID based off name
---@param name string
---@return integer -1 On not found
function CaseInventory:GetItemID(name)
	for k, v in pairs(self.ItemRegister) do
		if v.Name == name then
			return k
		end
	end
	return -1
end

---Returns item info from either the register or the override register
---@param id number
---@return table?
function CaseInventory:GetItemInfo(id)

	if CaseInventory.ItemRegister[id] == nil then
		return nil
	end

	if CaseInventory.RegisterOverrides[id] ~= nil then
		local reg = CaseInventory.RegisterOverrides[id]

		-- Apply this stuff now
		if reg.NeedsUpdating ~= nil and reg.NeedsUpdating then
			reg.NeedsUpdating = false
			reg = table.Copy(reg) -- Make a copy rq

			CaseInventory:SetOverride(id, reg)
		end

		if CaseInventory.RegisterOverrides[id].ItemID == nil then
			CaseInventory.RegisterOverrides[id].ItemID = id
		end

		return CaseInventory.RegisterOverrides[id]
	end

	-- Just as a super bonus ;)
	if CaseInventory.ItemRegister[id].ItemID == nil then
		CaseInventory.ItemRegister[id].ItemID = id
	end


	return CaseInventory.ItemRegister[id]
end

---Just incase
---@return table?
function CaseInventory:GetRecipe(id)
	return CaseInventory.CraftingRecipes[id]
end

---Generates the recipe table
---@param displayName string?
---@param resultID number?
---@param count number?
---@param input table?
---@param isCustom boolean?
---@param disabled boolean?
function CaseInventory:Recipe(displayName, resultID, count, input, isCustom, disabled)
	local recipe = {
		Result = resultID ~= nil and resultID or 1,
		Count = count ~= nil and count or 1,
		Input = input ~= nil and input or {},
		IsCustom = isCustom ~= nil and isCustom or false,
		DisplayName = displayName ~= nil and displayName or "",
		Disabled = disabled ~= nil and disabled or false
	}

	return recipe
end

---Loads data from data/caseoverrides.txt
function CaseInventory:LoadOverrides()
	if CLIENT then
		return
	end

	-- Can't load what isn't real
	if not file.Exists("caseinv/overrides.json", "DATA") then
		return
	end

	local overrides = util.JSONToTable(file.Read("caseinv/overrides.json", "DATA"))
	local updatedAmmo = false

	for k, v in pairs(overrides) do
		local itemName = k
		local isOldAmmoName = string.sub(k, 0, 10) == "case_ammo_"
		if isOldAmmoName then
			local ammoID = tonumber(string.sub(k, 11))
			if ammoID ~= nil then
				local ammoName = game.GetAmmoName(ammoID)
				if ammoName ~= nil then
					local newItemName = "ammo_" .. ammoName

					-- The register alreay exists....?
					if CaseInventory.RegisterOverrides[newItemName] ~= nil then
						continue
					end
					itemName = newItemName
					print(string.format("RE4Case: Converted override for ammo %s -> %s", k, itemName))
					updatedAmmo = true
				end
			end
		end

		local itemID = CaseInventory:GetItemID(itemName)
		if itemID == -1 then
			CaseInventory.GhostOverrides[k] = v
		else

			CaseInventory:SetOverride(
				itemID,
				{
					Size=v.Size,
					Blacklist=v.Blacklist,
					MaxCount=v.MaxCount,
					RenderInfo=CaseRenderInfo(v.Model, v.Scale, v.Rotations, v.Offset, v.Skin, v.UseSprite)
				}
			)

			-- Send it out just for singleplayer
			CaseInventory:SendOverride(itemID)
		end
	end

	if updatedAmmo then
		CaseInventory:SaveOverrides()
	end
end

function CaseInventory:SaveOverrides()
	local saveTable = {}

	for k, v in pairs(CaseInventory.RegisterOverrides) do
		saveTable[v.Name] = {}
		saveTable[v.Name].Size = {v.Size.W, v.Size.H}
		saveTable[v.Name].Model = v.RenderInfo.Model
		saveTable[v.Name].Rotations = v.RenderInfo.Rotations
		saveTable[v.Name].Scale = v.RenderInfo.Scale
		saveTable[v.Name].Offset = {}
		saveTable[v.Name].Offset[1] = v.RenderInfo.Offset.X
		saveTable[v.Name].Offset[2] = v.RenderInfo.Offset.Y
		saveTable[v.Name].Offset[3] = v.RenderInfo.Offset.Z
		saveTable[v.Name].Blacklist = v.ItemType == CASE_ITEM_DO_NOT_HANDLE
		saveTable[v.Name].MaxCount = v.MaxCount
		saveTable[v.Name].Skin = v.RenderInfo.Skin
		saveTable[v.Name].UseSprite = v.RenderInfo.UseSprite
	end

	-- Also save the stuff that isn't actually used
	for k, v in pairs(CaseInventory.GhostOverrides) do
		saveTable[k] = v
	end

	file.Write("caseinv/overrides.json", util.TableToJSON(saveTable))
end

---Syncs an override to a client
---@param itemID any
function CaseInventory:SendOverride(itemID, ply)
	if not SERVER then
		return
	end

	local function DefaultVar(var, default)
		if var == nil then
			return default
		end
		return var
	end

	net.Start("CaseNetMsg")
	net.WriteUInt(CASE_EVENT_SYNC_OVERRIDE, 8)
		net.WriteUInt(itemID, 16)

		local info = CaseInventory.RegisterOverrides[itemID]

		net.WriteBool(info == nil) -- Delete?

		if info ~= nil then
			net.WriteString(DefaultVar(info.RenderInfo.Model, ""))

			-- Write size
			net.WriteInt(DefaultVar(info.Size.W, 1), 16)
			net.WriteInt(DefaultVar(info.Size.H, 1), 16)

			-- Write scale
			net.WriteDouble(DefaultVar(info.RenderInfo.Scale, 1))

			-- Write offset
			net.WriteDouble(DefaultVar(info.RenderInfo.Offset.X, 0))
			net.WriteDouble(DefaultVar(info.RenderInfo.Offset.Y, 0))
			net.WriteDouble(DefaultVar(info.RenderInfo.Offset.Z, 0))

			-- Write rotation
			net.WriteDouble(DefaultVar(info.RenderInfo.Rotations[1], 0))
			net.WriteDouble(DefaultVar(info.RenderInfo.Rotations[2], 0))
			net.WriteDouble(DefaultVar(info.RenderInfo.Rotations[3], 0))

			-- Write max count
			net.WriteUInt(DefaultVar(info.MaxCount, 1), 16)

			-- Write blacklist
			net.WriteBool(info.ItemType == CASE_ITEM_DO_NOT_HANDLE)

			-- Write Skin
			net.WriteUInt(DefaultVar(info.RenderInfo.Skin, 0), 8)

			-- Write sprite
			net.WriteBool(DefaultVar(info.RenderInfo.UseSprite, false))
		end


	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end

---comment
---@param itemID number
---@param info table?
function CaseInventory:SetOverride(itemID, info)

	if info == nil then
		CaseInventory.RegisterOverrides[itemID] = nil
		return
	end

	local function GetDefault(val, default)
		if val == nil then return default end
		return val
	end

	if CaseInventory.ItemRegister[itemID] == nil then
		CaseInventory.RegisterOverrides[itemID] = {}
		CaseInventory.RegisterOverrides[itemID].Size = {}
		CaseInventory.RegisterOverrides[itemID].RenderInfo = {}
		CaseInventory.RegisterOverrides[itemID].NeedsUpdating = true -- Store it away for later :(
		CaseInventory.RegisterOverrides[itemID].Blacklist = info.Blacklist
	else
		CaseInventory.RegisterOverrides[itemID] = table.Copy(CaseInventory.ItemRegister[itemID])
	end

	-- Copy over the actual registry real quick


	-- Override the size
	if info.Size.W == nil then
		CaseInventory.RegisterOverrides[itemID].Size.W = GetDefault(info.Size[1], 1)
		CaseInventory.RegisterOverrides[itemID].Size.H = GetDefault(info.Size[2], 1)
	else
		CaseInventory.RegisterOverrides[itemID].Size = info.Size
	end

	-- Render info
	CaseInventory.RegisterOverrides[itemID].RenderInfo = info.RenderInfo

	-- MaxCount
	CaseInventory.RegisterOverrides[itemID].MaxCount = math.max(GetDefault(info.MaxCount, 1), 1) -- No less than 1

	-- Just kinda make sure this is valid
	CaseInventory.RegisterOverrides[itemID].ItemID = itemID

	-- Blacklist
	if (info.Blacklist) or (info.ItemType == CASE_ITEM_DO_NOT_HANDLE) then
		CaseInventory.RegisterOverrides[itemID].ItemType = CASE_ITEM_DO_NOT_HANDLE
	end
end

---Uploads an override to the server
---@param itemID number
---@param model string
---@param size table
---@param offset table
---@param rotation table
function CaseInventory:SubmitOverride(itemID, model, size, offset, rotation)
	if SERVER then
		return
	end
end

---Creates an item info table :)
---@param itemId integer
---@param count integer
---@param rotated boolean
---@param x integer
---@param y integer
---@return table
function CaseInventory:CreateItemInfo(itemId, count, rotated, x, y)
	return {
		ItemID=itemId,
		Count=count,
		Rotated=rotated,
		X=x,
		Y=y
	}
end

---Is this item supposed to be stored?
---@param itemID number
---@return boolean
function CaseInventory:IsStorable(itemID)
	local info = CaseInventory:GetItemInfo(itemID)
	if info == nil then
		return false
	end

	if info.Type == CASE_ITEM_DO_NOT_HANDLE or info.Type == CASE_ITEM_GLOW_ONLY then
		return false
	end

	return true
end

---Fetches and itemID based off source ammoID
---@param ammoID integer
---@return integer -1 On not found
function CaseInventory:GetItemFromAmmo(ammoID)
	for k, v in pairs(self.ItemRegister) do
		if v.AmmoID == ammoID then
			return k
		end
	end
	return -1
end

-- See sh_items.lua on how to make the info table
---@param info table
---@return boolean
function CaseInventory:RegisterItem(info)
	if info == nil then
		return false
	end
	local exists = false
	for k, v in pairs(self.ItemRegister) do
		if v.Name == info.Name then
			self.ItemRegister[k] = info
			info.ItemID = k
			exists = true
			break
		end
	end

	if exists then
		return true
	end

	table.insert(self.ItemRegister, info)

	return true
end

---Used to make sure the ammo in the player's inventory is the same in the case
---@param ply table
---@param sync boolean?
function CaseInventory:SyncAmmo(ply, sync)
	local ammoCount = {}
	local plyCurAmmo = ply:GetAmmo()
	if sync == nil then
		sync = true
	end
	for k, v in pairs(CaseInventory:Inv(ply).Items) do
		local info = CaseInventory:GetItemInfo(v.ItemID)

		if info.AmmoID ~= -1 then
			plyCurAmmo[info.AmmoID] = nil
			if ammoCount[info.AmmoID] == nil then
				ammoCount[info.AmmoID] = 0
			end
			ammoCount[info.AmmoID] = ammoCount[info.AmmoID] + v.Count
		end
	end

	for k, v in pairs(ammoCount) do
		ply:SetAmmo(v, k)
	end

	for k, v in pairs(plyCurAmmo) do -- Strip any ammo not in the inventory
		ply:SetAmmo(0, k)
	end

	if SERVER and sync then
		CaseInventory:Sync(ply)
	end
end

---Place items in the loadout array (or attempt to at least)
---Seperate to the player for reasons:tm:
---@param inv table
---@param invId integer
---@param info table
---@return boolean itemPlaced Could the item be placed in the inventory?
function CaseInventory:PlaceItem(inv, invId, info)
	local itemInfo = CaseInventory:GetItemInfo(info.ItemID)


	if itemInfo == nil then
		return false
	end
	local w = itemInfo.Size.W
	local h = itemInfo.Size.H

	if info.Rotated then
		local _w, _h = w, h
		w = _h
		h = _w
	end


	if not self:CheckLocation(inv, info.X, info.Y, w, h) then
		return false
	end

	for x = info.X, info.X + w-1 do
		for y = info.Y, info.Y + h-1 do
			inv.Loadout[x][y] = invId
		end
	end

	return true
end

---Helper function for checking overlaps
---@param x1 integer
---@param y1 integer
---@param w1 integer
---@param h1 integer
---@param x2 integer
---@param y2 integer
---@param w2 integer
---@param h2 integer
---@return boolean
function CaseInventory:Overlap(x1, y1, w1, h1, x2, y2, w2, h2)
	return 	x1 < x2 + w2 and
			x1 + w1 > x2 and
			y1 < y2 + h2 and
			y1 + h1 > y2
end

---Checks to see if any rotations are valid for moving into a spot
---@param inv table
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param reqRotation boolean
---@param filter table
---@return integer -1 -> Invalid, 0 -> Valid, No rotation, 1 -> Valid, Rotated
function CaseInventory:RotationCheck(inv, x, y, w, h, reqRotation, filter)

	local noRot = self:CheckLocation(inv, x, y, w, h, filter)
	local rot = self:CheckLocation(inv, x, y, h, w, filter)

	if not rot and not noRot then
		return -1
	end

	if rot and reqRotation then
		return 1
	end

	if noRot and not reqRotation then
		return 0
	end

	-- Default to no rotation
	return noRot and 0 or 1
end

function CaseInventory:SwapLogic(srcInv, srcId, tgtInv, tgtId, dstX, dstY, srcRot, checkOnly)
	local srcItem = srcInv.Items[srcId]
	local srcInfo = CaseInventory:GetItemInfo(srcItem.ItemID)

	local tgtItem = tgtInv.Items[tgtId]
	local tgtInfo = CaseInventory:GetItemInfo(tgtItem.ItemID)

	local srcW, srcH = srcInfo.Size.W, srcInfo.Size.H

	if srcRot then
		srcW = srcInfo.Size.H
		srcH = srcInfo.Size.W
	end

	local validSrc = self:CheckLocation(
		tgtInv, dstX, dstY, srcW, srcH, {
			0,
			tgtId,
			srcInv == tgtInv and srcId or nil
		}
	)

	local validTgt = self:RotationCheck(srcInv,
		srcItem.X,
		srcItem.Y,
		tgtInfo.Size.W,
		tgtInfo.Size.H,
		tgtItem.Rotated,
		{	0,
			srcId,
			srcInv == tgtInv and tgtId or nil
		})

	if not validSrc or validTgt == -1 then
		return false
	end

	local tgtW, tgtH = tgtInfo.Size.W, tgtInfo.Size.H
	if validTgt == 1 then
		tgtW = tgtInfo.Size.H
		tgtH = tgtInfo.Size.W
	end

	-- I'm gonna ask you to back that up with a source
	local overlapResult = self:Overlap(
		dstX,
		dstY,
		srcW,
		srcH,
		srcItem.X,
		srcItem.Y,
		tgtW,
		tgtH
	)

	if overlapResult then
		return false
	elseif not checkOnly then
		local newSrcId = 0
		local newTgtId = 0

		if tgtInv.Items[srcId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newSrcId = srcId
		else
			newSrcId = CaseInventory:FindFreeId(tgtInv)
		end

		if srcInv.Items[tgtId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newTgtId = tgtId
		else
			newTgtId = CaseInventory:FindFreeId(tgtInv)
		end

		local newTgtRotation = false

		if validTgt == 1 then
			newTgtRotation = true
		end

		local newSrcItem = CaseInventory:CreateItemInfo(
			srcItem.ItemID,
			srcItem.Count,
			srcRot,
			dstX,
			dstY
		)

		local newTgtItem = CaseInventory:CreateItemInfo(
			tgtItem.ItemID,
			tgtItem.Count,
			newTgtRotation,
			srcItem.X,
			srcItem.Y
		)

		tgtInv.Items[tgtId] = nil
		srcInv.Items[srcId] = nil

		tgtInv.Items[newSrcId] = newSrcItem
		srcInv.Items[newTgtId] = newTgtItem

		CaseInventory:RefreshLoadout(srcInv)
		CaseInventory:RefreshLoadout(tgtInv)
	end

	return true
end

---Just try to force it (Internal)
---@param srcInv table
---@param srcId integer
---@param tgtInv table
---@param tgtId integer
---@param checkOnly boolean
---@param rotationInvert? integer
function CaseInventory:SwapDirect(srcInv, srcId, tgtInv, tgtId, checkOnly, rotationInvert)
	if rotationInvert == nil then
		rotationInvert = 0
	end

	local srcItem = srcInv.Items[srcId]
	local srcInfo = CaseInventory:GetItemInfo(srcItem.ItemID)

	local tgtItem = tgtInv.Items[tgtId]
	local tgtInfo = CaseInventory:GetItemInfo(tgtItem.ItemID)

	local srcRot = srcItem.Rotated
	local tgtRot = tgtItem.Rotated

	if bit.band(rotationInvert, 0x1) ~= 0 then
		srcRot = not srcRot
	end

	if bit.band(rotationInvert, 0x2) ~= 0 then
		tgtRot = not tgtRot
	end


	local validSrc = self:RotationCheck(tgtInv,
		tgtItem.X,
		tgtItem.Y,
		srcInfo.Size.W,
		srcInfo.Size.H,
		srcRot,
		{	0,
			tgtId,
			srcInv == tgtInv and srcId or nil
		})

	local validTgt = self:RotationCheck(srcInv,
		srcItem.X,
		srcItem.Y,
		tgtInfo.Size.W,
		tgtInfo.Size.H,
		tgtRot,
		{	0,
			srcId,
			srcInv == tgtInv and tgtId or nil
		})

	if validSrc == -1 or validTgt == -1 then
		return false
	end

	-- Flip the items around if needed
	local srcW, srcH = srcInfo.Size.W, srcInfo.Size.H
	if validSrc == 1 then
		srcW = srcInfo.Size.H
		srcH = srcInfo.Size.W
	end

	local tgtW, tgtH = tgtInfo.Size.W, tgtInfo.Size.H
	if validTgt == 1 then
		tgtW = tgtInfo.Size.H
		tgtH = tgtInfo.Size.W
	end

	-- I'm gonna ask you to back that up with a source
	local overlapResult = self:Overlap(
		tgtItem.X,
		tgtItem.Y,
		srcW,
		srcH,
		srcItem.X,
		srcItem.Y,
		tgtW,
		tgtH
	)

	if overlapResult then
		-- That was everything i had, time to give up
		if rotationInvert == 4 then
			return false
		else
			return self:SwapDirect(srcInv, srcId, tgtInv, tgtId, checkOnly, rotationInvert + 1)
		end
	end

	-- Do the thing, Shadow.
	if not checkOnly then
		local newSrcId = 0
		local newTgtId = 0

		if tgtInv.Items[srcId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newSrcId = srcId
		else
			newSrcId = CaseInventory:FindFreeId(tgtInv)
		end

		if srcInv.Items[tgtId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newTgtId = tgtId
		else
			newTgtId = CaseInventory:FindFreeId(tgtInv)
		end

		local newSrcRotation = false
		local newTgtRotation = false

		if validSrc == 1 then
			newSrcRotation = true
		end

		if validTgt == 1 then
			newTgtRotation = true
		end

		local newSrcItem = CaseInventory:CreateItemInfo(
			srcItem.ItemID,
			srcItem.Count,
			newSrcRotation,
			tgtItem.X,
			tgtItem.Y
		)

		local newTgtItem = CaseInventory:CreateItemInfo(
			tgtItem.ItemID,
			tgtItem.Count,
			newTgtRotation,
			srcItem.X,
			srcItem.Y
		)

		tgtInv.Items[tgtId] = nil
		srcInv.Items[srcId] = nil

		tgtInv.Items[newSrcId] = newSrcItem
		srcInv.Items[newTgtId] = newTgtItem




		CaseInventory:RefreshLoadout(srcInv)
		CaseInventory:RefreshLoadout(tgtInv)
	end
	return true
end


-- Move an item and swap it with something else if possible
---@param src table Source inventory
---@param srcId integer Source invId
---@param tgt table Target inventory
---@param tgtX integer Target X Cell
---@param tgtY integer Target Y Cell
---@param tgtRot boolean Target rotation
---@param checkOnly boolean? Don't actually move anything
---@return boolean success, boolean wasSwapped
function CaseInventory:MoveItem(src, srcId, tgt, tgtX, tgtY, tgtRot, checkOnly)

	if checkOnly == nil then
		checkOnly = false
	end

	local srcItem = src.Items[srcId]
	local srcInfo = CaseInventory:GetItemInfo(srcItem.ItemID)
	local srcW = srcInfo.Size.W
	local srcH = srcInfo.Size.H

	if tgtRot then
		local _w, _h = srcW, srcH
		srcW = _h
		srcH = _w
	end


	local foundItem = tgt.Loadout[tgtX][tgtY]
	local foundSelf = false

	if foundItem == 0 or (src == tgt and foundItem == srcId) then
		for _x = tgtX, tgtX + srcW-1 do
			for _y = tgtY, tgtY + srcH-1 do
				if _x > tgt.Size[1] or _y > tgt.Size[2] then
					continue
				end

				local item = tgt.Loadout[_x][_y]
				if item ~= 0 then
					if src == tgt and item == srcId then
						continue
					else
						foundItem = item
						break
					end

				end
			end
		end
	end

	if foundItem == 0 and foundSelf then
		foundItem = srcId
	end

	local swap =
		foundItem ~= 0 and not
		(foundItem == srcId and src == tgt)

	if CLIENT then
		if not cvar_enable_swap:GetBool() then
			swap = false
		end
	end

	-- Time to perform a swap
	if swap then
		local dstItem = tgt.Items[foundItem]
		local dstInfo = CaseInventory:GetItemInfo(dstItem.ItemID)
		local dstW = dstInfo.Size.W
		local dstH = dstInfo.Size.H

		local result = self:SwapLogic(src, srcId, tgt, foundItem, tgtX, tgtY, tgtRot, checkOnly) or
			self:SwapDirect(src, srcId, tgt, foundItem, checkOnly, 0)
		return result, true
	else -- No swap time :(
		local tgtId = 0

		-- Technically done by the found item check lol
		if not self:CheckLocation(tgt, tgtX, tgtY, srcW, srcH, {
			0,
			src == tgt and srcId or nil})
		then
			return false, false
		end

		if not checkOnly then
			if tgt.Items[srcId] == nil or tgt == src then -- Resuse the old id so it's easier on me :)
				tgtId = srcId
			else
				tgtId = CaseInventory:FindFreeId(tgt)
			end

			local newItem = CaseInventory:CreateItemInfo(
				srcItem.ItemID,
				srcItem.Count,
				tgtRot,
				tgtX,
				tgtY
			)

			src.Items[srcId] = nil
			tgt.Items[tgtId] = newItem



			CaseInventory:RefreshLoadout(src)
			CaseInventory:RefreshLoadout(tgt)
		end
		return true, false
	end

	return false, swap
end

---Combines stacks of items together
---@param srcInv table
---@param destInv table
---@param srcID integer
---@param destID integer
---@param sync boolean Will use the srcInv player for server
---@return boolean combined, number sourceRem, number destRem
function CaseInventory:MergeItem(srcInv, destInv, srcID, destID, sync)
	-- Nice
	if srcInv == destInv and srcID == destID then
		return false, 0, 0
	end
	if srcInv.Items[srcID] == nil or destInv.Items[destID] == nil then
		return false, 0, 0
	end

	-- Can only combine items of the same type
	if srcInv.Items[srcID].ItemID ~= destInv.Items[destID].ItemID then
		return false, 0, 0
	end


	local itemFrom = srcInv.Items[srcID]
	local itemTo = destInv.Items[destID]
	local itemInfo = CaseInventory:GetItemInfo(itemTo.ItemID)

	if itemTo.Count == itemInfo.MaxCount then
		return false, 0, 0
	end

	local added = math.min(itemInfo.MaxCount, itemFrom.Count + itemTo.Count) - itemTo.Count
	local srcCount = 0
	-- All of the source was added to the dest
	if added == itemFrom.Count then
		srcInv.Items[srcID] = nil
		srcCount = 0
	else
		srcInv.Items[srcID].Count = srcInv.Items[srcID].Count - added
		srcCount = srcInv.Items[srcID].Count
	end

	destInv.Items[destID].Count = destInv.Items[destID].Count + added

	CaseInventory:RefreshLoadout(srcInv)
	CaseInventory:RefreshLoadout(destInv)

	if SERVER and sync then
		CaseInventory:Sync(srcInv.Player)
	end

	if CLIENT then
		CaseInventory.ClientNet.MergeItems(srcID, destID, sync)
	end

	return true, srcCount, destInv.Items[destID].Count
end

---Checks a location in a loadout table to see if it's either empty
---or only contains another thing (could be used to check for more but lmao)
---@param inv table
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param ignore table?
---@return boolean
function CaseInventory:CheckLocation(inv, x, y, w, h, ignore)
	ignore = ignore or {0} -- Items to ignore, useful for moving stuff

	if x + (w-1) > inv.Size[1] or y + (h-1) > inv.Size[2]
		or x < 1 or y < 1 then
		return false
	end

	-- *salutes* rip performance
	for _x = x, x + (w-1) do
		for _y = y, y + (h-1) do
			local found = false
			for k, v in pairs(ignore) do
				if inv.Loadout[_x][_y] == v then
					found = true
					break
				end
			end
			if not found then
				return false
			end
		end
	end

	return true
end

function CaseInventory:FindFreeId(inv)
	local itemSize = CaseInventory:ItemSize(inv)
	local newItemId = 0
	local foundSpace = false
	-- Check to see if there are any empty ids
	for k = 1, itemSize do
		local v = inv.Items[k]
		if v == nil then
			newItemId = k
			foundSpace = true
			break
		end
	end

	-- None found, place at the end of the item list
	if not foundSpace then
		newItemId = itemSize + 1
	end

	return newItemId
end


---Fetches the inventory of a player from the CaseInventory.Inventories value
---Or returns the .ClientInventory value if called from the client
---Not like the .Inventories could be accessed from the client anyway
---@param ply table?
---@param toSet table? Use this to override the table set
---@return table
function CaseInventory:Inv(ply, toSet)

	local defSize = CaseInventory:GetDefaultCaseSize()

	-- Basic mode
	-- Inventory data is stored on the player
	-- Good for singleplayer campaigns/single level multiplayer ones
	if cvar_inventory_mode:GetInt() == 0 then
		if CLIENT then
			if toSet ~= nil then
				LocalPlayer().CaseInv = toSet
			end
			if LocalPlayer().CaseInv == nil then
				LocalPlayer().CaseInv = CaseInventory:GenerateInventory(defSize[1], defSize[2], ply)
			end
			return LocalPlayer().CaseInv
		end

		if ply == nil then
			return {}
		end

		if toSet ~= nil then
			ply.CaseInv = toSet
		end

		if ply.CaseInv == nil then
			ply.CaseInv = CaseInventory:GenerateInventory(defSize[1], defSize[2], ply)
		end

		return ply.CaseInv
	end

	-- On disk for transitions mode
	-- Inventory data is stored in the CaseInventory.Inventories table
	-- Inventory data is saved to disk on map change
	-- Inventory data is not saved over server restarts
	if cvar_inventory_mode:GetInt() == 1 then
		if CLIENT then
			if toSet ~= nil then
				CaseInventory.ClientInventory = toSet
			end

			if CaseInventory.ClientInventory == nil then
				CaseInventory.ClientInventory = CaseInventory:GenerateInventory(defSize[1], defSize[2], ply)
			end
			return CaseInventory.ClientInventory
		end

		if ply == nil then
			return {}
		end

		if toSet ~= nil then
			CaseInventory.Inventories[ply:SteamID64()] = toSet
		end

		if CaseInventory.Inventories[ply:SteamID64()] == nil then
			ply.CaseInv = CaseInventory:GenerateInventory(defSize[1], defSize[2], ply)
		end

		return CaseInventory.Inventories[ply:SteamID64()]
	end

		-- On disk for transitions mode
	-- Inventory data is stored in the CaseInventory.Inventories table
	-- Inventory data is saved to disk on map change
	-- Inventory data is not saved over server restarts
	if cvar_persist_mode:GetInt() == 1 then

	end
end

---Shorthand CaseInventory:Inv(ply)
---@param ply table?
---@param toSet table?
---@return table
function CaseInv(ply, toSet)
	return CaseInventory:Inv(ply, toSet)
end

---Gets what size the default case should be
---@return table
function CaseInventory:GetDefaultCaseSize()
	-- Check if this is just straight up a usable size
	local type = string.upper(cvar_default_case_size:GetString())

	for k, v in pairs(CASE_SIZES) do
		if type == k then
			return v
		end
	end

	local i = 1
	local size = table.Copy(CASE_INVENTORY_SIZE_DEFAULT)
	for word in string.gmatch(type, '([^ ]+)') do
		if word == "" then
			continue
		end
		local num = tonumber(word)
		if num == nil then
			continue
		end

		size[i] = math.max(num, 1)
		i = i + 1
	end

	return size
end

---Resets the loadout table for a player
---@param inv table
function CaseInventory:ClearLoadout(inv)
	inv.Loadout = {}
	for x=1, inv.Size[1] do
		inv.Loadout[x] = {}
		for y=1,inv.Size[2] do
			inv.Loadout[x][y] = 0
		end
	end
end

---Resets the loadout table for a table
---@param load table
---@param w integer
---@param h integer
function CaseInventory:ClearLoadout2(load, w, h)
	load = {}
	for x=1, w do
		load[x] = {}
		for y=1,h do
			load[x][y] = 0
		end
	end
end

---Clear and then place :)
---@param inv table
function CaseInventory:RefreshLoadout(inv)
	CaseInventory:ClearLoadout(inv)

	for k, v in pairs(inv.Items) do
		CaseInventory:PlaceItem(inv, k, v)
	end
end

---Generates an empty inventory
---@param width? integer
---@param height? integer
---@param player table?
---@return table
function CaseInventory:GenerateInventory(width, height, player)
	local inv = {
		Size={width or 10, height or 6},
		Items={},
		Loadout={},
		Player=player -- could be any entity... maybe
	}
	if player ~= nil then
		player.UseCommand = 0
		player.CasePickupDelay = 0
	end

	CaseInventory:ClearLoadout(inv)
	return inv
end


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

---Sync the player inventory over the network
---@param ply table
---@param performDrop boolean?
function CaseInventory:Sync(ply, performDrop)
	if CLIENT then
		return
	end

	if performDrop == nil then
		performDrop = false
	end

	-- If any items were removed we have to place them back :)
	self:ClearLoadout(CaseInventory:Inv(ply))

	for k, v in pairs(CaseInventory:Inv(ply).Items) do
		if not CaseInventory:PlaceItem(CaseInventory:Inv(ply), k, v) and performDrop then -- This probably means the case shrunk
			CaseInventory:DropItem(CaseInventory:Inv(ply), k, -1, ply, false)
		end
	end



	net.Start("CaseNetMsg")
	net.WriteUInt(CASE_EVENT_SYNC, 8)
		net.WriteUInt(CaseInventory:Inv(ply).Size[1], 8)   -- SizeX
		net.WriteUInt(CaseInventory:Inv(ply).Size[2], 8)   -- SizeY

		net.WriteUInt(CaseInventory:ItemSize(CaseInventory:Inv(ply)), 16) -- ItemCount
		for k, v in pairs(CaseInventory:Inv(ply).Items) do
			net.WriteUInt(k, 16)            -- Index
			net.WriteUInt(v.ItemID, 16)     -- ItemID
			net.WriteUInt(v.Count, 32)      -- Count
			net.WriteBool(v.Rotated)       -- Rotation
			net.WriteUInt(v.X, 8)   -- X
			net.WriteUInt(v.Y, 8)   -- Y
		end

	net.Send(ply)

	--PrintTable(ply.CaseInv.Items)
	--print("sent ", CaseInventory:ItemSize(ply.CaseInv), "items")
	--CaseInventory:DebugPrintLoadout(ply.CaseInv.Items)
end

---Auto generates weapon and ammo
---Probably bad and also maybe like O(n something (nothing good))
function CaseInventory:AutoGenerate()
	if SERVER and not cvar_auto_generate:GetBool() then
		return
	end

	if CLIENT then
		for k, v in pairs(CaseInventory.AutoGenerateInfo) do
			if v.Type == CASE_AUTOGEN_WEAPON then
				CaseInventory:RegisterItem(CaseWeapon(v.Name, CaseRenderInfo(v.Model), v.Size[1], v.Size[2], v.PrintName))
			end

			if v.Type == CASE_AUTOGEN_AMMO then
				CaseInventory:RegisterItem(CaseAmmo(v.AmmoID ,CaseRenderInfo(v.Model, v.Scale, v.Rotation), v.Size[1], v.Size[2], v.Count))
			end
		end
		return
	end

	-- Copying as I don't want this to have any....
	-- Unforseen consequences
	local wepList = table.Copy(weapons.GetList())
	local ammoList = game.GetAmmoTypes()

	-- We're about to push that big O to its limits fellas
	-- Find out what is already registed and remove it from the todo list
	for k, v in pairs(CaseInventory.ItemRegister) do
		if v.ItemType ~= CASE_ITEM_WEAPON and v.ItemType ~= CASE_ITEM_GRENADE and v.ItemType ~= CASE_ITEM_DO_NOT_HANDLE then
			continue
		end
		local i = 1
		while i <= #wepList do
			local v2 = wepList[i]

			if v2.ClassName == v.Name then
				table.remove(wepList, i)
			else
				i = i + 1
			end
		end
	end

	for k, v in pairs(CaseInventory.ItemRegister) do
		if v.AmmoID == -1 then
			continue
		end


		for k2, v2 in pairs(ammoList) do
			if k2 == v.AmmoID then
				if not SERVER then
					local ammoName = language.GetPhrase("#" .. v2 .. "_ammo")
				end
				ammoList[k2] = nil
			end
		end
	end

	for k, v in pairs(wepList) do
		local world = v.WorldModel or "models/weapons/w_pistol.mdl"
		CaseInventory:RegisterItem(CaseWeapon(v.ClassName, CaseRenderInfo(world), 3, 2, v.Name))
		local name = v.ClassName
		if v.PrintName ~= nil then
			name = v.PrintName
		end

		table.insert(CaseInventory.AutoGenerateInfo, {
			Type = CASE_AUTOGEN_WEAPON,
			Name = v.ClassName,
			AmmoID = -1,
			Model = world,
			Scale = 1,
			Rotation = {0, 0, 0},
			PrintName = name,
			Size = {3, 2},
			Count = 1
		})
	end

	for k, v in pairs(ammoList) do
		CaseInventory:RegisterItem(CaseAmmo(k,CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30))
		local name = ""
		if v.Name ~= nil then
			name = v.Name
		end

		table.insert(CaseInventory.AutoGenerateInfo, {
			Type = CASE_AUTOGEN_AMMO,
			Name = "",
			AmmoID = k,
			Model = "models/Items/357ammo.mdl",
			Scale = 1.3,
			Rotation = {25, 180, 0},
			PrintName = name,
			Size = {2, 1},
			Count = 30
		})
	end

	if cvar_auto_generate:GetInt() == 2 and SERVER then
		local lua = ""
		for k, v in ipairs(wepList) do
			local world = v.WorldModel or "models/weapons/w_pistol.mdl"
			print(string.format("CaseWeapon(\"%s\", CaseRenderInfo(\"%s\"), 3, 2),", v.ClassName, world))
		end

		for k, v in pairs(ammoList) do
			print(string.format("CaseAmmo(game.GetAmmoID(\"%s\"), CaseRenderInfo(\"models/Items/357ammo.mdl\", 1.3, {25, 180, 0}), 2, 1, 30),", v))
		end
	end
end

--- Sorts item register and some other minor things
function CaseInventory:FinalizeItemRegister()

	-- Apply the item IDs obtained from the server
	if CLIENT then
		local tempRegister = {}
		for newItemID, newItemName in pairs(CaseInventory.ItemRegisterLayout ) do
			local itemID = CaseInventory:GetItemID(newItemName)
			tempRegister[newItemID] = CaseInventory.ItemRegister[itemID]
		end
		CaseInventory.ItemRegister = tempRegister

		return
	end

	if SERVER then
		table.sort(CaseInventory.ItemRegister, function (a, b)
			return a.Name < b.Name
		end)
	end

	-- Give the item info a way to reference its own id
	for k, v in pairs(CaseInventory.ItemRegister) do
		v.ItemID = k
	end

	if SERVER then
		CaseInventory.CustomItemStart = table.Count(CaseInventory.ItemRegister) + 1
	end

	CaseInventory:LoadCustomItems()


	CaseInventory:LoadOverrides()

end

function CaseInventory:TryLocalize(string)
	if string == nil then
		return ""
	end

	local attempt0 = language.GetPhrase(string)
	local attempt1 = language.GetPhrase("#" .. string)

	if attempt0 ~= string then
		return attempt0
	end

	if attempt1 ~= "#" .. string then
		return attempt1
	end

	return string
end

--- Funny check to see if an item is a weapon
---@param itemID integer
---@return boolean
function CaseInventory:IsWeapon(itemID)
	local item = CaseInventory:GetItemInfo(itemID)
	if item == nil then
		return false
	end

	return item.ItemType == CASE_ITEM_WEAPON or item.ItemType == CASE_ITEM_GRENADE
end

--- Funny check to see if an item is a weapon
---@param itemID integer
---@return boolean
function CaseInventory:IsAmmo(itemID)
	local item = CaseInventory:GetItemInfo(itemID)
	if item == nil then
		return false
	end

	return item.ItemType == CASE_ITEM_AMMO
end

--- Checks if an item is a proper item that can be placed in an inventory
---@param itemID integer
---@return boolean
function CaseInventory:IsItem(itemID)
	local item = CaseInventory:GetItemInfo(itemID)
	if item == nil then
		return false
	end

	return item.ItemType ~= CASE_ITEM_GLOW_ONLY
end

---Little thingy
---@param itemID number
---@param ply table
---@param runHook boolean?
function CaseInventory:CanUse(ply, itemID, runHook)
	if not IsValid(ply) then
		return false
	end

	if runHook == nil then
		runHook = true
	end

	local itemInfo = CaseInventory:GetItemInfo(itemID)
	if itemInfo == nil then
		return false
	end

	if itemInfo.ItemType ~= CASE_ITEM_GENERIC then
		return false
	end

	if itemInfo.OnUse == nil then
		return false
	end

	if itemInfo.CanUse == nil then
		return true
	end

	local canUse

	if runHook then
		canUse = hook.Run("CaseCanUse", ply, itemID)
	end

	-- Looks stupid but means it has to be a boolean so i mean ;)
	if canUse == true or canUse == false then
		return canUse
	end


	return itemInfo.CanUse(ply, itemID)
end

---Checks to see if an item has a tag
---@param itemID any
---@param tag any
function CaseInventory:HasTag(itemID, tag)
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	if itemInfo == nil then
		return false
	end

	for k, v in ipairs(itemInfo.Tags) do
		if v == tag then
			return true
		end
	end

	return false
end

---Is this item cool and custom?
---@param itemID number
---@return boolean
function CaseInventory:IsCustom(itemID)
	if CaseInventory:GetItemInfo(itemID) == nil then
		return false
	end

	return CaseInventory:HasTag(itemID, "custom")
end

---Creates a custom item
---@param name string
---@param printName string
---@param model string
---@return boolean
function CaseInventory:CreateCustomItem(name, printName, model)
	local itemID = CaseInventory:GetItemID(name)

	-- Item actually does exist!
	if itemID ~= -1 then
		return false
	end

	local item = CaseInventory:GenerateCustomItemInfo(name, printName, model, 1)
	item.ItemID = itemID

	itemID = CaseInventory.CustomItemStart

	-- Find the first free spot
	while CaseInventory.ItemRegister[itemID] ~= nil do
		itemID = itemID + 1
	end

	CaseInventory.ItemRegister[itemID] = item

	CaseInventory.CustomItems[itemID] = {
		Class = name,
		PrintName = printName,
		Type = CASE_CUSTOM_GENERIC,
		CanUse = CASE_CUSTOM_USE_ALWAYS,
		Model = model
	}

	-- Broadcast this new creation
	if SERVER then
		itemID = CaseInventory:GetItemID(name)
		table.insert(CaseInventory.CustomItemOrder, itemID)

		CaseInventory:SyncCustomItem(itemID)
		CaseInventory:SaveCustomItems()

		-- Also take a look at the ghost overides
		CaseInventory:GhostRecipesAdded(name)
	end

	return true
end

---Applies a custom item from a silly table
---Basically just for loading
---@param custom table
---@return number itemID
function CaseInventory:SetupCustomItem(custom)

	-- Generate item info based of what we have
	local itemInfo = CaseInventory:GenerateCustomItemInfo(
		custom.Class,
		custom.PrintName,
		custom.Model,
		custom.Type
	)

	if itemInfo == nil then
		return -1
	end

	CaseInventory:UpdateCustomTags(itemInfo, custom.Type, custom.CanUse)


	local itemID = CaseInventory.CustomItemStart

	-- Find the first free spot
	while CaseInventory.ItemRegister[itemID] ~= nil do
		itemID = itemID + 1
	end


	CaseInventory.ItemRegister[itemID] = itemInfo
	CaseInventory.ItemRegister[itemID].ItemID = itemID

	CaseInventory.CustomItems[itemID] = custom

	if SERVER then
		CaseInventory:SyncCustomItem(itemID)
	end

	return itemID
end

---Updates a custom item
---@param name string
---@param printName string
---@param itemType number
---@param canUseCondition number
function CaseInventory:UpdateCustomItem(name, printName, itemType, canUseCondition)
	local itemID = CaseInventory:GetItemID(name)

	-- Item isn't real!
	if itemID == -1 then
		return false
	end

	-- hold up...
	if not CaseInventory:IsCustom(itemID) then
		CaseInventory.Panel:HelpText("https://tenor.com/bW5F1.gif")
		return
	end

	local item = CaseInventory:GenerateCustomItemInfo(name, printName, CaseInventory.ItemRegister[itemID].RenderInfo.Model, itemType)
	if item == nil then
		return
	end

	if itemType == CASE_CUSTOM_GLOW_ONLY then
		for _, ply in ipairs(player.GetAll()) do
			for invID, invInfo in pairs(CaseInv(ply).Items) do
				if invInfo.ItemID == itemID then
					CaseInventory:DropItem(CaseInv(ply), invID, invInfo.Count, ply, true)
				end
			end
		end
	end

	item.ItemID = itemID
	CaseInventory:UpdateCustomTags(item, itemType, canUseCondition)


	CaseInventory.ItemRegister[itemID] = item

	CaseInventory.CustomItems[itemID] = {
		Class = name,
		PrintName = printName,
		Type = itemType,
		CanUse = canUseCondition,
		Model = CaseInventory.CustomItems[itemID].Model
	}


	-- We also have to update some of the override info if that exists
	if CaseInventory.RegisterOverrides[itemID] ~= nil then
		local override = CaseInventory.RegisterOverrides[itemID]
		override.PrintName = printName
		override.CanUse = item.CanUse
		override.OnUse = item.OnUse
	end

	-- Broadcast this new creation
	if SERVER then
		itemID = CaseInventory:GetItemID(name)
		CaseInventory:SyncCustomItem(itemID)
		CaseInventory:SaveCustomItems()
	end
end

---Updates tags for a custom item :)
---@param item table
---@param itemType number
---@param canUseCondition number
function CaseInventory:UpdateCustomTags(item, itemType, canUseCondition)

	if itemType == CASE_CUSTOM_GENERIC or itemType == CASE_CUSTOM_GLOW_ONLY then
		item.Tags = {CASE_TAG_CUSTOM}
	elseif itemType == CASE_CUSTOM_CONSUMABLE then
		item.Tags = {
			CASE_TAG_CUSTOM,
			CASE_TAG_CONSUMABLE
		}

		if canUseCondition == CASE_CUSTOM_USE_HEALTH then
			table.insert(item.Tags, CASE_TAG_HEALTH)
		elseif canUseCondition == CASE_CUSTOM_USE_ARMOR then
			table.insert(item.Tags, CASE_TAG_ARMOR)
		end
	end
end

---Banishes a custom item from existance
function CaseInventory:RemoveCustomItem(name)
	local itemID = CaseInventory:GetItemID(name)

	if itemID == -1 then
		return false
	end

	-- Maybe don't do that
	if not CaseInventory:IsCustom(itemID) then
		return
	end

	-- Make sure everyone drops the item
	for _, ply in ipairs(player.GetAll()) do
		for invID, invInfo in pairs(CaseInv(ply).Items) do
			if invInfo.ItemID == itemID then
				CaseInventory:DropItem(CaseInv(ply), invID, invInfo.Count, ply, true)
			end
		end
	end

	for i=1, table.Count(CaseInventory.CustomItemOrder) do
		if CaseInventory.CustomItemOrder[i] == itemID then
			table.remove(CaseInventory.CustomItemOrder, i)
			break
		end
	end

	-- See if there are any recipes we need to shift around
	CaseInventory:GhostRecipesRemoved(itemID)

	-- Now that's done, yeet it from the register
	CaseInventory.ItemRegister[itemID] = nil
	CaseInventory.RegisterOverrides[itemID] = nil

	CaseInventory:SyncCustomItem(itemID)
	CaseInventory:SaveCustomItems()


end

---Return a CaseX based on type for custom items
---@param name string
---@param printName string
---@param model string
---@param type number
function CaseInventory:GenerateCustomItemInfo(name, printName, model, type)
	if type == CASE_CUSTOM_GENERIC then
		return CaseGeneric(
			name,
			printName,
			CaseRenderInfo(model),
			1, 1, 1, {CASE_TAG_CUSTOM}
		)
	elseif type == CASE_CUSTOM_CONSUMABLE then
		return CaseConsumable(
			name,
			printName,
			CaseRenderInfo(model),
			1, 1, 1,
			CaseCustomItemUse,
			CaseCustomItemCanUse,
			{CASE_TAG_CUSTOM}
		)
	elseif type == CASE_CUSTOM_GLOW_ONLY then
		local item = CaseGlowOnly(name)
		item.PrintName = printName -- Apply this just for neatness
		return item
	end

	return nil
end

function CaseInventory:SyncCustomItem(itemID, ply)
	local info = CaseInventory.ItemRegister[itemID]


		--[[
			uint16 itemID
			bool delete?
			string name
			string printName
			string model
			uint8 type
			uint8 canUseCondition
		]]
	net.Start("CaseNetMsg")
	net.WriteUInt(CASE_EVENT_SYNC_CUSTOM_ITEMS, 8)
		net.WriteBool(false) -- This is not a stupid workaround
		if info == nil then
			net.WriteUInt(itemID, 16)
			net.WriteBool(true) -- Bye bye :(
		else
			net.WriteUInt(itemID, 16)
			net.WriteBool(false) -- Don't delete
			net.WriteString(info.Name)
			net.WriteString(info.PrintName)
			net.WriteString(info.RenderInfo ~= nil and info.RenderInfo.Model or "")
			net.WriteUInt(CaseInventory.CustomItems[itemID].Type, 8)
			net.WriteUInt(CaseInventory.CustomItems[itemID].CanUse, 8)
		end
	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end


function CaseInventory:SaveCustomItems()
	if CLIENT then
		return
	end
	local saveTable = {}

	-- Force everything to be in order
	for k, v in ipairs(CaseInventory.CustomItemOrder) do
		table.insert(saveTable,CaseInventory.CustomItems[v])
	end

	file.Write("caseinv/customitems.json", util.TableToJSON(saveTable))
end

function CaseInventory:LoadCustomItems()
	if CLIENT then
		return
	end

	-- Can't load what isn't real
	if not file.Exists("caseinv/customitems.json", "DATA") then
		return
	end

	local customs = util.JSONToTable(file.Read("caseinv/customitems.json", "DATA"))
	if customs == nil then
		return
	end


	for k, custom in ipairs(customs) do
		table.insert(CaseInventory.CustomItemOrder, CaseInventory:SetupCustomItem(custom))
	end
end

---Registers a new crafting recipe :)
---@param resultName string
---@param resultCount number
---@param input table
---@param isCustom boolean?
---@return number
function CaseInventory:RegisterCraftingRecipe(displayName, resultName, resultCount, input, isCustom)
	local newID = 1

	if isCustom == nil then
		isCustom = false
	end

	-- Find the first valid spot
	while CaseInventory.CraftingRecipes[newID] ~= nil do
		newID = newID + 1
	end

	local resultID = CaseInventory:GetItemID(resultName)
	if resultID == -1 then
		return 0
	end

	local inputFinal = {}
	for k, v in pairs(input) do
		local itemID = CaseInventory:GetItemID(k)
		if itemID == -1 then
			return 0
		end

		inputFinal[itemID] = v
	end


	CaseInventory.CraftingRecipes[newID] = CaseInventory:Recipe(
		displayName,
		resultID,
		resultCount,
		inputFinal,
		isCustom,
		false
	)

	return newID
end

---Updates the quick lookup table for recipes
function CaseInventory:UpdateLookups()
	CaseInventory.CraftingLookup = {}

	for rID, recipe in pairs(CaseInventory.CraftingRecipes) do
		if recipe.Disabled or not CaseInventory:ValidateRecipe(rID) then
			continue
		end

		for itemID, _ in pairs(recipe.Input) do
			if CaseInventory.CraftingLookup[itemID] == nil then
				CaseInventory.CraftingLookup[itemID] = {}
			end

			table.insert(CaseInventory.CraftingLookup[itemID], rID)
		end
	end
end

---Syncs a recipe to a player(s) :)
---@param ply any?
---@param recipeID number
function CaseInventory:SyncRecipe(recipeID, ply)
	local recipe = CaseInventory:GetRecipe(recipeID)
	if recipe == nil then
		return
	end

	net.Start("CaseNetMsg")
		net.WriteUInt(CASE_EVENT_SYNC_RECIPE, 8)
		net.WriteUInt(recipeID, 16)
		net.WriteBool(false) -- Delete
		net.WriteBool(recipe.IsCustom)
		net.WriteBool(recipe.Disabled)
		net.WriteUInt(recipe.Result, 16)
		net.WriteString(recipe.DisplayName)
		net.WriteUInt(recipe.Count, 16)
		net.WriteUInt(table.Count(recipe.Input), 4)
		for itemID, count in pairs(recipe.Input) do
			net.WriteUInt(itemID, 16)
			net.WriteUInt(count, 16)
		end
	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end

---Deletes a recipe :(
---@param recipeID number
function CaseInventory:DeleteRecipe(recipeID)
	local recipe = CaseInventory:GetRecipe(recipeID)
	if recipe == nil then
		return
	end

	if not recipe.IsCustom then
		return
	end

	CaseInventory.CraftingRecipes[recipeID] = nil

	net.Start("CaseNetMsg")
	net.WriteUInt(CASE_EVENT_SYNC_RECIPE, 8)
		net.WriteUInt(recipeID, 16)
		net.WriteBool(true) -- Delete
	net.Broadcast()

end

---Performs a craft
---@param ply table
---@param recID number
---@return boolean
function CaseInventory:Craft(ply, recID)

	-- No? The first
	if not CaseInventory:ValidateRecipe(recID) then
		return false
	end

	local recipe = CaseInventory.CraftingRecipes[recID]
	if recipe == nil then
		return false
	end

	-- No? The second
	if recipe.Disabled then
		return false
	end

	local usedItems = CaseInventory:GetInvIDsForCraft(ply, recID)
	if usedItems == nil then
		return false
	end

	-- Use up the items
	for invID, count in pairs(usedItems) do
		local item = CaseInv(ply).Items[invID]
		if item.Count == count then
			local itemID = CaseInv(ply).Items[invID].ItemID
			local info = CaseInventory:GetItemInfo(itemID)

			if info ~= nil and CaseInventory:IsWeapon(itemID) then
				-- Ammo refund
				local wep = ply:GetWeapon(info.Name)

				if wep ~= nil then
					local _clip1 = wep.Clip1 ~= nil and wep:Clip1() or 0
					if _clip1 == nil then
						_clip1 = 0
					end

					if _clip1 > 0 then
						ply:GiveAmmo(wep:Clip1(), wep:GetPrimaryAmmoType())
					end

					local _clip2 = wep.Clip2 ~= nil and wep:Clip2() or 0
					if _clip2 == nil then
						_clip2 = 0
					end
					if _clip2 > 0 then
						ply:GiveAmmo(wep:Clip2(), wep:GetSecondaryAmmoType())
					end


					ply:StripWeapon(info.Name)
				end
			end
			-- Bye bye
			CaseInv(ply).Items[invID] = nil
		else
			item.Count = item.Count - count
		end
	end

	-- Just so we can place the item in a good spot
	CaseInventory:RefreshLoadout(CaseInv(ply))

	-- Do unique things depending on what we got as a treat

	local info = CaseInventory:GetItemInfo(recipe.Result)


	-- Is some form of ammo
	if info.AmmoID ~= -1 then
		ply:GiveAmmo(recipe.Count, info.AmmoID)

		-- A weapon perhaps?
	elseif info.ItemType == CASE_ITEM_WEAPON then
		for i = 1, recipe.Count do
			local wpn = ents.Create(info.Name)
			if not IsValid(wpn) then
				return true
			end

			wpn:SetPos(ply:GetPos())
			wpn:Spawn()
			wpn:SetClip1(0)
			wpn:SetClip2(0)
		end
	else -- Generic ass item
		local added, rem = CaseInventory:AddItemToInventory(CaseInv(ply), recipe.Result, recipe.Count, false)

		-- Plonk the rest on the floor if it can't be stored
		if rem > 0 then
			CaseInventory:SpawnItemAtPlayer(ply, recipe.Result, rem)
		end
	end

	-- Oh yeah! Your reward i guess
	--[[
	local added, rem = CaseInventory:AddItemToInventory(CaseInv(ply), recipe.Result, 1, false)

	-- Uh....
	if rem > 0 then

	end
]]

	-- Sync it all up
	CaseInventory:Sync(ply)

	return true
end

---Do some little validation on everything
---@param recID number
---@return boolean
function CaseInventory:ValidateRecipe(recID)
	local recipe = CaseInventory:GetRecipe(recID)
	if recipe == nil then
		return false
	end

	local function IsValidItem(itemID)
		local info = CaseInventory:GetItemInfo(itemID)
		if info == nil then
			return false
		end

		return info.ItemType ~= CASE_ITEM_DO_NOT_HANDLE and info.ItemType ~= CASE_ITEM_GLOW_ONLY
	end

	if not IsValidItem(recipe.Result) then
		return false
	end

	for itemID, _ in pairs(recipe.Input) do
		if not IsValidItem(itemID) then
			return false
		end
	end

	return true
end

function CaseInventory:CanCraft(ply, recipeID)
	return CaseInventory:GetInvIDsForCraft(ply, recipeID) ~= nil
end

---Builds a list of ids that would be used up if you tried to craft something
---@param ply table
---@param recipeID number
---@return table?
function CaseInventory:GetInvIDsForCraft(ply, recipeID)
	local recipe = {}
	if CaseInventory.CraftingRecipes[recipeID] == nil then
		return nil
	end

	recipe = CaseInventory.CraftingRecipes[recipeID]

	-- Count up everything required for the recipe
	local input = table.Copy(recipe.Input)


	-- Figure out what items in our inventory we're gonna use
	local usedItems = {}
	for invID, invInfo in pairs(CaseInv(ply).Items) do
		if input[invInfo.ItemID] == nil then
			continue
		end

		if input[invInfo.ItemID] ~= 0 then
			local usedCount = math.min(input[invInfo.ItemID], invInfo.Count)
			usedItems[invID] = usedCount
			input[invInfo.ItemID] = input[invInfo.ItemID] - usedCount
		end
	end

	-- Check if all items were used up
	for k, v in pairs(input) do

		-- If anything is more than 0 then boo whomp
		if v > 0 then
			return nil
		end
	end

	return usedItems
end

-- For reasons...
function CaseInventory:GenerateRecipeHash(recipe)
	-- We need to sort the keys or something
	local function _GetInputOrder(inputs)
		local keys = {}

		for k in pairs(inputs) do
			table.insert(keys, k)
		end

		table.sort(keys)

		return keys
	end

	local rString = string.format("%s_%i_%i_", recipe.DisplayName, recipe.Result, recipe.Count)
	local rem = table.Count(recipe.Input)
	local inputOrder = _GetInputOrder(recipe.Input)

	for _, itemID in ipairs(inputOrder) do
		local count = recipe.Input[itemID]

		rString = rString .. string.format("%i_%i", itemID, count)
		if rem ~= 1 then
			rString = rString .. "_"
		end

		rem = rem - 1
	end

	return util.SHA256(rString)
end

---For loading & loading from ghost recipes
---@param recipe table
---@return number
function CaseInventory:SaveToRecipe(recipe)
	if not recipe.IsCustom then
		local hash = recipe.Hash
		local disabled = recipe.Disabled -- This should really only be true but whatever
		for rID, sRecipe in pairs(CaseInventory.CraftingRecipes) do
			if sRecipe.IsCustom then
				continue
			end

			if CaseInventory:GenerateRecipeHash(sRecipe) == hash then

				sRecipe.Disabled = disabled
				return rID
			end
		end
		return 0
	end

	local id = CaseInventory:RegisterCraftingRecipe(recipe.DisplayName, recipe.Result, recipe.Count, recipe.Input, true)
	return id
end

function CaseInventory:RecipeToSave(recipe)
	local sRecipe = {}
	if not recipe.IsCustom then

		-- Only save if modified
		if recipe.Disabled then
			sRecipe.IsCustom = false
			sRecipe.Hash = CaseInventory:GenerateRecipeHash(recipe)
			sRecipe.Disabled = recipe.Disabled
			return sRecipe
		end
		return nil
	end
	sRecipe.IsCustom = true
	sRecipe.DisplayName = recipe.DisplayName
	sRecipe.Result = CaseInventory:GetItemInfo(recipe.Result).Name
	sRecipe.Count = recipe.Count
	sRecipe.Disabled = recipe.Disabled
	sRecipe.Input = {}

	for itemID, count in pairs(recipe.Input) do
		sRecipe.Input[CaseInventory:GetItemInfo(itemID).Name] = count
	end

	return sRecipe
end

function CaseInventory:LoadRecipes()
	if CLIENT then
		return
	end

	-- Can't load what isn't real
	if not file.Exists("caseinv/recipes.json", "DATA") then
		return
	end

	local recipes = util.JSONToTable(file.Read("caseinv/recipes.json", "DATA"))
	local recipeHashCache = {} -- fun name
	for _, recipe in pairs(recipes) do
		local addedID = CaseInventory:SaveToRecipe(recipe)

		-- Recipe can't actually be loaded, slap it into the ghost zone
		if addedID == 0 then
			table.insert(CaseInventory.GhostRecipes, recipe)
		end
	end

	for rID, recipe in pairs(recipes) do
		if recipe.IsCustom then
			recipe.DisplayName = CaseInventory:GetValidRecipeName(recipe.DisplayName, rID)
		end
	end
end

function CaseInventory:SaveRecipes()
	local recipeSave = {}
	for _, recipe in pairs(CaseInventory.CraftingRecipes) do
		local sRecipe = CaseInventory:RecipeToSave(recipe)
		if sRecipe ~= nil then
			table.insert(recipeSave, sRecipe)
		end
	end

	-- Make sure to save the ghost stuff!
	for _, recipe in pairs(CaseInventory.GhostRecipes) do
		table.insert(recipeSave, recipe)
	end

	file.Write("caseinv/recipes.json", util.TableToJSON(recipeSave))
end

---For when a custom item is added
---@param itemName string
function CaseInventory:GhostRecipesAdded(itemName)
	local change = false
	for index, recipe in pairs(CaseInventory.GhostRecipes) do
		local tryLoad = false
		if recipe.Result == itemName then
			tryLoad = true
		end

		for inputName, _ in pairs(recipe.Input) do
			if inputName == itemName then
				tryLoad = true
				break
			end
		end

		if tryLoad then
			local addedID = CaseInventory:SaveToRecipe(recipe)

			-- Recipe was added, share with the world!
			if addedID ~= 0 then
				CaseInventory:SyncRecipe(addedID)
				-- Also remove from the list
				CaseInventory.GhostRecipes[index] = nil

				change = true
			end
		end
	end

	if change then
		CaseInventory:SaveRecipes()
	end
end

---For when a custom item ins removed
---@param itemID number
function CaseInventory:GhostRecipesRemoved(itemID)
	local change = false
	for rID, recipe in pairs(CaseInventory.CraftingRecipes) do
		local doRemove = false
		if recipe.Result == itemID then
			doRemove = true
		end

		for inputID, _ in pairs(recipe.Input) do
			if inputID == itemID then
				doRemove = true
				break
			end
		end

		-- bye bye :(
		if doRemove then
			local save = CaseInventory:RecipeToSave(recipe)
			table.insert(CaseInventory.GhostRecipes, save)

			CaseInventory:DeleteRecipe(rID)
			change = true
		end
	end

	if change then
		CaseInventory:SaveRecipes()
	end
end

---Try to create a unique name for an item
---@param name string
---@param ignoreID number?
---@return string
function CaseInventory:GetValidRecipeName(name, ignoreID)
	if ignoreID == nil then
		ignoreID = -1
	end
	local nameTable = {}

	for rID, rInfo in pairs(CaseInventory.CraftingRecipes) do
		if rID == ignoreID then
			continue
		end
		table.insert(nameTable, rInfo.DisplayName)
	end

	for _, rInfo in pairs(CaseInventory.GhostRecipes) do
		table.insert(nameTable, rInfo.DisplayName)
	end

	local finalName = ""
	local badName = false
	for _, displayName in ipairs(nameTable) do
		if displayName == name then
			badName = true
			break
		end
	end

	if not badName then
		return name
	end

	local i = 1
	while badName do
		badName = false
		finalName = string.format("%s (%i)", name, i)
		for _, displayName in ipairs(nameTable) do
			if displayName == finalName then
				i = i + 1
				badName = true
				break
			end
		end

	end

	return finalName
end


---Client only
function CaseInventory:PopulateNames()
	for k, v in pairs(CaseInventory.ItemRegister) do
		if v.PrintName ~= nil then
			v.PrintName = CaseInventory:TryLocalize(v.PrintName)
			continue
		end

		if v.ItemType == CASE_ITEM_WEAPON or v.ItemType == CASE_ITEM_GRENADE then
			local info = weapons.Get(v.Name)
			if info ~= nil then
				if info.PrintName ~= nil then
					v.PrintName = CaseInventory:TryLocalize(info.PrintName)
				elseif info.ClassName ~= nil then
					v.PrintName = CaseInventory:TryLocalize(info.ClassName)
				else
					v.PrintName = ""
				end
			end

			if v.PrintName == nil then
				v.PrintName = ""
			end
		end
	end
end



function CaseInventory:DebugPrintLoadout(inv)
	local s = ""
	for y=1,inv.Size[2] do
		for x=1,inv.Size[1] do
			s = s .. string.format("[%i]", inv.Loadout[x][y])
		end
		s = s .. "\n"
	end
	print(s)
	return s
end