local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_enchanted_book = class(ItemBaseClass)

function item_enchanted_book:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    if IsSummonTCOTRPG(caster) then return end
    if caster:GetUnitName() == "npc_dota_hero_invoker" then
      DisplayError(caster:GetPlayerID(), "This Hero Cannot Use This.")
      return
    end

    if caster:GetUnitName() == "npc_dota_hero_meepo" then DisplayError(caster:GetPlayerID(), "CHEEKY BREEKY YOU CANNOT DO THAT") return end

    function canAbilityBeChanged(name)
      for _,ban in ipairs(BOOK_ABILITY_CHANGE_PROHIBITED) do
        if ban == name then return false end
      end

      return true
    end

    local accountID = PlayerResource:GetSteamAccountID(caster:GetPlayerID())
    local abilities = {}

    for _,ability in ipairs(_G.PlayerStoredAbilities[accountID]) do
        if canAbilityBeChanged(ability) then
            table.insert(abilities, ability)
        end
    end

    CustomNetTables:SetTableValue("ability_selection_open", "game_info", { abilities = abilities, userEntIndex = caster:GetEntityIndex(), r = RandomInt(1, 999), z = RandomInt(1, 999)})
    
    if self:GetCurrentCharges() > 1 then
        self:SetCurrentCharges(self:GetCurrentCharges()-1)
    else
        caster:RemoveItem(self)
    end
end