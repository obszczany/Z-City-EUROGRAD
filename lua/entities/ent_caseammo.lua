AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Generic Ammo Entity"
ENT.Author = "CakeKing64"
ENT.Contact = "CakeKing64"
ENT.Spawnable = false


ENT.AmmoID = -1
ENT.AmmoCount = 0
ENT.GrenadeInfo = nil

function ENT:Initialize()
end


function ENT:SetInfo(model, ammoID, count)
	if SERVER then
	    self:SetModel( model )
	    self:PhysicsInit( SOLID_VPHYSICS )
	    self:SetMoveType( MOVETYPE_VPHYSICS )
	    self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		self:SetUseType(SIMPLE_USE)

	    local phys = self:GetPhysicsObject()
	    if phys:IsValid() then
	        phys:Wake()
	    end
        self.AmmoID = ammoID
        self.AmmoCount = count
	end
end

function ENT:Use( activator )
    -- Dump all of the ammo onto the player
    if activator:IsPlayer() then
        activator:GiveAmmo(self.AmmoCount, self.AmmoID)
        self:Remove()
    end
end


if not CLIENT then return end


function ENT:Draw()
    self:DrawModel()
end