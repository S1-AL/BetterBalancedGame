------------------------------------------------------------------------------
--	FILE:	 bbg_script.lua
--	AUTHOR:  D. / Jack The Narrator
--	PURPOSE: Gameplay script - Centralises all the calls for BBG
------------------------------------------------------------------------------

-- 4.00
-- Mechanics:
-- Condemn now does 100 dmg (affected by Religious Strength) to religious units
-- Condemn mechanics now also reduce loyalty (-15) in your nearby cities (6 range) if they have the majority religion of the condemned units
-- Remove Heresy lower loyalty by -20 in cities not with a majority religion different from the inquisitor
-- All Inquisitor characteristics reverted to base game
-- Moksha religious strength reverted to base game
-- Itenirant preacher reverted to base game
-- Policies:
-- Lime card reverted base game but still never obselete
-- 3 siege cards at Military Tradition, Medieval Faires and Scorched Earth can boost Siege Production
-- Fixed the bug on the Naval Cards with UU
-- Civ/Leaders:
-- Mother Russia trait no longer give faith on tundra, but +1 passive. Border expansion reverted to base game
-- Dynastic Cycle trait (China) now only grant +1f +1p per wonder
-- Ethiopia's trait now only grant +1f on improved resources
-- Toqui trait (Mapuche) no longer applied to attack from the city's walls
-- Catherine the magnificient project is now moved to Mediaval Faires
-- Catherine Black Queen +1 visibility moved to Political Philosophy
-- Dromon reverted to base game
-- Quadriemes range reverted to 1
-- Georgia faith reverted to 4
-- Crusader reverted to +5


--include "bbg_stateutils"
--include "bbg_unitcommands"

-- ===========================================================================
--	Constants
-- ===========================================================================
local iReligion_ScientificDecay = 0;
local iReligion_DecayTech = GameInfo.Technologies["TECH_SCIENTIFIC_THEORY"].Index
local iReligion_ByzantiumRange = 90; -- In tiles covered, 90 tiles covered = 5 tiles radius 
local iReligion_ByzantiumMultiplier = 5; -- multipler X unit base combat strength
local iDomination_level = 0.60;

local NO_TEAM :number = -1;
local NO_PLAYER :number = -1;
local NO_PLOT :number = -1;
local NO_UNIT :number = -1;
local NO_DISTRICT :number = -1;
local NO_IMPROVEMENT :number = -1;
local NO_BUILDING :number = -1;

-- ===========================================================================
--	Function
-- ===========================================================================

function OnGameTurnStarted( turn:number )
	print ("BBG TURN STARTING: " .. turn);
	Check_DominationVictory()
end

function OnCombatOccurred(attackerPlayerID :number, attackerUnitID :number, defenderPlayerID :number, defenderUnitID :number, attackerDistrictID :number, defenderDistrictID :number)
	if(attackerPlayerID == NO_PLAYER 
		or defenderPlayerID == NO_PLAYER) then
		return;
	end

	local pAttackerPlayer = Players[attackerPlayerID];
	local pAttackerReligion = pAttackerPlayer:GetReligion()
	local pAttackerLeader = PlayerConfigurations[attackerPlayerID]:GetLeaderTypeName()
	local pDefenderPlayer = Players[defenderPlayerID];
	local pAttackingUnit :object = attackerUnitID ~= NO_UNIT and pAttackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local pDefendingUnit :object = defenderUnitID ~= NO_UNIT and pDefenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
	local pAttackingDistrict :object = attackerDistrictID ~= NO_DISTRICT and pAttackerPlayer:GetDistricts():FindID(attackerDistrictID) or nil;
	local pDefendingDistrict :object = defenderDistrictID ~= NO_DISTRICT and pDefenderPlayer:GetDistricts():FindID(defenderDistrictID) or nil;
	
	-- Attacker died to defender.
	if(pAttackingUnit ~= nil and pDefendingUnit ~= nil and (pDefendingUnit:IsDead() or pDefendingUnit:IsDelayedDeath())) then
		if pAttackerLeader = "LEADER_BASIL" then
			local x = pAttackingUnit:GetX()
			local y = pAttackingUnit:GetY()
			local power = pDefendingUnit:GetCombat()
			local religionType = pAttackerReligion:GetReligionInMajorityOfCities()
			if x ~= nil and y ~= nil and power ~= nil and religionType ~= nil then
				ApplyByzantiumTrait(x,y,power,religionType,attackerPlayerID)
			end
		end
	end

end

-- ===========================================================================
--	Bizantium
-- ===========================================================================
function ApplyByzantiumTrait(x,y,power,religionType,playerID)
	if x == nil or y == nil or power == nil or religionType == nil then
		return
	end
	--local religionInfo = GameInfo.Religions[religionType]
	local pPlot = Map.GetPlot(x, y)
	for i = 1, iReligion_ByzantiumRange do
		local plotScanned = GetAdjacentTiles(pPlot, i)
		if plotScanned ~= nil then
			if plotScanned:IsCity() then
				local pCity = Cities.GetCityInPlot(plotScanned)
				local pCityReligion = pCity:GetReligion()
				local impact = power * iReligion_ByzantiumMultiplier
				pCityReligion:AddReligiousPressure(playerID, religionType,impact, -1);
				print("Added Religious Pressure",impact,pCity:GetName())
				local message:string  = "+"..tostring(impact)
				if religionInfo ~= nil then
					--message = message.."[ICON_" .. religionInfo.ReligionType .."]"
					message = message.." [ICON_Religion]"
					else
					message = message.." [ICON_Religion]"
				end
				Game.AddWorldViewText(0, message, pCity:GetX(), pCity:GetY());
			end
		end
	end
end
-- ===========================================================================
--	Sumer
-- ===========================================================================

function ApplyGilgameshTrait()
	local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
	local iStartIndex = 0
	if iStartEra ~= nil then
		iStartIndex = iStartEra.ChronologyIndex;
		else
		return
	end
	if iStartIndex ~= 1 then
		return
	end
	
	for _, iPlayerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local pPlayer = Players[iPlayerID]
		if pPlayer ~= nil then
			if PlayerConfigurations[iPlayerID]:GetLeaderTypeName() == "LEADER_GILGAMESH" then
				local playerUnits;
				playerUnits = Players[iPlayerID]:GetUnits();
				for k, unit in playerUnits:Members() do
					local unitTypeName = UnitManager.GetTypeName(unit)
					if "LOC_UNIT_WARRIOR_NAME" == unitTypeName then
						local unitX = unit:GetX()
						local unitY = unit:GetY()
						playerUnits:Destroy(unit)
						local iWarCart = GameInfo.Units["UNIT_SUMERIAN_WAR_CART"].Index
						playerUnits:Create(iWarCart, unitX, unitY)
					end
				end
			end
		end
	end	

end

-- ===========================================================================
--	Religion
-- ===========================================================================

function ApplyScientificTheory(iPlayerID:number)
	-- Remove Religious Pressure in Cities whose religions are not like the main religion
	local pPlayer = Players[iPlayerID]
	local pReligion = pPlayer:GetReligion()
	if pReligion == nil then
		return
	end
	local iMainReligion = pReligion:GetReligionInMajorityOfCities()
	local pPlayerCities = pPlayer:GetCities();
	for i, pCity in pPlayerCities:Members() do
		if pCity ~= nil then
			local pCityReligion = pCity:GetReligion()
			local iCityReligion = pCityReligion:GetMajorityReligion()
			if iCityReligion ~= iMainReligion then
				pCity:GetReligion():AddReligiousPressure(iPlayerID, iCityReligion, iReligion_ScientificDecay, -1);
				print("Reduced Religious Pressure in", pCity:GetName())
			end
		end
	end	
	
end

-- ===========================================================================
--	Domination
-- ===========================================================================

function Check_DominationVictory()
	local teamIDs = GetAliveMajorTeamIDs();
	local hasWon = false
	local victoryTeam = -99

	for _, teamID in ipairs(teamIDs) do
		if(teamID ~= nil) then
			--local progress = Game.GetVictoryProgressForTeam(victoryType, teamID);
			local progress = true
			if(progress ~= nil) then

				-- PlayerData
				local playerCount:number = 0;
				local teamGenericScore = 0;

				for i, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
					if Players[playerID]:GetTeam() == teamID then
						local pPlayer:table = Players[playerID];
						local genericScore = 0
						local land = 0
						for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
							local pPlot = Map.GetPlotByIndex(iPlotIndex)
							if (pPlot:IsWater() == false) then
								land = land + 1;
								if (pPlot:GetOwner() == playerID) then
									genericScore = genericScore + 1;
								end
							end
						end
						if land ~= 0 then
							genericScore = genericScore / land
							else
							genericScore = 0
						end
						teamGenericScore = teamGenericScore + genericScore
						if teamGenericScore > iDomination_level then
							hasWon = true
							victoryTeam = teamID
						end
						playerCount = playerCount + 1;
					end
				end
			end
		end
	end
	
	if hasWon == false or victoryTeam == -99 then
		return
	end

	for i, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if Players[playerID]:GetTeam() == victoryTeam then
			local pPlayer:table = Players[playerID];
			local pCapCity = Players[i]:GetCities():GetCapitalCity()
			if pCapCity ~= nil then
				-- Add Victory Flag
				print("Add Victory Flag",playerID)
			end
		end
	end	

end

-- ===========================================================================
--	Tools
-- ===========================================================================

function GetAliveMajorTeamIDs()
	print("GetAliveMajorTeamIDs()")
	local ti = 1;
	local result = {};
	local duplicate_team = {};
	for i,v in ipairs(PlayerManager.GetAliveMajors()) do
		local teamId = v:GetTeam();
		if(duplicate_team[teamId] == nil) then
			duplicate_team[teamId] = true;
			result[ti] = teamId;
			ti = ti + 1;
		end
	end

	return result;
end

-- ===========================================================================
--	Initialize
-- ===========================================================================

function Initialize()

	print("BBG - Gameplay Script Launched")
	local currentTurn = Game.GetCurrentGameTurn()
	local startTurn = GameConfiguration.GetStartTurn()
	
	
	-- turn 0 effects:
	if currentTurn == startTurn then
		ApplyGilgameshTrait()
	end
	
	-- turn checked effects:
	GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted);

	-- combat effect:
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
end

Initialize();