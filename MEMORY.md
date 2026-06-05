# El Norte — Memoria del Proyecto

## Estado (5/6/2026)
Godot 4.6.2, resolución 1920×1080 landscape mobile. Stretch `canvas_items` + `expand`. PC dev: windowed 960×540. Cámara zoom 1.2 (visible ~1600×900). Filtro Nearest global.

## Stack
- Godot 4.6.2 (GDScript)
- VS Code
- Android export (APK)
- Git + GitHub (repo: TomasMoreno21/El-Norte)

## Dirección del viaje
El juego se llama "El Norte" porque el viaje va de **sur a norte** de Argentina. El hornero vuela desde la Cordillera hasta la Puna.

### Biomas (en orden del viaje)
1. **Montaña/Cordillera** (sur, 0–800m) — cielo gris azulado, montañas oscuras
2. Transición 800–900m: sin obstáculos, mensaje "Las Llanuras se abren..."
3. **Llanuras** (centro, 900–2000m) — verdes de llanura
4. Transición 2000–2100m: sin obstáculos, mensaje "La Puna te espera..."
5. **Puna** (norte, 2100+) — ocres y terracota

## Escenas
- **Menu** (`menu.tscn`): Jugar, Salir, RightBox (Tienda/Skins/Logros), Reset. Staggered fade-in on load.
- **Main** (`main.tscn`): Player, Camera2D, HUD, DeathScreen, RevivePopup, Background, SpawnTimer, BolaTimer, kiwi/choice_menu/bola_barro/turbo_effect como PackedScene.
- **Shop** (`shop.tscn`): VBoxContainer centrado, 3 columnas (260/200/260), 100px left spacer.
- **Skins** (`skins.tscn`): tarjetas horizontales de 240px.
- **Achievements** (`achievements.tscn`): VBoxContainer centrado, ScrollContainer, progress bars.
- **Kiwi** (`kiwi/`): Area2D 54×54, cooldown-based (20s + 8% chance).
- **Choice Menu** (`kiwi/choice_menu.tscn`): CanvasLayer, RightPanel, botones dinámicos desde pool. Sin nodos placeholder.
- **Death Screen** (`death_screen.tscn`): **Estático, centrado** (anchor 0.25–0.75), pausa inmediata. Sin animación.
- **Revive Popup** (`revive_popup/`): CanvasLayer layer 20, process_mode=2, REVIVE_COST=200, REVIVE_REWIND=150m.
- **Background** (`background/`): ParallaxBackground con BIOMES (Cordillera/Llanuras/Puna), 100m transitions, self_modulate. Zonas de transición sin obstáculos + mensaje.
- **Effects** (`effects/`): button_feedback.gd (reusable), scene_transition.gd (autoload 0.15s).

## Mecánicas
- **Player**: CharacterBody2D, gravity 900, flap -400, hold-to-rise. Start x=400. Muerte y<53.5 o y>1026.5. `reset()` restaura todo incluyendo Engine.time_scale=1.0.
- **Obstáculos**: 3 shapes (RECT_H 100×25, RECT_V 25×100, CIRCLE ø55), 2 movimientos (70% estático, 30% oscilante), 8% spawn doble, rotación angular aleatoria. **Constraint-based**: `_safe_obstacle_y()` garantiza 90px gap mínimo. Sin ghost_time (eliminado).
- **Dificultad**: speed = `min(500 + dist×0.6, 1000)`, interval = `max(1.3 − dist×0.0012, 0.5)`. `difficulty_dist` ≠ `distance`.
- **Tormenta**: cada 500m, 4s, speed ×1.3, interval ×0.7. **Warning "!"** a 50m, pulse rápido, auto-hide 2s.
- **Ráfaga**: cooldown 1200m, 40% chance, 5s, distance ×1.5, partículas verdes.
- **Calma**: cooldown 800m, 25% chance, 5s, pausa spawn.
- **Shield**: 4s base + nivel×0.2s, collision_mask=0, parpadeo.
- **Turbo**: 6s base + nivel×0.2s, distance ×2, obs speed ×1.5, spawn interval ×1.5, shake 5.
- **Eventos mutuamente excluyentes**: ráfaga/calma/tormenta no se solapan.
- **x2 Bolas**: duplica próxima bola.
- **Miniatura**: 3s, player scale 0.5, collision shape escalada.
- **Palitos**: `(dist/10) × (1 + nivel_palitos)`.
- **Revive**: 200 palitos, rewinds 150m, once per run.
- **Transiciones de bioma**: 100m sin obstáculos, mensaje centrado con fade.
- **Barro**: "+1" flotante al recolectar (o "+2" con x2_bolas).

## Game Feel
- **Slow-motion al morir**: `Engine.time_scale` 1.0 → 0.3 en 0.4s (12 steps con callbacks). Pausa del árbol + tween con TWEEN_PAUSE_PROCESS.
- **Transiciones de escena**: 0.15s fade to black (SceneTransition autoload).
- **Button feedback**: scale 0.92 press, 1.05 hover (button_feedback.gd).
- **Achievement popups**: slide-in izquierda, stay 2s, slide-out.
- **Storm warning "!"**: pulse rápido, auto-hide 2s.

## UI Animations
- **Menu**: staggered fade-in (Label→Jugar→Salir→RightBox, 0.1s delays).
- **Achievement popups**: slide-in ease-out back 0.4s, stay 2s, slide-out ease-in cubic 0.3s.

## Pájaros (costos en bolas de barro)
| Pájaro | Costo | flap_mult | speed_mult | kiwi_bonus | palitos_mult | extra_lives |
|---|---|---|---|---|---|---|
| Hornero | 0 | 1.0 | 1.0 | 0.0 | 1.0 | 0 |
| Tero | 15 | 0.6 | 2.0 | 0.0 | 1.0 | 0 |
| Golondrina | 15 | 1.0 | 1.0 | 0.15 | 0.5 | 0 |
| Carpintero | 15 | 1.0 | 0.6 | 0.0 | 1.0 | 1 |
| premio_pajarero | -1 | — | — | — | — | — |

## Tienda — Mejoras
Costo = `base × 2^nivel`. Cada mejora tiene `UPGRADE_MAX_LEVEL`.

| Mejora | Base | Max | Efecto |
|---|---|---|---|
| Velocidad | 30 | 8 | +5% speed acumulativo |
| Kiwi | 25 | 8 | +5% chance spawn kiwi |
| Palitos | 40 | 8 | +1 palito cada 10m |
| Escudo | 30 | 5 | +0.2s duración escudo |
| Turbo | 30 | 5 | +0.2s duración turbo |

## Achievements (con niveles)
`completed_achievements` es Dictionary `{ id: level_index }`.

| ID | Nombre | Cond | Niveles |
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
- palitos_balance, bolas_balance, upgrades, unlocked_birds, active_bird
- bolas_total, deaths, storms_survived, max_distance, kiwi_accepts, total_upgrades_bought, calmas_survived
- completed_achievements: Dictionary `{ id: level_index }`
- Save/load: `user://save.data`

### Migración de saves viejos
- `calandria_accepts` → `kiwi_accepts`
- `upgrades["calandria"]` → `upgrades["kiwi"]`
- `completed_achievements` Array → Dict

## Datos de kiwi
- **Cooldown por tiempo**: KIWI_COOLDOWN=20s, KIWI_SPAWN_CHANCE=8%. Upgrade ×0.02/lvl.
- Power-ups: shield, turbo, x2_bolas, miniatura, x2_palitos, precognicion (+ bola_extra con Trato Hecho).
- Menú 3 opciones; con Trato Hecho: 4.

## Bugs conocidos y fixes
- `x2_bolas_active` no estaba declarada → agregada
- `choice_menu.tscn` referenciaba calandria → corregido a kiwi
- GDScript `:=` con Dictionary.get() devuelve Variant → tipado explícito
- **Softlock al morir con logro** (5/6/2026): `_show_popups` usaba `await` con árbol pausado → movido después de UI decision
- **kill_tweens() no existe** en Godot 4 → usar `get_tree().get_processed_tweens()`
- **Engine.time_scale no se tweenea** con `tween_property` → usar callbacks con steps
- **Enums Tween en mayúsculas**: `TRANS_QUAD`, `EASE_OUT`, etc.

## Limpieza (5/6/2026)
- `_miniatura` write-only eliminada de player.gd
- `hide_effect()` y `show_effect()` muertas eliminadas de turbo_effect.gd
- `ghost_time` + `_alive` + lógica ghost eliminados de obstacle.gd (nunca se activaban)
- 3 nodos placeholder (BarroSeco, PlumaViento, Semilla) eliminados de choice_menu

## Pendiente
- Sprites pixel art (bird 137×73, obst 100×25/25×100/55×55, kiwi 54×54, bola 70×70)
- Sonido/música
- Nubes/elementos en fondo parallax (esperando sprites)
- Más variedad de encuentros (tailwind, bird flock)
- Definir skin reward para "Pajarero"
- Consumibles pre-partida
- Desafíos diarios
