---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by maudlin27.
--- DateTime: 09/12/2022 07:49
---
local M28UnitInfo = import('/mods/M28AI/lua/AI/M28UnitInfo.lua')
local M28Utilities = import('/mods/M28AI/lua/AI/M28Utilities.lua')
local M28Map = import('/mods/M28AI/lua/AI/M28Map.lua')
local NavUtils = import("/lua/sim/navutils.lua")
local M28Profiler = import('/mods/M28AI/lua/AI/M28Profiler.lua')
local M28Conditions = import('/mods/M28AI/lua/AI/M28Conditions.lua')
local M28Overseer = import('/mods/M28AI/lua/AI/M28Overseer.lua')
local M28Team = import('/mods/M28AI/lua/AI/M28Team.lua')

tLZRefreshCountByTeam = {}

function UpdateUnitPositionsAndLandZone(aiBrain, tUnits, iTeam, iRecordedPlateau, iRecordedLandZone, bUseLastKnownPosition)
    --Based on RemoveEntriesFromArrayAndAddToNewTableBasedOnCondition, but more complex as dont always want to add unit to a table
    local iRevisedIndex = 1
    local iTableSize = table.getn(tUnits)
    local iActualPlateau, iActualLandZone
    local UpdateUnitLastKnownPosition = M28Team.UpdateUnitLastKnownPosition

    for iOrigIndex=1, iTableSize do
        if tUnits[iOrigIndex].Dead then
            --Remove the entry
            tUnits[iOrigIndex] = nil
        else
            --Unit still valid, does it have the right plateau and land zone?
            if bUseLastKnownPosition then
                UpdateUnitLastKnownPosition(aiBrain, tUnits[iOrigIndex], false)
                iActualPlateau, iActualLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(tUnits[iOrigIndex][M28UnitInfo.reftLastKnownPositionByTeam][iTeam])
            else
                --Allied unit so can use actual position
                iActualPlateau, iActualLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(tUnits[iOrigIndex]:GetPosition())
            end

            --Is the plateau and zone correct?
            if iRecordedPlateau == iActualPlateau and iRecordedLandZone == iActualLandZone then
                --No change needed for unit
                if (iOrigIndex ~= iRevisedIndex) then
                    tUnits[iRevisedIndex] = tUnits[iOrigIndex]
                    tUnits[iOrigIndex] = nil
                end
                iRevisedIndex = iRevisedIndex + 1
            else
                local oUnitToAdd = tUnits[iOrigIndex]
                --Want to remove the entry from this table, but then add it to the correct table
                oUnitToAdd[M28UnitInfo.reftAssignedPlateauAndLandZoneByTeam][iTeam] = nil --Done here so we dont try and go through this table again when removing later on
                if iActualPlateau > 0 and iActualLandZone > 0 then
                    M28Land.AddUnitToLandZoneForBrain(aiBrain, oUnitToAdd, iActualPlateau, iActualLandZone)
                else
                    --Not sure where to record unit so call main logic
                    M28Team.AssignUnitToZoneOrPond(aiBrain, oUnitToAdd, true)
                end
                tUnits[iOrigIndex] = nil
            end
        end

    end
end

function RefreshAllLandZoneUnits(aiBrain, iTeam)
    local bDebugMessages = true if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'RefreshAllLandZoneUnits'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    local iLastRefreshCount = (tLZRefreshCountByTeam[iTeam] or 1)
    local iCurRefreshCount = 0
    local iTicksToSpreadOver = 10
    local iRefreshThreshold = math.max(2, math.ceil(iLastRefreshCount * 0.95 / iTicksToSpreadOver))
    local iCurCycleRefreshCount = 0
    local iCurTicksWaited = 0

    local function WantToKeepUnitInTable(tArray, iEntry)
        if tArray[iEntry].Dead then
            return false
        else return true
        end
    end

    if bDebugMessages == true then
        LOG(sFunctionRef..': Start of code, Time='..GetGameTimeSeconds()..'; If have an ACU will list its plateau and land zone')
        local tOurACU = aiBrain:GetListOfUnits(categories.COMMAND, false, true)
        if M28Utilities.IsTableEmpty(tOurACU) == false then
            local iACUPlateau, iACULZ = M28Map.GetPlateauAndLandZoneReferenceFromPosition(tOurACU[1]:GetPosition())
            LOG(sFunctionRef..': ACU is at plateau '..iACUPlateau..'; LZ='..iACULZ)
        end
        LOG(sFunctionRef..': Is plateau 12 LZ 2 empty of allies for team 2='..tostring(M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[12][M28Map.subrefPlateauLandZones][2][M28Map.subrefLZTeamData][2][M28Map.subrefLZTAlliedUnits])))
    end


    --Cycle through land zones
    for iPlateau, tPlateauData in M28Map.tAllPlateaus do
        if M28Utilities.IsTableEmpty(tPlateauData[M28Map.subrefPlateauLandZones]) == false then
            if bDebugMessages == true then
                LOG(sFunctionRef..': About to cycle through every land zone in plateau '..iPlateau..'; subrefLandZoneCount='..tPlateauData[M28Map.subrefLandZoneCount])
                LOG(sFunctionRef..': Is plateau 12 LZ 2 empty of allies for team 2='..tostring(M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[12][M28Map.subrefPlateauLandZones][2][M28Map.subrefLZTeamData][2][M28Map.subrefLZTAlliedUnits])))
            end
            for iLandZone, tLandZoneDataByTeam in tPlateauData[M28Map.subrefPlateauLandZones] do
                local tLZData = tLandZoneDataByTeam[M28Map.subrefLZTeamData][iTeam]
                if bDebugMessages == true then
                    LOG(sFunctionRef..': iPlateau='..iPlateau..'; iLandZone='..iLandZone..'; Is table of enemey units empty='..tostring(M28Utilities.IsTableEmpty(tLZData[M28Map.subrefLZTEnemyUnits]))..'; Is table of friendly units empty='..tostring(M28Utilities.IsTableEmpty(tLZData[M28Map.subrefLZTAlliedUnits])))
                    if iPlateau == 12 and iLandZone == 2 then LOG(sFunctionRef..': Will do reprs of tLZData='..reprs(tLZData)..'; reprs of same table via full ref='..reprs(M28Map.tAllPlateaus[iPlateau][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZTeamData][iTeam])..'; Is table empty for team '..aiBrain.M28Team..' doing full ref='..tostring(M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateau][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZTeamData][aiBrain.M28Team][M28Map.subrefLZTAlliedUnits]))) end
                end
                --First check all units in here are alive
                if M28Utilities.IsTableEmpty(tLZData[M28Map.subrefLZTEnemyUnits]) == false then
                    iCurCycleRefreshCount = iCurCycleRefreshCount + 1
                    UpdateUnitPositionsAndLandZone(aiBrain, tLZData[M28Map.subrefLZTEnemyUnits], iTeam, iPlateau, iLandZone, true)
                end
                if M28Utilities.IsTableEmpty(tLZData[M28Map.subrefLZTAlliedUnits]) == false then
                    iCurCycleRefreshCount = iCurCycleRefreshCount + 1
                    UpdateUnitPositionsAndLandZone(aiBrain, tLZData[M28Map.subrefLZTAlliedUnits], iTeam, iPlateau, iLandZone, false)
                end

                if iCurCycleRefreshCount >= iRefreshThreshold then
                    iCurRefreshCount = iCurRefreshCount + iCurCycleRefreshCount
                    iCurCycleRefreshCount = 0
                    if iCurTicksWaited < iTicksToSpreadOver then
                        WaitTicks(1)
                        iCurTicksWaited = iCurTicksWaited + 1
                    end
                end
            end
        else
            if bDebugMessages == true then LOG(sFunctionRef..': Warning - no land zones found for plateau '..iPlateau) end
        end
    end
    iCurRefreshCount = iCurRefreshCount + iCurCycleRefreshCount
    tLZRefreshCountByTeam[iTeam] = iCurRefreshCount

    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function LandZoneOverseer(iTeam)
    --Periodically cycles through every land zone and refreshes the unit details
    local bDebugMessages = true if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'LandZoneOverseer'
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)


    local aiBrain
    function GetFirstActiveBrain(iTeam)
        for iBrain, oBrain in M28Team.tTeamData[iTeam][M28Team.subreftoFriendlyActiveM28Brains] do
            if not(oBrain.M28IsDefeated) then
                return oBrain
            end
        end
    end
    aiBrain = GetFirstActiveBrain(iTeam)

    if bDebugMessages == true then LOG(sFunctionRef..': About to start the main loop for land zones provided we have friendly M28 brains in the team '..iTeam..'; is table empty='..tostring(M28Utilities.IsTableEmpty(M28Team.tTeamData[iTeam][M28Team.subreftoFriendlyActiveM28Brains]))) end

    while M28Utilities.IsTableEmpty(M28Team.tTeamData[iTeam][M28Team.subreftoFriendlyActiveM28Brains]) == false do
        if bDebugMessages == true then LOG(sFunctionRef..': Will call logic to refresh every unit in a land zone') end
        ForkThread(RefreshAllLandZoneUnits, aiBrain, iTeam)

        WaitSeconds(1)
        if aiBrain.M28IsDefeated and M28Utilities.IsTableEmpty(M28Team.tTeamData[iTeam][M28Team.subreftoFriendlyActiveM28Brains]) == false then
            aiBrain = GetFirstActiveBrain(iTeam)
        end
        if bDebugMessages == true then LOG(sFunctionRef..': About to restart the loop for team '..iTeam..'; aiBrain referred to='..(aiBrain.Nickname or 'nil')..'; Is table of active m28 brains='..tostring(M28Utilities.IsTableEmpty(M28Team.tTeamData[iTeam][M28Team.subreftoFriendlyActiveM28Brains]))) end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end