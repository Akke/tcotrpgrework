LinkLuaModifier("tricks_of_the_trade_custom_modifier", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("tricks_of_the_trade_custom_thinker", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("tricks_of_the_trade_custom_banished", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("tricks_of_the_trade_custom_buff", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

tricks_of_the_trade_custom = class(BaseClass)
tricks_of_the_trade_custom_thinker = class(BaseClass)
tricks_of_the_trade_custom_banished = class(BaseClass)
tricks_of_the_trade_custom_modifier = class(BaseClass)
tricks_of_the_trade_custom_buff = class(BaseClassBuff)

function tricks_of_the_trade_custom:GetIntrinsicModifierName()
    return "tricks_of_the_trade_custom_modifier"
end

function tricks_of_the_trade_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function tricks_of_the_trade_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    --todo: check if Length2D instead of Length fixes the stair thing
    if (point - caster:GetAbsOrigin()):Length2D() > self:GetEffectiveCastRange(caster:GetOrigin(), nil) then return end -- Exceeded cast range

    -- Give Riki his agility buff --
    caster:AddNewModifier(caster, self, "tricks_of_the_trade_custom_buff", {
        duration = duration
    })

    -- Particles
    self.castParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks_cast.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(self.castParticle, 0, point)
    ParticleManager:SetParticleControl(self.castParticle, 3, point)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(self.particle, 0, point)
    ParticleManager:SetParticleControl(self.particle, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(self.particle, 2, Vector(duration, 0, 0))

    -- Thinker
    local interval = self:GetSpecialValueFor("damage_interval")

    if caster:HasItemInInventory("item_ultimate_scepter") or caster:HasModifier("modifier_item_ultimate_scepter_consumed_alchemist") or caster:HasModifier("modifier_item_ultimate_scepter_consumed") then
        interval = 1 / caster:GetAttacksPerSecond()
    end

    FindClearSpaceForUnit(caster, point, true)

    caster:AddNewModifier(caster, self, "tricks_of_the_trade_custom_banished", {})

    caster:AddNewModifier(caster, self, "tricks_of_the_trade_custom_thinker", {
        interval = interval,
        radius = radius
    })
end

function tricks_of_the_trade_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("tricks_of_the_trade_custom_thinker")
    caster:RemoveModifierByName("tricks_of_the_trade_custom_banished")

    -- Remove Particles
    ParticleManager:DestroyParticle(self.castParticle, true)
    ParticleManager:ReleaseParticleIndex(self.castParticle)

    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
end
--------------
function tricks_of_the_trade_custom_thinker:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.interval = params.interval
    self.radius = params.radius

    EmitSoundOn("Hero_Riki.TricksOfTheTrade", caster)

    self:StartIntervalThink(self.interval)
end

function tricks_of_the_trade_custom_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    local backstab = caster:FindAbilityByName("riki_backstab")
    local backstabLevel = backstab:GetLevel()

    local damageMultiplier = backstab:GetSpecialValueFor("damage_multiplier") / 100

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES),
        FIND_CLOSEST, false)

    if #units > 0 then
        local target = units[RandomInt(1, #units)]
        if target and not target:IsNull() then
            -- Do a backstab if it exists and is leveled
            if backstabLevel > 0 then
                EmitSoundOn("Hero_Riki.Backstab", target)

                local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_ABSORIGIN_FOLLOW, target) 
                ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true) 

                ApplyDamage({
                    victim = target, 
                    attacker = caster, 
                    damage = caster:GetAverageTrueAttackDamage(caster) + (caster:GetAgility() * damageMultiplier), 
                    damage_type = backstab:GetAbilityDamageType(),
                    ability = self:GetAbility()
                })

                -- apply poisonous dagger --
                local poisonousDagger = caster:FindAbilityByName("riki_poisonous_dagger")
                if poisonousDagger ~= nil and poisonousDagger:GetLevel() > 0 or not poisonousDagger:IsCooldownReady() then
                    if not poisonousDagger:IsCooldownReady() then return end

                    local duration = poisonousDagger:GetLevelSpecialValueFor("duration", (poisonousDagger:GetLevel() - 1))

                    local buff = target:FindModifierByName("modifier_riki_poisonous_dagger_debuff")
                    if buff == nil then
                        buff = target:AddNewModifier(caster, poisonousDagger, "modifier_riki_poisonous_dagger_debuff", {
                            duration = duration
                        })
                    end

                    if buff ~= nil then
                        if buff:GetStackCount() < poisonousDagger:GetSpecialValueFor("max_stacks") then
                            buff:IncrementStackCount()
                        end

                        buff:ForceRefresh()
                    end

                    poisonousDagger:UseResources(false, false, false, true)
                end
            end

            caster:PerformAttack(target, true, true, true, false, false, false, false)
        end
    end
end
-------------------
function tricks_of_the_trade_custom_banished:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    caster:AddNoDraw()
end

function tricks_of_the_trade_custom_banished:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    caster:RemoveNoDraw()

    caster:RemoveModifierByName("tricks_of_the_trade_custom_buff")
end

function tricks_of_the_trade_custom_banished:CheckState()
    local states = {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }

    return states
end
-----------
function tricks_of_the_trade_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }

    return funcs
end

function tricks_of_the_trade_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.agility = self:GetParent():GetBaseAgility() * (self:GetAbility():GetSpecialValueFor("agi_mult")/100)

    self:InvokeBonusAgility()
end

function tricks_of_the_trade_custom_buff:AddCustomTransmitterData()
    return
    {
        agility = self.fAgility,
    }
end

function tricks_of_the_trade_custom_buff:HandleCustomTransmitterData(data)
    if data.agility ~= nil then
        self.fAgility = tonumber(data.agility)
    end
end

function tricks_of_the_trade_custom_buff:InvokeBonusAgility()
    if IsServer() == true then
        self.fAgility = self.agility

        self:SendBuffRefreshToClients()
    end
end

function tricks_of_the_trade_custom_buff:GetModifierBonusStats_Agility()
    return self.fAgility
end