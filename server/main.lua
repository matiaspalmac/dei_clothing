-----------------------------------------------------------
-- RATE LIMITING
-----------------------------------------------------------
local cooldowns = {}
local function checkCooldown(src, action, seconds)
    local key = src .. ':' .. action
    local now = os.time()
    if cooldowns[key] and (now - cooldowns[key]) < seconds then return false end
    cooldowns[key] = now
    return true
end

local payLocks = {}

-----------------------------------------------------------
-- OUTFIT PERSISTENCE (KVP by license)
-----------------------------------------------------------

local function getOutfitKey(license)
    return 'dei_clothing:outfits:' .. license
end

local function getSkinKey(license)
    return 'dei_clothing:skin:' .. license
end

local function getPlayerOutfits(license)
    local raw = GetResourceKvpString(getOutfitKey(license))
    if raw and raw ~= '' then
        return json.decode(raw) or {}
    end
    return {}
end

local function savePlayerOutfits(license, outfits)
    SetResourceKvp(getOutfitKey(license), json.encode(outfits))
end

-----------------------------------------------------------
-- EVENTS
-----------------------------------------------------------

-- Save outfit
RegisterNetEvent('dei_clothing:saveOutfit', function(name, appearance)
    local src = source
    if not checkCooldown(src, 'saveOutfit', 2) then return end

    -- Validate outfit name
    if type(name) ~= 'string' or #name == 0 then return end
    name = string.sub(name, 1, 50)
    name = name:gsub('[^%w%s%-_]', '')
    if name == '' then return end

    -- Validate appearance data
    if type(appearance) ~= 'table' then return end
    local json_str = json.encode(appearance)
    if #json_str > 10000 then return end

    local license = GetPlayerLicense(src)
    if not license then
        TriggerClientEvent('dei_clothing:outfitSaved', src, false, {})
        return
    end

    local outfits = getPlayerOutfits(license)

    -- Check max outfits
    if #outfits >= Config.MaxOutfits then
        -- Replace if same name exists, otherwise reject
        local replaced = false
        for i, outfit in ipairs(outfits) do
            if outfit.name == name then
                outfits[i].data = appearance
                replaced = true
                break
            end
        end
        if not replaced then
            TriggerClientEvent('dei_clothing:outfitSaved', src, false, outfits)
            return
        end
    else
        -- Check for duplicate name
        local found = false
        for i, outfit in ipairs(outfits) do
            if outfit.name == name then
                outfits[i].data = appearance
                found = true
                break
            end
        end
        if not found then
            table.insert(outfits, { name = name, data = appearance })
        end
    end

    savePlayerOutfits(license, outfits)

    -- Return sanitized list (name only for UI)
    local outfitList = {}
    for _, o in ipairs(outfits) do
        table.insert(outfitList, { name = o.name, data = o.data })
    end

    TriggerClientEvent('dei_clothing:outfitSaved', src, true, outfitList)
end)

-- Get outfits
RegisterNetEvent('dei_clothing:getOutfits', function()
    local src = source
    local license = GetPlayerLicense(src)
    if not license then
        TriggerClientEvent('dei_clothing:receiveOutfits', src, {})
        return
    end

    local outfits = getPlayerOutfits(license)
    TriggerClientEvent('dei_clothing:receiveOutfits', src, outfits)
end)

-- Delete outfit
RegisterNetEvent('dei_clothing:deleteOutfit', function(name)
    local src = source
    local license = GetPlayerLicense(src)
    if not license then
        TriggerClientEvent('dei_clothing:outfitDeleted', src, false, {})
        return
    end

    local outfits = getPlayerOutfits(license)
    local newOutfits = {}
    for _, o in ipairs(outfits) do
        if o.name ~= name then
            table.insert(newOutfits, o)
        end
    end

    savePlayerOutfits(license, newOutfits)
    TriggerClientEvent('dei_clothing:outfitDeleted', src, true, newOutfits)
end)

-- Pay for clothing (deprecated: payment is now handled in saveSkin)
RegisterNetEvent('dei_clothing:pay', function()
    -- Deprecated: payment is now handled atomically in saveSkin
    return
end)

-- Save current skin (with atomic payment)
RegisterNetEvent('dei_clothing:saveSkin', function(appearance, storeIndex)
    local src = source
    if not checkCooldown(src, 'saveSkin', 2) then return end
    if type(appearance) ~= 'table' then return end
    local json_str = json.encode(appearance)
    if #json_str > 10000 then return end

    -- Handle payment if at a paid store
    if storeIndex and Config.EnablePricing and Config.FlatFee > 0 then
        local isFree = false
        if type(storeIndex) == 'string' and storeIndex == 'wardrobe' then
            isFree = true
        end
        if not isFree then
            local playerJob = GetPlayerJobSv(src)
            for _, freeJob in ipairs(Config.FreeJobs or {}) do
                if playerJob == freeJob then isFree = true break end
            end
        end
        if not isFree then
            local success = RemoveMoney(src, Config.FlatFee)
            if not success then
                TriggerClientEvent('dei_clothing:saveSkinResult', src, false)
                return
            end
        end
    end

    -- Save skin
    local license = GetPlayerLicense(src)
    if not license then return end
    SetResourceKvp(getSkinKey(license), json_str)
    TriggerClientEvent('dei_clothing:saveSkinResult', src, true)
end)

-- Load skin on player join
RegisterNetEvent('dei_clothing:requestSkin', function()
    local src = source
    local license = GetPlayerLicense(src)
    if not license then return end

    local raw = GetResourceKvpString(getSkinKey(license))
    if raw and raw ~= '' then
        local appearance = json.decode(raw)
        if appearance then
            TriggerClientEvent('dei_clothing:applySkin', src, appearance)
        end
    end
end)

-- Cleanup on player drop
AddEventHandler('playerDropped', function()
    local src = source
    payLocks[src] = nil
    for key in pairs(cooldowns) do
        if key:find('^' .. src .. ':') then cooldowns[key] = nil end
    end
end)

-- ============================================================
-- Dei Ecosystem - Startup
-- ============================================================
CreateThread(function()
    Wait(500)
    local v = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0'
    print('^4[Dei]^0 dei_clothing v' .. v .. ' - ^2Iniciado^0')
end)
