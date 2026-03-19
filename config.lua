Config = {}

Config.Framework = 'esx' -- 'esx' or 'qb'
Config.InteractKey = 38 -- E
Config.InteractDistance = 2.5
Config.EnablePricing = true
Config.FlatFee = 200
Config.MaxOutfits = 15
Config.CameraTransitionSpeed = 500
Config.FreeJobs = {'clothing'}

-- Notificaciones: 'dei' (dei_notifys auto-detect), 'esx', 'qb', 'native'
Config.Notify = 'dei'

Config.ShowBlips = true

Config.BlipSprite = 73
Config.BlipColor = 47
Config.BlipScale = 0.7

Config.Stores = {
    {
        label = 'Tienda de Ropa - Vinewood',
        coords = vector3(123.0, -219.0, 54.5),
        blip = true,
        categories = 'all',
    },
    {
        label = 'Tienda de Ropa - Centro',
        coords = vector3(75.0, -1393.0, 29.4),
        blip = true,
        categories = 'all',
    },
    {
        label = 'Tienda de Ropa - Vespucci',
        coords = vector3(-822.0, -1073.0, 11.3),
        blip = true,
        categories = 'all',
    },
    {
        label = 'Tienda de Mascaras',
        coords = vector3(-1338.0, -1278.0, 4.9),
        blip = true,
        categories = {'mascaras'},
    },
}

Config.Wardrobes = {
    {
        label = 'Vestuario LSPD',
        coords = vector3(452.0, -993.0, 30.7),
        jobs = {'police'},
        free = true,
    },
    {
        label = 'Vestuario EMS',
        coords = vector3(305.0, -599.0, 43.3),
        jobs = {'ambulance'},
        free = true,
    },
}

Config.ComponentLabels = {
    [1]  = 'Mascaras',
    [3]  = 'Camisetas',
    [4]  = 'Pantalones',
    [5]  = 'Bolsos',
    [6]  = 'Zapatos',
    [7]  = 'Accesorios',
    [8]  = 'Camiseta Interior',
    [9]  = 'Chalecos',
    [10] = 'Insignias',
    [11] = 'Chaquetas',
}

Config.PropLabels = {
    [0] = 'Sombreros',
    [1] = 'Gafas',
    [2] = 'Orejas',
    [6] = 'Relojes',
    [7] = 'Pulseras',
}

Config.CameraOffsets = {
    head  = { z = 0.6,  fov = 35 },
    torso = { z = 0.2,  fov = 45 },
    legs  = { z = -0.3, fov = 50 },
    feet  = { z = -0.8, fov = 40 },
    full  = { z = 0.0,  fov = 55 },
}

-- Map component/prop IDs to camera zones
Config.ComponentCameraZone = {
    [1]  = 'head',
    [3]  = 'torso',
    [4]  = 'legs',
    [5]  = 'torso',
    [6]  = 'feet',
    [7]  = 'torso',
    [8]  = 'torso',
    [9]  = 'torso',
    [10] = 'torso',
    [11] = 'torso',
}

Config.PropCameraZone = {
    [0] = 'head',
    [1] = 'head',
    [2] = 'head',
    [6] = 'torso',
    [7] = 'torso',
}
