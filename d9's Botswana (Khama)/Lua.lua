-- Author: dninemfive
-- Many thanks to TopHatPaladin and Chrisy15 for help, noted below.
-- DateCreated: 7/15/2019 9:00:46 AM
--------------------------------------------------------------
local kgosi = GameInfoTypes["UNIT_D9_BOTSWANAN_KGOSI"]
local ignoreZOC = GameInfoTypes["PROMOTION_D9_KGOSI_ZOC"]
local botswana = GameInfoTypes["CIVILIZATION_D9_BOTSWANA"]
local food = GameInfoTypes["BUILDING_D9_BOTS_FOODDUMMY"]
local happiness = GameInfoTypes["BUILDING_D9_BOTS_HAPPDUMMY"]
-- variables
local healAmount = -10
local foodDiv = 2 -- food divisor
local growthHappiness = 2
-- intentionally a generic great general
local iGeneralClass = GameInfoTypes["UNITCLASS_GREAT_GENERAL"]

function d9BotswanaDoTurn(iplayer)
	local player = Players[iplayer];
	if player:IsEverAlive() and (player:GetCivilizationType() == botswana) then
		print("processing Botswana's turn...")
		d9BotswanaPula(player)
		d9BatswanaKgosi(player)
		if 1 then print("1 equals true") end
	end
end
GameEvents.PlayerDoTurn.Add(d9BotswanaDoTurn);
--====== Trait lua ======--
function d9BotswanaPula(player)
	-- print("  pula:")
	if player:GetNumCities() > 0 then
		for city in player:Cities() do
			-- print("    processing " .. city:GetName())
			-- count freshwater worked tiles 
			local ct = 0
			-- Chrisy15 credits this to Bane_
			for i = 0, city:GetNumCityPlots() - 1, 1 do
				-- print("      inside for loop: " .. i)
				local plot = city:GetCityIndexPlot(i)
				if (plot ~= nil) and (plot:GetWorkingCity() == city) and plot:IsBeingWorked() and plot:IsFreshWater() then
					ct = ct + 1 -- I miss ct++ :(
				end
			end
			-- print("end for loop")
			-- give city food dummies equal to floor(count/2)
			city:SetNumRealBuilding(food, math.floor(ct/foodDiv))
			-- print("    gave " .. city:GetName() .. math.floor(ct/foodDiv) .. " food (ct = " .. ct .. ")")
			-- if city is growing, give 2 happiness dummy
			if city:FoodDifference() > 0 then
				-- print("City is growing, giving happiness...")
				city:SetNumRealBuilding(happiness, growthHappiness)
			end
		end
	end
end
--====== UU lua ======--
function d9BatswanaKgosi(player) -- not a typo, it's the adjectival form if I'm not mistaken
	-- if player:GetCivilizationType() == botswana then -- checked in the doturn call
	if player:HasUnitOfClassType(iGeneralClass) then
		print("  kgosi:")
		-- iterate through all units, remove any ignoreZOC promotions
		for unit in player:Units() do
			unit:SetHasPromotion(ignoreZOC, false)
		end
		-- iterate through all units, grant ZOC promotions to units stacked with or adjacent to Kgosi, heal if Kgosi in hills
		for unit in player:Units() do			
			if unit:GetUnitCombatType() == kgosi then
				print("Kgosi found")
				local isInHills = unit:GetPlot():IsHills()
				print("  isInHills = " .. isInHills)
				for other in adjacentUnits(unit) do
					other:SetHasPromotion(ignoreZOC, true)
					if isInHills then
						other:ChangeDamage(healAmount)
					end
				end
			end
		end
	end
	-- end
end
-- following code written entirely by TopHatPaladin
function LastKgosiKilled(playerID, unitID, unitType, iX, iY, bDelay)
    if not bDelay then
        if unitType == kgosi then
            local pPlayer = Players[playerID]
            if (pPlayer:GetCivilizationType() == botswana) and (not pPlayer:HasUnitOfClassType(iGeneralClass)) then
                for pUnit in pPlayer:Units() do
					pUnit:SetHasPromotion(ignoreZOC, false)
                end
            end
        end
    end
end
GameEvents.UnitPrekill.Add(LastKgosiKilled)
--====== UI lua ======--
-- if Botswana has any cities
-- for each Batswana city
-- for each tile the city owns
-- if the tile has a Conservatory
-- 		iterate through all tiles, count conservatories, set bAdjToNW and bAdjToResource as needed
-- select dummy based on combination of ct > 2, adjToNW, adjToRes
-- gonna need improvements for:
--		no adjacencies (1)
--		adj only to conservatories, NWs, or resources (3)
-- 		adj to two of them (3)
--		adj to all three (1)