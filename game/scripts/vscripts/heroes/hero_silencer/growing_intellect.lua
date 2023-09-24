LinkLuaModifier("modifier_silencer_growing_intellect_custom", "heroes/hero_silencer/growing_intellect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_growing_intellect_custom_buff_permanent", "heroes/hero_silencer/growing_intellect.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}
local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}


silencer_growing_intellect_custom = class(ItemBaseClass)
modifier_silencer_growing_intellect_custom = class(silencer_growing_intellect_custom)
modifier_silencer_growing_intellect_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_silencer_growing_intellect_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_silencer_growing_intellect_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_TOOLTIP 
    }

    return funcs
end

function modifier_silencer_growing_intellect_custom_buff_permanent:OnCreated()
    self.total = 0
end

function modifier_silencer_growing_intellect_custom_buff_permanent:OnTooltip()
    return self.total
end

function modifier_silencer_growing_intellect_custom_buff_permanent:OnRefresh()
    local gain = self:GetAbility():GetSpecialValueFor("int_gain")

    self.total = self.total + gain
    
    if not IsServer() then return end

    self:GetParent():ModifyIntellect(gain)
end
-------------
function silencer_growing_intellect_custom:GetIntrinsicModifierName()
    return "modifier_silencer_growing_intellect_custom"
end


function modifier_silencer_growing_intellect_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_silencer_growing_intellect_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_silencer_growing_intellect_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()

    local buff = unit:FindModifierByNameAndCaster("modifier_silencer_growing_intellect_custom_buff_permanent", unit)
    local stacks = unit:GetModifierStackCount("modifier_silencer_growing_intellect_custom_buff_permanent", unit)
    
    if not buff then
        buff = unit:AddNewModifier(unit, ability, "modifier_silencer_growing_intellect_custom_buff_permanent", {})
    end

    unit:SetModifierStackCount("modifier_silencer_growing_intellect_custom_buff_permanent", unit, (stacks + 1))
    buff:ForceRefresh()
end