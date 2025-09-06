local mod = GLITCHED_MINER

mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, function ()
    if ConWorm then
        mod.AddEvent(function(pos)
            Isaac.Spawn(
                EntityType.ENTITY_STONEY,
                0,
                0,
                pos,
                Vector.Zero,
                nil
            )
        end, 20, "(ConWorm) Steve")

        mod.AddEvent(function()
            local trinket = Isaac.GetTrinketIdByName("ConWorm")
            for _, player in ipairs(PlayerManager.GetPlayers()) do
                player:AddSmeltedTrinket(trinket)
            end
        end, 1, "(ConWorm) ConBoi")
    end

    if EID then
        --EID:addCollectible(mod.ItemId, "{{Bomb}} +10 Bombs#Adds a {{ColorGreen}}Luck-based chance to turn rocks into {{ColorRainbow}}{{ERROR}}Glitched Rocks{{CR}}#{{Warning}} {{ColorRainbow}}{{ERROR}}Glitched Rocks{{CR}} trigger random effects when destroyed")
        EID:addCollectible(mod.ItemId, "{{Bomb}} +{{Quality1}}{{Quality0}}{{ColorCyan}}10{{CR}} {{Bomb}}{{ColorBlack}}Bombs{{CR}}#{{ArrowUp}} Adds a {{ColorGreen}}{{Luck}}Luck{{CR}}-based {{ColorRed}}{{DiceRoom}}chance{{CR}} to turn {{ColorGray}}rocks{{CR}} into {{ColorRainbow}}{{ERROR}}Glitched Rocks{{CR}}#{{Warning}} {{ColorRainbow}}{{ERROR}}Glitched Rocks{{CR}} trigger {{ColorRed}}{{DiceRoom}}random{{CR}} {{ColorLime}}effects{{CR}} when {{BossRoom}}{{ColorBlack}}destroyed{{CR}}")
    end
end)