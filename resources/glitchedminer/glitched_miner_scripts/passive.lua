local mod = GLITCHED_MINER
local PibbySprite = Sprite()
PibbySprite:Load("glitchedminer/resources/gfx/grid/pibby_glitch.anm2")
PibbySprite:Play("Idle")

local ITEM_ID = mod.ItemId

---@return integer
local function TotalLuck()
    local sum = 0
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        sum = sum + player.Luck
    end
    return sum
end

---@param rock GridEntityRock
local function IsErrorOre(rock)
    if not PlayerManager.AnyoneHasCollectible(ITEM_ID) then
        return
    end
    local luck = TotalLuck()
    local luckBonus = math.max(0, math.min(10, luck))
    local chance = (10 + luckBonus*2)/100
    local rng = RNG(rock:GetSaveState().SpawnSeed)
    return rng:RandomFloat() < chance
end

---@param rock GridEntityRock
local function PostRockDestroy(_, rock)
    if not IsErrorOre(rock) then
        return
    end
    mod.TriggerRandomEvent(rock, PlayerManager.GetNumCollectibles(ITEM_ID))
end

mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, PostRockDestroy, GridEntityType.GRID_ROCK)

---@param rock GridEntityRock
local function PostRockRender(_, rock)
    if rock.State == 2 or not IsErrorOre(rock) then
        return
    end
    local pos = Isaac.WorldToScreen(rock.Position)
    PibbySprite:Render(pos)
end

mod:AddCallback(ModCallbacks.MC_POST_GRID_ENTITY_ROCK_RENDER, PostRockRender, GridEntityType.GRID_ROCK)

local function PostUpdate()
    PibbySprite:Update()
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)