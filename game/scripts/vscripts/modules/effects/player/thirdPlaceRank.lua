LinkLuaModifier("modifier_effect_thirdplace_rank", "modules/effects/player/firstPlaceScoreboard", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_thirdplace_rank then modifier_effect_thirdplace_rank = class({}) end

THIRD_PLACE_RANK_PRIVATE_IDS = {
    "76561199528241706",
    "76561199387364484",
    "76561199251521550",
    "76561198841165931",
    "76561198057544064",
    "76561198138993689",
    "76561197981550829",
    "76561198039521995",
    "76561198159857988",
    "76561198045035756"
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

