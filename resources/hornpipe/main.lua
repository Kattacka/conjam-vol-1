-- messy code

---@class ModReference
local mod = RegisterMod("Hornpipe", 1)
local COLLECTIBLE_HORNPIPE = Isaac.GetItemIdByName("Hornpipe")
local NUM_STABS = 5
local STAB_DELAY = 30
if EID then
    EID:addCollectible(COLLECTIBLE_HORNPIPE, "Wormwood stabs through the floor " .. NUM_STABS .. " times over the span of " .. STAB_DELAY // 30 * NUM_STABS .. " seconds#Each stab creates a pit and damages anything overhead#Prioritizes enemies by health, then obstacles by worth, then players")
end
local SOUND_HORNPIPE = Isaac.GetSoundIdByName("Hornpipe")
local EFFECT_HORNPIPE = Isaac.GetEntityVariantByName("Hornpipe Effect")
local SFX = SFXManager()
local GAME = Game()

---@type GridEntity[]
local GRID_PRIORITIES = {
    GridEntityType.GRID_ROCK_ALT2,
    GridEntityType.GRID_ROCK_SS,
    GridEntityType.GRID_ROCKT,
    GridEntityType.GRID_ROCK_GOLD,
    GridEntityType.GRID_ROCK_BOMB,
    GridEntityType.GRID_ROCK_ALT,
    GridEntityType.GRID_ROCK,
    GridEntityType.GRID_TNT,
    GridEntityType.GRID_POOP,
}
local function GetEnemies()
    ---@type Entity[]
    local enemies = {}
    for _, v in ipairs(Isaac.GetRoomEntities()) do
        if v:IsActiveEnemy(false) and v:IsVulnerableEnemy() and not v:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            enemies[#enemies + 1] = v
        end
    end
    table.sort(enemies, function (a, b)
        return a.MaxHitPoints > b.MaxHitPoints
    end)
    return enemies
end

---@param player? EntityPlayer
local function Lament(player)
    player = player or Isaac.GetPlayer()
    local rng = player:GetCollectibleRNG(COLLECTIBLE_HORNPIPE)
    local enemies = GetEnemies()
    local room = GAME:GetRoom()
    if #enemies > 0 then
        local enemy = enemies[1]
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EFFECT_HORNPIPE,
            0,
            room:GetGridPosition(room:GetGridIndex(enemy.Position)),
            Vector.Zero,
            player
        )
    else
        ---@type table<GridEntityType, GridEntity>
        local grids = {}
        for i = 0, room:GetGridSize() do
            local grid = room:GetGridEntity(i)
            if grid and grid.CollisionClass ~= GridCollisionClass.COLLISION_NONE then
                local type = grid:GetType()
                grids[type] = grids[type] or {}
                grids[type][#grids[type] + 1] = grid
            end
        end
        local activated
        for _, v in ipairs(GRID_PRIORITIES) do
            if grids[v] then
                local grid = grids[v][rng:RandomInt(1, #grids[v])]
                activated = true
                -- grid:Destroy(true)
                Isaac.Spawn(
                    EntityType.ENTITY_EFFECT,
                    EFFECT_HORNPIPE,
                    0,
                    grid.Position,
                    Vector.Zero,
                    player
                )
                break
            end
        end
        if not activated then
            Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EFFECT_HORNPIPE,
                0,
                room:GetGridPosition(room:GetGridIndex(player.Position)),
                Vector.Zero,
                player
            )
        end
    end
end

local queue = 0
---@type integer?
local frame

---@param rng RNG
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player)
    SFX:Play(SOUND_HORNPIPE)
    queue = queue + NUM_STABS
    frame = frame or GAME:GetFrameCount()
    -- return true
    player:AnimateCollectible(COLLECTIBLE_HORNPIPE)
end, COLLECTIBLE_HORNPIPE)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    queue = 0
    frame = nil
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
    if not frame then return end
    local diff = GAME:GetFrameCount() - frame + 1
    if diff % STAB_DELAY == 0 then
        -- GAME:ShakeScreen(10)
        -- SFX:Play(SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
        -- Isaac.CreateTimer(Lament, 25, 1, false)
        Lament()
        queue = queue - 1
        if queue <= 0 then
            queue = 0
            frame = nil
        end
    end
end)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function (_, effect)
    local sprite = effect:GetSprite()
    sprite:Play("Attack2", true)
    effect.SpriteOffset = Vector(0, -6)
end, EFFECT_HORNPIPE)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function (_, effect)
    local player = effect.SpawnerEntity and effect.SpawnerEntity:ToPlayer() or Isaac.GetPlayer()
    local sprite = effect:GetSprite()
    if sprite:GetFrame() == 4 then
        local room = GAME:GetRoom()
        local idx = room:GetGridIndex(effect.Position)
        -- room:DestroyGrid(idx, true)
        local grid = room:GetGridEntity(idx)
        if grid then
            grid:Destroy()
        end
        -- GAME:GetRoom():DestroyGrid()
    end
    if sprite:IsEventTriggered("Shoot") then
        local room = GAME:GetRoom()
        if room:HasWater() then
            Isaac.Spawn(EntityType.ENTITY_EFFECT, 132, 0, effect.Position, Vector.Zero, nil)
            SFX:Play(SoundEffect.SOUND_BOSS2_DIVE)
        end
        local idx = room:GetGridIndex(effect.Position)
        if not room:CanSpawnObstacleAtPosition(idx, false) then
            effect:GetData().Adhjsghjdjshdjh = true
        end
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            player.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        end
        local grid = Isaac.GridSpawn(GridEntityType.GRID_PIT, 0, effect.Position, true)

        if grid then
            grid:PostInit()
        end
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            player:AddCacheFlags(CacheFlag.CACHE_FLYING, true)
        end
        GAME:ShakeScreen(10)
        SFX:Play(SoundEffect.SOUND_ROCK_CRUMBLE)
        for i = 1, 5 do
            local particle = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.ROCK_PARTICLE,
                0,
                effect.Position,
                RandomVector():Resized(10) * math.random(),
                nil
            ):ToEffect()
            particle:Update()
            particle.m_Height = particle.m_Height * 0.5
        end

        ---@type table<integer, true>
        local players = {}

        for _, v in ipairs(Isaac.FindInRadius(effect.Position, 30)) do
            if v.Type == EntityType.ENTITY_PLAYER then
                v:TakeDamage(1, 0, EntityRef(effect), 0)
                players[GetPtrHash(v)] = true
            else
                v:TakeDamage(25, DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(effect), 0)
            end
        end

        GAME:ButterBeanFart(effect.Position, 80, player, false, true)
    end
    if sprite:GetFrame() == 17 then
        if effect:GetData().Adhjsghjdjshdjh then
            local room = GAME:GetRoom()
            local grid = room:GetGridEntityFromPos(effect.Position)
            local pit = grid and grid:ToPit()
            if pit then
                pit:MakeBridge(nil)
            end
            local poof = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.POOF02,
                2,
                effect.Position,
                Vector.Zero,
                nil
            )
            poof.Color = Color(1, 1, 1, 0.75)
            poof.SpriteScale = Vector.One * 0.8
            poof.SpriteOffset = Vector(0, 8)
        end
        effect:Remove()
    end
    -- sprite:Play("Attack2", true)
end, EFFECT_HORNPIPE)