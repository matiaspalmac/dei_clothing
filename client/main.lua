local isOpen = false
local currentStore = nil
local isFree = false
local originalComponents = {}
local originalProps = {}
local currentCam = nil
local currentZone = 'full'
local pedHeading = 0.0

-----------------------------------------------------------
-- BLIPS
-----------------------------------------------------------
CreateThread(function()
    if not Config.ShowBlips then return end
    for _, store in ipairs(Config.Stores) do
        if store.blip then
            local blip = AddBlipForCoord(store.coords.x, store.coords.y, store.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipColour(blip, Config.BlipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(store.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-----------------------------------------------------------
-- INTERACTION LOOP
-----------------------------------------------------------
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not isOpen then
            -- Stores
            for i, store in ipairs(Config.Stores) do
                local dist = #(playerCoords - store.coords)
                if dist < Config.InteractDistance then
                    sleep = 0
                    DrawMarker(20, store.coords.x, store.coords.y, store.coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.5, 59, 130, 246, 120, false, true, 2, false, nil, nil, false)
                    if IsControlJustReleased(0, Config.InteractKey) then
                        OpenClothingStore(i)
                    end
                elseif dist < 10.0 then
                    sleep = 200
                end
            end

            -- Wardrobes
            for _, wardrobe in ipairs(Config.Wardrobes) do
                local dist = #(playerCoords - wardrobe.coords)
                if dist < Config.InteractDistance then
                    sleep = 0
                    local job = GetPlayerJob()
                    local hasAccess = not wardrobe.jobs or #wardrobe.jobs == 0
                    if not hasAccess then
                        for _, j in ipairs(wardrobe.jobs) do
                            if j == job then hasAccess = true break end
                        end
                    end
                    if hasAccess then
                        DrawMarker(20, wardrobe.coords.x, wardrobe.coords.y, wardrobe.coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.5, 74, 222, 128, 120, false, true, 2, false, nil, nil, false)
                        if IsControlJustReleased(0, Config.InteractKey) then
                            OpenWardrobeMenu(wardrobe)
                        end
                    end
                elseif dist < 10.0 then
                    sleep = 200
                end
            end
        end

        Wait(sleep)
    end
end)

-----------------------------------------------------------
-- SAVE / RESTORE APPEARANCE
-----------------------------------------------------------
function SaveCurrentAppearance()
    local ped = PlayerPedId()
    originalComponents = {}
    originalProps = {}

    for compId, _ in pairs(Config.ComponentLabels) do
        originalComponents[compId] = {
            drawable = GetPedDrawableVariation(ped, compId),
            texture = GetPedTextureVariation(ped, compId),
        }
    end

    for propId, _ in pairs(Config.PropLabels) do
        originalProps[propId] = {
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId),
        }
    end
end

function RestoreAppearance()
    local ped = PlayerPedId()
    for compId, data in pairs(originalComponents) do
        SetPedComponentVariation(ped, compId, data.drawable, data.texture, 2)
    end
    for propId, data in pairs(originalProps) do
        if data.drawable == -1 then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, data.drawable, data.texture, true)
        end
    end
end

function GetCurrentAppearance()
    local ped = PlayerPedId()
    local components = {}
    local props = {}

    for compId, _ in pairs(Config.ComponentLabels) do
        components[tostring(compId)] = {
            drawable = GetPedDrawableVariation(ped, compId),
            texture = GetPedTextureVariation(ped, compId),
        }
    end

    for propId, _ in pairs(Config.PropLabels) do
        props[tostring(propId)] = {
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId),
        }
    end

    return { components = components, props = props }
end

function ApplyAppearance(data)
    local ped = PlayerPedId()
    if data.components then
        for compId, info in pairs(data.components) do
            local id = tonumber(compId)
            SetPedComponentVariation(ped, id, info.drawable, info.texture, 2)
        end
    end
    if data.props then
        for propId, info in pairs(data.props) do
            local id = tonumber(propId)
            if info.drawable == -1 then
                ClearPedProp(ped, id)
            else
                SetPedPropIndex(ped, id, info.drawable, info.texture, true)
            end
        end
    end
end

-----------------------------------------------------------
-- CAMERA SYSTEM
-----------------------------------------------------------
function CreateClothingCamera(zone)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    pedHeading = GetEntityHeading(ped)

    local offset = Config.CameraOffsets[zone] or Config.CameraOffsets.full
    local headingRad = math.rad(pedHeading)

    local camDist = 1.8
    local camX = pedCoords.x + math.sin(headingRad) * camDist
    local camY = pedCoords.y + math.cos(headingRad) * camDist
    local camZ = pedCoords.z + offset.z

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camX, camY, camZ, 0.0, 0.0, 0.0, offset.fov, false, 0)
    PointCamAtCoord(cam, pedCoords.x, pedCoords.y, pedCoords.z + offset.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, Config.CameraTransitionSpeed, true, false)

    return cam
end

function TransitionCamera(zone)
    if zone == currentZone then return end
    currentZone = zone

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local offset = Config.CameraOffsets[zone] or Config.CameraOffsets.full
    local headingRad = math.rad(pedHeading)

    local camDist = 1.8
    local camX = pedCoords.x + math.sin(headingRad) * camDist
    local camY = pedCoords.y + math.cos(headingRad) * camDist
    local camZ = pedCoords.z + offset.z

    local newCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camX, camY, camZ, 0.0, 0.0, 0.0, offset.fov, false, 0)
    PointCamAtCoord(newCam, pedCoords.x, pedCoords.y, pedCoords.z + offset.z)
    SetCamActiveWithInterp(newCam, currentCam, Config.CameraTransitionSpeed, 1, 1)

    if currentCam then
        Wait(Config.CameraTransitionSpeed)
        DestroyCam(currentCam, false)
    end

    currentCam = newCam
end

function DestroyClothingCamera()
    if currentCam then
        RenderScriptCams(false, true, Config.CameraTransitionSpeed, true, false)
        DestroyCam(currentCam, false)
        currentCam = nil
    end
    currentZone = 'full'
end

-----------------------------------------------------------
-- OPEN / CLOSE
-----------------------------------------------------------
function OpenClothingStore(storeIndex)
    if isOpen then return end
    local store = Config.Stores[storeIndex]
    if not store then return end

    isOpen = true
    currentStore = store

    -- Check if free
    local job = GetPlayerJob()
    isFree = false
    for _, freeJob in ipairs(Config.FreeJobs) do
        if job == freeJob then isFree = true break end
    end

    SaveCurrentAppearance()

    -- Freeze player and face camera
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    TaskStandStill(ped, -1)

    currentCam = CreateClothingCamera('full')

    -- Build categories for NUI
    local categories = BuildCategories(store.categories)

    SyncTheme()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        storeLabel = store.label,
        categories = categories,
        isFree = isFree,
        flatFee = Config.EnablePricing and Config.FlatFee or 0,
        maxOutfits = Config.MaxOutfits,
    })
end

function OpenWardrobeMenu(wardrobe)
    if isOpen then return end

    isOpen = true
    currentStore = nil
    isFree = true

    SaveCurrentAppearance()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    TaskStandStill(ped, -1)

    currentCam = CreateClothingCamera('full')

    local categories = BuildCategories('all')

    SyncTheme()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        storeLabel = wardrobe.label,
        categories = categories,
        isFree = true,
        flatFee = 0,
        maxOutfits = Config.MaxOutfits,
    })
end

function CloseClothing(revert)
    if not isOpen then return end

    if revert then
        RestoreAppearance()
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    DestroyClothingCamera()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)

    isOpen = false
    currentStore = nil
    isFree = false
end

-----------------------------------------------------------
-- BUILD CATEGORIES
-----------------------------------------------------------
function BuildCategories(filter)
    local ped = PlayerPedId()
    local cats = {}

    -- Components
    for compId, label in pairs(Config.ComponentLabels) do
        local key = string.lower(label:gsub(' ', ''))
        local include = (filter == 'all')
        if not include and type(filter) == 'table' then
            for _, f in ipairs(filter) do
                if string.lower(f) == key or string.lower(f) == string.lower(label) then
                    include = true
                    break
                end
            end
        end

        if include then
            local maxDrawable = GetNumberOfPedDrawableVariations(ped, compId)
            local currentDrawable = GetPedDrawableVariation(ped, compId)
            local maxTexture = GetNumberOfPedTextureVariations(ped, compId, currentDrawable)
            local currentTexture = GetPedTextureVariation(ped, compId)

            table.insert(cats, {
                type = 'component',
                id = compId,
                label = label,
                currentDrawable = currentDrawable,
                maxDrawable = maxDrawable,
                currentTexture = currentTexture,
                maxTexture = maxTexture,
                zone = Config.ComponentCameraZone[compId] or 'full',
            })
        end
    end

    -- Props
    for propId, label in pairs(Config.PropLabels) do
        local key = string.lower(label:gsub(' ', ''))
        local include = (filter == 'all')
        if not include and type(filter) == 'table' then
            for _, f in ipairs(filter) do
                if string.lower(f) == key or string.lower(f) == string.lower(label) then
                    include = true
                    break
                end
            end
        end

        if include then
            local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, propId)
            local currentDrawable = GetPedPropIndex(ped, propId)
            local maxTexture = GetNumberOfPedPropTextureVariations(ped, propId, currentDrawable)
            local currentTexture = GetPedPropTextureIndex(ped, propId)

            table.insert(cats, {
                type = 'prop',
                id = propId,
                label = label,
                currentDrawable = currentDrawable,
                maxDrawable = maxDrawable,
                currentTexture = currentTexture,
                maxTexture = maxTexture,
                zone = Config.PropCameraZone[propId] or 'full',
            })
        end
    end

    -- Sort by a consistent order
    table.sort(cats, function(a, b)
        if a.type == b.type then return a.id < b.id end
        return a.type < b.type
    end)

    return cats
end

-----------------------------------------------------------
-- EXPORTS
-----------------------------------------------------------
function OpenClothing(storeIndex)
    OpenClothingStore(storeIndex or 1)
end

function OpenWardrobe()
    OpenWardrobeMenu({ label = 'Vestuario', coords = GetEntityCoords(PlayerPedId()), free = true })
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    if currentCam and DoesCamExist(currentCam) then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(currentCam, false)
    end
    DisplayHud(true)
    DisplayRadar(true)
end)

-----------------------------------------------------------
-- ROTATE PED (mouse drag from NUI)
-----------------------------------------------------------
CreateThread(function()
    while true do
        if not isOpen then
            Wait(500)
        else
            local ped = PlayerPedId()
            SetEntityHeading(ped, pedHeading)
            DisableAllControlActions(0)
            Wait(0)
        end
    end
end)
