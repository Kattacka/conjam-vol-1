-- aka Tech VI?

local mod = RegisterMod("Basement 95 Item Jam Aero Submission", 1)
local game = Game()
local sfx = SFXManager()

local itemID = Isaac.GetItemIdByName("Hexagonal Core")
local sfxID = Isaac.GetSoundIdByName("hexagonal_core_jingle")

local LASER_SPAWN_POS = 850
local LASER_VELOCITY = 15
local LASER_TIMEOUT = 60
-- Chosen at random
local LASER_COLORS = {
    Color(1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0), -- red
    Color(1, 1, 1, 1, 0, 0, 0, 4, 2, 1, 1), -- orange
    Color(1, 1, 1, 1, 0, 0, 0, 4, 4, 1, 1), -- yellow
    Color(1, 1, 1, 1, 0, 0, 0, 1, 4, 1.5, 1), -- green
    Color(1, 1, 1, 1, 0, 0, 0, 1, 4, 4, 1), -- cyan
    Color(1, 1, 1, 1, 0, 0, 0, 2, 1, 3, 1), -- purple
    Color(1, 1, 1, 1, 0, 0, 0, 4, 1, 4, 1), -- magenta
    Color(1, 1, 1, 1, 0, 0, 0, 4, 4, 4, 1), -- white
}

local rotationAmount = 0
local points = {}

-- Can be used for a potential settings menu
local playHexagonalCoreLaserSFX = true
local playHexagonalCoreJingle = true

-- Returns number + 1, but if number = 6 returns 1
local function GetNextHexaLaserIndex(num)
    return math.max((num + 1) % 7, 1)
end

local function CleanHexaLasers()
    for _, laser in ipairs(Isaac.FindByType(EntityType.ENTITY_LASER, LaserVariant.THIN_RED)) do
        if laser:GetData().ItemJamAeronaut_HexagonLaserIndex then
            laser:Remove()
        end
    end
    points = {}
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function (_)
    if not PlayerManager.AnyoneHasCollectible(itemID) then return end

    local room = game:GetRoom()
    if not room:IsClear() then
        if #points == 0 then
            local player = PlayerManager.FirstCollectibleOwner(itemID) or Isaac.GetPlayer(0)
            local rng = RNG(math.max(Random(), 1))
            local center = room:GetCenterPos()
            for i = 1, 6 do
                points[i] = center + Vector(LASER_SPAWN_POS, 0):Rotated(60 * (i - 1))
            end

            local exclusionPoint = rng:RandomInt(1, 6)
            rotationAmount = math.max(rng:RandomInt(-5, 5), 0)
            rotationAmount = rotationAmount * (rng:RandomInt(2) == 0 and 1 or -1)
            local randomColor = LASER_COLORS[rng:RandomInt(1, #LASER_COLORS)]
            for i = 1, 6 do
                if i ~= exclusionPoint then
                    local point1 = points[i]
                    local point2 = points[GetNextHexaLaserIndex(i)]
                    local vecToPoint2 = point2 - point1
                    local hexagonLaser = EntityLaser.ShootAngle(LaserVariant.THIN_RED, point1, vecToPoint2:GetAngleDegrees(), LASER_TIMEOUT, Vector.Zero, player)
                    hexagonLaser.Parent = nil
                    hexagonLaser.MaxDistance = vecToPoint2:Length()
                    hexagonLaser.CollisionDamage = 3 + player:GetTearPoisonDamage() / 2
                    hexagonLaser:GetData().ItemJamAeronaut_HexagonLaserIndex = i
                    hexagonLaser.Color = randomColor
                    if exclusionPoint == GetNextHexaLaserIndex(i) then
                        hexagonLaser:GetData().ItemJamAeronaut_HexagonLaserHasExcludedIndex = true
                    end
                end
            end
            if not playHexagonalCoreLaserSFX then
                Isaac.CreateTimer(function ()
                    sfx:Stop(SoundEffect.SOUND_REDLIGHTNING_ZAP)
                end, 1, 1, true)
            end

            return
        end
    end

    if #points > 0 then
        local center = room:GetCenterPos()
        for i = 1, 6 do
            if points[i] then
                points[i] = points[i] + (center - points[i]):Resized(LASER_VELOCITY)
                points[i] = center + (points[i] - center):Rotated(rotationAmount)
            end
        end

        if points[1] and center:Distance(points[1]) < 5 then
            CleanHexaLasers()
        end
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function (_, laser)
    local hexaLaserIndex = laser:GetData().ItemJamAeronaut_HexagonLaserIndex
    if not hexaLaserIndex then return end

    local point1, point2 = points[hexaLaserIndex], points[GetNextHexaLaserIndex(hexaLaserIndex)]
    if not point1 or not point2 then return end
    local vecToPoint2 = point2 - point1

    laser.Position = point1
    laser.MaxDistance = vecToPoint2:Length()
    laser.Angle = vecToPoint2:GetAngleDegrees()
end)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function (_, entity)
    local data = entity:GetData()
    local hexaLaserIndex = data.ItemJamAeronaut_HexagonLaserIndex
    if not hexaLaserIndex then return end
    points[hexaLaserIndex] = nil
    if data.ItemJamAeronaut_HexagonLaserHasExcludedIndex then
        points[GetNextHexaLaserIndex(hexaLaserIndex)] = nil
    end
end, EntityType.ENTITY_LASER)

-- Jingle
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not player.QueuedItem.Item or player.QueuedItem.Item.ID ~= itemID then return end
    if not playHexagonalCoreJingle then return end

    for _, sound in ipairs({SoundEffect.SOUND_CHOIR_UNLOCK, SoundEffect.SOUND_POWERUP1, SoundEffect.SOUND_POWERUP2, SoundEffect.SOUND_POWERUP3, SoundEffect.SOUND_DEVILROOM_DEAL}) do
        if sfx:IsPlaying(sound) then
            sfx:Stop(sound)
            sfx:Play(sfxID)
            break
        end
    end
end)

-- Description
if EID then
    EID:addCollectible(itemID, "Periodically spawns 5 lasers in a hexagon pattern which move from outside the room towards the center #Each laser deals half the {{Damage}} player's damage + 3")
end