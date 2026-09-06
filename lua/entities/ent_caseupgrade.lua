AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Case Upgrade (Base/Custom)"
ENT.Author = "CakeKing64"
ENT.Category = "RE4 Cases"
ENT.Contact = "CakeKing64"
ENT.Purpose = "Upgrading your fine case sir?"
ENT.Spawnable = false

ENT.Model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ENT.CaseSize = {
    1, 1
}


function ENT:Initialize()
    if SERVER then
        self:SetModel( self.Model )
	    self:PhysicsInit( SOLID_VPHYSICS )
	    self:SetMoveType( MOVETYPE_VPHYSICS )
	    self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
        self:SetUseType(SIMPLE_USE)
	    local phys = self:GetPhysicsObject()
	    if phys:IsValid() then
	        phys:Wake()
	    end
    end
end

function ENT:Use(activator)
    if activator:IsPlayer() then
        if self.CaseSize[1] > CaseInv(activator).Size[1] or self.CaseSize[2] >  CaseInv(activator).Size[2] then
            CaseInv(activator).Size[1] = math.max(self.CaseSize[1], CaseInv(activator).Size[1])
            CaseInv(activator).Size[2] = math.max(self.CaseSize[2], CaseInv(activator).Size[2])
            CaseInventory:Sync(activator)
            self:Remove()
        end
    end
end
