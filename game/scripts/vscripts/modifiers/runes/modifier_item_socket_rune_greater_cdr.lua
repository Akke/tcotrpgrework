LinkLuaModifier("modifier_item_socket_rune_greater_cdr", "modifiers/runes/modifier_item_socket_rune_greater_cdr.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_cdr = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_cdr:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE 
    }
end

function modifier_item_socket_rune_greater_cdr:GetModifierPercentageCooldown()
    return 3 * self:GetStackCount()
end