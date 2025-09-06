HolyHamsaMod.NO_KNOCKBACK_FLAGS = EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK
HolyHamsaMod.MOD_PREFIX = "[StaleBasementJam]"
HolyHamsaMod.GAME = Game()
HolyHamsaMod.SFX_MANAGER = SFXManager()
HolyHamsaMod.ITEM_CONFIG = Isaac.GetItemConfig()





--Taken from the Inhouse Isaacscript Lua Port / Overhaul written by 4Grabs   
-------------------------------------------------------------------------------------------------

-- Converts MaxFireDelay (tears stat) to tears per second (what is visually displayed in game)
function HolyHamsaMod:MaxFireDelayToTps(maxFireDelay)
	return 30 / (maxFireDelay + 1)
end

-- Converts tears per second (what is visually displayed in game) to MaxFireDelay (tears stat)
function HolyHamsaMod:TpsToMaxFireDelay(tps)
	return 30 / tps - 1
end

-- tps to maxfiredelay, basically
function HolyHamsaMod:AddTearsStat(player, tearsStat)
	local existingTearsStat = HolyHamsaMod:MaxFireDelayToTps(player.MaxFireDelay)
	local newTearsStat = existingTearsStat + tearsStat
	local newMaxFireDelay = HolyHamsaMod:TpsToMaxFireDelay(newTearsStat)
	player.MaxFireDelay = newMaxFireDelay
end

--------------------------------------------------------------------------------------------------