LinkLuaModifier("modifier_xp_all_talent_3", "abilities/talents/all/xp_all_talent_3.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_all_talent_3 = class(ItemBaseClass)
modifier_xp_all_talent_3 = class(xp_all_talent_3)
-------------
function xp_all_talent_3:GetIntrinsicModifierName()
    return "modifier_xp_all_talent_3"
end
-------------
function modifier_xp_all_talent_3:OnCreated()
end

function modifier_xp_all_talent_3:OnDestroy()
end

function modifier_xp_all_talent_3:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXP_RATE_BOOST      
    }
end

function modifier_xp_all_talent_3:GetModifierPercentageExpRateBoost()
    return 1 * self:GetStackCount()
end