-- d9gwbua
-- Author: dninemfive
-- DateCreated: 2/15/2019 4:33:37 PM
--------------------------------------------------------------
include("PlotIterators");
local mounted = GameInfoTypes["UNITCOMBAT_MOUNTED"]
local mechanized = GameInfoTypes["UNITCOMBAT_ARMOR"]
local bradley = GameInfoTypes["UNIT_D9_AMERICAN_BRADLEY"]
local nimitz = GameInfoTypes["UNIT_D9_AMERICAN_NIMITZ"]
local promo_uabonus = GameInfoTypes["PROMOTION_D9_UABONUS"]

function d9GWBShockAndAwe(attacker, attackunit, attackdmg, attackdmgf, attackunitmxhp, defender, defendunit, defenddmg, defenddmgf, defendmxhp)
	local player = Players[attacker];
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_D9_GWBAMERICA"] then
		 for plot in PlotRingIterator(defendingunit:GetPlot(), 1) do
			if plot:GetNumUnits() > 0 then
				local unit = plot:GetUnit() -- only damages the first unit; damaging all (e.g. with a stack mod, or air units in a city/carrier/improvement) isn't worth the increased processing imo
				if Players[unit:GetOwner()]:GetTeam():IsAtWar(player:GetTeam()) then
					unit:ChangeDamage(10, attacker)
				end
			end
			if plot:IsEnemyCity(attackingunit) then
				plot:GetPlotCity():ChangeDamage(15)
			end
		 end
	end
end
Events.SerialEventUnitSetDamage.Add(d9GWBShockAndAwe)
function d9GWBOnDoTurnUnitIterators(iplayer) --as one script to try and reduce turn times
	local player = Players[iplayer];
	for unit in player:Units() do
		-- Golden Age UA bonuses
		if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_D9_AMERICA_GWB"] then -- unit special abilities don't check for civs in case they're CS gifts
			if player:IsGoldenAge() then
				local combattype = unit:GetUnitCombatType()
				if combattype == mounted or combattype == mechanized or unit:GetUnitType() == bradley then
					unit:SetHasPromotion(promo_uabonus, true)
				end
			else
				unit:SetHasPromotion(promo_uabonus, false)
			end		
		end
		if unit:GetUnitCombatType() == bradley then
			--gib TOW
			--check if adj to city, give free production (1/3 of city prod) to lowest-level unconstructed defense building
		end
		-- free moves for embarked units stacked with Nimitzes
		if unit:GetUnitCombatType() == nimitz then
			-- get stacked embarked unit, foreach give free MPs
		end		
	end
end
GameEvents.PlayerDoTurn.Add(d9GWBOnDoTurnUnitIterators);
function d9GWBOnSelectAllowParadrop(iplayer, unit, x, y, k, isselected, six)
	-- when unit selected, if it is an embarked unit stacked with a Nimitz-Class, claim tile, spawn dummy improvement, disembark; on unit paradrop/deselected, restore claim/improvement
end