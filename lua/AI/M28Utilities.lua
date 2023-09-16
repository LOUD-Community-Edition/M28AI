---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by maudlin27.
--- DateTime: 16/11/2022 07:26
---
local M28Profiler = import('/mods/M28AI/lua/AI/M28Profiler.lua')
local NavUtils = import("/lua/sim/navutils.lua")
local M28Map = import('/mods/M28AI/lua/AI/M28Map.lua')
local M28Overseer = import('/mods/M28AI/lua/AI/M28Overseer.lua')
local M28Conditions = import('/mods/M28AI/lua/AI/M28Conditions.lua')

tErrorCountByMessage = {} --WHenever we have an error, then the error message is a key that gets included in this table

bM28AIInGame = false --true if have M28 AI in the game (used to avoid considering callback logic further)


function ErrorHandler(sErrorMessage, bWarningNotError, bIgnoreCount, iIntervalOverride)
    --Intended to be put in code wherever a condition isn't met that should be, so can debug it without the code crashing
    --Search for "error " in the log to find both these errors and normal lua errors, while not bringing up warnings
    if sErrorMessage == nil then sErrorMessage = 'Not specified' end
    local iCount = (tErrorCountByMessage[sErrorMessage] or 0) + 1
    tErrorCountByMessage[sErrorMessage] = iCount
    local iInterval = iIntervalOverride or 1
    local bShowError = true
    if not(iIntervalOverride) and iCount >= 3 then
        bShowError = false
        if bIgnoreCount then bShowError = true
        else
            if bWarningNotError then
                if iCount > 1024 then iInterval = 4096
                elseif iCount > 256 then iInterval = 1024
                elseif iCount > 64 then iInterval = 256
                elseif iCount > 16 then iInterval = 64
                elseif iCount > 2 then iInterval = 16
                else iInterval = 2
                end
            else
                if iCount > 2187 then iInterval = 2187
                elseif iCount > 729 then iInterval = 729
                elseif iCount > 243 then iInterval = 243
                elseif iCount >= 81 then iInterval = 81
                elseif iCount >= 27 then iInterval = 27
                elseif iCount >= 9 then iInterval = 9
                else iInterval = 3
                end
            end
            if math.floor(iCount / iInterval) == iCount/iInterval then bShowError = true end
        end
    end
    if bShowError then
        local sErrorBase = 'M28ERROR '
        if bWarningNotError then sErrorBase = 'M28Warning: ' end
        sErrorBase = sErrorBase..'Count='..iCount..': GameTime '..math.floor(GetGameTimeSeconds())..': '
        sErrorMessage = sErrorBase..sErrorMessage
        local a, s = pcall(assert, false, sErrorMessage)
        WARN(a, s)
    end

    --if iOptionalWaitInSeconds then WaitSeconds(iOptionalWaitInSeconds) end
end


function IsTableEmpty(tTable, bEmptyIfNonTableWithValue)
    --bEmptyIfNonTableWithValue - Optional, defaults to true
    --E.g. if passed oUnit to a function that was expecting a table, then setting bEmptyIfNonTableWithValue = false means it will register the table isn't nil

    if (type(tTable) == "table") then
        if next (tTable) == nil then return true
        else
            for i1, v1 in pairs(tTable) do
                if IsTableEmpty(v1, false) == false then return false end
            end
            return true
        end
    else
        if tTable == nil then return true
        else
            if bEmptyIfNonTableWithValue == nil then return true --tried to simplify this with return (bEmptyIfNonTableWithValue or true) but it caused errors
            else return bEmptyIfNonTableWithValue
            end
        end
    end
end

function ForkedDrawRectangle(rRect, iColour, iDisplayCount)
    --Only call via cork thread
    --Draws lines around rRect; rRect should be a rect table, with keys x0, x1, y0, y1
    --iColour - if it isn't a number from 1 to 8 then it will try and use the value as the hex key instead

    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'ForkedDrawRectangle'
    if bDebugMessages == true then LOG(sFunctionRef..': rRect='..repru(rRect)) end

    local sColour
    if iColour == nil then sColour = 'c00000FF' --dark blue
    elseif iColour == 1 then sColour = 'c00000FF' --dark blue
    elseif iColour == 2 then sColour = 'ffFF4040' --Red
    elseif iColour == 3 then sColour = 'c0000000' --Black (can be hard to see on some maps)
    elseif iColour == 4 then sColour = 'fff4a460' --Gold
    elseif iColour == 5 then sColour = 'ff27408b' --Light Blue
    elseif iColour == 6 then sColour = 'ff1e90ff' --Cyan (might actually be white as well?)
    elseif iColour == 7 then sColour = 'ffffffff' --white
    elseif iColour == 8 then sColour = 'ffFF6060' --Orangy pink
    else sColour = iColour
    end


    if iDisplayCount == nil then iDisplayCount = 500
    elseif iDisplayCount <= 0 then iDisplayCount = 1
    elseif iDisplayCount >= 10000 then iDisplayCount = 10000 end
    local tCurPos, tLastPos
    local iCurX, iCurZ

    local iCurDrawCount = 0
    local iCount = 0
    while true do
    iCount = iCount + 1
    if iCount > 10000 then ErrorHandler('Infinite loop') break end
        for iValX = 1, 2 do
            for iValZ = 1, 2 do
                if iValX == 1 then
                    iCurX = rRect['x0']
                    if iValZ == 1 then
                        iCurZ = rRect['y0']
                    else
                        iCurZ = rRect['y1']
                    end
                else
                    iCurX = rRect['x1']
                    if iValZ == 1 then
                        iCurZ = rRect['y1']
                    else
                        iCurZ = rRect['y0']
                    end
                end

                tLastPos = tCurPos
                tCurPos = { iCurX, GetTerrainHeight(iCurX, iCurZ), iCurZ }
                if tLastPos then
                    if bDebugMessages == true then
                        LOG(sFunctionRef .. ': tLastPos=' .. repru(tLastPos) .. '; tCurPos=' .. repru(tCurPos)..'; sColour='..sColour)
                    end
                    DrawLine(tLastPos, tCurPos, sColour)
                end
            end
        end
        iCurDrawCount = iCurDrawCount + 1
        if iCurDrawCount > iDisplayCount then
            return
        end
        coroutine.yield(2) --Any more and lines will flash instead of being constant
    end
end

function DrawRectangle(rRectangle, iOptionalColour, iOptionalTimeInTicks, iOptionalSizeIncrease)
    local iRadiusIncrease = (iOptionalSizeIncrease or 0) * 0.5
    LOG('DrawRectangle: reprs of rRectangle='..reprs(rRectangle))
    --LOG('x0='..rRectangle['x0'])
    --NOTE: Some rectangles are in the format {[1]=x1,[2]=z1,[3]=x2,[4]=z2}
    --Others are in the format ['x0']=x1, ['y0'] = z1.... (although order of x0, y0, x1, y1 may change?)
    --so if get error with below probably because it was only written with the one format in mind
    ForkThread(ForkedDrawRectangle, Rect(rRectangle['x0'] - iRadiusIncrease, rRectangle['y0'] - iRadiusIncrease, rRectangle['x1'] + iRadiusIncrease, rRectangle['y1'] + iRadiusIncrease), (iOptionalColour or 1), (iOptionalTimeInTicks or 200))
end

function DrawLocation(tLocation, iOptionalColour, iOptionalTimeInTicks, iOptionalSize)
    local iRadius = (iOptionalSize or 1) * 0.5
    ForkThread(ForkedDrawRectangle, Rect(tLocation[1] - iRadius, tLocation[3] - iRadius, tLocation[1] + iRadius, tLocation[3] + iRadius), (iOptionalColour or 1), (iOptionalTimeInTicks or 200))
end

function ForkedDrawLine(tStart, tEnd, iColour, iDisplayCount)
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    local sFunctionRef = 'ForkedDrawLine'
    if bDebugMessages == true then LOG(sFunctionRef..': rRect='..repru(rRect)) end

    local sColour
    if iColour == nil then sColour = 'c00000FF' --dark blue
    elseif iColour == 1 then sColour = 'c00000FF' --dark blue
    elseif iColour == 2 then sColour = 'ffFF4040' --Red
    elseif iColour == 3 then sColour = 'c0000000' --Black (can be hard to see on some maps)
    elseif iColour == 4 then sColour = 'fff4a460' --Gold
    elseif iColour == 5 then sColour = 'ff27408b' --Light Blue
    elseif iColour == 6 then sColour = 'ff1e90ff' --Cyan (might actually be white as well?)
    elseif iColour == 7 then sColour = 'ffffffff' --white
    else sColour = 'ffFF6060' --Orangy pink
    end


    if iDisplayCount == nil then iDisplayCount = 500
    elseif iDisplayCount <= 0 then iDisplayCount = 1
    elseif iDisplayCount >= 10000 then iDisplayCount = 10000 end

    local iCurDrawCount = 0
    local iCount = 0
    while true do
        DrawLine(tStart, tEnd, sColour)
        iCount = iCount + 1
        if iCount > 10000 then ErrorHandler('Infinite loop') break end
        if iCurDrawCount > iDisplayCount then return end
        coroutine.yield(2) --Any more and lines will flash instead of being constant
    end
end

function DrawPath(tPath, iOptionalColour, iOptionalTimeInTicks)
    local iColour = iOptionalColour or 1
    local iDisplayCount = iOptionalTimeInTicks or 100
    local iCount = 0
    local tPrevPosition
    for iPath, tPath in tPath do
        iCount = iCount + 1
        if iCount > 1 then
            ForkThread(ForkedDrawLine, tPrevPosition, tPath, iColour, iDisplayCount)
        end
        tPrevPosition = {tPath[1], tPath[2], tPath[3]}
    end
end

function GetApproxTravelDistanceBetweenPositions(tStart, tEnd)
    --Similar to GetTravelDistanceBetweenPositions, but will only precisely calculate the distance from the start to the first point, and then rely on the base pathing distance calculation
    local tFullPath, iPathSize, iDistance = NavUtils.PathTo('Land', tStart, tEnd, nil)
    if tFullPath then
        if tFullPath[iPathSize][1] == tEnd[1] and tFullPath[iPathSize][3] == tEnd[3] then
            return iDistance + VDist2(tFullPath[1][1], tFullPath[1][3], tStart[1], tStart[3])
        else
            return iDistance + VDist2(tFullPath[1][1], tFullPath[1][3], tStart[1], tStart[3]) + VDist2(tFullPath[iPathSize][1], tFullPath[iPathSize][3])
        end
    else
        return nil
    end
end
function GetTravelDistanceBetweenPositions(tStart, tEnd, sPathing)
    --Returns the distance for a land unit to move from tStart to tEnd using Jips pathing algorithm
    --Returns nil if cant path there

    --4th argument could be NavUtils.PathToDefaultOptions(), e.g. local tFullPath, iPathSize, iDistance = NavUtils.PathTo('Land', tStart, tEnd, NavUtils.PathToDefaultOptions()); left as nil:
    local tFullPath, iPathSize, iDistance = NavUtils.PathTo((sPathing or 'Land'), tStart, tEnd, nil)
    if tFullPath then

        --Option 1 - recalculate all distances (during testing as at 2022-11-20 sometimes even if go with option 2 below the distance is significantly lower than option 1 gives:
        local iTravelDistance = 0
        tFullPath[0] = tStart
        tFullPath[iPathSize + 1] = tEnd
        for iPath = 1, iPathSize + 1 do
            --iTravelDistance = iTravelDistance + GetDistanceBetweenPositions(tFullPath[iPath - 1], tFullPath[iPath])
            iTravelDistance = iTravelDistance + VDist2(tFullPath[iPath - 1][1], tFullPath[iPath - 1][3], tFullPath[iPath][1], tFullPath[iPath][3])
        end
        return iTravelDistance


        --[[
        --Below log is for debug
        local iDistanceAddingStartAndEnd = iDistance + VDist2(tStart[1], tStart[3], tFullPath[1][1], tFullPath[1][3]) + VDist2(tEnd[1], tEnd[3], tFullPath[iPathSize][1], tFullPath[iPathSize][3])
        if iTravelDistance > iDistanceAddingStartAndEnd then
            LOG('Just got pathing distance, iDistanceAddingStartAndEnd='..iDistanceAddingStartAndEnd..'; iTravelDistance='..iTravelDistance..'; base distance value before adjust='..iDistance..' from '..repru(tStart)..' to '..repru(tEnd)..'; iPathSize='..(iPathSize or 'nil')..'; Reprs of path='..reprs(tFullPath)..'; Distance in straight line from start to first point in path='..GetDistanceBetweenPositions(tStart, tFullPath[1])..'; Dist from last path point to end='..GetDistanceBetweenPositions(tFullPath[iPathSize], tEnd)..'; Distance if take iDistance+this='..(iDistance + GetDistanceBetweenPositions(tStart, tFullPath[1]) + GetDistanceBetweenPositions(tFullPath[iPathSize], tEnd)))
        end
        --Option 2 - just add in the first and last distance to the distance determined by the pathing algorithm (not as accurate):
        return iDistance + VDist2(tStart[1], tStart[3], tFullPath[1][1], tFullPath[1][3]) + VDist2(tEnd[1], tEnd[3], tFullPath[iPathSize][1], tFullPath[iPathSize][3])--]]
    else
        return nil
    end
end
function GetDistanceBetweenPositions(tPosition1, tPosition2)
    --Done for convenience and to reduce risk of human error if were to use vdist2 directly; returns the distance in a straight line (ignoring pathing) between 2 positions
    return VDist2(tPosition1[1], tPosition1[3], tPosition2[1], tPosition2[3])
end

function GetRoughDistanceBetweenPositions(tPosition1, tPosition2)
    --If want a rough indication of proximity but it isnt as important as speed
    return math.max(math.abs(tPosition1[1] - tPosition2[1]), math.abs(tPosition1[3] - tPosition2[3]))
end

function GenerateUniqueColourTable(iTableSize)
    local FAFColour = import("/lua/shared/color.lua")
    local tColourTable = {}
    local tInterval = {{0.13, 0.23, 0.37}, {0.13,0.37,0.23},{0.23,0.13,.37},{0.23,0.37,0.13},{0.37,0.13,0.23},{0.37,0.23,0.13}}
    local tiIntervalToUse = tInterval[math.random(table.getn(tInterval))]
    local iCurR = 0
    local iCurG = 0
    local iCurB = 0
    for iEntry = 1, iTableSize do
        iCurR = iCurR + tiIntervalToUse[1]
        if iCurR > 1 then iCurR = iCurR - 1 end
        iCurG = iCurG + tiIntervalToUse[2]
        if iCurG > 1 then iCurG = iCurG - 1 end
        iCurB = iCurB + tiIntervalToUse[3]
        if iCurB > 1 then iCurB = iCurB - 1 end
        tColourTable[iEntry] = FAFColour.ColorRGB(iCurR, iCurG, iCurB, nil)
    end
    return tColourTable

end

function GetNearestUnit(tUnits, tCurPos, bUseActualTravelDistance, sPathingToUse)
    --returns the nearest unit in tUnits from tCurPos

    local sFunctionRef = 'GetNearestUnit'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    local iMinDist = 1000000
    local iCurDist
    local iNearestUnit
    if bDebugMessages == true then LOG('GetNearestUnit: tUnits table size='..table.getn(tUnits)) end
    for iUnit, oUnit in tUnits do
        if not(oUnit.Dead) then
            if bUseActualTravelDistance then iCurDist = GetTravelDistanceBetweenPositions(oUnit:GetPosition(), tCurPos, sPathingToUse)
            else iCurDist = GetDistanceBetweenPositions(oUnit:GetPosition(), tCurPos)
            end
            if bDebugMessages == true then LOG('GetNearestUnit: iUnit='..iUnit..'; iCurDist='..iCurDist..'; iMinDist='..iMinDist) end
            if (iCurDist or iMinDist) < iMinDist then
                iMinDist = iCurDist
                iNearestUnit = iUnit
            end
        end
    end

    if bDebugMessages == true then
        if iNearestUnit == nil then LOG('Nearest unit is nil')
        else LOG('Nearest unit ID='..tUnits[iNearestUnit].UnitId)
        end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
    if iNearestUnit then return tUnits[iNearestUnit]
    else return nil end
end

function ConvertAngleToRadians(iAngle)
    return iAngle * math.pi / 180
end

function ConvertRadiansToAngle(iRadians)
    --Assumes radians when converted would result in north being 180 degrees, east 90 degrees, south 0 degrees, west 270 degrees

    --iRadians = iAngle * math.pi / 180
    --180 * iRadians = iAngle * math.pi
    --iAngle = 180 * iRadians / math.pi
    local iAngle = 360 - (180 * iRadians / math.pi) - 180
    if iAngle < 0 then iAngle = iAngle + 360 end
    return iAngle
end

function GetAngleDifference(iAngle1, iAngle2)
    --returns positive value from 0 to 180 for the difference between two positions (i.e. if turn by the angle closest to there)
    local iAngleDif = math.abs(iAngle1 - iAngle2)
    if iAngleDif > 180 then iAngleDif = math.abs(iAngleDif - 360) end
    return iAngleDif
end

function GetAngleFromAToB(tLocA, tLocB)
    --Returns an angle 0 = north, 90 = east, etc. based on direction of tLocB from tLocA
    local iTheta
    if tLocA[1] == tLocB[1] then
        --Will get infinite if try and use this; is [3] the same?
        if tLocA[3] >= tLocB[3] then --Start is below end, so End is north of start (or LocA == LocB and want 0)
            iTheta = 0
        else
            --Start Z value is lower than end, so start is above end, so if facing end from start we are facing south
            iTheta = 180
        end
    elseif tLocA[3] == tLocB[3] then
        --Have dif in X values but not Z values, so moving in straight line east or west:
        if tLocA[1] < tLocB[1] then --Start is to left of end, so if facing end from start we are facing 90 degrees (Moving east)
            iTheta = 90
        else --must be moving west
            iTheta = 270
        end
    else
        iTheta = math.atan(math.abs(tLocA[3] - tLocB[3]) / math.abs(tLocA[1] - tLocB[1])) * 180 / math.pi
        if tLocB[1] > tLocA[1] then
            if tLocB[3] > tLocA[3] then
                return 90 + iTheta
            else return 90 - iTheta
            end
        else
            if tLocB[3] > tLocA[3] then
                return 270 - iTheta
            else return 270 + iTheta
            end
        end
    end
    return iTheta
end

function IsLineFromAToBInRangeOfCircleAtC(iDistFromAToB, iDistFromAToC, iDistFromBToC, iAngleFromAToB, iAngleFromAToC, iCircleRadius)
    --E.g. if TML is at point A, target is at point B, and TMD is at point C, does the TMD block the TML in a straight line?
    if iDistFromAToC <= iCircleRadius or iDistFromBToC <= iCircleRadius then
        --LOG('Dist within circle radius so are in range, returning true')
        return true
        --Note - have done circleradius*1.2 as was one scenario where the SMD just overlapped despite distAtoB+CircleRadius being less than DistAtoC (for SMD was about 82 vs 90)
    elseif (iDistFromAToC > iDistFromBToC and iDistFromAToB < iDistFromAToC) or iDistFromAToB + iCircleRadius*1.2 < iDistFromAToC then
        --LOG('Dist to circle further than target and not in range of circle radius, so returning false')
        return false
    else
        --Unclear so need more precise calculation
        --LOG('Unclear so doing more precise calculation.  iAngleFromAToB - iAngleFromAToC='..(iAngleFromAToB - iAngleFromAToC)..'; ConvertAngleToRadians(iAngleFromAToB - iAngleFromAToC)='..ConvertAngleToRadians(iAngleFromAToB - iAngleFromAToC)..'; math.tan(math.abs(ConvertAngleToRadians(iAngleFromAToB - iAngleFromAToC)))='..math.tan(math.abs(ConvertAngleToRadians(iAngleFromAToB - iAngleFromAToC)))..'; iDistFromAToC='..iDistFromAToC..'; iCircleRadius='..iCircleRadius..'; Calculation result='..math.tan(math.abs(ConvertAngleToRadians(iAngleFromAToB - iAngleFromAToC))) * iDistFromAToC)
        if math.abs(math.tan(ConvertAngleToRadians(iAngleFromAToB - iAngleFromAToC))) * iDistFromAToC <= iCircleRadius then
            --LOG('Are in range so returning true')
            return true
        else
            --LOG('Are out of range so returning false')
            return false
        end
    end
end

function GetRectangleAtPosition()  end --Used to help locate the below
function GetRectAroundLocation(tLocation, iRadius)
    --Looks iRadius left/right and up/down (e.g. if want 1x1 square centred on tLocation, iRadius should be 0.5)
    return Rect(tLocation[1] - iRadius, tLocation[3] - iRadius, tLocation[1] + iRadius, tLocation[3] + iRadius)
end

function MoveInDirection(tStart, iAngle, iDistance, bKeepInMapBounds, bTravelUnderwater, bKeepInCampaignPlayableArea)
    --iAngle: 0 = north, 90 = east, etc.; use GetAngleFromAToB if need angle from 2 positions
    --tStart = {x,y,z} (y isnt used); try to use a location that is inside the playable area as tStart
    --if bKeepInMapBounds is true then will limit to map bounds
    --bTravelUnderwater - if true then will get the terrain height instead of the surface height

    --local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end
    --local sFunctionRef = 'MoveInDirection'
    local iTheta = ConvertAngleToRadians(iAngle)
    --if bDebugMessages == true then LOG(sFunctionRef..': iAngle='..(iAngle or 'nil')..'; iTheta='..(iTheta or 'nil')..'; iDistance='..(iDistance or 'nil')..'; M28Map.rMapPotentialPlayableArea='..repru(M28Map.rMapPotentialPlayableArea)..'; tStart='..repru(tStart)) end
    local iXAdj = math.sin(iTheta) * iDistance
    local iZAdj = -(math.cos(iTheta) * iDistance)

    if not(bKeepInMapBounds) then
        --if bDebugMessages == true then LOG(sFunctionRef..': Are within map bounds, iXAdj='..iXAdj..'; iZAdj='..iZAdj..'; iTheta='..iTheta..'; position='..repru({tStart[1] + iXAdj, GetSurfaceHeight(tStart[1] + iXAdj, tStart[3] + iZAdj), tStart[3] + iZAdj})) end
        if bTravelUnderwater then
            return {tStart[1] + iXAdj, GetTerrainHeight(tStart[1] + iXAdj, tStart[3] + iZAdj), tStart[3] + iZAdj}
        else
            return {tStart[1] + iXAdj, GetSurfaceHeight(tStart[1] + iXAdj, tStart[3] + iZAdj), tStart[3] + iZAdj}
        end
    else
        local rPlayableArea
        if bKeepInCampaignPlayableArea then
            --Adjust slightly as had a location that was 0.1 inside the playable area and units couldnt move to it
            rPlayableArea = {M28Map.rMapPlayableArea[1] + 1, M28Map.rMapPlayableArea[2] + 1, M28Map.rMapPlayableArea[3] - 1, M28Map.rMapPlayableArea[4] - 1}
        else rPlayableArea = M28Map.rMapPotentialPlayableArea
        end
        local tTargetPosition
        if bTravelUnderwater then
            tTargetPosition = {tStart[1] + iXAdj, GetTerrainHeight(tStart[1] + iXAdj, tStart[3] + iZAdj), tStart[3] + iZAdj}
        else
            tTargetPosition = {tStart[1] + iXAdj, GetSurfaceHeight(tStart[1] + iXAdj, tStart[3] + iZAdj), tStart[3] + iZAdj}
        end
        --Get actual distance required to keep within map bounds
        local iNewDistWanted = 10000

        if tTargetPosition[1] < rPlayableArea[1] then iNewDistWanted = (iDistance - 0.5) * (tStart[1] - rPlayableArea[1]) / (tStart[1] - tTargetPosition[1]) end
        if tTargetPosition[3] < rPlayableArea[2] then iNewDistWanted = math.min(iNewDistWanted, (iDistance - 0.5) * (tStart[3] - rPlayableArea[2]) / (tStart[3] - tTargetPosition[3])) end
        if tTargetPosition[1] > rPlayableArea[3] then iNewDistWanted = math.min(iNewDistWanted, (iDistance - 0.5) * (rPlayableArea[3] - tStart[1]) / (tTargetPosition[1] - tStart[1])) end
        if tTargetPosition[3] > rPlayableArea[4] then iNewDistWanted = math.min(iNewDistWanted, (iDistance - 0.5) * (rPlayableArea[4] - tStart[3]) / (tTargetPosition[3] - tStart[3])) end
        if GetGameTimeSeconds() >= 2160 and iDistance == 200 then LOG('tStart='..repru(tStart)..'; tTargetPosition='..repru(tTargetPosition)..'; rPlayableArea='..repru(rPlayableArea)..'; iNewDistWanted='..iNewDistWanted..'; (10k means we dont need to adjust for playable area so will just return target position)') end

        if iNewDistWanted == 10000 then
            --if bDebugMessages == true then LOG(sFunctionRef..': Are inside playable area, returning tTargetPosition='..repru(tTargetPosition)) end
            return tTargetPosition
        else
            --Are out of playable area, so adjust the position; Can use the ratio of the amount we have moved left/right or top/down vs the long line length to work out the long line length if we reduce the left/right so its within playable area
            --if bDebugMessages == true then LOG(sFunctionRef..': Outside playable area, iNewDistWanted='..iNewDistWanted..'; iXAdj='..iXAdj..'; iZAdj='..iZAdj..'; iDistance='..iDistance..'; tTargetPosition after updating for x and z adj='..repru(tTargetPosition)..'; rPlayableArea='..repru(rPlayableArea)) end
            return MoveInDirection(tStart, iAngle, iNewDistWanted, false)
        end
    end
end

function ConvertLocationToReference(tLocation)
    --Rounds tLocation down for X and Z, and uses these to provide a unique string reference (for use for table keys)
    return ('X'..math.floor(tLocation[1])..'Z'..math.floor(tLocation[3]))
end

function RemoveEntriesFromTableForSearch(tArray, fnKeepCurEntry)
--Only included to help locate RemoveEntriesFromArrayBasedOnCondition - below is redundancy in case we actually used this by mistake
--NOTE: Doesnt work on all tables, must be an array, i.e. the key is 1, 2, 3.....x
    RemoveEntriesFromArrayBasedOnCondition(tArray, fnKeepCurEntry)
end

function RemoveEntriesFromArrayBasedOnCondition(tArray, fnKeepCurEntry)
    --Alternative to table.remove, intended as a faster option where potentially removing more than one entry; only for use on tables with a sequential integer key starting at 1 (i.e. {[1]=asdf, [2] = asdf, ...})
    --fnKeepCurEntry is a function (that should do specific for each use case) that decides what entries we want to remove from the table
    --This means if we are removing multiple entries from a table at once, we only reindex the table once (vs table.remove which reindexes it every time we remove an entry)
    --Based on approach outlined by 'Mitch' in https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating

    --[[Example of using this: The below removes test2 from the array:
    local tTestArray = {[1] = 'Test1', [2] = 'Test2', [3] = 'Test3', [4] = 'Test4'}
    local function WantToKeep(tArray, iEntry)
        if tArray[iEntry] == 'Test2' then return false else return true end
    end
    M28Utilities.RemoveEntriesFromArrayBasedOnCondition(tTestArray, WantToKeep)
    LOG('Finished updating array, tTestArray='..repru(tTestArray))
    --]]

    --NOTE: If want something more complex, then just copy the below code and adapt, e.g. if want to add removed entries to a different table
    
    local iRevisedIndex = 1
    local iTableSize = table.getn(tArray)

    for iOrigIndex=1, iTableSize do
        if tArray[iOrigIndex] then
            if fnKeepCurEntry(tArray, iOrigIndex) then --I.e. this should run the logic to decide whether we want to keep this entry of the table or remove it
                --We want to keep the entry; Move the original index to be the revised index number (so if e.g. a table of 1,2,3 removed 2, then this would've resulted in the revised index being 2 (i.e. it starts at 1, then icnreases by 1 for the first valid entry); this then means we change the table index for orig index 3 to be 2
                if (iOrigIndex ~= iRevisedIndex) then
                    tArray[iRevisedIndex] = tArray[iOrigIndex];
                    tArray[iOrigIndex] = nil;
                end
                iRevisedIndex = iRevisedIndex + 1; --i.e. this will be the position of where the next value that we keep will be located
            else
                tArray[iOrigIndex] = nil;
            end
        end
    end
    return tArray;
end


function DoesCategoryContainCategory(iCategoryWanted, iCategoryToSearch, bOnlyContainsThisCategory)
    --Not very efficient so consider alternative such as recording variables if going to be running lots of times
    local tsUnitIDs = EntityCategoryGetUnitList(iCategoryToSearch)
    if bOnlyContainsThisCategory then
        for iRef, sRef in tsUnitIDs do
            if not(EntityCategoryContains(iCategoryWanted, sRef)) then return false end
        end
        return true
    else
        for iRef, sRef in tsUnitIDs do
            if EntityCategoryContains(iCategoryWanted, sRef) then return true end
        end
    end
    return false
end

function spairs(t, order)
    --Required by the sort tables function
    --Code with thanks to Michal Kottman https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    -- collect the keys
    local keys = {}
    local iKeyCount = 0
    for k in pairs(t) do
        iKeyCount = iKeyCount+1
        keys[iKeyCount] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function SortTableBySubtable(tTableToSort, sSortByRef, bLowToHigh)
    --NOTE: This doesnt update tTableToSort.  Instead it returns a 1-off table reference that you can use e.g. to loop through each entry.  Its returning function(table), which means if you try and store it as a table variable, then further references to it will re-run the function causing issues
    --[[ e.g. of a table where this will work:
    local tPreSortedThreatGroup = {}
    local sThreatGroup
    for i1 = 1, 4 do
        sThreatGroup = 'M28'..i1
        tPreSortedThreatGroup[sThreatGroup] = {}
        if i1 == 1 then
            tPreSortedThreatGroup[sThreatGroup][refiDistanceFromOurBase] = 100
        elseif i1 == 4 then tPreSortedThreatGroup[sThreatGroup][refiDistanceFromOurBase] = 200
        else tPreSortedThreatGroup[sThreatGroup][refiDistanceFromOurBase] = math.random(1, 99)
        end
    end
    for iEntry, tValue in SortTableBySubtable(tPreSortedThreatGroup, refiDistanceFromOurBase, true) then will iterate through the values from low to high
    ]]--

    if bLowToHigh == nil then bLowToHigh = true end
    if bLowToHigh == true then
        return spairs(tTableToSort, function(t,a,b) return t[b][sSortByRef] > t[a][sSortByRef] end)
    else return spairs(tTableToSort, function(t,a,b) return t[b][sSortByRef] < t[a][sSortByRef] end)
    end
end

function SortTableByValue(tTableToSort, bHighToLow)
    --e.g. for iCategory, iCount in M28Utilities.SortTableByValue(tCategoryUsage, true) do
    if bHighToLow then return spairs(tTableToSort, function(t,a,b) return t[b] < t[a] end)
    else return spairs(tTableToSort, function(t,a,b) return t[b] > t[a] end)
    end
end

function GetAverageOfLocations(tAllLocations)
    local tTotalPos = {0,0,0}
    local iLocationCount = 0
    for iLocation, tLocation in tAllLocations do
        tTotalPos[1] = tTotalPos[1] + tLocation[1]
        tTotalPos[3] = tTotalPos[3] + tLocation[3]
        iLocationCount = iLocationCount + 1
    end
    local tAveragePos = {tTotalPos[1] / iLocationCount, 0, tTotalPos[3] / iLocationCount}
    tAveragePos[2] = GetSurfaceHeight(tAveragePos[1], tAveragePos[3])
    return tAveragePos
end

function ForkedDelayedChangedVariable(oVariableOwner, sVariableName, vVariableValue, iDelayInSeconds, sOptionalOwnerConditionRef, iMustBeLessThanThisTimeValue, iMustBeMoreThanThisTimeValue, vMustNotEqualThisValue)
    --After waiting iDelayInSeconds, changes the variable to vVariableValue.
    local sFunctionRef = 'ForkedDelayedChangedVariable'

    WaitSeconds(iDelayInSeconds)
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerStart)
    if oVariableOwner then
        local bReset = true
        if sOptionalOwnerConditionRef then
            if iMustBeLessThanThisTimeValue and oVariableOwner[sOptionalOwnerConditionRef] >= iMustBeLessThanThisTimeValue then bReset = false
            elseif iMustBeMoreThanThisTimeValue and oVariableOwner[sOptionalOwnerConditionRef] <= iMustBeMoreThanThisTimeValue then bReset = false
            elseif vMustNotEqualThisValue and oVariableOwner[sOptionalOwnerConditionRef] == vMustNotEqualThisValue then bReset = false
            end
        end
        if bReset then oVariableOwner[sVariableName] = vVariableValue end
    end
    M28Profiler.FunctionProfiler(sFunctionRef, M28Profiler.refProfilerEnd)
end

function DelayChangeVariable(oVariableOwner, sVariableName, vVariableValue, iDelayInSeconds, sOptionalOwnerConditionRef, iMustBeLessThanThisTimeValue, iMustBeMoreThanThisTimeValue, vMustNotEqualThisValue)
    --sOptionalOwnerConditionRef - can specify a variable for oVariableOwner; if so then the value of this variable must be <= iMustBeLessThanThisTimeValue
    --e.g. if delay reset a variable, but are claling multiple times so want to only reset on the latest value, then this allows for that
    ForkThread(ForkedDelayedChangedVariable, oVariableOwner, sVariableName, vVariableValue, iDelayInSeconds, sOptionalOwnerConditionRef, iMustBeLessThanThisTimeValue, iMustBeMoreThanThisTimeValue, vMustNotEqualThisValue)
end

function DrawCircleAtTarget(tLocation, iColour, iDisplayCount, iCircleSize) --Dont call DrawCircle since this is a built in function
    ForkThread(SteppingStoneForDrawCircle, tLocation, iColour, iDisplayCount, iCircleSize)
end

function SteppingStoneForDrawCircle(tLocation, iColour, iDisplayCount, iCircleSize)
    DrawCircleAroundPoint(tLocation, iColour, iDisplayCount, iCircleSize)
end

function DrawCircleAroundPoint(tLocation, iColour, iDisplayCount, iCircleSize)
    --Use DrawCircle which will call a forkthread to call this
    local sFunctionRef = 'DrawCircleAroundPoint'
    local bDebugMessages = false if M28Profiler.bGlobalDebugOverride == true then   bDebugMessages = true end


    if iCircleSize == nil then iCircleSize = 2 end
    if iDisplayCount == nil then iDisplayCount = 500
    elseif iDisplayCount <= 0 then iDisplayCount = 1
    elseif iDisplayCount >= 10000 then iDisplayCount = 10000
    end

    local sColour
    if iColour == nil then sColour = 'c00000FF' --dark blue
    elseif iColour == 1 then sColour = 'c00000FF' --dark blue
    elseif iColour == 2 then sColour = 'ffFF4040' --Red
    elseif iColour == 3 then sColour = 'c0000000' --Black (can be hard to see on some maps)
    elseif iColour == 4 then sColour = 'fff4a460' --Gold
    elseif iColour == 5 then sColour = 'ff27408b' --Light Blue
    elseif iColour == 6 then sColour = 'ff1e90ff' --Cyan (might actually be white as well?)
    elseif iColour == 7 then sColour = 'ffffffff' --white
    else sColour = 'ffFF6060' --Orangy pink
    end

    local iMaxDrawCount = iDisplayCount
    local iCurDrawCount = 0
    if bDebugMessages == true then LOG('About to draw circle at table location ='..repru(tLocation)) end
    while true do
        DrawCircle(tLocation, iCircleSize, sColour)
        iCurDrawCount = iCurDrawCount + 1
        if iCurDrawCount > iMaxDrawCount then return end
        if bDebugMessages == true then LOG(sFunctionRef..': Will wait 2 ticks then refresh the drawing') end
        coroutine.yield(2) --Any more and circles will flash instead of being constant
    end
end