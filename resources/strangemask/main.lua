SpoopItemJam = RegisterMod("SpoopItemJam", 1) ---@type ModReference

SpoopItemJam.COLLECTIBLE_MISK = Isaac.GetItemIdByName("Strange Mask")

local DMG_MULT = 0.8
local POISON_TICK_DELAY_TEARS_MULT = 1.25

if(EID) then
    EID:addCollectible(
        SpoopItemJam.COLLECTIBLE_MISK,
        "\2 x0.8 Damage#{{Poison}} Poison tears#Delay between poison damage ticks is equal to " .. POISON_TICK_DELAY_TEARS_MULT .. "x your firedelay (max of 0.67s)",
        "Strange Mask"
    )
end

---@param pl EntityPlayer
---@param flag CacheFlag
local function evaluateCache(_, pl, flag)
    if(not pl:HasCollectible(SpoopItemJam.COLLECTIBLE_MISK)) then return end

    --local mult = pl:GetCollectibleNum(SpoopItemJam.COLLECTIBLE_MISK)

    if(flag & CacheFlag.CACHE_TEARFLAG == CacheFlag.CACHE_TEARFLAG) then
        pl.TearFlags = pl.TearFlags | TearFlags.TEAR_POISON
    elseif(flag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE) then
        pl.Damage = pl.Damage*DMG_MULT
    end
end
SpoopItemJam:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateCache)

---@param npc EntityNPC
local function miskPoisonedUpdate(_, npc)
    if(not PlayerManager.AnyoneHasCollectible(SpoopItemJam.COLLECTIBLE_MISK)) then return end

    local pl = PlayerManager.FirstCollectibleOwner(SpoopItemJam.COLLECTIBLE_MISK) or Isaac.GetPlayer()

    ---@diagnostic disable-next-line: undefined-field
    if(npc:GetPoisonCountdown()<=0) then return end

    if(npc:GetPoisonDamageTimer()<=2) then
        npc:SetPoisonDamageTimer(20+npc:GetPoisonDamageTimer())
    end
    if(npc:GetPoisonDamageTimer()==22) then
        local fd = math.floor(pl.MaxFireDelay)
        fd = 20-math.min(math.max(math.floor(fd*POISON_TICK_DELAY_TEARS_MULT),3), 19)

        npc:SetPoisonDamageTimer(2+fd)
    end
end
SpoopItemJam:AddCallback(ModCallbacks.MC_NPC_UPDATE, miskPoisonedUpdate)