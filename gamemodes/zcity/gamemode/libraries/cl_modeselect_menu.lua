if CLIENT then
    local isMenuOpen = nil
    zb.availableModes = zb.availableModes or {}
    local availableModes = zb.availableModes
    
    zb.RoundList = zb.RoundList or {}
    zb.nextround = zb.nextround or nil
    local queuePanelInstance = nil 
    local selectedModes = {}

    local karmaCfgCache = {
        MaxKarma = tonumber(zb and zb.MaxKarma or 150),
        GroupMaxKarma = istable(zb and zb.GroupMaxKarma) and table.Copy(zb.GroupMaxKarma) or {},
        PlayerMaxKarma = istable(zb and zb.PlayerMaxKarma) and table.Copy(zb.PlayerMaxKarma) or {}
    }
    local karmaCfgSyncedOnce = false
    local karmaCfgOpenPanel = nil

    net.Receive("hg_admin_karma_settings", function()
        local act = net.ReadString()
        if act ~= "sync" then return end
        local maxK = tonumber(net.ReadFloat()) or 150
        local n = net.ReadUInt(16)
        local groups = {}
        for i = 1, n do
            local g = net.ReadString()
            local v = tonumber(net.ReadFloat()) or 150
            if g and g ~= "" then groups[g] = v end
        end
        local np = net.ReadUInt(16)
        local players = {}
        for i = 1, np do
            local s = net.ReadString()
            local v = tonumber(net.ReadFloat()) or 150
            if s and s ~= "" then players[s] = v end
        end
        karmaCfgCache.MaxKarma = maxK
        karmaCfgCache.GroupMaxKarma = groups
        karmaCfgCache.PlayerMaxKarma = players
        karmaCfgSyncedOnce = true
        if zb then
            zb.MaxKarma = maxK
            zb.GroupMaxKarma = table.Copy(groups)
            zb.PlayerMaxKarma = table.Copy(players)
        end
        if IsValid(karmaCfgOpenPanel) and karmaCfgOpenPanel.RefreshFromCache then
            karmaCfgOpenPanel:RefreshFromCache()
        end
    end)

    net.Receive("ZB_SendModesInfo", function()
        zb.availableModes = net.ReadTable()
    end)
    
    net.Receive("ZB_SendRoundList", function()
        zb.RoundList = net.ReadTable()
        zb.nextround = net.ReadString()
        table.insert(zb.RoundList, 1, zb.nextround)
        zb.nextround = nil
        if IsValid(queuePanelInstance) then
            queuePanelInstance:QueueUpdate()
        end
    end)
    
    net.Receive("ZB_NotifyRoundListChange", function()
        local playerName = net.ReadString()
        
        chat.AddText(Color(180, 180, 255), playerName, Color(255, 255, 255), " has modified the game mode queue")
        
        net.Start("ZB_RequestRoundList")
        net.SendToServer()
    end)

    local function StyleElement(element, bgColor)
        bgColor = bgColor or Color(40, 40, 40, 200)
        
        element.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, bgColor)
            
            if self:IsHovered() and self.Selectable then
                draw.RoundedBox(6, 1, 1, w-2, h-2, Color(60, 60, 60, 100))
                surface.SetDrawColor(255, 165, 0, 150)
                surface.DrawOutlinedRect(1, 1, w-2, h-2, 1)
            end
            
            if self.Selected then
                surface.SetDrawColor(0, 255, 0, 150)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
        end
    end
    
    local function CreateModeItem(parent, mode, queue, index)
        local modePanel = vgui.Create("DPanel", parent)
        modePanel:SetTall(40)
        modePanel:Dock(TOP)
        modePanel:DockMargin(5, 2, 5, 2)
        modePanel.Mode = mode
        modePanel.Index = index 
        modePanel.Selectable = true
        modePanel.Selected = selectedModes[mode.key] or false
        
        StyleElement(modePanel, Color(50, 50, 50, 200))
        
        local title = vgui.Create("DLabel", modePanel)
        title:SetFont("DermaDefaultBold")
        title:SetText(mode.name)
        title:SetTextColor(Color(255, 255, 255))
        title:Dock(LEFT)
        title:DockMargin(10, 0, 0, 0)
        title:SizeToContents()
        
        if queue then
            local posLabel = vgui.Create("DLabel", modePanel)
            posLabel:SetFont("DermaDefault")
            posLabel:SetText("#" .. index)
            posLabel:SetTextColor(Color(180, 180, 180))
            posLabel:Dock(LEFT)
            posLabel:DockMargin(5, 0, 0, 0)
            posLabel:SizeToContents()
            
            local upBtn = vgui.Create("DButton", modePanel)
            upBtn:SetSize(24, 24)
            upBtn:Dock(RIGHT)
            upBtn:DockMargin(2, 8, 5, 8)
            upBtn:SetText("▲")
            upBtn.DoClick = function()
                if index > 1 then
                    local item = table.remove(zb.RoundList, index)
                    table.insert(zb.RoundList, index - 1, item)
                    queue:QueueUpdate()
                    
                    /*net.Start("ZB_UpdateRoundList")
                        net.WriteTable(zb.RoundList)
                        net.WriteBool(false) 
                    net.SendToServer()*/
                end
            end
            
            local downBtn = vgui.Create("DButton", modePanel)
            downBtn:SetSize(24, 24)
            downBtn:Dock(RIGHT)
            downBtn:DockMargin(2, 8, 2, 8)
            downBtn:SetText("▼")
            downBtn.DoClick = function()
                if index < #zb.RoundList then
                    local item = table.remove(zb.RoundList, index)
                    table.insert(zb.RoundList, index + 1, item)
                    queue:QueueUpdate()
                    
                    /*net.Start("ZB_UpdateRoundList")
                        net.WriteTable(zb.RoundList)
                        net.WriteBool(false)
                    net.SendToServer()*/
                end
            end
            
            local removeBtn = vgui.Create("DButton", modePanel)
            removeBtn:SetSize(24, 24)
            removeBtn:Dock(RIGHT)
            removeBtn:DockMargin(2, 8, 2, 8)
            removeBtn:SetText("✕")
            removeBtn.DoClick = function()
                table.remove(zb.RoundList, index)
                queue:QueueUpdate()

                /*net.Start("ZB_UpdateRoundList")
                    net.WriteTable(zb.RoundList)
                    net.WriteBool(false)
                net.SendToServer()*/
            end
        else

            modePanel.OnMousePressed = function()
                modePanel.Selected = not modePanel.Selected
                selectedModes[mode.key] = modePanel.Selected
                
                if modePanel.Selected then
                    surface.PlaySound("buttons/button9.wav")
                else
                    surface.PlaySound("buttons/button17.wav")
                end
            end
        end
        
        return modePanel
    end
    
    local function CreateQueuePanel(frame)
        local queuePanel = vgui.Create("DPanel", frame)
        queuePanel:SetSize(frame:GetWide() / 2 - 10, frame:GetTall())
        queuePanel:Dock(RIGHT)
        queuePanel:DockMargin(5, 5, 5, 5)
        StyleElement(queuePanel, Color(30, 30, 30, 200))
        
        queuePanelInstance = queuePanel
        
        local titleLabel = vgui.Create("DLabel", queuePanel)
        titleLabel:SetText("Game Mode Queue")
        titleLabel:SetFont("DermaLarge")
        titleLabel:SetTextColor(Color(255, 200, 0))
        titleLabel:Dock(TOP)
        titleLabel:DockMargin(0, 5, 0, 5)
        titleLabel:SetContentAlignment(5) 
        
        local queueScroll = vgui.Create("DScrollPanel", queuePanel)
        queueScroll:Dock(FILL)
        queueScroll:DockMargin(5, 5, 5, 5)
        
        local saveBtn = vgui.Create("DButton", queuePanel)
        saveBtn:SetText("Apply Queue")
        saveBtn:Dock(BOTTOM)
        saveBtn:DockMargin(5, 5, 5, 5)
        saveBtn:SetTall(30)
        saveBtn.DoClick = function()
            //if #zb.RoundList > 0 then
                local tbl = table.Copy(zb.RoundList)
                //table.insert(tbl, 1, zb.nextround)
                net.Start("ZB_UpdateRoundList")
                    net.WriteTable(tbl)
                    net.WriteBool(true)
                net.SendToServer()
                
                chat.AddText(Color(0, 255, 0), "Game mode queue has been set!")
            //else
                //chat.AddText(Color(255, 0, 0), "Game mode queue is empty!")
            //end
        end
        
        local clearBtn = vgui.Create("DButton", queuePanel)
        clearBtn:SetText("Clear Queue")
        clearBtn:Dock(BOTTOM)
        clearBtn:DockMargin(5, 5, 5, 5)
        clearBtn:SetTall(30)
        clearBtn.DoClick = function()
            zb.RoundList = {}
            queuePanel:QueueUpdate()
            
            /*net.Start("ZB_UpdateRoundList")
                net.WriteTable({})
                net.WriteBool(false)
            net.SendToServer()*/
            
            chat.AddText(Color(255, 165, 0), "Game mode queue cleared!")
        end
        
        function queuePanel:QueueUpdate()
            queueScroll:Clear()
            
            if zb.nextround and zb.nextround ~= "" then
                local nextRoundLabel = vgui.Create("DLabel", queueScroll)
                nextRoundLabel:SetText("Next Mode: " .. zb.nextround)
                nextRoundLabel:SetFont("DermaDefaultBold")
                nextRoundLabel:SetTextColor(Color(100, 255, 100))
                nextRoundLabel:Dock(TOP)
                nextRoundLabel:DockMargin(5, 0, 0, 10)
                nextRoundLabel:SizeToContents()
            end
            
            for idx, modeKey in ipairs(zb.RoundList) do
                local mode = nil
                
                for _, availableMode in ipairs(zb.availableModes) do
                    if availableMode.key == modeKey then
                        mode = availableMode
                        break
                    end
                end
                
                if not mode then
                    mode = {key = modeKey, name = modeKey}
                end
                
                CreateModeItem(queueScroll, mode, queuePanel, idx)
            end
        end
        
        queuePanel:QueueUpdate()
        return queuePanel
    end

    local function OpenModeSelection(command)
        local frame = vgui.Create("ZFrame")
        frame:SetSize(700, 500)
        frame:Center()
        frame:SetTitle("Game Mode Manager")
        frame:MakePopup()
        
        selectedModes = {}
        
        local queuePanel = CreateQueuePanel(frame)
        
        local leftPanel = vgui.Create("DPanel", frame)
        leftPanel:SetSize(frame:GetWide() / 2 - 10, frame:GetTall())
        leftPanel:Dock(LEFT)
        leftPanel:DockMargin(5, 5, 5, 5)
        StyleElement(leftPanel, Color(30, 30, 30, 200))
        
        local titleLabel = vgui.Create("DLabel", leftPanel)
        titleLabel:SetText("Available Game Modes")
        titleLabel:SetFont("DermaLarge")
        titleLabel:SetTextColor(Color(255, 200, 0))
        titleLabel:Dock(TOP)
        titleLabel:DockMargin(0, 5, 0, 5)
        titleLabel:SetContentAlignment(5) 
        
        local searchBar = vgui.Create("DTextEntry", leftPanel)
        searchBar:SetPlaceholderText("Search game modes...")
        searchBar:Dock(TOP)
        searchBar:DockMargin(5, 5, 5, 5)
        searchBar:SetTall(25)
        
        local dscroll = vgui.Create("DScrollPanel", leftPanel)
        dscroll:Dock(FILL)
        dscroll:DockMargin(5, 5, 5, 5)
        
        local modeItems = {}
        
        local function UpdateSearch(filter)
            filter = filter:lower()
            
            for _, item in ipairs(modeItems) do
                local visible = filter == "" or string.find(item.Mode.name:lower(), filter)
                item:SetVisible(visible)
            end
            
            dscroll:InvalidateLayout()
        end
        
        searchBar.OnChange = function(self)
            UpdateSearch(self:GetValue())
        end
        
        local allowedModes = {
            ["tdm"] = true,
            ["cstrike"] = true,
            ["hmcd"] = true,
            ["hl2dm"] = true,
            ["riot"] = true,
            ["gwars"] = true,
            ["criresp"] = true,
        }
        
        for i, mode in SortedPairsByMemberValue(zb.availableModes,"canlaunch",true) do
            if !LocalPlayer():IsAdmin() and !allowedModes[mode.key] then continue end
            
            local modeBtn = CreateModeItem(dscroll, mode)
            table.insert(modeItems, modeBtn)
            
            modeBtn:SetCursor("hand")
            modeBtn:SetTooltip("Click to select/unselect mode")
            
            local inQueue = false
            for _, queuedModeKey in ipairs(zb.RoundList) do
                if queuedModeKey == mode.key then
                    inQueue = true
                    break
                end
            end

            local indicator = vgui.Create("DPanel", modeBtn)
            indicator:SetSize(16, 7)
            indicator:SetPos(8, 4)
            indicator.IndiColor = Color(0, 0, 0, 0)
            indicator.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, indicator.IndiColor)
            end

            if mode.canlaunch == 1 then
                indicator.IndiColor = Color(0,255,34)
                indicator:SetTooltip("This mode can launch")
            end

            if inQueue then
                indicator.IndiColor = Color(255, 155, 0, 255)
                indicator:SetTooltip("This mode is already in queue")
            end
     
            if mode.canlaunch == 0 then
                indicator.IndiColor = Color(255,0,0,255)
                indicator:SetTooltip("This mode can't launch")
            end
            
            if command == "setmode" or command == "setforcemode" then
                local selectBtn = vgui.Create("DButton", modeBtn)
                selectBtn:SetSize(80, 26)
                selectBtn:Dock(RIGHT)
                selectBtn:DockMargin(5, 7, 5, 7)
                selectBtn:SetText("Select")
                selectBtn.DoClick = function()
                    net.Start("AdminSetGameMode")
                    net.WriteString(command)
                    net.WriteString(mode.key)
                    net.WriteBool(false) 
                    net.SendToServer()
                    frame:Close()
                end
            end
        end
        

        local batchPanel = vgui.Create("DPanel", leftPanel)
        batchPanel:Dock(BOTTOM)
        batchPanel:DockMargin(5, 5, 5, 5)
        batchPanel:SetTall(80)
        StyleElement(batchPanel, Color(40, 40, 40, 200))
        
        local batchTitle = vgui.Create("DLabel", batchPanel)
        batchTitle:SetText("Batch Operations")
        batchTitle:SetFont("DermaDefaultBold")
        batchTitle:SetTextColor(Color(255, 255, 255))
        batchTitle:Dock(TOP)
        batchTitle:DockMargin(0, 5, 0, 5)
        batchTitle:SetContentAlignment(5)
        
        local addToQueueBtn = vgui.Create("DButton", batchPanel)
        addToQueueBtn:SetText("Add Selected to Beginning of Queue")
        addToQueueBtn:Dock(TOP)
        addToQueueBtn:DockMargin(5, 0, 5, 5)
        addToQueueBtn:SetTall(26)
        addToQueueBtn.DoClick = function()
            local selectedCount = 0
            
            local selectedKeys = {}
            for key, selected in pairs(selectedModes) do
                if selected then
                    table.insert(selectedKeys, 1, key) 
                    selectedCount = selectedCount + 1
                end
            end
            
            for i = 1, #selectedKeys do
                table.insert(zb.RoundList, 1, selectedKeys[i])
            end
            
            if selectedCount > 0 then
                queuePanel:QueueUpdate()
                
                /*net.Start("ZB_UpdateRoundList")
                    net.WriteTable(zb.RoundList)
                    net.WriteBool(false)
                net.SendToServer()*/
                
                chat.AddText(Color(0, 255, 0), "Added " .. selectedCount .. " modes to beginning of queue!")
                
                selectedModes = {}
                for _, item in ipairs(modeItems) do
                    item.Selected = false
                end
            else
                chat.AddText(Color(255, 0, 0), "No modes selected!")
            end
        end
        
        local addToEndBtn = vgui.Create("DButton", batchPanel)
        addToEndBtn:SetText("Add Selected to End of Queue")
        addToEndBtn:Dock(TOP)
        addToEndBtn:DockMargin(5, 0, 5, 0)
        addToEndBtn:SetTall(26)
        addToEndBtn.DoClick = function()
            local selectedCount = 0
            
            for key, selected in pairs(selectedModes) do
                if selected then
                    table.insert(zb.RoundList, key)
                    selectedCount = selectedCount + 1
                end
            end
            
            if selectedCount > 0 then
                queuePanel:QueueUpdate()
                
                /*net.Start("ZB_UpdateRoundList")
                    net.WriteTable(zb.RoundList)
                    net.WriteBool(false)
                net.SendToServer()*/
                
                chat.AddText(Color(0, 255, 0), "Added " .. selectedCount .. " modes to end of queue!")
                

                selectedModes = {}
                for _, item in ipairs(modeItems) do
                    item.Selected = false
                end
            else
                chat.AddText(Color(255, 0, 0), "No modes selected!")
            end
        end
        
        local refreshBtn = vgui.Create("DButton", leftPanel)
        refreshBtn:SetText("Refresh Data")
        refreshBtn:Dock(BOTTOM)
        refreshBtn:DockMargin(5, 5, 5, 5)
        refreshBtn:SetTall(30)
        refreshBtn.DoClick = function()
            net.Start("ZB_RequestRoundList")
            net.SendToServer()
        end
        
        timer.Create("QueueAutoRefresh", 5, 0, function()
            if IsValid(frame) then
                //net.Start("ZB_RequestRoundList")
                //net.SendToServer()
            else
                timer.Remove("QueueAutoRefresh")
            end
        end)
        
        frame.OnClose = function()
            timer.Remove("QueueAutoRefresh")
            queuePanelInstance = nil
        end
        
        net.Start("ZB_RequestRoundList")
        net.SendToServer()
    end

    local function OpenKarmaMenu()
        local frame = vgui.Create("ZFrame")
        frame:SetSize(520, 380)
        frame:Center()
        frame:SetTitle("Manage Karma")
        frame:MakePopup()

        local selectedTargetMode = "player"
        local selectedPlayer = nil
        local maxKarma = zb and zb.MaxKarma or 100
        local hideAnnouncements = false

        local top = vgui.Create("DPanel", frame)
        top:Dock(TOP)
        top:DockMargin(8, 8, 8, 6)
        top:SetTall(70)
        StyleElement(top, Color(30, 30, 30, 200))

        local targetMode = vgui.Create("DComboBox", top)
        targetMode:Dock(TOP)
        targetMode:DockMargin(8, 8, 8, 4)
        targetMode:SetTall(24)
        targetMode:SetValue("Target: Selected player")
        targetMode:AddChoice("Target: Selected player", "player", true)
        targetMode:AddChoice("Target: Yourself", "self", false)
        targetMode:AddChoice("Target: All players", "all", false)
        targetMode:AddChoice("Target: None", "none", false)
        targetMode.OnSelect = function(_, _, _, data)
            selectedTargetMode = data or "player"
        end

        local playerSelect = vgui.Create("DComboBox", top)
        playerSelect:Dock(TOP)
        playerSelect:DockMargin(8, 0, 8, 8)
        playerSelect:SetTall(24)
        playerSelect:SetValue("Player: (pick)")
        playerSelect.OnSelect = function(_, _, _, data)
            selectedPlayer = data
        end

        local function refreshPlayers()
            playerSelect:Clear()
            local players = player.GetAll()
            table.sort(players, function(a, b)
                return string.lower(a:Nick()) < string.lower(b:Nick())
            end)

            for _, p in ipairs(players) do
                if not IsValid(p) or p:IsBot() then continue end
                local k = p:GetNetVar("Karma") or p.Karma or 0
                local pMax = 150
                if karmaGetMaxForPlayer then
                    pMax = karmaGetMaxForPlayer(p)
                elseif zb and zb.GroupMaxKarma and p.GetUserGroup then
                    local grp = p:GetUserGroup()
                    pMax = tonumber((zb.GroupMaxKarma or {})[grp]) or tonumber(zb.MaxKarma) or 150
                elseif zb and zb.MaxKarma then
                    pMax = tonumber(zb.MaxKarma) or 150
                end
                local label = string.format("%s (%s) — %s / %s", p:Nick(), p:SteamID64(), tostring(math.Round(tonumber(k) or 0)), tostring(pMax))
                playerSelect:AddChoice(label, p)
            end
        end

        refreshPlayers()

        local bottomRow = vgui.Create("DPanel", frame)
        bottomRow:Dock(BOTTOM)
        bottomRow:DockMargin(8, 0, 8, 8)
        bottomRow:SetTall(32)
        bottomRow.Paint = nil

        local toggleBtn = vgui.Create("DButton", bottomRow)
        toggleBtn:Dock(RIGHT)
        toggleBtn:SetWide(150)
        toggleBtn:DockMargin(0, 0, 6, 0)
        toggleBtn:SetText("Toggle Karma System")
        StyleElement(toggleBtn)
        toggleBtn.DoClick = function()
            net.Start("hg_admin_karma")
                net.WriteString("toggle")
                net.WriteBool(hideAnnouncements)
            net.SendToServer()
        end

        local refreshBtn = vgui.Create("DButton", bottomRow)
        refreshBtn:Dock(RIGHT)
        refreshBtn:SetWide(140)
        refreshBtn:SetText("Refresh Players")
        StyleElement(refreshBtn)
        refreshBtn.DoClick = function()
            refreshPlayers()
        end

        local hideChk = vgui.Create("DCheckBoxLabel", bottomRow)
        hideChk:Dock(LEFT)
        hideChk:SetText("Hide announcements")
        hideChk:SetConVar("")
        hideChk:SetValue(false)
        hideChk:SizeToContents()
        hideChk:DockMargin(4, 6, 0, 6)
        hideChk.OnChange = function(_, val)
            hideAnnouncements = val
        end

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(8, 0, 8, 6)
        StyleElement(scroll, Color(30, 30, 30, 200))

        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(8, 8, 8, 6)
        row:SetTall(28)
        row.Paint = nil

        local karmaEntry = vgui.Create("DTextEntry", row)
        karmaEntry:Dock(FILL)
        karmaEntry:SetTall(28)
        karmaEntry:SetPlaceholderText("Karma amount (-60 to " .. tostring(maxKarma) .. ")")
        karmaEntry:SetUpdateOnType(true)

        local function getTargetMode()
            return selectedTargetMode or "player"
        end

        local function getSelectedSid64()
            return selectedPlayer
        end

        local function applySetKarma(value)
            local mode = getTargetMode()
            if mode == "none" then return end

            value = tonumber(value)
            if not value then return end
            value = math.Clamp(value, -60, maxKarma)

            if mode == "self" then
                net.Start("hg_admin_karma")
                    net.WriteString("set")
                    net.WriteBool(false)
                    net.WriteFloat(value)
                    net.WriteEntity(LocalPlayer())
                    net.WriteBool(hideAnnouncements)
                net.SendToServer()
                return
            end

            if mode == "all" then
                net.Start("hg_admin_karma")
                    net.WriteString("set")
                    net.WriteBool(true)
                    net.WriteFloat(value)
                    net.WriteBool(hideAnnouncements)
                net.SendToServer()
                return
            end

            local ent = getSelectedSid64()
            if not IsValid(ent) then return end
            net.Start("hg_admin_karma")
                net.WriteString("set")
                net.WriteBool(false)
                net.WriteFloat(value)
                net.WriteEntity(ent)
                net.WriteBool(hideAnnouncements)
            net.SendToServer()
        end

        local function applyResetKarma()
            local mode = getTargetMode()
            if mode == "none" then return end

            if mode == "self" then
                net.Start("hg_admin_karma")
                    net.WriteString("reset")
                    net.WriteBool(false)
                    net.WriteEntity(LocalPlayer())
                    net.WriteBool(hideAnnouncements)
                net.SendToServer()
                return
            end

            if mode == "all" then
                net.Start("hg_admin_karma")
                    net.WriteString("reset")
                    net.WriteBool(true)
                    net.WriteBool(hideAnnouncements)
                net.SendToServer()
                return
            end

            local ent = getSelectedSid64()
            if not IsValid(ent) then return end
            net.Start("hg_admin_karma")
                net.WriteString("reset")
                net.WriteBool(false)
                net.WriteEntity(ent)
                net.WriteBool(hideAnnouncements)
            net.SendToServer()
        end

        local function addActionButton(text, onClick)
            local btn = vgui.Create("DButton", scroll)
            btn:SetText(text)
            btn:Dock(TOP)
            btn:DockMargin(8, 0, 8, 8)
            btn:SetTall(34)
            StyleElement(btn)
            btn.DoClick = onClick
            return btn
        end

        addActionButton("Set To Amount", function()
            applySetKarma(karmaEntry:GetValue())
        end)

        addActionButton("Set Max (" .. tostring(maxKarma) .. ")", function()
            applySetKarma(maxKarma)
        end)

        addActionButton("Reset (" .. tostring(maxKarma) .. ")", function()
            applyResetKarma()
        end)

        addActionButton("Set To 0 (Ban risk)", function()
            applySetKarma(0)
        end)

        local function updateEnabled()
            local mode = getTargetMode()
            local needsPlayer = mode == "player"
            playerSelect:SetEnabled(needsPlayer)
            playerSelect:SetAlpha(needsPlayer and 255 or 80)
        end

        updateEnabled()
    end

    local function OpenKarmaSettingsMenu()
        if IsValid(karmaCfgOpenPanel) then
            karmaCfgOpenPanel:Close()
        end

        local frame = vgui.Create("ZFrame")
        frame:SetSize(650, 640)
        frame:Center()
        frame:SetTitle("Karma Settings")
        frame:MakePopup()
        karmaCfgOpenPanel = frame

        frame.OnClose = function()
            if karmaCfgOpenPanel == frame then
                karmaCfgOpenPanel = nil
            end
        end

        local editing = {
            MaxKarma = tonumber(karmaCfgCache.MaxKarma) or 150,
            Groups = table.Copy(karmaCfgCache.GroupMaxKarma or {}),
            Players = table.Copy(karmaCfgCache.PlayerMaxKarma or {})
        }

        -- Top People Karma
        local top = vgui.Create("DPanel", frame)
        top:Dock(TOP)
        top:DockMargin(8, 8, 8, 6)
        top:SetTall(72)
        StyleElement(top, Color(30, 30, 30, 200))

        local row1 = vgui.Create("DPanel", top)
        row1:Dock(TOP)
        row1:SetTall(32)
        row1:DockMargin(0, 6, 0, 2)
        row1.Paint = nil

        local lbl = vgui.Create("DLabel", row1)
        lbl:Dock(LEFT)
        lbl:DockMargin(12, 6, 8, 6)
        lbl:SetWide(150)
        lbl:SetText("Global Max Karma:")
        lbl:SetTextColor(Color(235, 235, 235))

        local maxEntry = vgui.Create("DTextEntry", row1)
        maxEntry:Dock(LEFT)
        maxEntry:SetWide(100)
        maxEntry:DockMargin(0, 2, 8, 2)
        maxEntry:SetText(tostring(editing.MaxKarma))
        maxEntry:SetNumeric(true)
        maxEntry:SetUpdateOnType(true)
        maxEntry.OnChange = function(self)
            editing.MaxKarma = tonumber(self:GetValue()) or editing.MaxKarma
        end

        local info = vgui.Create("DLabel", top)
        info:Dock(TOP)
        info:DockMargin(14, 2, 12, 4)
        info:SetTall(18)
        info:SetText("Priority order: Player-Specific → ULX Group → Global default.")
        info:SetTextColor(Color(185, 185, 185))

        -- ====================
        -- SECTION 1: Groups (scrollable)
        -- ====================
        local groupsWrap = vgui.Create("DPanel", frame)
        groupsWrap:Dock(TOP)
        groupsWrap:DockMargin(8, 0, 8, 6)
        groupsWrap:SetTall(200)
        groupsWrap.Paint = nil

        local groupsHeader = vgui.Create("DPanel", groupsWrap)
        groupsHeader:Dock(TOP)
        groupsHeader:SetTall(30)
        groupsHeader.Paint = nil

        local ghLbl = vgui.Create("DLabel", groupsHeader)
        ghLbl:Dock(LEFT)
        ghLbl:DockMargin(4, 6, 8, 4)
        ghLbl:SetWide(260)
        ghLbl:SetText("ULX Group Max Karma Overrides:")
        ghLbl:SetTextColor(Color(230, 230, 230))

        local addGroupBtn = vgui.Create("DButton", groupsHeader)
        addGroupBtn:Dock(RIGHT)
        addGroupBtn:SetWide(100)
        addGroupBtn:DockMargin(4, 2, 4, 2)
        addGroupBtn:SetText("+ Add Group")
        StyleElement(addGroupBtn)

        local groupsScroll = vgui.Create("DScrollPanel", groupsWrap)
        groupsScroll:Dock(FILL)
        groupsScroll:DockMargin(0, 2, 0, 0)
        StyleElement(groupsScroll, Color(30, 30, 30, 200))

        local function rebuildGroupRows()
            groupsScroll:Clear()
            local sorted = {}
            for g, v in pairs(editing.Groups) do table.insert(sorted, {g, v}) end
            table.sort(sorted, function(a, b) return string.lower(a[1]) < string.lower(b[1]) end)
            for _, row in ipairs(sorted) do
                local grpName, grpVal = row[1], row[2]
                local r = vgui.Create("DPanel", groupsScroll)
                r:Dock(TOP)
                r:DockMargin(8, 6, 8, 0)
                r:SetTall(32)
                r.Paint = nil

                local nameEntry = vgui.Create("DTextEntry", r)
                nameEntry:Dock(LEFT)
                nameEntry:SetWide(230)
                nameEntry:DockMargin(0, 2, 6, 2)
                nameEntry:SetText(grpName)
                nameEntry:SetPlaceholderText("group name (e.g. superadmin)")
                nameEntry.OnChange = function(self)
                    local new = self:GetValue()
                    if new == grpName then return end
                    editing.Groups[grpName] = nil
                    grpName = new
                    if new and new ~= "" then
                        editing.Groups[new] = tonumber(grpVal) or 150
                    end
                end

                local valEntry = vgui.Create("DTextEntry", r)
                valEntry:Dock(LEFT)
                valEntry:SetWide(110)
                valEntry:DockMargin(0, 2, 6, 2)
                valEntry:SetText(tostring(grpVal))
                valEntry:SetNumeric(true)
                valEntry:SetPlaceholderText("max karma")
                valEntry.OnChange = function(self)
                    local v = tonumber(self:GetValue()) or 150
                    grpVal = v
                    if grpName and grpName ~= "" then editing.Groups[grpName] = v end
                end

                local del = vgui.Create("DButton", r)
                del:Dock(LEFT)
                del:SetWide(70)
                del:DockMargin(0, 2, 0, 2)
                del:SetText("Remove")
                StyleElement(del)
                del.DoClick = function()
                    editing.Groups[grpName] = nil
                    rebuildGroupRows()
                end
            end
        end

        addGroupBtn.DoClick = function()
            local freeName = "newgroup"
            local i = 1
            while editing.Groups[freeName] do
                freeName = "newgroup" .. i
                i = i + 1
            end
            editing.Groups[freeName] = 150
            rebuildGroupRows()
        end

        rebuildGroupRows()

        -- ====================
        -- SECTION 2: Players (scrollable + add by SteamID OR by online player)
        -- ====================
        local playersWrap = vgui.Create("DPanel", frame)
        playersWrap:Dock(FILL)
        playersWrap:DockMargin(8, 0, 8, 6)
        playersWrap.Paint = nil

        local playersHeader = vgui.Create("DPanel", playersWrap)
        playersHeader:Dock(TOP)
        playersHeader:SetTall(64)
        playersHeader.Paint = nil

        local phRow1 = vgui.Create("DPanel", playersHeader)
        phRow1:Dock(TOP)
        phRow1:SetTall(30)
        phRow1.Paint = nil

        local phLbl = vgui.Create("DLabel", phRow1)
        phLbl:Dock(LEFT)
        phLbl:DockMargin(4, 6, 8, 4)
        phLbl:SetWide(280)
        phLbl:SetText("Player-Specific Max Karma Overrides:")
        phLbl:SetTextColor(Color(230, 230, 230))

        local addPlayerBtn = vgui.Create("DButton", phRow1)
        addPlayerBtn:Dock(RIGHT)
        addPlayerBtn:SetWide(140)
        addPlayerBtn:DockMargin(4, 2, 4, 2)
        addPlayerBtn:SetText("+ Add by SteamID…")
        StyleElement(addPlayerBtn)

        local onlineBtn = vgui.Create("DButton", phRow1)
        onlineBtn:Dock(RIGHT)
        onlineBtn:SetWide(160)
        onlineBtn:DockMargin(4, 2, 4, 2)
        onlineBtn:SetText("Select Online Player…")
        StyleElement(onlineBtn)

        local phRow2 = vgui.Create("DPanel", playersHeader)
        phRow2:Dock(TOP)
        phRow2:DockMargin(0, 4, 0, 0)
        phRow2:SetTall(26)
        phRow2.Paint = nil

        local col1 = vgui.Create("DLabel", phRow2)
        col1:Dock(LEFT)
        col1:DockMargin(8, 4, 8, 4)
        col1:SetWide(230)
        col1:SetText("SteamID64 (or pick online player)")
        col1:SetTextColor(Color(200, 200, 200))

        local col2 = vgui.Create("DLabel", phRow2)
        col2:Dock(LEFT)
        col2:DockMargin(0, 4, 8, 4)
        col2:SetWide(110)
        col2:SetText("Max Karma")
        col2:SetTextColor(Color(200, 200, 200))

        local playersScroll = vgui.Create("DScrollPanel", playersWrap)
        playersScroll:Dock(FILL)
        playersScroll:DockMargin(0, 4, 0, 0)
        StyleElement(playersScroll, Color(30, 30, 30, 200))

        local function playerLabelForSid(sid)
            local nick = nil
            for _, p in ipairs(player.GetHumans()) do
                if IsValid(p) and p.SteamID64 and p:SteamID64() == sid then
                    nick = p:Nick()
                    break
                end
            end
            return nick and string.format("%s (%s)", nick, sid) or sid
        end

        local function rebuildPlayerRows()
            playersScroll:Clear()
            local sorted = {}
            for s, v in pairs(editing.Players) do table.insert(sorted, {s, v}) end
            table.sort(sorted, function(a, b) return playerLabelForSid(a[1]) < playerLabelForSid(b[1]) end)
            for _, row in ipairs(sorted) do
                local sid, pVal = row[1], row[2]
                local r = vgui.Create("DPanel", playersScroll)
                r:Dock(TOP)
                r:DockMargin(8, 6, 8, 0)
                r:SetTall(32)
                r.Paint = nil

                local sidEntry = vgui.Create("DTextEntry", r)
                sidEntry:Dock(LEFT)
                sidEntry:SetWide(230)
                sidEntry:DockMargin(0, 2, 6, 2)
                sidEntry:SetText(sid)
                sidEntry:SetPlaceholderText("SteamID64")
                sidEntry.OnChange = function(self)
                    local new = self:GetValue()
                    if new == sid then return end
                    editing.Players[sid] = nil
                    sid = new
                    if new and new ~= "" then
                        editing.Players[new] = tonumber(pVal) or 150
                    end
                end
                -- Show the player's nick (if online) in tooltip for quick verification
                local nickShown = nil
                for _, p in ipairs(player.GetHumans()) do
                    if IsValid(p) and p.SteamID64 and p:SteamID64() == sid then
                        nickShown = p:Nick()
                        break
                    end
                end
                if nickShown then
                    sidEntry:SetTooltip("Currently online as: " .. nickShown)
                end

                local valEntry = vgui.Create("DTextEntry", r)
                valEntry:Dock(LEFT)
                valEntry:SetWide(110)
                valEntry:DockMargin(0, 2, 6, 2)
                valEntry:SetText(tostring(pVal))
                valEntry:SetNumeric(true)
                valEntry:SetPlaceholderText("max karma")
                valEntry.OnChange = function(self)
                    local v = tonumber(self:GetValue()) or 150
                    pVal = v
                    if sid and sid ~= "" then editing.Players[sid] = v end
                end

                local del = vgui.Create("DButton", r)
                del:Dock(LEFT)
                del:SetWide(70)
                del:DockMargin(0, 2, 0, 2)
                del:SetText("Remove")
                StyleElement(del)
                del.DoClick = function()
                    editing.Players[sid] = nil
                    rebuildPlayerRows()
                end
            end
        end

        addPlayerBtn.DoClick = function()
            Derma_StringRequest(
                "Add Player Karma Override",
                "Enter the player's SteamID64 (or SteamID — will be converted):",
                "76561198000000000",
                function(text)
                    local raw = string.Trim(text or "")
                    if raw == "" then return end
                    -- Accept STEAM_0 or modern SteamID and convert to SteamID64 if possible
                    local sid64 = raw
                    if string.StartWith(string.lower(raw), "steam_") then
                        if util.SteamIDTo64 then
                            local c = util.SteamIDTo64(raw)
                            if c and c ~= "" and c ~= "0" then sid64 = c end
                        end
                    end
                    if editing.Players[sid64] then
                        Derma_Message("This player is already in the list. Edit the existing row instead.", "Already Added", "OK")
                        return
                    end
                    editing.Players[sid64] = 150
                    rebuildPlayerRows()
                end,
                function() end,
                "Add",
                "Cancel"
            )
        end

        onlineBtn.DoClick = function()
            -- Show panel of current connected idiots here
            local pm = vgui.Create("ZFrame")
            pm:SetSize(520, 380)
            pm:Center()
            pm:SetTitle("Select Online Player")
            pm:MakePopup()

            local list = vgui.Create("DListView", pm)
            list:Dock(FILL)
            list:DockMargin(8, 8, 8, 6)
            list:AddColumn("Name"):SetFixedWidth(200)
            list:AddColumn("SteamID64")
            list:AddColumn("Group"):SetFixedWidth(100)
            StyleElement(list, Color(30, 30, 30, 200))

            local humans = player.GetHumans()
            table.sort(humans, function(a, b) return string.lower(a:Nick()) < string.lower(b:Nick()) end)
            for _, p in ipairs(humans) do
                if IsValid(p) and p.SteamID64 then
                    local sid64 = p:SteamID64() or ""
                    local grp = (p.GetUserGroup and p:GetUserGroup()) or ""
                    local line = list:AddLine(p:Nick(), sid64, grp)
                    line.SteamID64 = sid64
                    line.Player = p
                end
            end

            local btns = vgui.Create("DPanel", pm)
            btns:Dock(BOTTOM)
            btns:DockMargin(8, 0, 8, 8)
            btns:SetTall(34)
            btns.Paint = nil

            local cancel = vgui.Create("DButton", btns)
            cancel:Dock(RIGHT)
            cancel:SetWide(100)
            cancel:DockMargin(4, 2, 4, 2)
            cancel:SetText("Cancel")
            StyleElement(cancel)
            cancel.DoClick = function() pm:Close() end

            local pick = vgui.Create("DButton", btns)
            pick:Dock(RIGHT)
            pick:SetWide(120)
            pick:DockMargin(4, 2, 4, 2)
            pick:SetText("Add Selected")
            StyleElement(pick)

            local function doPick()
                local linePanel = nil
                local selLines = list:GetSelected()
                if istable(selLines) and #selLines >= 1 then
                    for _, l in ipairs(selLines) do
                        if ispanel(l) and l.SteamID64 then
                            linePanel = l
                            break
                        end
                    end
                end
                if not ispanel(linePanel) or not linePanel.SteamID64 then return end
                local sid64 = linePanel.SteamID64
                if editing.Players[sid64] then
                    Derma_Message("This player is already in the list. Edit the existing row instead.", "Already Added", "OK")
                    return
                end
                editing.Players[sid64] = 150
                rebuildPlayerRows()
                pm:Close()
            end
            pick.DoClick = doPick
            list.DoDoubleClick = function(self, lineID, line)
                if ispanel(line) and line.SteamID64 then
                    list:SelectItem(line)
                    doPick()
                end
            end
        end

        rebuildPlayerRows()

        function frame:RefreshFromCache()
            if not IsValid(self) then return end
            editing.MaxKarma = tonumber(karmaCfgCache.MaxKarma) or 150
            editing.Groups = table.Copy(karmaCfgCache.GroupMaxKarma or {})
            editing.Players = table.Copy(karmaCfgCache.PlayerMaxKarma or {})
            if IsValid(maxEntry) then
                maxEntry:SetText(tostring(editing.MaxKarma))
            end
            rebuildGroupRows()
            rebuildPlayerRows()
        end

        -- Bottom: Save / Reset
        local bottom = vgui.Create("DPanel", frame)
        bottom:Dock(BOTTOM)
        bottom:DockMargin(8, 0, 8, 8)
        bottom:SetTall(36)
        bottom.Paint = nil

        local resetBtn = vgui.Create("DButton", bottom)
        resetBtn:Dock(LEFT)
        resetBtn:SetWide(160)
        resetBtn:DockMargin(0, 0, 6, 0)
        resetBtn:SetText("Reset to Defaults")
        StyleElement(resetBtn)
        resetBtn.DoClick = function()
            Derma_Query("Reset ALL karma settings to defaults? (MaxKarma=150, clear group & player overrides)",
                "Confirm Reset",
                "Reset All", function()
                    net.Start("hg_admin_karma_settings")
                        net.WriteString("reset")
                    net.SendToServer()
                end,
                "Cancel", function() end)
        end

        local saveBtn = vgui.Create("DButton", bottom)
        saveBtn:Dock(RIGHT)
        saveBtn:SetWide(160)
        saveBtn:SetText("Save Changes")
        StyleElement(saveBtn)
        saveBtn.DoClick = function()
            local newMax = math.max(tonumber(editing.MaxKarma) or 150, 100)
            local cleanedGroups = {}
            for g, v in pairs(editing.Groups) do
                if g and g ~= "" then
                    cleanedGroups[tostring(g)] = math.max(tonumber(v) or 150, 100)
                end
            end
            local cleanedPlayers = {}
            for s, v in pairs(editing.Players) do
                if s and s ~= "" then
                    cleanedPlayers[tostring(s)] = math.max(tonumber(v) or 150, 100)
                end
            end
            net.Start("hg_admin_karma_settings")
                net.WriteString("save")
                net.WriteFloat(newMax)
                local gkeys = table.GetKeys(cleanedGroups)
                net.WriteUInt(#gkeys, 16)
                for _, g in ipairs(gkeys) do
                    net.WriteString(tostring(g))
                    net.WriteFloat(tonumber(cleanedGroups[g]) or 150)
                end
                local pkeys = table.GetKeys(cleanedPlayers)
                net.WriteUInt(#pkeys, 16)
                for _, s in ipairs(pkeys) do
                    net.WriteString(tostring(s))
                    net.WriteFloat(tonumber(cleanedPlayers[s]) or 150)
                end
            net.SendToServer()
        end

        if not karmaCfgSyncedOnce then
            net.Start("hg_admin_karma_settings")
                net.WriteString("request")
            net.SendToServer()
        end
    end

    local function OpenModeChancesMenu()
        local frame = vgui.Create("ZFrame")
        frame:SetSize(700, 560)
        frame:Center()
        frame:SetTitle("Mode Chances")
        frame:MakePopup()

        local edited = {}
        local rows = {}

        local top = vgui.Create("DPanel", frame)
        top:Dock(TOP)
        top:DockMargin(8, 8, 8, 6)
        top:SetTall(64)
        StyleElement(top, Color(30, 30, 30, 200))

        local searchBar = vgui.Create("DTextEntry", top)
        searchBar:Dock(TOP)
        searchBar:DockMargin(8, 8, 8, 6)
        searchBar:SetTall(24)
        searchBar:SetPlaceholderText("Search modes...")

        local totalLabel = vgui.Create("DLabel", top)
        totalLabel:Dock(TOP)
        totalLabel:DockMargin(8, 0, 8, 8)
        totalLabel:SetFont("DermaDefault")
        totalLabel:SetTextColor(Color(180, 180, 180))
        totalLabel:SetText("")

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(8, 0, 8, 6)
        StyleElement(scroll, Color(30, 30, 30, 200))

        local bottom = vgui.Create("DPanel", frame)
        bottom:Dock(BOTTOM)
        bottom:DockMargin(8, 0, 8, 8)
        bottom:SetTall(36)
        bottom.Paint = nil

        local function getModeChance(mode)
            if edited[mode.key] ~= nil then
                return edited[mode.key]
            end
            return tonumber(mode.chance) or 0
        end

        local function computeTotal()
            local total = 0
            for _, mode in ipairs(zb.availableModes or {}) do
                if mode.chanceCanChange then
                    local v = getModeChance(mode)
                    if v > 0 then
                        total = total + v
                    end
                end
            end
            return total
        end

        local function updatePercents()
            local total = computeTotal()
            totalLabel:SetText("Total weight: " .. string.format("%.3f", total))
            for _, row in ipairs(rows) do
                if row.UpdatePercent then
                    row:UpdatePercent(total)
                end
            end
        end

        local function rebuild()
            scroll:Clear()
            rows = {}

            local filter = string.Trim(string.lower(searchBar:GetValue() or ""))

            local modes = table.Copy(zb.availableModes or {})
            table.sort(modes, function(a, b)
                return string.lower(a.name or a.key or "") < string.lower(b.name or b.key or "")
            end)

            for _, mode in ipairs(modes) do
                local displayName = tostring(mode.name or mode.key or "")
                local keyName = tostring(mode.key or "")
                local check = string.lower(displayName .. " " .. keyName)
                if filter ~= "" and not string.find(check, filter, 1, true) then
                    continue
                end

                local row = vgui.Create("DPanel", scroll)
                row:SetTall(34)
                row:Dock(TOP)
                row:DockMargin(8, 8, 8, 0)
                StyleElement(row, Color(40, 40, 40, 200))

                local nameLabel = vgui.Create("DLabel", row)
                nameLabel:Dock(FILL)
                nameLabel:DockMargin(10, 0, 0, 0)
                nameLabel:SetFont("DermaDefaultBold")
                nameLabel:SetTextColor(Color(255, 255, 255))
                nameLabel:SetText(displayName .. " (" .. keyName .. ")")

                local percentLabel = vgui.Create("DLabel", row)
                percentLabel:Dock(RIGHT)
                percentLabel:SetWide(90)
                percentLabel:SetFont("DermaDefault")
                percentLabel:SetTextColor(Color(180, 180, 180))
                percentLabel:SetContentAlignment(6)
                percentLabel:SetText("")

                local chanceWang = vgui.Create("DNumberWang", row)
                chanceWang:Dock(RIGHT)
                chanceWang:DockMargin(8, 6, 8, 6)
                chanceWang:SetWide(120)
                chanceWang:SetMin(0)
                chanceWang:SetMax(9999)
                chanceWang:SetDecimals(3)
                chanceWang:SetValue(getModeChance(mode))
                chanceWang:SetEnabled(mode.chanceCanChange and true or false)
                chanceWang:SetAlpha(mode.chanceCanChange and 255 or 80)

                row.UpdatePercent = function(self, total)
                    local v = getModeChance(mode)
                    local pct = (total > 0 and (v / total * 100)) or 0
                    percentLabel:SetText(string.format("%.2f%%", pct))
                end

                chanceWang.OnValueChanged = function(_, val)
                    edited[mode.key] = tonumber(val) or 0
                    updatePercents()
                end

                rows[#rows + 1] = row
            end

            updatePercents()
        end

        searchBar.OnChange = function()
            rebuild()
        end

        local applyBtn = vgui.Create("DButton", bottom)
        applyBtn:Dock(LEFT)
        applyBtn:SetWide(140)
        applyBtn:SetText("Apply")
        StyleElement(applyBtn)
        applyBtn.DoClick = function()
            local changed = 0
            for key, value in pairs(edited) do
                RunConsoleCommand("zb_setmodechance", key, tostring(value))
                changed = changed + 1
            end

            net.Start("ZB_RequestRoundList")
            net.SendToServer()

            if changed > 0 then
                chat.AddText(Color(0, 255, 0), "Updated mode chances (" .. tostring(changed) .. ").")
            else
                chat.AddText(Color(255, 165, 0), "No changes to apply.")
            end
        end

        local saveBtn = vgui.Create("DButton", bottom)
        saveBtn:Dock(LEFT)
        saveBtn:DockMargin(8, 0, 0, 0)
        saveBtn:SetWide(140)
        saveBtn:SetText("Save")
        StyleElement(saveBtn)
        saveBtn.DoClick = function()
            RunConsoleCommand("zb_savemodeschances")
            chat.AddText(Color(0, 255, 0), "Saved mode chances.")
        end

        local rerollBtn = vgui.Create("DButton", bottom)
        rerollBtn:Dock(LEFT)
        rerollBtn:DockMargin(8, 0, 0, 0)
        rerollBtn:SetWide(180)
        rerollBtn:SetText("Reroll Queue")
        StyleElement(rerollBtn)
        rerollBtn.DoClick = function()
            RunConsoleCommand("zb_rerollchances")
            net.Start("ZB_RequestRoundList")
            net.SendToServer()
            chat.AddText(Color(0, 255, 0), "Rerolled the game mode queue.")
        end

        net.Start("ZB_RequestRoundList")
        net.SendToServer()

        rebuild()
    end

    local function OpenAdminMenu()
        if IsValid(isMenuOpen) then return end

        isMenuOpen = vgui.Create("ZFrame")
        local frame = isMenuOpen
        frame:SetSize(300, 260)
        frame:Center()
        frame:SetTitle("Admin Panel")
        frame:MakePopup()

        local setModeBtn = vgui.Create("DButton", frame)
        setModeBtn:SetText("Set Next Mode")
        setModeBtn:Dock(TOP)
        setModeBtn:DockMargin(5, 10, 5, 2)
        setModeBtn:SetSize(300, 40)
        StyleElement(setModeBtn)
        setModeBtn.DoClick = function()
            OpenModeSelection("setmode") 
        end

        local setForceModeBtn = vgui.Create("DButton", frame)
        setForceModeBtn:SetText("Set Auto Next Mode")
        setForceModeBtn:Dock(TOP)
        setForceModeBtn:DockMargin(5, 2, 5, 2)
        setForceModeBtn:SetSize(300, 40)
        StyleElement(setForceModeBtn)
        setForceModeBtn.DoClick = function()
            OpenModeSelection("setforcemode")
        end
        
        local queueModeBtn = vgui.Create("DButton", frame)
        queueModeBtn:SetText("Manage Game Mode Queue")
        queueModeBtn:Dock(TOP)
        queueModeBtn:DockMargin(5, 2, 5, 2)
        queueModeBtn:SetSize(300, 40)
        StyleElement(queueModeBtn)
        queueModeBtn.DoClick = function()
            OpenModeSelection("queue")
        end

        local queueModeGearBtn = vgui.Create("DImageButton", queueModeBtn)
        queueModeGearBtn:SetSize(16, 16)
        queueModeGearBtn:SetImage("icon16/cog.png")
        queueModeGearBtn:SetTooltip("Change mode chances")
        queueModeGearBtn.DoClick = function()
            OpenModeChancesMenu()
        end
        queueModeGearBtn.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 30)
                surface.DrawRect(0, 0, w, h)
            end
        end
        local oldQueueModePerformLayout = queueModeBtn.PerformLayout
        queueModeBtn.PerformLayout = function(self)
            if oldQueueModePerformLayout then
                oldQueueModePerformLayout(self)
            end
            local w, h = self:GetSize()
            queueModeGearBtn:SetPos(w - 26, math.floor((h - 16) / 2))
        end
        queueModeBtn:InvalidateLayout(true)

        local karmaBtn = vgui.Create("DButton", frame)
        karmaBtn:SetText("Manage Karma")
        karmaBtn:Dock(TOP)
        karmaBtn:DockMargin(5, 2, 5, 2)
        karmaBtn:SetSize(300, 40)
        StyleElement(karmaBtn)
        karmaBtn.DoClick = function()
            OpenKarmaMenu()
        end

        local karmaGearBtn = vgui.Create("DImageButton", karmaBtn)
        karmaGearBtn:SetSize(16, 16)
        karmaGearBtn:SetImage("icon16/cog.png")
        karmaGearBtn:SetTooltip("Karma settings: global max & per-group caps")
        karmaGearBtn.DoClick = function()
            OpenKarmaSettingsMenu()
        end
        karmaGearBtn.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 30)
                surface.DrawRect(0, 0, w, h)
            end
        end
        local oldKarmaPerformLayout = karmaBtn.PerformLayout
        karmaBtn.PerformLayout = function(self)
            if oldKarmaPerformLayout then
                oldKarmaPerformLayout(self)
            end
            local w, h = self:GetSize()
            karmaGearBtn:SetPos(w - 26, math.floor((h - 16) / 2))
        end
        karmaBtn:InvalidateLayout(true)

        local endRoundBtn = vgui.Create("DButton", frame)
        endRoundBtn:SetText("End Round")
        endRoundBtn:Dock(TOP)
        endRoundBtn:DockMargin(5, 2, 5, 2)
        endRoundBtn:SetSize(300, 40)
        StyleElement(endRoundBtn)
        endRoundBtn.DoClick = function()
			net.Start("AdminEndRound")
			net.SendToServer()
			frame:Close()
        end

        frame.OnClose = function()
            isMenuOpen = false
        end
        frame:InvalidateLayout(true)
        frame:SizeToChildren(false, true)
    end
    

    hook.Add("InitPostEntity", "RequestModeData", function()
        if LocalPlayer():IsAdmin() then
            timer.Simple(2, function()
                net.Start("ZB_RequestRoundList")
                net.SendToServer()
            end)
        end
    end)

    local f6Key = KEY_F6

    hook.Add("PlayerButtonDown", "OpenAdminMenuF6", function(ply, key)
        if key == f6Key and LocalPlayer():IsAdmin() and not IsValid(isMenuOpen) then
            OpenAdminMenu()
        end
    end)
end
