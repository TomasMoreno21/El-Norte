# El Norte — Memoria del Proyecto

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
| collector | Coleccionista | bolas_total | 3, 5, 10 |
| persistent | Persistente | deaths | 20, 35, 50 |
| storm_survivor | Tormentero | storms | 3, 10, 25 |
| buyer | Comprador | total_upgrades_bought | 3, 7, 15 |
| calma_survivor | Sereno | calmas_survived | 3, 10 |
| maxed_out | Al Maximo | all_maxed | 1 |
| birder | Pajarero | all_birds | 1 |
| trato_hecho | Trato Hecho | kiwi_accepts | 20 |
| rey_tormentas | Rey de Tormentas | storms_in_run | 6 |
| llanura | Llanuras | distance | 2200m |
| norte | Norte (Puna) | distance | 4600m |
| por_los_pelos | Por los Pelos | revives_used | 1, 5, 10 |
| rico | Rico | palitos_balance | 1000, 3000, 8000 |
| multiuso | Multiuso | bird_uses | 2, 3, 4 |

## Kiwi
- Cooldown: 20s + 8% por spawn. Upgrade ×0.02/lvl.
- Power-ups: shield(35🪵), turbo(40🪵), x2_bolas(25🪵), miniatura(20🪵), x2_palitos(60🪵), bola_extra(35🪵, requiere Trato Hecho).
- 1 gratis siempre primero. "Rechazar" al final.

## Variables persistentes (DataManager)
- palitos_balance, bolas_balance, upgrades, unlocked_birds, active_bird
- bolas_total, deaths, storms_survived, max_distance, kiwi_accepts, total_upgrades_bought, calmas_survived
- completed_achievements: Dictionary, revives_used, used_birds[]
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

## Branch: implementacion-sprites (sin mergear)
Contiene: game feel completo, kiwi _draw(), storm tuning, menu sprites, lluvia de barro, etc.

---

# 🪵 BANCO DE IDEAS — Mejoras Potenciales

*Guardado el 18/6/2026. Ideas clasificadas por área, priorizadas por facilidad de integración y valor.*

---

## 🎮 GAME FEEL (Juice) — 30 ideas

1. **Efecto elástico en contador de barro**: Label rebota con `ease out back`
2. **Pop de spawn en obstáculos**: escala 0→1 en 0.15s
3. **Línea de guía predictiva**: trayectoria punteada si soltás
4. **Screen shake al tocar techo/piso**
5. **VHS glitch sutil al cambiar de bioma**
6. **Estrellitas al comprar upgrade**: partículas amarillas
7. **Latido del HUD cerca del récord personal**
8. **Onda de choque circular al activar turbo**
9. **Score animado**: números rotan al incrementarse
10. **Chispas en bordes del pájaro a alta velocidad**
11. **Splash de color al entrar a nuevo bioma**
12. **Barro brilla al estar por desaparecer**
13. **Ondulación de calor en Puna** (shader simple)
14. **Viñeta dinámica según altura del pájaro**
15. **Flash breve en HUD cada 100m**
16. **Rebote gelatinoso en botones**
17. **Círculo expansivo al morir**
18. **Parpadeo del pájaro si está idle >2s**
19. **Contracción horizontal al cambiar de dirección**
20. **Barro se agranda con la distancia**
21. **Cámara "respira" (zoom leve) antes del slow-motion de muerte**
22. **Polvo al aterrizar después de estar en techo**
23. **Pixelación/glitch progresivo cuanto más cerca de morir**
24. **Horizonte se tiñe del color del próximo bioma 50m antes**
25. **Micro-sacudón al pasar múltiplos de 100 en score**
26. **Tono de luz cambia según distancia (atardecer simulado)**
27. **Estela de polvo de estrellas en turbo**
28. **Brillo especular en barros según sol virtual**
29. **After-image fantasma de obstáculos al pasar**
30. **Lluvia fina permanente en Cordillera (partículas continuas)**

## ⚙️ GAMEPLAY — 30 ideas

1. **Elección de mejora temporal a los 1000m** (tipo roguelite)
2. **Knockback al golpear con escudo** (empuja, no mata)
3. **Fatiga**: 10 flaps rápidos → cooldown 1s
4. **Planeo**: soltar da pequeño lift extra
5. **Barro de riesgo**: rozar obstáculo da +1 barro
6. **Muerte barata gratis hasta 500m** (primera no cuenta)
7. **Power-up congelar**: obstáculos quietos 2s
8. **Hold-to-mine**: más barro si mantenés
9. **Modo ayuda tras 3 muertes seguidas <1000m**
10. **Vender upgrades**: recuperar 50%
11. **Convertir palitos → barro** (ratio variable)
12. **Tap arriba/abajo como control alternativo**
13. **Doble tap = mini turbo gratuito** (5s cd)
14. **Línea de altura segura en obstáculos altos**
15. **Hitbox se reduce 10% a alta velocidad**
16. **Invlunerabilidad creciente**: 0.5s→1s tras racha
17. **Cerrar kiwi tocando afuera del menú**
18. **Descuento por muerte en tienda** (5% c/u, max 50%)
19. **Reset de mejoras pagando palitos**
20. **Indicador de peligro si estás mucho en misma altura**
21. **Power-up rebote**: tocar borde rebota 1 vez
22. **Empuje extra al aletear justo saliendo de obstáculo**
23. **Combo**: 3 barros seguido rápido → ×1.5
24. **Aire caliente en Puna**: eleva al pájaro gratis
25. **Skill shot**: gap muy justo entre obstáculos da bonus
26. **Inercia al soltar**: desacelera suave, no instantáneo
27. **Barros en oleadas sinusoidales** (no estáticos)
28. **Obstáculos que rotan 360° lentamente**
29. **Obstáculos rompibles si venís muy rápido**
30. **Barro magnético**: atrae desde más lejos 5s

## 🎨 VARIEDAD DE CONTENIDO — 30 ideas

1. **Cactus rodador**: obstáculo circular con textura de cactus
2. **Pájaros enemigos estáticos** en distancias fijas
3. **Power-up brújula**: muestra distancia al próximo kiwi
4. **Logro "Maratón"**: llegar a 10000m
5. **Logro "Coleccionista"**: comprar todos los pájaros
6. **Logro "Sin manos"**: 2000m sin tocar pantalla
7. **Logro "Ladrón"**: 1000 barros totales acumulados
8. **Logro "Superviviente"**: 3 tormentas en una partida
9. **Logro "Veloz"**: 3000m en menos de 90s
10. **Logro "Rico"**: 1000 palitos sin gastar
11. **Logro "Atrevido"**: gap entre obstáculos ≤110px
12. **Pájaro Cardenal**: +10% flap, +5% palitos (1000 palitos totales)
13. **Pájaro Benteveo**: +1 vida, -10% velocidad (50 partidas)
14. **Escudo con 3 cargas** si upgrade al máximo
15. **Modo espejo**: todo invertido horizontalmente
16. **Modo nocturno**: fondo oscuro, siluetas
17. **Evento "fiesta" cada 2000m**: barros como confeti
18. **Item "alas extra"**: vida extra por 100 palitos
19. **Item "detector de barro"**: radar en HUD
20. **Logro "Pampeano"**: 5000m con cada pájaro
21. **Evento "langostas"**: 60s, evitalas o perdés barro
22. **Moneda "plumas"**: coleccionable raro para skins
23. **Power-up fantasma**: atravesar obstáculos 2s
24. **Logro "Veterano"**: 100 partidas jugadas
25. **Pájaro Lechuza**: visión nocturna (modo noche)
26. **Cactácea rodante que rebota** (va y viene)
27. **Troncos diagonales** (obstáculo 45°)
28. **Cardones/arbustos altos** que obligan a bajar
29. **Rocas colgantes**: caen desde arriba
30. **Plataformas móviles verticales**: suben y bajan

## 🧩 UI / SETTINGS / QoL — 30 ideas

1. **Icono kiwi disponible parpadea en HUD**
2. **Tooltip en power-ups del kiwi** (explicación + precio)
3. **Botón compartir puntuación**: screenshot al morir
4. **Slider de sensibilidad de flap**
5. **Opción Hold vs Tap**
6. **Opción tamaño del pájaro**: chico/mediano/grande
7. **Tema claro/oscuro para la UI**
8. **Modo reducir movimiento**: desactiva shake y partículas
9. **Beneficio exacto en tienda**: "+15% velocidad"
10. **Stats comparativas en Skins** vs pájaro activo
11. **Barra de progreso del próximo upgrade en tienda**
12. **Alerta de fin de power-up** (destello)
13. **Mostrar "quedaste a Xm del récord" al morir**
14. **Stats de partida en pausa**: barros, palitos, kmh
15. **Confirmación antes de gastar >200 palitos**
16. **Tip aleatorio en pantalla de muerte**
17. **Atajo muerte → menú principal sin transición extra**
18. **Historial de últimas 10 partidas**
19. **Botón "reset data" oculto (doble confirmación)**
20. **Autopause al perder foco**
21. **Modo ahorro batería (30fps)**
22. **Feedback háptico**: vibrar al agarrar barro/chocar
23. **Notificación kiwi listo desde el menú**
24. **Preview hitbox del pájaro (debug toggle)**
25. **Tooltip "primera vez" en cada power-up del kiwi**
26. **Widget "próximo hito"**: cuánto falta para el milestone
27. **Mapa minimalista del viaje (sur→norte) en esquina**
28. **Icono de evento activo en HUD** (ráfaga/tormenta/calma)
29. **Botón "siguiente partida" directo desde muerte**
30. **Opción de texto más grande (accesibilidad)****

## 💰 ECONOMÍA / PROGRESIÓN — 30 ideas

1. **Bono bienvenida**: 50 palitos al abrir primera vez
2. **Bono por volver a jugar inmediato**: +20% palitos
3. **Racha de partidas**: +5% c/u hasta +25%
4. **Precio dinámico**: comprar sube leve el costo
5. **Descuento rotativo semanal en upgrades**
6. **Canjear barros → palitos**: 1 barro = 5 palitos
7. **Bono explorador**: llegar a nuevo bioma da palitos
8. **Inversión con el kiwi**: prestás, devuelve con interés
9. **Límite de gasto diario en tienda**
10. **Palitos no gastados → conversión parcial a barros al morir**
11. **Bonificación por distancia exacta**: morir en múltiplo de 500m → bonus
12. **Interés compuesto**: palitos no gastados generan 1% por partida
13. **Logro "inversor"**: 5000 palitos sin gastar
14. **Logro "gastador"**: gastar 10000 palitos totales
15. **Oferta del día**: upgrade aleatorio 30% desc.
16. **Bono de regreso**: no jugar 24h → palitos gratis al volver
17. **Bono horario**: jugar de noche da ×1.1 palitos
18. **Megabono 5000m**: palitos ×3 (además de biome)
19. **Fianza**: pagar palitos para no perder barros al morir
20. **Seguro de barro**: 50 palitos pre-partida, si morís <1000m conservás mitad
21. **Tarjeta fidelidad**: cada 10 partidas, una con ×2 palitos
22. **Ascenso a 3000m**: desbloquea upgrades "élite"
23. **Palitos por anuncio** (opcional)
24. **Barro por compartir resultado**
25. **Bono racha semanal**: 7 días seguidos → bonus grande
26. **Tasa mejora de conversión barro→palitos con nivel**
27. **Multa por revive**: cada revive cuesta +50 palitos
28. **Bono explorador extremo**: 8000m → bonus permanente
29. **Barra de viaje total**: cada 10000m acumulados → bonus
30. **Regalo de cumpleaños** (fecha configurable → bonus)**

## 🌪️ ENCUENTROS / EVENTOS NUEVOS — 30 ideas

1. **Túnel de viento**: 3s sin aletear, avanza solo
2. **Río vertical**: obstáculos suben desde abajo
3. **Granizo**: partículas caen, frenan 0.3s
4. **Eclipse**: 2s oscuro total, solo brillan barros
5. **Espejismo**: barros falsos que se desvanecen
6. **Corriente ascendente**: 2s sube solo
7. **Muro de ramas**: obstáculo horizontal ancho
8. **Zona de nubes**: obstáculos semitransparentes
9. **Abejas**: enjambre persigue al pájaro
10. **Multiplicador ×2 global**: 60s palitos dobles
11. **Viento en contra**: 4s, velocidad mitad, más aleteo
12. **Marea de barro**: el piso sube temporalmente
13. **Enjambre de mosquitos**: nube que tapa visión parcial
14. **Espejismo de agua**: fondo como lago, distrae
15. **Terremoto**: pantalla tiembla 2s, obstáculos erráticos
16. **Lluvia oblicua**: partículas diagonales
17. **Corriente de chorro**: 3s velocidad ×3, sin control
18. **Aire polvoriento**: partículas densas reducen visión
19. **Campo magnético**: barros atraídos/repelidos
20. **Oleada de energía**: pulso visual L→R
21. **Neblina tóxica**: baja altura empuja hacia abajo
22. **Gravedad cero**: 2s no caés, solo aleteo te mueve
23. **Lluvia de estrellas**: partículas brillantes + 1 barro
24. **Eclipse solar**: todo oscuro salvo horizonte 3s
25. **Tromba de agua**: cilindro desplaza obstáculos
26. **Frente frío**: todo más lento (pájaro incluido)
27. **Frente cálido**: todo más rápido
28. **Avalancha (Puna)**: obstáculos caen desde arriba
29. **Geiser (Puna)**: chorro vertical empuja arriba
30. **Migración de mariposas**: cruzando, 1 barro al tocarlas

---

*Próximo paso sugerido: elegir 3–5 ideas del banco y arrancar implementación.*
