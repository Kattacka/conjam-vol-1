local this = {}

local function EnlightmentInit(npc,player)
	SFXManager():Play(SoundEffect.SOUND_ULTRA_GREED_PULL_SLOT, 0.5, 0, false, 0.9)
--	npc:SetControllerId(0)
	npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS )
	Game():ShakeScreen(10)
	local NazarAmount = math.ceil(npc.MaxHitPoints / 10) + 1
	if npc:IsBoss() == true then
		NazarAmount =  math.ceil(npc.MaxHitPoints / 40)
	end
	if npc:GetData().STALEBASEMENTJAM_ENLIGHTENMENT == true then
		NazarAmount = NazarAmount / 2
	end
	for i=1, NazarAmount,1 do
			local Fraction = 360 / NazarAmount
			local Nazar = Isaac.Spawn(3,HolyHamsaMod.FamiliarVariantCustom.NAZAR.variant,HolyHamsaMod.FamiliarVariantCustom.NAZAR.subType,npc.Position,Vector.FromAngle(i * Fraction) * 5,npc):ToFamiliar()
			if Nazar == nil then
				return
			end
			if npc:GetData().STALEBASEMENTJAM_ENLIGHTENMENT == nil then
				Nazar.Parent = npc
				Nazar.OrbitSpeed = 0.4
				Nazar:AddToOrbit(npc.Index) --BS Fix
			end
			Nazar.Player = player
			Nazar.Color = player.TearColor
			Nazar.FireCooldown = 5
			Nazar:ClearEntityFlags(EntityFlag.FLAG_APPEAR )
			SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
				local cloud  = Isaac.Spawn(1000,16,5,npc.Position,Vector.Zero,player):ToEffect()
				cloud.Color = Color(0,0,0,1)
				cloud.SpriteScale = Vector(0.75,-0.75)
				cloud.DepthOffset = -100
				cloud.Parent = npc
				cloud:FollowParent(npc)
	end
	npc:GetData().STALEBASEMENTJAM_ENLIGHTENMENT = true
end

function this:HamsaCharge(familiar)
	if familiar and familiar.SubType ~= HolyHamsaMod.FamiliarVariantCustom.HAMSA.subType then
		return
	end
	familiar.Velocity = familiar.TargetPosition
	if  Game():GetFrameCount() / 5 % 1 == 0 then 
		local trail = Isaac.Spawn(1000,111,0,familiar.Position,Vector.Zero,familiar)
		trail.Color = Color(0,0,0,1)
	end
	if familiar.Hearts <= 0 then
		familiar:Remove()
	end
	familiar.Hearts = familiar.Hearts - 1
	local Bing = Isaac.FindInRadius(familiar.Position, 15, EntityPartition.ENEMY)
		for i=1,#Bing,1 do
			local Target = Bing[i]:ToNPC()
			if Target == nil then
				return
			end
			if Target:IsActiveEnemy(false) and Target:IsVulnerableEnemy() then
				local Parent = familiar.SpawnerEntity:ToPlayer()
				if Parent == nil then
					return
				end
					EnlightmentInit(Target:ToNPC(),Parent)
				Isaac.Spawn(1000,97,0,familiar.Position,Vector.Zero,familiar)
				familiar:Remove()
			end
		end
	
end

local AnimDoc = 
{
	[0] = "Right",
	[1] = "Up",
	[2] = "Left",
	[3] = "Down",

}

function this:HamsaInit(familiar)
	if familiar and familiar.SubType ~= HolyHamsaMod.FamiliarVariantCustom.HAMSA.subType then
		return
	end
	familiar.Hearts = 150
	familiar:ClearEntityFlags(EntityFlag.FLAG_APPEAR )
	local sprite = 	familiar:GetSprite()
	local Dir = B95Mix1:VectorToDirection(familiar.Velocity)
	sprite:Play(AnimDoc[Dir],false)
end

function this:NewRoom()
	local Count = Isaac.FindByType(
			EntityType.ENTITY_FAMILIAR,
			HolyHamsaMod.FamiliarVariantCustom.HAMSA.variant,
			HolyHamsaMod.FamiliarVariantCustom.HAMSA.subType
		)
	for i=1,#Count,1 do
		Count[i]:Remove()
	end
end

function this:init()
	HolyHamsaMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, this.HamsaCharge,HolyHamsaMod.FamiliarVariantCustom.HAMSA.variant)
	HolyHamsaMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, this.HamsaInit,HolyHamsaMod.FamiliarVariantCustom.HAMSA.variant)
	HolyHamsaMod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_ROOM,CallbackPriority.LATE, this.NewRoom)
end

return this