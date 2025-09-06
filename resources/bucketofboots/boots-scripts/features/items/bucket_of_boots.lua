local this = {}

local THROW_SPEED = 15
local THROW_TEAR_FALLING_SPEED = -15
local THROW_TEAR_FALLING_ACCEL = 1
local BOOT_VELOCITY_MIN = 3
local BOOT_VELOCITY_MAX = 5
local BOOT_FALL_SPEED_MIN = -30
local BOOT_FALL_SPEED_MAX = -8
local BOOT_FALL_ACCEL = 1
local BOOTS_TO_SPAWN = 6
local BOOT_SIZE_MIN = 0.7
local BOOT_SIZE_MAX = 1.25
local BOOT_DAMAGE_MULTIPLIER = 3

local bucket_of_boots_item = Isaac.GetItemIdByName("Bucket of Boots")
local boot_picker = WeightedOutcomePicker()

---@param bucket EntityTear
function this:post_tear_death_bucket(bucket)
	SFXManager():Play(SoundEffect.SOUND_POT_BREAK_2)

	for i = 1, BOOTS_TO_SPAWN do
		local scale = BucketOfBootsMod:get_random_float(BOOT_SIZE_MIN, BOOT_SIZE_MAX)
		local velocity = RandomVector() * BucketOfBootsMod:get_random_float(BOOT_VELOCITY_MIN, BOOT_VELOCITY_MAX)
		local boot = Isaac.Spawn(
			EntityType.ENTITY_TEAR,
			BucketOfBootsMod.TearVariant.BUCKET_MORPHING_TEAR,
			0,
			bucket.Position,
			velocity,
			bucket
		):ToTear()

		if boot then
			boot.Scale = scale
			boot.FallingSpeed = BucketOfBootsMod:get_random_float(BOOT_FALL_SPEED_MIN, BOOT_FALL_SPEED_MAX)
			boot.FallingAcceleration = BOOT_FALL_ACCEL
			boot.CollisionDamage = 0
		end
	end

	Game():SpawnParticles(bucket.Position, EffectVariant.NAIL_PARTICLE, 8, 5, Color.Default, nil)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.IMPACT, 0, bucket.Position, Vector.Zero, bucket)

	local destruction = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		BucketOfBootsMod.EffectVariant.BUCKET_OF_BOOTS_DESTRUCTION,
		0,
		bucket.Position,
		Vector.Zero,
		bucket
	)
	destruction:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
end

---@param _collectible CollectibleType
---@param _rng RNG
---@param player EntityPlayer
function this:use_item_bucket_of_boots(_collectible, _rng, player)
	if player:GetItemState() == bucket_of_boots_item then
		player:AnimateCollectible(bucket_of_boots_item, "HideItem", "PlayerPickupSparkle")
		player:ResetItemState()
	else
		player:AnimateCollectible(bucket_of_boots_item, "LiftItem", "PlayerPickupSparkle")
		player:SetItemState(bucket_of_boots_item)
	end

	return {
		Discharge = false,
		ShowAnim = false,
	}
end

---@param player EntityPlayer
function this:post_player_update(player)
	local shoot_input = player:GetShootingInput()
	local aim_direction = player:GetAimDirection()

	if
		player:GetItemState() ~= bucket_of_boots_item
		or aim_direction:Length() == 0
		or shoot_input:Length() == 0
		or not player:IsHeldItemVisible()
	then
		return
	end

	player:AnimateCollectible(bucket_of_boots_item, "HideItem")
	player:ResetItemState()

	local slot = player:GetActiveItemSlot(bucket_of_boots_item)

	if slot ~= -1 then
		player:DischargeActiveItem(slot)
	end

	local aim_vector = aim_direction:Resized(THROW_SPEED)
	local movement_inheritance = player:GetTearMovementInheritance(aim_vector)
	local tear_velocity = aim_vector + movement_inheritance

	local boots_to_spawn = 1

	if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
		boots_to_spawn = 2
	end

	for i = 1, boots_to_spawn do
		local tear = Isaac.Spawn(
			EntityType.ENTITY_TEAR,
			BucketOfBootsMod.TearVariant.BUCKET,
			0,
			player.Position,
			tear_velocity,
			nil
		):ToTear()
		tear.FlipX = tear_velocity.X < 0
		tear.CollisionDamage = player.Damage * BOOT_DAMAGE_MULTIPLIER

		if tear then
			tear.FallingSpeed = THROW_TEAR_FALLING_SPEED
			tear.FallingAcceleration = THROW_TEAR_FALLING_ACCEL
		end

		SFXManager():Play(SoundEffect.SOUND_SHELLGAME)
	end
end

---@param boot EntityTear
---@param collider Entity
function this:post_tear_collision_boot(boot, collider)
	local npc = collider:ToNPC()
	if
		npc
		and npc:IsVulnerableEnemy()
		and not npc:IsBoss()
		and (npc.Type ~= BucketOfBootsMod.BootsEntityType or npc.Variant ~= BucketOfBootsMod.BootsEntityVariant)
	then
		local npc_position = npc.Position
		npc:Remove()

		local sub_type = boot_picker:PickOutcome(boot:GetDropRNG())

		local boot_enemy = Isaac.Spawn(
			BucketOfBootsMod.BootsEntityType,
			BucketOfBootsMod.BootsEntityVariant,
			sub_type,
			npc_position,
			Vector.Zero,
			boot
		)

		boot:Kill()
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, boot)
		boot_enemy:AddEntityFlags(EntityFlag.FLAG_APPEAR)
	end
end

---@param boot EntityTear
function this:post_tear_update_boot(boot)
	local sprite = boot:GetSprite()
	sprite:Play("RegularTear6")
end

---@param boot EntityTear
function this:post_tear_death_boot(boot)
	boot.Visible = false

	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.IMPACT, 0, boot.Position, Vector.Zero, boot)
	SFXManager():Play(SoundEffect.SOUND_PESTILENCE_MAGGOT_POPOUT, 1, 0, false, 1.2)
end

function this:init()
	BucketOfBootsMod:AddCallback(ModCallbacks.MC_USE_ITEM, this.use_item_bucket_of_boots, bucket_of_boots_item)
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_TEAR_DEATH,
		this.post_tear_death_bucket,
		BucketOfBootsMod.TearVariant.BUCKET
	)
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_TEAR_DEATH,
		this.post_tear_death_boot,
		BucketOfBootsMod.TearVariant.BUCKET_MORPHING_TEAR
	)
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_TEAR_UPDATE,
		this.post_tear_update_boot,
		BucketOfBootsMod.TearVariant.BUCKET_MORPHING_TEAR
	)
	BucketOfBootsMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, this.post_player_update)
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_TEAR_COLLISION,
		this.post_tear_collision_boot,
		BucketOfBootsMod.TearVariant.BUCKET_MORPHING_TEAR
	)

	if EID then
		EID:addCollectible(
			bucket_of_boots_item,
			"Using the item and firing in a direction throws the bucket that deals 3x the player's damage#The bucket breaks where it lands and fires out boot tears#Boot tears turn enemies into Boot Enemies#Boot Enemies only attack by moving in chess figure patterns"
		)
	end

	boot_picker:AddOutcomeFloat(BucketOfBootsMod.BootSubType.PAWN, 0.35)
	boot_picker:AddOutcomeFloat(BucketOfBootsMod.BootSubType.BISHOP, 0.25)
	boot_picker:AddOutcomeFloat(BucketOfBootsMod.BootSubType.ROOK, 0.2)
	boot_picker:AddOutcomeFloat(BucketOfBootsMod.BootSubType.QUEEN, 0.2)
end

return this
