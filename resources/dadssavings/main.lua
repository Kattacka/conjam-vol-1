ConboiMod = RegisterMod("ConboiMod", "1")
local mod = ConboiMod

local DADS_SAVINGS = Isaac.GetItemIdByName("Dad's Savings")

local PICKUP_VARIANT_CHIP = Isaac.GetEntityVariantByName("Red Poker Chip")

local CHIP_SUBTYPE_RED = Isaac.GetEntitySubTypeByName("Red Poker Chip")
local CHIP_SUBTYPE_GREEN = Isaac.GetEntitySubTypeByName("Green Poker Chip")
local CHIP_SUBTYPE_BLACK = Isaac.GetEntitySubTypeByName("Black Poker Chip")

local RED_CHIP_COUNTER = Isaac.GetNullItemIdByName("Red Chip")
local GREEN_CHIP_COUNTER = Isaac.GetNullItemIdByName("Green Chip")
local BLACK_CHIP_COUNTER = Isaac.GetNullItemIdByName("Black Chip")

local SFX_CHIP_DROP = Isaac.GetSoundIdByName("Poker Chip Drop")
local SFX_CHIP_COLLECT = Isaac.GetSoundIdByName("Poker Chip Collect")

local redChipCountCache = 0
local greenChipCountCache = 0
local blackChipCountCache = 0
for i, player in ipairs(PlayerManager.GetPlayers()) do
    redChipCountCache = redChipCountCache + player:GetEffects():GetNullEffectNum(RED_CHIP_COUNTER)
    greenChipCountCache = greenChipCountCache + player:GetEffects():GetNullEffectNum(GREEN_CHIP_COUNTER)
    blackChipCountCache = blackChipCountCache + player:GetEffects():GetNullEffectNum(BLACK_CHIP_COUNTER)
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
        player1:GetEffects():AddNullEffect(RED_CHIP_COUNTER)
    elseif pickup.SubType == CHIP_SUBTYPE_GREEN then
        player1:GetEffects():AddNullEffect(GREEN_CHIP_COUNTER)
    elseif pickup.SubType == CHIP_SUBTYPE_BLACK then
        player1:GetEffects():AddNullEffect(BLACK_CHIP_COUNTER)
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
    --print(pickup:GetSprite():GetAnimation())
    --if pickup.SubType ~= CHIP_SUBTYPE_BLACK then return end
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
local greenSprite = Sprite()
greenSprite:Load("dadssavings/resources/gfx/chip_ui.anm2", true)
greenSprite:SetFrame("Idle", 1)
local blackSprite = Sprite()
blackSprite:Load("dadssavings/resources/gfx/chip_ui.anm2", true)
blackSprite:SetFrame("Idle", 2)

function mod:HudRender()
    local startPos = Vector(42, 32)
    if not PlayerManager.AnyoneHasCollectible(DADS_SAVINGS) then return end
    local player1 = Isaac.GetPlayer()
    if redChipCountCache then
        local pos = mod:HUDOffset(startPos.X, startPos.Y, 'topleft')
        redSprite:Render(Vector(pos.X - 7, pos.Y + 8), Vector.Zero, Vector.Zero)
        font:DrawString(string.format("%02d", player1:GetEffects():GetNullEffectNum(RED_CHIP_COUNTER)), pos.X , pos.Y, KColor(0.9, 0, 0.1,1), 0, true)
    end
    if greenChipCountCache then
        local greenChipText = "Green Chips: " .. greenChipCountCache
        local pos = mod:HUDOffset(startPos.X, startPos.Y + 11, 'topleft')
        greenSprite:Render(Vector(pos.X - 7, pos.Y + 8), Vector.Zero, Vector.Zero)
        font:DrawString(string.format("%02d", player1:GetEffects():GetNullEffectNum(GREEN_CHIP_COUNTER)), pos.X , pos.Y, KColor(0, 0.9, 0.3, 1), 0, true)
    end
    if blackChipCountCache then
        local blackChipText = "Black Chips: " .. blackChipCountCache
        local pos = mod:HUDOffset(startPos.X, startPos.Y + 22, 'topleft')
        blackSprite:Render(Vector(pos.X - 7, pos.Y + 8), Vector.Zero, Vector.Zero)
        font:DrawString(string.format("%02d", player1:GetEffects():GetNullEffectNum(BLACK_CHIP_COUNTER)), pos.X , pos.Y, KColor(0.1, 0.1, 0.1, 1), 0, true)
    end


end
mod:AddCallback(ModCallbacks.MC_POST_HUD_RENDER, mod.HudRender)


local blackPayoutState = 12
local greenPayoutState = 13

mod:AddCallback(ModCallbacks.MC_PRE_SLOT_COLLISION, function(_, slot, player)
    if player.Type ~= EntityType.ENTITY_PLAYER then return end
    if slot:GetPrizeType() == blackPayoutState or slot:GetPrizeType() == greenPayoutState then return false end
    player = player:ToPlayer()
    local player1 = Isaac.GetPlayer()
    if slot:GetState() ~= 1 then return end

    if player1:GetEffects():GetNullEffectNum(BLACK_CHIP_COUNTER) > 0 then
        player1:GetEffects():RemoveNullEffect(BLACK_CHIP_COUNTER)
        local sprite = slot:GetSprite()
        --sprite:ReplaceSpritesheet(2, "gfx/items/slots/slot_007_key_master_gold.png", true)
        sprite:Play("PayPrize")
        slot:SetState(blackPayoutState)
        --slot:SetState(2)
        return false
    elseif player1:GetEffects():GetNullEffectNum(GREEN_CHIP_COUNTER) > 0 then
        player1:GetEffects():RemoveNullEffect(GREEN_CHIP_COUNTER)
        local sprite = slot:GetSprite()
        --sprite:ReplaceSpritesheet(2, "gfx/items/slots/slot_007_key_master_gold.png", true)
        sprite:Play("PayPrize")
        slot:SetState(2)
        slot:GetData().FreePayouts = 3
        --slot:SetState(2)
        return false
    elseif player1:GetEffects():GetNullEffectNum(RED_CHIP_COUNTER) > 0 then
        player1:GetEffects():RemoveNullEffect(RED_CHIP_COUNTER)
        local sprite = slot:GetSprite()
        --sprite:ReplaceSpritesheet(2, "gfx/items/slots/slot_007_key_master_gold.png", true)
        sprite:Play("PayPrize")
        slot:SetState(2)
        return false
    end
end, SlotVariant.BEGGAR)

---@param slot EntitySlot
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
    if slot:GetState() == blackPayoutState then

        local sprite = slot:GetSprite()
        if sprite:IsFinished("PayPrize") then
            sprite:Play("Prize")
        end

        if sprite:IsPlaying("Prize") then
            if sprite:IsEventTriggered("Prize") then
                local collectible = Game():GetItemPool():GetCollectible(ItemPoolType.POOL_BEGGAR, true, slot.DropSeed)
                local position = Game():GetRoom():FindFreePickupSpawnPosition(slot.Position + Vector(0, 80))
                slot:GetSprite():Play("Teleport")
                slot:SetState(4)
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectible, position, Vector.Zero, slot)
            elseif sprite:IsFinished("Prize") then
                slot:SetState(4)
                sprite:Play("Teleport")
            end
        end
    elseif slot:GetData().FreePayouts then
        local sprite = slot:GetSprite()
        if sprite:IsFinished("Prize") then
            slot:GetData().FreePayouts = slot:GetData().FreePayouts - 1
            if slot:GetData().FreePayouts > 0 then
                sprite:Play("PayPrize")
            end

        end
    end
end, SlotVariant.BEGGAR)



mod:AddCallback(ModCallbacks.MC_PRE_SLOT_COLLISION, function(_, slot, player)
    if player.Type ~= EntityType.ENTITY_PLAYER then return end
    if slot:GetPrizeType() == blackPayoutState or slot:GetPrizeType() == greenPayoutState then return false end
    player = player:ToPlayer()
    local player1 = Isaac.GetPlayer()
    if slot:GetState() ~= 1 then return end

    if player1:GetEffects():GetNullEffectNum(BLACK_CHIP_COUNTER) > 0 then
        player1:GetEffects():RemoveNullEffect(BLACK_CHIP_COUNTER)
        local sprite = slot:GetSprite()

        slot:SetState(3)
        sprite:Play("Wiggle")
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, 0, slot.Position, Vector.Zero, nil)
        for i = 0, 5 do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, NullPickupSubType.NO_COLLECTIBLE_TRINKET_CHEST, slot.Position, RandomVector():Resized(math.random()), nil)
        end
        --slot:SetState(2)
        return false
    elseif player1:GetEffects():GetNullEffectNum(GREEN_CHIP_COUNTER) > 0 then
        player1:GetEffects():RemoveNullEffect(GREEN_CHIP_COUNTER)
        local sprite = slot:GetSprite()

        sprite:Play("Initiate")
        SFXManager():Play(SoundEffect.SOUND_COIN_INSERT)
        for i = 0, 3 do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, NullPickupSubType.NO_COLLECTIBLE_TRINKET_CHEST, slot.Position, RandomVector():Resized(math.random()), nil)
        end
        
        return false
    elseif player1:GetEffects():GetNullEffectNum(RED_CHIP_COUNTER) > 0 then
        player1:GetEffects():RemoveNullEffect(RED_CHIP_COUNTER)
        local sprite = slot:GetSprite()

        sprite:Play("Wiggle")
        SFXManager():Play(SoundEffect.SOUND_COIN_INSERT)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, NullPickupSubType.NO_COLLECTIBLE_TRINKET_CHEST, slot.Position, RandomVector():Resized(math.random()), nil)
        
        return false
    end
end, SlotVariant.SLOT_MACHINE)






mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if not PlayerManager.AnyoneHasCollectible(DADS_SAVINGS) then return end
    local rng = pickup:GetDropRNG()
    if pickup.SubType == CoinSubType.COIN_PENNY and rng:RandomFloat() > 0.5 then
        pickup:Morph(5, PICKUP_VARIANT_CHIP, CHIP_SUBTYPE_RED, false, true)
    elseif pickup.SubType == CoinSubType.COIN_NICKEL  and rng:RandomFloat() > 0.5 then
        pickup:Morph(5, PICKUP_VARIANT_CHIP, CHIP_SUBTYPE_GREEN,   false, true)
    elseif pickup.SubType == CoinSubType.COIN_DIME  and rng:RandomFloat() > 0.5 then
        pickup:Morph(5, PICKUP_VARIANT_CHIP, CHIP_SUBTYPE_BLACK,   false, true)
    end
end, PickupVariant.PICKUP_COIN)

if EID then
    EID:addCollectible(DADS_SAVINGS, "50% chance to replace coins with chips#pennies -> red chips#nickles -> green chips#dimes -> black chips#when interacting with a beggar, a red chip will make it payout once for free, a green chip 3 times for free, and a black chip makes it instantly spawn an item and leave#when using a slot, a red chip makes it payout one time, green 3 times, and black 5 times and it explodes")
end