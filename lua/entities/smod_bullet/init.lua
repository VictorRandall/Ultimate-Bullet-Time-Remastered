AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.LastUpdate = 0
ENT.Accumulator = 0

ENT.think = false

local style = GetConVar("utb_tracer_style")
local feedback = GetConVar("utb_bulletfeedback")

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    
    self:SetModel("models/weapons/w_pbullet1.mdl") 
    self:SetMaterial("models/weapons/bullets/bullet_9mm")
    self:SetColor(Color(201, 157, 72, 255))
    
    local style_idx = style:GetInt()
    local effect = "bulletrail_grey"
    if style_idx == 1 then effect = "bulletrail_smod" 
    elseif style_idx == 2 then effect = "bulletrail_matrix" end
    
    ParticleEffectAttach(effect, PATTACH_ABSORIGIN_FOLLOW, self, 0)
    
    self:SetNWVector("BulletPos", self:GetPos())
    self:SetNWVector("BulletDir", self.Dir)
    self:SetNWFloat("BulletSpeed", self.Speed)
    
    self.LastUpdate = CurTime()
    
    print("shot bulllt server side")
    print(CurTime())
    
--    print("first move")
--	local hit = self:MoveBullet()
end

function ENT:Think()
	if not self.think then
		print("first think")
		print(CurTime())
		self.think = true
	end
	
    if !IsValid(self.Firer) then self:Remove() return end
	
	self:SetNWVector("BulletPos", self:GetPos())
	
	local now = CurTime()
	local frameTime = now - self.LastUpdate
	self.LastUpdate = now
	
	self.Accumulator = self.Accumulator + frameTime
	
	while (self.Accumulator >= self.FixedTimeStep) do
		local hit = self:MoveBullet()
		
		self.Accumulator = self.Accumulator - self.FixedTimeStep
	end
	
    self:NextThink(CurTime())
    return true
end
