LinkLuaModifier("modifier_pudge_flesh_heap_custom", "heroes/hero_pudge/heap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_flesh_heap_custom_buff_permanent", "heroes/hero_pudge/heap.lua", LUA_MODIFIER_MOTION_NONE)

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


pudge_flesh_heap_custom = class(ItemBaseClass)
modifier_pudge_flesh_heap_custom = class(pudge_flesh_heap_custom)
modifier_pudge_flesh_heap_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_pudge_flesh_heap_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_pudge_flesh_heap_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_STATS_STRENGTH_BONUS , --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_MODEL_SCALE, --GetModifierModelScale
    }

    return funcs
end

function modifier_pudge_flesh_heap_custom_buff_permanent:OnCreated()
    self.total = 0
end

function modifier_pudge_flesh_heap_custom_buff_permanent:OnTooltip()
    return self.total
end

function modifier_pudge_flesh_heap_custom_buff_permanent:GetModifierModelScale()
    local stack = self:GetStackCount() * 0.2
    if stack > 200 then
        stack = 200
    end

    return stack
end

function modifier_pudge_flesh_heap_custom_buff_permanent:OnRefresh()
    local gain = self:GetAbility():GetSpecialValueFor("str_gain")

    self.total = self.total + gain
    
    if not IsServer() then return end

    self:GetParent():ModifyStrength(gain)
end
-------------
function pudge_flesh_heap_custom:GetIntrinsicModifierName()
    return "modifier_pudge_flesh_heap_custom"
end


function modifier_pudge_flesh_heap_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
    }
    return funcs
end

function modifier_pudge_flesh_heap_custom:GetModifierPhysical_ConstantBlock(event)
    local block = event.damage * (self:GetAbility():GetSpecialValueFor("damage_block")/100)

    return block
end

function modifier_pudge_flesh_heap_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_pudge_flesh_heap_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()

    local buff = unit:FindModifierByNameAndCaster("modifier_pudge_flesh_heap_custom_buff_permanent", unit)
    local stacks = unit:GetModifierStackCount("modifier_pudge_flesh_heap_custom_buff_permanent", unit)
    
    if not buff then
        buff = unit:AddNewModifier(unit, ability, "modifier_pudge_flesh_heap_custom_buff_permanent", {})
    end

    if buff ~= nil then
        local preTotal = (buff:GetStackCount() * ability:GetSpecialValueFor("str_gain"))
        if preTotal >= 1000000 then return false end

        unit:SetModifierStackCount("modifier_pudge_flesh_heap_custom_buff_permanent", unit, (stacks + 1))
        buff:ForceRefresh()
    end
end