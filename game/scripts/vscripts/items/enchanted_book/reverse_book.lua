local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_reverse_book = class(ItemBaseClass)

function item_reverse_book:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    if IsSummonTCOTRPG(caster) then return end
    if caster:GetUnitName() == "npc_dota_hero_invoker" then
      DisplayError(caster:GetPlayerID(), "This Hero Cannot Use This.")
      return
    end

    function canAbilityBeSwapped(name)
      for _,ban in ipairs(BOOK_ABILITY_FORBIDDEN_SWAP) do
        if ban == name then return false end
      end

      return true
    end

    local abilities = {}

    for i=0, caster:GetAbilityCount()-1 do
        local abil = caster:GetAbilityByIndex(i)
        if abil ~= nil then
            if canAbilityBeSwapped(abil:GetAbilityName()) then
                table.insert(abilities, abil:GetAbilityName())
            end
        end
    end

    CustomNetTables:SetTableValue("ability_selection_swap_position", "game_info", { abilities = abilities, userEntIndex = caster:GetEntityIndex(), r = RandomInt(1, 999), z = RandomInt(1, 999)})
    
    if self:GetCurrentCharges() > 1 then
        self:SetCurrentCharges(self:GetCurrentCharges()-1)
    else
        caster:RemoveItem(self)
    end
end