slark_essence_shift_custom = class({})

function slark_essence_shift_custom:GetIntrinsicModifierName()
    return "modifier_slark_essence_shift_custom"
end

modifier_slark_essence_shift_custom = class({
    IsHidden = function(self) return self:GetStackCount() > 1 end
})

function modifier_slark_essence_shift_custom:OnCreated(keys)
    local parent = self:GetParent()
    parent:AddNewModifier(parent, self:GetAbility(), "modifier_slark_essence_shift_custom_creeps", {})
end

function modifier_slark_essence_shift_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS_PERCENTAGE
    }
end

function modifier_slark_essence_shift_custom:OnDeath(event)
    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if event.unit == parent then return end

    local modifier = parent:FindModifierByName("modifier_slark_essence_shift_custom_creeps")
    if modifier == nil then
        modifier = parent:AddNewModifier(parent, self:GetAbility(), "modifier_slark_essence_shift_custom_creeps", {})
    end

    if IsBossTCOTRPG(event.unit) then
       self:IncrementStackCount()
    else if IsCreepTCOTRPG(event.unit) then
        modifier:IncrementStackCount()

        if modifier:GetStackCount() >= self:GetAbility():GetSpecialValueFor("creep_to_agi") then
            modifier:SetStackCount(0)

            self:IncrementStackCount()
        end
    end

    self:PlayEffects(event.unit)
end

function modifier_slark_essence_shift_custom:GetModifierBonusStats_Agility()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("agi_gain")
end

function modifier_slark_essence_shift_custom:GetModifierBonusStats_Agility_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_base_agi_pct")
end

function modifier_slark_essence_shift_custom:PlayEffects(target)
	local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_essence_shift.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(effect_cast, 1, self:GetParent():GetOrigin() + Vector(0, 0, 64))
	ParticleManager:ReleaseParticleIndex(effect_cast)
end

modifier_slark_essence_shift_custom_creeps = class({
    IsHidden = function(self) return self:GetStackCount() > 1 end,
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    GetAttributes = function(self) return MODIFIER_ATTRIBUTE_PERMANENT end
})