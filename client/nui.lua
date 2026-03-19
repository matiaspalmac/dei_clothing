-----------------------------------------------------------
-- NUI CALLBACKS
-----------------------------------------------------------

-- Change component (drawable or texture)
RegisterNUICallback('changeComponent', function(data, cb)
    local ped = PlayerPedId()
    local compId = tonumber(data.id)
    local drawable = tonumber(data.drawable)
    local texture = tonumber(data.texture)

    SetPedComponentVariation(ped, compId, drawable, texture, 2)

    -- Return updated texture info
    local maxTexture = GetNumberOfPedTextureVariations(ped, compId, drawable)
    local curTexture = GetPedTextureVariation(ped, compId)

    cb({ maxTexture = maxTexture, currentTexture = curTexture })
end)

-- Change prop
RegisterNUICallback('changeProp', function(data, cb)
    local ped = PlayerPedId()
    local propId = tonumber(data.id)
    local drawable = tonumber(data.drawable)
    local texture = tonumber(data.texture)

    if drawable < 0 then
        ClearPedProp(ped, propId)
        cb({ maxTexture = 0, currentTexture = 0 })
        return
    end

    SetPedPropIndex(ped, propId, drawable, texture, true)

    local maxTexture = GetNumberOfPedPropTextureVariations(ped, propId, drawable)
    local curTexture = GetPedPropTextureIndex(ped, propId)

    cb({ maxTexture = maxTexture, currentTexture = curTexture })
end)

-- Camera zone change
RegisterNUICallback('setCameraZone', function(data, cb)
    local zone = data.zone or 'full'
    CreateThread(function()
        TransitionCamera(zone)
    end)
    cb('ok')
end)

-- Rotate camera / ped heading
RegisterNUICallback('rotateCamera', function(data, cb)
    local delta = tonumber(data.delta) or 0
    pedHeading = pedHeading + delta
    if pedHeading > 360 then pedHeading = pedHeading - 360 end
    if pedHeading < 0 then pedHeading = pedHeading + 360 end
    cb('ok')
end)

-- Pending callback variables for outfit operations (avoid event handler stacking)
local pendingSaveCb = nil
local pendingLoadCb = nil
local pendingDeleteCb = nil

RegisterNetEvent('dei_clothing:outfitSaved', function(success, outfits)
    if pendingSaveCb then
        pendingSaveCb(success, outfits)
        pendingSaveCb = nil
    end
end)

RegisterNetEvent('dei_clothing:receiveOutfits', function(outfits)
    if pendingLoadCb then
        pendingLoadCb(outfits)
        pendingLoadCb = nil
    end
end)

RegisterNetEvent('dei_clothing:outfitDeleted', function(success, outfits)
    if pendingDeleteCb then
        pendingDeleteCb(success, outfits)
        pendingDeleteCb = nil
    end
end)

-- Save outfit
RegisterNUICallback('saveOutfit', function(data, cb)
    local name = data.name
    if not name or name == '' then
        cb({ success = false, error = 'Nombre vacio' })
        return
    end

    local appearance = GetCurrentAppearance()
    TriggerServerEvent('dei_clothing:saveOutfit', name, appearance)

    local responded = false
    pendingSaveCb = function(success, outfits)
        responded = true
        if success then
            Notify('Outfit guardado: ' .. name, 'success')
            cb({ success = true, outfits = outfits })
        else
            Notify('Error al guardar outfit', 'error')
            cb({ success = false, error = 'Error del servidor' })
        end
    end

    -- Timeout
    SetTimeout(5000, function()
        if not responded then
            pendingSaveCb = nil
            cb({ success = false, error = 'Timeout' })
        end
    end)
end)

-- Load outfits list
RegisterNUICallback('loadOutfits', function(_, cb)
    TriggerServerEvent('dei_clothing:getOutfits')

    pendingLoadCb = function(outfits)
        cb({ outfits = outfits or {} })
    end
end)

-- Apply outfit
RegisterNUICallback('loadOutfit', function(data, cb)
    local outfitData = data.outfit
    if outfitData then
        ApplyAppearance(outfitData)
        Notify('Outfit aplicado', 'success')
    end
    cb('ok')
end)

-- Delete outfit
RegisterNUICallback('deleteOutfit', function(data, cb)
    local outfitName = data.name
    TriggerServerEvent('dei_clothing:deleteOutfit', outfitName)

    pendingDeleteCb = function(success, outfits)
        if success then
            Notify('Outfit eliminado', 'success')
            cb({ success = true, outfits = outfits })
        else
            cb({ success = false })
        end
    end
end)

-- Confirm purchase (atomic payment + save)
local pendingSaveSkinCb = nil

RegisterNetEvent('dei_clothing:saveSkinResult', function(success)
    if pendingSaveSkinCb then
        pendingSaveSkinCb(success)
        pendingSaveSkinCb = nil
    end
end)

RegisterNUICallback('confirmPurchase', function(_, cb)
    if not isFree and Config.EnablePricing and Config.FlatFee > 0 then
        local money = GetPlayerMoney()
        if money < Config.FlatFee then
            Notify('No tienes suficiente dinero ($' .. Config.FlatFee .. ')', 'error')
            cb({ success = false, error = 'Sin dinero' })
            return
        end
    end

    -- Save appearance server-side with store context for atomic payment
    local appearance = GetCurrentAppearance()
    local storeContext = isFree and 'wardrobe' or 'store'
    TriggerServerEvent('dei_clothing:saveSkin', appearance, storeContext)

    local responded = false
    pendingSaveSkinCb = function(success)
        responded = true
        if success then
            Notify('Apariencia actualizada', 'success')
            CloseClothing(false)
            cb({ success = true })
        else
            Notify('No tienes suficiente dinero ($' .. Config.FlatFee .. ')', 'error')
            cb({ success = false, error = 'Pago fallido' })
        end
    end

    -- Timeout fallback
    SetTimeout(5000, function()
        if not responded then
            pendingSaveSkinCb = nil
            Notify('Apariencia actualizada', 'success')
            CloseClothing(false)
            cb({ success = true })
        end
    end)
end)

-- Cancel
RegisterNUICallback('cancelClothing', function(_, cb)
    CloseClothing(true)
    Notify('Cambios descartados', 'info')
    cb('ok')
end)

-- Close
RegisterNUICallback('closeClothing', function(_, cb)
    CloseClothing(true)
    cb('ok')
end)

-- Get component info for refreshing max values
RegisterNUICallback('getComponentInfo', function(data, cb)
    local ped = PlayerPedId()
    local itemType = data.type
    local id = tonumber(data.id)
    local drawable = tonumber(data.drawable)

    if itemType == 'component' then
        local maxTexture = GetNumberOfPedTextureVariations(ped, id, drawable)
        cb({ maxTexture = maxTexture })
    else
        local maxTexture = GetNumberOfPedPropTextureVariations(ped, id, drawable)
        cb({ maxTexture = maxTexture })
    end
end)
