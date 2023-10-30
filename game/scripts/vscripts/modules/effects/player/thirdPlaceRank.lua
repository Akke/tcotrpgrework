LinkLuaModifier("modifier_effect_thirdplace_rank", "modules/effects/player/firstPlaceScoreboard", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_thirdplace_rank then modifier_effect_thirdplace_rank = class({}) end

THIRD_PLACE_RANK_PRIVATE_IDS = {
    "76561198415231883",
    "76561198007338005",
    "76561198815618025",
    "76561199154514273",
    "76561199082379294",
    "76561197999938469",
    "76561198071317896",
    "76561198079733573",
    "76561198090081362",
}

function modifier_effect_thirdplace_rank:IsHidden()
    return false
end

function modifier_effect_thirdplace_rank:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_thirdplace_rank:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_thirdplace_rank:GetTexture()
      return "medal1"
end

function modifier_effect_thirdplace_rank:AllowIllusionDuplicate() return true end

function modifier_effect_thirdplace_rank:GetPriority()
    return 99998
end

function modifier_effect_thirdplace_rank:OnCreated()
    if not IsServer() then return end 

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

