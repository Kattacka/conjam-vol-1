B95Mix1 = RegisterMod("B95Mix1", 1)

---@type Direction[]
B95Mix1.DICT_ANGLE_TO_DIRECTION = {
    Direction.RIGHT,
    Direction.DOWN,
    Direction.LEFT,
    Direction.UP,
}

---@type table<Direction, Vector>
B95Mix1.DICT_DIRECTION_TO_VECTOR = {
    [Direction.DOWN] = Vector(0, 1),
    [Direction.LEFT] = Vector(-1, 0),
    [Direction.UP] = Vector(0, -1),
    [Direction.RIGHT] = Vector(1, 0),
    [Direction.NO_DIRECTION] = Vector(0, 0),
}

---@type table<Direction, integer>
B95Mix1.DICT_DIRECTION_TO_ANGLE = {
    [Direction.LEFT] = 180,
    [Direction.UP] = -90,
    [Direction.RIGHT] = 0,
    [Direction.DOWN] = 90,
    [Direction.NO_DIRECTION] = 0,
}

---@generic T
---@param tbl T[]
---@param filter? fun(value: T, key: any): boolean?
---@return T[]
function B95Mix1:Filter(tbl, filter)
    local _tbl = {}

    for k, v in pairs(tbl) do
        if not filter or filter(v, k) then
            _tbl[#_tbl + 1] = v
        end
    end

    return _tbl
end

---@param angle number
function B95Mix1:AngleToDirection(angle)
    return B95Mix1.DICT_ANGLE_TO_DIRECTION[math.floor((angle % 360 + 45) / 90) % 4 + 1]
end

---@param vector Vector
---@return Direction
function B95Mix1:VectorToDirection(vector)
    if vector:Length() < 0.001 then
        return Direction.NO_DIRECTION
    end

    return B95Mix1:AngleToDirection(vector:GetAngleDegrees())
end

local FONT = Font()
FONT:Load("font/teammeatfont16.fnt")
local display

B95Mix1:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
    if Input.IsButtonTriggered(Keyboard.KEY_1, -1) then
        display = not display
    end
    if not display then return end
    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do
        local data = XMLData.GetEntryById(XMLNode.ITEM, v.SubType)
        if data and data.b95mix1credit then
            local pos = Isaac.WorldToScreen(v.Position)
            FONT:DrawStringScaled(data.b95mix1credit, pos.X, pos.Y + 10, 0.5, 0.5, KColor(1, 1, 1, 1), 1, true)
        end
    end
end)