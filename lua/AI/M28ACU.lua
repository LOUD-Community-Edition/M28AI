---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by maudlin27.
--- DateTime: 02/12/2022 08:29
---
local M28Utilities = import('/mods/M28AI/lua/AI/M28Utilities.lua')
local M28UnitInfo = import('/mods/M28AI/lua/AI/M28UnitInfo.lua')
local M28Economy = import('/mods/M28AI/lua/AI/M28Economy.lua')
local M28Map = import('/mods/M28AI/lua/AI/M28Map.lua')
local M28Orders = import('/mods/M28AI/lua/AI/M28Orders.lua')
local M28Profiler = import('/mods/M28AI/lua/AI/M28Profiler.lua')
local M28Engineer = import('/mods/M28AI/lua/AI/M28Engineer.lua')
local M28Team = import('/mods/M28AI/lua/AI/M28Team.lua')


--ACU specific variables against the ACU
refbDoingInitialBuildOrder = 'M28ACUInitialBO'

function ACUBuildUnit(aiBrain, oACU, iCategoryToBuild, iMaxAreaToSearch, iOptionalAdjacencyCategory, iOptionalCategoryBuiltUnitCanBuild)
    local sFunctionRef = 'ACUBuildUnit'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    
    --Do we have a nearby unit of the type we want to build under construction?
    local tNearbyUnitsOfCategoryToBuild = aiBrain:GetUnitsAroundPoint(iCategoryToBuild, oACU:GetPosition(), iMaxAreaToSearch, 'Ally')
    local oNearestPartComplete
    if M28Utilities.IsTableEmpty(tNearbyUnitsOfCategoryToBuild) == false then
        local iClosestUnit = 10000
        local iCurDist
        for _, oUnit in tNearbyUnitsOfCategoryToBuild do
            if oUnit:GetFractionComplete() < 1 then
                iCurDist = M28Utilities.GetTravelDistanceBetweenPositions(oUnit:GetPosition(), oACU:GetPosition(), M28Map.refPathingTypeLand)
                if iCurDist < iClosestUnit then
                    oNearestPartComplete = oUnit
                    iClosestUnit = iCurDist
                end
            end
        end
    end
    if oNearestPartComplete then
        if bDebugMessages == true then LOG(sFunctionRef..': Will assist part complete building='..oNearestPartComplete.UnitId..M28UnitInfo.GetUnitLifetimeCount(oNearestPartComplete)) end
        M28Orders.IssueTrackedGuard(oACU, oNearestPartComplete, false)
    else
        --No nearby under construction factory, so build one
        --GetBlueprintAndLocationToBuild(aiBrain, oEngineer, iCategoryToBuild, iMaxAreaToSearch, iCatToBuildBy,         tAlternativePositionToLookFrom, bLookForQueuedBuildings, oUnitToBuildBy, iOptionalCategoryForStructureToBuild, bBuildCheapestStructure)
        local sBlueprint, tBuildLocation = M28Engineer.GetBlueprintAndLocationToBuild(aiBrain, oACU, iCategoryToBuild, iMaxAreaToSearch, iOptionalAdjacencyCategory, nil,                           false,                      nil,         iOptionalCategoryBuiltUnitCanBuild, nil)
        if bDebugMessages == true then
            local iPlateau, iLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oACU:GetPosition())
            LOG(sFunctionRef..': Blueprint to build='..(sBlueprint or 'nil')..'; tBuildLocation='..repru(tBuildLocation)..'; ACU plateau and land zone based on cur position='..iPlateau..'; iLandZone='..(iLandZone or 'nil'))
        end
        if sBlueprint and tBuildLocation then
            --Move to the target and then build on it
            local tMoveTarget = M28Engineer.GetLocationToMoveForConstruction(oACU, tBuildLocation, sBlueprint)
            if tMoveTarget then
                --IssueTrackedMoveAndBuild(oUnit, tBuildLocation, sOrderBlueprint, tMoveTarget, iDistanceToReorderMoveTarget, bAddToExistingQueue)
                M28Orders.IssueTrackedMoveAndBuild(oACU, tBuildLocation, sBlueprint, tMoveTarget, 2, false)
            else
                M28Orders.IssueTrackedBuild(oACU, tBuildLocation, sBlueprint, false)
            end
        else
            M28Orders.UpdateRecordedOrders(oACU)
        end
    end

    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function ACUActionBuildFactory(aiBrain, oACU)
    local sFunctionRef = 'ACUActionBuildFactory'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    local iMaxAreaToSearch = 35
    local iCategoryToBuild = M28UnitInfo.refCategoryLandFactory
    if aiBrain:GetCurrentUnits(M28UnitInfo.refCategoryFactory) >= 2 and iCategoryToBuild == M28UnitInfo.refCategoryLandFactory then
        iMaxAreaToSearch = 20
    end
    ACUBuildUnit(aiBrain, oACU, iCategoryToBuild, iMaxAreaToSearch, M28UnitInfo.refCategoryMex, M28UnitInfo.refCategoryEngineer)

    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function ACUActionAssistHydro(aiBrain, oACU)
    --If have hydro under construction then assist the hydro if it's within build range; if not under construciton or out of build range then move towards it
    local sFunctionRef = 'ACUActionAssistHydro'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    --Redundancy - make sure we have hydros in this LZ:
    local iPlateauGroup, iLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oACU:GetPosition())
    if bDebugMessages == true then LOG(sFunctionRef..': Do we have hydro loations in iPlateauGroup '..iPlateauGroup..'; iLZ='..iLandZone..': Table empty='..tostring(M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZHydroLocations]))) end
    if M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZHydroLocations]) == false then
        local tNearestHydro
        local iNearestHydro = 10000
        local iCurDist
        local iBuildRange = oACU:GetBlueprint().Economy.MaxBuildDistance
        local iMinRangeToAssist = iBuildRange + 3
        for iHydro, tHydro in M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZHydroLocations] do
            iCurDist = M28Utilities.GetDistanceBetweenPositions(tHydro, oACU:GetPosition())
            if iCurDist < iNearestHydro then iNearestHydro = iCurDist tNearestHydro = tHydro end
        end
        --If we are in range of a hydro then assist it (or wait until construction is started)
        if iNearestHydro < iMinRangeToAssist then
            local tUnderConstructionHydro = aiBrain:GetUnitsAroundPoint(M28UnitInfo.refCategoryHydro, tNearestHydro, 5, 'Ally')
            local oUnderConstructionHydro
            if M28Utilities.IsTableEmpty(tUnderConstructionHydro) == false then
                for iHydro, oHydro in tUnderConstructionHydro do
                    if oHydro:GetFractionComplete() < 1 then
                        oUnderConstructionHydro = oHydro
                        break
                    end
                end
            end
            if oUnderConstructionHydro then
                M28Orders.IssueTrackedRepair(oACU, oUnderConstructionHydro, false)
            else
                oACU['M28BOHydroWait'] = ( oACU['M28BOHydroWait'] or 0) + 1
                if  oACU['M28BOHydroWait'] >= 20 then
                    ACUActionBuildPower(aiBrain, oACU)
                else
                    --Stay where we are as maybe we are waiting for an engi to start construction
                    M28Orders.IssueTrackedMove(oACU, oACU:GetPosition(), 3, false)
                end
            end
        else
            --Move to be near hydro
            local tLocationNearHydro = M28Engineer.GetLocationToMoveForConstruction(oACU, tNearestHydro, 'ueb1102', -0.5, false)
            if tLocationNearHydro then
                M28Orders.IssueTrackedMove(oACU, tLocationNearHydro, 3, false)
            else
                M28Orders.IssueTrackedMove(oACU, tNearestHydro, 3, false)
            end
        end
    else
        M28Utilities.ErrorHandler('Trying to buidl hydro when none nearby')
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function ACUActionBuildPower(aiBrain, oACU)
    local sFunctionRef = 'ACUActionBuildPower'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    local iCategoryToBuild = M28UnitInfo.refCategoryPower
    local iMaxAreaToSearch = 16
    local iOptionalAdjacencyCategory
    if aiBrain:GetCurrentUnits(M28UnitInfo.refCategoryAirFactory) > 0 then iOptionalAdjacencyCategory = M28UnitInfo.refCategoryAirFactory
    elseif aiBrain[M28Economy.refiGrossEnergyBaseIncome] <= 11 then iOptionalAdjacencyCategory = M28UnitInfo.refCategoryLandFactory
    end
    if bDebugMessages == true then LOG(sFunctionRef..': About to tell ACU to build power; is optional adjacency category nil='..tostring(iOptionalAdjacencyCategory == nil)) end
    ACUBuildUnit(aiBrain, oACU, iCategoryToBuild, iMaxAreaToSearch, iOptionalAdjacencyCategory, nil)

    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function ACUActionBuildMex(aiBrain, oACU)
    local sFunctionRef = 'ACUActionBuildMex'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    local iMaxAreaToSearch = 16
    --Increase search range if still doing initial build order, as this suggests we have mexes in our initial land zone that we havent built on yet
    if oACU[refbDoingInitialBuildOrder] then
        if aiBrain[M28Economy.refiGrossEnergyBaseIncome] >= 12 then iMaxAreaToSearch = 50
        elseif aiBrain[M28Economy.refiGrossMassBaseIncome] < 6 then iMaxAreaToSearch = 30
        end
    end

    if bDebugMessages == true then LOG(sFunctionRef..': About to tell ACU to build a mex, iMaxAreaToSearch='..iMaxAreaToSearch) end
    ACUBuildUnit(aiBrain, oACU, M28UnitInfo.refCategoryMex, iMaxAreaToSearch, nil, nil)

    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function GetACUEarlyGameOrders(aiBrain, oACU)
    local sFunctionRef = 'GetACUEarlyGameOrders'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    --Are we already building something?
    if bDebugMessages == true then LOG(sFunctionRef..': ACU unit state='..M28UnitInfo.GetUnitState(oACU)) end
    if not(oACU:IsUnitState('Building')) then
        local iPlateauGroup, iLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oACU:GetPosition())


        --Do we want to build a mex, hydro or factory?
        if bDebugMessages == true then LOG(sFunctionRef..': Current land factories='..aiBrain:GetCurrentUnits(M28UnitInfo.refCategoryLandFactory)..'; Gross energy income='..aiBrain[M28Economy.refiGrossEnergyBaseIncome]..'; Gross mass income='..aiBrain[M28Economy.refiGrossMassBaseIncome]) end
        local iMinEnergyPerTickWanted = 14 --i.e. 6 T1 PGens given ACU gives 2 E
        local iCurLandFactories = aiBrain:GetCurrentUnits(M28UnitInfo.refCategoryLandFactory)
        if iCurLandFactories == 0 then
            if bDebugMessages == true then LOG(sFunctionRef..': Want ACU to build land factory') end
            ACUActionBuildFactory(aiBrain, oACU)
        elseif aiBrain[M28Economy.refiGrossEnergyBaseIncome] <= iMinEnergyPerTickWanted then

            --Do we want to build a hydro (so get mexes first then hydro) or build pgen?

            if bDebugMessages == true then LOG(sFunctionRef..': Will adjust build order depending on if have hydro nearby. Is table of land zone hydros empty='..tostring(M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZHydroLocations]))) end
            if M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZHydroLocations]) then
                --Per discord gameplay and training pinned build order for going land facs with no hydro:
                --ACU:      Landfac - 2 PG - 2 Mex - 1 PG - 2 Mex - 3 PG - Landfac - PG - Landfac
                if bDebugMessages == true then LOG(sFunctionRef..': No hydro locations so will build power or mex depending on income') end
                if aiBrain[M28Economy.refiGrossEnergyBaseIncome] < 6 then
                    if bDebugMessages == true then LOG(sFunctionRef..': Want to build initial PGens') end
                    ACUActionBuildPower(aiBrain, oACU)
                else
                    local iMexInLandZone = 0
                    if M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZMexLocations]) == false then iMexInLandZone = table.getn(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZMexLocations]) end
                    if aiBrain[M28Economy.refiGrossMassBaseIncome] < math.min(2, iMexInLandZone) * 0.2 then
                        ACUActionBuildMex(aiBrain, oACU)

                    elseif aiBrain[M28Economy.refiGrossEnergyBaseIncome] < 8 then
                        ACUActionBuildPower(aiBrain, oACU)
                    elseif aiBrain[M28Economy.refiGrossMassBaseIncome] < math.min(4, iMexInLandZone) * 0.2 then
                        ACUActionBuildMex(aiBrain, oACU)
                    elseif aiBrain[M28Economy.refiGrossEnergyBaseIncome] < iMinEnergyPerTickWanted then
                        ACUActionBuildPower(aiBrain, oACU)
                    elseif iCurLandFactories < 1 then
                        ACUActionBuildFactory(aiBrain, oACU)
                    elseif aiBrain[M28Economy.refiGrossMassBaseIncome] < iMexInLandZone * 0.2 then
                        ACUActionBuildMex(aiBrain, oACU)
                    else
                        --No more actions so abort initial BO
                        oACU[refbDoingInitialBuildOrder] = false
                    end
                end

                --Redundancy if failed to get orer from the above
                if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) and oACU[refbDoingInitialBuildOrder] then
                    --No hydro nearby - try building power; then try building mex; then cancel initial build order
                    ACUActionBuildMex(aiBrain, oACU)
                    if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) then
                        ACUActionBuildPower(aiBrain, oACU)
                        if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) then
                            oACU[refbDoingInitialBuildOrder] = false
                        end
                    end
                end
            else --Have a hydro so get more mexes initially
                --Max mex to build
                local iMexInLandZone = 0
                if M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZMexLocations]) == false then iMexInLandZone = table.getn(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZMexLocations]) end
                if bDebugMessages == true then LOG(sFunctionRef..': Hydro is nearby, Gross mass income='..aiBrain[M28Economy.refiGrossMassBaseIncome]..'; iMexInLandZone='..iMexInLandZone..'; Gross base energy income='..aiBrain[M28Economy.refiGrossEnergyBaseIncome]) end
                if aiBrain[M28Economy.refiGrossMassBaseIncome] < math.min(4, iMexInLandZone) * 0.2 then
                    if bDebugMessages == true then LOG(sFunctionRef..': We ahve mexes in land zone and we havent built on all of them so will build a mex') end
                    ACUActionBuildMex(aiBrain, oACU)
                elseif aiBrain[M28Economy.refiGrossEnergyBaseIncome] < 10 then
                    if bDebugMessages == true then LOG(sFunctionRef..': Will try to assist a hydro nearby') end
                    ACUActionAssistHydro(aiBrain, oACU)
                else
                    --Have base level of power suggesting already have hydro
                    ACUActionBuildPower(aiBrain, oACU)
                end

                --Redundancy if fail to get order from above
                if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) and oACU[refbDoingInitialBuildOrder] then
                    --Is it just that we want to assist a hydro and engineers havent started one yet? If so then check if we have an engineer assigned to build one, and check the game time
                    if GetGameTimeSeconds() <= 180 and aiBrain[M28Economy.refiGrossEnergyBaseIncome] < 10 and M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZHydroLocations]) == false then
                        ACUActionAssistHydro(aiBrain, oACU)
                        if bDebugMessages == true then LOG(sFunctionRef..': Assuming we are waiting for an engi to start on building a hydro, or we have no nearby mexes to our ACU') end
                    else
                        --No hydro nearby - try building power; then try building mex; then cancel initial build order
                        ACUActionBuildMex(aiBrain, oACU)
                        if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) then
                            ACUActionAssistHydro(aiBrain, oACU)
                            if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) then
                                ACUActionBuildPower(aiBrain, oACU)
                                if M28Utilities.IsTableEmpty(oACU[M28Orders.reftiLastOrders]) then
                                    oACU[refbDoingInitialBuildOrder] = false
                                end
                            end
                        end
                    end
                end
            end
        else
            --Have initial power and mexes built, get second factory now
            if iCurLandFactories < 2 then
                ACUActionBuildFactory(aiBrain, oACU)
            else
                local iMexInLandZone = 0
                if M28Utilities.IsTableEmpty(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZMexLocations]) == false then iMexInLandZone = table.getn(M28Map.tAllPlateaus[iPlateauGroup][M28Map.subrefPlateauLandZones][iLandZone][M28Map.subrefLZMexLocations]) end
                if aiBrain[M28Economy.refiGrossMassBaseIncome] < iMexInLandZone * 0.2 then
                    ACUActionBuildMex(aiBrain, oACU)
                else
                    --Finish the initial BO
                    oACU[refbDoingInitialBuildOrder] = false
                end
            end
        end
    else
        if bDebugMessages == true then LOG(sFunctionRef..': Are building so wont give any new orders') end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function GetACUOrder(aiBrain, oACU)
    --Early game - do we want to build factory/power?
    local sFunctionRef = 'GetACUOrder'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)

    if bDebugMessages == true then LOG(sFunctionRef..': oACU[refbDoingInitialBuildOrder]='..tostring(oACU[refbDoingInitialBuildOrder])) end

    if oACU[refbDoingInitialBuildOrder] then
        GetACUEarlyGameOrders(aiBrain, oACU)

        --Have we finished our initial build order? (even if we stil lahve some early game orders)
        if bDebugMessages == true then LOG(sFunctionRef..': Checking if have finished initial build order, Economy stored mass='..aiBrain:GetEconomyStored('MASS')..'; Gross mass income='..aiBrain[M28Economy.refiGrossMassBaseIncome]..'; Gross energy income='..aiBrain[M28Economy.refiGrossEnergyBaseIncome]) end
        if not(oACU:IsUnitState('Building')) and aiBrain:GetEconomyStored('MASS') == 0 and aiBrain[M28Economy.refiGrossMassBaseIncome] >= 0.3 and aiBrain[M28Economy.refiGrossEnergyBaseIncome] >= 15 then
            bDoingInitialBuildOrder = false
        end
    else
        --Placeholder - assist nearest factory
        if bDebugMessages == true then LOG(sFunctionRef..': ACU no longer doing iniitial BO; Will give backup assist factory order if not building or guarding, ACU unit state='..M28UnitInfo.GetUnitState(oACU)) end
        if not(oACU:IsUnitState('Building')) and not(oACU:IsUnitState('Guarding')) then
            local oNearestFactory = M28Utilities.GetNearestUnit(aiBrain:GetListOfUnits(M28UnitInfo.refCategoryFactory, false, true), oACU:GetPosition(), true, M28Map.refPathingTypeAmphibious)
            if M28UnitInfo.IsUnitValid(oNearestFactory) then
                M28Orders.IssueTrackedGuard(oACU, oNearestFactory, false)
            end
        end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function ManageACU(aiBrain)
    local sFunctionRef = 'ManageACU'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    --First get our ACU
    local oACU
    while not(oACU) do
        local tOurACU = aiBrain:GetListOfUnits(categories.COMMAND, false, true)
        if M28Utilities.IsTableEmpty(tOurACU) == false then
            for _, oUnit in tOurACU do
                oACU = oUnit
                break
            end
        end
        if bDebugMessages == true then LOG(sFunctionRef..': Looking for ACU that we own, is oACU valid='..tostring(M28UnitInfo.IsUnitValid(oACU))) end
        if oACU then
            oACU[refbDoingInitialBuildOrder] = true
            break
        end
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
        WaitTicks(1)
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    end

    --Wait until ok for us to give orders
    while (GetGameTimeSeconds() <= 4.5) do
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
        WaitTicks(1)
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    end

    --Make sure ACU is recorded
    M28Team.AssignUnitToZoneOrPond(aiBrain, oACU)

    while M28UnitInfo.IsUnitValid(oACU) do
        GetACUOrder(aiBrain, oACU)
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
        WaitSeconds(1)
        M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    end
end