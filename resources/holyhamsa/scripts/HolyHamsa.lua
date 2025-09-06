local this = {}

---@param player EntityPlayer
---@param cacheflags integer
function this:updateHamsa(player)
	if player:HasCollectible(HolyHamsaMod.CollectibleTypeCustom.HOLY_HAMSA) == true then
		local dat = player:GetData()
		if player:GetShootingInput():LengthSquared() ~= 0 then
			dat.Charge =  dat.Charge and  dat.Charge + 1 or 1
		elseif 	dat.Charge and dat.Charge >= 100 and player:GetShootingInput():LengthSquared() == 0 then
			-- print(FireDir)
			local Vel = (player.Velocity / 2) + dat.FireDir * 15
				local Hamsa = Isaac.Spawn(3,HolyHamsaMod.FamiliarVariantCustom.HAMSA.variant,HolyHamsaMod.FamiliarVariantCustom.HAMSA.subType,player.Position,Vel,player):ToFamiliar()
				Hamsa.TargetPosition = Vel
				local cloud  = Isaac.Spawn(1000,16,5,player.Position,Vector.Zero,player):ToEffect()
				cloud.Color = Color(0,0,0,1)
				cloud.SpriteScale = Vector(0.5,-0.5)
				cloud.DepthOffset = -100
				dat.Charge = 0
				SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
				SFXManager():Play(701)
				Game():ShakeScreen(5)
		else
			Isaac.CreateTimer(function ()
				if player:GetShootingInput():LengthSquared() == 0 then
					dat.Charge =  0
				end
			end, 3, 1, false)
		end
		dat.FireDir =  player:GetShootingInput()
	end
end



local DirectionDict = 
{
	[1] = Vector(5,0),
	[2] = Vector(-5,0),
	[3] = Vector(0,5),
	[4] = Vector(0,-5)

}
		local RenderSprite = Sprite()
		local OverlaySprite = Sprite()
		local CoreSprite = Sprite()
		local CoreOverlaySprite = Sprite()
		local WhiteColor = Color(0,0,0,10,10,10,10)
		WhiteColor:SetColorize(0, 0, 1, 1)

function this:EnlightmentRENDER(npc)
	if npc:GetData().STALEBASEMENTJAM_ENLIGHTENMENT == true   then
			local NpcSprite = npc:GetSprite()
			local FilePath = NpcSprite:GetFilename()
			if NpcSprite:GetOverlayAnimation() ~= nil then
				OverlaySprite:Load(FilePath, true)
				OverlaySprite:Play(NpcSprite:GetOverlayAnimation())
				OverlaySprite.Color = Color(0,0,0,1)
				CoreOverlaySprite:Load(FilePath, true)
				CoreOverlaySprite:Play(NpcSprite:GetOverlayAnimation())
				CoreOverlaySprite.Color = WhiteColor
				CoreOverlaySprite.Scale =  Vector(0.5,0.5)
			end
			RenderSprite:Load(FilePath, true)
			RenderSprite.Color = Color(0,0,0,1)
			RenderSprite.FlipX = NpcSprite.FlipX
			CoreSprite:Load(FilePath, true)
			CoreSprite.Color = WhiteColor
			CoreSprite.Scale = Vector(0.5,0.5)
			CoreSprite:Play(NpcSprite:GetAnimation(),true)
			CoreSprite:SetFrame(NpcSprite:GetFrame())
			CoreSprite.FlipX = NpcSprite.FlipX
		for i=1,4,1 do
			RenderSprite:Play(NpcSprite:GetAnimation(),true)
			RenderSprite:SetFrame(NpcSprite:GetFrame())
			RenderSprite:Render(Isaac.WorldToScreen(npc.Position) + DirectionDict[i] + Vector(math.random(-1,1),math.random(-1,1)))
			if NpcSprite:GetOverlayAnimation() ~= nil then
				CoreOverlaySprite:Render(Isaac.WorldToScreen(npc.Position + Vector(1,-13)))
				CoreOverlaySprite.Color = WhiteColor
				OverlaySprite:Render(Isaac.WorldToScreen(npc.Position ) + DirectionDict[i] + Vector(math.random(-1,1),math.random(-1,1)))
			end
		end
		local Color = Color(0,0,0,10,0,0,10)
		Color:SetColorize(0, 0, 1, 1)
		npc.Color = Color
		NpcSprite:Render(Isaac.WorldToScreen(npc.Position))
		local CorePos =  (NpcSprite:GetNullFrame("OverlayEffect"))
		if CorePos == nil then
			CorePos = Vector(0,-13)
		else
			CorePos = CorePos:GetPos() / 2
		end
		CoreSprite:Render(Isaac.WorldToScreen(npc.Position + CorePos + Vector(0,4)))
		if NpcSprite:GetOverlayAnimation() ~= nil then
			CoreOverlaySprite:Render(Isaac.WorldToScreen(npc.Position + (CorePos) + Vector(0,4)))
		end
	end
end

local function spawnLightBeam(spawner, position)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, position, Vector.Zero, spawner)
end

function this:EnlightmentDeath(npc)
	if npc:GetData().STALEBASEMENTJAM_ENLIGHTENMENT == true then
		local room = Game():GetRoom()
		spawnLightBeam(Isaac.GetPlayer(), npc.Position)
		for i = 1, math.ceil(npc.MaxHitPoints / 20)  do
		Isaac.CreateTimer(function ()
			local angle = math.random(1, 360)
			local positionOffset =math.random(1, 124)
			local position = npc.Position + Vector.FromAngle(angle) + Vector(math.random(-2,2),math.random(-4,4)) * positionOffset
			local clampedPosition = room:GetClampedPosition(position, 0)
			spawnLightBeam(Isaac.GetPlayer(), clampedPosition)
		end,  i * 1, 1, false)
	end
	end
end

function this:RenderUI()
	local RenderTargets = 	B95Mix1:Filter(PlayerManager.GetPlayers(), function (v)
		return v:HasCollectible(HolyHamsaMod.CollectibleTypeCustom.HOLY_HAMSA)
	end)
	for i=1, #RenderTargets, 1 do 
		local player = RenderTargets[i]
		local dat = player:GetData()
		dat.Chargebar = dat.Chargebar or HolyHamsaMod.Chargebar()
		dat.Chargebar:SetCharge(dat.Charge or 0,100)
		local Offset = Vector(-11,-35)
		if player:HasCollectible(643) then
			Offset = Vector(-11, -39)
		end
		dat.Chargebar:Render(Isaac.WorldToScreen(player.Position) + Offset)
	end
end

function this:NewRoom()
local RenderTargets = 	B95Mix1:Filter(PlayerManager.GetPlayers(), function (v)
		return v:HasCollectible(HolyHamsaMod.CollectibleTypeCustom.HOLY_HAMSA)
	end)
	for i=1, #RenderTargets, 1 do 
		local player = RenderTargets[i]
		local dat = player:GetData()
		local OldCharge = dat.Charge
		dat.Charge = -10
		Isaac.CreateTimer(function ()
			dat.Charge = OldCharge
		end,5, 1, false)
	end
end

function this:init()
	HolyHamsaMod:AddCallback(
		ModCallbacks.MC_POST_PLAYER_UPDATE,
		this.updateHamsa
	)
	HolyHamsaMod:AddCallback(
		ModCallbacks.MC_POST_NPC_RENDER,
		this.EnlightmentRENDER
	)
	HolyHamsaMod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, this.EnlightmentDeath)
	HolyHamsaMod:AddCallback(
	ModCallbacks.MC_POST_RENDER,
	this.RenderUI)
	HolyHamsaMod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_ROOM,CallbackPriority.LATE, this.NewRoom)
end

return this
