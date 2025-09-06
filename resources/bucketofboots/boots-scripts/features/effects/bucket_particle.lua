local this = {}

---@param particle EntityEffect
function this:post_effect_init_bucket_of_boots_particle(particle)
	local sprite = particle:GetSprite()
	local animation_data = sprite:GetAnimationData("Rubble")

	if animation_data then
		local length = animation_data:GetLength()
		local frame = BucketOfBootsMod:get_random_int(0, length - 1)
		sprite:SetFrame(frame)
	end
end

function this:init()
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_EFFECT_INIT,
		this.post_effect_init_bucket_of_boots_particle,
		BucketOfBootsMod.EffectVariant.BUCKET_OF_BOOTS_PARTICLE
	)
end

return this
