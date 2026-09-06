local cvar_draw_names = CreateClientConVar("case_cl_draw_weapon_names", "1", true, false, "Should item names be shown in the case?", 0, 1)
local cvar_prefer_sprites = CreateClientConVar("case_cl_prefer_sprites", "0", true, false, "Try to use sprites always", 0, 2)
--local cvar_play_sound = CreateClientConVar("case_play_sounds", "1", true, false, "Should sounds be played?", 0, 1)

local invpanel = {}
invpanel.InvTarget = nil
invpanel.IsMainPanel = false
invpanel.LastHoveredItem = -1
invpanel.RT = nil
invpanel.RTMat = nil
invpanel.ItemRT = nil
invpanel.ItemRTMat = nil
invpanel.NextDrawTime = 0

AccessorFunc(invpanel, "bHasItems", "HasItems")

local itemColors = {
	Color(250, 61, 61, 255), -- Empty **SHOULD** only be visible on guns >:(
	Color(247, 237, 227, 255), -- Somewhere inbetween
	Color(99, 199, 99, 255) -- Full/Max count
}

local ratio = 16/9

function invpanel:InvW()
	return self:Inv().Size[1]
end

function invpanel:InvH()
	return self:Inv().Size[2]
end

function invpanel:Inv()
	return self.InvTarget
end

---@param clamp? boolean Instead of returning nil, clamp to the last grid index
---@return integer?
---@return integer?
function invpanel:GetMouseSlot(clamp)
	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local posX, posY = self:LocalToScreen(self:GetPos())
	local relX, relY = gui.MouseX() - posX, gui.MouseY() - posY
	local gridX, gridY = math.floor((relX - __CASE_UI_BORDER*scaleW) / (__CASE_UI_CELL_SIZE * scaleW)) + 1,
		math.floor((relY - __CASE_UI_BORDER*scaleH) / (__CASE_UI_CELL_SIZE * scaleH)) + 1


	if not clamp and
		(gridX < 1 or gridX > self:InvW() or gridY < 1 or gridY > self:InvH()) then
		return nil, nil
	end

	-- Return clamped
	return math.Clamp(gridX, 1, self:InvW()),
			math.Clamp(gridY, 1, self:InvH())
end

function invpanel:GetMouseItem()
	local slotX, slotY = self:GetMouseSlot()

	if slotX == nil or slotY == nil then
		return 0
	end

	if slotX < 1 or slotX > self:InvW() or
		slotY < 1 or slotY > self:InvH() then
			return 0
	end

	return self:Inv().Loadout[slotX][slotY]
end

function invpanel:DrawGrid(w, h)
	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local baseX, baseY = __CASE_UI_BORDER * scaleW, __CASE_UI_BORDER * scaleH

	local zcity = CaseGUI and CaseGUI.ZCityStyle
	surface.SetDrawColor(zcity and Color(215, 226, 238, 100) or Color(255, 255, 255, 20))
	local _x, _y = 0, 0

	-- Vert Lines
	for x = 0, self:InvW() do
		surface.DrawLine(
			-- From
			baseX + __CASE_UI_CELL_SIZE * _x * scaleW,
			baseY,
			-- To
			baseX + __CASE_UI_CELL_SIZE * _x * scaleW,
			baseY + self:InvH() * __CASE_UI_CELL_SIZE * scaleH
		)
		_x = _x + 1
	end

	-- Horiz Lines
	for y = 0, self:InvH() do
		surface.DrawLine(
			-- From
			baseX,
			baseY + __CASE_UI_CELL_SIZE * _y * scaleH,
			-- To
			baseX + self:InvW() * __CASE_UI_CELL_SIZE * scaleW,
			baseY + __CASE_UI_CELL_SIZE * _y * scaleH
		)
		_y = _y + 1
	end
end

function invpanel:DrawModel(itemID, invId, gridX, gridY, gridW, gridH, isRotated)
	local screenW, screenH = _CaseUIGetScaledSize()
	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local posX, posY = self:LocalToScreen(self:GetPos())
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	local renderInfo = itemInfo.RenderInfo
	local model = CaseGUI.ModelCache[renderInfo.Model]

	if model == nil then
		model = ClientsideModel(renderInfo.Model)
		CaseGUI.ModelCache[renderInfo.Model] = model
	end

	local baseX, baseY = __CASE_UI_BORDER*scaleW, (__CASE_UI_BORDER*scaleH)


	local _x, _y, _w, _h =
		posX + (__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW),
		posY+ (__CASE_UI_BORDER*scaleH) + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH),
		__CASE_UI_CELL_SIZE * gridW * scaleW,
		__CASE_UI_CELL_SIZE * gridH * scaleH

	local _ogW, _ogH = _w, _h
	local _scale = renderInfo.Scale or gridW

	if isRotated then
		local tw = _w
		_w = _h
		_h = tw

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
		--x=(_x - ScrW()/2) + _w/2,
		-- y=(_y - ScrH()/2) + _h/2,



		local modelWidth = 0
		if renderInfo.ForceRot == 0 then
			modelWidth = math.max( xDiff, yDiff )
		elseif renderInfo.ForceRot == 0 then
			modelWidth = yDiff
		else
			modelWidth = xDiff
		end


		local square = math.max(_w, _h)

		local function _offset(a, b)
			local diff = b-a
			return diff/2
		end

		render.SetScissorRect( _x, _y, _x+_w, _y+_h, true )
		cam.Start({
			x=_x-_offset(_w, square),
			y=_y-_offset(_h, square),
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

function invpanel:DrawSprite(itemID, invId, gridX, gridY, gridW, gridH, isRotated)
	local screenW, screenH = _CaseUIGetScaledSize()
	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local posX, posY = self:LocalToScreen(self:GetPos())
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	local renderInfo = itemInfo.RenderInfo

	local _x, _y, _w, _h =
	(__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW),
	(__CASE_UI_BORDER*scaleH) + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH),
	__CASE_UI_CELL_SIZE * gridW * scaleW,
	__CASE_UI_CELL_SIZE * gridH * scaleH

		--[[
	if isRotated then
		local tw = _w
		_w = _h
		_h = tw

	end
	]]

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
				if wep.DrawWeaponSelection ~= nil then
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

		-- Draw the icon to the top left of the render texture
		render.PushRenderTarget(self.ItemRT)
		cam.Start2D()
		render.SetViewPort( 0, 0, ScrW(), ScrH())
		render.Clear(0, 0, 0, 0, true, true)
		LocalPlayer():GetWeapon(itemInfo.Name):DrawWeaponSelection(0, 0, _w, _h, 255)
		cam.End2D()
		render.PopRenderTarget()



		--

		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(self.ItemRTMat)


		if not isRotated then
			render.SetScissorRect( posX + _x, posY + _y,  posX + _x + _w, posY + _y + _h, true)
			surface.DrawTexturedRect(_x, _y, ScrW(), ScrH())
		else
			-- Make sure to swap width and height because we are rotated here!
			-- But it works no?

			render.SetScissorRect( posX + _x, posY + _y,  posX + _x + _h, posY + _y + _w, true)

			local xOffset = (-ScrH()) + _h
			surface.DrawTexturedRectRotated(_x + ( ScrH() / 2 ) + xOffset, _y + (ScrW() / 2), ScrW(),ScrH(), 270)
		end
		render.SetScissorRect( 0, 0, 0, 0, false)

	elseif mat.Texture ~= nil then
		surface.SetTexture(mat.Texture)
	elseif mat.Material ~= nil then
		surface.SetMaterial(mat.Material)
	else
		return self:DrawModel(itemID, invId, gridX, gridY, gridW, gridH, isRotated)
	end

	surface.SetDrawColor(255, 255, 255)

	if mat.DrawIcon == nil then
		if not isRotated then
			surface.DrawTexturedRectUV( _x, _y, _w, _h, 0, 0, 1, 1)
		else
			surface.DrawTexturedRectRotated( _x + (_h/2), _y + (_w/2), _w, _h, 270)
		end
	end
end

--- Some of this shamelessly stolen from<br>
--- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dmodelpanel.lua
--- https://github.com/louiefox/tetris-inventory/blob/master/lua/vgui/tetris_inv_main.lua
---@param itemID integer
---@param invId integer
---@param gridX integer
---@param gridY integer griddy heh
---@param gridW integer
---@param gridH integer
---@param isRotated boolean
---@param count integer
---@param isHeld boolean
function invpanel:DrawItem(itemID, invId, gridX, gridY, gridW, gridH, isRotated, count, isHeld)
	local screenW, screenH = _CaseUIGetScaledSize()
	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local posX, posY = self:LocalToScreen(self:GetPos())
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	local renderInfo = itemInfo.RenderInfo

	local baseX, baseY = __CASE_UI_BORDER*scaleW, (__CASE_UI_BORDER*scaleH)


	local _x, _y, _w, _h =
		posX + (__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW),
		posY+ (__CASE_UI_BORDER*scaleH) + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH),
		__CASE_UI_CELL_SIZE * gridW * scaleW,
		__CASE_UI_CELL_SIZE * gridH * scaleH

	if isRotated then
		local tw = _w
		_w = _h
		_h = tw

	end

	-- Draw the background
	local contextHover = CaseGUI.Context.Panel ~= nil and (CaseGUI.Context.Panel:IsHovered() or CaseGUI.Context.Panel:IsChildHovered())

	if invId == CaseGUI.HeldItem.InvID  then
		local canMove, willSwap = CaseInventory:MoveItem(
			CaseGUI.HeldItem.SourceWindow:Inv(),
			CaseGUI.HeldItem.InvID,
			CaseGUI.HoveredWindow:Inv(),
			CaseGUI.HeldItem.X,
			CaseGUI.HeldItem.Y,
			CaseGUI.HeldItem.Rotated,
			true
		)

		-- wait i HATE performance
		if not canMove then
			--[[local mx, my = self:GetMouseSlot(true)
			canMove, willSwap = CaseInventory:MoveItem(
				CaseGUI.HeldItem.SourceWindow:Inv(),
				CaseGUI.HeldItem.InvID,
				CaseGUI.HoveredWindow:Inv(),
				mx,
				my,
				CaseGUI.HeldItem.Rotated,
				true
			)]]
		end

		-- surface.SetDrawColor(Color(128, 128, 128, 128))
		if canMove and not willSwap then
			surface.SetDrawColor(Color(0, 128, 0, 128))
		elseif canMove and willSwap then
			surface.SetDrawColor(Color(0, 128, 128, 128))
		else
			surface.SetDrawColor(Color(128, 0, 0, 128))
		end

	elseif CaseGUI.HeldItem.InvID == -1 and invId == self:GetMouseItem() and not contextHover then
		surface.SetDrawColor(CaseGUI.ZCityStyle and Color(44, 132, 230, 112) or Color(128, 128, 128, 128))
	else
		surface.SetDrawColor(CaseGUI.ZCityStyle and Color(14, 20, 31, 112) or Color(25,25,25, 200))
	end

	surface.DrawRect(
		baseX + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW) + (5 * scaleW),
		baseY + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH) + (5 * scaleH),
		_w - (7.5 * scaleW),
		_h - (7.5 * scaleH)
	 )
	 surface.SetDrawColor(Color(0,0,0, 255))



	-- Actually draw the damn thing
	if renderInfo.UseSprite or cvar_prefer_sprites:GetInt() >= 1 then
		self:DrawSprite(itemID, invId, gridX, gridY, gridW, gridH, isRotated)
	else
		self:DrawModel(itemID, invId, gridX, gridY, gridW, gridH, isRotated)
	end

	-- Draw either item count or ammo loaded into the weapon
	local _count = 0
	local _countStatus = 0 -- 1 == Empty, 2 = Neither empty or full, 3 = Full, 4 = Don't draw count

	if IsValid(LocalPlayer()) and itemInfo.ItemType == CASE_ITEM_WEAPON and LocalPlayer():HasWeapon(itemInfo.Name) then
		local player = LocalPlayer()
		local wpn = player:GetWeapon(itemInfo.Name)
		if not IsValid(wpn) then
			_count = 0
		else
			-- If the only ammo is stored in the secondary clip use that instead
			local _maxClip = wpn:GetMaxClip1()
			_count = wpn:Clip1()
			if wpn:GetMaxClip1() <= 0 and wpn:GetMaxClip2() > 0 then
				_maxClip = wpn:GetMaxClip2()
				_count = wpn:Clip2()
			end

			if _maxClip <= 0 then -- Melee weapon or something gravgun like?
				_countStatus = 4
			elseif _count >= _maxClip then
				_countStatus = 3
			elseif _count > 0 then
				_countStatus = 2
			else
				_countStatus = 1
			end
		end
	else
		if itemInfo.MaxCount == 1 then
			_countStatus = 4
		elseif count == itemInfo.MaxCount then
			_countStatus = 3
		elseif count > 0 then
			_countStatus = 2
		else
			_countStatus = 1
		end

		_count = count
	end

	if _countStatus ~= 4 then
		surface.SetDrawColor(itemColors[_countStatus])
		local sizeW, sizeH = CaseInvBitmapTextSize(tostring(_count), 25)
		CaseInvBitmapTextDraw(tostring(_count),
			(baseX + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW) + _w) - sizeW - (5*scaleW),
			(baseY + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH) + _h) - sizeH,
		25
		)
	end


end

function invpanel:Init()
end

function invpanel:OnRemove()
end

function invpanel:UpdateItemPos(mx, my)
	local v = CaseGUI.HeldItem.SourceWindow:Inv().Items[CaseGUI.HeldItem.InvID]
	local info = CaseInventory:GetItemInfo(v.ItemID)
	local itemW, itemH = info.Size.W, info.Size.H


	if itemW > self:Inv().Size[1] then -- If the item doesn't fit horiz force rotate it
		CaseGUI.HeldItem.Rotated = true
	end

	if itemW > self:Inv().Size[2] then -- If the item doesn't fit vert force rotate it
		CaseGUI.HeldItem.Rotated = false
	end




	if CaseGUI.HeldItem.Rotated then
		local _w = itemW
		itemW = itemH
		itemH = _w
	end

	local offsetX, offsetY =
			math.Clamp(math.floor(itemW / 2), 0,  math.max(0, itemW-1)),
			math.Clamp(math.floor(itemH / 2), 0, math.max(0, itemH-1))

	if offsetX > 1 then
		mx = mx - offsetX
	end

	if offsetY > 1 then
		my = my - offsetY
	end

	mx = math.Clamp(mx, 1, self:InvW()+1 - itemW)
	my = math.Clamp(my, 1, self:InvH()+1 - itemH)

	CaseGUI.HeldItem.X = mx or v.X
	CaseGUI.HeldItem.Y = my or v.Y

	return mx, my
end

function invpanel:OnMousePressed(keyCode)


	if CaseGUI.Context.Panel ~= nil and (keyCode == MOUSE_LEFT or keyCode == MOUSE_RIGHT ) then
		if not CaseGUI.Context.Panel:GoBack() then
			CaseGUI.Context.Panel:Remove()
			CaseGUI.Context.Panel = nil
			CaseGUI.Context.Parent = nil
			CaseGUI.Context.InvID = -1
			CaseGUI.PlaySound("ui/re4case/context_close.wav")
		end
		return
	end

	-- An item is held
	if CaseGUI.HeldItem.InvID ~= -1 then
		if keyCode == MOUSE_LEFT then
			local mx, my = self:GetMouseSlot()
			if mx then
				local destInvID = self:Inv().Loadout[mx][my]

				-- This doesn't look pretty
				-- But we're just seeing if it slot we're placing the held item on contains an item of the same type
				if destInvID ~= 0 and
					CaseGUI.HeldItem.SourceWindow:Inv().Items[CaseGUI.HeldItem.InvID].ItemID == self:Inv().Items[destInvID].ItemID
				then
					local mergeResult, mSC, mDC = CaseInventory:MergeItem(
						CaseGUI.HeldItem.SourceWindow:Inv(),
						self:Inv(),
						CaseGUI.HeldItem.InvID,
						destInvID,
						true
					)

					if mergeResult then
						-- All of the first item was merged
						if mSC == 0 then
							CaseGUI.HeldItem.InvID = -1
						end

						return
					end
				end

				self:UpdateItemPos(mx, my)

				if CaseInventory:MoveItem(
					CaseGUI.HeldItem.SourceWindow:Inv(),
					CaseGUI.HeldItem.InvID,
					self:Inv(),
					CaseGUI.HeldItem.X,
					CaseGUI.HeldItem.Y,
					CaseGUI.HeldItem.Rotated
				) --[[ or CaseInventory:MoveItem(
					CaseGUI.HeldItem.SourceWindow:Inv(),
					CaseGUI.HeldItem.InvID,
					self:Inv(),
					mx,
					my,
					CaseGUI.HeldItem.Rotated
				)]]
				then
					CaseGUI.PlaySound("ui/re4case/case_putdown.wav", "ui/re4case/case_unequip.wav")
					CaseGUI.HeldItem.InvID = -1
					CaseGUI:Sync()
					return
				end
			end
		end
	end

	-- No item is held
	if CaseGUI.HeldItem.InvID == -1 then
		-- Pickup item
		if keyCode == MOUSE_LEFT then
			local itm = self:GetMouseItem()
			if itm ~= 0 then

				CaseGUI.PlaySound("ui/re4case/case_pickup.wav", "ui/re4case/case_equip.wav")

				CaseGUI.HeldItem.SourceWindow = self
				CaseGUI.HeldItem.InvID = itm
				CaseGUI.HeldItem.OldInfo = self:Inv().Items[CaseGUI.HeldItem.InvID]
				CaseGUI.HeldItem.Rotated = self:Inv().Items[CaseGUI.HeldItem.InvID].Rotated
			end
		end

		-- Show context menu
		if keyCode == MOUSE_RIGHT then
			local itm = self:GetMouseItem()


			if itm ~= 0 then
				CaseGUI.PlaySound("ui/re4case/context_open.wav")
				CaseGUI.Context.Panel = vgui.Create("CaseInvContext")
				local posX, posY = self:LocalToScreen(self:GetPos())
				local itemX, itemY = self:Inv().Items[itm].X, self:Inv().Items[itm].Y
				local itemInfo = CaseInventory:GetItemInfo(self:Inv().Items[itm].ItemID)

				local scaleW, scaleH = _CaseUIGetScaledDiff()
				local _x, _y, _w, _h =
				posX + (__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (itemX-1) * scaleW),
				posY+ (__CASE_UI_BORDER*scaleH) + (__CASE_UI_CELL_SIZE * (itemY-1) * scaleH),
				__CASE_UI_CELL_SIZE * itemInfo.Size.W * scaleW,
				__CASE_UI_CELL_SIZE * itemInfo.Size.H * scaleH


				if self:Inv().Items[itm].Rotated then
					local tw = _w
					_w = _h
					_h = tw

				end

				CaseGUI.Context.Panel:SetPos(_x + _w, _y)
				CaseGUI.Context.Panel:SetSize(200 * scaleW, 200)
				CaseGUI.Context.Panel:NoClipping(true)
				CaseGUI.Context.Panel:MakePopup()
				CaseGUI.Context.InvID = itm
				CaseGUI.Context.Parent = self

				CaseGUI:FillContext(CaseGUI.Context.Panel, self)
			end
		end

	end



end

function invpanel:Think()

	if CaseGUI.HeldItem.InvID ~= -1 and CaseGUI.HeldItem.SourceWindow == self and self:Inv().Items[CaseGUI.HeldItem.InvID] == nil then
		CaseGUI.HeldItem.InvID = -1
	end

	if self:GetMouseSlot() ~= nil then
		CaseGUI.HoveredWindow = self
	end


	if CaseGUI.ShouldPlaySounds:GetBool() then
		local item = self:GetMouseItem()

		if CaseGUI.HeldItem.InvID ~= -1 then
			item = CaseGUI.HeldItem.InvID
			self.LastHoveredItem = item
		end

		if CaseGUI.Context.InvID ~= nil and CaseGUI.Context.InvID ~= -1 then
			item = CaseGUI.Context.InvID
			self.LastHoveredItem  = item
		end

		if item ~= 0 and item ~= self.LastHoveredItem then
			CaseGUI.PlaySound("ui/re4case/case_selection.wav")
		end

		self.LastHoveredItem = item
	end

	self.bHasItems = false
	for k, v in pairs(self:Inv().Items) do
		if v ~= nil then
			self.bHasItems = true
			break
		end
	end

	if CaseGUI.HeldItem.InvID ~= -1 and CaseGUI.HoveredWindow == self then
		local v = CaseGUI.HeldItem.SourceWindow:Inv().Items[CaseGUI.HeldItem.InvID]
		local info = CaseInventory:GetItemInfo(v.ItemID)
		local mx, my = self:GetMouseSlot(true)
		self:UpdateItemPos(mx, my)
	end
end

function invpanel:PaintLimited(w, h)
	local screenW, screenH = _CaseUIGetScaledSize()
	local scaleW, scaleH = _CaseUIGetScaledDiff()

	if self.RT ~= nil then
		render.PushRenderTarget(self.RT)
		render.ClearDepth()
	end

	if CaseGUI.ZCityStyle then
		draw.RoundedBox(6, 0, 0, w, h, Color(9, 14, 23, 166))
	else
		surface.SetDrawColor(42, 41, 37)
		surface.DrawRect(0, 0, w, h)
	end
	if CaseGUI.ZCityStyle then
		surface.SetDrawColor(205, 216, 230, 105)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.SetDrawColor(230, 72, 132, 210)
		surface.DrawRect(0, 0, math.min(w, 82 * scaleW), 2)
		surface.SetDrawColor(35, 137, 255, 220)
		surface.DrawRect(math.min(w, 82 * scaleW), 0, math.min(w, 190 * scaleW), 2)
	end
	self:DrawGrid(w, h)

	render.SetAmbientLight(255, 255, 255)
	render.SuppressEngineLighting( true )
	local ambient = render.GetAmbientLightColor()


	for k, v in pairs(self:Inv().Items) do
		local info = CaseInventory:GetItemInfo(v.ItemID)
		local held = (k == CaseGUI.HeldItem.InvID and self == CaseGUI.HeldItem.SourceWindow)

		if info == nil then
			-- This happens when a new mod is loaded in between maps
			print("CASE: Invalid item id", v.ItemID)
			continue
		end
		if held then -- Draw at mouse position if held :)
			continue -- draw later so it can be over the top of everything
		else
			self:DrawItem(v.ItemID, k, v.X, v.Y, info.Size.W, info.Size.H, v.Rotated, v.Count, false)
		end
	end


	if CaseGUI.HeldItem.InvID ~= -1 and CaseGUI.HoveredWindow == self then
		local v = CaseGUI.HeldItem.SourceWindow:Inv().Items[CaseGUI.HeldItem.InvID]
		local info = CaseInventory:GetItemInfo(v.ItemID)
		local mx, my = self:GetMouseSlot(true)

		if mx and my then -- Don't draw if model would be out of the grid
			-- Make it so this item is drawn on top of everything else
			render.ClearDepth()
			self:DrawItem(v.ItemID, CaseGUI.HeldItem.InvID, CaseGUI.HeldItem.X or v.X, CaseGUI.HeldItem.Y or v.Y, info.Size.W, info.Size.H, CaseGUI.HeldItem.Rotated, v.Count, true)
		end
	end

	render.SetAmbientLight(ambient.X, ambient.Y, ambient.Z)
	render.SuppressEngineLighting( false )

	if self.RT ~= nil then
		render.PopRenderTarget()
	end
end

function invpanel:Paint(w, h)
	local posX, posY = self:LocalToScreen(self:GetPos())
	local panelW, panelH = self:GetSize()
	-- Limit the framerate as to not use 100fps

	if self.RT == nil or SysTime() >= self.NextDrawTime then
		self:PaintLimited(w, h)
		self.NextDrawTime = SysTime() + (1/CaseGUI.CaseFPS:GetInt())
	end


	-- Draw the render target
	if self.RT ~= nil then
		render.SetScissorRect( posX, posY, posX+panelW, posY+panelH, true)
		surface.SetMaterial(self.RTMat)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(-posX, -posY, ScrW(), ScrH())
		render.SetScissorRect( 0, 0, 0, 0, false )
	end

	-- Draw item item name (+ desc?)
	-- This is done outside of the framerate limit because it's cool
	if cvar_draw_names:GetBool() and self.IsMainPanel then
		local itm = 0
		local realID = 0

		if CaseGUI.HeldItem.InvID ~= -1 then
			itm = CaseGUI.HeldItem.InvID
			realID = CaseGUI.HeldItem.SourceWindow:Inv().Items[itm].ItemID
		elseif CaseGUI.Context.InvID ~= -1 and IsValid(CaseGUI.Context.Parent) and CaseGUI.Context.Parent:Inv().Items[itm] ~= nil then
			itm = CaseGUI.Context.InvID
			realID = CaseGUI.Context.Parent:Inv().Items[itm].ItemID
		elseif IsValid(CaseGUI.HoveredWindow) then
			itm = CaseGUI.HoveredWindow:GetMouseItem()
			if itm ~= 0 then
				realID = CaseGUI.HoveredWindow:Inv().Items[itm].ItemID
			end
		end

		if itm ~= 0 then
			local name = CaseInventory:GetItemInfo(realID).PrintName or "" -- or if someone opens the case frame 0 or something
			local sW, sH = self:GetSize()
			local tW, tH = CaseInvBitmapTextSize(name, 35)


			surface.SetDrawColor(Color(255, 255, 255))
			CaseInvBitmapTextDraw(name, (sW / 2) - (tW / 2), -50, 35)
		end
	end


end



vgui.Register("CaseInvPanel", invpanel, "DPanel")
