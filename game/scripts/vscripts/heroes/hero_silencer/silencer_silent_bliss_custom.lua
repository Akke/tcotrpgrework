LinkLuaModifier("modifier_silencer_silent_bliss_custom", "heroes/hero_silencer/silencer_silent_bliss_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

silencer_silent_bliss_custom = class(ItemBaseClass)
modifier_silencer_silent_bliss_custom = class(silencer_silent_bliss_custom)
-------------
function silencer_silent_bliss_custom:GetIntrinsicModifierName()
    return "modifier_silencer_silent_bliss_custom"
end

function modifier_silencer_silent_bliss_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
    }
    return funcs
end

function modifier_silencer_silent_bliss_custom:GetModifierBonusStats_Intellect()
    return self.fIntellect
end

function modifier_silencer_silent_bliss_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_silencer_silent_bliss_custom:OnIntervalThink()
    self:OnRefresh()
end

function modifier_silencer_silent_bliss_custom:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.intellect = parent:GetBaseIntellect() * (ability:GetSpecialValueFor("bonus_intellect_gain_pct")/100)

    self:InvokeBonus()
end

function modifier_silencer_silent_bliss_custom:AddCustomTransmitterData()
    return
    {
        intellect = self.fIntellect,
    }
end

function modifier_silencer_silent_bliss_custom:HandleCustomTransmitterData(data)
    if data.intellect ~= nil then
        self.fIntellect = tonumber(data.intellect)
    end
end

function modifier_silencer_silent_bliss_custom:InvokeBonus()
    if IsServer() == true then
        self.fIntellect = self.intellect

        self:SendBuffRefreshToClients()
    end
end

function modifier_silencer_silent_bliss_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.unit 

    if event.attacker ~= parent or victim == parent then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end
    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local mana = event.damage * (ability:GetSpecialValueFor("mana_restore_pct")/100)

    parent:GiveMana(mana)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, mana, nil)

    ability:UseResources(false, false, false, true)
end