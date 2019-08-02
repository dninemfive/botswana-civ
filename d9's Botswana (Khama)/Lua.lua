-- Author: dninemfive
-- Many thanks to TopHatPaladin and Chrisy15 for help, noted below.
-- DateCreated: 7/15/2019 9:00:46 AM
--------------------------------------------------------------
include("PlotIterators")

local kgosi = GameInfoTypes["UNIT_D9_BOTSWANAN_KGOSI"]
local ignoreZOC = GameInfoTypes["PROMOTION_D9_KGOSI_ZOC"]
local botswana = GameInfoTypes["CIVILIZATION_D9_BOTSWANA"]
local food = GameInfoTypes["BUILDING_D9_BOTS_FOODDUMMY"]
local happiness = GameInfoTypes["BUILDING_D9_BOTS_HAPPDUMMY"]
local pula = GameInfoTypes["POLICY_D9_PULAHAPPINESS"]
-- improvement ids
local iNumDirections = DirectionTypes.NUM_DIRECTION_TYPES - 1
local tImprovementPlots = {}
local consa = GameInfoTypes["IMPROVEMENT_D9_CONSERVATIONAREA"]
local consa2 = GameInfoTypes["IMPROVEMENT_D9_CONSAREATWO"]
local consa3 = GameInfoTypes["IMPROVEMENT_D9_CONSAREATHREE"]
local consa4 = GameInfoTypes["IMPROVEMENT_D9_CONSAREAFOUR"]
-- variables
local healAmount = -10
local foodDiv = 2 -- food divisor
local growthHappiness = 2
local nwValue = 3 -- natural wonder value
-- vanilla references
local iGeneralClass = GameInfoTypes["UNITCLASS_GREAT_GENERAL"]
local iFeatureFallout = GameInfoTypes["FEATURE_FALLOUT"]

function d9BotswanaDoTurn(iplayer)
	local player = Players[iplayer];
	if player:IsEverAlive() and (player:GetCivilizationType() == botswana) then
		print("processing Botswana's turn...")
		d9BotswanaPula(player)
		d9BatswanaKgosi(player)
	end
end
GameEvents.PlayerDoTurn.Add(d9BotswanaDoTurn);
--====== Trait lua ======--
function d9BotswanaPula(player)
	if player:GetNumCities() > 0 then
		for city in player:Cities() do
			local ct = 0 -- worked freshwater tiles
			-- Chrisy15 credits this to Bane_
			for i = 0, city:GetNumCityPlots() - 1, 1 do
				local plot = city:GetCityIndexPlot(i)
				if (plot ~= nil) and (plot:GetWorkingCity() == city) and plot:IsBeingWorked() and plot:IsFreshWater() then
					ct = ct + 1
				end
			end
			city:SetNumRealBuilding(food, math.floor(ct/foodDiv))
			-- print("  city ".. city:GetName() .. ": is growing?")
			if city:FoodDifference() > 0 then
				city:SetNumRealBuilding(happiness, growthHappiness)
				-- print("    yes, adding happiness")
			end
		end
	end
end
--====== UU lua ======--
function d9BatswanaKgosi(player) -- not a typo, it's the adjectival form if I'm not mistaken
	-- if player:GetCivilizationType() == botswana then -- checked in the doturn call
	if player:HasUnitOfClassType(iGeneralClass) then
		-- print("  kgosi:")
		-- iterate through all units, remove any ignoreZOC promotions
		for unit in player:Units() do
			-- print("    unit: " .. unit:GetName())
			if unit:GetUnitType() ~= kgosi then unit:SetHasPromotion(ignoreZOC, false) end
		end
		-- iterate through all units, grant ZOC promotions to units stacked with or adjacent to Kgosi, heal if Kgosi in hills
		for unit in player:Units() do			
			-- print("unit " .. unit:GetName() .. " type = " .. unit:GetUnitType() .. ", kgosi = " .. kgosi)
			if unit:GetUnitType() == kgosi then
				-- print("    Kgosi found")
				local curPlot = unit:GetPlot()
				-- grant promo to stacked units
				for i = 0,(curPlot:GetNumUnits() - 1) do
					local otherUnit = curPlot:GetUnit(i)
					-- print("Stacked with Kgosi: " .. otherUnit:GetName())
					if otherUnit:GetOwner() == player:GetID() and otherUnit:IsCombatUnit() then
						otherUnit:SetHasPromotion(ignoreZOC, true)
						if curPlot:IsHills() then
							otherUnit:ChangeDamage(healAmount)
						end
					end
				end
				-- iterate through adjacent plots and grant appropriate promos
				for plot in PlotRingIterator(curPlot, 1) do 
					for i = 0,(plot:GetNumUnits() - 1) do
						local anotherUnit = plot:GetUnit(i)
						-- print("    Adjacent to Kgosi: " .. anotherUnit:GetName())
						if anotherUnit:GetOwner() == player:GetID() and anotherUnit:IsCombatUnit() then
							-- print("      Unit is owned by Botswana and is a combat unit.")
							anotherUnit:SetHasPromotion(ignoreZOC, true)
							if curPlot:IsHills() then
								anotherUnit:ChangeDamage(healAmount)
							end
						end
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
-- end TopHatPaladin code
-- following code from Thayae Kittaya, written by Chrisy15
function GivePulaPolicy(playerID)    -- Should this even pass a playerID? Who nose
	-- print("  givePulaPolicy")
    for playerID, pPlayer in pairs(Players) do
        if (pPlayer:GetCivilizationType() == botswana and pPlayer:IsEverAlive()) then
            if not pPlayer:HasPolicy(pula) then
                if Player.GrantPolicy then
                    pPlayer:GrantPolicy(pula, true)
                else
                    pPlayer:SetNumFreePolicies(1)
                    pPlayer:SetNumFreePolicies(0)
                    pPlayer:SetHasPolicy(pula, true)
                end
            end
        end
    end
end
Events.LoadScreenClose.Add(GivePulaPolicy)
-- end Chrisy15 code
--====== UI lua ======--
-- if Botswana has any cities
-- for each Batswana city
-- 	for each tile the city owns
-- 		if the tile has a Conservatory
-- 			for each adjacent tile
--				if tile is unimproved/has conservatory, ++; if natural wonder, ++++
--			replace with appropriate dummy
-- TopHatPaladin code
function TabulateConservationAreas()
	-- print("  tabulateConservationAreas")
	print("consa: " .. consa .. ", consa2: " .. consa2 .. ", consa3: " .. consa3 .. ", consa4: " .. consa4)
	for i = 0, Map.GetNumPlots() - 1, 1 do
		local pPlot = Map.GetPlotByIndex(i)
		if isConservationArea(pPlot:GetImprovementType()) then
			print("  isConsa(" .. pPlot:GetImprovementType() .. ") = true")
			tImprovementPlots[pPlot] = true
		end
	end
end
Events.SequenceGameInitComplete.Add(TabulateConservationAreas)
function ConservationAreaBuilt(playerID, iX, iY, improvementType)
	local pPlot = Map.GetPlot(iX, iY)
	if isConservationArea(improvementType) then
		tImprovementPlots[pPlot] = true
	elseif tImprovementPlots[pPlot] then
		-- this check seems redundant, but it prevents you from losing the bonuses when you build a road on top of the improvement
		if not isConservationArea(pPlot:GetImprovementType()) then
			tImprovementPlots[pPlot] = false
		end
	end
end
GameEvents.BuildFinished.Add(ConservationAreaBuilt)
function ModifyConsAreaYields(playerID)
	local pPlayer = Players[playerID]
	if playerHasAnyConservationAreas(pPlayer) then
		for kPlot, v in pairs(tImprovementPlots) do
			if kPlot:GetOwner() == playerID and not kPlot:IsImprovementPillaged() then
				local ct = 0
				for iDirection = 0, iNumDirections, 1 do -- todo: use this code instead of PlotIterators for all adjacency
					local pAdjPlot = Map.PlotDirection(kPlot:GetX(), kPlot:GetY(), iDirection)
					if pAdjPlot ~= nil then ct = ct + plotValue(pAdjPlot) end				
				end
				if ct > 6 then -- requires at least one adjacent natural wonder
					kPlot:SetImprovementType(consa4)
				elseif ct > 4 then
					kPlot:SetImprovementType(consa3)
				elseif ct > 1 then
					kPlot:SetImprovementType(consa2)
				else 
					kPlot:SetImprovementType(consa)
				end
			end
		end
	end
end
GameEvents.PlayerDoTurn.Add(ModifyConsAreaYields)
-- end TopHatPaladin code
function plotValue(plot) -- TODO: DLL support properly checking if it's a natural wonder
	local t = plot:GetImprovementType()
	-- check if it's a natural wonder
	if t == -1 and plot:GetFeatureType() > iFeatureFallout then return nwValue end
	-- check if it's unimproved	
	if (((not plot:IsWater()) or (plot:IsWater() and plot:IsLake()))) and (t == -1 or isConservationArea(t)) then return 1 end
	return 0	
end
function isConservationArea(t)
	if (t == consa) or (t == consa2) or (t == consa3) or (t == consa4) then return true
	else return false end
end
function playerHasAnyConservationAreas(player)
	if player:GetImprovementCount(consa) > 0 then return true
	elseif player:GetImprovementCount(consa2) > 0 then return true
	elseif player:GetImprovementCount(consa3) > 0 then return true
	elseif player:GetImprovementCount(consa4) > 0 then return true
	else return false end
end