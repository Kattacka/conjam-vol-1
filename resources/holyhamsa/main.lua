HolyHamsaMod = RegisterMod("HolyHamsaMod", 1)

---@param enumName string
---@param enum table<string, number>
function HolyHamsaMod:validateEnum(enumName, enum)
	for i, v in pairs(enum) do
		assert(
			v ~= -1,
			"The value for " .. enumName .. "." .. i .. " is -1. Make sure this was properly defined in the XML file!"
		)
	end
end

local scripts = {
	-- Enums
	include("resources.holyhamsa.scripts.constants"),
	include("resources.holyhamsa.scripts.enums.CollectibleType"),
	include("resources.holyhamsa.scripts.enums.FamiliarVariantCustom"),
	include("resources.holyhamsa.scripts.HolyHamsa"),
	include("resources.holyhamsa.scripts.Nazar"),
	include("resources.holyhamsa.scripts.Hamsa"),
	include("resources.holyhamsa.scripts.chargebar")
}

for _, file in pairs(scripts) do
	if type(file) == "table" and type(file.init) == "function" then
		file:init()
	end
end

if EID then
	EID:addCollectible(HolyHamsaMod.CollectibleTypeCustom.HOLY_HAMSA, "Charge based passive, shoots a Hamsa at max charge.#When a Hamsa hits an enemy it spawns a bunch of Nazar familiars orbit the enemy hit and fire bullets#When an enemy dies, the Nazar decouples and flies slowly, bursting into lasers when you shoot afain")
end