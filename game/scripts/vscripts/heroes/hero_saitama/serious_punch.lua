LinkLuaModifier("modifier_saitama_limiter", "heroes/hero_saitama/modifier_saitama_limiter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saitama_serious_punch", "heroes/hero_saitama/serious_punch.lua", LUA_MODIFIER_MOTION_NONE)

saitama_serious_punch = class({})

saitama_serious_punch = class({
	GetIntrinsicModifierName = function() return "modifier_saitama_serious_punch" end,
})

modifier_saitama_serious_punch = class({
	IsHidden = function() return true end,
})

if IsServer() then
	--[[
	function saitama_serious_punch:OnSpellStart()
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		if not target:TriggerSpellAbsorb(self) then
			target:TriggerSpellReflect(self)
			local damage = caster:GetAverageTrueAttackDamage(target) * (self:GetSpecialValueFor("base_damage_multiplier_pct") + self:GetSpecialValueFor("damage_multiplier_per_stack_pct") * caster:GetModifierStackCount("modifier_saitama_limiter", caster)) * 0.01

			target:EmitSound("Hero_Earthshaker.EchoSlam")
			ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_fallback_mid_egset.vpcf", PATTACH_ABSORIGIN, target)

			ApplyDamage({
				attacker = caster,
				victim = target,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = self
			})
		end
	end
	--]]

	function modifier_saitama_serious_punch:DeclareFunctions()
        return {
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end

    function modifier_saitama_serious_punch:OnAttackLanded(event)
        local parent = self:GetParent()

        if parent ~= event.attacker then return end

        local ability = self:GetAbility()
        if parent:PassivesDisabled() or not ability:IsCooldownReady() or not RollPercentage(ability:GetSpecialValueFor("chance")) or ability:GetManaCost(-1) > parent:GetMana() then return end

        local target = event.target
        if not target:TriggerSpellAbsorb(ability) then
			target:TriggerSpellReflect(ability)
			local damage = parent:GetAverageTrueAttackDamage(target) * (ability:GetSpecialValueFor("base_damage_multiplier_pct") + ability:GetSpecialValueFor("damage_multiplier_per_stack_pct") * parent:GetModifierStackCount("modifier_saitama_limiter", parent)) * 0.01

			target:EmitSound("Hero_Earthshaker.EchoSlam")
			ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_fallback_mid_egset.vpcf", PATTACH_ABSORIGIN, target)

			ApplyDamage({
				attacker = parent,
				victim = target,
				damage = damage,
				damage_type = ability:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = ability
			})

			ability:UseResources(true, false, false, true)
		end
    end
end
