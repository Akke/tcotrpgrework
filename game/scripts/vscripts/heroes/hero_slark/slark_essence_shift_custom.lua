LinkLuaModifier("modifier_slark_essence_shift_custom", "heroes/hero_slark/slark_essence_shift_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_essence_shift_custom_debuff", "heroes/hero_slark/slark_essence_shift_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_essence_shift_custom_buff", "heroes/hero_slark/slark_essence_shift_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_essence_shift_custom_buff_permanent", "heroes/hero_slark/slark_essence_shift_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}


slark_essence_shift_custom = class(ItemBaseClass)
modifier_slark_essence_shift_custom = class(slark_essence_shift_custom)
modifier_slark_essence_shift_custom_debuff = class(ItemBaseClassDebuff)
modifier_slark_essence_shift_custom_buff = class(ItemBaseClassBuff)
modifier_slark_essence_shift_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_slark_essence_shift_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_slark_essence_shift_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
    }

    return funcs
end

function modifier_slark_essence_shift_custom_debuff:GetModifierBonusStats_Agility()
    return -self:GetAbility():GetSpecialValueFor("stat_loss") * self:GetStackCount()
end

function modifier_slark_essence_shift_custom_debuff:GetModifierBonusStats_Strength()
    return -self:GetAbility():GetSpecialValueFor("stat_loss") * self:GetStackCount()
end

function modifier_slark_essence_shift_custom_debuff:GetModifierBonusStats_Intellect()
    return -self:GetAbility():GetSpecialValueFor("stat_loss") * self:GetStackCount()
end
-------------
function modifier_slark_essence_shift_custom_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_slark_essence_shift_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
    }

    return funcs
end

function modifier_slark_essence_shift_custom_buff:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("agi_gain") * self:GetStackCount()
end
-------------
function modifier_slark_essence_shift_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_slark_essence_shift_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_TOOLTIP
    }

    return funcs
end

function modifier_slark_essence_shift_custom_buff_permanent:OnCreated()
    self.total = 0
end

function modifier_slark_essence_shift_custom_buff_permanent:OnTooltip()
    return self.total
end

function modifier_slark_essence_shift_custom_buff_permanent:OnRefresh()
    local gain = self:GetAbility():GetSpecialValueFor("agi_gain")

    self.total = self.total + gain
    
    if not IsServer() then return end

    self:GetParent():ModifyAgility(gain)
end
-------------
function slark_essence_shift_custom:GetIntrinsicModifierName()
    return "modifier_slark_essence_shift_custom"
end


function modifier_slark_essence_shift_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_slark_essence_shift_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_slark_essence_shift_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() or (not victim:IsRealHero() and not IsCreepTCOTRPG(victim)) or victim:IsIllusion() then
        return
    end

    local ability = self:GetAbility()
    local agiGain = ability:GetLevelSpecialValueFor("agi_gain", (ability:GetLevel() - 1))
    local statLoss = ability:GetLevelSpecialValueFor("stat_loss", (ability:GetLevel() - 1))
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    if victim:IsRealHero() then
        local debuff = victim:FindModifierByNameAndCaster("modifier_slark_essence_shift_custom_debuff", unit)
        local stacks = victim:GetModifierStackCount("modifier_slark_essence_shift_custom_debuff", unit)
        
        if not debuff then
            victim:AddNewModifier(unit, ability, "modifier_slark_essence_shift_custom_debuff", { duration = duration })
        else
            debuff:ForceRefresh()
        end

        victim:SetModifierStackCount("modifier_slark_essence_shift_custom_debuff", unit, (stacks + 1))

        -- Now add agility to Slark --

        local buffSlark = unit:FindModifierByNameAndCaster("modifier_slark_essence_shift_custom_buff", unit)
        local stacksSlark = unit:GetModifierStackCount("modifier_slark_essence_shift_custom_buff", unit)
        
        if not buffSlark then
            unit:AddNewModifier(unit, ability, "modifier_slark_essence_shift_custom_buff", { duration = duration })
        else
            buffSlark:ForceRefresh()
        end

        unit:SetModifierStackCount("modifier_slark_essence_shift_custom_buff", unit, (stacksSlark + 1))

        self:PlayEffects(victim)
    end
end

function modifier_slark_essence_shift_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()

    local buffSlark = unit:FindModifierByNameAndCaster("modifier_slark_essence_shift_custom_buff_permanent", unit)
    local stacksSlark = unit:GetModifierStackCount("modifier_slark_essence_shift_custom_buff_permanent", unit)
    
    if not buffSlark then
        buffSlark = unit:AddNewModifier(unit, ability, "modifier_slark_essence_shift_custom_buff_permanent", {})
    end

    unit:SetModifierStackCount("modifier_slark_essence_shift_custom_buff_permanent", unit, (stacksSlark + 1))
    buffSlark:ForceRefresh()
end

function modifier_slark_essence_shift_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_slark/slark_essence_shift.vpcf"
    local sound_cast = "Hero_Slark.EssenceShift"

    -- Get Data
    local forward = (target:GetOrigin()-self.parent:GetOrigin()):Normalized()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, forward )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end