LinkLuaModifier("modifier_tanya_counterattack", "heroes/hero_tanya/tanya_counterattack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tanya_counterattack_buff", "heroes/hero_tanya/tanya_counterattack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tanya_counterattack_debuff", "heroes/hero_tanya/tanya_counterattack.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

tanya_counterattack = class(ItemBaseClass)
modifier_tanya_counterattack = class(tanya_counterattack)
modifier_tanya_counterattack_buff = class(ItemBaseClassBuff)
modifier_tanya_counterattack_debuff = class(ItemBaseClassDebuff)
-------------
function tanya_counterattack:GetIntrinsicModifierName()
    return "modifier_tanya_counterattack"
end
------------
function modifier_tanya_counterattack:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_tanya_counterattack:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.target then return end
    if parent:IsRangedAttacker() then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) or not ability:IsCooldownReady() or parent:HasModifier("modifier_tanya_counterattack_buff") then return end 

    parent:AddNewModifier(parent, ability, "modifier_tanya_counterattack_buff", { duration = 1})

    ability:UseResources(false, false, false, true)
end
------------
function modifier_tanya_counterattack_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_tanya_counterattack_buff:GetModifierAttackSpeedBonus_Constant()
    return 1000
end

function modifier_tanya_counterattack_buff:OnCreated(props)
    if not IsServer() then return end 

    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    self.records = {}
    self.procs = false

    self.attacks = self.ability:GetSpecialValueFor("number_of_hits")

    self.count = 0
end

function modifier_tanya_counterattack_buff:OnAttackRecordDestroy(event)
	if not self.records[event.record] then return end

	-- destroy record, and immediately destroy ignore armor modifier
	local modifier = self.records[event.record]

	if type(modifier)=='table' and not modifier:IsNull() then modifier:Destroy() end

	self.records[event.record] = nil
end

function modifier_tanya_counterattack_buff:OnAttackStart(event)
	if not IsServer() then return end
	if event.attacker~=self:GetParent() then return end

	self.procs = true
end

function modifier_tanya_counterattack_buff:OnAttack(event)
	if not IsServer() then return end
	if event.attacker~=self:GetParent() then return end

	-- check if procs
	if not self.procs then return end

	self.procs = false

	-- procs, record attack
	self.records[event.record] = true
end

function modifier_tanya_counterattack_buff:OnAttackLanded(event)
    if not IsServer() then return end 

    if not self.records[event.record] then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    if self.count < self.attacks then
        self.count = self.count + 1

        local modifier = event.target:AddNewModifier(parent, self.ability, "modifier_tanya_counterattack_debuff", { duration = 0.5 })
        
        self.records[event.record] = modifier
        
        local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_courage_hit_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
        ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(effect_cast)

        EmitSoundOn("Hero_LegionCommander.Courage", parent)
    else
        self:Destroy()
    end
end
-------
function modifier_tanya_counterattack_debuff:DeclareFunctions()
	local funcs = {
		-- MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, -- for base armor only
		MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR, -- for all armor
	}

	return funcs
end

function modifier_tanya_counterattack_debuff:GetModifierIgnorePhysicalArmor()
	if not IsServer() then return end
	-- strip base armor
	return 1
end

function modifier_tanya_counterattack_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end