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
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS , --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_MODEL_SCALE, --GetModifierModelScale
    }

    return funcs
end

function modifier_pudge_flesh_heap_custom_buff_permanent:GetModifierModelScale()
    return math.min(self:GetStackCount() * 0.2, 200)
end

function modifier_pudge_flesh_heap_custom_buff_permanent:GetModifierBonusStats_Strength()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("str_gain")
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

function modifier_pudge_flesh_heap_custom:OnDeath(event)
    local attacker = event.attacker
    local parent = self:GetParent()
    local victim = event.unit

    if attacker ~= parent then
        return
    end

    local ability = self:GetAbility()

    local buff = parent:FindModifierByNameAndCaster("modifier_pudge_flesh_heap_custom_buff_permanent", parent)
    
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_pudge_flesh_heap_custom_buff_permanent", {})
    end

    if buff ~= nil then
        local preTotal = (buff:GetStackCount() * ability:GetSpecialValueFor("str_gain"))
        if preTotal >= 1000000 then return end

        buff:IncrementStackCount()
    end
end