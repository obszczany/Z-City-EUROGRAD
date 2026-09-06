local cvar_blur_bg = CreateClientConVar("case_cl_blur_bg", "1", true, false, "Blur the background for the UI", 0, 1)
local cvar_show_edit_button = CreateClientConVar("case_cl_show_edit", "1", true, false, "Shows the edit button in the case menu", 0, 1)
local cvar_prefer_sprites = CreateClientConVar("case_cl_prefer_sprites", "0", true, false, "Try to use sprites always", 0, 2)

local ogWidth, ogHeight = 1920, 1080 -- not my screen size, hopefully that makes it better for testing????
__CASE_UI_CELL_SIZE = 64 -- #define
__CASE_UI_BORDER = 32

CaseGUI = {
	HeldItem = {
		InvID=-1,
		SourceWindow=nil,
		Rotated=false,
		X=1,
		Y=1,
		OldInfo={} -- Store info to reset the pos & rot of an item
	},
	SortingWindow = nil,
	MainWindow = nil,
	EditWindow = {
		Panel = nil
	},
	HoveredWindow = nil,
	IsOpen = false,
	ReadyToClose=false,
	Context = {
		Panel=nil,
		Parent=nil,
		InvID=-1
	},
	InvTargets = {
	},
	ShouldPlaySounds = CreateClientConVar("case_cl_play_sounds", "1", true, false, [[Should sounds be played?
	Set to 2 to replace the more annoying sounds]], 0, 2 ),
	PlaySound = function (sound, replace)
		if not CaseGUI.ShouldPlaySounds:GetBool() then
			return
		end

		if replace ~= nil and CaseGUI.ShouldPlaySounds:GetInt() == 2 then
			surface.PlaySound(replace)
			return
		end

		surface.PlaySound(sound)
	end,
	ModelCache={},
	SpriteCache={},
	CaseFPS = CreateClientConVar("case_cl_menu_fps", "40", true, false, "Framerate at which the case menu should be drawn", 0, 999),

	-- Me when i lie
	FakePlayerInv = {}
}

-- The bane of GUI progammers world wide
-- Different hardware configurations
-- / Ultrawide users
function _CaseUIGetScaledSize()
	local height = ScrH()
	local width = height * (16/9) -- banish the ultrawide users to brazil

	return width, height
end

function _CaseUIGetScaledDiff()
	local newW, newH = _CaseUIGetScaledSize()

	return newW/ ogWidth, newH /ogHeight
end

function _CaseUIScale(a, b)
	local scaleX, scaleY = _CaseUIGetScaledDiff()
	return a * scaleX, b * scaleY
end

function _CaseUIGetCell(arguments)

end

function CaseGUI:Sync(dropItems)
	if dropItems == nil then
		dropItems = false
	end

	-- Start by dropping all items stored in the sorting menu
	if dropItems then
		for k, v in pairs(self.InvTargets["SortingWindow"]:Inv().Items) do
			CaseInventory.ClientNet.DropItem(k, -1, false)
		end
	end

	-- Copy over all our work and sync
	CaseInv(LocalPlayer()).Items = CaseGUI.FakePlayerInv.Items
	CaseInventory.ClientNet.SyncItems()
end

-- Sick cleanup
function CaseGUI:Close(silent)
	if silent == nil then
		silent = false
	end
	self:Sync(true)
	self.SortingWindow:Close()
	self.MainWindow:Close()
	if self.Context.Panel ~= nil then
		self.Context.Panel:Remove()
	end
	self:CloseEditMenu()
	self.SortingWindow = nil
	self.MainWindow = nil
	self.IsOpen = false
	self.Context = {
		Panel=nil,
		Parent=nil,
		Item=-1
	}
	self.HeldItem.InvID = -1
	self.ReadyToClose = false

	if not silent then
		CaseGUI.PlaySound("ui/re4case/case_close.wav")
	end

	for k, v in pairs(self.ModelCache) do
		v:Remove()
	end

	self.ModelCache = {}
	self.SpriteCache = {}
end

function CaseGUI:CloseContext()
	if self.Context.Panel ~= nil then
		self.Context.Panel:Remove()
	end

	self.Context.Panel = nil
	self.Context.Parent = nil
	self.Context.Item = -1
end

---Creates a context item
---@param text string
---@param callback function
---@param allowed function?
---@param sound string?
function CaseGUI:AddContext(list, text, callback, allowed, sound)
	table.insert(list, {
		Text=text,
		Callback=callback,
		Allowed=allowed,
		Sound=sound
	})
end


function CaseGUI.ContextUse(info)
	local itemInfo = info.ItemInfo
	CaseInventory.ClientNet.UseItem(info.InvID, true) -- Request for the server to use the item

	-- Cool line
	local used, useCount = CaseInventory:UseItem(LocalPlayer(), info.InvID, false)
	useCount = useCount and math.max(0, useCount) or 1
	if used then
		info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - useCount
		if info.Inv.Items[info.InvID].Count == 0 then
			info.Inv.Items[info.InvID] = nil
			CaseInventory:RefreshLoadout(info.Inv)
			CaseGUI:CloseContext()
		end
	end
end

function CaseGUI.ContextUseCheck(info)
	return CaseInventory:CanUse(LocalPlayer(), info.ItemID)
end

function CaseGUI.ContextEquip(info)
	local itemInfo = info.ItemInfo
	for _, wep in ipairs( LocalPlayer():GetWeapons() ) do
		if wep:GetClass() == itemInfo.Name then
			input.SelectWeapon(wep)
			break
		end
	end
	CaseGUI:CloseContext()
end

function CaseGUI.ContextEquipCheck(info)
	local itemInfo = info.ItemInfo
	if not IsValid(LocalPlayer():GetActiveWeapon()) then
		return true
	end
	return LocalPlayer():GetActiveWeapon():GetClass() ~= itemInfo.Name
end

function CaseGUI.ContextDrop1(info)
	local itemInfo = info.ItemInfo
	CaseInventory.ClientNet.DropItem(info.InvID, 1, false)
	info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - 1
	if info.Inv.Items[info.InvID].Count == 0 then
		info.Inv.Items[info.InvID] = nil
		CaseInventory:RefreshLoadout(info.Inv)
		CaseGUI:CloseContext()
	end
end

function CaseGUI.ContextDrop(info)
	CaseInventory.ClientNet.DropItem(info.InvID, -1, false)
	info.Inv.Items[info.InvID] = nil

	CaseInventory:RefreshLoadout(info.Inv)
	CaseGUI:CloseContext()
end

function CaseGUI.ContextDropHalf(info)
	local count = info.Inv.Items[info.InvID].Count
	count = math.ceil(count / 2)
	CaseInventory.ClientNet.DropItem(info.InvID, count, false)
	info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - count


	if info.Inv.Items[info.InvID].Count == 0 then
		info.Inv.Items[info.InvID] = nil
		CaseInventory:RefreshLoadout(info.Inv)
		CaseGUI:CloseContext()
	end
end


hook.Add("CaseFillContext", "CaseDefaultFillContext", function (list, info)
	local itemInfo = info.ItemInfo
	if itemInfo.OnUse ~= nil then
		CaseGUI:AddContext(list, "Use", CaseGUI.ContextUse, CaseGUI.ContextUseCheck)
	end

	if itemInfo.ItemType == CASE_ITEM_WEAPON or itemInfo.ItemType == CASE_ITEM_GRENADE then
		CaseGUI:AddContext(list, "Equip", CaseGUI.ContextEquip, CaseGUI.ContextEquipCheck, "ui/re4case/case_equip.wav")
	end

	if CaseInventory.CraftingLookup[itemInfo.ItemID] ~= nil then
		CaseGUI:AddContext(list, "Combine", function ()
			CaseGUI:Close()
			CaseCraftGUI:OpenCrafting(itemInfo.ItemID)
		end)
	end

	if itemInfo.ItemType == CASE_ITEM_GENERIC or itemInfo.ItemType == CASE_ITEM_GRENADE then
		CaseGUI:AddContext(list, "Drop 1", CaseGUI.ContextDrop1)
	end

	if itemInfo.ItemType == CASE_ITEM_AMMO then
		CaseGUI:AddContext(list, "Drop Half", CaseGUI.ContextDropHalf)
		CaseGUI:AddContext(list, "Drop 1", CaseGUI.ContextDrop1)
	end

end)


---Fills the context menu with that fits with whatever item was selected
---Params here just for ease of use
---@param panel table
---@param parent table
---@param itm integer
function CaseGUI:FillContext(panel, parent)
	local itemID = self.Context.Parent:Inv().Items[CaseGUI.Context.InvID].ItemID
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	local list = {}

	local info = self:GenerateInfo()
	if info ~= nil then
		hook.Call("CaseFillContext", nil, list, info)
	end


	-- All items have this :)
	CaseGUI:AddContext(list,"Drop", CaseGUI.ContextDrop)

	for k, v in pairs(list) do
		panel:AddOption(v.Text, v.Callback, v.Allowed, v.Sound)
	end
end

---Generates some info to pass to a context option
---@return table?
function CaseGUI:GenerateInfo()
	if self.Context.Parent == nil or
		CaseGUI.Context.InvID == nil or
		self.Context.Parent:Inv().Items[CaseGUI.Context.InvID] == nil then
		return nil
	end

	local itemID = self.Context.Parent:Inv().Items[CaseGUI.Context.InvID].ItemID
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	return {
		Menu=self.Context.Panel,
		ItemID=itemID,
		ItemInfo=itemInfo,
		Inv=self.Context.Parent:Inv(),
		InvID=CaseGUI.Context.InvID}
end

function CaseGUI:OpenEditMenu()
	if IsValid(self.EditWindow.Window) then
		self:CloseEditMenu()
		return
	end

	local sizeW, sizeH = 400, 700

	self.EditWindow.Window = vgui.Create("DFrame")
	self.EditWindow.Window:InvalidateLayout(true)
	self.EditWindow.Window:SetSize(sizeW, sizeH)
	self.EditWindow.Window:SetSizable( true )
	self.EditWindow.Window:NoClipping(true)
	self.EditWindow.Window:MakePopup()
	self.EditWindow.Window:Center()
	self.EditWindow.Window:SetTitle("The Edit Zone")

	local backgroundPanel = vgui.Create( "DPanel", self.EditWindow.Window )
	backgroundPanel:Dock( TOP )
	backgroundPanel:DockPadding( 4, 4, 4, 4 )
	backgroundPanel:DockMargin( 0, 0, 0, 4 )
	backgroundPanel:SetSize(sizeW - 4, sizeH- 8)


	local panel, b = vgui.Create("DForm", backgroundPanel)

	panel:InvalidateLayout(true)
	panel:SizeToChildren( true, true )
	panel:SetSize(sizeW- 4, sizeH - 8)
	panel:SetLabel("The Edit Zone")


	CaseEditor.Populate(self.EditWindow, panel)

	panel:ControlHelp("\n\nYou can hide the button that opens this menu in the settings :)")
end

function CaseGUI:CloseEditMenu()
	if not IsValid(self.EditWindow.Window) then
		return
	end

	self.EditWindow.Window:Remove()
end

-- Quick shortcut for using an item in an inventory with +use/E
local function _windowOnKeyboardInput(self, keycode)
	if CaseGUI.HoveredWindow == nil then
		return false
	end
	local window = CaseGUI.HoveredWindow
	if window == nil then
		return false
	end

	-- i uh i uhm i um what????
	-- not the best practice to just ignore it buuuuut
	-- i don't care :)
	if window.GetMouseItem == nil then
		return
	end

	local invId = window:GetMouseItem()
	if invId == 0 then
		return false
	end

	local invInfo = window:Inv().Items[invId]
	local itemInfo = CaseInventory:GetItemInfo(invInfo.ItemID)

	return true
end


local function _createWindow(name, inv, parent, isMain, rtName)
	local window = vgui.Create("DFrame")
	window:NoClipping(true)
	local screenW, screenH = _CaseUIGetScaledSize()
	local scaleW, scaleH = _CaseUIGetScaledDiff()

	window:SetSize(
		(inv.Size[1] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
		(inv.Size[2] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
	)

	window:Center()
	window:MakePopup()
	--window:ShowCloseButton(false)
	window:SetDraggable(false)
	window.OnKeyCodePressed = _windowOnKeyboardInput
	if parent and cvar_blur_bg:GetBool() then
		window:SetBackgroundBlur(true)
	end

	local inventory = vgui.Create("CaseInvPanel", window)
	inventory:SetSize(
		(inv.Size[1] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
		(inv.Size[2] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
	)
	inventory.InvTarget = inv

	if rtName ~= nil then
		inventory.RT = GetRenderTarget("re4case_RT_" .. rtName, ScrW(), ScrH())
		inventory.RTMat = CreateMaterial("re4case_MAT_" .. rtName, "UnlitGeneric", {
			["$basetexture"] = inventory.RT:GetName()
		})

		inventory.ItemRT = GetRenderTarget("re4case_ItemRT_" .. rtName, ScrW(), ScrH())
		inventory.ItemRTMat = CreateMaterial("re4case_ItemMAT_" .. rtName, "UnlitGeneric", {
			["$basetexture"] = inventory.ItemRT:GetName(),
			["$translucent"] = 1
		})
	end

	inventory:NoClipping(true)
	CaseGUI.InvTargets[name] = inventory

	inventory.IsMainPanel = isMain

	return window
end

function CaseGUI.OpenInventory(silent)
	if silent == nil then
		silent = false
	end

	if CaseGUI.IsOpen then
		return
	end

	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local mwX, mwY = 0, 0

	CaseGUI.FakePlayerInv = table.Copy(CaseInv(LocalPlayer()))
	CaseGUI.MainWindow = _createWindow("MainWindow", CaseGUI.FakePlayerInv , true, true, "MainWindow")
	CaseGUI.MainWindow:Center()

	mwX, mwY = CaseGUI.MainWindow:GetPos()
	mwX = mwX - ((__CASE_UI_BORDER/1.5) * scaleW)

	-- Nobody will notice it's slightly off center yeah?
	-- **YOU** won't tell about this right?
	CaseGUI.MainWindow:SetPos(mwX , mwY)
	CaseGUI.SortingWindow = _createWindow("SortingWindow", CaseInventory:GenerateInventory(6, 9), false, false, "SortingWindow")
	CaseGUI.MainWindow:SetPaintedManually(true)

	CaseGUI.SortingWindow:SetPos(mwX + CaseGUI.MainWindow:GetSize() + ((__CASE_UI_BORDER/2) * scaleW), mwY)
	CaseGUI.SortingWindow:SetPaintedManually(true)
	CaseGUI.IsOpen = true


	local mainWindowW = CaseGUI.MainWindow:GetSize()
	local button = vgui.Create("CaseInvExitButton", CaseGUI.MainWindow)
	button:SetText("")
	button:SetSize(25 * scaleH, 25 * scaleH)
	button:SetPos(mainWindowW - ((5*scaleW) +  (25 * scaleH)), (5*scaleW))
	button.DoClick = function()
		CaseGUI:Close()
	end

	-- Z-City owns the actual gameplay inventory. Its compatibility view must
	-- not expose the case crafting/editor controls, which can create state that
	-- the gamemode does not know about.
	local zcityCompat = CaseGUI.ZCityStyle or engine.ActiveGamemode() == "zcity" or (hg and hg.loaded)
	if not zcityCompat then
		local craftButton = CaseGUI.MainWindow:Add("CaseButton")
		craftButton:SetString("C")
		craftButton:SetSize(_CaseUIScale(25, 25))
		craftButton:SetPos(mainWindowW - ((35*scaleW) +  (25 * scaleH)), (5*scaleW))
		craftButton.DoClick = function()
			CaseGUI:Close(true)
			CaseCraftGUI:OpenCrafting(-1)
		end
	end

	if not zcityCompat and cvar_show_edit_button:GetBool() then
		local editButton = vgui.Create("CaseInvEditButton", CaseGUI.MainWindow)
		editButton:SetText("")
		editButton:SetSize(25 * scaleH, 25 * scaleH)
		editButton:SetPos(5*scaleW, 5*scaleH)
		editButton.DoClick = function()
			if IsValid(CaseGUI.EditWindow.Window) then
				CaseGUI:CloseEditMenu()
			else
				CaseGUI:OpenEditMenu()
			end
		end
	end

	if CaseGUI.ShouldPlaySounds:GetBool() and not silent then
		CaseGUI.PlaySound("ui/re4case/case_open.wav")
	end
end

---Returns the last hovered item in any inventory
---@return number?
---@return table?
function CaseGUI:GetHoveredItem()
	if self.HoveredWindow == nil then
		return nil, nil
	end

	local lastHoveredItem = self.HoveredWindow.LastHoveredItem
	if lastHoveredItem == 0 then
		return nil, nil
	end

	if self.HoveredWindow.Inv == nil then
		return nil, nil
	end

	return lastHoveredItem, self.HoveredWindow:Inv().Items[lastHoveredItem]
end

function CaseGUI:DrawModel(itemID, x, y, w, h, isRotated)
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	local renderInfo = itemInfo.RenderInfo

	-- gulp
	if renderInfo == nil or renderInfo.Model == nil then
		return
	end

	local model = CaseGUI.ModelCache[renderInfo.Model]

	if model == nil then
		model = ClientsideModel(renderInfo.Model)
		CaseGUI.ModelCache[renderInfo.Model] = model
	end
	local _scale = renderInfo.Scale

	if isRotated then
		local tw = w
		w = h
		h = tw
	end





	if IsValid(model) then
		local min, max = model:GetRenderBounds()

		local function getOffset( val )
			return math.abs( min[val] )-(max[val]-min[val])/2
		end

		--[[ Gotta remind myself :)
		X -> Forward/Back
		Y -> Left/Right
		Z -> Up/Down
		]]--

		-- If the x width of the model is larger rotate it 90 degrees
		local xDiff, yDiff = max[1]-min[1], max[2]-min[2]
		local _renderRotate = false
		if renderInfo.Rotate then
			_renderRotate = not _renderRotate
		end

		if( xDiff > yDiff or renderInfo.ForceRot == 2) then
			model:SetPos( Vector( getOffset( 2 ), getOffset( 1 ), getOffset( 3 ) ) )
			model:SetAngles( Angle( 0, 90, 0 ) )
		else
			model:SetPos( Vector( getOffset( 1 ), getOffset( 2 ), getOffset( 3 ) ) )
			model:SetAngles( Angle( 0, 0, 0 ) )
		end

		model:SetAngles(model:GetAngles() + Angle(renderInfo.Rotations[1], renderInfo.Rotations[2], renderInfo.Rotations[3]))
		model:SetPos(model:GetPos() + renderInfo.Offset)



		local modelWidth = 0
		if renderInfo.ForceRot == 0 then
			modelWidth = math.max( xDiff, yDiff )
		elseif renderInfo.ForceRot == 0 then
			modelWidth = yDiff
		else
			modelWidth = xDiff
		end


		local square = math.max(w, h)

		local function _offset(a, b)
			local diff = b-a
			return diff/2
		end

		render.SetScissorRect( x, y, x+w, y+h, true )
		cam.Start({
			x=x-_offset(w, square),
			y=y-_offset(h, square),
			w=square,
			h=square,
			type="3D",
			angles = Angle(0, 0, isRotated and -90 or 0),
			origin = Vector(-modelWidth*4/(_scale or 1),0,0),
			fov=70,
			aspect=1,
			subrect=true
		})

		model:SetNoDraw(false)
		model:SetSkin(renderInfo.Skin)
		model:DrawModel()
		model:SetNoDraw(true)
		cam.End3D()


		render.SetScissorRect( 0, 0, 0, 0, false )
	end

end

function CaseGUI:DrawSprite(itemID, x, y, w, h, isRotated, useDrawWeaponSelection)
	if useDrawWeaponSelection == nil then
		useDrawWeaponSelection = true
	end

	local itemInfo = CaseInventory:GetItemInfo(itemID)

	local function GetMaterial(path)
		local mat = Material(path, "noclamp smooth ignorez")
		if mat:IsError() then
			return nil
		end

		return {Material = mat}
	end

	-- Load up a sprite :)
	if CaseGUI.SpriteCache[itemID] == nil then
		local spritePath = string.format("caseicons/%s.png", itemInfo.Name)
		local mat = GetMaterial(spritePath)

		-- Try to use spawn icons
		local useSpawnIcon = mat == nil and CaseInventory:HasTag(itemID, "weapon")

		-- If use sprite mode is set to 1 then only do something
		-- if the item specifically wants to be rendered with a sprite no matter what
		if cvar_prefer_sprites:GetInt() == 1 then
			useSpawnIcon = useSpawnIcon and itemInfo.RenderInfo.UseSprite
		end

		if useSpawnIcon then
			local wep = weapons.Get(itemInfo.Name)

			if wep ~= nil then
				if useDrawWeaponSelection and wep.DrawWeaponSelection ~= nil then
					mat = {DrawIcon=wep.DrawWeaponSelection}
				end

				if wep == nil then
					mat = {}
				elseif mat == nil then
					mat = {Texture=wep.WepSelectIcon}
				end

			end
		end

		if mat == nil then
			mat = {}
		end

		CaseGUI.SpriteCache[itemID] = mat
	end

	local mat = CaseGUI.SpriteCache[itemID]

	if mat.DrawIcon ~= nil then

		if self.ItemRTMat == nil then
			self.ItemRT = GetRenderTarget("re4case_ItemSpriteRT", ScrW(), ScrH())
			self.ItemRTMat = CreateMaterial("re4case_ItemSpriteRTMat", "UnlitGeneric", {
				["$basetexture"] = self.ItemRT:GetName(),
				["$translucent"] = 1
			})
		end

		-- Draw the icon to the top left of the render texture
		render.PushRenderTarget(self.ItemRT)
		cam.Start2D()
		render.SetViewPort( 0, 0, ScrW(), ScrH())
		render.Clear(0, 0, 0, 0, true, true)
		LocalPlayer():GetWeapon(itemInfo.Name):DrawWeaponSelection(0, 0, w, h, 255)
		cam.End2D()
		render.PopRenderTarget()



		--

		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(self.ItemRTMat)


		if not isRotated then
			render.SetScissorRect( x, y, w, h, true)
			surface.DrawTexturedRect(x, y, ScrW(), ScrH())
		else
			-- Make sure to swap width and height because we are rotated here!
			-- But it works no?

			render.SetScissorRect( x, y,  x + h, y + w, true)

			local xOffset = (-ScrH()) + h
			surface.DrawTexturedRectRotated(x + ( ScrH() / 2 ) + xOffset, y + (ScrW() / 2), ScrW(),ScrH(), 270)
		end
		render.SetScissorRect( 0, 0, 0, 0, false)

	elseif mat.Texture ~= nil then
		surface.SetTexture(mat.Texture)
	elseif mat.Material ~= nil then
		surface.SetMaterial(mat.Material)
	else
		return self:DrawModel(itemID, x, y, w, h, isRotated)
	end

	surface.SetDrawColor(255, 255, 255)

	if mat.DrawIcon == nil then
		if not isRotated then
			surface.DrawTexturedRectUV( x, y, w, h, 0, 0, 1, 1)
		else
			surface.DrawTexturedRectRotated( x + (h/2), y + (w/2), w, h, 270)
		end
	end
end

function CaseGUI:DrawItem(itemID, invId, x, y, w, h, isRotated)

end

concommand.Add("case_open", function ()
	CaseGUI.OpenInventory()
end)


-- Do this manually to remove flickering :)
hook.Add( "PostDrawHUD", "CASE_PostDrawHUD", function()
	if CaseGUI.IsOpen then
		-- Make a new 2D context so there isn't a 1px border where there isn't a blur
		cam.Start2D()
			CaseGUI.MainWindow:PaintManual()
			CaseGUI.SortingWindow:PaintManual()
		cam.End2D()
	end
end )
