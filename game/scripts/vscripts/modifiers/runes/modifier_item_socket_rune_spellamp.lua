LinkLuaModifier("modifier_item_socket_rune_spellamp", "modifiers/runes/modifier_item_socket_rune_spellamp.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_spellamp = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_spellamp:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE  
    }
end

function modifier_item_socket_rune_spellamp:GetModifierSpellAmplify_Percentage()
    return 5.0 * self:GetStackCount()
end