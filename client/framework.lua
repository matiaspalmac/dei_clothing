Framework = nil

CreateThread(function()
    if Config.Framework == 'esx' then
        Framework = exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb' then
        Framework = exports['qb-core']:GetCoreObject()
    end
end)

-- Read theme from dei_hud KVP (shared ecosystem preferences)
local function getSharedTheme()
    local raw = GetResourceKvpString('dei_hud_prefs')
    if raw and raw ~= '' then
        local prefs = json.decode(raw)
        return prefs and prefs.theme or 'dark', prefs and prefs.lightMode or false
    end
    return 'dark', false
end

function SyncTheme()
    local theme, lightMode = getSharedTheme()
    SendNUIMessage({ action = 'setTheme', theme = theme, lightMode = lightMode })
end

CreateThread(function()
    Wait(1500)
    SyncTheme()
end)

RegisterNetEvent('dei:themeChanged', function(theme, lightMode)
    SendNUIMessage({ action = 'setTheme', theme = theme, lightMode = lightMode })
end)

function Notify(msg, type)
    if Config.Notify == 'dei' and GetResourceState('dei_notifys') == 'started' then
        exports['dei_notifys']:Notify(msg, type or 'info')
    elseif Config.Notify == 'esx' or (Config.Notify == 'dei' and Config.Framework == 'esx') then
        if Framework then Framework.ShowNotification(msg) end
    elseif Config.Notify == 'qb' or (Config.Notify == 'dei' and Config.Framework == 'qb') then
        if Framework then Framework.Functions.Notify(msg, type or 'primary') end
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, false)
    end
end

function GetPlayerJob()
    if not Framework then return 'unemployed' end
    if Config.Framework == 'esx' then
        local pd = Framework.PlayerData
        return pd and pd.job and pd.job.name or 'unemployed'
    elseif Config.Framework == 'qb' then
        local pd = Framework.Functions.GetPlayerData()
        return pd and pd.job and pd.job.name or 'unemployed'
    end
    return 'unemployed'
end

function GetPlayerMoney()
    if not Framework then return 0 end
    local cash = 0
    if Config.Framework == 'esx' then
        local pd = Framework.PlayerData
        if pd and pd.accounts then
            for _, acc in ipairs(pd.accounts) do
                if acc.name == 'money' then cash = math.floor(acc.money) end
            end
        end
    elseif Config.Framework == 'qb' then
        local pd = Framework.Functions.GetPlayerData()
        if pd and pd.money then
            cash = math.floor(pd.money['cash'] or 0)
        end
    end
    return cash
end
