---@param effectName string
local function registerEffect(effectName)
	local formattedName = HolyHamsaMod.MOD_PREFIX .. " " .. effectName
	return Isaac.GetEntityVariantByName(formattedName)
end

HolyHamsaMod.EffectVariantCustom = {
}

HolyHamsaMod:validateEnum("EffectVariantCustom", HolyHamsaMod.EffectVariantCustom)
