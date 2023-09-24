LinkLuaModifier("modifier_troll_warlord_battle_trance_custom", "heroes/hero_troll_warlord/troll_warlord_battle_trance_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_warlord_battle_trance_custom_buff", "heroes/hero_troll_warlord/troll_warlord_battle_trance_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

troll_warlord_battle_trance_custom = class(ItemBaseClass)
modifier_troll_warlord_battle_trance_custom = class(troll_warlord_battle_trance_custom)
modifier_troll_warlord_battle_trance_custom_buff = class(ItemBaseClassBuff)
-------------
function troll_warlord_battle_trance_custom:GetIntrinsicModifierName()
    return "modifier_troll_warlord_battle_trance_custom"
end

function modifier_troll_warlord_battle_trance_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
    return funcs
end

function modifier_troll_warlord_battle_trance_custom:OnCreated()
    if not IsServer() then return end
end

function modifier_troll_warlord_battle_trance_custom:OnTakeDamage(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if victim ~= parent then
        return
    end

    local ability = self:GetAbility()

    if caster:HasModifier("modifier_troll_warlord_battle_trance_custom_buff") or not ability:IsCooldownReady() then return end

    local threshold = ability:GetSpecialValueFor("health_threshold")

    if parent:GetMaxHealth() <= threshold or (((parent:GetHealth() - event.damage)/parent:GetMaxHealth())*100) <= threshold then
        caster:AddNewModifier(caster, ability, "modifier_troll_warlord_battle_trance_custom_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })

        ability:UseResources(true, false, false, true)
    end
end
---
function modifier_troll_warlord_battle_trance_custom_buff:GetStatusEffectName()
    return "particles/status_fx/status_effect_troll_warlord_battletrance.vpcf"
end

function modifier_troll_warlord_battle_trance_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE  
    }
    return funcs
end

function modifier_troll_warlord_battle_trance_custom_buff:GetModifierPreAttack_BonusDamage()
    if self:GetParent():HasScepter() then
        return self.fDamage
    end
end

function modifier_troll_warlord_battle_trance_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.effect_cast = nil

    local caster = self:GetCaster()

    self.damage = caster:GetAverageTrueAttackDamage(caster) * (self:GetAbility():GetSpecialValueFor("outgoing_damage")/100)

    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
    local sound_cast = "Hero_TrollWarlord.BattleTrance.Cast"
    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, caster:GetOrigin() )

    -- Create Sound
    EmitSoundOn( sound_cast, caster )

    self:InvokeBonusDamage()
end

function modifier_troll_warlord_battle_trance_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_troll_warlord_battle_trance_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_troll_warlord_battle_trance_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_troll_warlord_battle_trance_custom_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_troll_warlord_battle_trance_custom_buff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local heal = caster:GetMaxHealth() * (ability:GetSpecialValueFor("max_hp_heal")/100)

    caster:Heal(heal, ability)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, heal, nil)
end

function modifier_troll_warlord_battle_trance_custom_buff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_troll_warlord_battle_trance_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("speed_bonus")
end