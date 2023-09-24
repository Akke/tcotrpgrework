LinkLuaModifier("modifier_item_socket_rune_lesser_strength", "modifiers/runes/modifier_item_socket_rune_lesser_strength.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_lesser_strength = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_lesser_strength:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_item_socket_rune_lesser_strength:GetModifierBonusStats_Strength()
    return 3 * self:GetStackCount()
end