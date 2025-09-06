local COSTUME_PATH_PREFIX = "gfx/characters/"

local function getCostume(path)
	return Isaac.GetCostumeIdByPath(COSTUME_PATH_PREFIX .. path)
end

-- These must have a corresponding entry in the "costumes2.xml" file
---@enum HolyHamsaMod.NullItemIDCustom
HolyHamsaMod.NullItemIDCustom = {
	HAIR = getCostume("c_Hair.anm2"),
	BLOODMARKS = getCostume("c_Bloodmarks.anm2"),
	SUCKING = getCostume("c_Suck.anm2"),
	BACK_COSTUME = getCostume("c_BackCostume.anm2"),
	MOUTHFULL = getCostume("c_MouthFull.anm2")
}

HolyHamsaMod:validateEnum("NullItemIDCustom", HolyHamsaMod.NullItemIDCustom)