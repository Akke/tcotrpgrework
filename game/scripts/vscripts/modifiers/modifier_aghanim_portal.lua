modifier_aghanim_portal = class({})

function modifier_aghanim_portal:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    local model = "models/props_gameplay/team_portal/team_portal.vmdl"

    parent:SetOriginalModel(model)
    parent:SetModel(model)

    local currentAngles = parent:GetAngles()
    local newAngles = QAngle(currentAngles.x, currentAngles.y, currentAngles.z)

    -- Set the new rotation angle for the entity
    parent:SetAngles(newAngles.x, newAngles.y, newAngles.z)

    local particle = "particles/base_static/team_portal_active.vpcf"

    self.vfxAwaiting = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.vfxAwaiting, 0, parent:GetAbsOrigin())
    
    self:StartIntervalThink(FrameTime())
end

function modifier_aghanim_portal:OnIntervalThink()
    local parent = self:GetParent()

    if _G.AghanimCrystalCount >= _G.AghanimCrystalCountMax then
        if self.vfxAwaiting ~= nil then
            ParticleManager:DestroyParticle(self.vfxAwaiting, false)
            ParticleManager:ReleaseParticleIndex(self.vfxAwaiting)
        end

        local particle = "particles/base_static/team_portal_ambient.vpcf"

        self.vfx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.vfx, 1, parent:GetAbsOrigin())
        ParticleManager:SetParticleControl(self.vfx, 2, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(self.vfx)
        self:StartIntervalThink(-1)
    end
end

function modifier_aghanim_portal:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE 
    }
end

function modifier_aghanim_portal:GetModifierModelChange()
    return "models/props_gameplay/team_portal/team_portal.vmdl"
end

function modifier_aghanim_portal:CheckState()
    return {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false,
    }
end
