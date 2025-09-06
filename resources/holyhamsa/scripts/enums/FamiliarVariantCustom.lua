---@param familiarName string
local function registerFamiliar(familiarName)
	local formattedName = HolyHamsaMod.MOD_PREFIX .. " " .. familiarName
	return {
		variant = Isaac.GetEntityVariantByName(formattedName),
		subType = Isaac.GetEntitySubTypeByName(formattedName),
	}
end

HolyHamsaMod.FamiliarVariantCustom = {
	NAZAR = registerFamiliar("Nazar"),
	HAMSA = registerFamiliar("Hamsa")
}


HolyHamsaMod:validateEnum("FamiliarVariantCustom", HolyHamsaMod.FamiliarVariantCustom)
