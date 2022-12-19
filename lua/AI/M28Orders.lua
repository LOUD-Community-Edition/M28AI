---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by maudlin27.
--- DateTime: 30/11/2022 22:36
---

--LOCAL FILE DECLARATIONS - Do after the below global ones as for m28engineer it refers to some of these global variables

--Order info
reftiLastOrders = 'M28OrdersLastOrders' --Against unit, table first of the order number (1 = first order given, 2 = 2nd etc., qhere they were queued), which returns a table containing all the details of the order (including the order type per the below reference integers)

--Subtables for each order:
subrefiOrderType = 1
subreftOrderPosition = 2
subrefoOrderTarget = 3
subrefsOrderBlueprint = 4

--Order type references
refiOrderIssueMove = 1
refiOrderIssueFormMove = 2
refiOrderIssueAttack = 3
refiOrderIssueAggressiveMove = 4
refiOrderIssueAggressiveFormMove = 5
refiOrderIssueReclaim = 6
refiOrderIssueGuard = 7
refiOrderIssueRepair = 8
refiOrderIssueBuild = 9
refiOrderOvercharge = 10
refiOrderUpgrade = 11
refiOrderTransportLoad = 12
refiOrderIssueGroundAttack = 13
refiOrderIssueFactoryBuild = 14

--Other tracking: Against units
toUnitsOrderedToRepairThis = 'M28OrderRepairing' --Table of units given an order to repair the unit

local M28Utilities = import('/mods/M28AI/lua/AI/M28Utilities.lua')
local M28UnitInfo = import('/mods/M28AI/lua/AI/M28UnitInfo.lua')
local M28Engineer = import('/mods/M28AI/lua/AI/M28Engineer.lua')
local M28Config = import('/mods/M28AI/lua/M28Config.lua')
local M28Map = import('/mods/M28AI/lua/AI/M28Map.lua')


function UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc)
    local sBaseOrder = 'Clear'
    if oUnit[reftiLastOrders] then
        sBaseOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])][subrefiOrderType]
    end
    local sExtraOrder = ''
    if sOptionalOrderDesc then sExtraOrder = ' '..sOptionalOrderDesc end
    local sPlateauAndZoneDesc = ''
    if EntityCategoryContains(categories.LAND + categories.NAVAL, oUnit.UnitId) then
        local iPlateauGroup, iLandZone = M28Map.GetPlateauAndLandZoneReferenceFromPosition(oUnit:GetPosition())
        sPlateauAndZoneDesc = ':P='..iPlateauGroup..'LZ='..(iLandZone or 0)
    end
    oUnit:SetCustomName(oUnit.UnitId..M28UnitInfo.GetUnitLifetimeCount(oUnit)..sPlateauAndZoneDesc..':'..sBaseOrder..sExtraOrder)
end

function IssueTrackedClearCommands(oUnit)
    --Update tracking for repairing units:
    if oUnit[reftiLastOrders] then
        local tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])]
        if tLastOrder[subrefiOrderType] == refiOrderIssueRepair and M28UnitInfo.IsUnitValid(tLastOrder[subrefoOrderTarget]) and M28Utilities.IsTableEmpty(tLastOrder[subrefoOrderTarget][toUnitsOrderedToRepairThis]) == false then
            local iRefToRemove
            for iRepairer, oRepairer in tLastOrder[subrefoOrderTarget][toUnitsOrderedToRepairThis] do
                if oRepairer == oUnit then
                    iRefToRemove = iRepairer
                    break
                end
            end
            if iRefToRemove then table.remove(tLastOrder[subrefoOrderTarget][toUnitsOrderedToRepairThis], iRefToRemove) end
        end
    end
    oUnit[reftiLastOrders] = nil

    --Update tracking for engineers:
    if EntityCategoryContains(M28UnitInfo.refCategoryEngineer, oUnit.UnitId) then M28Engineer.ClearEngineerTracking(oUnit) end

    --Clear orders:
    IssueClearCommands({oUnit})

    --Unit name
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit) end
end

function RefreshUnitOrderTracking()  end --Just used to easily find UpdateRecordedOrders
function UpdateRecordedOrders(oUnit)
    --Checks a unit's command queue and removes items if we have fewer items than we recorded
    local iRecordedOrders
    if not(oUnit[reftiLastOrders]) then
        oUnit[reftiLastOrders] = nil
        --iRecordedOrders = 0
    else
        iRecordedOrders = table.getn(oUnit[reftiLastOrders])
        local tCommandQueue = oUnit:GetCommandQueue()
        local iCommandQueue = 0
        if tCommandQueue then iCommandQueue = table.getn(tCommandQueue) end
        if iCommandQueue < iRecordedOrders then
            if iCommandQueue == 0 then
                oUnit[reftiLastOrders] = nil
            else
                local iOrdersToRemove = iRecordedOrders - iCommandQueue
                for iEntry = 1, iOrdersToRemove do
                    oUnit[reftiLastOrders][iRecordedOrders] = nil
                    iRecordedOrders = iRecordedOrders - 1
                end
            end
        end
    end
end

function IssueTrackedMove(oUnit, tOrderPosition, iDistanceToReissueOrder, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --If we are close enough then issue the order again
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder and tLastOrder[subrefiOrderType] == refiOrderIssueMove and iDistanceToReissueOrder and M28Utilities.GetDistanceBetweenPositions(tOrderPosition, tLastOrder[subreftOrderPosition]) < iDistanceToReissueOrder) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueMove, [subreftOrderPosition] = tOrderPosition})
        IssueMove({oUnit}, tOrderPosition)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end

end

function IssueTrackedAttackMove(oUnit, tOrderPosition, iDistanceToReissueOrder, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --If we are close enough then issue the order again
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueAggressiveMove and iDistanceToReissueOrder and M28Utilities.GetDistanceBetweenPositions(tOrderPosition, tLastOrder[subreftOrderPosition]) < iDistanceToReissueOrder) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueAggressiveMove, [subreftOrderPosition] = tOrderPosition})
        IssueAggressiveMove({oUnit}, tOrderPosition)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedAttack(oUnit, oOrderTarget, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --Issue order if we arent already trying to attack them
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueAttack and oOrderTarget == tLastOrder[subrefoOrderTarget]) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueAttack, [subrefoOrderTarget] = oOrderTarget})
        IssueAttack({oUnit}, oOrderTarget)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedMoveAndBuild(oUnit, tBuildLocation, sOrderBlueprint, tMoveTarget, iDistanceToReorderMoveTarget, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    local bDontAlreadyHaveOrder = true
    local iLastOrderCount = 0
    if oUnit[reftiLastOrders] then
        iLastOrderCount = table.getn(oUnit[reftiLastOrders])
        if iLastOrderCount >= 2 then
            local tLastOrder = oUnit[reftiLastOrders][iLastOrderCount]
            if tLastOrder[subrefiOrderType] == refiOrderIssueBuild and sOrderBlueprint == tLastOrder[subrefsOrderBlueprint] and M28Utilities.GetDistanceBetweenPositions(tBuildLocation, tLastOrder[subreftOrderPosition]) <= 0.5 then
                local tSecondLastOrder = oUnit[reftiLastOrders][iLastOrderCount - 1]
                if tSecondLastOrder[subrefiOrderType] == refiOrderIssueMove and M28Utilities.GetDistanceBetweenPositions(tMoveTarget, tSecondLastOrder[subreftOrderPosition]) < (iDistanceToReorderMoveTarget or 0.01) then
                    bDontAlreadyHaveOrder = false
                end
            end
        end
    end
    LOG('IssueTrackedMoveAndBuild: oUnit='..oUnit.UnitId..M28UnitInfo.GetUnitLifetimeCount(oUnit)..'; bDontAlreadyHaveOrder='..tostring(bDontAlreadyHaveOrder or false))
    if bDontAlreadyHaveOrder then
        if not(bAddToExistingQueue) then
            LOG('IssueTrackedMoveAndBuild: Will clear commands of the unit')
            IssueTrackedClearCommands(oUnit)
        end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueMove, [subreftOrderPosition] = tMoveTarget})
        IssueMove({oUnit}, tMoveTarget)

        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueBuild, [subrefsOrderBlueprint] = sOrderBlueprint, [subreftOrderPosition] = tBuildLocation})
        IssueBuildMobile({ oUnit }, tBuildLocation, sOrderBlueprint, {})
        LOG('Sent an issuebuildmobile order to the unit')
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedBuild(oUnit, tOrderPosition, sOrderBlueprint, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueBuild and sOrderBlueprint == tLastOrder[subrefsOrderBlueprint] and M28Utilities.GetDistanceBetweenPositions(tOrderPosition, tLastOrder[subreftOrderPosition]) <= 0.5) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueBuild, [subrefsOrderBlueprint] = sOrderBlueprint, [subreftOrderPosition] = tOrderPosition})
        IssueBuildMobile({ oUnit }, tOrderPosition, sOrderBlueprint, {})
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedFactoryBuild(oUnit, sOrderBlueprint, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueFactoryBuild and sOrderBlueprint == tLastOrder[subrefsOrderBlueprint]) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueFactoryBuild, [subrefsOrderBlueprint] = sOrderBlueprint})
        IssueBuildFactory({ oUnit }, sOrderBlueprint, 1)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end


function IssueTrackedReclaim(oUnit, oOrderTarget, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --Issue order if we arent already trying to attack them
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueReclaim and oOrderTarget == tLastOrder[subrefoOrderTarget]) or (not(oUnit:IsUnitState('Reclaiming'))) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueReclaim, [subrefoOrderTarget] = oOrderTarget})
        IssueReclaim({oUnit}, oOrderTarget)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedGroundAttack(oUnit, tOrderPosition, iDistanceToReissueOrder, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --If we are close enough then issue the order again
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueGroundAttack and iDistanceToReissueOrder and M28Utilities.GetDistanceBetweenPositions(tOrderPosition, tLastOrder[subreftOrderPosition]) < iDistanceToReissueOrder) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueGroundAttack, [subreftOrderPosition] = tOrderPosition})
        IssueAttack({oUnit}, tOrderPosition)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedGuard(oUnit, oOrderTarget, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --Issue order if we arent already trying to attack them
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueGuard and oOrderTarget == tLastOrder[subrefoOrderTarget]) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueGuard, [subrefoOrderTarget] = oOrderTarget})
        IssueGuard({oUnit}, oOrderTarget)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedRepair(oUnit, oOrderTarget, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --Issue order if we arent already trying to attack them
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderIssueRepair and oOrderTarget == tLastOrder[subrefoOrderTarget]) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderIssueRepair, [subrefoOrderTarget] = oOrderTarget})
        IssueRepair({oUnit}, oOrderTarget)
        --Track against the unit we are repairing if it is under construction
        if oOrderTarget:GetFractionComplete() < 1 then
            if not(oOrderTarget[toUnitsOrderedToRepairThis]) then
                oOrderTarget[toUnitsOrderedToRepairThis] = {}
            end
            table.insert(oOrderTarget[toUnitsOrderedToRepairThis], oUnit)
        end
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

function IssueTrackedUpgrade(oUnit, sUpgradeRef, bAddToExistingQueue, sOptionalOrderDesc)
    UpdateRecordedOrders(oUnit)
    --Issue order if we arent already trying to attack them
    local tLastOrder
    if oUnit[reftiLastOrders] then tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])] end
    if not(tLastOrder[subrefiOrderType] == refiOrderUpgrade and sUpgradeRef == tLastOrder[subrefsOrderBlueprint]) then
        if not(bAddToExistingQueue) then IssueTrackedClearCommands(oUnit) end
        if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
        table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = refiOrderUpgrade, [subrefsOrderBlueprint] = sUpgradeRef})
        IssueUpgrade({oUnit}, sUpgradeRef)
    end
    if M28Config.M28ShowUnitNames then UpdateUnitNameForOrder(oUnit, sOptionalOrderDesc) end
end

--[[function IssueTrackedOrder(oUnit, iOrderType, tOrderPosition, oOrderTarget, sOrderBlueprint)
--Decided not to implement below as hopefully using separate functions should be better performance wise, and also issueformmove and aggressive move will require a table of units instead of individual units if they ever get implemented
    --tOrderPosition - this should only be completed if it is requried for the order
    if not(oUnit[reftiLastOrders]) then oUnit[reftiLastOrders] = {} end
    table.insert(oUnit[reftiLastOrders], {[subrefiOrderType] = iOrderType, [subreftOrderPosition] = tOrderPosition, [subrefoOrderTarget] = oOrderTarget, [subrefsOrderBlueprint] = sOrderBlueprint})
    if iOrderType == refiOrderIssueMove then
        IssueMove({oUnit}, tOrderPosition)
    elseif iOrderType == refiOrderIssueAggressiveMove then
        IssueAggressiveMove({oUnit}, tOrderPosition)
    elseif iOrderType == refiOrderIssueBuild then
        IssueBuildMobile({oUnit}, tOrderPosition, sOrderBlueprint, {})
    elseif iOrderType == refiOrderIssueReclaim then
        IssueReclaim({oUnit}, oOrderTarget)
    elseif iOrderType == refiOrderIssueAttack then
        IssueAttack({oUnit}, oOrderTarget)
    elseif iOrderType == refiOrderIssueGroundAttack then
        IssueAttack({oUnit}, tOrderPosition)
    elseif iOrderType == refiOrderIssueGuard then
        IssueGuard({oUnit}, oOrderTarget)
    elseif iOrderType == refiOrderIssueFormMove then
        IssueFormMove({oUnit}, tOrderPosition)
    elseif iOrderType == refiOrderIssueAggressiveFormMove then
        IssueFormAggressiveMove({oUnit}, tOrderPosition)
    elseif iOrderType == refiOrderIssueRepair then
        IssueRepair({oUnit}, oOrderTarget)
    elseif iOrderType == refiOrderOvercharge then
        IssueOvercharge({oUnit}, oOrderTarget)
    elseif iOrderType == refiOrderUpgrade then
        IssueScript({oUnit}, {TaskName = 'EnhanceTask', Enhancement = sOrderBlueprint})
    elseif iOrderType == refiOrderTransportLoad then
        IssueTransportLoad({oUnit}, oOrderTarget) --oUnit is e.g. the engineer, oOrderTarget is the transport it should bel oaded onto
    elseif iOrderType == refiOrderIssueGroundAttack then
        IssueTransportUnload({oUnit}, tOrderPosition) --e.g. oUnit is the transport
    end
end--]]

function ClearAnyRepairingUnits(oUnitBeingRepaired)
    --LOG('Is table of units ordered to repair oUnitBeingRepaired='..oUnitBeingRepaired.UnitId..M28UnitInfo.GetUnitLifetimeCount(oUnitBeingRepaired)..' empty='..tostring(M28Utilities.IsTableEmpty(oUnitBeingRepaired[toUnitsOrderedToRepairThis])))
    if oUnitBeingRepaired[toUnitsOrderedToRepairThis] then
        if M28Utilities.IsTableEmpty(oUnitBeingRepaired[toUnitsOrderedToRepairThis]) == false then
            for iUnit, oUnit in oUnitBeingRepaired[toUnitsOrderedToRepairThis] do
                if M28UnitInfo.IsUnitValid(oUnit) then
                    --Is this unit still trying to repair this?
                    UpdateRecordedOrders(oUnit)
                    LOG('Considering if oUnit='..oUnit.UnitId..M28UnitInfo.GetUnitLifetimeCount(oUnit)..' is still repairing; Last orders='..reprs(oUnit[reftiLastOrders]))
                    if oUnit[reftiLastOrders] then
                        local tLastOrder = oUnit[reftiLastOrders][table.getn(oUnit[reftiLastOrders])]
                        if tLastOrder[subrefiOrderType] == refiOrderIssueRepair and oUnitBeingRepaired == tLastOrder[subrefoOrderTarget] then
                            oUnit[reftiLastOrders] = nil --Clear here so we avoid the logic for lcearing in trackedclearcommands
                            IssueTrackedClearCommands(oUnit)
                        end

                    end
                end
            end
        end
        oUnitBeingRepaired[toUnitsOrderedToRepairThis] = nil
    end
end