TOOL.Category = "RE4 Case"
TOOL.Name = "#tool.recase_entity_selector.name"
TOOL.Author = "CakeKing64"
TOOL.Information = {
	{ name = "left" }
}


if CLIENT then
	language.Add("tool.recase_entity_selector.name", "RE4 Case Item Creator")
	language.Add("tool.recase_entity_selector.left", "Select an entity")
	language.Add("tool.recase_entity_selector.desc", "Sets up an entity in the item creator")
end

function TOOL:LeftClick(tr)
	local ent = tr.Entity
	if not IsValid(ent) then
		return false
	end

	-- this sucks actually what is this
	if game.SinglePlayer() and SERVER then
		net.Start("CaseNetMsg")
		net.WriteUInt(CASE_EVENT_SYNC_CUSTOM_ITEMS, 8)
			local printName = ent.PrintName
			if printName == nil then
				printName = ent:GetClass()
			end

			net.WriteBool(true)
			net.WriteString(ent:GetClass())
			net.WriteString(printName)
			net.WriteString(ent:GetModel() or "")
		net.Send(player.GetAll()[1])
	end


	-- This is what it SHOULD be but the above code only runs serverside if singleplayer
	if CLIENT then
		CaseItemCreator.Current.Model = ent:GetModel() or ""
		local printName = ent.PrintName
		if printName == nil then
			printName = ent:GetClass()
		end
		CaseItemCreator.Current.PrintName = printName
		CaseItemCreator:SelectEntity(ent:GetClass())
		return true
	end



	return true
end

function TOOL:RightClick(tr)
	return false
end

function TOOL.BuildCPanel(panel)
	CaseItemCreator.Panel = panel
	CaseItemCreator:Populate(panel)
end