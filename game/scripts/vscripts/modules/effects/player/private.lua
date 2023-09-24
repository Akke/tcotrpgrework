LinkLuaModifier("modifier_effect_private", "modules/effects/player/private", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_private then modifier_effect_private = class({}) end

PRIVATE_IDS = {
    --[[
    -- handsome
    "76561198059398095",
    -- donators
    "76561198016484191",
    "76561199239767257",
    "76561198846036305",
    "76561199100151253",
    "76561198867602440",
    "76561199030472417",
    "76561197997700307",
    "76561199249646807",
    "76561198862554806",
    "76561197960346102",
    --event prize
    "76561199031435869",
    "76561198118826479",
    "76561198281614362",
    "76561198154935267",
    "76561198073200021",
    "76561197960346102",
    "76561199266085673",
    "76561198255285470",
    "76561198285867886",
    "76561199111219644",
    "76561198150805492",
    "76561198154148965",
    "76561197991300331",
    "76561199265241258",
    "76561198126857616",
    "76561199104921523",
    "76561198139732374",
    "76561198081239401",
    "76561198053237749",
    "76561199346682044",
    "76561199481370713",
    "76561198057334441",
    "76561198810440126",
    "76561198194993369",
    --]]
}

function modifier_effect_private:IsHidden()
    return false
end

function modifier_effect_private:GetPriority()
    return 10001
end

function modifier_effect_private:GetEffectName()
    local parent = self:GetParent()
    if parent:HasModifier("modifier_effect_event_first") or parent:HasModifier("modifier_effect_scoreboard_first") or parent:HasModifier("modifier_effect_thirdplace_rank") then return end
    
    return "particles/econ/events/ti10/emblem/ti10_emblem_effect.vpcf"
end

function modifier_effect_private:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_private:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_private:GetTexture()
      return "item_ultimate_scepter"
end

function modifier_effect_private:AllowIllusionDuplicate() return true end