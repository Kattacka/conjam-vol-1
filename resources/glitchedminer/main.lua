GLITCHED_MINER = RegisterMod("Glitched Miner", 1)
local mod = GLITCHED_MINER
local sfx = SFXManager()
local game = Game()
mod.ItemId = Isaac.GetItemIdByName("Glitched Miner")

local forcedEvent = 0
local eventsAutocomplete = {
    {"0", "Disable override"},
}
local events = {}
local eventsPicker = WeightedOutcomePicker()

---@param outcome function
---@param weight integer?
---@param eventName string?
function mod.AddEvent(outcome, weight, eventName)
    weight = weight or 100
    local index = #events+1
    events[index] = outcome
    eventsPicker:AddOutcomeWeight(index, weight)
    if eventName then
        local description = string.format("%s (%d%% weight)", eventName, weight)
        table.insert(eventsAutocomplete, {tostring(index), description})
    end
end

---@param seed integer
---@return function
function mod.RollEvent(seed)
    if forcedEvent ~= 0 then
        return events[forcedEvent]
    end
    local index = eventsPicker:PickOutcome(RNG(seed))
    return events[index]
end

---@param rock GridEntityRock
---@param count integer?
function mod.TriggerRandomEvent(rock, count)
    count = count or 1
    local player = PlayerManager.FirstCollectibleOwner(mod.ItemId)
    local rng = RNG(rock:GetSaveState().SpawnSeed)
    game:MakeShockwave(rock.Position, 0.035, 0.025, 10)
    rng:Next() --The same seed is used earlier to determine glitched rocks. Idk I was worried about that skewing the results.
    for i = 1, count do
        local event = mod.RollEvent(rng:Next())
        event(rock.Position, rng, rock, player)
    end
    sfx:Play(SoundEffect.SOUND_EDEN_GLITCH, 4)
end

mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function (_, cmd, args)
    if cmd ~= "GlitchedMinerForceEffect" then
        return
    end
    local index = tonumber(args)
    if not (events[index] or index == 0) then
        return "Invalid event index!"
    end
    ---@cast index integer
    forcedEvent = index
    return "Forced event to appear"
end)

Console.RegisterCommand(
    "GlitchedMinerForceEffect",
    "Overrides Glitched Miner's effect choice",
    "Forces which ErrorOre effect from Glitched Miner to activate",
    true,
    AutocompleteType.CUSTOM
)

mod:AddCallback(ModCallbacks.MC_CONSOLE_AUTOCOMPLETE, function ()
    return eventsAutocomplete
end, "GlitchedMinerForceEffect")

include("resources.glitchedminer.glitched_miner_scripts.passive")
include("resources.glitchedminer.glitched_miner_scripts.events")
include("resources.glitchedminer.glitched_miner_scripts.conpat")