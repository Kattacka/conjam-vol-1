local this = {}


function this:SfxOverride(ID, Volume, FrameDelay, Loop, Pitch, Pan)
	local player = Isaac.GetPlayer()
	if player == nil then
		return
	end
	local charactertype = player:GetPlayerType()
	if charactertype ~= HolyHamsaMod.PlayerTypeCustom.CORINTHEA then
		return
	end
	if ID == 55 then
    	return {HolyHamsaMod.SoundEffectCustom.HURT, Volume - 0.75, FrameDelay, false, Pitch, Pan}
	elseif ID == 217 then
		return {HolyHamsaMod.SoundEffectCustom.DEATH, Volume , FrameDelay, false, Pitch, Pan}
	elseif ID == 5 then
		return {HolyHamsaMod.SoundEffectCustom.BRIMSTONE_SPIT, Volume - 0.5, FrameDelay, false, 0.75 + math.random(), Pan}
	end
end


function this:init()
	HolyHamsaMod:AddCallback(ModCallbacks.MC_PRE_SFX_PLAY, this.SfxOverride)
end

return this
