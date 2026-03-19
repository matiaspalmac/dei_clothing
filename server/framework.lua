FrameworkSv = nil

CreateThread(function()
    if Config.Framework == 'esx' then
        FrameworkSv = exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb' then
        FrameworkSv = exports['qb-core']:GetCoreObject()
    end
end)

function GetPlayerLicense(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

function GetPlayerJobSv(src)
    if Config.Framework == 'esx' then
        local xPlayer = FrameworkSv.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then return xPlayer.job.name end
    elseif Config.Framework == 'qb' then
        local player = FrameworkSv.Functions.GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.job then return player.PlayerData.job.name end
    end
    return nil
end

function RemoveMoney(src, amount)
    if Config.Framework == 'esx' then
        local xPlayer = FrameworkSv.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeMoney(amount)
            return true
        end
    elseif Config.Framework == 'qb' then
        local player = FrameworkSv.Functions.GetPlayer(src)
        if player then
            player.Functions.RemoveMoney('cash', amount)
            return true
        end
    end
    return false
end
