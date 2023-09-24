LinkLuaModifier("modifier_silencer_global_silence_custom", "heroes/hero_silencer/silencer_global_silence_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_global_silence_custom_buff", "heroes/hero_silencer/silencer_global_silence_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_global_silence_custom_debuff", "heroes/hero_silencer/silencer_global_silence_custom.lua", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

silencer_global_silence_custom = class(ItemBaseClass)
modifier_silencer_global_silence_custom = class(silencer_global_silence_custom)
modifier_silencer_global_silence_custom_buff = class(ItemBaseClassBuff)
modifier_silencer_global_silence_custom_debuff = class(ItemBaseClassDebuff)
-------------
function silencer_global_silence_custom:GetIntrinsicModifierName()
    return "modifier_silencer_global_silence_custom"
end

function silencer_global_silence_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_silencer/silencer_global_silence.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, caster:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Silencer.GlobalSilence.Cast", caster)

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        victim:AddNewModifier(caster, self, "modifier_silencer_global_silence_custom_debuff", {
            duration = self:GetSpecialValueFor("duration")
        })
    end

    caster:AddNewModifier(caster, self, "modifier_silencer_global_silence_custom_buff", {
        duration = self:GetSpecialValueFor("duration")
    })
end
-----------
function modifier_silencer_global_silence_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_silencer_global_silence_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.target:IsSilenced() and self:GetParent():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    end
end
-----------
function modifier_silencer_global_silence_custom_debuff:GetEffectName()
    return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_silencer_global_silence_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_silencer_global_silence_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end
---------
function modifier_silencer_global_silence_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
    }
end

function modifier_silencer_global_silence_custom_buff:GetModifierBonusStats_Intellect()
    return self.fTotal
end

function modifier_silencer_global_silence_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.total = parent:GetIntellect() * (ability:GetSpecialValueFor("int_mult")/100)

    self:InvokeBonus()

    EmitSoundOn("Hero_Silencer.GlobalSilence.Effect", parent)
end

function modifier_silencer_global_silence_custom_buff:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_silencer_global_silence_custom_buff:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_silencer_global_silence_custom_buff:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end