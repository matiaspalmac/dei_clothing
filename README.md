# dei_clothing

Sistema de ropa y outfits para FiveM - Ecosistema Dei.

## Caracteristicas

- Menu de ropa con glassmorphism (panel lateral derecho)
- Navegacion por componentes y props del ped (modelo + textura)
- Sistema de outfits: guardar, cargar y eliminar
- Camara dinamica que enfoca la zona del cuerpo relevante
- Rotacion del personaje con mouse drag
- Tiendas y vestuarios configurables
- Precios configurables (tarifa plana o gratis)
- Soporte ESX y QBCore
- 4 temas + modo claro (ecosistema Dei)

## Instalacion

1. Copiar `dei_clothing` a la carpeta `resources`
2. Agregar `ensure dei_clothing` al `server.cfg`
3. Configurar `config.lua` segun necesidad

## Exports

```lua
exports['dei_clothing']:OpenClothing(storeIndex) -- Abrir tienda por indice
exports['dei_clothing']:OpenWardrobe()           -- Abrir vestuario libre
```

## Dependencias

- ESX o QBCore
- dei_notifys (opcional, para notificaciones)

## Estructura

```
dei_clothing/
├── fxmanifest.lua
├── config.lua
├── README.md
├── LICENSE
├── .gitignore
├── client/
│   ├── main.lua
│   ├── framework.lua
│   └── nui.lua
├── server/
│   ├── main.lua
│   └── framework.lua
└── html/
    ├── index.html
    └── assets/
        ├── css/
        │   ├── themes.css
        │   └── styles.css
        ├── js/
        │   └── app.js
        └── fonts/
            ├── Gilroy-Light.otf
            └── Gilroy-ExtraBold.otf
```

## Licencia

MIT License - Dei
