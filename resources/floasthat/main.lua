---@class ModReference
local mod = RegisterMod("Floast Hat", 1)

---@type table<string, Direction>
local WALK_ANIM_TO_DIRECTION = {
    WalkDown = Direction.DOWN,
    WalkUp = Direction.UP,
    WalkRight = Direction.RIGHT,
    WalkLeft = Direction.LEFT,
}

---@type table<Direction, string>
local DIRECTION_TO_ANIM_SUFFIX = {
    [Direction.DOWN] = "Down",
    [Direction.UP] = "Up",
    [Direction.RIGHT] = "Right",
    [Direction.LEFT] = "Left",
}

---@type Direction[]
local ANGLE_TO_DIRECTION = {
    Direction.RIGHT,
    Direction.DOWN,
    Direction.LEFT,
    Direction.UP,
}

---@param angle number
local function AngleToDirection(angle)
    return ANGLE_TO_DIRECTION[math.floor((angle % 360 + 45) / 90) % 4 + 1]
end

---@param vector Vector
---@return Direction
local function VectorToDirection(vector)
    if vector:Length() < 0.001 then
        return Direction.NO_DIRECTION
    end

    return AngleToDirection(vector:GetAngleDegrees())
end

---@param entity Entity
---@param id string
local function GetData(entity, id)
    local data = entity:GetData()
    data.______FE_FKJEFJKE_FDJFJKD_SDJ = data.______FE_FKJEFJKE_FDJFJKD_SDJ or {}
    data.______FE_FKJEFJKE_FDJFJKD_SDJ[id] = data.______FE_FKJEFJKE_FDJFJKD_SDJ[id] or {}
    return data.______FE_FKJEFJKE_FDJFJKD_SDJ[id]
end

--#region Floast Hat

local FloastHat = {}

FloastHat.ID = Isaac.GetItemIdByName("Floast Hat")
FloastHat.BULLET_HEIGHT_MULT = 3.95

---@param player EntityPlayer
function FloastHat:GetData(player)
    ---@class FloastHatData
    ---@field AnimFrame integer
    ---@field AnimOverride string
    ---@field AnimDir string
    return GetData(player, "FloastHat")
end

---@param player EntityPlayer
function FloastHat:GetOffset(player)
    return Vector(0, math.sin(player.FrameCount * 0.075) * 3 - 10 + (player:GetSprite():GetOverlayFrame() >= 2 and player:IsExtraAnimationFinished() and -2 or 0))
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, function (_, player)
    if player:HasCollectible(FloastHat.ID) then
        return FloastHat:GetOffset(player)
    end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    if player:HasCollectible(FloastHat.ID) then
        player.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if player:HasCollectible(FloastHat.ID) then
        local data = FloastHat:GetData(player)

        for _, v in ipairs(player:GetCostumeSpriteDescs()) do
            local sprite = v:GetSprite()
            local conf = v:GetItemConfig()

            if conf.Type == ItemType.ITEM_PASSIVE and conf.ID == FloastHat.ID then
                if data.AnimOverride and data.AnimFrame then
                    sprite:Play(data.AnimOverride .. (data.AnimDir or DIRECTION_TO_ANIM_SUFFIX[player:GetHeadDirection()]), true)
                    sprite:SetFrame(player.FrameCount - data.AnimFrame)

                    if player.FrameCount - data.AnimFrame > sprite:GetCurrentAnimationData():GetLength() then
                        data.AnimFrame = nil
                        data.AnimOverride = nil
                        data.AnimDir = nil
                    end
                end
            elseif WALK_ANIM_TO_DIRECTION[sprite:GetAnimation()] and not v:IsFlying() then
                sprite:SetFrame(0)
            end
        end

        local sprite = player:GetSprite()

        if WALK_ANIM_TO_DIRECTION[sprite:GetAnimation()] then
            sprite:SetFrame(0)
        end
    end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, function (_, player)
    if not player:HasCollectible(FloastHat.ID) then
        player.PositionOffset = FloastHat:GetOffset(player) * 1.535
    end
end, FloastHat.ID)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function (_, tear)
    if tear.FrameCount == 0 and not tear:HasTearFlags(TearFlags.TEAR_CHAIN) then
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()

        if player and player:HasCollectible(FloastHat.ID) then
            tear.Height = tear.Height + FloastHat:GetOffset(player).Y * FloastHat.BULLET_HEIGHT_MULT
        end
    end
end)

---@param player EntityPlayer
---@param pos Vector
mod:AddCallback(ModCallbacks.MC_POST_RENDER_PLAYER_HEAD, function (_, player, pos)
    ---@type Sprite, Sprite
    local host, floast

    for _, cost in ipairs(player:GetCostumeSpriteDescs()) do
        local conf = cost:GetItemConfig()

        if conf.Type == ItemType.ITEM_PASSIVE then
            if conf.ID == CollectibleType.COLLECTIBLE_HOST_HAT then
                host = cost:GetSprite()
            elseif conf.ID == FloastHat.ID then
                floast = cost:GetSprite()
            end
        end
    end

    if host or floast then
        local dir = player:GetHeadDirection()
        local frame = player:GetSprite():GetOverlayFrame()
        local y = 0
        local primary = player:HasCollectible(FloastHat.ID) and FloastHat.ID or CollectibleType.COLLECTIBLE_HOST_HAT
        ---@type table<CollectibleType, integer>
        local counts = {
            [CollectibleType.COLLECTIBLE_HOST_HAT] = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_HOST_HAT) - (primary == CollectibleType.COLLECTIBLE_HOST_HAT and 1 or 0),
            [FloastHat.ID] = player:GetCollectibleNum(FloastHat.ID) - (primary == FloastHat.ID and 1 or 0)
        }
        ---@type table<CollectibleType, Sprite?>
        local idToSprite = {
            [CollectibleType.COLLECTIBLE_HOST_HAT] = host,
            [FloastHat.ID] = floast,
        }

        if idToSprite[primary] then
            local anim = idToSprite[primary]:GetAnimation()

            if anim:find("Guard") then
                y = y + 5
            elseif anim:find("Shooting") then
                y = y - (idToSprite[primary]:GetFrame() <= 8 and 20 or 2) * idToSprite[primary]:GetLayerFrameData(0):GetScale().Y
            end

            y = y * player.SpriteScale.Y

            for _, v in ipairs(player:GetHistory():GetCollectiblesHistory()) do
                if not v:IsTrinket() then
                    local id = v:GetItemID()
                    local sprite = idToSprite[id]
                    if sprite and counts[id] > 0 then
                        local prevAnim = sprite:GetAnimation()
                        local prevFrame = sprite:GetFrame()
                        local prevScale = sprite.Scale
                        local prevColor = sprite.Color

                        counts[id] = counts[id] - 1
                        y = y - 18 * player.SpriteScale.Y

                        sprite:Play("Head" .. DIRECTION_TO_ANIM_SUFFIX[dir], true)
                        sprite:SetFrame(frame)
                        sprite.Scale = player.SpriteScale
                        sprite.Color = player.Color
                        sprite:Render(pos + Vector(0, y))
                        sprite:Play(prevAnim, true)
                        sprite:SetFrame(prevFrame)
                        sprite.Scale = prevScale
                        sprite.Color = prevColor
                    end
                end
            end
        end
    end
end)

---@param player EntityPlayer
---@param amt number
---@param flags DamageFlag
---@param source EntityRef
mod:AddPriorityCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, CallbackPriority.IMPORTANT, function (_, player, amt, flags, source)
    if player:HasCollectible(FloastHat.ID) then
        if flags & DamageFlag.DAMAGE_EXPLOSION ~= 0 then
            local data = FloastHat:GetData(player)

            data.AnimOverride = "Guard"
            data.AnimFrame = player.FrameCount

            return false
        elseif source.Entity and source.Entity.Type == EntityType.ENTITY_PROJECTILE then
            if source.Entity:ToProjectile().Height * FloastHat.BULLET_HEIGHT_MULT >= -FloastHat:GetOffset(player).Y then
                return false
            elseif player:GetCollectibleRNG(FloastHat.ID):RandomFloat() <= 0.25 then
                if source.Entity.SpawnerEntity then
                    local vect = (source.Entity.SpawnerEntity.Position - player.Position):Resized(10)
                    local dir = VectorToDirection(vect)

                    for i = -1, 1 do
                        local tear = player:FireTear(player.Position, vect:Rotated(i * 10), true, true, false, player)
                        tear.Height = tear.Height - 133
                    end

                    if dir ~= Direction.NO_DIRECTION then
                        local data = FloastHat:GetData(player)
                        data.AnimOverride = "Shooting"
                        data.AnimFrame = player.FrameCount
                        data.AnimDir = DIRECTION_TO_ANIM_SUFFIX[dir]
                    end
                end

                return false
            end
        end
    end
end)

if EID then
    EID:addCollectible(FloastHat.ID, "Grants immunity to explosions and falling projectiles#25% chance to reflect enemy shots#Flight")
end
--#endregion