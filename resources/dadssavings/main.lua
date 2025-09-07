ConboiMod = RegisterMod("ConboiMod", "1")
local mod = ConboiMod

local DADS_SAVINGS = Isaac.GetItemIdByName("Dad's Savings")

local PICKUP_VARIANT_CHIP = Isaac.GetEntityVariantByName("Red Poker Chip")

local CHIP_SUBTYPE_RED = Isaac.GetEntitySubTypeByName("Red Poker Chip")

local SFX_CHIP_DROP = Isaac.GetSoundIdByName("Poker Chip Drop")
local SFX_CHIP_COLLECT = Isaac.GetSoundIdByName("Poker Chip Collect")

local json = require("json")

local PENNY_REPLACE_CHANCE = 0.2

local chipCountCache = 0

local function initSaveData()
    local dataToSave = {
            DadsSavings = {
                RunChipCount = 0
            }
        }
    chipCountCache = 0
    local encoded = json.encode(dataToSave)
    mod:SaveData(encoded)
end


mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    if mod:HasData() and isContinued then
        local loadedData = mod:LoadData()
        local saveData = json.decode(loadedData)
    else
        initSaveData()
    end
end)

local function getChipCount()
    if mod:HasData() then
        local saveData = json.decode(mod:LoadData())
        if saveData and saveData.DadsSavings and saveData.DadsSavings.RunChipCount then
            return saveData.DadsSavings.RunChipCount
        end
    else
        initSaveData()
        return 0
    end
end
    
chipCountCache = getChipCount()

local function addChipCount(add)
    if mod:HasData() then
        local saveData = json.decode(mod:LoadData())
        if saveData and saveData.DadsSavings and saveData.DadsSavings.RunChipCount then
            local curChipCount = saveData.DadsSavings.RunChipCount
            chipCountCache = curChipCount + add
            local dataToSave = {
                DadsSavings = {
                    RunChipCount = curChipCount + add
                }
            }
            local encoded = json.encode(dataToSave)
            mod:SaveData(encoded)
        end
    else
        initSaveData()
    end
end



function mod:HUDOffset(x, y, anchor)
    local notches = math.floor(Options.HUDOffset * 10 + 0.5)
    local xoffset = (notches*2)
    local yoffset = ((1/8)*(10*notches+(-1)^notches+7))
    if anchor == 'topleft' then
      xoffset = x+xoffset
      yoffset = y+yoffset
    elseif anchor == 'topright' then
      xoffset = x-xoffset
      yoffset = y+yoffset
    elseif anchor == 'bottomleft' then
      xoffset = x+xoffset
      yoffset = y-yoffset
    elseif anchor == 'bottomright' then
      xoffset = x-xoffset * 0.8
      yoffset = y-notches * 0.6
    else
      error('invalid anchor provided. Must be one of: \'topleft\', \'topright\', \'bottomleft\', \'bottomright\'', 2)
    end
    local newPos = Vector(math.floor(xoffset + 0.5), math.floor(yoffset + 0.5))
    return newPos
end

---@param pickup EntityPickup 
function mod:PickupCollision(pickup, collider, low)

    local player = collider:ToPlayer()
    ---@cast player EntityPlayer
    if not player then return false end
    if not (pickup:GetSprite():IsPlaying("Idle") or pickup:GetSprite():WasEventTriggered("DropSound")) then return end
    if pickup.Price > player:GetNumCoins() then return end
    if not PlayerManager.AnyoneHasCollectible(DADS_SAVINGS) then return end
    if getChipCount() >= 10 then return end
    if pickup:IsShopItem() then
        if pickup.Price >= 0 then
            player:AddCoins(-(pickup.Price))
        elseif pickup.Price == -5 then
            player:TakeDamage(
                2,
                DamageFlag.DAMAGE_NO_PENALTIES
                | DamageFlag.DAMAGE_NO_MODIFIERS
                | DamageFlag.DAMAGE_INVINCIBLE,
                EntityRef(player),
                20
            )
        end
        player:AnimatePickup(pickup:GetSprite(), true)
        pickup:Remove()
    end

    local player1 = Isaac.GetPlayer()
    if pickup.SubType == CHIP_SUBTYPE_RED then
        addChipCount(1)
    end

    SFXManager():Play(SFX_CHIP_COLLECT, 1, 2, false, 1)
    pickup:GetSprite():Play("Collect", true)

    pickup:Die()
    pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

    return true
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.PickupCollision, PICKUP_VARIANT_CHIP)

---@param pickup EntityPickup
function mod:PickupUpdate(pickup)
    if not pickup:GetSprite():IsPlaying("Appear") then return end
    if pickup:GetSprite():IsEventTriggered("DropSound") then
        SFXManager():Play(SFX_CHIP_DROP, 1, 2, false, 1)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.PickupUpdate, PICKUP_VARIANT_CHIP)


local font = Font()
font:Load("font/pftempestasevencondensed.fnt")
local redSprite = Sprite()
redSprite:Load("dadssavings/resources/gfx/chip_ui.anm2", true)
redSprite:SetFrame("Idle", 0)

function mod:HudRender()
    local startPos = Vector(42, 31)
    if not PlayerManager.AnyoneHasCollectible(DADS_SAVINGS) then return end

    for i = 0, chipCountCache-1 do
        local sprite = Sprite()
        sprite:Load("dadssavings/resources/gfx/chip_ui.anm2", true)
        sprite:SetFrame("Idle", 0)
        local pos = mod:HUDOffset(startPos.X + 4*i, startPos.Y, 'topleft')
        redSprite:Render(Vector(pos.X - 7, pos.Y + 8), Vector.Zero, Vector.Zero)
    end
    
    -- font:DrawString(string.format("%02d", chipCountCache), pos.X , pos.Y, KColor(0.9, 0, 0.1,1), 0, true)

end
mod:AddCallback(ModCallbacks.MC_POST_HUD_RENDER, mod.HudRender)



---@param slot EntitySlot
function mod:SlotCollision(slot, player)
    if player.Type ~= EntityType.ENTITY_PLAYER then return end
    player = player:ToPlayer()
    ---@cast player EntityPlayer
    if not PlayerManager.AnyoneHasCollectible(DADS_SAVINGS) then return end
    if getChipCount() <= 0 then return end

    if slot:GetState() ~= 1 then return end

    local slotVar = slot.Variant

    if (slotVar == SlotVariant.BEGGAR 
    or slotVar == SlotVariant.DEVIL_BEGGAR
    or slotVar == SlotVariant.BATTERY_BUM
    or slotVar == SlotVariant.KEY_MASTER
    or slotVar == SlotVariant.BOMB_BUM
    or slotVar == SlotVariant.ROTTEN_BEGGAR) then
        local sprite = slot:GetSprite()
        sprite:ReplaceSpritesheet(2, "dadssavings/resources/gfx/items/slots/chipped_beggar.png", true)
        SFXManager():Play(SoundEffect.SOUND_SCAMPER, 1, 2, false, 1)
        sprite:Play("PayPrize")
        slot:SetState(2)
        slot:GetData().DadChipped = true
        if slotVar == SlotVariant.BOMB_BUM then
            local rng = slot:GetDropRNG()
            local chance = rng:RandomFloat()
            if chance < 0.65 then
                slot:SetPrizeType(1)
            elseif chance < 0.875 then
                slot:SetPrizeType(2)
            else
                slot:SetPrizeType(3)
            end
        end

    elseif slotVar == SlotVariant.SLOT_MACHINE then
        slot:SetState(2)
        slot:GetSprite():Play("Initiate")
        slot:SetTimeout(30)
        SFXManager():Play(SoundEffect.SOUND_COIN_SLOT, 1, 2, false, 1)
        slot:GetData().DadChipped = true

    elseif slotVar == SlotVariant.FORTUNE_TELLING_MACHINE then
        slot:SetState(2)
        slot:GetSprite():Play("Initiate")
        slot:SetTimeout(30)
        SFXManager():Play(SoundEffect.SOUND_COIN_SLOT, 1, 2, false, 1)
        slot:GetData().DadChipped = true
                  
        local rng = slot:GetDropRNG()
        local willPayOut = false
        local attempts = 0
        while willPayOut == false and attempts < 30 do
            local tempRNG = RNG()
            tempRNG:SetSeed(rng:GetSeed(), 30)

            local fortuneChance = Game().Difficulty == Difficulty.DIFFICULTY_HARD and 0.85 or 0.65

            if player:HasCollectible(CollectibleType.COLLECTIBLE_LUCKY_FOOT, false) then
                fortuneChance = fortuneChance * 0.46
            end

            local random = tempRNG:RandomFloat()

            if random < fortuneChance then
                rng:Next()
                attempts = attempts + 1
            else
                willPayOut = true
                break
            end
        end


    elseif slotVar == SlotVariant.BLOOD_DONATION_MACHINE then
        slot:SetState(2)
        slot:GetSprite():Play("Initiate")
        slot:SetTimeout(30)
        SFXManager():Play(SoundEffect.SOUND_BLOODBANK_TOUCHED, 1, 2, false, 1)

    elseif slotVar == SlotVariant.SHELL_GAME then
        --slot:SetPrizeType(10)
        -- slot:SetState(2)
        -- slot:GetSprite():Play("PayShuffle")

        -- slot:GetSprite():ReplaceSpritesheet(5, "dadssavings/resources/gfx/items/slots/chipped_beggar.png", true)
        -- slot:GetData().DadChipped = true

        -- local rng = slot:GetDropRNG()
        -- local chance = rng:RandomFloat()
        -- if chance < 0.25 then
        --     slot:SetPrizeType(10)
        -- elseif chance < 0.5 then
        --     slot:SetPrizeType(20)
        -- elseif chance < 0.75 then
        --     slot:SetPrizeType(30)
        -- else
        --     slot:SetPrizeType(40)
        -- end

        slot:GetSprite():ReplaceSpritesheet(5, "dadssavings/resources/gfx/items/slots/chipped_beggar.png", true)
        SFXManager():Play(SFX_CHIP_DROP, 1, 2, false, 1)
        addChipCount(-1)
        slot:GetData().DadChipped = true
        slot:GetData().RefundTo = player
        slot:GetData().OriginalCoinCount = player:GetNumCoins()
        player:AddCoins(1)
        return

    elseif slotVar == SlotVariant.HELL_GAME then
        -- slot:SetState(2)
        -- slot:GetSprite():Play("PayShuffle")

        -- slot:GetSprite():ReplaceSpritesheet(5, "dadssavings/resources/gfx/items/slots/chipped_beggar.png", true)
        -- slot:GetData().DadChipped = true

        -- local rng = slot:GetDropRNG()
        -- local chance = rng:RandomFloat()
        -- if chance < 0.154 then
        --     slot:SetPrizeType(20)
        -- elseif chance < 0.154 * 2 then
        --     slot:SetPrizeType(10)
        -- elseif chance < 0.154 * 3 then
        --     slot:SetPrizeType(40)
        -- elseif chance < 0.154 * 4 then
        --     slot:SetPrizeType(30)
        -- elseif chance < 0.154 * 5 then
        --     slot:SetPrizeType(300)
        -- elseif chance < 0.154 * 6 then
        --     slot:SetPrizeType(0)
        -- else
        --     slot:SetPrizeType(100)
        --     local item = Game():GetItemPool():GetCollectible(ItemPoolType.POOL_DEVIL, false, slot:GetDropRNG():GetSeed())
        --     slot:SetPrizeCollectible(item)
        -- end
        
        if player:GetDamageCooldown() <= 0 then
            slot:GetSprite():ReplaceSpritesheet(5, "dadssavings/resources/gfx/items/slots/chipped_beggar.png", true)
            SFXManager():Play(SFX_CHIP_DROP, 1, 2, false, 1)
            addChipCount(-1)
            slot:GetData().DadChipped = true

            player:GetData().DadsSavings = {IgnoreNextDamage = true}
            return
        else
            return false
        end

    
    elseif slotVar == SlotVariant.CONFESSIONAL then
        slot:SetState(2)
        slot:GetSprite():Play("Initiate")
        slot:SetTimeout(30)

        slot:GetSprite():ReplaceSpritesheet(0, "dadssavings/resources/gfx/items/slots/chipped_confessional.png", true)
        slot:GetSprite():PlayOverlay("HeartInsert", true)
        slot:GetData().DadChipped = true

        
        local willPayOut = false
        local attempts = 0
        while willPayOut == false and attempts < 30 do
            local tempRNG = RNG()
            tempRNG:SetSeed(slot:GetDropRNG():GetSeed(), 35)
            local prizeChance = Game().Difficulty == Difficulty.DIFFICULTY_HARD and 0.25 or 0.3
            if player:HasCollectible(CollectibleType.COLLECTIBLE_LUCKY_FOOT, false) then
                prizeChance = prizeChance * 1.5
            end
            if tempRNG:RandomFloat() < prizeChance then
                willPayOut = true
                break
            else
                slot:GetDropRNG():Next()
                attempts = attempts + 1
            end
        end

    elseif slotVar == SlotVariant.CRANE_GAME then
        slot:SetState(2)
        slot:GetSprite():Play("Initiate")
        slot:SetTimeout(30)
        SFXManager():Play(SoundEffect.SOUND_COIN_SLOT, 1, 2, false, 1)

        slot:GetSprite():ReplaceSpritesheet(3, "dadssavings/resources/gfx/items/slots/chipped_crane_game.png", true)
        slot:GetSprite():PlayOverlay("CoinInsert", true)
        slot:GetData().DadChipped = true
    else
        return
    end

    SFXManager():Play(SFX_CHIP_DROP, 1, 2, false, 1)
    addChipCount(-1)
    return false
end
mod:AddCallback(ModCallbacks.MC_PRE_SLOT_COLLISION, mod.SlotCollision)

local slotVarSpriteSheet = {
    [SlotVariant.BEGGAR] = "gfx/items/slots/slot_004_beggar.png",
    [SlotVariant.DEVIL_BEGGAR] = "gfx/items/slots/slot_005_devil_beggar.png",
    [SlotVariant.BATTERY_BUM] = "gfx/items/slots/slot_013_battery_bum.png",
    [SlotVariant.KEY_MASTER] = "gfx/items/slots/slot_007_key_master.png",
    [SlotVariant.BOMB_BUM] = "gfx/items/slots/slot_009_bomb_bum.png",
    [SlotVariant.ROTTEN_BEGGAR] = "gfx/items/slots/rotten_beggar.png",
    [SlotVariant.SHELL_GAME] = "gfx/items/slots/slot_006_shell_game.png",
    [SlotVariant.HELL_GAME] = "gfx/items/slots/hell_game.png",
    [SlotVariant.CONFESSIONAL] = "gfx/items/slots/confessional.png",
    [SlotVariant.CRANE_GAME] = "gfx/items/slots/crane_game.png",
}

---@param slot EntitySlot
function mod:SlotUpdate(slot)
    local slotVar = slot.Variant
    if not slot:GetData().DadChipped then return end
    if (slotVar == SlotVariant.BEGGAR 
    or slotVar == SlotVariant.DEVIL_BEGGAR
    or slotVar == SlotVariant.BATTERY_BUM
    or slotVar == SlotVariant.KEY_MASTER
    or slotVar == SlotVariant.BOMB_BUM
    or slotVar == SlotVariant.ROTTEN_BEGGAR) then
        local sprite = slot:GetSprite()
        if sprite:IsFinished("PayPrize") then
            sprite:ReplaceSpritesheet(2, slotVarSpriteSheet[slotVar], true)
            slot:GetData().DadChipped = false
        end

    elseif slotVar == SlotVariant.SHELL_GAME then
        local player = slot:GetData().RefundTo and slot:GetData().RefundTo:ToPlayer()
        ---@cast player EntityPlayer
        if player then
            if player:GetNumCoins() < slot:GetData().OriginalCoinCount then
                player:AddCoins(1)
            end
            slot:GetData().RefundTo = nil
            slot:GetData().OriginalCoinCount = nil
        end

        local sprite = slot:GetSprite()
        if sprite:IsEventTriggered("Shuffle") then
            sprite:ReplaceSpritesheet(5, slotVarSpriteSheet[slotVar], true)
            -- slot:SetState(5)
            -- slot:GetSprite():Play("Shell3Prize", true)
            slot:GetData().DadChipped = false

            local rng = slot:GetDropRNG()
            local willPayOut = false
            local attempts = 0

            while willPayOut == false and attempts < 30 do
                local tempRNG = RNG()
                tempRNG:SetSeed(rng:GetSeed(), 30)

                local success = tempRNG:RandomInt(3) == 0
                if success then
                    willPayOut = true
                    break
                else
                    rng:Next()
                    attempts = attempts + 1
                end
            end

        end

    elseif slotVar == SlotVariant.HELL_GAME then
        local sprite = slot:GetSprite()
        if sprite:IsEventTriggered("Shuffle") then
            sprite:ReplaceSpritesheet(5, slotVarSpriteSheet[slotVar], true)
            -- slot:SetState(5)
            -- slot:GetSprite():Play("Shell3Prize", true)
            slot:GetData().DadChipped = false

            local rng = slot:GetDropRNG()
            local willPayOut = false
            local attempts = 0

            while willPayOut == false and attempts < 30 do
                local tempRNG = RNG()
                tempRNG:SetSeed(rng:GetSeed(), 30)

                local success = tempRNG:RandomInt(3) == 0
                if success then
                    willPayOut = true
                    break
                else
                    rng:Next()
                    attempts = attempts + 1
                end
            end
        end

    elseif slotVar == SlotVariant.SLOT_MACHINE then
        local sprite = slot:GetSprite()
        if sprite:IsFinished("WiggleEnd") then
            slot:SetPrizeType(slot:GetDropRNG():RandomInt(10) + 3)
            sprite:Play("Prize", true)
            SFXManager():Play(SoundEffect.SOUND_SLOTSPAWN, 1, 2, false, 1)
            slot:GetData().DadChipped = false
        end

    elseif slotVar == SlotVariant.FORTUNE_TELLING_MACHINE then
        local sprite = slot:GetSprite()
        if slot:GetTimeout() == 0 then
            sprite:Play("Prize", true)
            SFXManager():Play(SoundEffect.SOUND_SLOTSPAWN, 1, 2, false, 1)
            slot:GetData().DadChipped = false
        end

    elseif slotVar == SlotVariant.CONFESSIONAL then
        local sprite = slot:GetSprite()
        if slot:GetTimeout() == 0 then
            sprite:ReplaceSpritesheet(0, slotVarSpriteSheet[slotVar], true)
            sprite:Play("Prize", true)
            slot:GetData().DadChipped = false
        end

    elseif slotVar == SlotVariant.CRANE_GAME then
        local sprite = slot:GetSprite()
        if sprite:IsFinished("Wiggle") then
            sprite:ReplaceSpritesheet(3, slotVarSpriteSheet[slotVar], true)
            sprite:Play("Prize", true)
            SFXManager():Play(SoundEffect.SOUND_THUMBSUP, 1, 2, false, 1)
            slot:GetData().DadChipped = false
        end
    else
        return
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_SLOT_UPDATE, mod.SlotUpdate)


mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, amount, flags, source, countdown)
    if not player:GetData().DadsSavings then return end
    if not player:GetData().DadsSavings.IgnoreNextDamage then return end

    player:GetData().DadsSavings.IgnoreNextDamage = false
    if source.Type == EntityType.ENTITY_SLOT and source.Variant == SlotVariant.HELL_GAME then
        return false
    end
end)


mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if not PlayerManager.AnyoneHasCollectible(DADS_SAVINGS) then return end
    local rng = pickup:GetDropRNG()
    if pickup.SubType == CoinSubType.COIN_PENNY and rng:RandomFloat() < PENNY_REPLACE_CHANCE then
        pickup:Morph(5, PICKUP_VARIANT_CHIP, CHIP_SUBTYPE_RED, false, true)
    end
end, PickupVariant.PICKUP_COIN)

if EID then
    EID:addCollectible(DADS_SAVINGS, "20% chance to turn pennies into Poker Chips" ..
    "#Poker Chips can be used to play beggars and slot machines for guranteed payouts")
end


-- mod:AddCallback(ModCallbacks.MC_HUD_RENDER, function()
--     local ent = Isaac.FindByType(EntityType.ENTITY_SLOT, SlotVariant.SHELL_GAME, 0, false, false)[1]
--     local slot = ent and ent:ToSlot()
--     ---@cast slot EntitySlot
--     if not slot then return end

--     Isaac.RenderText("Donation Value: "..tostring(slot:GetDonationValue() or 0), 30, 80, 1,1,1,1)

--     Isaac.RenderText("Prize Collectible: " .. tostring(slot:GetPrizeCollectible()), 30, 90, 1,1,1,1)

--     Isaac.RenderText("Prize Type: " .. tostring(slot:GetPrizeType()), 30, 100, 1,1,1,1)

--     Isaac.RenderText("State: " .. tostring(slot:GetState()), 30, 110, 1,1,1,1)

--     Isaac.RenderText("Timeout: " .. tostring(slot:GetTimeout()), 30, 120, 1,1,1,1)

--     Isaac.RenderText("Touch: " .. tostring(slot:GetTouch()), 30, 130, 1,1,1,1)

--     Isaac.RenderText("Anim: " .. tostring(slot:GetSprite():GetAnimation()), 30, 140, 1,1,1,1)

--     Isaac.RenderText("Anim Index: " .. tostring(slot:GetShellGameAnimationIndex()), 30, 150, 1,1,1,1)

--     Isaac.RenderText("Overlay Anim: " .. tostring(slot:GetSprite():GetOverlayAnimation()), 30, 160, 1,1,1,1)

--     Isaac.RenderText("Finished Wiggle: " .. tostring(slot:GetSprite():IsFinished("Wiggle")), 30, 170, 1,1,1,1)
-- end)