local radius = 3.5
local trunkBoneName = "boot" -- Name of the Trunk Bone
local menuActive = false
local displayText = true
local menuOptions = {
    [1] = {label = "Equip Traffic Vest", item = "traffic_vest"},
    [2] = {label = "Equip Less Than Lethal Shotgun", item = "less_lethal_shotgun"},
    [3] = {label = "Equip Fire Extinguisher", item = "fire_extinguisher"},
    [4] = {label = "Equip Road Flare(s)", item = "road_flare"},
    [5] = {label = "Equip Assualt Rifle", item = "assualt_rifle"},
}
local selectedOption = 1
local vehicle = nil

function DrawTextUI(x, y, text)
    SetTextScale(0.0, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

function GetTrunkPosition()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = nil
    local closestDistance = radius

    -- Get all nearby vehicles within the defined radius
    local vehicles = GetGamePool("CVehicle")

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local model = GetEntityModel(vehicle)
        local vehicleClass = GetVehicleClassFromName(model)

        -- Check if the vehicle class is an emergency vehicle class (9 or 18)
        if vehicleClass == 9 or vehicleClass == 18 then
            local distance = GetDistanceBetweenCoords(playerCoords, GetEntityCoords(vehicle), true)

            if distance <= closestDistance then
                closestDistance = distance
                closestVehicle = vehicle
            end
        end
    end

    if closestVehicle ~= nil then
        local trunkPos = GetWorldPositionOfEntityBone(closestVehicle, GetEntityBoneIndexByName(closestVehicle, trunkBoneName))

        if trunkPos ~= nil then
            return trunkPos, closestVehicle
        end
    end

    return nil, nil
end

function OpenTrunkMenu(vehicle)
    menuActive = true
    selectedOption = 1

    while menuActive do
        Citizen.Wait(0)
        local trunkPos = GetTrunkPosition()

        if trunkPos ~= nil and DoesEntityExist(vehicle) then
            local onScreen, screenX, screenY = World3dToScreen2d(trunkPos.x, trunkPos.y, trunkPos.z + 0.5)

            if onScreen then
                DrawTextUI(screenX, screenY, menuOptions[selectedOption].label)

                if IsControlJustPressed(0, 172) then -- Arrow Up
                    if selectedOption > 1 then
                        selectedOption = selectedOption - 1
                    else
                        selectedOption = #menuOptions
                    end
                elseif IsControlJustPressed(0, 173) then -- Arrow Down
                    if selectedOption < #menuOptions then
                        selectedOption = selectedOption + 1
                    else
                        selectedOption = 1
                    end
                elseif IsControlJustPressed(0, 176) then -- Enter
                    local item = menuOptions[selectedOption].item
                    -- Perform the desired action based on the selected option
                    if item == "traffic_vest" then
                        -- Equip Traffic Vest
                        SetPedComponentVariation(PlayerPedId(), 9, 3, 0, 0)
                        -- TODO: Add your implementation here
                    elseif item == "less_lethal_shotgun" then
                        GiveWeaponToPed(PlayerPedId(), GetHashKey("weapon_pumpshotgun"), 28, false, true) -- Equip Less Than Lethal Shotgun
                    elseif item == "assualt_rifle" then
                        GiveWeaponToPed(PlayerPedId(), GetHashKey("weapon_carbinerifle"), 120, false, true) -- Equips Assualt Rifle
                    elseif item == "fire_extinguisher" then
                        GiveWeaponToPed(PlayerPedId(), GetHashKey("weapon_fireextinguisher"), 100, false, true)-- Equip Fire Extinguisher
                    elseif item == "road_flare" then
                        GiveWeaponToPed(PlayerPedId(), GetHashKey("weapon_flare"), 2, false, true) -- Equip Road Flare(s)
                    end

                    local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
                    local animName = "machinic_loop_mechandplayer"
                    local duration = 1500 -- Animation duration in milliseconds

                    RequestAnimDict(animDict)
                    while not HasAnimDictLoaded(animDict) do
                        Citizen.Wait(0)
                    end

                    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, duration, 16, 0, false, false, false)

                elseif IsControlJustPressed(0, 177) then -- Backspace
                    menuActive = false
                    displayText = true -- Show the "Press E to open the trunk" text again
                    SetVehicleDoorShut(vehicle, 5, false)
                    vehicle = nil
                    break
                end
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()

        -- Check if the player is in a vehicle
        if not IsPedInAnyVehicle(playerPed, false) then
            local trunkPos, closestVehicle = GetTrunkPosition()

            if trunkPos ~= nil then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = GetDistanceBetweenCoords(playerCoords, trunkPos.x, trunkPos.y, trunkPos.z, true)

                if distance <= radius then
                    if displayText then
                        local onScreen, screenX, screenY = World3dToScreen2d(trunkPos.x, trunkPos.y, trunkPos.z + 0.5)

                        if onScreen then
                            DrawTextUI(screenX, screenY, "Press E to open the trunk")

                            if IsControlJustPressed(0, 38) then -- Check if the "E" key is pressed
                                SetVehicleDoorOpen(closestVehicle, 5, false, false) -- Open the trunk
                                vehicle = closestVehicle
                                menuActive = true
                                displayText = false
                                OpenTrunkMenu(vehicle)
                            end
                        end
                    end
                end
            end
        else
            -- Player is in a vehicle, close the trunk if it was opened
            if vehicle ~= nil then
                SetVehicleDoorShut(vehicle, 5, false)
                vehicle = nil
            end
        end
        -- Check if the player moves away from the trunk's radius or enters a vehicle
        if vehicle ~= nil then
            local trunkPos = GetTrunkPosition()

            if trunkPos ~= nil then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = GetDistanceBetweenCoords(playerCoords, trunkPos.x, trunkPos.y, trunkPos.z, true)

                if distance > radius or IsPedInAnyVehicle(playerPed, false) then
                    SetVehicleDoorShut(vehicle, 5, false)
                    vehicle = nil
                    equipItem = false -- Reset equip item flag
                    menuActive = false -- Close the trunk menu
                end
            end
        end
    end
end)