# Viaje Pampeano — Memoria del Proyecto

## Estado (2/6/2026)
Godot 4.6.2, resolución 1920×1080 landscape mobile. Stretch `canvas_items` + `expand`. PC dev: windowed 960×540. Cámara zoom 1.2 (visible ~1600×900). Filtro Nearest global.

## Stack
- Godot 4.6.2 (GDScript)
- VS Code
- Android export (APK)
- Git + GitHub

## Escenas
- **Menu** (`menu.tscn`): Jugar (25-75% ancho, 55-75% alto), Salir (25-75%, 78-90%), RightBox (80-100% ancho, 45-75%) con Tienda/Skins/Logros, Reset top-left. Staggered fade-in on load.
- **Main** (`main.tscn`): Player, Camera2D, HUD, DeathScreen, RevivePopup, SpawnTimer, BolaTimer, Background, kiwi/choice_menu/bola_barro/turbo_effect como PackedScene exportadas
- **Shop** (`shop.tscn`): VBoxContainer centrado 1120×1000, ScrollContainer con filas de 120px, 3 columnas (260/200/260) con CenterContainer + 60px separación. 100px left spacer.
- **Skins** (`skins.tscn`): tarjetas horizontales de 240px
- **Achievements** (`achievements.tscn`): VBoxContainer centrado 1120×960, ScrollContainer, filas 190px, progress bars
- **Kiwi** (`kiwi/`): Area2D 54×54, sprite azul, señal `collected`, movimiento sinusoidal + dart. Cooldown-based (20s + 8% chance).
- **Choice Menu** (`kiwi/choice_menu.tscn`): CanvasLayer, RightPanel (45-100% ancho), botones dinámicos desde pool
- **Death Screen** (`death_screen.tscn`): slide-up animation, anchor_top=0.35/anchor_bottom=0.95, button_feedback on buttons
- **Revive Popup** (`revive_popup/`): CanvasLayer layer 20, process_mode=2, REVIVE_COST=200, REVIVE_REWIND=150m
- **Background** (`background/`): ParallaxBackground con BIOMES const (Pampa/Espinal/Yungas), 200m transitions, self_modulate coloring
- **Effects** (`effects/`): button_feedback.gd (reusable), scene_transition.gd (autoload)

## Mecánicas
- **Player**: CharacterBody2D, gravity 900, flap -480, hold-to-rise. Start x=400. Muerte cuando y<53.5 o y>1026.5 (hitbox 73px fuera de pantalla). `reset()` restaura alive, velocity, position, collision_mask.
- **Obstáculos**: 3 shapes (RECT_H 100×25, RECT_V 25×100, CIRCLE ø55), 2 movimientos (70% estático, 30% oscilante), 8% spawn doble, rotación angular aleatoria, ghost_time para precognición. **Constraint-based**: `_safe_obstacle_y()` garantiza 90px gap mínimo. `_safe_double_y()` separa doubles.
- **Dificultad**: speed = `min(500 + dist×0.6, 1000)`, interval = `max(1.3 − dist×0.0012, 0.5)`. `difficulty_dist` ≠ `distance` (desacoplada). MIN_SPEED=500, MAX_SPEED=1000, MAX_INTERVAL=1.3.
- **Tormenta**: cada 500m, duración 4s (tiempo real), speed ×1.3, interval ×0.7, shake sostenido 8/pico 16. **Warning "!"** a 50m (STORM_WARNING_DIST=50), pulse rápido, auto-hide 2s.
- **Ráfaga**: cooldown 1200m, 40% chance, 5s, distance ×1.5, partículas verdes.
- **Calma**: cooldown 800m, 25% chance, 5s, pausa spawn. Increments `calmas_survived`.
- **Shield**: 4s base + nivel×0.2s, collision_mask=0, parpadeo, countdown HUD.
- **Turbo**: 6s base + nivel×0.2s, distance ×2, obs speed ×1.5, spawn interval ×1.5, shake sostenido 5/pico 10.
- **Eventos mutuamente excluyentes**: ráfaga/calma/tormenta no se solapan.
- **x2 Bolas**: duplica próxima bola (variable `x2_bolas_active` declarada).
- **Precognición**: 5s, ghost_time 0.5s en obstáculos (alpha 0.25, collision disabled).
- **Miniatura**: 3s, player scale 0.5, collision shape escalada.
- **Palitos**: `(dist/10) × (1 + nivel_palitos)`, modificado por bird.palitos_mult.
- **Revive**: 200 palitos, rewinds 150m, clears obstacles/kiwis/bolas, once per run. RevivePopup en layer 20, process_mode=2 (WHEN_PAUSED). `revive_popup.gd` emite señales `revived`/`rejected`.
- **Biomas parallax**: 3 biomas viaje sur→norte (Cordillera 0–800m, Llanuras 1000–2000m, Puna 2200+). 200m transición con lerp. `self_modulate` para colores (placeholder textures blancas). 3 capas por bioma (scroll_scale 0.05, 0.2, 0.4). Zonas de transición sin obstáculos + mensaje.

## UI Animations
- **Death screen**: slide-up desde y=1080→0 (ease-out back 0.5s), pausa después.
- **Menu**: staggered fade-in (Label→Jugar→Salir→RightBox, 0.1s delays).
- **Button feedback**: `button_feedback.gd` — scale 0.92 press, 1.05 hover, 1.0 exit/release.
- **Scene transitions**: `SceneTransition` autoload, `fade_to_scene()` 0.3s fade to black.
- **Achievement popups**: slide-in desde izquierda (ease-out back 0.4s), stay 2s, slide-out (ease-in cubic 0.3s).
- **Storm warning "!"**: font 140, orange-red, fast pulse (×15, scale 0.8–1.2, alpha 0.5–1.0), auto-hide 2s.

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
- **Cooldown por tiempo**: KIWI_COOLDOWN=20s, KIWI_SPAWN_CHANCE=8% por spawn event. Upgrade ×0.02/lvl.
- `kiwi_cooldown_timer` acumula delta. Cuando timer >= cooldown, 8% chance de spawn + reset timer.
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

## Dirección del viaje
El juego se llama "El Norte" porque el viaje va de **sur a norte** de Argentina. El hornero vuela desde la Cordillera hasta la Puna.

### Biomas (en orden del viaje)
1. **Montaña/Cordillera** (sur, 0–800m) — bioma inicial
2. Transición 800–1000m: sin obstáculos, mensaje "Las Llanuras se abren..."
3. **Llanuras** (centro, 1000–2000m) — segundo bioma
4. Transición 2000–2200m: sin obstáculos, mensaje "La Puna te espera..."
5. **Puna** (norte, 2200+) — bioma final

## Pendiente
- Sprites pixel art (bird 137×73, obst 100×25/25×100/55×55, kiwi 54×54, bola 70×70)
- Sonido/música
- Más variedad de encuentros (tailwind, bird flock)
- Definir skin reward para "Pajarero"
- Consumibles pre-partida
- Desafíos diarios
