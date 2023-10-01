LinkLuaModifier("modifier_boss_lava", "bosses/lava.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_lava_follower", "bosses/lava.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_lava = class(BaseClass)
modifier_boss_lava = class(boss_lava)
modifier_boss_lava_follower = class(boss_lava)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = ""
--------------------
function boss_lava:GetIntrinsicModifierName()
    return "modifier_boss_lava"
end

function modifier_boss_lava:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
    }
    return funcs
end

function modifier_boss_lava:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_lava:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_lava:OnTakeDamage(event)
    if not IsServer() then return end

    if event.unit ~= self.boss then return end

    self.canRegen = false
    if self.regenTimer ~= nil then
        Timers:RemoveTimer(self.regenTimer)
    end
    
    self.regenTimer = Timers:CreateTimer(5.0, function()
        self.canRegen = true
    end)
end

function modifier_boss_lava:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_lava:OnCreated(kv)
    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil
end

function modifier_boss_lava:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_lava_1" then return true end
    if follower:GetUnitName() == "npc_dota_creature_lava_2" then return true end
    if follower:GetUnitName() == "npc_dota_creature_140_crip_Robo" then return true end

    return false
end

function modifier_boss_lava:OnDeath(event)
    if not IsServer() then return end
end
-----------
function modifier_boss_lava_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_lava_follower:OnCreated(kv)
    if not IsServer() then return end

    local parent = self:GetParent()

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    self.fireball = parent:FindAbilityByName("lava_drake_flames")
    self.meteor = parent:FindAbilityByName("invoker_chaos_meteor_lua")

    if parent:GetUnitName() == "npc_dota_creature_lava_2" then
        self.particle = ParticleManager:CreateParticle("particles/econ/items/invoker/glorious_inspiration/invoker_forge_spirit_ambient_esl.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.particle, 0, parent:GetOrigin())
        ParticleManager:SetParticleControl(self.particle, 1, parent:GetOrigin())
    end

    if parent:GetUnitName() == "npc_dota_creature_140_crip_Robo" then
        self.particle = ParticleManager:CreateParticle("particles/econ/items/warlock/warlock_golem_obsidian/golem_ambient_obsidian.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 7, parent, PATTACH_POINT_FOLLOW, "attach_mane2", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 10, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 11, parent, PATTACH_POINT_FOLLOW, "attach_attack2", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 12, parent, PATTACH_POINT_FOLLOW, "attach_mane2", parent:GetAbsOrigin(), true)
    end

    self:StartIntervalThink(1)
end

function modifier_boss_lava_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_lava_follower:OnIntervalThink()
    local parent = self:GetParent()

    local flameGuard = parent:FindAbilityByName("creature_lava_flame_guard")
    
    if parent:IsAlive() then
        if _G.FinalGameWavesEnabled then
            Timers:CreateTimer(parent:entindex()/1000, function()
                UTIL_RemoveImmediate(parent)
            end)
            return
        end
    
        if flameGuard ~= nil then 
            if flameGuard:IsCooldownReady() and not parent:IsSilenced() then
                SpellCaster:Cast(flameGuard, parent, true)
            end
        end
    end

    local target = parent:GetAggroTarget()

    if target then
        if self.meteor and self.meteor:GetLevel() > 0 then
            if self.meteor:IsFullyCastable() and not parent:IsStunned() and not parent:IsSilenced() and not parent:IsHexed() then
                if (target:GetAbsOrigin()-parent:GetAbsOrigin()):Length2D() <= self.meteor:GetEffectiveCastRange(parent:GetAbsOrigin(), parent) then
                    SpellCaster:Cast(self.meteor, target:GetAbsOrigin(), true)
                end
            end
        end

        if self.fireball and self.fireball:GetLevel() > 0 then
            if self.fireball:IsFullyCastable() and not parent:IsStunned() and not parent:IsSilenced() and not parent:IsHexed() then
                if (target:GetAbsOrigin()-parent:GetAbsOrigin()):Length2D() <= self.fireball:GetEffectiveCastRange(parent:GetAbsOrigin(), parent) then
                    SpellCaster:Cast(self.fireball, target:GetAbsOrigin(), true)
                end
            end
        end
    end
end

function modifier_boss_lava_follower:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end

    local respawnTime = CREEP_RESPAWN_TIME

    if GetMapName() == "tcotrpg_1v1" then respawnTime = 15 end

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" then
        respawnTime = respawnTime / 2
    end

    -- Drops --
    local Tome_Chance = event.attacker:GenerateDropChance()
    local Meteorite_Chance = event.attacker:GenerateDropChance()
    local EnrageCrystal_Chance = event.attacker:GenerateDropChance()
    
    if parent:GetUnitName() == "npc_dota_creature_lava_1" or parent:GetUnitName() == "npc_dota_creature_lava_2" then
        if Meteorite_Chance <= 0.5 and not _G.ItemDroppedMeteoriteSword then
            DropNeutralItemAtPositionForHero("item_fallen_meteor", parent:GetAbsOrigin(), parent, 1, false)
            _G.ItemDroppedMeteoriteSword = true
        end

        if Tome_Chance <= 25 then
            DropNeutralItemAtPositionForHero("item_tome_un_5", parent:GetAbsOrigin(), parent, 1, false)
        end
    end

    if parent:GetUnitName() == "npc_dota_creature_140_crip_Robo" then
        --if EnrageCrystal_Chance <= 0.45 and not _G.ItemDroppedEnrageCrystal then
            --DropNeutralItemAtPositionForHero("item_stygian_crystal", parent:GetAbsOrigin(), parent, 1, false)
        --    _G.ItemDroppedEnrageCrystal = true
        --end

        if event.attacker:GenerateDropChance() <= 2.5 then
            local runes = {
                "item_socket_rune_legendary_exodus_shield",
            }
    
            local rune = runes[RandomInt(1, #runes)]
    
            DropNeutralItemAtPositionForHero(rune, parent:GetAbsOrigin(), parent, -1, true)
        end
    end

    Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_lava_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_lava:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_lava_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_lava_follower:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

    local level = GetLevelFromDifficulty()

     -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, parent:GetAbilityCount() - 1 do
            local abil = parent:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
            end
        end
    end)
end
