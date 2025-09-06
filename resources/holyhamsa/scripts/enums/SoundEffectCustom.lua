---@param soundName string
local function registerSound(soundName)
	local formattedName = HolyHamsaMod.MOD_PREFIX .. " " .. soundName
	return Isaac.GetSoundIdByName(formattedName)
end

HolyHamsaMod.SoundEffectCustom = {
	HURT = registerSound("Hurt"),
	DEATH = registerSound("Death"),
	SWALLOWING = registerSound("Swallow"),
	SUCKING = registerSound("Suck"),
	BRIMSTONE_SPIT = registerSound("Brimstone Spit"),
	SPIT = registerSound("Spitting")
}

HolyHamsaMod:validateEnum("SoundEffectCustom", HolyHamsaMod.SoundEffectCustom)
