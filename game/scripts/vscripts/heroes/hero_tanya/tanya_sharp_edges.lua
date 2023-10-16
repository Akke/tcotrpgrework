LinkLuaModifier("modifier_tanya_sharp_edges", "heroes/hero_tanya/tanya_sharp_edges.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tanya_sharp_edges_debuff", "heroes/hero_tanya/tanya_sharp_edges.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

tanya_sharp_edges = class(ItemBaseClass)
modifier_tanya_sharp_edges = class(tanya_sharp_edges)
modifier_tanya_sharp_edges_debuff = class(ItemBaseClassDebuff)
-------------
function tanya_sharp_edges:GetIntrinsicModifierName()
    return "modifier_tanya_sharp_edges"
end
------------
function modifier_tanya_sharp_edges:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
    }
end

function modifier_tanya_sharp_edges:OnCreated()
    if not IsServer() then return end 

    self.bat = self:GetParent():GetBaseAttackTime() - self:GetAbility():GetSpecialValueFor("bat_decrease")
end

function modifier_tanya_sharp_edges:GetModifierBaseAttackTimeConstant()
    return self.bat
end

function modifier_tanya_sharp_edges:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    local target = event.target 

    local debuff = target:FindModifierByName("modifier_tanya_sharp_edges_debuff")

    if not debuff then
        debuff = target:AddNewModifier(parent, ability, "modifier_tanya_sharp_edges_debuff", { duration = ability:GetSpecialValueFor("duration") })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
-----------------
function modifier_tanya_sharp_edges_debuff:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")

    self.bleedDmg = ability:GetSpecialValueFor("bleed_from_attack")

    self.damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        ability = ability,
        damage_type = DAMAGE_TYPE_PHYSICAL,
    }

    self:StartIntervalThink(interval)
end

function modifier_tanya_sharp_edges_debuff:OnIntervalThink()
    self.damageTable.damage = (self.damage * (self.bleedDmg/100)) * self:GetStackCount()
    ApplyDamage(self.damageTable)
end