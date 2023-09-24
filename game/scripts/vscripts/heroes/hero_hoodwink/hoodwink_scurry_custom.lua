LinkLuaModifier("modifier_hoodwink_scurry_custom", "heroes/hero_hoodwink/hoodwink_scurry_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_scurry_custom_shard", "heroes/hero_hoodwink/hoodwink_scurry_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_scurry_custom_disarm", "heroes/hero_hoodwink/hoodwink_scurry_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_scurry_custom_post_damage_buff", "heroes/hero_hoodwink/hoodwink_scurry_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

hoodwink_scurry_custom = class(ItemBaseClass)
modifier_hoodwink_scurry_custom = class(hoodwink_scurry_custom)
modifier_hoodwink_scurry_custom_shard = modifier_hoodwink_scurry_custom
modifier_hoodwink_scurry_custom_disarm = class(ItemBaseClassDebuff)
modifier_hoodwink_scurry_custom_post_damage_buff = class(ItemBaseClass)

function modifier_hoodwink_scurry_custom:IsStackable() return true end
function modifier_hoodwink_scurry_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
-------------
function hoodwink_scurry_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self:GetToggleState() then
        if not caster:HasModifier("modifier_item_aghanims_shard") then
            caster:AddNewModifier(caster, self, "modifier_hoodwink_scurry_custom", {})
        else
            caster:AddNewModifier(caster, self, "modifier_hoodwink_scurry_custom_shard", {})
        end

        caster:AddNewModifier(caster, self, "modifier_hoodwink_scurry_custom_disarm", {})
    else
        if not caster:HasModifier("modifier_item_aghanims_shard") then
            caster:RemoveModifierByName("modifier_hoodwink_scurry_custom")
        else
            caster:RemoveModifierByName("modifier_hoodwink_scurry_custom_shard")
        end

        caster:RemoveModifierByName("modifier_hoodwink_scurry_custom_disarm")
    end
end
----------------------------
function modifier_hoodwink_scurry_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_hoodwink_scurry_custom:OnTooltip()
    local total = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("dmg_increase_per_sec_pct")
    return total
end

function modifier_hoodwink_scurry_custom:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("evasion")
end

function modifier_hoodwink_scurry_custom:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("hp_regen_pct")
end

function modifier_hoodwink_scurry_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_speed_pct")
end

function modifier_hoodwink_scurry_custom:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.duration = 0

    EmitSoundOn("Hero_Hoodwink.Scurry.Cast", caster)

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_hoodwink/hoodwink_scurry_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControl( self.effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, caster:GetAbsOrigin() )

    self:StartIntervalThink(1)
end

function modifier_hoodwink_scurry_custom:OnIntervalThink()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        if self:GetStackCount() < (self:GetAbility():GetSpecialValueFor("max_dmg_increase")/self:GetAbility():GetSpecialValueFor("dmg_increase_per_sec_pct")) then
            self.duration = self.duration + 1
            self:IncrementStackCount()
        end
    else
        if self.duration < (self:GetAbility():GetSpecialValueFor("max_dmg_increase")/self:GetAbility():GetSpecialValueFor("dmg_increase_per_sec_pct")) then
            self.duration = self.duration + 1
        end
    end
end

function modifier_hoodwink_scurry_custom:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("Hero_Hoodwink.Scurry.End", caster)

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    if caster:HasModifier("modifier_item_aghanims_shard") then
        if caster:HasModifier("modifier_hoodwink_scurry_custom_post_damage_buff") then
            caster:RemoveModifierByName("modifier_hoodwink_scurry_custom_post_damage_buff")
        end
        
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_hoodwink_scurry_custom_post_damage_buff", {
            duration = self:GetAbility():GetSpecialValueFor("damage_buff_duration"),
            totalDuration = self.duration
        })
    end
end

function modifier_hoodwink_scurry_custom:GetEffectName()
    return "particles/units/heroes/hero_hoodwink/hoodwink_scurry_passive.vpcf"
end
---------------------------------------
function modifier_hoodwink_scurry_custom_disarm:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end

function modifier_hoodwink_scurry_custom_disarm:GetEffectName()
    return "particles/units/heroes/hero_demonartist/demonartist_engulf_disarm/items2_fx/heavens_halberd.vpcf"
end

function modifier_hoodwink_scurry_custom_disarm:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end
---------------------------------------
function modifier_hoodwink_scurry_custom_post_damage_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_hoodwink_scurry_custom_post_damage_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local caster = self:GetCaster()

    local duration = params.totalDuration
    local ability = self:GetAbility()
    local maxIncrease = ability:GetSpecialValueFor("max_dmg_increase")
    local scaling = ability:GetSpecialValueFor("dmg_increase_per_sec_pct")

    local total = 0
    total = scaling * duration

    if total > maxIncrease then
        total = maxIncrease
    end

    self.damage = total

    self:InvokeBonusDamage()
end

function modifier_hoodwink_scurry_custom_post_damage_buff:GetModifierDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_hoodwink_scurry_custom_post_damage_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_hoodwink_scurry_custom_post_damage_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_hoodwink_scurry_custom_post_damage_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end