local mod = RegisterMod("Mega Dice", 1)
local game = Game()
local sfx = SFXManager()

mod.Collectible = {
	MEGA_DICE = Isaac.GetItemIdByName("Mega Dice"),
}

mod.Effect = {
	MEGA_DICE = Isaac.GetEntityVariantByName("Mega Dice"),
}

mod.Sound = {
	CINEMATIC_BOOM = Isaac.GetSoundIdByName("Cinematic Boom"),
}

function mod.IsActiveVulnerableEnemy(entity, includeFriendly, includeDead)
	if not entity then return end
	local isFriendly = entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
	
	return entity:IsVulnerableEnemy() and entity:IsActiveEnemy(includeDead) and (includeFriendly or not isFriendly)
end

function mod.GetNearestEntity(position, func)
	local nearestDistance = math.huge
	local nearestEntity = nil
	
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity and func and func(entity) then
			local distanceSqr = position:DistanceSquared(entity.Position)
			
			if distanceSqr < nearestDistance then
				nearestDistance = distanceSqr
				nearestEntity = entity
			end
		end
	end
	return nearestEntity
end

local CRUSH_DAMAGE = 200
local KNOCKBACK_SIZE_MULT = 1.5
local JUMP_SPEED = 10

local function triggerMegaDiceEffect(position, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	local level = game:GetLevel()
	local room = game:GetRoom()
	local roll = rng:RandomInt(6)
	
	if roll == 0 then
		room:SetCardAgainstHumanity()
	elseif roll == 1 then
		level:RemoveCurses(-1)
		level:ApplyBlueMapEffect()
		level:ApplyMapEffect()
		level:ApplyCompassEffect(true)
	elseif roll == 2 then
		Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_D20, UseFlag.USE_NOANIM)
		game:RerollLevelPickups(seed or level:GetDungeonPlacementSeed())
	elseif roll == 3 then
		Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_D6, UseFlag.USE_NOANIM)
		game:RerollLevelCollectibles()
	elseif roll == 4 then
		room:MamaMegaExplosion(position)
	elseif roll == 5 then
		local gridCount = 0
		
		for _, player in pairs(PlayerManager.GetPlayers()) do player:FullCharge(-1, true) end
		for gridIdx = 0, room:GetGridSize() - 1 do
			if room:IsPositionInRoom(room:GetGridPosition(gridIdx), 0) then
				gridCount = gridCount + 1
			end
		end
		Isaac.CreateTimer(function()
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 1, Isaac.GetRandomPosition(), Vector.Zero, nil).DepthOffset = 1
		end, 2, math.ceil((gridCount - 1) ^ 0.5), false) -- Amount based on room size
	end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, collectible, rng, player, flag, slot, data)
	local effect = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, mod.Effect.MEGA_DICE, 0, 
		Isaac.GetRandomPosition(), Vector.Zero, player):ToEffect()
	effect.Position = game:GetRoom():GetClampedPosition(effect.Position, effect.Size)
	
	return {ShowAnim = true}
end, mod.Collectible.MEGA_DICE)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	local effectSpr = effect:GetSprite()
	local level = game:GetLevel()
	local room = game:GetRoom()
	
	if effectSpr:IsFinished("Drop") then effectSpr:Play("Explode") end
	if effectSpr:IsFinished("Explode") then effect:Remove() end
	if effectSpr:IsEventTriggered("Stomp") then
		local poof = effect:MakeGroundPoof()
		
		effect.Velocity = Vector.Zero
		poof.Color = Color(0.75, 0.75, 0.75) -- Doing the color this way because the function is bugged and returns errors
		poof.Child.Color = poof.Color
		game:ButterBeanFart(effect.Position, effect.Size * KNOCKBACK_SIZE_MULT, effect, false, false)
		game:BombDamage(effect.Position, CRUSH_DAMAGE, effect.Size, false, effect, nil, DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_NO_MODIFIERS | DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_IGNORE_ARMOR)
		sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS)
	end
	if effectSpr:IsEventTriggered("Jump") then
		if effectSpr:IsPlaying("Drop") then
			local target = mod.GetNearestEntity(effect.Position, function(entity)
				return entity:ToPlayer() or mod.IsActiveVulnerableEnemy(entity)
			end)
			if target then
				effect.Velocity = (target.Position - effect.Position):Resized(JUMP_SPEED)
			else
				effect.Velocity = RandomVector():Resized(JUMP_SPEED)
			end
		end
		if effectSpr:IsPlaying("Explode") then
			local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, effect.Position, Vector.Zero, effect):ToEffect()
			
			poof.Color = Color(0.75, 0.75, 0.75)
			poof.SpriteScale = poof.SpriteScale * 0.5
			sfx:Play(SoundEffect.SOUND_FETUS_JUMP, nil, nil, nil, 0.6)
		end
	end
	if effectSpr:IsEventTriggered("Roll") then
		triggerMegaDiceEffect(effect.Position, effect.DropSeed)
		sfx:Play(mod.Sound.CINEMATIC_BOOM, 2)
		game:SetBloom(30, 1)
	end
	effectSpr.PlaybackSpeed = 0.75 -- Is a bit too fast on its own
	effect.Position = room:GetClampedPosition(effect.Position, effect.Size * 0.5) -- To prevent it from going off-screen
end, mod.Effect.MEGA_DICE)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
	if entity.Variant == FamiliarVariant.WISP and entity.SubType == mod.Collectible.MEGA_DICE then
		triggerMegaDiceEffect(entity.Position, entity.DropSeed)
		sfx:Play(mod.Sound.CINEMATIC_BOOM, 2)
		game:SetBloom(30, 1)
	end
end, EntityType.ENTITY_FAMILIAR)

if EID then
	EID:addCollectible(mod.Collectible.MEGA_DICE, "Drops a dice that jumps at near enemies or players#Triggers a random effect and vanishes:#{{PoopPickup}} Poops everywhere#{{Collectible" .. CollectibleType.COLLECTIBLE_TREASURE_MAP .. "}} Removes curses and reveals map#{{Collectible" .. CollectibleType.COLLECTIBLE_D20 .. "}} Rerolls floor pickups#{{Collectible" .. CollectibleType.COLLECTIBLE_D6 .. "}} Rerolls floor pedestals#{{Bomb}} Mama Mega explosion#{{Battery}} Fully recharges actives")
end

if AccurateBlurbs then
	mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, function()
		Isaac.GetItemConfig():GetCollectible(mod.Collectible.MEGA_DICE).Description = "Dice crushes foes + triggers random effect"
	end)
end