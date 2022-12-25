---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by maudlin27.
--- DateTime: 05/12/2022 21:39
---
local M28Profiler = import('/mods/M28AI/lua/AI/M28Profiler.lua')
local M28Utilities = import('/mods/M28AI/lua/AI/M28Utilities.lua')
local M28Orders = import('/mods/M28AI/lua/AI/M28Orders.lua')
local M28Overseer = import('/mods/M28AI/lua/AI/M28Overseer.lua')
local M28Engineer = import('/mods/M28AI/lua/AI/M28Engineer.lua')
local M28UnitInfo = import('/mods/M28AI/lua/AI/M28UnitInfo.lua')
local M28Map = import('/mods/M28AI/lua/AI/M28Map.lua')
local M28Land = import('/mods/M28AI/lua/AI/M28Land.lua')
local M28Economy = import('/mods/M28AI/lua/AI/M28Economy.lua')
local M28Team = import('/mods/M28AI/lua/AI/M28Team.lua')

function AreMobileLandUnitsInRect(rRectangleToSearch)
    --returns true if have mobile land units in rRectangleToSearch
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end

    local sFunctionRef = 'AreMobileUnitsInRect'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    local tBlockingUnits = GetUnitsInRect(rRectangleToSearch)
    if M28Utilities.IsTableEmpty(tBlockingUnits) then
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
        return false
    else
        for iUnit, oUnit in tBlockingUnits do
            if oUnit.UnitId and EntityCategoryContains(categories.MOBILE * categories.LAND, oUnit.UnitId) then
                M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
                return true
            end
        end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
    return false
end

function GetLifetimeBuildCount(aiBrain, category)
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'GetLifetimeBuildCount'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    local iTotalBuilt = 0
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local tUnitBPIDs = EntityCategoryGetUnitList(category)
    local oCurBlueprint
    local iCurCount

    if tUnitBPIDs == nil then
        M28Utilities.ErrorHandler('tUnitBPIDs is nil, so wont have built any')
        iTotalBuilt = 0
    else
        if bDebugMessages == true then LOG(sFunctionRef..': cycling through tUnitBPIDs') end
        for _, sBPID in tUnitBPIDs do
            oCurBlueprint = __blueprints[sBPID]
            iCurCount = aiBrain.M28LifetimeUnitCount[sBPID]
            if iCurCount == nil then iCurCount = 0 end
            if bDebugMessages == true then LOG(sFunctionRef..': sBPID='..sBPID..'; LifetimeCount='..iCurCount) end
            iTotalBuilt = iTotalBuilt + iCurCount
        end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
    return iTotalBuilt
end

function IsCivilianBrain(aiBrain)
    --Is this an AI brain?
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'IsCivilianBrain'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    if aiBrain.M28IsCivilian == nil then
        local bIsCivilian = false
        if bDebugMessages == true then
            LOG(sFunctionRef..': Brain index='..aiBrain:GetArmyIndex()..'; BrainType='..(aiBrain.BrainType or 'nil')..'; Personality='..ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality..'; reprs of brain='..reprs(aiBrain))
        end
        --Basic check that it appears to have the values we'd expect
        --if aiBrain.BrainType and aiBrain.Name then
        if aiBrain.BrainType == nil or aiBrain.BrainType == "AI" or string.find(aiBrain.BrainType, "AI") then
            if bDebugMessages == true then LOG('Dealing with an AI brain') end
            --Does it have no personality?
            if not(ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality) or ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality == "" then
                if bDebugMessages == true then LOG(sFunctionRef..': Index='..aiBrain:GetArmyIndex()..'; Has no AI personality so will treat as being a civilian brain unless nickname contains AI or AIX and doesnt contain civilian') end
                bIsCivilian = true
                if string.find(aiBrain.Nickname, '%(AI') and not(string.find(aiBrain.Nickname, "civilian")) then
                    if bDebugMessages == true then LOG(sFunctionRef..': AI nickanme suggests its an actual AI and the developer has forgotten to give it a personality') end
                    bIsCivilian = false
                end
            end
        end
        aiBrain.M28IsCivilian = bIsCivilian
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
    return aiBrain.M28IsCivilian
end

function GetLifetimeBuildCount(aiBrain, category)
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'GetLifetimeBuildCount'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    local iTotalBuilt = 0
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local tUnitBPIDs = EntityCategoryGetUnitList(category)
    local oCurBlueprint
    local iCurCount

    if tUnitBPIDs == nil then
        M28Utilities.ErrorHandler('tUnitBPIDs is nil, so wont have built any')
        iTotalBuilt = 0
    else
        if bDebugMessages == true then LOG(sFunctionRef..': cycling through tUnitBPIDs') end
        for _, sBPID in tUnitBPIDs do
            oCurBlueprint = __blueprints[sBPID]
            iCurCount = aiBrain.M28LifetimeUnitCount[sBPID]
            if iCurCount == nil then iCurCount = 0 end
            if bDebugMessages == true then LOG(sFunctionRef..': sBPID='..sBPID..'; LifetimeCount='..iCurCount) end
            iTotalBuilt = iTotalBuilt + iCurCount
        end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
    return iTotalBuilt
end

function IsEngineerAvailable(oEngineer)
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'IsEngineerAvailable'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    --if oEngineer.UnitId..M28UnitInfo.GetUnitLifetimeCount(oEngineer) == 'xsl010515' then bDebugMessages = true end

    if bDebugMessages == true then
        local iCurPlateau, iCurLZ = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oEngineer:GetPosition())
        LOG(sFunctionRef..': GameTIme '..GetGameTimeSeconds()..': Engineer '..oEngineer.UnitId..M28UnitInfo.GetUnitLifetimeCount(oEngineer)..' owned by '..oEngineer:GetAIBrain().Nickname..': oEngineer:GetFractionComplete()='..oEngineer:GetFractionComplete()..'; Unit state='..M28UnitInfo.GetUnitState(oEngineer)..'; Are last orders empty='..tostring(oEngineer[M28Orders.reftiLastOrders] == nil)..'; Engineer Plateau='..(iCurPlateau or 'nil')..'; LZ='..(iCurLZ or 'nil'))
    end
    if oEngineer:GetFractionComplete() == 1 and not(oEngineer:IsUnitState('Attached')) then
        M28Orders.UpdateRecordedOrders(oEngineer)
        if not(oEngineer[M28Orders.reftiLastOrders]) then
            --If last order is to move, then treat engineer as available
            if bDebugMessages == true then LOG(sFunctionRef..': Engineer has no last orders active so is available') end
            M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
            return true
        else
            --If engineer is moving but it doesnt have an assignment, or its assignment isnt to move, then make it available
            local iLastOrderType = oEngineer[M28Orders.reftiLastOrders][table.getn(oEngineer[M28Orders.reftiLastOrders])][M28Orders.subrefiOrderType]
            if bDebugMessages == true then LOG(sFunctionRef..': Engineer '..oEngineer.UnitId..M28UnitInfo.GetUnitLifetimeCount(oEngineer)..' owned by '..oEngineer:GetAIBrain().Nickname..' has a last order type of '..(iLastOrderType or 'nil')..'; and an action assigned of '..(oEngineer[M28Engineer.refiAssignedAction] or 'nil')..'; Order for this action='..(M28Engineer.tiActionOrder[oEngineer[M28Engineer.refiAssignedAction]] or 'nil')) end
            if iLastOrderType == M28Orders.refiOrderIssueMove then
                if oEngineer[M28Engineer.refiAssignedAction] and M28Engineer.tiActionOrder[oEngineer[M28Engineer.refiAssignedAction]] == iLastOrderType then
                    --Engineer not available, unless its order was to move to a land zone, in which case check if it is now in that land zone
                    if (oEngineer[M28Engineer.refiAssignedAction] == M28Engineer.refActionMoveToLandZone or oEngineer[M28Engineer.refiAssignedAction] == M28Engineer.refActionRunToLandZone) then
                        local iCurPlateau, iCurLZ = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oEngineer:GetPosition(), true)
                        if bDebugMessages == true then LOG(sFunctionRef..': Engineer has action to move to LZ, reftiPlateauAndLZToMoveTo='..reprs(oEngineer[M28Land.reftiPlateauAndLZToMoveTo])..'; Eng position iCurPlateau='..(iCurPlateau or 'nil')..'; iCurLZ='..(iCurLZ or 'nil')) end
                        if iCurPlateau == oEngineer[M28Land.reftiPlateauAndLZToMoveTo][1] and iCurLZ == oEngineer[M28Land.reftiPlateauAndLZToMoveTo][2] then
                            M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
                            return true
                        else
                            M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
                            return false
                        end
                    else
                        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
                        return false
                    end
                else
                    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
                    return true
                end
            else
                M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
                return false
            end
        end
    else
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
        return false
    end
end

function IsResourceBlockedByResourceBuilding(iResourceCategory, sResourceBlueprint, tResourceLocation)
    --True if there is a mex or hydro at the location - used since CanBuildStructureAt can return false if reclaim is on the resource location (but we can sitll build there)
    local rRectangleToSearch = M28Utilities.GetRectAroundLocation(tResourceLocation, M28UnitInfo.GetBuildingSize(sResourceBlueprint) * 0.5)
    local tUnitsInRect = GetUnitsInRect(rRectangleToSearch)
    if M28Utilities.IsTableEmpty(tUnitsInRect) == false then
        if M28Utilities.IsTableEmpty(EntityCategoryFilterDown(iResourceCategory, tUnitsInRect)) == false then
            --if sResourceBlueprint == 'ueb1102' then LOG('Have units in rectangle around tResourceLocation='..repru(tResourceLocation)) end
            return true
        end
    end
    return false
end

function CanBuildStorageAtLocation(tLocation)
    if M28Overseer.tAllActiveM28Brains[1]:CanBuildStructureAt('ueb1106', tLocation) == true then
        return true
    else
        return not(IsResourceBlockedByResourceBuilding(M28UnitInfo.refCategoryStructure, 'ueb1106', tLocation))
    end
end

function CanBuildOnMexLocation(tMexLocation)
    --True if can build on mex location; will return true if aiBrain result is true
    --Want to use a function in case t urns out reclaim on a mex means aibrain canbuild returns false
    if M28Overseer.tAllActiveM28Brains[1]:CanBuildStructureAt('urb1103', tMexLocation) == true then
        return true
    else
        return not(IsResourceBlockedByResourceBuilding(M28UnitInfo.refCategoryMex, 'urb1103', tMexLocation))
    end
end

function CanBuildOnHydroLocation(tHydroLocation)
    --True if can build on hydro; will return true if aiBrain result is true
    --Want to use a function in case t urns out reclaim on a hydro means aibrain canbuild returns false
    if M28Overseer.tAllActiveM28Brains[1]:CanBuildStructureAt('ueb1102', tHydroLocation) == true then
        return true
    else
        --local iPlateau, iLZ = M28Map.GetPlateauAndLandZoneReferenceFromPosition(tHydroLocation)
        --LOG('CanBuildOnHydroLocation: Considering for tHydroLocation='..repru(tHydroLocation)..' at iPlateau='..iPlateau..'; iLZ='..iLZ..'; IsResourceBlockedByResourceBuilding='..tostring(IsResourceBlockedByResourceBuilding(M28UnitInfo.refCategoryHydro, 'ueb1102', tHydroLocation)))
        return not(IsResourceBlockedByResourceBuilding(M28UnitInfo.refCategoryHydro, 'ueb1102', tHydroLocation))
    end
end

function IsUnitVisibleSEEBELOW()  end --To help with finding canseeunit
function CanSeeUnit(aiBrain, oUnit, bFalseIfOnlySeeBlip)
    --returns true if aiBrain can see oUnit
    --bFalseIfOnlySeeBlip - if true, then returns false if can see the blip but have never seen what the unit was for the blip; defaults to false
    local iUnitBrain = oUnit:GetAIBrain()
    if iUnitBrain == aiBrain then return true
    else
        local iArmyIndex = aiBrain:GetArmyIndex()
        if not(oUnit.Dead) then
            if not(oUnit.GetBlip) then
                --ErrorHandler('oUnit with UnitID='..(oUnit.UnitId or 'nil')..' has no blip, will assume can see it')
                return true
            else
                local oBlip = oUnit:GetBlip(iArmyIndex)
                if oBlip then
                    if bFalseIfOnlySeeBlip and not(oBlip:IsSeenEver(iArmyIndex)) then return false
                    else return true
                    end
                end
            end
        end
    end
    return false
end

function SafeToUpgradeUnit(oUnit)
    --Returns true if safe to upgrade oUnit:
    local iPlateau, iLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oUnit:GetPosition())
    if (iLandZone or 'nil') > 0 then
        if not(M28Map.tAllPlateaus[iPlateau][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZTeamData][oUnit:GetAIBrain().M28Team][M28Map.subrefbEnemiesInThisOrAdjacentLZ]) then
            return true
        end
    end
    return false

end

function HaveLowMass(aiBrain)
    --Not actually used as yet
    local bHaveLowMass = false
    if aiBrain[M28Economy.refiGrossMassBaseIncome] <= 200 then --i.e. we dont ahve a paragon or crazy amount of SACUs
        local iMassStoredRatio = aiBrain:GetEconomyStoredRatio('MASS')
        if (iMassStoredRatio <= 0.15 or aiBrain:GetEconomyStored('MASS') <= 300) then
            if aiBrain[M28Economy.refiNetMassBaseIncome] < 0.2 then bHaveLowMass = true
            elseif iMassStoredRatio <= 0.05 and aiBrain[M28Economy.refiNetMassBaseIncome] < aiBrain[M28Economy.refiGrossMassBaseIncome] * 0.05 then bHaveLowMass = true
            end
        end
    end
    return bHaveLowMass
end

function TeamHasLowMass(iTeam)
    local bHaveLowMass = false
    if M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossMass] <= 200 then --i.e. we dont ahve a paragon or crazy amount of SACUs
        local iMassStoredRatio = M28Team.tTeamData[iTeam][M28Team.subrefiTeamLowestMassPercentStored]

        if (iMassStoredRatio <= 0.15 or M28Team.tTeamData[iTeam][M28Team.subrefiTeamMassStored] <= 300 * M28Team.tTeamData[iTeam][M28Team.subrefiActiveM28BrainCount]) then
            if M28Team.tTeamData[M28Team.subrefiTeamNetMass] < 0.2 then bHaveLowMass = true
            elseif iMassStoredRatio <= 0.05 and M28Team.tTeamData[iTeam][M28Team.subrefiTeamNetMass] < M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossMass] * 0.05 then bHaveLowMass = true
            end
        end
    end
    return bHaveLowMass
end

function HaveLowPower(iTeam)
    if M28Team.tTeamData[iTeam][M28Team.subrefiTeamNetEnergy] < 0 or M28Team.tTeamData[iTeam][M28Team.subrefbTeamIsStallingEnergy] or M28Team.tTeamData[iTeam][M28Team.subrefiTeamLowestEnergyPercentStored] < 0.5 or (M28Team.tTeamData[iTeam][M28Team.subrefiTeamLowestMassPercentStored] >= 0.15 and M28Team.tTeamData[iTeam][M28Team.subrefbTooLittleEnergyForUpgrade]) or M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossEnergy] < M28Economy.tiMinEnergyPerTech[M28Team.tTeamData[iTeam][M28Team.subrefiHighestFriendlyFactoryTech]] then
        if not(M28Team.tTeamData[iTeam][M28Team.refbJustBuiltLotsOfPower]) then
            return true
        else return false
        end
    end
    return false
end

function WantMorePower(iTeam)
    local bWantMorePower = false
    if M28Team.tTeamData[iTeam][M28Team.refbJustBuiltLotsOfPower] then return false
    else
        if HaveLowPower(iTeam) then bWantMorePower = true
        else
            local iNetPowerWanted
            local iHighestTeamTech = M28Team.tTeamData[iTeam][M28Team.subrefiHighestFriendlyFactoryTech]
            if iHighestTeamTech >= 3 then
                iNetPowerWanted = math.max(50, M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossEnergy] * 0.2)
            elseif iHighestTeamTech == 2 then
                iNetPowerWanted = math.max(15, M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossEnergy] * 0.15)
            elseif M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossEnergy] >= 20 * M28Team.tTeamData[iTeam][M28Team.subrefiActiveM28BrainCount] then
                iNetPowerWanted = math.max(3, M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossEnergy] * 0.1)
            else
                iNetPowerWanted = 2
            end
            if M28Team.tTeamData[iTeam][M28Team.subrefiTeamNetEnergy] < iNetPowerWanted then
                bWantMorePower = true
            end
        end
    end
    return bWantMorePower
end

function WantToReclaimEnergyNotMass(iTeam, iPlateau, iLandZone)
    if M28Team.tTeamData[iTeam][M28Team.subrefiTeamLowestEnergyPercentStored] <= 0.7 and M28Team.tTeamData[iTeam][M28Team.subrefiTeamGrossEnergy] <= 80 and M28Map.tAllPlateaus[iPlateau][M28Map.subrefPlateauLandZones][iLandZone][M28Map.refReclaimTotalEnergy] >= 100 and M28Team.tTeamData[iTeam][M28Team.subrefiTeamNetEnergy] < 2 then
        return true
    end
    return false
end