local this = {}

---@class BootData
---@field current_grid_index integer
---@field target_grid_index integer
---@field start_pos Vector
---@field target_pos Vector
---@field state integer
---@field last_move_direction integer

---@class MoveRule
---@field direction Vector
---@field range integer
---@field condition function?

local BootState = {
	IDLE = 1,
	START_MOVE = 2,
	MOVING = 3,
	STOP_MOVE = 4,
}

local MOVE_FREQUENCY = 20
local MOVE_SPEED = 8
local GRID_SIZE = 40
local PLAYER_DISTANCE_THRESHOLD = 2
local MAX_BOOT_RANGE = 20
local BOOT_MOVING_UP_SPRITE_OFFSET = Vector(0, 10)
local SOUNDS = {
	[BucketOfBootsMod.BootSubType.QUEEN] = {
		sound = BucketOfBootsMod.SoundEffect.QUEEN_STEP,
		pitch_min = 0.9,
		pitch_max = 1.1,
		volume = 2,
	},
	[BucketOfBootsMod.BootSubType.PAWN] = {
		sound = BucketOfBootsMod.SoundEffect.PAWN_STEP,
		pitch_min = 0.8,
		pitch_max = 1.1,
	},
	[BucketOfBootsMod.BootSubType.BISHOP] = {
		sound = SoundEffect.SOUND_SUMMON_POOF,
		pitch_min = 1,
		pitch_max = 1,
		volume = 2,
	},
	[BucketOfBootsMod.BootSubType.ROOK] = {
		sound = BucketOfBootsMod.SoundEffect.ROOK_STEP,
		pitch_min = 1,
		pitch_max = 1,
		volume = 1,
	},
}
local reserved_grid_indices = {}

---@param boot EntityNPC
---@return BootData
local function get_boot_data(boot)
	---@type BootData?
	local boot_data = boot:GetData().BootEnemyData

	if not boot_data then
		local room = Game():GetRoom()
		local grid_index = room:GetGridIndex(boot.Position)
		local clamped_position = room:GetGridPosition(grid_index)

		boot_data = {
			current_grid_index = grid_index,
			target_grid_index = grid_index,
			start_pos = clamped_position,
			target_pos = clamped_position,
			state = BootState.IDLE,
			last_move_direction = Direction.DOWN,
		}

		boot:GetData().BootEnemyData = boot_data
	end

	return boot_data
end

---@param entity Entity
local function get_entity_grid_position(entity)
	local room = Game():GetRoom()
	local grid_index = room:GetGridIndex(entity.Position)
	return room:GetGridPosition(grid_index)
end

---@param boot EntityNPC
---@param target Entity
---@param potential_directions Vector[]
---@param max_range number
local function get_valid_directions(boot, target, potential_directions, max_range)
	local room = Game():GetRoom()
	local data = get_boot_data(boot)
	local current_pos = room:GetGridPosition(data.current_grid_index)
	local target_pos = get_entity_grid_position(target)

	local all_valid_moves = {}

	for _, dir in pairs(potential_directions) do
		for i = 1, max_range do
			local move_vec = dir * GRID_SIZE * i
			local next_pos = current_pos + move_vec
			local next_grid_index = room:GetGridIndex(next_pos)

			if room:GetGridCollision(next_grid_index) ~= GridCollisionClass.COLLISION_NONE then
				break
			end

			local blocking_entity = room:CheckLine(current_pos, move_vec, LineCheckMode.ENTITY, 950)
			if blocking_entity and blocking_entity ~= target then
				break
			end

			table.insert(all_valid_moves, { Position = next_pos, Direction = dir, Range = i })

			if blocking_entity and blocking_entity == target then
				break
			end
		end
	end

	if #all_valid_moves == 0 then
		return {}
	end

	table.sort(all_valid_moves, function(a, b)
		return a.Position:Distance(target_pos) < b.Position:Distance(target_pos)
	end)

	local best_distance = all_valid_moves[1].Position:Distance(target_pos)
	local move_set = {}

	for _, move in ipairs(all_valid_moves) do
		if move.Position:Distance(target_pos) <= best_distance + 1 then
			table.insert(move_set, { direction = move.Direction, range = move.Range })
		else
			break
		end
	end

	return move_set
end

---@type table<integer, MoveRule[] | function>
local BootMoveSets = {
	[BucketOfBootsMod.BootSubType.PAWN] = function(boot)
		local player = boot:GetPlayerTarget()

		if not player then
			return {}
		end

		local potential_directions = {
			Vector(0, 1),
			Vector(0, -1),
			Vector(1, 0),
			Vector(-1, 0),
		}

		local move_set = get_valid_directions(boot, player, potential_directions, 1)

		return move_set
	end,
	[BucketOfBootsMod.BootSubType.BISHOP] = function(boot)
		local player = boot:GetPlayerTarget()

		if not player then
			return {}
		end

		local potential_directions = {
			Vector(1, 1),
			Vector(1, -1),
			Vector(-1, 1),
			Vector(-1, -1),
		}

		local move_set = get_valid_directions(boot, player, potential_directions, MAX_BOOT_RANGE)

		return move_set
	end,
	[BucketOfBootsMod.BootSubType.ROOK] = function(boot)
		local player = boot:GetPlayerTarget()

		if not player then
			return {}
		end

		local data = get_boot_data(boot)
		local room = Game():GetRoom()

		local potential_directions = {
			Vector(0, 1),
			Vector(0, -1),
			Vector(1, 0),
			Vector(-1, 0),
		}
		local move_set = get_valid_directions(boot, player, potential_directions, MAX_BOOT_RANGE)

		return move_set
	end,
	[BucketOfBootsMod.BootSubType.QUEEN] = function(boot)
		local player = boot:GetPlayerTarget()

		if not player then
			return {}
		end

		local potential_directions = {
			Vector(0, 1),
			Vector(0, -1),
			Vector(1, 0),
			Vector(-1, 0),
			Vector(1, 1),
			Vector(1, -1),
			Vector(-1, 1),
			Vector(-1, -1),
		}

		local move_set = get_valid_directions(boot, player, potential_directions, MAX_BOOT_RANGE)

		return move_set
	end,
}

---@param boot EntityNPC
local function get_valid_moves(boot)
	local move_rules = BootMoveSets[boot.SubType](boot)

	local room = Game():GetRoom()
	local data = get_boot_data(boot)
	local current_pos = room:GetGridPosition(data.current_grid_index)
	local valid_moves = {}

	for _, rule in pairs(move_rules) do
		for i = 1, rule.range do
			local next_pos = current_pos + (rule.direction * GRID_SIZE * i)
			if not room:IsPositionInRoom(next_pos, 0) then
				break
			end

			local grid_index = room:GetGridIndex(next_pos)
			local grid_entity = room:GetGridEntityFromPos(next_pos)

			local is_blocked = false
			if reserved_grid_indices[grid_index] then
				is_blocked = true
			elseif grid_entity and grid_entity.CollisionClass ~= GridCollisionClass.COLLISION_NONE then
				is_blocked = true
			end

			if is_blocked then
				break
			else
				table.insert(valid_moves, grid_index)
			end
		end
	end

	return valid_moves
end

---@param boot EntityNPC
local function state_start_move(boot)
	local data = get_boot_data(boot)
	local sprite = boot:GetSprite()

	local move_dir = data.last_move_direction
	local anim_to_play

	if move_dir == Direction.LEFT or move_dir == Direction.RIGHT then
		anim_to_play = "WalkStartHoriz"
	else
		anim_to_play = "WalkStartVertical"
	end

	sprite:Play(anim_to_play, false)

	if sprite:IsFinished() then
		data.state = BootState.MOVING
	end
end

---@param boot EntityNPC
local function state_moving(boot)
	local data = get_boot_data(boot)
	local sprite = boot:GetSprite()

	local move_dir = data.last_move_direction
	local anim_to_play

	if move_dir == Direction.LEFT or move_dir == Direction.RIGHT then
		anim_to_play = "WalkFloatHoriz"
	else
		anim_to_play = "WalkFloatVertical"
	end
	sprite:Play(anim_to_play, true)

	boot.Velocity = (data.target_pos - boot.Position):Resized(MOVE_SPEED)
end

---@param boot EntityNPC
local function state_stop_move(boot)
	local data = get_boot_data(boot)
	local sprite = boot:GetSprite()

	local move_dir = data.last_move_direction
	local anim_to_play

	if move_dir == Direction.LEFT or move_dir == Direction.RIGHT then
		anim_to_play = "WalkStopHoriz"
	else
		anim_to_play = "WalkStopVertical"
	end
	sprite:Play(anim_to_play, false)

	if sprite:IsFinished() then
		data.state = BootState.IDLE
	end
end

---@param boot EntityNPC
local function state_idle(boot)
	local data = get_boot_data(boot)
	local sprite = boot:GetSprite()

	if data.last_move_direction == Direction.LEFT or data.last_move_direction == Direction.RIGHT then
		sprite:Play("Idle", true)
	else
		sprite:Play("IdleVert", true)
	end

	boot.StateFrame = boot.StateFrame + 1
	boot.Velocity = Vector.Zero

	if
		boot.StateFrame >= MOVE_FREQUENCY
		and not boot:HasEntityFlags(EntityFlag.FLAG_FEAR | EntityFlag.FLAG_SHRINK | EntityFlag.FLAG_CONFUSION)
	then
		boot.StateFrame = 0
		local valid_moves = get_valid_moves(boot)

		if #valid_moves > 0 then
			local rng = RNG()
			rng:SetSeed(Random())
			local target_index = valid_moves[rng:RandomInt(#valid_moves) + 1]

			reserved_grid_indices[data.current_grid_index] = nil
			reserved_grid_indices[target_index] = true
			data.target_grid_index = target_index

			local room = Game():GetRoom()
			data.start_pos = room:GetGridPosition(data.current_grid_index)
			data.target_pos = room:GetGridPosition(data.target_grid_index)

			local move_vec = data.target_pos - data.start_pos
			data.last_move_direction = BucketOfBootsMod:vector_to_direction(move_vec)
			sprite.FlipX = data.last_move_direction == Direction.LEFT
			sprite.FlipY = data.last_move_direction == Direction.UP

			if data.last_move_direction == Direction.UP then
				sprite.Offset = BOOT_MOVING_UP_SPRITE_OFFSET
			else
				sprite.Offset = Vector.Zero
			end

			data.state = BootState.START_MOVE
		end
	end
end

---@param boot EntityNPC
function this:npc_init_boots(boot)
	if boot.Variant ~= BucketOfBootsMod.BootsEntityVariant then
		return
	end

	---@diagnostic disable-next-line: param-type-mismatch
	boot:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_KNOCKBACK)

	local room = Game():GetRoom()
	local grid_index = room:GetGridIndex(boot.Position)
	local clamped_position = room:GetGridPosition(grid_index)

	boot.Position = clamped_position
	local grid_entity = room:GetGridEntityFromPos(boot.Position)

	if grid_entity and grid_entity.CollisionClass ~= GridCollisionClass.COLLISION_NONE then
		if grid_entity:IsBreakableRock() then
			grid_entity:Destroy(true)
			grid_entity:UpdateCollision()
		else
			boot:Kill()
			return
		end
	end

	if reserved_grid_indices[grid_index] then
		boot:Kill()
		return
	end

	local data = get_boot_data(boot)
	reserved_grid_indices[data.current_grid_index] = true
end

---@param boot EntityNPC
function this:post_entity_remove_boots(boot)
	if boot.Variant ~= BucketOfBootsMod.BootsEntityVariant then
		return
	end

	local data = get_boot_data(boot)

	for grid_index in pairs(reserved_grid_indices) do
		if grid_index == data.target_grid_index or grid_index == data.current_grid_index then
			reserved_grid_indices[grid_index] = nil
		end
	end
end

---@param boot EntityNPC
function this:npc_update_boots(boot)
	if boot.Variant ~= BucketOfBootsMod.BootsEntityVariant then
		return
	end

	local data = get_boot_data(boot)
	local room = Game():GetRoom()
	local grid_index = room:GetGridIndex(boot.Position)
	room:SetGridPath(grid_index, 900)

	if data.state == BootState.IDLE then
		state_idle(boot)
	elseif data.state == BootState.START_MOVE then
		state_start_move(boot)
	elseif data.state == BootState.MOVING then
		state_moving(boot)
	elseif data.state == BootState.STOP_MOVE then
		state_stop_move(boot)
	end
end

---@param boot EntityNPC
function this:post_npc_render_boots(boot)
	if boot.Variant ~= BucketOfBootsMod.BootsEntityVariant then
		return
	end

	local data = get_boot_data(boot)

	if data.state ~= BootState.MOVING then
		return
	end

	local distance_to_target = boot.Position:Distance(data.target_pos)
	if distance_to_target <= PLAYER_DISTANCE_THRESHOLD then
		boot.Velocity = Vector.Zero
		boot.Position = data.target_pos
		data.current_grid_index = data.target_grid_index
		data.state = BootState.STOP_MOVE

		local sound_data = SOUNDS[boot.SubType] or {}
		local volume = sound_data.volume or 1
		local sound_effect = sound_data.sound or BucketOfBootsMod.SoundEffect.PAWN_STEP
		local pitch_min = sound_data.pitch_min or 1
		local pitch_max = sound_data.pitch_max or 1
		local pitch = BucketOfBootsMod:get_random_float(pitch_min, pitch_max)
		boot:PlaySound(sound_effect, volume, 0, false, pitch)
	end
end

---@param boot EntityNPC
function this:post_npc_death_boots(boot)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.IMPACT, 0, boot.Position, Vector.Zero, boot)
	SFXManager():Play(SoundEffect.SOUND_PESTILENCE_MAGGOT_POPOUT, 1, 0, false, 1.2)
	SFXManager():Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
end

function this:init()
	BucketOfBootsMod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, this.npc_init_boots, BucketOfBootsMod.BootsEntityType)
	BucketOfBootsMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, this.npc_update_boots, BucketOfBootsMod.BootsEntityType)

	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_NPC_RENDER,
		this.post_npc_render_boots,
		BucketOfBootsMod.BootsEntityType
	)
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_ENTITY_REMOVE,
		this.post_entity_remove_boots,
		BucketOfBootsMod.BootsEntityType
	)
	BucketOfBootsMod:AddCallback(
		ModCallbacks.MC_POST_NPC_DEATH,
		this.post_npc_death_boots,
		BucketOfBootsMod.BootsEntityType
	)
end

return this
