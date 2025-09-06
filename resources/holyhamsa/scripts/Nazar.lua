local this = {}
local ORBIT_FAMILIAR_COUNT_DISTANCE_OFFSET = 4
local FAMILIAR_ORBIT_OFFSET = Vector(8, 2)

local function GetAllNazarsOfParent(Count,Parent)
	local buffer = 1
	for i=1,#Count, 1 do
		if Count[i].Parent == nil then
			--Haha you got no parents 
		else
			if Count[i].Parent.Index and Count[i].Parent.Index == Parent.Index then
				buffer = buffer + 1
			end
		end
	end
	return buffer
end

function this:NazarUpdate(familiar)
	if familiar.SubType ~= HolyHamsaMod.FamiliarVariantCustom.NAZAR.subType then
		return
	end
	local Parent = familiar.Parent
	local Player = familiar.Player:ToPlayer() 

	if Parent ~= nil then
		local count = Isaac.FindByType(
			EntityType.ENTITY_FAMILIAR,
			HolyHamsaMod.FamiliarVariantCustom.NAZAR.variant,
			HolyHamsaMod.FamiliarVariantCustom.NAZAR.subType
		)
		local targetCount = GetAllNazarsOfParent(count,Parent)
		familiar.OrbitDistance = Vector(
			(ORBIT_FAMILIAR_COUNT_DISTANCE_OFFSET * targetCount) + 20,
			(ORBIT_FAMILIAR_COUNT_DISTANCE_OFFSET * targetCount) + 20 
		) + FAMILIAR_ORBIT_OFFSET 
		familiar.Velocity = (familiar:GetOrbitPosition(Parent.Position) - familiar.Position) * 0.25
		familiar:Shoot()
	else
		if familiar.State ~=  5 then
			if familiar.State ~= 16 then
				familiar.State = 16
				Isaac.CreateTimer(function ()
				SFXManager():Play(SoundEffect.SOUND_ULTRA_GREED_SLOT_STOP, 0.5, 0, false, 1)
				familiar:SetColor(Color(1, 1, 1, 1, 1, 1, 1), 5, 15, true, true)
				familiar.State = 5
			end, 15, 1, false)
			end
		else
		familiar.Velocity = familiar.Velocity * 0.95
		if Game():GetFrameCount() / 20 % 1 == 0 then
			SFXManager():Play(SoundEffect.SOUND_BULB_FLASH)
			familiar:SetColor(Color(1, 1, 1, 1, 1, 1, 1), 5, 15, true, true)
		end
		if Player:GetShootingInput():LengthSquared() ~= 0 then
			local input = Player:GetShootingInput()
			Isaac.CreateTimer(function ()
				local laser = Player:FireTechLaser(familiar.Position, LaserOffset.LASER_BRIMSTONE_OFFSET,input, false, false, familiar, 2)
				laser:SetTimeout(5)
				laser.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				if Player.TearColor.R == 1 and Player.TearColor.G == 1 and Player.TearColor.B == 1 then
					local Color = Color(0,0,0,10,0,0,10)
					Color:SetColorize(0, 0, 1, 1)
					laser.Color = Color
				else
					laser.Color = Player.TearColor
				end
				laser.TearFlags = Player.TearFlags
				familiar:Remove()
				for i=1,3,1 do
					local angle = math.random(1, 360)
					local Particle = Isaac.Spawn(1000,98,0,familiar.Position,Vector.FromAngle(angle) * 3,familiar)
					Particle.Color = Color(0,0,1,1)
				end
				SFXManager():Play(SoundEffect.SOUND_GLASS_BREAK)
				Isaac.Spawn(1000,97,0,familiar.Position,Vector.Zero,familiar)
			end, math.random(0,5), 1, false)
		end
		end
	end
end

function this:NazarShoot(tear)
	local familiar = tear.SpawnerEntity:ToFamiliar()
	if familiar and familiar.SubType ~= HolyHamsaMod.FamiliarVariantCustom.NAZAR.subType then
		return
	end
	SFXManager():Play(509, 0.5, 0, false, 1 + math.random())
	local Player = familiar.Player:ToPlayer() 
	if Player == nil then
		return
	end
	tear.TearFlags = Player.TearFlags
	tear.Color = Player.TearColor
	tear.CollisionDamage = Player.Damage
end



function this:init()
	HolyHamsaMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, this.NazarUpdate,HolyHamsaMod.FamiliarVariantCustom.NAZAR.variant)
	HolyHamsaMod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_FIRE_PROJECTILE, this.NazarShoot,HolyHamsaMod.FamiliarVariantCustom.NAZAR.variant)
end

return this