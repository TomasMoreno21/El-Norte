# Viaje Pampeano — Memoria del Proyecto

## Estado (2/6/2026)
Godot 4.6.2, resolución 1920×1080 landscape mobile. Stretch `canvas_items` + `expand`. PC dev: windowed 960×540. Cámara zoom 1.2 (visible ~1600×900). Filtro Nearest global.

## Stack
- Godot 4.6.2 (GDScript)
- VS Code
- Android export (APK)
- Git + GitHub

## Escenas
- **Menu** (`menu.tscn`): Jugar (25-75% ancho, 55-75% alto), Salir (25-75%, 78-90%), RightBox (80-100% ancho, 35-75%) con Tienda/Skins/Logros, Reset top-left
- **Main** (`main.tscn`): Player, Camera2D, HUD, DeathScreen, SpawnTimer, BolaTimer, kiwi/choice_menu/bola_barro/turbo_effect como PackedScene exportadas
- **Shop** (`shop.tscn`): VBoxContainer centrado 1120×1000, ScrollContainer con filas de 120px, 3 columnas (260/200/260) con CenterContainer + 60px separación
- **Skins** (`skins.tscn`): tarjetas horizontales de 240px
- **Achievements** (`achievements.tscn`): VBoxContainer centrado 1120×960, ScrollContainer, filas 190px, progress bars
- **Kiwi** (`kiwi/`): Area2D 54×54, sprite azul, señal `collected`, movimiento sinusoidal + dart
- **Choice Menu** (`kiwi/choice_menu.tscn`): CanvasLayer, RightPanel (45-100% ancho), botones dinámicos desde pool
- **Death Screen** (`death_screen.tscn`): estadísticas + botones

## Mecánicas
- **Player**: CharacterBody2D, gravity 900, flap -480, hold-to-rise. Start x=400. Muerte cuando y<53.5 o y>1026.5 (hitbox 73px fuera de pantalla).
- **Obstáculos**: 3 shapes (RECT_H 100×25, RECT_V 25×100, CIRCLE ø55), 2 movimientos (70% estático, 30% oscilante), 8% spawn doble, rotación angular aleatoria, ghost_time para precognición.
- **Dificultad**: speed = `min(400 + dist×0.5, 1000)`, interval = `max(1.6 − dist×0.0009, 0.5)`. `difficulty_dist` ≠ `distance` (desacoplada).
- **Tormenta**: cada 500m, duración 4s (tiempo real), speed ×1.6, interval ×0.5, shake sostenido 8/pico 16.
- **Ráfaga**: cooldown 1200m, 40% chance, 5s, distance ×1.5, partículas verdes.
- **Calma**: cooldown 800m (desde 500m), 25% chance, 5s, pausa spawn.
- **Shield**: 4s base + nivel×0.2s, collision_mask=0, parpadeo, countdown HUD.
- **Turbo**: 6s base + nivel×0.2s, distance ×2, obs speed ×1.5, spawn interval ×1.5, shake sostenido 5/pico 10.
- **Eventos mutuamente excluyentes**: ráfaga/calma/tormenta no se solapan.
- **x2 Bolas**: duplica próxima bola (variable `x2_bolas_active` declarada).
- **Precognición**: 5s, ghost_time 0.5s en obstáculos (alpha 0.25, collision disabled).
- **Miniatura**: 3s, player scale 0.5, collision shape escalada.
- **Palitos**: `(dist/10) × (1 + nivel_palitos)`, modificado por bird.palitos_mult.

## Pájaros (costos en bolas de barro)
| Pájaro | Costo | flap_mult | speed_mult | kiwi_bonus | palitos_mult | extra_lives |
|---|---|---|---|---|---|---|
| Hornero | 0 | 1.0 | 1.0 | 0.0 | 1.0 | 0 |
| Tero | 15 | 0.6 | 2.0 | 0.0 | 1.0 | 0 |
| Golondrina | 15 | 1.0 | 1.0 | 0.15 | 0.5 | 0 |
| Carpintero | 15 | 1.0 | 0.6 | 0.0 | 1.0 | 1 |
| premio_pajarero | -1 | — | — | — | — | — |

## Tienda — Mejoras
Cada mejora tiene su propio `UPGRADE_MAX_LEVEL`. Costo = `base × 2^nivel`.

| Mejora | Base | Max nivel | Efecto |
|---|---|---|---|
| Velocidad | 30 | 8 | +5% speed acumulativo |
| Kiwi | 25 | 8 | +5% chance spawn kiwi |
| Palitos | 40 | 8 | +1 palito cada 10m |
| Escudo | 30 | 5 | +0.2s duración escudo |
| Turbo | 30 | 5 | +0.2s duración turbo |

Costo total para maxear todo: ~24.225 palitos (originales 3) + costo shield/turbo.

## Achievements (con niveles)
ACHIEVEMENTS usa `{ id: { name, cond, idx, levels: [{ target, desc, reward_type, reward_amount }] } }`.
`completed_achievements` es Dictionary `{ id: level_index }`. Backward compat con Array.

| ID | Nombre | Cond | Niveles (target) |
|---|---|---|---|
| first_flight | Primer Vuelo | distance | 100m |
| explorer | Explorador | distance | 500m |
| fearless | Sin Miedo | distance | 2000m |
| collector | Coleccionista | bolas_total | 3, 5, 10 |
| persistent | Persistente | deaths | 20, 35, 50 |
| storm_survivor | Tormentero | storms | 3, 10, 25 |
| buyer | Comprador | total_upgrades_bought | 3, 7, 15 |
| calma_survivor | Sereno | calmas_survived | 3, 10 |
| maxed_out | Al Maximo | all_maxed | 1 |
| birder | Pajarero | all_birds | 1 |
| trato_hecho | Trato Hecho | kiwi_accepts | 20 |
| rey_tormentas | Rey de Tormentas | storms_in_run | 6 |

## Variables persistentes (data_manager.gd)
- palitos_balance, bolas_balance: monedas
- upgrades: Dictionary `{ clave: nivel }`
- unlocked_birds: Array de IDs, active_bird: String
- bolas_total, deaths, storms_survived, max_distance
- kiwi_accepts (migrado desde calandria_accepts en saves viejos)
- total_upgrades_bought, calmas_survived
- completed_achievements: Dictionary `{ id: level_completed }`

Save/load: `user://save.data` con FileAccess store_var/get_var (Dictionary).

### Migración de saves viejos
- `calandria_accepts` → `kiwi_accepts`: `data.get("kiwi_accepts", data.get("calandria_accepts", 0))`
- `upgrades["calandria"]` → `upgrades["kiwi"]`: migración automática en load
- `completed_achievements` Array → Dict: conversión con nivel 0

## Datos de kiwi
- Scene reemplazó a "Calandria" (rename completo: archivos, constantes, variables, display text)
- Rampa: KIWI_MIN_DIST=400, KIWI_MAX_DIST=1200, KIWI_BASE_CHANCE=0.15
- Probabilidad: `base + clamp((dist-min)/(max-min), 0, 1) × (1-base) + bird_bonus + upgrade×0.05`
- Power-ups disponibles: shield, turbo, x2_bolas, miniatura, x2_palitos, precognicion (+ bola_extra con Trato Hecho)
- Menú siempre 3 opciones; con Trato Hecho: 4 opciones

## Logros UI
- Popup flotante (DataManager.show_achievement_popup) funciona desde cualquier escena (menu, juego, tienda)
- Pantalla centrada con ScrollContainer, barras de progreso, niveles indicados

## Kiwi rename (2/6/2026)
Todo "calandria" renombrado a "kiwi": nombres de archivo, constantes, variables, display text, export paths. Directorio `scenes/calandria/` eliminado.

## Bugs conocidos y fixes
- `x2_bolas_active` no estaba declarada en main.gd → agregada
- `choice_menu.tscn` referenciaba `res://scenes/calandria/choice_menu.gd` → corregido a `res://scenes/kiwi/choice_menu.gd`
- GDScript `:=` con Dictionary.get() devuelve Variant → usar tipado explícito `: Tipo`

## Pendiente
- Sprites pixel art (bird 137×73, obst 100×25/25×100/55×55, kiwi 54×54, bola 70×70)
- Parallax background
- Sonido/música
- Consumibles pre-partida
- Desafíos diarios
- Más variedad de encuentros
- Animaciones UI
- Definir skin reward para "Pajarero"
