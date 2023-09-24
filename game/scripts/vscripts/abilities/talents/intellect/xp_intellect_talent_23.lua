LinkLuaModifier("modifier_xp_intellect_talent_23", "abilities/talents/intellect/xp_intellect_talent_23.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_23 = class(ItemBaseClass)
modifier_xp_intellect_talent_23 = class(xp_intellect_talent_23)
-------------
function xp_intellect_talent_23:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_23"
end
-------------
function modifier_xp_intellect_talent_23:OnCreated()
end

function modifier_xp_intellect_talent_23:OnDestroy()
end

function modifier_xp_intellect_talent_23:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS  
    }
end

function modifier_xp_intellect_talent_23:GetModifierBonusStats_Intellect()
    return 0.1 * self:GetParent():GetLevel() * self:GetStackCount()
end