--[[
	Some info, read if you're gonna add something :)

	.OnUse/.CanUse are given three arguments, the player, the info table and the inventoryID
	(the inventoryID will be -1 if not yet in the inventory!), you'll probably only need to use the player but do whatever
	BOTH are used client and serverside

	.CanUse returns true or false
	You can set CanUse to nil to indicate always usable

	.OnUse can return two items, a boolean (true/false) to indicate if an item was used and a number to indicate how many were used (optional, will default to 1)
	It will also be called both CLIENTSIDE AND SERVERSIDE
	clientside is ONLY used to calculate if the item would've actually been used, make sure to account for this :)

	You might want to set the player variable .CasePickup to the entity you want them to pickup instantly if you're gonna spawn the item to pickup

]]
CASE_ITEM_GENERIC       = 0 -- :Use will be called when picking up normally, holding Alt/walk will add it to inventory (useful for healing/armor)
CASE_ITEM_WEAPON        = 1
CASE_ITEM_GRENADE       = 2
CASE_ITEM_GLOW_ONLY     = 3 -- Only used to show that ammo can be obtained, :Use will be called instead of adding to inventory
CASE_ITEM_AMMO          = 4
CASE_ITEM_AMMO_SPECIAL  = 5 -- Used for the caseammo entity to store any type of ammo
CASE_ITEM_DO_NOT_HANDLE = 6 -- Used for fists and stuff for when it's not really something to go into the inventory

CASE_TAG_ITEM = "item"
CASE_TAG_CONSUMABLE = "consumable"
CASE_TAG_WEAPON = "weapon"
CASE_TAG_GRENADE = "grenade"
CASE_TAG_HEALTH = "health"
CASE_TAG_ARMOR = "armor"
CASE_TAG_AMMO = "ammo"
CASE_TAG_CRAFTING = "crafting_component"
CASE_TAG_CUSTOM = "custom"

---@param name string
---@param sizeW number
---@param sizeH number
---@param maxSize number
---@param itemType number
---@param onUse function?
---@param canUse function?
---@param ammoID number
---@param renderInfo table?
---@param printName string?
---@param tags table?
function CaseItem(name, sizeW, sizeH, maxSize, itemType, onUse, canUse, ammoID, renderInfo, printName, tags)
	return {
		Name=name,
		PrintName=printName,
		Size={
			W=sizeW,
			H=sizeH
		},
		OnUse=onUse,
		CanUse=canUse,
		AmmoID=ammoID,
		MaxCount=maxSize,
		ItemType=itemType,
		RenderInfo=renderInfo or CaseRenderInfo(
			"models/error",
			1,
			{0,0,0}
		),
		Tags= tags or {}
	}
end

---@param model string?
---@param scale number?
---@param rotVec table|boolean? Uses this vector to apply rotations post xDiff/yDiff OR if it's true/false it'll apply 90 degrees instead
---@param offset table? Vector offset
---@param skin integer? Skin to use
---@return table
function CaseRenderInfo(model, scale, rotVec, offset, skin, useSprite)
	if type(offset) == "table" then
		offset = Vector(
			offset[1] ~= nil and offset[1] or 0,
			offset[2] ~= nil and offset[2] or 0,
			offset[3] ~= nil and offset[3] or 0
		)
	end

	if useSprite == nil then
		useSprite = false
	end

	return {
		Model = model or "",
		Scale = scale or 1, -- Ok to be nil
		Rotations = rotVec or {0, 0, 0},
		Offset = offset or Vector(0, 0),
		Skin = skin or 0,
		UseSprite = useSprite
	}


end

---Generic item
---@param name string
---@param printName string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param maxSize integer
---@param tags table?
---@return table
function CaseGeneric(name, printName, renderInfo, sizeW, sizeH, maxSize, tags)
	local tags2 = {}
	if tags ~= nil then
		tags2 = table.Copy(tags)
	end
	table.insert(tags2, CASE_TAG_ITEM)

	return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, nil, nil, -1, renderInfo, printName, tags2)
end

---Usable item
---@param name string
---@param printName string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param maxSize integer
---@param onUse function
---@param canUse function?
---@param tags table?
---@return table
function CaseConsumable(name, printName, renderInfo, sizeW, sizeH, maxSize, onUse, canUse, tags)
	local tags2 = {}
	if tags ~= nil then
		tags2 = table.Copy(tags)
	end
	table.insert(tags2, CASE_TAG_CONSUMABLE)

	return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, onUse, canUse, -1, renderInfo,  printName, tags2)
end

---Weapon :)
---@param name string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param printName string? Last because only HL2 weapons will need to be manually added (their pickup names are all caps :()
---@param tags table?
---@return table
function CaseWeapon(name, renderInfo, sizeW, sizeH, printName, tags)
	local tags2 = {}
	if tags ~= nil then
		tags2 = table.Copy(tags)
	end
	table.insert(tags2, CASE_TAG_WEAPON)

	return CaseItem(name, sizeW, sizeH, 1, CASE_ITEM_WEAPON, nil, nil,-1, renderInfo, printName, tags2)
end

---Creates a grenade :)
---@param name string
---@param renderInfo table
---@param sizeW integer
---@param sizeH integer
---@param maxSize integer
---@param grenadeAmmo integer
---@param tags table?
---@return table
function CaseGrenade(name, renderInfo, sizeW, sizeH, maxSize, grenadeAmmo, tags)
	local tags2 = {}
	if tags ~= nil then
		tags2 = table.Copy(tags)
	end
	table.insert(tags2, CASE_TAG_WEAPON)
	table.insert(tags2, CASE_TAG_GRENADE)

	return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GRENADE, nil, nil, grenadeAmmo, renderInfo, game.GetAmmoName( grenadeAmmo ), tags2)
end

---Creates ammo
---@param ammoID integer|string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param maxSize integer
---@param printName string?
---@return table|nil
function CaseAmmo(ammoID, renderInfo, sizeW, sizeH, maxSize, printName)
	if type(ammoID) == "string" then
		ammoID = game.GetAmmoID(ammoID)
	end

	if ammoID == -1 then
		return nil
	end
	local ammoName = game.GetAmmoName(ammoID)


	if printName == nil and not SERVER then
		printName = CaseInventory:TryLocalize(game.GetAmmoName( ammoID ) .. "_ammo")
	end
	return CaseItem("ammo_" .. ammoName, sizeW, sizeH, maxSize, CASE_ITEM_AMMO, nil, nil, ammoID, renderInfo, printName, {CASE_TAG_AMMO})
end

function CaseGlowOnly(name)
   return CaseItem(name, 0, 0, 0, CASE_ITEM_GLOW_ONLY, nil, nil, -1, {}, "")
end

function CaseDoNotHandle(name)
	return CaseItem(name, 0, 0, 0, CASE_ITEM_DO_NOT_HANDLE, nil, nil, -1, {}, "")
end

-- Weight is deliberately kept separate from the grid size. Addons may set an
-- exact value by assigning ItemInfo.Weight (kilograms per item); otherwise the
-- fallback below gives every legacy/generated item a useful, predictable mass.
-- This makes the HUD useful now and provides a stable API for a future hard
-- carry limit without changing the existing item constructor signatures.
function CaseInventory:GetItemWeight(itemID, count)
	local info = self:GetItemInfo(itemID)
	if not info then return 0 end

	count = math.max(tonumber(count) or 1, 0)
	if isnumber(info.Weight) then
		return math.max(info.Weight, 0) * count
	end

	local area = math.max((info.Size and info.Size.W or 1) * (info.Size and info.Size.H or 1), 1)
	local perItem

	if info.ItemType == CASE_ITEM_AMMO then
		perItem = 0.018
	elseif info.ItemType == CASE_ITEM_GRENADE then
		perItem = 0.45
	elseif info.ItemType == CASE_ITEM_WEAPON then
		perItem = 0.55 + area * 0.32
	elseif info.ItemType == CASE_ITEM_GENERIC then
		perItem = 0.18 + area * 0.20
	else
		perItem = 0
	end

	return perItem * count
end

function CaseInventory:GetInventoryWeight(inv)
	if not inv or not istable(inv.Items) then return 0 end

	local total = 0
	for _, item in pairs(inv.Items) do
		if item then
			total = total + self:GetItemWeight(item.ItemID, item.Count)
		end
	end

	return total
end


-- Custom item stuff

function CaseCustomItemUse(ply, itemID)
	if CLIENT then
		return true
	end

	local info = CaseInventory:GetItemInfo(itemID)
	if info == nil then
		return false
	end

	local ent = ents.Create(info.Name)

	-- Unlucky?
	if not IsValid(ent) then
		return false
	end

	ent:Spawn()
	ply.CasePickup = ent
	ent:SetPos(ply:GetPos())
	ent:Use(ply, ply)


	return true
end

function CaseCustomItemCanUse(ply, itemID)
	local custom = CaseInventory.CustomItems[itemID]
	if custom.Type ~= CASE_CUSTOM_CONSUMABLE then
		return false
	end

	if custom.CanUse == CASE_CUSTOM_USE_ALWAYS then
		return true
	elseif custom.CanUse == CASE_CUSTOM_USE_HEALTH then
		return ply:Health() < ply:GetMaxHealth()
	elseif custom.CanUse == CASE_CUSTOM_USE_ARMOR then
		return ply:Armor() < ply:GetMaxArmor()
	end
end
