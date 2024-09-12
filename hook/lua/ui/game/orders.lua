---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by maudlin27.
--- DateTime: 23/08/2024 22:16
---

local defaultOrdersTable = defaultOrdersTable or { }

GetOrderBitmapNames = function(bitmapId)
    --LOG('GetOrderBitmapNames: Start')
    if bitmapId == nil then
        LOG("Error - nil bitmap passed to GetOrderBitmapNames")
        bitmapId = "basic-empty"    -- TODO do I really want to default it?
    end

    local button_prefix
    --LOG('bitmapId='..(bitmapId or 'nil')..'; string.sub(bitmapId, 1, 3)='..string.sub(bitmapId, 1, 3))
    if string.sub(bitmapId, 1, 3) == 'M28' then
        button_prefix = "/mods/M28AI/textures/"..bitmapId.."_btn_"
    else
        button_prefix = "/game/orders/" .. bitmapId .. "_btn_"
    end
    return UIUtil.SkinnableFile(button_prefix .. "up.dds")
    ,  UIUtil.SkinnableFile(button_prefix .. "up_sel.dds")
    ,  UIUtil.SkinnableFile(button_prefix .. "over.dds")
    ,  UIUtil.SkinnableFile(button_prefix .. "over_sel.dds")
    ,  UIUtil.SkinnableFile(button_prefix .. "dis.dds")
    ,  UIUtil.SkinnableFile(button_prefix .. "dis_sel.dds")
    , "UI_Action_MouseDown", "UI_Action_Rollover"   -- sets click and rollover cues
end

local function M28AIToggle(self, modifiers, subState)
    --This runs when the user clicks on the button to toggle whether M28 is enabled on the unit or not
    local state
    if subState ~= nil then --Is the button currently checked?
        state = subState
    else
        state = self:IsChecked()
    end
    local mixed = false
    if self._mixedIcon then --If we had selected mixture of units that are enabled and not-enabled, then get rid of the quesiton mark icon created on selecting the units
        mixed = true
        self._mixedIcon:Destroy()
        self._mixedIcon = nil
    end

    ToggleScriptBit(currentSelection, self._data.extraInfo, state)

    if controls.mouseoverDisplay.text then
        controls.mouseoverDisplay.text:SetText(self._curHelpText)
    end
    if subState == nil then
        Checkbox.OnClick(self) --alternates between enabled and disabled
    end
    --See SimCallbacks.lua for below
    SimCallback({Func = 'M28TestCallback', Args = {Enable = not(state)} }, true) --Runs function that updates a variable against the unit, as well as updating variable that can be accessed from UI (via GetStat('M28Active, 0)) so we can track in the SIM whether the button is enabled or not
end

local function M28ScriptButtonInitFunction(control, unitList, subCheck)
    --This runs when units are selected; it includes logic for checking if the button should be enabled or disabled (or if we have a mixture in our selection such that a question mark should be shown)
    local result = nil
    local mixed = false
    local bHaveTrueValue = false
    local bHaveFalseValue = false
    for i, v in unitList do
        --LOG('Considering unit with entityID='..v:GetEntityId()..'; GetStat='..reprs(v:GetStat('M28Active', 0).Value or 0))
        local iUnitStatus = (v:GetStat('M28Active', 0).Value or 0)
        if iUnitStatus == 0 then
            bHaveFalseValue = true
        else
            bHaveTrueValue = true
        end
    end
    if bHaveFalseValue and bHaveTrueValue then
        mixed = true
        result = true
    elseif bHaveTrueValue then result = true
    else result = false
    end

    if mixed then
        control._mixedIcon = Bitmap(control, UIUtil.UIFile('/game/orders-panel/question-mark_bmp.dds'))
        LayoutHelpers.AtRightTopIn(control._mixedIcon, control, -2, 2)
    end
    control:SetCheck(result)
end

--extraInfo == 7 - this is used by blacksun only, so wouldn't expect it to cause issues more generally
defaultOrdersTable['M28Toggle'] = {                       helpText = "M28Toggle",  bitmapId = 'M28charge',                 preferredSlot = 10,  behavior = M28AIToggle, initialStateFunc = M28ScriptButtonInitFunction, extraInfo = 7}

function CreateAltOrders(availableOrders, availableToggles, units)
    --Following is a copy of the FAF CreateAltOrders as at 2024-08-23 (with modification to add in a button for M28AI), refer to FAF for the copyright relating to this
    --the orders.lua file specifically has the copyright notice:
    -----------------------------------------------------------------
    -- File: lua/modules/ui/game/orders.lua
    -- Author: Chris Blackwell
    -- Summary: Unit orders UI
    -- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
    -----------------------------------------------------------------

    -- TODO? it would indeed be easier if the alt orders slot was in the blueprint, but for now try
    -- to determine where they go by using preferred slots
    --ADDED FOR LOUD
    --LOG('About to define M28AddAbilityButtons')

    M28AddAbilityButtons = function(standardOrdersTable, availableOrders, units)
        -- Look for units in the selection that have special ability buttons
        -- If any are found, add the ability information to the standard order table
        if units and categories.ABILITYBUTTON and EntityCategoryFilterDown(categories.ABILITYBUTTON, units) then
            for index, unit in units do
                local tempBP = UnitData[unit:GetEntityId()]
                if tempBP.Abilities then
                    for abilityIndex, ability in tempBP.Abilities do
                        if ability.Active ~= false then
                            table.insert(availableOrders, abilityIndex)
                            standardOrdersTable[abilityIndex] = table.merged(ability, import("/lua/abilitydefinition.lua").abilities[abilityIndex])
                            standardOrdersTable[abilityIndex].behavior = AbilityButtonBehavior
                        end
                    end
                end
            end
        end
    end
    --LOG('Finished defining M28AddAbilityButtons')

    M28AddAbilityButtons(standardOrdersTable, availableOrders, units)

    local assistingUnitList = {}

    --- Pods
    local podUnits = {}
    local podStagingPlatforms = EntityCategoryFilterDown(categories.PODSTAGINGPLATFORM, units)
    local pods = EntityCategoryFilterDown(categories.POD, units)
    if not table.empty(units) and (not table.empty(podStagingPlatforms) or not table.empty(pods)) then
        local assistingUnits = {}
        if not table.empty(pods) then
            for _, pod in pods do
                table.insert(assistingUnits, pod:GetCreator())
            end
            podUnits['DroneL'] = pods
        elseif not table.empty(podStagingPlatforms) then
            assistingUnits = GetAssistingUnitsList(podStagingPlatforms)
            podUnits['DroneL'] = assistingUnits
        end


        if not table.empty(assistingUnits) then
            if table.getn(podStagingPlatforms) == 1 and table.empty(pods) then
                table.insert(availableOrders, 'DroneL')
                assistingUnitList['DroneL'] = {assistingUnits[1]}
                if table.getn(assistingUnits) > 1 then
                    table.insert(availableOrders, 'DroneR')
                    assistingUnitList['DroneR'] = {assistingUnits[2]}
                    podUnits['DroneL'] = {assistingUnits[1]}
                    podUnits['DroneR'] = {assistingUnits[2]}
                end
            else
                table.insert(availableOrders, 'DroneL')
                assistingUnitList['DroneL'] = assistingUnits
            end
        end
    end

    --- External factories
    local exFacs = EntityCategoryFilterDown(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, units)
    if not table.empty(exFacs) and table.getn(exFacs) == table.getn(units) then
        -- make sure we've selected all external factories, or all external factory units
        if table.getn(EntityCategoryFilterDown(categories.EXTERNALFACTORY, exFacs)) == table.getn(units) or
                table.getn(EntityCategoryFilterDown(categories.EXTERNALFACTORYUNIT, exFacs)) == table.getn(units) then
            assistingUnitList['ExFac'] = {}
            -- finally, make sure our units are all of the same type
            local bp = exFacs[1]:GetUnitId()
            if table.getn(EntityCategoryFilterDown(categories[bp], exFacs)) == table.getn(exFacs) then
                for _, exFac in exFacs do
                    table.insert(assistingUnitList['ExFac'], exFac:GetCreator())
                end
                table.insert(availableOrders, 'ExFac')
            end
        end
    end

    ----------------------------------START OF ADDED CODE------------------------
    --M28AI toggle
    local iCategoriesToSearch = categories.ALLUNITS - categories.UNSELECTABLE
    if categories.ope6006 then iCategoriesToSearch = iCategoriesToSearch - categories.ope6006 end --excludes black sun as it uses the special rule (that we use for toggling M28AI), in case there might be compatibility issues
    if categories.uec1901 then iCategoriesToSearch = iCategoriesToSearch - categories.uec1901 end --(second black sun unit that uses rule 7)
    local M28Units = EntityCategoryFilterDown(iCategoriesToSearch, units)
    if not table.empty(M28Units) then
        assistingUnitList['M28Toggle'] = {}
        for _, Unit in M28Units do
            table.insert(assistingUnitList['M28Toggle'], Unit:GetCreator())
        end
        table.insert(availableOrders, 'M28Toggle')
    end
    ----------------------------------END OF ADDED CODE------------------------

    -- Determine what slots to put alt orders
    -- We first want a table of slots we want to fill, and what orders want to fill them
    local desiredSlot = {}
    local usedSpecials = {}
    for index, availOrder in availableOrders do
        if standardOrdersTable[availOrder] then
            local preferredSlot = standardOrdersTable[availOrder].preferredSlot
            if not desiredSlot[preferredSlot] then
                desiredSlot[preferredSlot] = {}
            end
            table.insert(desiredSlot[preferredSlot], availOrder)
        else
            if specialOrdersTable[availOrder] ~= nil then
                specialOrdersTable[availOrder].behavior()
                usedSpecials[availOrder] = true
            end
        end
    end

    for index, availToggle in availableToggles do
        if standardOrdersTable[availToggle] then
            local preferredSlot = standardOrdersTable[availToggle].preferredSlot
            if not desiredSlot[preferredSlot] then
                desiredSlot[preferredSlot] = {}
            end
            table.insert(desiredSlot[preferredSlot], availToggle)
        else
            if specialOrdersTable[availToggle] ~= nil then
                specialOrdersTable[availToggle].behavior()
                usedSpecials[availToggle] = true
            end
        end
    end

    for i, specialOrder in specialOrdersTable do
        if not usedSpecials[i] and specialOrder.notAvailableBehavior then
            specialOrder.notAvailableBehavior()
        end
    end

    -- Now go through that table and determine what doesn't fit and look for slots that are empty
    -- Since this is only alt orders, just deal with slots 7-12
    local orderInSlot = {}

    -- Go through first time and add all the first entries to their preferred slot
    for slot = firstAltSlot, numSlots do
        if desiredSlot[slot] then
            orderInSlot[slot] = desiredSlot[slot][1]
        end
    end

    -- Now put any additional entries wherever they will fit
    for slot = firstAltSlot, numSlots do
        if desiredSlot[slot] and table.getn(desiredSlot[slot]) > 1 then
            for index, item in desiredSlot[slot] do
                if index > 1 then
                    local foundFreeSlot = false
                    for newSlot = firstAltSlot, numSlots do
                        if not orderInSlot[newSlot] then
                            orderInSlot[newSlot] = item
                            foundFreeSlot = true
                            break
                        end
                    end
                    if not foundFreeSlot then
                        SPEW("No free slot for order: " .. item)
                        -- Could break here, but don't, then you'll know how many extra orders you have
                    end
                end
            end
        end
    end

    -- Now map it the other direction so it's order to slot
    local slotForOrder = {}
    for slot, order in orderInSlot do
        slotForOrder[order] = slot
    end

    -- Create the alt order buttons
    for index, availOrder in availableOrders do
        if not standardOrdersTable[availOrder] then continue end -- Skip any orders we don't have in our table
        if not commonOrders[availOrder] and slotForOrder[availOrder] ~= nil then
            local orderInfo = standardOrdersTable[availOrder] or AbilityInformation[availOrder]
            local orderCheckbox = AddOrder(orderInfo, slotForOrder[availOrder], true)

            orderCheckbox._order = availOrder

            if standardOrdersTable[availOrder].script then
                orderCheckbox._script = standardOrdersTable[availOrder].script
            end

            if standardOrdersTable[availOrder].cursor then
                orderCheckbox._cursor = standardOrdersTable[availOrder].cursor
            end

            if assistingUnitList[availOrder] then
                orderCheckbox._unit = assistingUnitList[availOrder]
            end

            if podUnits[availOrder] then
                orderCheckbox._pod = podUnits[availOrder]
            end

            if orderInfo.initialStateFunc then
                orderInfo.initialStateFunc(orderCheckbox, currentSelection)
            end

            orderCheckboxMap[availOrder] = orderCheckbox
        end
    end

    for index, availToggle in availableToggles do
        if not standardOrdersTable[availToggle] then continue end -- Skip any orders we don't have in our table
        if not commonOrders[availToggle] and slotForOrder[availToggle] ~= nil then
            local orderInfo = standardOrdersTable[availToggle] or AbilityInformation[availToggle]
            local orderCheckbox = AddOrder(orderInfo, slotForOrder[availToggle], true)

            orderCheckbox._order = availToggle

            if standardOrdersTable[availToggle].script then
                orderCheckbox._script = standardOrdersTable[availToggle].script
            end

            if assistingUnitList[availToggle] then
                orderCheckbox._unit = assistingUnitList[availToggle]
            end

            if orderInfo.initialStateFunc then
                orderInfo.initialStateFunc(orderCheckbox, currentSelection)
            end

            orderCheckboxMap[availToggle] = orderCheckbox
        end
    end
end