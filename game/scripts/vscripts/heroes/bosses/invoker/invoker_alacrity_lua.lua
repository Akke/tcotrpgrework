invoker_alacrity_lua = class({})
LinkLuaModifier( "modifier_invoker_alacrity_lua", "heroes/bosses/invoker/modifier_invoker_alacrity_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function invoker_alacrity_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local duration = self:GetSpecialValueFor("duration")

	-- add modifier
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_invoker_alacrity_lua", -- modifier name
		{ duration = duration } -- kv
	)

	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_medusa_split_shot", -- modifier name
		{ duration = duration } -- kv
	)
end