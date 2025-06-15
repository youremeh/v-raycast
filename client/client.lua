local screenX = 0.75
local screenY = 0.5
local enabled = false
local lastEntityPos = vector3(0, 0, 0)
local boundingBoxCache = nil
local lastUpdateTime = 0
local activeTasksCache = {}
local boxcolor = Config.BoxColor
local linecolor = Config.LineColor
local highlightedlinecolor = Config.HighlightedLineColor

RegisterNetEvent('v-raycast:client:toggle')
AddEventHandler('v-raycast:client:toggle', function() enabled = not enabled end)

local function RotationToDirection(rotation)
    local radRotation = vector3(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
    return vector3(-math.sin(radRotation.z) * math.abs(math.cos(radRotation.x)), math.cos(radRotation.z) * math.abs(math.cos(radRotation.x)), math.sin(radRotation.x))
end

local function RayCastGamePlayCamera(distance)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local direction = RotationToDirection(camRot)
    local dest = camPos + (direction * distance)
    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords, _, entity = GetShapeTestResult(rayHandle)
    return hit, endCoords, entity
end

local function GetEntityBoundingBox(entity)
    local currentPos = GetEntityCoords(entity)
    if #(currentPos - lastEntityPos) > 0.3 then
        local min, max = GetModelDimensions(GetEntityModel(entity))
        local pad = 0.001
        boundingBoxCache = {
            vector3(GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, min.z - pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, max.x + pad, min.y - pad, min.z - pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, min.z - pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, min.x - pad, max.y + pad, min.z - pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, max.z + pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, max.x + pad, min.y - pad, max.z + pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, max.z + pad)),
            vector3(GetOffsetFromEntityInWorldCoords(entity, min.x - pad, max.y + pad, max.z + pad))
        }
        lastEntityPos = currentPos
    end
    return boundingBoxCache
end

local function DrawEntityBoundingBox(entity)
    if not DoesEntityExist(entity) then return end
    local model = GetEntityModel(entity)
    if not model or model == 0 then return end
    local min, max = GetModelDimensions(model)
    local frontBottomLeft = GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, min.z)
    local frontBottomRight = GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, min.z)
    local backBottomLeft = GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, min.z)
    local backBottomRight = GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, min.z)
    local frontTopLeft = GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, max.z)
    local frontTopRight = GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, max.z)
    local backTopLeft = GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, max.z)
    local backTopRight = GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, max.z)
    local function DrawEdge(p1, p2, r, g, b, a) DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, r, g, b, a) end
    local edgeColor = boxcolor
    DrawEdge(frontBottomLeft, frontBottomRight, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(frontBottomRight, backBottomRight, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(backBottomRight, backBottomLeft, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(backBottomLeft, frontBottomLeft, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(frontTopLeft, frontTopRight, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(frontTopRight, backTopRight, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(backTopRight, backTopLeft, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(backTopLeft, frontTopLeft, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(frontBottomLeft, frontTopLeft, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(frontBottomRight, frontTopRight, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(backBottomLeft, backTopLeft, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
    DrawEdge(backBottomRight, backTopRight, edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a)
end

local function GetActiveTasks(entity)
    local currentTime = GetGameTimer()
    if currentTime - lastUpdateTime > 500 then
        lastUpdateTime = currentTime
        activeTasksCache = {}
        for id, task in pairs(allTasks) do
            if GetIsTaskActive(entity, id) then table.insert(activeTasksCache, task) end
        end
    end
    return activeTasksCache
end

local function Draw2DText(x, y, text)
    SetTextScale(0.55, 0.55)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

CreateThread(function()
    while true do
        local waitTime = enabled and 5 or 1000
        if enabled then
            local hit, endCoords, entity = RayCastGamePlayCamera(1000.0)
            local startCoords = GetEntityCoords(PlayerPedId())
            local color = linecolor
            if hit == 1 then
                if entity and DoesEntityExist(entity) and entity ~= 0 and (IsEntityAnObject(entity) or IsEntityAVehicle(entity) or IsEntityAPed(entity)) then
                    color = highlightedlinecolor
                    local entityHash = GetEntityModel(entity)
                    local coords = GetEntityCoords(entity)
                    local heading = GetEntityHeading(entity)
                    if IsEntityAVehicle(entity) then
                        local plate = GetVehicleNumberPlateText(entity)
                        Draw2DText(screenX, screenY + 0.065, 'Plate: ' .. plate)
                    elseif IsEntityAPed(entity) then
                        local taskNames = GetActiveTasks(entity)
                        local taskText = 'Tasks: ' .. table.concat(taskNames, ', ')
                        Draw2DText(screenX, screenY + 0.065, taskText)
                    end
                    Draw2DText(screenX, screenY, 'Raycast Coords: ' .. string.format('%.2f, %.2f, %.2f, %.2f', coords.x, coords.y, coords.z, heading) .. '\nHash: ' .. entityHash .. '\n Press [E] to copy raycast')
                    if IsControlJustPressed(0, 46) then -- E key
                        local data = string.format('%.2f, %.2f, %.2f', endCoords.x, endCoords.y, endCoords.z)
                        lib.setClipboard(data)
                    end
                    DrawEntityBoundingBox(entity)
                else
                    Draw2DText(screenX, screenY, 'Raycast: ' .. string.format('%.2f, %.2f, %.2f', endCoords.x, endCoords.y, endCoords.z) .. '\n Press [E] to copy raycast')
                    if IsControlJustPressed(0, 46) then -- E key
                        local data = string.format('%.2f, %.2f, %.2f', endCoords.x, endCoords.y, endCoords.z)
                        lib.setClipboard(data)
                    end
                end
                DrawLine(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, color.r, color.g, color.b, color.a)
                DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
            end
        end
        Wait(waitTime)
    end
end)