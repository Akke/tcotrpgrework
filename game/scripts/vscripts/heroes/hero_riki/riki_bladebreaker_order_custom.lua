LinkLuaModifier("modifier_riki_bladebreaker_order_custom", "heroes/hero_riki/riki_bladebreaker_order_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_bladebreaker_order_custom_buff", "heroes/hero_riki/riki_bladebreaker_order_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

riki_bladebreaker_order_custom = class(BaseClass)
modifier_riki_bladebreaker_order_custom = class(riki_bladebreaker_order_custom)
modifier_riki_bladebreaker_order_custom_buff = class(BaseClassBuff)
-------------------------------
function riki_bladebreaker_order_custom:GetIntrinsicModifierName()
    return "modifier_riki_bladebreaker_order_custom"
end
-------------------------------
function modifier_riki_bladebreaker_order_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EXP_RATE_BOOST,
        MODIFIER_EVENT_ON_DEATH 
    }
end

function modifier_riki_bladebreaker_order_custom:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_riki_bladebreaker_order_custom_buff")
end

function modifier_riki_bladebreaker_order_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_pct")
end

function modifier_riki_bladebreaker_order_custom:GetModifierPercentageExpRateBoost()
    return self:GetAbility():GetSpecialValueFor("xp_mult_pct")
end

function modifier_riki_bladebreaker_order_custom:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    local buff = parent:FindModifierByName("modifier_riki_bladebreaker_order_custom_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_riki_bladebreaker_order_custom_buff", {})
    end

    if buff then
        buff:IncrementStackCount()
        buff:ForceRefresh()
    end
end
-----------------------------
function modifier_riki_bladebreaker_order_custom_buff:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("duration")
    
    self:StartIntervalThink(duration)
end

function modifier_riki_bladebreaker_order_custom_buff:OnIntervalThink()
    if self:GetStackCount() > 0 then
        self:DecrementStackCount()
    end

    if self:GetStackCount() <= 0 then
        self:Destroy()
    end
end

function modifier_riki_bladebreaker_order_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_riki_bladebreaker_order_custom_buff:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("agi_per_kill") * self:GetStackCount()
end