LinkLuaModifier("hero_akasha_sonic_wave_modifier", "heroes/hero_akasha/sonic_wave.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_sonic_wave_thinker", "heroes/hero_akasha/sonic_wave.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_sonic_wave_thinker_animation", "heroes/hero_akasha/sonic_wave.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_sonic_wave_debuff", "heroes/hero_akasha/sonic_wave.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_sonic_wave_thinker_scepter", "heroes/hero_akasha/sonic_wave.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_sonic_wave_thinker_scepter_cd", "heroes/hero_akasha/sonic_wave.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

local BaseClassScepter = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end
}

hero_akasha_sonic_wave = class(BaseClass)
hero_akasha_sonic_wave_thinker_scepter_cd = class(BaseClass)
hero_akasha_sonic_wave_modifier = class(BaseClass)
hero_akasha_sonic_wave_thinker = class(BaseClass)
hero_akasha_sonic_wave_thinker_scepter = class(BaseClassScepter)
hero_akasha_sonic_wave_thinker_animation = class(BaseClass)
hero_akasha_sonic_wave_debuff = class(BaseClassDebuff)

function hero_akasha_sonic_wave:GetIntrinsicModifierName()
    return "hero_akasha_sonic_wave_modifier"
end

function hero_akasha_sonic_wave:GetAbilityDamageType()
    if self:GetCaster():HasScepter() then return DAMAGE_TYPE_PURE end 

    return DAMAGE_TYPE_MAGICAL 
end

--[[
function hero_akasha_sonic_wave:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "hero_akasha_sonic_wave_thinker", {})
end

function hero_akasha_sonic_wave:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("hero_akasha_sonic_wave_thinker")

    caster:FadeGesture(ACT_DOTA_CAST_ABILITY_4)
end
--]]
function hero_akasha_sonic_wave:OnProjectileHit(hTarget, vLocation)
    if not IsServer() then return end
    if hTarget == nil then return end

    local caster = self:GetCaster()
    local damage = self:GetLevelSpecialValueFor("damage", (self:GetLevel() - 1))+(caster:GetMaxMana()*(self:GetSpecialValueFor("mana_to_damage")/100))
    local interval = self:GetLevelSpecialValueFor("summon_interval", (self:GetLevel() - 1))
    local knockbackDistance = self:GetLevelSpecialValueFor("knockback_distance", (self:GetLevel() - 1))
    local position = caster:GetAbsOrigin()
    local len = (hTarget:GetAbsOrigin() - position):Length2D()
    len = math.abs(knockbackDistance - knockbackDistance * ( len / 900 ))

    local knockbackModifierTable =
    {
        should_stun = 0,
        knockback_duration = 1,
        duration = 1,
        knockback_distance = len,
        knockback_height = 0,
        center_x = position.x,
        center_y = position.y,
        center_z = position.z
    }

    hTarget:AddNewModifier(hTarget, nil, "modifier_knockback", knockbackModifierTable)
    hTarget:AddNewModifier(hTarget, self, "hero_akasha_sonic_wave_debuff", { duration = interval })

    local damageTable = {
        victim = hTarget,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self
    }

    if caster:HasScepter() then
        hTarget:AddNewModifier(caster, nil, "modifier_silence", {
            duration = self:GetSpecialValueFor("silence_duration")
        })
    end

    ApplyDamage(damageTable)
end
----------
function hero_akasha_sonic_wave_thinker:OnCreated()
    if not IsServer() then return end

    self.projectile = "particles/econ/items/queen_of_pain/qop_arcana/qop_arcana_sonic_wave.vpcf"
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self.distance = self.ability:GetLevelSpecialValueFor("distance", (self.ability:GetLevel() - 1))
    self.startingAoe = self.ability:GetLevelSpecialValueFor("starting_aoe", (self.ability:GetLevel() - 1))
    self.finalAoe = self.ability:GetLevelSpecialValueFor("final_aoe", (self.ability:GetLevel() - 1))
    self.velocity = self.ability:GetLevelSpecialValueFor("speed", (self.ability:GetLevel() - 1))
    self.interval = self.ability:GetLevelSpecialValueFor("summon_interval", (self.ability:GetLevel() - 1))

    self.order = RandomInt(0, 1)

    -- Cast it once at the start
    hero_akasha_sonic_wave_thinker:CastSonicWaves(self.caster, self.ability, self.projectile, self.distance, self.startingAoe, self.finalAoe, self.velocity, self.order)

    self:StartIntervalThink(self.interval)
end

function hero_akasha_sonic_wave_thinker:OnIntervalThink()
    if not IsServer() then return end

    if self.order == 0 then
        self.order = 1
    elseif self.order == 1 then
        self.order = 0
    end

    self.caster:AddNewModifier(self.caster, nil, "hero_akasha_sonic_wave_thinker_animation", { duration = self.interval })

    hero_akasha_sonic_wave_thinker:CastSonicWaves(self.caster, self.ability, self.projectile, self.distance, self.startingAoe, self.finalAoe, self.velocity, self.order)
end

function hero_akasha_sonic_wave_thinker:GetDiagonalAnglePosition(caster, delta)
    local r = RandomInt(10, 1000)

    local angle = caster:GetAnglesAsVector().y

    a = math.rad(delta)

    local point = Vector(math.cos(a), math.sin(a), 0):Normalized() * r

    return caster:GetOrigin() + point
end

function hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, targetPoint, projectile, position, distance, startingAoe, finalAoe, velocity)
    local info = {
        Ability = ability,
        EffectName = projectile,
        vSpawnOrigin = position,
        fDistance = distance,
        fStartRadius = startingAoe,
        fEndRadius = finalAoe,
        Source = caster,
        bHasFrontalCone = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,                            
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,                            
        bDeleteOnHit = false,
        vVelocity = ((targetPoint - position):Normalized()) * velocity,
        bProvidesVision = false
    }

    ProjectileManager:CreateLinearProjectile(info)
end

function hero_akasha_sonic_wave_thinker:CastSonicWaves(caster, ability, projectile, distance, startingAoe, finalAoe, velocity, order)
    local position = caster:GetAbsOrigin()

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.SonicWave.ArcanaLayer", caster)

    if order == 0 then
        -- First wave horizontal/vertical lines
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x, position.y+distance, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x, position.y-distance, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x+distance, position.y, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x-distance, position.y, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
    elseif order == 1 then
        -- Second wave diagonal lines
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, hero_akasha_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 45), projectile, position, distance, startingAoe, finalAoe, velocity)
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, hero_akasha_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 135), projectile, position, distance, startingAoe, finalAoe, velocity)
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, hero_akasha_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 225), projectile, position, distance, startingAoe, finalAoe, velocity)
        hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, hero_akasha_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 315), projectile, position, distance, startingAoe, finalAoe, velocity)
    end

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.SonicWave", caster)
end
--------
function hero_akasha_sonic_wave_thinker_animation:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE 
    }

    return funcs
end

function hero_akasha_sonic_wave_thinker_animation:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.SonicWave.Precast.Arcana", caster)
end

function hero_akasha_sonic_wave_thinker_animation:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_4
end

function hero_akasha_sonic_wave_thinker_animation:GetOverrideAnimationRate()
    return 0.5
end
--------
function hero_akasha_sonic_wave_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function hero_akasha_sonic_wave_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end

function hero_akasha_sonic_wave_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("movement_slow", (self:GetAbility():GetLevel() - 1))
end
-------
function hero_akasha_sonic_wave_modifier:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.sonicWave = self:GetAbility()
end
------------------------
function hero_akasha_sonic_wave_modifier:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function hero_akasha_sonic_wave_modifier:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if event.attacker ~= parent then return end

    if not self.sonicWave:IsCooldownReady() then return end

    local position = parent:GetAbsOrigin()
    local cd = ability:GetSpecialValueFor("proc_cooldown")
    local projectile = "particles/econ/items/queen_of_pain/qop_arcana/qop_arcana_sonic_wave.vpcf"
    local distance = ability:GetLevelSpecialValueFor("distance", (ability:GetLevel() - 1))
    local startingAoe = ability:GetLevelSpecialValueFor("starting_aoe", (ability:GetLevel() - 1))
    local finalAoe = ability:GetLevelSpecialValueFor("final_aoe", (ability:GetLevel() - 1))
    local velocity = ability:GetLevelSpecialValueFor("speed", (ability:GetLevel() - 1))
    local interval = ability:GetLevelSpecialValueFor("summon_interval", (ability:GetLevel() - 1))

    hero_akasha_sonic_wave_thinker:CreateSonicWaveParticle(self.sonicWave, parent,  parent:GetAbsOrigin()+parent:GetForwardVector(), projectile, position, distance, startingAoe, finalAoe, velocity)
    EmitSoundOnLocationWithCaster(parent:GetOrigin(), "Hero_QueenOfPain.SonicWave.ArcanaLayer", parent)
    EmitSoundOnLocationWithCaster(parent:GetOrigin(), "Hero_QueenOfPain.SonicWave", parent)

    self.sonicWave:UseResources(false, false, false, true)
end

