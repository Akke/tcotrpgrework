LinkLuaModifier("modifier_dummy_target", "modifiers/modifier_dummy_target.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

dummy_target = class(ItemBaseClass)
modifier_dummy_target = class(dummy_target)
-----------------
function dummy_target:GetIntrinsicModifierName()
    return "modifier_dummy_target"
end
-----------------
function modifier_dummy_target:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_PROPERTY_MIN_HEALTH 
    }

    return funcs
end

function modifier_dummy_target:GetMinHealth()
    return self:GetParent():GetMaxHealth()
end

function modifier_dummy_target:GetModifierProvidesFOWVision()
    return 1
end

function modifier_dummy_target:OnCreated()
    if not IsServer() then return end

    local unit = self:GetParent()

    unit:SetForwardVector(-unit:GetForwardVector())

    self:StartIntervalThink(0.5)
end

function modifier_dummy_target:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true
    }
    return state
end

function modifier_dummy_target:GetModifierIncomingDamage_Percentage(event)
    if self:GetParent() ~= event.target then return end
    
    if not event.attacker:IsRealHero() then return -100 end
end
