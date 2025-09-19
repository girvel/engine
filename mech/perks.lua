--- All perks except feats
local perks = {}

perks.passive = {
  modify_activation = function(self, entity, value, codename)
    if codename == "opportunity_attack" then
      return false
    end
    return value
  end,
}

Ldump.mark(perks, {}, ...)
return perks
