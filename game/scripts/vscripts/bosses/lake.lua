LinkLuaModifier("modifier_boss_lake", "bosses/lake.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_lake_follower", "bosses/lake.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_lake = class(BaseClass)
modifier_boss_lake = class(boss_lake)
modifier_boss_lake_follower = class(boss_lake)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = "npc_dota_creature_130_boss_death"
--------------------
function boss_lake:GetIntrinsicModifierName()
    return "modifier_boss_lake"
end

function modifier_boss_lake:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
    return funcs
end

function modifier_boss_lake:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_lake:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_lake:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_lake:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_lake:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_lake:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_lake:OnTakeDamage(event)
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

function modifier_boss_lake:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_lake:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    local level = GetLevelFromDifficulty()

    self.status = 25 * BOSS_STAGE
    self:InvokeStatusResistance()

    self.chillingTouch = self.boss:FindAbilityByName("boss_ancient_apparition_chilling_touch_custom")

    if not self.boss:HasAbility("boss_ancient_apparition_chilling_touch_custom") then
        self.chillingTouch = self.boss:AddAbility("boss_ancient_apparition_chilling_touch_custom") 
    end

    --if not self.boss:HasAbility("boss_ancient_apparition_chilling_barrier") then
    --    self.chillingBarrier = self.boss:AddAbility("boss_ancient_apparition_chilling_barrier") 
    --end

    self.chillingGround = self.boss:FindAbilityByName("boss_ancient_apparition_chilling_ground")

    if not self.boss:HasAbility("boss_ancient_apparition_chilling_ground") then
        self.chillingGround = self.boss:AddAbility("boss_ancient_apparition_chilling_ground") 
    end

    self.iceBlast = self.boss:FindAbilityByName("ancient_apparition_ice_blast")

    if not self.boss:HasAbility("ancient_apparition_ice_blast") then
        self.iceBlast = self.boss:AddAbility("ancient_apparition_ice_blast") 
    end

    self.iceBlastRelease = self.boss:FindAbilityByName("ancient_apparition_ice_blast_release")

    if not self.boss:HasAbility("ancient_apparition_ice_blast_release") then
        self.iceBlastRelease = self.boss:AddAbility("ancient_apparition_ice_blast_release") 
    end

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, self.boss:GetAbilityCount() - 1 do
            local abil = self.boss:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
                if abil == self.chillingTouch and not abil:GetAutoCastState() then
                    abil:ToggleAutoCast()
                end
            end
        end
    end)

    self.boss:AddItemByName("item_ultimate_scepter")
    self.boss:AddItemByName("item_aghanims_shard")

    self:StartIntervalThink(1)
end

function modifier_boss_lake:OnIntervalThink()
    if not self.boss:IsAlive() then return end

    if self.boss:GetAggroTarget() == nil then return end
    if self.boss:IsSilenced() or self.boss:IsStunned() or self.boss:IsHexed() then return end

    local enemies = FindUnitsInRadius(self.boss:GetTeam(), self.boss:GetAbsOrigin(), nil,
        850, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(enemies) do
        if self.chillingGround:IsCooldownReady() and not self.boss:IsSilenced() and not self.boss:IsStunned() and not self.boss:IsHexed() then
            SpellCaster:Cast(self.chillingGround, enemy, true)
        end

        if self.iceBlast:IsCooldownReady() and self.iceBlastRelease:IsCooldownReady() and not self.boss:IsSilenced() and not self.boss:IsStunned() and not self.boss:IsHexed() then
            SpellCaster:Cast(self.iceBlast, enemy, true)
            Timers:CreateTimer(0.5, function()
                SpellCaster:Cast(self.iceBlastRelease, self.boss, true)
            end)
        end
    end
end

function modifier_boss_lake:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_130_crip3_death" then return true end
    if follower:GetUnitName() == "npc_dota_creature_130_crip2_death" then return true end
    if follower:GetUnitName() == "npc_dota_creature_130_crip1_death" then return true end

    return false
end

function modifier_boss_lake:ProgressToNext()
    if PARTICLE_ID ~= nil then
        ParticleManager:DestroyParticle(PARTICLE_ID, true)
        ParticleManager:ReleaseParticleIndex(PARTICLE_ID)
    end

    --todo: you also need to apply the new stage abilities to them when they respawn.
    --this just updates the currently spawned units.
    local followers = FindUnitsInRadius(self.boss:GetTeam(), self.boss:GetAbsOrigin(), nil,
        99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,minion in ipairs(followers) do
        if minion:GetUnitName() == "npc_dota_creature_130_crip3_death" or
        minion:GetUnitName() == "npc_dota_creature_130_crip2_death" then
            minion:FindModifierByNameAndCaster("modifier_boss_lake_follower", minion):ForceRefresh()
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end

function modifier_boss_lake:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit

    if victim ~= self:GetParent() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" then
        respawnTime = respawnTime / 2
    end

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_lake", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })
        end)
    end)

    if BOSS_STAGE < BOSS_MAX_STAGE then
        BOSS_STAGE = BOSS_STAGE + 1

        self.status = 25 * BOSS_STAGE
        self:InvokeStatusResistance()

        self:ProgressToNext()
    end

    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() then
            if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED then
                if hero:FindItemInAnyInventory("item_reef_soul") == nil and _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                    --hero:AddItemByName("item_reef_soul")
                end
                
                hero:ModifyGold(20000, false, 0)
            end
        end
    end

    DropNeutralItemAtPositionForHero("item_reef_soul", victim:GetAbsOrigin(), victim, -1, true)

    -- Drops --
    if event.attacker:GenerateDropChance() <= 10.0 then
        local runes = {
            "item_socket_rune_legendary_chronomancer",
        }

        local rune = runes[RandomInt(1, #runes)]

        DropNeutralItemAtPositionForHero(rune, victim:GetAbsOrigin(), victim, -1, true)
    end
    --
end
-----------
function modifier_boss_lake_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_lake_follower:OnCreated(kv)
    if not IsServer() then return end

    local parent = self:GetParent()

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    self:StartIntervalThink(1.0)
end

function modifier_boss_lake_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_lake_follower:OnIntervalThink()
    local parent = self:GetParent()

    if parent:IsAlive() then
        if _G.FinalGameWavesEnabled then
            Timers:CreateTimer(parent:entindex()/1000, function()
                UTIL_RemoveImmediate(parent)
            end)
            return
        end
    end

    if parent:GetUnitName() == "npc_dota_creature_130_crip1_death" then
        if self.embrace ~= nil and self.embrace:GetLevel() > 0 then
            local allies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
                600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,ally in ipairs(allies) do
                if self.embrace:IsCooldownReady() and ally:GetHealthPercent() <= 30 then
                    SpellCaster:Cast(self.embrace, ally, true)
                    return
                end
            end
        end

    end
end

function modifier_boss_lake_follower:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    local respawnTime = CREEP_RESPAWN_TIME

    if GetMapName() == "tcotrpg_1v1" then respawnTime = 15 end

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" then
        respawnTime = respawnTime / 2
    end

    if unitName == "npc_dota_creature_130_crip3_death" and event.attacker:GenerateDropChance() <= 20.0 then
        DropNeutralItemAtPositionForHero("item_blessed_book", parent:GetAbsOrigin(), parent, 1, false)
    end

    local chance = event.attacker:GenerateDropChance()
    if chance <= 0.2 and not _G.ItemDroppedFrozenCrystal then
        DropNeutralItemAtPositionForHero("item_frozen_crystal", parent:GetAbsOrigin(), parent, 1, false)
        _G.ItemDroppedFrozenCrystal = true
    end

    Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_lake_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_lake:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_lake_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_lake_follower:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

    local level = GetLevelFromDifficulty()

    self.nova = parent:FindAbilityByName("creep_ancient_apparition_crystal_nova_custom")

    if parent:GetUnitName() == "npc_dota_creature_130_crip3_death" and not parent:HasAbility("creep_ancient_apparition_crystal_nova_custom") then
        self.nova = parent:AddAbility("creep_ancient_apparition_crystal_nova_custom") 
    end

    if self.nova ~= nil then
        self.nova:ToggleAutoCast()
    end

    self.punch = parent:FindAbilityByName("creep_ancient_apparition_punch")

    if parent:GetUnitName() == "npc_dota_creature_130_crip2_death" and not parent:HasAbility("creep_ancient_apparition_punch") then
        self.punch = parent:AddAbility("creep_ancient_apparition_punch") 
    end

    if self.punch ~= nil then
        self.punch:ToggleAutoCast()
    end

    self.embrace = parent:FindAbilityByName("creep_ancient_apparition_cold_embrace")

    if parent:GetUnitName() == "npc_dota_creature_130_crip1_death" and not parent:HasAbility("creep_ancient_apparition_cold_embrace") then
        self.embrace = parent:AddAbility("creep_ancient_apparition_cold_embrace") 
    end

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
