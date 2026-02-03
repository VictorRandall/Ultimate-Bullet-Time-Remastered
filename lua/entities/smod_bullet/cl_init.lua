include("shared.lua")

local ply = LocalPlayer()
ply.SlowMoWhizTime = 0

ENT.LastUpdate = 0
ENT.Accumulator = 0

ENT.Speed = nil
ENT.Dir = nil
ENT.FixedTimeStep = 0.01

function ENT:Initialize()
    self.Speed = self:GetNWFloat("BulletSpeed", 0.1)
	self.Dir = self:GetNWVector("BulletDir", self:GetForward())
	
	print("speed")
	print(self.Speed)
	
	print("dir")
	print(self.Dir)
end

function ENT:Think()
	self.Speed = self:GetNWFloat("BulletSpeed")
	self.Dir = self:GetNWVector("BulletDir")
	

	self.LastUpdate = self.LastUpdate or CurTime()
    self.Accumulator = self.Accumulator or 0
    self.FixedTimeStep = self.FixedTimeStep or 0.01

	local now = CurTime()
	local frameTime = now - self.LastUpdate
	self.LastUpdate = now
	
	self.Accumulator = self.Accumulator + frameTime
	
	while (self.Accumulator >= self.FixedTimeStep) do
		local curPos = self:GetPos()
		local targetPos = curPos + (self.Dir * self.Speed * self.FixedTimeStep)
		
		local tr = util.TraceLine({
            start = curPos,
            endpos = targetPos,
            filter = {self, self.Firer, self:GetOwner(), self:GetParent()},
            mask = MASK_SHOT
        })
		
		if tr.Hit then
			self:SetRenderOrigin(tr.HitPos)
		else
			self:SetRenderOrigin(targetPos)
		end
		
		self.Accumulator = self.Accumulator - self.FixedTimeStep
	end
	
    local ply = LocalPlayer()
    local CT = CurTime()
    
    if CT < ply.SlowMoWhizTime then return end

    if self:GetOwner() == ply then return end

    local myPos = self:GetPos()
    local distSqr = myPos:DistToSqr(ply:GetPos())
	
    -- 192 units is roughly 12 feet in Source units
    local distRange = 192

    if distSqr < (distRange * distRange) then
        local sndNum = math.random(3, 14)
        local sndName = "weapons/fx/nearmiss/bulletLtoR0" .. (sndNum < 10 and "0" or "") .. sndNum .. ".wav"
        
        self:EmitSound(sndName, 70, 100)
        
        ply.SlowMoWhizTime = CT + (0.2 * game.GetTimeScale())
    end
    
    self:SetNextClientThink(CurTime())
    return true
end

function ENT:Draw()
	local curPos = self:GetPos()
	local targetPos = curPos + (self.Dir * self.Speed * FrameTime())
	
	print("render pos")
	print(self:GetRenderOrigin())
	
	self:SetRenderOrigin(targetPos)
	
	self:DrawModel()
end
