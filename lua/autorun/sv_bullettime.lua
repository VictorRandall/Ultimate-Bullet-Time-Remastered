local bind
local heartbeat = 0
local currentPitch, currentTime, currentPhys, CurrentBright, CurrentMat, currentGreen, currentAlpha, currentContrast, currentColour = 100, 1, 1, 5, 1, 0, 1, 1, 1
local targetPitch, targetTime, targetPhys, targetBright, targetMat, targetGreen, targetAlpha, targetContrast, targetColour = 100, 1, 1, 1, 1, 1, 1, 1, 1
local pitchLerpSpeed = CreateConVar("utb_lerp_speed", "2", {FCVAR_ARCHIVE, FCVAR_REPLICATED})

local pitch, time, phys = CreateConVar("utb_sound_pitch", "70", {FCVAR_ARCHIVE, FCVAR_REPLICATED}), CreateConVar("utb_timescale", "0.25", {FCVAR_ARCHIVE, FCVAR_REPLICATED}), CreateConVar("utb_phys_timescale", "0.5", {FCVAR_ARCHIVE, FCVAR_REPLICATED})
local bindpanel = CreateClientConVar("utb_panel_bind", 22, true, false)
local screen_effect = CreateClientConVar("utb_screenspace_style", 1, true, false)
local tracer_style = CreateConVar("utb_tracer_style", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("utb_bulletfeedback", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED})

local bullet_ply = CreateConVar("utb_enable_bullet_ply", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED})
local bullet_npc = CreateConVar("utb_enable_bullet_npc", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED})
local bulletspeed_ply = CreateConVar("utb_bulletspeed_ply", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED})
local bulletspeed_npc = CreateConVar("utb_bulletspeed_npc", "0.2667", {FCVAR_ARCHIVE, FCVAR_REPLICATED})

local cooldownTime = CreateConVar("utb_cooldown_time", "1.5", {FCVAR_ARCHIVE, FCVAR_REPLICATED})
local lastToggleTime = 0

local dir, src, num, spread_x, spread_y, spread_z

cvars.AddChangeCallback("utb_screenspace_style", function(convar_name, value_old, value_new)
    if screen_effect:GetInt() == 1 then
        tracer_style:SetInt(1)
    elseif screen_effect:GetInt() == 2 then
        tracer_style:SetInt(2)
    elseif screen_effect:GetInt() == 3 then
        tracer_style:SetInt(0)
    end
end)

if SERVER then
    util.AddNetworkString("BindOnChangeBT")
else
    local inslomo = true

    local function UTB(panel)
        local ply = LocalPlayer()
        if not ply:IsAdmin() then
            return
        end
        panel:Help([[Ultimate Bullet Time Configs]])
        panel:ControlHelp([[]])
        panel:ControlHelp([[]])
        panel:ControlHelp([[]])
        panel:ControlHelp([[]])
        panel:NumSlider("Scale Lerp Value","utb_lerp_speed",1,100,3)
        panel:NumSlider("Scale Timescale","utb_timescale",0,1,3)
        panel:NumSlider("Scale Sound Pitch","utb_sound_pitch",0,100,3)
        panel:NumSlider("Scale Physics Timescale","utb_phys_timescale",0,1,3)
        panel:ControlHelp([[MUST READ WARNING: Firing TOO MANY(more than 30-50)
physical bullets will CRUSH the game if physics timescale is set to 0 due to source physics. 
Just don't fire too many.]])
        panel:CheckBox("Enable Bullets for Player","utb_enable_bullet_ply")
        panel:CheckBox("Enable Bullets for NPC","utb_enable_bullet_npc")
        panel:CheckBox("Enable Slow Bullet Impact Sound","utb_bulletfeedback")
        panel:NumSlider("Player Bullet Speed","utb_bulletspeed_ply",0,1,3)
        panel:NumSlider("NPC Bullet Speed","utb_bulletspeed_npc",0,1,3)
        panel:NumSlider("Choose Bullet Tracer Style","utb_tracer_style",0,3,0)
        panel:ControlHelp([[ 0 = Grey Tracer
1 = SMOD Style Tracer 
2 = The Matrix Tracer]])
        panel:NumSlider("Choose Screenspace Effects","utb_screenspace_style",0,3,0)
        panel:ControlHelp([[0 = No Screenspace Effect
1 = SMOD Style Screenspace 
2 = The Matrix Screenspace
3 = Max Payne Screenspace]])

        local binder = vgui.Create( "DBinder", panel )
        binder:SetSize( 200, 50 )
        binder:SetPos( 50, 50 )

        binder:SetSelectedNumber(bindpanel:GetInt())
        
        function binder:OnChange( num )
            net.Start("BindOnChangeBT")
            net.WriteFloat(num)
            net.SendToServer()
        end
    end

    hook.Add("PopulateToolMenu","UTBUlletTime",function(panel)
        spawnmenu.AddToolMenuOption("Options","Ultimate Bullet Time","cl_bt_configs","Ultimate Bullet Time Options","","",UTB)
    end)

    local function BulletTimeSound(on, off)
        if GetGlobalBool("IsSlowMotionActive") and inslomo then
            inslomo = false
            surface.PlaySound(on)
        elseif !GetGlobalBool("IsSlowMotionActive") and !inslomo then
            inslomo = true
            surface.PlaySound(off)
        end
    end

    hook.Add("HUDPaint", "UTB_HUDPaint", function() 
        if screen_effect:GetInt()==1 then
            BulletTimeSound("bteffect/bullettimeon_smod.wav", "bteffect/bullettimeoff_smod.wav")
        elseif screen_effect:GetInt()==2 then
            BulletTimeSound("bteffect/bullettime_matrixon.wav", "bteffect/bullettime_matrixoff.wav")
        elseif screen_effect:GetInt()==3 then    
            BulletTimeSound("bteffect/bulletime_mpon.mp3", "bteffect/bulletime_mpoff.mp3")
            if CurTime() > heartbeat and GetGlobalBool("IsSlowMotionActive") then 
				surface.PlaySound("bteffect/mp_heartbeat.wav")
				heartbeat = CurTime() + 1
			end
        end
    end)

    local function SMODEffect()
        local mat = Material("effects/bullettime_screenspace")
        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = CurrentBright,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        if GetGlobalBool("IsSlowMotionActive") then
            targetBright = 0
            targetMat = 1
            DrawColorModify( tab )
        else
            targetBright = 5
            targetMat = 0
        end
        if math.Round(CurrentMat, 2) > 0.005 then
            render.SetMaterial(mat)
            render.DrawScreenQuad()
            DrawSharpen( 2, 0.4*CurrentMat)
            mat:SetFloat("$refractamount", CurrentMat*0.1)
            mat:SetVector("$refracttint", Vector(1, 1, 1)*CurrentMat)
        end
        CurrentMat = Lerp(3 * FrameTime(), CurrentMat, targetMat)
        CurrentBright = Lerp(3 * FrameTime(), CurrentBright, targetBright)
    end

    local function MatrixEffect()
        local mat = Material("effects/bullettime_matrix")
        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = currentGreen,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        if GetGlobalBool("IsSlowMotionActive") then
            targetGreen = 0.1
            targetAlpha = 0.5
        else
            targetGreen = 0
            targetAlpha = 0
        end
        if math.Round(currentAlpha, 2) > 0.005 then
            DrawColorModify( tab )
            mat:SetFloat("$alpha", currentAlpha)
            render.SetMaterial(mat)
            render.DrawScreenQuad()
        else
            targetGreen = 1
        end
        currentGreen = Lerp(1 * FrameTime(), currentGreen, targetGreen)
        currentAlpha = Lerp(1 * FrameTime(), currentAlpha, targetAlpha)
    end

    local function MaxPayneEffect()
        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = currentContrast,
            ["$pp_colour_colour"] = currentColour,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        local tab2 = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = currentColour,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        if GetGlobalBool("IsSlowMotionActive") then
            targetContrast = 1
            targetColour = 1.5
            DrawColorModify( tab )
        else
            targetContrast = 0
            targetColour = 1
            if math.Round(currentColour, 2) != 1 then
                DrawColorModify( tab2 )
            end
        end
        currentContrast = Lerp(15 * FrameTime(), currentContrast, targetContrast)
        currentColour = Lerp(5 * FrameTime(), currentColour, targetColour)
    end
    hook.Add("RenderScreenspaceEffects", "PostProcessingUTB", function()
        if screen_effect:GetInt()==1 then
            SMODEffect()
        elseif screen_effect:GetInt()==2 then
            MatrixEffect()
        elseif screen_effect:GetInt()==3 then
            MaxPayneEffect()
        end
    end )
end

concommand.Add("toggle_utb", function()
    if CLIENT then
        local ply = LocalPlayer()

        if not ply:IsAdmin() then
            return
        end
    end
    local CurTime1 = CurTime()

    if (CurTime1 - lastToggleTime) < cooldownTime:GetFloat() then
        return
    end

    if GetGlobalBool("IsSlowMotionActive") then
        SetGlobalBool("IsSlowMotionActive", false)
    else
        SetGlobalBool("IsSlowMotionActive", true)
    end

    lastToggleTime = CurTime1
end)


hook.Add( "PlayerButtonDown", "PlayerButtonDownUTB", function( ply, button )
    net.Receive("BindOnChangeBT", function(len, ply)
        bind = net.ReadFloat()
        bindpanel:SetInt(bind)
    end)
    if button == bindpanel:GetFloat() then
        RunConsoleCommand("toggle_utb")
    end
end)

local function TimeScale(time, phys)
    if SERVER then
        RunConsoleCommand("phys_timescale", phys)
        game.SetTimeScale(time)
    end
end

hook.Add( "InitPostEntity", "InitEntityBTime", function()
    if CLIENT then
	    LocalPlayer().SlowMoWhizTime = 0
    end
end )

hook.Add("Initialize", "BulletTimeParticleUTB", function()
    game.AddParticles("particles/bullettime_particle.pcf")
    PrecacheParticleSystem("bulletrail_smod")
    PrecacheParticleSystem("bulletrail_grey")
    PrecacheParticleSystem("bulletrail_matrix")
end)

hook.Add("Think", "SmoothPitchTransitionUTB", function()
    if GetGlobalBool("IsSlowMotionActive") then
        TimeScale(currentTime, math.Round(currentPhys,1))
        targetPitch = pitch:GetFloat()
        targetTime = time:GetFloat()
        targetPhys = phys:GetFloat()
    else
        if game.GetTimeScale()==1 then
            return
        end
        TimeScale(currentTime, math.Round(currentPhys,1))
        targetPitch = 100
        targetTime = 1
        targetPhys = 1
    end
    currentPitch = Lerp(pitchLerpSpeed:GetFloat() * FrameTime(), currentPitch, targetPitch)
    currentTime = Lerp(pitchLerpSpeed:GetFloat() * FrameTime(), currentTime, targetTime)
    currentPhys = Lerp(pitchLerpSpeed:GetFloat() * FrameTime(), currentPhys, targetPhys)
end)

hook.Add("EntityEmitSound", "UTBSlowMotion", function(t)
    if math.Round(currentPitch,4)!=100 then
        t.Pitch = currentPitch
        return true
    end
end)


hook.Add("PostEntityFireBullets", "UTBFireBulletsSlowmo", function(ent, data)
    if GetGlobalBool("IsSlowMotionActive") then
        if ent.DontReFire then
            ent.DontReFire = false
            return
        end
        
        local function SlowBullets()
            local dir2 
			if num > 1 then
				dir2 = dir + Vector(math.Rand(-spread_x, spread_x), math.Rand(-spread_y, spread_y), math.Rand(-spread_z, spread_z)) * 0.4
			else
				dir2 = dir + Vector(math.Rand(-spread_x, spread_x), math.Rand(-spread_y, spread_y), math.Rand(-spread_z, spread_z)) * 0.25
			end
            local bul = ents.Create("smod_bullet")
            local bulspeed
            bul:SetPos(src + dir2 * 10)
            bul:SetAngles(dir2:Angle())
            bul.Dir = dir2
			bul:SetNWVector("BulletDir", dir2)
            if ent:IsPlayer() then
                if data.Damage <= 25 then
                    bulspeed = (7500 / currentPhys) * bulletspeed_ply:GetFloat()
                else
                    bulspeed = (data.Damage * 100 / currentPhys) * bulletspeed_ply:GetFloat()
                end
            else
                if data.Damage <= 25 then
                    bulspeed = (7500 / currentPhys) * bulletspeed_npc:GetFloat()
                else
                    bulspeed = (data.Damage * 100 / currentPhys) * bulletspeed_npc:GetFloat()
                end
            end
            bul.Speed = bulspeed
			bul:SetNWVector("BulletSpeed", bulspeed)
            bul:SetOwner(ent)
            bul.BulletData = data
            bul.Firer = ent
            bul:Spawn()
            bul:NextThink(CurTime() + 0.01)
        end

        if bullet_ply:GetBool() and ent:IsPlayer() then
            SlowBullets()
            return false
        end
        if bullet_npc:GetBool() and !ent:IsPlayer() then
            SlowBullets()
            return false
        end
    end
end)


hook.Add("EntityFireBullets", "UTBFireBulletsSlowmo", function(ent, data)
    src = data.Src
    num = data.Num
    dir = data.Dir
    spread_x = data.Spread.x
    spread_y = data.Spread.y
    spread_z = data.Spread.z
end)

