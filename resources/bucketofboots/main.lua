BucketOfBootsMod = RegisterMod("BucketOfBoots", 1)
BucketOfBootsMod.TearVariant = {
	BUCKET = Isaac.GetEntityVariantByName("Bucket of Boots Tear"),
	BUCKET_MORPHING_TEAR = Isaac.GetEntityVariantByName("Bucket of Boots Morphing Tear"),
}
BucketOfBootsMod.BootsEntityVariant = Isaac.GetEntityVariantByName("Boot Pawn")
BucketOfBootsMod.BootsEntityType = Isaac.GetEntityTypeByName("Boot Pawn")
BucketOfBootsMod.BootSubType = {
	BISHOP = Isaac.GetEntitySubTypeByName("Boot Bishop"),
	PAWN = Isaac.GetEntitySubTypeByName("Boot Pawn"),
	QUEEN = Isaac.GetEntitySubTypeByName("Boot Queen"),
	ROOK = Isaac.GetEntitySubTypeByName("Boot Rook"),
}
BucketOfBootsMod.SoundEffect = {
	PAWN_STEP = Isaac.GetSoundIdByName("Boot Pawn Step"),
	QUEEN_STEP = Isaac.GetSoundIdByName("Boot Queen Step"),
	ROOK_STEP = Isaac.GetSoundIdByName("Boot Rook Step"),
}
BucketOfBootsMod.EffectVariant = {
	BUCKET_OF_BOOTS_DESTRUCTION = Isaac.GetEntityVariantByName("Boot Destruction"),
	BUCKET_OF_BOOTS_PARTICLE = Isaac.GetEntityVariantByName("Boot Particle"),
}

---@param angle number
function BucketOfBootsMod:angle_to_direction(angle)
	local positive_degrees = angle

	while positive_degrees < 0 do
		positive_degrees = positive_degrees + 360
	end

	local normalized_degrees = positive_degrees % 360

	if normalized_degrees >= 315 or normalized_degrees < 45 then
		return Direction.RIGHT
	elseif normalized_degrees >= 45 and normalized_degrees < 135 then
		return Direction.DOWN
	elseif normalized_degrees >= 135 and normalized_degrees < 225 then
		return Direction.LEFT
	else
		return Direction.UP
	end
end

function BucketOfBootsMod:vector_to_direction(vector)
	local angle = vector:GetAngleDegrees()
	return BucketOfBootsMod:angle_to_direction(angle)
end

---@param min number
---@param max number
---@param seed_or_rng RNG | number | nil
function BucketOfBootsMod:get_random_float(min, max, seed_or_rng)
	local rng

	if not seed_or_rng then
		rng = RNG(Random())
	elseif type(seed_or_rng) == "number" then
		rng = RNG(seed_or_rng)
	else
		rng = seed_or_rng
	end

	if min > max then
		local old_min = min
		local old_max = max
		min = old_max
		max = old_min
	end

	return min + rng:RandomFloat() * (max - min)
end

---@param min number
---@param max number
---@param seed_or_rng RNG | number | nil
function BucketOfBootsMod:get_random_int(min, max, seed_or_rng)
	local rng
	min = math.ceil(min)
	max = math.ceil(max)

	if not seed_or_rng then
		rng = RNG(Random())
	elseif type(seed_or_rng) == "number" then
		rng = RNG(seed_or_rng)
	else
		rng = seed_or_rng
	end

	if min > max then
		local old_min = min
		local old_max = max
		min = old_max
		max = old_min
	end

	return rng:RandomInt(min, max)
end

local scripts = {
	include("resources.bucketofboots.boots-scripts.features.items.bucket_of_boots"),
	include("resources.bucketofboots.boots-scripts.features.enemies.boots"),
	include("resources.bucketofboots.boots-scripts.features.effects.bucket_particle"),
}

for _, v in pairs(scripts) do
	if type(v) == "table" and type(v.init) == "function" then
		v:init()
	end
end
