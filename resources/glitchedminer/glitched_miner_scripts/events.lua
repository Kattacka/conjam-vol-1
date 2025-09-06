local mod = GLITCHED_MINER
local game = Game()
local sfx = SFXManager()

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    game:Fart(pos, 185)
end, 30, "Fart")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    game:CharmFart(pos, 185, player)
end, 30, "Charm fart")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    game:ButterBeanFart(pos, 185, player, true, true)
end, 30, "Butter fart")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    Isaac.Explode(pos, player, 40)
end, 30, "Explosion")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 3 do
            local rocket = Isaac.Spawn(
            EntityType.ENTITY_BOMB,
            BombVariant.BOMB_ROCKET,
            0,
            pos,
            Vector.Zero,
            player
        ):ToBomb()
        ---@cast rocket EntityBomb
        rocket:SetRocketAngle(rng:RandomFloat()*360)
        rocket.IsFetus = true
        rocket:AddTearFlags(TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_HOMING)
    end
end, 100, "Rocket in a Jar")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 90, 360, 90 do
        local laser = EntityLaser.ShootAngle(
            LaserVariant.LIGHT_BEAM,
            pos,
            i,
            45,
            Vector.Zero,
            player
        )
        laser.CollisionDamage = player.Damage
        laser:SetDisableFollowParent(true)
    end
end, 100, "Light Blast")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local laser = player:SpawnMawOfVoid(45)
    laser:SetDisableFollowParent(true)
    laser.Position = pos
end, 100, "Athame")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local creep = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PLAYER_CREEP_LEMON_PARTY,
        0,
        pos,
        Vector.Zero,
        player
    )
    creep:Update()
end, 100, "Jarate")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local ghost = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.HUNGRY_SOUL,
        0,
        pos,
        Vector.Zero,
        player
    ):ToEffect()
    ghost.Timeout = 270
    sfx:Play(SoundEffect.SOUND_FLOATY_BABY_ROAR, 0.7, 2, false, 2.17)
end, 100, "Ghost")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 10 do
        local tear = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            TearVariant.BLUE,
            0,
            pos,
            rng:RandomVector()*60,
            player
        ):ToTear()
        ---@cast tear EntityTear
        tear.CollisionDamage = player.Damage*3 + 10
        tear.Color = Color(rng:RandomFloat(), rng:RandomFloat(), rng:RandomFloat())
        tear:AddTearFlags(TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_BOUNCE)
    end
end, 100, "Balls")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, true)
end, 100, "Shield")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    sfx:Play(SoundEffect.SOUND_DEATH_CARD)
    local ref = EntityRef(player)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            ent:AddFear(ref, 120)
        end
    end
end, 75, "Fear")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
    local ref = EntityRef(player)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            ent:AddBaited(ref, 120)
        end
    end
end, 75, "Bait")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    sfx:Play(SoundEffect.SOUND_DOGMA_SCREAM)
    local ref = EntityRef(player)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            ent:AddConfusion(ref, 120, true)
        end
    end
end, 75, "Confusion")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS)
    local ref = EntityRef(player)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            ent:AddBurn(ref, 120, player.Damage)
        end
    end
end, 75, "Burn")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    sfx:Play(SoundEffect.SOUND_DEVIL_CARD)
    player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, true)
end, 75, "Belial")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_METRONOME, UseFlag.USE_NOANIM)
end, 50, "Metronome")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local heart = Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_HEART,
        HeartSubType.HEART_BLENDED,
        pos,
        Vector.Zero,
        nil
    ):ToPickup()
    ---@cast heart EntityPickup
    heart:GetSprite():ReplaceSpritesheet(0, "glitchedminer/resources/gfx/items/pickups/mango_heart_pickup.png", true)
    heart.Timeout = 120
end, 50, "Mangoheart")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    player:FullCharge(ActiveSlot.SLOT_PRIMARY, true)
end, 50, "Full Charge")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 5 do
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_BOMB,
            0,
            pos,
            rng:RandomVector()*8,
            nil
        )
    end
end, 50, "Las Bombas")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 3 do
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            0,
            NullPickupSubType.NO_COLLECTIBLE_TRINKET_CHEST,
            pos,
            rng:RandomVector()*3,
            nil
        )
    end
end, 50, "Just pickups")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local pill = Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_PILL,
        0,
        pos,
        Vector.Zero,
        nil
    )
    game:GetItemPool():UnidentifyPill(pill.SubType)
end, 50, "Mystery Pill")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 7 do
        local coin = Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_COIN,
            CoinSubType.COIN_PENNY,
            pos,
            rng:RandomVector()*3,
            nil
        ):ToPickup()
        ---@cast coin EntityPickup
        coin.Timeout = 90
    end
end, 50, "Payday")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    ItemOverlay.Show(Giantbook.D10)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            game:RerollEnemy(ent)
        end
    end
end, 30, "Enemy reroll")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_LIL_DUMPY, true)
    player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_LIL_DUMPY, true)
end, 30, "2 of Gyatt")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            if rng:RandomInt(2) == 0 then
                ---@diagnostic disable-next-line: param-type-mismatch
                ent:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR | EntityFlag.FLAG_RENDER_WALL | EntityFlag.FLAG_NO_REMOVE_ON_TEX_RENDER)
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                ent:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR | EntityFlag.FLAG_RENDER_WALL)
            end
        end
    end
end, 20, "In the house like carpet")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local ref = EntityRef(player)
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and not ent:IsBoss() then
            local pushDirection = (ent.Position - pos):Resized(20)
            ent:AddKnockback(ref, pushDirection, 10, true)
        end
    end
end, 20, "Blastoff")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_DATAMINER, UseFlag.USE_NOANIM)
end, 20, "Dataminer")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 5 do
        local minisaac = player:AddMinisaac(pos, true)
        minisaac.Color = Color(rng:RandomFloat(), rng:RandomFloat(), rng:RandomFloat())
    end
end, 20, "Dad's Gormiti collection")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    player:SetFullHearts()
    sfx:Play(SoundEffect.SOUND_VAMP_DOUBLE)
end, 10, "Full heal")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    ---@diagnostic disable-next-line: param-type-mismatch
    player:UseCard(Card.CARD_SOUL_JACOB, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
    for _, otherPlayer in ipairs(PlayerManager.GetPlayers()) do
        print(otherPlayer.FrameCount)
        if otherPlayer.FrameCount ~= 0 then
            goto continue
        end
        otherPlayer.Color = Color(0.6,1,0.6,1,0,0.1,0,0,1,0,0.5)
        otherPlayer.Position = pos
        otherPlayer:SetMinDamageCooldown(60)
        ::continue::
    end
end, 10, "Stumpford")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if (ent:IsVulnerableEnemy() and not ent:IsBoss()) or (ent:ToPickup() and ent:ToPickup():CanReroll()) then
            Isaac.Spawn(
                EntityType.ENTITY_BOMB,
                BombVariant.BOMB_GIGA,
                0,
                ent.Position,
                Vector.Zero,
                ent
            )
            ent:Remove()
        end
    end
end, 10, "Sand Flies")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 5 do
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_TRINKET,
            TrinketType.TRINKET_TICK,
            rock.Position,
            rng:RandomVector()*4,
            nil
        )
    end
end, 5, "Curse of the Tick")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local polty = Isaac.Spawn(
        EntityType.ENTITY_POLTY,
        0,
        0,
        pos,
        Vector.Zero,
        nil
    )
    polty.MaxHitPoints = 1500
    polty.HitPoints = 1500
    polty.Color = Color(1, 1, 0.2, 0.3)
end, 5, "Super Polty")

local ip = nil

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    if not ip then
        ip = {rng:RandomInt(256), rng:RandomInt(256), rng:RandomInt(256), rng:RandomInt(256)}
    end
    local message = string.format("%d.%d.%d.%d", table.unpack(ip))
    Game():GetHUD():ShowItemText("I AM JOHN IP!", message)
end, 5, "John IP")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local pickup = Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        0,
        pos,
        Vector.Zero,
        nil
    ):ToPickup()
    ---@cast pickup EntityPickup
    ---@diagnostic disable-next-line: undefined-field
    pickup:RemoveCollectibleCycle()
    pickup:TryInitOptionCycle(20)
end, 1, "Rapidcycle pedestal")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    for i = 1, 100 do
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_TAROTCARD,
            Card.CARD_FOOL,
            rock.Position,
            rng:RandomVector(),
            nil
        )
    end
end, 1, "Silksong fans when Indie World on 7/8")

---@param pos Vector
---@param rng RNG
---@param rock GridEntityRock
---@param player EntityPlayer
mod.AddEvent(function (pos, rng, rock, player)
    local deli = Isaac.Spawn(
        EntityType.ENTITY_DELIRIUM,
        0,
        0,
        pos,
        Vector.Zero,
        nil
    )
    deli.HitPoints = 20
    deli.MaxHitPoints = 20
end, 1, "Random Delirium event")