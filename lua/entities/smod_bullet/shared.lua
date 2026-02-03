ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Author = "Spy"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BulletDir")
    self:NetworkVar("Float", 1, "BulletSpeed")
    self:NetworkVar("Vector", 2, "BulletPos")
	self:NetworkVar("Bool", 3, "BulletHit")
end

ENT.FixedTimeStep = 0.01
ENT.Hit = false

local style = GetConVar("utb_tracer_style")
local feedback = GetConVar("utb_bulletfeedback")

function ENT:GetImpactSound(mat)
    local sounds = {
        [MAT_CONCRETE] = "bullettime/concrete_impact_bullet"..math.random(1,4)..".wav",
        [MAT_DIRT] = "bullettime/sand_impact_bullet"..math.random(1,4)..".wav",
        [MAT_GRASS] = "bullettime/sand_impact_bullet"..math.random(1,4)..".wav",
        [MAT_SAND] = "bullettime/sand_impact_bullet"..math.random(1,4)..".wav",
        [MAT_FLESH] = "bullettime/flesh_impact_bullet"..math.random(1,5)..".wav",
        [MAT_METAL] = "bullettime/metal_impact_bullet"..math.random(1,9)..".wav",
        [MAT_WOOD] = "bullettime/wood_impact_bullet"..math.random(1,9)..".wav",
        [MAT_GLASS] = "bullettime/glass_impact_bullet"..math.random(1,4)..".wav"
    }
    return sounds[mat] or nil
end

function ENT:HandleBulletCollision(tr)
	if self.Hit then return end
	
	self.Hit = true
	self:SetNWVector("BulletPos", self:GetPos())
	self:SetNWVector("BulletHit", true)
	
    self.BulletData.Src = tr.StartPos
    self.BulletData.Dir = self.Dir
    self.BulletData.Spread = Vector(0, 0, 0)
    self.BulletData.Tracer = 0
    
    self.Firer.DontReFire = true
    self.Firer:FireBullets(self.BulletData)
    
    if feedback:GetBool() then
	    local sound = self:GetImpactSound(tr.MatType)
	    if sound then
	        self:EmitSound(sound, 100, 100)
	    end
	end

    self:Remove()
end

function ENT:MoveBullet()
	if not self.Dir and not self.Speed and self.Hit then return end
	
	local speed = self:GetNWFloat("BulletSpeed", self.Dir)
    local dir = self:GetNWVector("BulletDir", self.Speed) 
	
	local curPos = self:GetPos()
	local targetPos = curPos + (dir * speed * self.FixedTimeStep)
	
	self:SetPos(targetPos)
	
	local tr = util.TraceHull({
		start = curPos,
		endpos = targetPos,
		filter = {self, self.Firer, self:GetOwner(), self:GetParent()},
		mins = Vector(-0.5, -0.5, -0.5),
		maxs = Vector(0.5, 0.5, 0.5),
		mask = MASK_SHOT,
	})
	
	if tr.Hit then
		self:SetPos(tr.HitPos)
		if SERVER then
			self:HandleBulletCollision(tr)
		end
		return true
	end
	
	return false
end
