# El Norte — Memoria del Proyecto

## Pendientes para próxima sesión
- **Minimapa no centrado en celular**: la barra horizontal con BAR_LEFT=200/BAR_RIGHT=1720 se ve corrida a la izquierda en mobile. Revisar si el Control con anchors_preset=10 (TOP_WIDE) soluciona o si se necesita otro approach (ej: usar get_viewport_rect().size.x en _draw).
- **Botones Jugar/Salir se ven distintos en celular vs PC**: los sprites con expand_icon=true no cubren todo el botón en mobile. Revisar theme, padding del button, o usar TextureRect en vez de Button+icon.

## Estado (18/6/2026)
Godot 4.6.2, resolución 1920×1080 landscape mobile. Stretch `canvas_items` + `expand`. PC dev: windowed 960×540. Cámara zoom 1.2 (visible ~1600×900). Filtro Nearest global.

## Stack
- Godot 4.6.2 (GDScript)
- VS Code
- Android export (APK)
- Git + GitHub (repo: TomasMoreno21/El-Norte)

## Dirección del viaje
El juego se llama "El Norte" porque el viaje va de **sur a norte** de Argentina. El hornero vuela desde la Cordillera hasta la Puna.

### Biomas (en orden del viaje, definitivos)
1. **Cordillera** (sur, 0–2200m)
2. **Llanuras** (centro, 2200–4600m)
3. **Puna** (norte, 4600m+ INF)

Transiciones de 15m con FADE_OUT de 200m. Neblina 4 capas con shader `fog_fade.gdshader` en zonas 2100–2300 y 4500–4700.

## Escenas principales
- **Menu** (`menu.tscn`): Jugar/Salir como Button con `icon` + `expand_icon`. `gui_input` para mouse+touch. Direct scene change. `process_mode = ALWAYS`.
- **Main** (`main.tscn`): Player, Camera2D, HUD, DeathScreen, RevivePopup, Background, sistema de encuentros (storm/rafaga/calma/lluvia).
- **Shop** (`shop.tscn`): VBoxContainer centrado, costos desde `UPGRADE_COST_TABLE`.
- **Skins** (`skins.tscn`): tarjetas 240px. Carancho oculto (???) hasta "Pajarero".
- **Achievements**: VBoxContainer, ScrollContainer, progress bars.
- **Kiwi** (`kiwi/`): `_draw()` círculo azul radio 27 + borde blanco. No Sprite2D.
- **Death Screen**: estático centrado (anchor 0.25–0.75), pausa inmediata.
- **Revive Popup**: CanvasLayer layer 20, REVIVE_COST=200, REVIVE_REWIND=150m.
- **Background**: ParallaxBackground con BIOMES, fmod wrapping, editor F1.
- **Effects**: SceneTransition (autoload, safety timeouts 0.5s, `PROCESS_MODE_ALWAYS`).

## Dificultad (definitiva)
- `speed = 550 + 650 × (1 − e^(−dist/2500))`
- `interval = 0.38 + 0.90 × e^(−dist/2600)`
- `double_chance = min(0.08 + dist × 0.002, 0.40)`
- `turbo_obs_speed = min(1.5 + dist × 0.00002, 1.7)`
- Storm: ×1.3 speed, ×0.7 interval. Storm+turbo cap solo cuando ambos activos (×1.5).
- `_update_encounter_mode()` centralizado con prioridad: calma > storm > rafaga > lluvia > turbo > normal.

## Mecánicas clave
- **Player**: gravity 900, flap -400, hold-to-rise. Start x=400. Muerte y<53.5 o y>1026.5.
- **Obstáculos**: 3 shapes, 90px gap mínimo. Doble chance escala con distancia.
- **Shield**: collision_mask=0, parpadeo.
- **Turbo**: distance ×2, obs speed ×1.5, spawn interval ×1.5.
- **Miniatura**: 3s, scale 0.5.
- **Palitos**: `int(dist/10) × (1 + lv_palitos_base) × biome_mult × bird_mult`. Biome mult: ×1.0/×1.5/×2.0.
- **Revive**: 200 palitos, 150m rewind. `kill_all_tweens()` en `player.reset()`. Limpia partículas turbo.
- **Barro**: "+1"/"+2" flotante al recolectar.
- **Lluvia de barro**: spawn alternado (banda alta 250–450 / banda baja 700–900), cada 1s, duración 6s, 15% chance cada 2500m.

## Game Feel (branch implementacion-sprites)
- **Shake cámara**: `flapped` → shake_strength=8.0 (antes 6), decay 4/s, X+Y. No durante storm/turbo.
- **Plumas**: GPUParticles2D 14 partículas crema, one_shot por flap, local_coords=false.
- **Squash**: scale (1.08, 0.92) 0.05s → 0.1s. Usa `$Sprite2D.scale` como base.
- **Pulso contadores**: 1.0→1.25→1.0 al actualizar distancia/bolas/palitos.
- **Flash milestone**: 4 ColorRect strips 30px, alpha 0.2→0 en 0.4s.
- **Animación aleteo**: Timer 0.08s alterna hornero1/hornero2.
- **Slow-motion muerte**: Engine.time_scale 1.0→0.3 en 0.4s (12 steps).
- **Storm flap nerf**: storm_flap_override = -340. Vuelve gradual en 1.5s ease-out.

## Encuentros/Eventos
| Evento | Gatillo | Duración | Efecto |
|--------|---------|----------|--------|
| Tormenta | cada 500m | 4s | ×1.3 speed, ×0.7 interval. Warning "!" escala 0.6–1.4 |
| Ráfaga | 40% cada 1200m | 5s | ×1.5 distance, partículas verdes. NO afecta parallax |
| Calma | 25% cada 800m | 5s | Pausa spawn de obstáculos |
| Lluvia de barro | 15% cada 2500m | 6s | Spawnea barros cada 1s alternando alto/bajo |
| **Mutuamente excluyentes** | — | — | calma > storm > rafaga > lluvia > turbo > normal |

## Pájaros (costos en bolas de barro)
| Pájaro | Costo | flap_mult | speed_mult | kiwi_bonus | palitos_mult | extra_lives |
|--------|-------|-----------|------------|------------|--------------|-------------|
| Hornero | 0 | 1.0 | 1.0 | 0.0 | 1.0 | 0 |
| Tero | 45 | 0.72 | 1.4 | 0.0 | 0.85 | 0 |
| Golondrina | 35 | 1.1 | 1.0 | 0.20 | 0.85 | 0 |
| Carpintero | 25 | 1.0 | 0.9 | 0.0 | 0.75 | 1 |
| Carancho (secreto) | — | 1.0 | 1.6 | 0.0 | 1.1 | 1 |

## Tienda — Costos (UPGRADE_COST_TABLE)
| Mejora | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | Lv6 | Lv7 | Lv8 |
|--------|-----|-----|-----|-----|-----|-----|-----|-----|
| Velocidad | 200 | 300 | 500 | 700 | 1200 | 2000 | 3000 | 5000 |
| Kiwi | 150 | 250 | 400 | 600 | 1000 | 1500 | 2500 | 4000 |
| Palitos Base | 250 | 400 | 600 | 1000 | 1500 | 2500 | 4000 | 6500 |
| Escudo/Turbo (max5) | 150 | 250 | 400 | 700 | 1000 | — | — | — |

**Total maxear: ~34.840 🪵**. Pájaros: Carpintero 25🔵, Golondrina 35🔵, Tero 45🔵.

## Achievements (con niveles)
`completed_achievements` = `{ id: level_index }`.

| ID | Nombre | Cond | Niveles |
|----|--------|------|---------|
| first_flight | Primer Vuelo | distance | 100m |
| explorer | Explorador | distance | 500m |
| fearless | Sin Miedo | distance | 2000m |
| llanura | Llanuras | distance | 2200m |
| norte | Norte (Puna) | distance | 4600m |
| maraton | Maratón | distance | 10000m |
| collector | Coleccionista | bolas_total | 3, 5, 10 |
| ladron | Ladrón | bolas_total | 1000 |
| rico | Rico | palitos_balance | 1000, 3000, 8000 |
| buyer | Comprador | total_upgrades_bought | 3, 7, 15 |
| maxed_out | Al Maximo | all_maxed | 1 |
| multiuso | Multiuso | bird_uses | 2, 3, 4 |
| birder | Pajarero | all_birds | 1 |
| pampeano | Pampeano | all_birds_5000 | 4 pájaros a 5000m |
| trato_hecho | Trato Hecho | kiwi_accepts | 20 |
| por_los_pelos | Por los Pelos | revives_used | 1, 5, 10 |
| storm_survivor | Tormentero | storms | 3, 10, 25 |
| calma_survivor | Sereno | calmas_survived | 3, 10 |
| rey_tormentas | Rey de Tormentas | storms_in_run | 6 |
| persistent | Persistente | deaths | 20, 35, 50 |
| veterano | Veterano | deaths | 100 |

## Kiwi
- Cooldown: 20s + 8% por spawn. Upgrade ×0.02/lvl.
- Power-ups: shield(35🪵), turbo(40🪵), x2_bolas(25🪵), miniatura(20🪵), x2_palitos(60🪵), bola_extra(35🪵, requiere Trato Hecho).
- 1 gratis siempre primero. "Rechazar" al final.

## Variables persistentes (DataManager)
- palitos_balance, bolas_balance, upgrades, unlocked_birds, active_bird
- bolas_total, deaths, storms_survived, max_distance, kiwi_accepts, total_upgrades_bought, calmas_survived
- completed_achievements: Dictionary, revives_used, used_birds[], bird_max_distances: {}
- first_milestones_claimed[], record_bolas_claimed[], tutorial_done
- Achievement popups persistentes (autoload), bottom-left

## Flujo récord
1. `_on_player_died()` guarda `_death_old_max` → actualiza `max_distance`
2. `show_screen(old_max)` → claim_record_bolas(distance, old_max)
3. Solo paga si distance > old_max
4. `_on_revive_reject()` también pasa `_death_old_max`

## Lecciones Aprendidas
- `dict["key"]` siempre devuelve Variant en GDScript 4
- `Array[var] := [{...}]` infiere `Array`, no `Array[Dictionary]`
- `Engine.time_scale` no se puede tweenear → callbacks con steps
- `kill_tweens()` no existe → `get_tree().get_processed_tweens()`
- Conectar señales en callbacks causa conexiones duplicadas
- ShaderMaterial compartido: cambios afectan a todos
- Android touch = `InputEventScreenTouch`, no `InputEventMouseButton`
- `mouse_entered`/`mouse_exited` rompen botones en Android
- `ImageTexture.create_from_image()` falla en Android → usar `_draw()`
- `ParticleProcessMaterial` NO tiene `scale_y_min`/`scale_y_max` ni `lifetime_min`/`lifetime_max`. Escala es uniforme (un solo float `scale_min`/`scale_max`). Lifetime se setea en `GPUParticles2D.lifetime`.
- `GPUParticles2D.position` usa coordenadas del padre (Node2D). Usar `global_position` si se necesita posición absoluta.
- Background offset NO debe duplicar multiplicadores que ya están en `distance`. Si `distance` ya acumula con `turbo_mult`, pasar `speed_mult=1.0` al background, no `turbo_mult`.
- Multiplicadores de score aplicados a `distance` tienen efecto permanente (distancia inflada para toda la run). Si se quiere un bonus temporal sin inflar distancia, aplicar el mult directamente al score, no a `distance`.
- Al aplicar x2 a palitos: NO hacer `run_palitos *= 2` si ya `distance` acumula al doble por `palitos_dist_mult`. Es doble-doble → cuadruplicación con salto visual.
- Score flip animation (scale:y 0→cambio→1) rechazada por el usuario. Prefiere animación continua sutil (idle + pulso al cambiar).
- Achievement cond type "all_birds_5000": requiere nueva variable Dictionary persistente (bird_max_distances), save/load, función mark_bird_distance, handler en check_achievements + get_current_value, y llamada desde _on_player_died.

## Branch: implementacion-sprites (sin mergear)
Contiene: game feel completo, kiwi _draw(), storm tuning, menu sprites, lluvia de barro, etc.

---

# 🪵 BANCO DE IDEAS — Mejoras Potenciales

*Guardado el 18/6/2026. Ideas clasificadas por área, priorizadas por facilidad de integración y valor.*

---

## 🎮 GAME FEEL (Juice) — 30 ideas

1. **Efecto elástico en contador de barro**: Label rebota con `ease out back`
   → Al agarrar barro, el número se estira y rebota antes de asentarse
2. **Pop de spawn en obstáculos**: escala 0→1 en 0.15s
   → ~~Obstáculos aparecen con animación de crecimiento~~ ❌
3. **Línea de guía predictiva**: trayectoria punteada si soltás
   → Línea punteada que muestra dónde caería el pájaro si soltás ahora
4. **Screen shake al tocar techo/piso**
   → Leve vibración al llegar al borde superior o inferior de la pantalla
5. **VHS glitch sutil al cambiar de bioma**
   → Línea de scan horizontal rápida al cruzar a Cordillera/Llanuras/Puna
6. **Estrellitas al comprar upgrade**: partículas amarillas
   → Mini explosión de estrellas al comprar una mejora en la tienda
7. **Latido del HUD cerca del récord personal**
   → El label de distancia pulsa suave cuando estás cerca de tu récord
8. **Onda de choque circular al activar turbo**
   → Anillo expansivo desde el centro al activar el turbo
9. **Score animado**: números rotan al incrementarse
   → Cada dígito gira como un contador mecánico al subir
10. **Chispas en bordes del pájaro a alta velocidad**
    → Partículas finas desde los extremos del pájaro cuando va rápido
11. **Splash de color al entrar a nuevo bioma**
    → Ola de color que cruza la pantalla al cambiar de bioma
12. **Barro brilla al estar por desaparecer**
    → ✅ El barro parpadea cuando está por salir de pantalla
13. **Ondulación de calor en Puna** (shader simple)
    → Distorsión ondulante en los bordes simulando aire caliente
14. **Viñeta dinámica según altura del pájaro**
    → Los bordes se oscurecen más cuando el pájaro está cerca del techo/piso
15. **Flash breve en HUD cada 100m**
    → ✅ Destello blanco sutil que cruza la pantalla cada 100m recorridos
16. **Rebote gelatinoso en botones**
    → Los botones se estiran como gelatina al presionarlos (ease out back)
17. **Círculo expansivo al morir**
    → Onda circular que crece desde el pájaro hasta llenar la pantalla al morir
18. **Parpadeo del pájaro si está idle >2s**
    → Si no tocás la pantalla, el pájaro cierra los ojos brevemente
19. **Contracción horizontal al cambiar de dirección**
    → ~~Contracción al soltar~~ ❌
20. **Barro se agranda con la distancia**
    → Cuanto más lejos llegás, más grandes aparecen los barros (más fáciles)
21. **Cámara "respira" (zoom leve) antes del slow-motion de muerte**
    → Zoom in/out muy sutil en el momento justo antes de morir
22. **Polvo al aterrizar después de estar en techo**
    → Nube de polvo al caer rápido y tocar el piso
23. **Pixelación/glitch progresivo cuanto más cerca de morir**
    → El pájaro se pixela más cuanto menor es su vida restante
24. **Horizonte se tiñe del color del próximo bioma 50m antes**
    → El cielo empieza a cambiar de color antes de la transición oficial
25. **Micro-sacudón al pasar múltiplos de 100 en score**
    → La pantalla vibra apenas al cruzar cada 100m
26. **Tono de luz cambia según distancia (atardecer simulado)**
    → La iluminación general se vuelve más cálida con la distancia
27. **Estela de polvo de estrellas en turbo**
    → Partículas brillantes que quedan atrás del pájaro en turbo
28. **Brillo especular en barros según sol virtual**
    → Los barros reflejan un destello que rota, como si hubiera sol
29. **After-image fantasma de obstáculos al pasar**
    → Los obstáculos dejan un rastro fantasma breve al rebasarlos
30. **Lluvia fina permanente en Cordillera (partículas continuas)**
    → Gotas finas cayendo siempre en el bioma Cordillera

## ⚙️ GAMEPLAY — 30 ideas

1. **Elección de mejora temporal a los 1000m** (tipo roguelite)
   → Al llegar a 1000m elegí entre 2 buffos aleatorios para el resto de la partida
2. **Knockback al golpear con escudo** (empuja, no mata)
   → Si tenés escudo, el golpe te empuja atrás en vez de matarte
3. **Fatiga**: 10 flaps rápidos → cooldown 1s
   → Si aleteás 10 veces sin pausa, el pájaro se cansa y no responde 1s
4. **Planeo**: soltar da pequeño lift extra
   → Al soltar el botón, el pájaro planea suave 0.3s antes de caer
5. **Barro de riesgo**: rozar obstáculo da +1 barro
   → Si pasás rozando un obstáculo (muy cerca), ganás 1 barro extra
6. **Muerte barata gratis hasta 500m** (primera no cuenta)
   → Si morís antes de 500m, no perdés nada (es como si no hubiera pasado)
7. **Power-up congelar**: obstáculos quietos 2s
   → Congela todos los obstáculos en su lugar por 2s, solo se mueve el fondo
8. **Hold-to-mine**: más barro si mantenés
   → Si mantenés presionado sobre un barro, da más (riesgo-recompensa)
9. **Modo ayuda tras 3 muertes seguidas <1000m**
   → Si morís 3 veces seguidas antes de los 1000m, la próxima es más fácil
10. **Vender upgrades**: recuperar 50%
    → Podés vender una mejora comprada y recuperar la mitad de lo invertido
11. **Convertir palitos → barro** (ratio variable)
    → Botón en tienda para convertir palitos a barros (ej: 5 palitos = 1 barro)
12. **Tap arriba/abajo como control alternativo**
    → Tocar arriba de la pantalla sube, abajo baja (alternativa al hold)
13. **Doble tap = mini turbo gratuito** (5s cd)
    → ~~Doble tap rápido da turbo corto~~ ❌
14. **Línea de altura segura en obstáculos altos**
    → Línea tenue que marca por dónde pasar sin chocar en obstáculos grandes
15. **Hitbox se reduce 10% a alta velocidad**
    → Cuanto más rápido vas, más chico es el área de colisión del pájaro
16. **Invulnerabilidad creciente**: 0.5s→1s tras racha
    → Si morís varias veces seguidas, la invulnerabilidad post-golpe dura más
17. **Cerrar kiwi tocando afuera del menú**
    → Tocar fuera del menú del kiwi lo cierra sin aceptar ni rechazar
18. **Descuento por muerte en tienda** (5% c/u, max 50%)
    → Cada muerte acumula 5% de descuento en la tienda (hasta 50%)
19. **Reset de mejoras pagando palitos**
    → Podés reiniciar todas las mejoras a cambio de palitos
20. **Indicador de peligro si estás mucho en misma altura**
    → Si estás mucho tiempo en la misma Y, aparece una advertencia
21. **Power-up rebote**: tocar borde rebota 1 vez
    → Si tocás techo o piso, el pájaro rebota una vez sin morir
22. **Empuje extra al aletear saliendo de obstáculo**
    → Si aleteás justo al pasar un obstáculo, recibís empuje extra
23. **Combo**: 3 barros seguido rápido → ×1.5
    → ~~3 barros en 1.5s dan bonus~~ ❌
24. **Aire caliente en Puna**: eleva al pájaro gratis
    → Zonas de aire caliente en Puna que elevan al pájaro sin aletear
25. **Skill shot**: gap justo entre obstáculos da bonus
    → Pasar por un gap muy angosto da barro o palitos extra
26. **Inercia al soltar**: desacelera suave, no instantáneo
    → ~~Al soltar, la velocidad vertical disminuye gradual~~ ❌
27. **Barros en oleadas sinusoidales** (no estáticos)
    → Los barros se mueven en ondas suaves arriba/abajo al aparecer
28. **Obstáculos que rotan 360° lentamente**
    → Los obstáculos rotan sobre sí mismos cambiando el ángulo de paso
29. **Obstáculos rompibles si venís muy rápido**
    → Si vas a alta velocidad, algunos obstáculos se rompen al tocarlos
30. **Barro magnético**: atrae desde más lejos 5s
    → Power-up que atrae barros desde mayor distancia por 5s

## 🎨 VARIEDAD DE CONTENIDO — 30 ideas

1. **Cactus rodador**: obstáculo circular con textura de cactus
   → Cactus bola que cruza rodando, misma hitbox que el círculo actual
2. **Pájaros enemigos estáticos** en distancias fijas
   → Pájaros posados en el camino que hay que esquivar a ciertas distancias
3. **Power-up brújula**: muestra distancia al próximo kiwi
   → Al agarrarlo, muestra en el HUD a qué distancia está el kiwi
4. **Logro "Maratón"**: llegar a 10000m
   → ✅ Llegar a 10000m en una partida → premio 5 bolas
5. **Logro "Coleccionista"**: comprar todos los pájaros
   → Desbloquear todas las aves disponibles → premio palitos
6. **Logro "Sin manos"**: 2000m sin tocar pantalla
   → Llegar a 2000m sin presionar ni una vez (solo gravedad)
7. **Logro "Ladrón"**: 1000 barros totales acumulados
   → ✅ Acumular 1000 barros entre todas las partidas → premio 500 palitos
8. **Logro "Superviviente"**: 3 tormentas en una partida
   → Sobrevivir 3 tormentas en una misma partida
9. **Logro "Veloz"**: 3000m en menos de 90s
   → Alcanzar los 3000m antes de 90 segundos de partida
10. **Logro "Rico"**: 1000 palitos sin gastar
    → Acumular 1000 palitos sin comprar nada (solo alcanzar el saldo)
11. **Logro "Atrevido"**: gap entre obstáculos ≤110px
    → Pasar por un espacio de 110px o menos entre dos obstáculos
12. **Pájaro Cardenal**: +10% flap, +5% palitos (1000 palitos totales)
    → Desbloqueable al acumular 1000 palitos totales, stats equilibradas
13. **Pájaro Benteveo**: +1 vida, -10% velocidad (50 partidas)
    → Desbloqueable tras 50 partidas jugadas, ideal para aprender
14. **Escudo con 3 cargas** si upgrade al máximo
    → Al maxear el upgrade de escudo, aguanta 3 golpes en vez de 1
15. **Modo espejo**: todo invertido horizontalmente
    → Desbloqueable que invierte izquierda/derecha, mayor desafío
16. **Modo nocturno**: fondo oscuro, siluetas
    → Modo alternativo con fondo negro y obstáculos en silueta
17. **Evento "fiesta" cada 2000m**: barros como confeti
    → Al llegar a 2000m, barros aparecen con colores de confeti
18. **Item "alas extra"**: vida extra por 100 palitos
    → Comprar una vida extra en la tienda por 100 palitos (stackeable)
19. **Item "detector de barro"**: radar en HUD
    → Mini radar que muestra la dirección del barro más cercano
20. **Logro "Pampeano"**: 5000m con cada pájaro
    → ✅ Llegar a 5000m con cada uno de los pájaros disponibles
21. **Evento "langostas"**: 60s, evitalas o perdés barro
    → Nube de langostas que si te tocan, perdés barro acumulado
22. **Moneda "plumas"**: coleccionable raro para skins
    → Plumas doradas que aparecen muy de vez en cuando, canjeables por skins
23. **Power-up fantasma**: atravesar obstáculos 2s
    → Volvés intangible y atravesás cualquier obstáculo por 2s
24. **Logro "Veterano"**: 100 partidas jugadas
    → ✅ Jugar 100 partidas en total → premio 3 bolas
25. **Pájaro Lechuza**: visión nocturna (modo noche)
    → Desbloqueable al completar modo noche, ve mejor en oscuridad
26. **Cactácea rodante que rebota** (va y viene)
    → Cactus que rebota en los bordes y cruza varias veces la pantalla
27. **Troncos diagonales** (obstáculo 45°)
    → Obstáculo inclinado a 45° que obliga a pasar en diagonal
28. **Cardones/arbustos altos** que obligan a bajar
    → Obstáculos verticales muy altos que obligan a volar abajo
29. **Rocas colgantes**: caen desde arriba
    → Rocas que cuelgan del techo y caen si el pájaro pasa cerca
30. **Plataformas móviles verticales**: suben y bajan
    → Obstáculos que se mueven arriba/abajo cambiando la altura del gap

## 🧩 UI / SETTINGS / QoL — 30 ideas

1. **Icono kiwi disponible parpadea en HUD**
   → Cuando el kiwi está listo, un icono parpadea para avisar al jugador
2. **Tooltip en power-ups del kiwi** (explicación + precio)
   → Al tocar un power-up del kiwi, muestra qué hace y cuánto cuesta
3. **Botón compartir puntuación**: screenshot al morir
   → Botón que guarda captura de pantalla con la distancia al morir
4. **Slider de sensibilidad de flap**
   → Ajustar qué tan sensible es el flap al toque (velocidad de respuesta)
5. **Opción Hold vs Tap**
   → Elegir entre mantener presionado o tocar repetido para aletear
6. **Opción tamaño del pájaro**: chico/mediano/grande
   → Cambia el visual y la hitbox del pájaro (mayor dificultad = más chico)
7. **Tema claro/oscuro para la UI**
   → Alternar entre interfaz clara u oscura en los menús
8. **Modo reducir movimiento**: desactiva shake y partículas
   → Para accesibilidad: apaga el shake de cámara y las partículas
9. **Beneficio exacto en tienda**: "+15% velocidad"
   → Mostrar el porcentaje exacto en vez de solo "mejora velocidad"
10. **Stats comparativas en Skins** vs pájaro activo
    → Al ver otro pájaro, muestra "+10% velocidad vs activo"
11. **Barra de progreso del próximo upgrade en tienda**
    → Barra visual que muestra cuánto falta para el siguiente nivel
12. **Alerta de fin de power-up** (destello)
    → Cuando un power-up está por expirar, destello de advertencia
13. **Mostrar "quedaste a Xm del récord" al morir**
    → Si no fue récord, muestra la diferencia con el récord actual
14. **Stats de partida en pausa**: barros, palitos, kmh
    → ✅ Al pausar, se ven stats de la partida actual
15. **Confirmación antes de gastar >200 palitos**
    → Diálogo "¿Estás seguro?" antes de compras grandes
16. **Tips aleatorios en muerte**
    → ✅ Consejo útil al azar en la pantalla de muerte
17. **Atajo muerte → menú principal sin transición extra**
    → Botón "menú" que va directo sin fade adicional
18. **Historial de últimas 10 partidas**
    → Lista con distancia, palitos, barros y fecha de cada partida
19. **Botón "reset data" oculto (doble confirmación)**
    → Borrar todos los datos, con doble confirmación para evitar accidentes
20. **Autopause al perder foco**
    → El juego se pausa solo si cambiás de ventana o app
21. **Modo ahorro batería (30fps)**
    → Limita el framerate a 30fps para ahorrar batería en móviles
22. **Feedback háptico**: vibrar al agarrar barro/chocar
    → Vibración del teléfono al agarrar barro o al chocar
23. **Notificación kiwi listo desde el menú**
    → Aunque estés en el menú, avisa que el kiwi está disponible
24. **Preview hitbox del pájaro (debug toggle)**
    → Toggle invisible que muestra el área de colisión del pájaro
25. **Tooltip "primera vez" en cada power-up del kiwi**
    → La primera vez que ves cada power-up, muestra un tooltip explicativo
26. **Widget "próximo hito"**: cuánto falta para el milestone
    → ~~Muestra cuánto falta para los 500/1000/2200/4600m~~ ❌
27. **Mapa minimalista del viaje (sur→norte) en esquina**
    → Pequeño mapa en la esquina mostrando tu progreso por Argentina
28. **Icono de evento activo en HUD** (ráfaga/tormenta/calma)
    → Icono que indica qué evento climático está activo
29. **Botón "siguiente partida" directo desde muerte**
    → Botón "Jugar de nuevo" en la pantalla de muerte sin pasar por menú
30. **Opción de texto más grande (accesibilidad)**
    → Aumentar el tamaño de todo el texto de la interfaz

## 💰 ECONOMÍA / PROGRESIÓN — 30 ideas

1. **Bono bienvenida**: 50 palitos al abrir primera vez
   → ✅ Al jugar por primera vez, se acreditan 50 palitos automáticamente
2. **Bono por volver a jugar inmediato**: +20% palitos
   → Si jugás otra partida justo después de morir, ganás 20% más palitos
3. **Racha de partidas**: +5% c/u hasta +25%
   → Por cada partida consecutiva sin cerrar el juego, bonus acumulativo
4. **Precio dinámico**: comprar sube leve el costo
   → Cada compra de un upgrade sube su precio un poco (oferta-demanda)
5. **Descuento rotativo semanal en upgrades**
   → Cada semana un upgrade distinto tiene descuento
6. **Canjear barros → palitos**: 1 barro = 5 palitos
   → Botón en tienda para convertir barros en palitos
7. **Bono explorador**: llegar a nuevo bioma da palitos
   → ✅ Llegar a Llanuras (+30) y Puna (+60) da palitos una vez
8. **Inversión con el kiwi**: prestás, devuelve con interés
   → Darle palitos al kiwi, los devuelve con interés después de X partidas
9. **Límite de gasto diario en tienda**
   → Para no desbalancear, máximo de palitos gastables por día
10. **Palitos no gastados → conversión parcial a barros al morir**
    → Al morir, un % de los palitos no gastados se convierten a barros
11. **Bonificación por distancia exacta**: morir en múltiplo de 500m → bonus
    → Si morís justo en 500/1000/1500m etc, bonus extra de palitos
12. **Interés compuesto**: palitos no gastados generan 1% por partida
    → Los palitos que tengás guardados generan interés cada partida
13. **Logro "inversor"**: 5000 palitos sin gastar
    → Acumular 5000 palitos sin gastar ninguno
14. **Logro "gastador"**: gastar 10000 palitos totales
    → Gastar 10000 palitos acumulados entre todas las partidas
15. **Oferta del día**: upgrade aleatorio 30% desc.
    → Cada día real un upgrade distinto tiene 30% de descuento
16. **Bono de regreso**: no jugar 24h → palitos gratis al volver
    → Si no jugás por 24h, al volver te dan palitos de bienvenida
17. **Bono horario**: jugar de noche da ×1.1 palitos
    → Entre 22hs y 6hs, los palitos ganados tienen 10% de bonus
18. **Megabono 5000m**: palitos ×3 (además de biome)
    → Si llegás a 5000m, los palitos se multiplican ×3 encima del biome mult
19. **Fianza**: pagar palitos para no perder barros al morir
    → Antes de la partida, pagás palitos para no perder barros al morir
20. **Seguro de barro**: 50 palitos pre-partida, si morís <1000m conservás mitad
    → Pagás 50 palitos antes, si morís antes de 1000m conservás la mitad
21. **Tarjeta fidelidad**: cada 10 partidas, una con ×2 palitos
    → Cada 10 partidas jugadas, la siguiente da palitos dobles
22. **Ascenso a 3000m**: desbloquea upgrades "élite"
    → Al llegar a 3000m se desbloquean mejoras avanzadas más caras y potentes
23. **Palitos por anuncio** (opcional)
    → Ver un anuncio voluntario a cambio de palitos
24. **Barro por compartir resultado**
    → Compartir tu distancia en redes da barros como recompensa
25. **Bono racha semanal**: 7 días seguidos → bonus grande
    → Si jugás 7 días seguidos, al 7mo día bonus grande de palitos
26. **Tasa mejora de conversión barro→palitos con nivel**
    → Cuanto más alto tu nivel, mejor tasa de conversión barro→palitos
27. **Multa por revive**: cada revive cuesta +50 palitos
    → Si revivís varias veces en una partida, cada revive cuesta 50 más
28. **Bono explorador extremo**: 8000m → bonus permanente
    → Llegar a 8000m da un bonus permanente de ×1.05 a todos los palitos
29. **Barra de viaje total**: cada 10000m acumulados → bonus
    → Cada 10000m totales entre todas las partidas, bonus de palitos
30. **Regalo de cumpleaños** (fecha configurable → bonus)
    → Si configurás tu cumpleaños, ese día recibís un bonus especial

## 🌪️ ENCUENTROS / EVENTOS NUEVOS — 30 ideas

1. **Túnel de viento**: 3s sin aletear, avanza solo
   → Zona donde el viento empuja al pájaro automáticamente por 3s
2. **Río vertical**: obstáculos suben desde abajo
   → En vez de venir desde la derecha, los obstáculos vienen desde abajo
3. **Granizo**: partículas caen, frenan 0.3s
   → Gotas de granizo caen del cielo, si te pegan frenás 0.3s
4. **Eclipse**: 2s oscuro total, solo brillan barros
   → Todo se oscurece, solo ves los barros que brillan
5. **Espejismo**: barros falsos que se desvanecen
   → Aparecen barros que parecen reales pero desaparecen al tocarlos
6. **Corriente ascendente**: 2s sube solo
   → ✅ Corriente de aire que eleva al pájaro automáticamente por 2s
7. **Muro de ramas**: obstáculo horizontal ancho
   → Pared ancha horizontal que cubre 1/3 de la pantalla
8. **Zona de nubes**: obstáculos semitransparentes
   → Niebla que hace los obstáculos difíciles de ver
9. **Abejas**: enjambre persigue al pájaro
   → Enjambre que sigue la Y del pájaro, hay que esquivarlo
10. **Multiplicador ×2 global**: 60s palitos dobles
    → Todo palito ganado es doble durante 60s
11. **Viento en contra**: 4s, velocidad mitad, más aleteo
    → ✅ Viento que frena al pájaro a la mitad de velocidad por 4s
12. **Marea de barro**: el piso sube temporalmente
    → El nivel del piso sube, reduciendo el espacio vertical disponible
13. **Enjambre de mosquitos**: nube que tapa visión parcial
    → Nube de puntos negros que tapa parte de la pantalla
14. **Espejismo de agua**: fondo como lago, distrae
    → El fondo se ve como agua, distrae visualmente al jugador
15. **Terremoto**: pantalla tiembla 2s, obstáculos erráticos
    → La cámara tiembla fuerte y los obstáculos se mueven erraticamente
16. **Lluvia oblicua**: partículas diagonales
    → Lluvia que cruza la pantalla en diagonal visualmente
17. **Corriente de chorro**: 3s velocidad ×3, sin control
    → Ráfaga que empuja al pájaro a ×3 automáticamente, solo esquivar
18. **Aire polvoriento**: partículas densas reducen visión
    → Partículas de polvo densas que reducen la visibilidad
19. **Campo magnético**: barros atraídos/repelidos
    → Los barros se atraen o repelen según el lado del campo
20. **Oleada de energía**: pulso visual L→R
    → Pulso de luz que recorre la pantalla de izquierda a derecha
21. **Neblina tóxica**: baja altura empuja hacia abajo
    → Si estás abajo, una niebla te empuja hacia el piso
22. **Gravedad cero**: 2s no caés, solo aleteo te mueve
    → La gravedad se desactiva 2s, solo el aleteo te mueve verticalmente
23. **Lluvia de estrellas**: partículas brillantes + 1 barro
    → Estrellas fugaces caen, si agarrás una das 1 barro
24. **Eclipse solar**: todo oscuro salvo horizonte 3s
    → El sol se tapa 3s, solo se ve la silueta del horizonte
25. **Tromba de agua**: cilindro desplaza obstáculos
    → Tromba que cruza y desplaza obstáculos a su paso
26. **Frente frío**: todo más lento (pájaro incluido)
    → Todo se vuelve más lento, incluido el pájaro
27. **Frente cálido**: todo más rápido
    → Todo se vuelve más rápido, incluido el pájaro
28. **Avalancha (Puna)**: obstáculos caen desde arriba
    → En Puna, rocas caen desde el techo de la pantalla
29. **Geiser (Puna)**: chorro vertical empuja arriba
    → En Puna, chorros de vapor empujan al pájaro hacia arriba
30. **Migración de mariposas**: cruzando, 1 barro al tocarlas
    → Grupo de mariposas cruza la pantalla, si tocás una das 1 barro

---

*Próximo paso sugerido: elegir 3–5 ideas del banco y arrancar implementación.*
