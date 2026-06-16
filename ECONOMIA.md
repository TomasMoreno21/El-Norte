# Sistema Económico — Informe de Diseño

## 1. Situación Actual

| Concepto | Valor |
|----------|-------|
| 🪵 fórmula | `(dist/10) × (1 + lv_palitos_base) × bird_mult` |
| 🪵 revive | 200 flat |
| 🪵 kiwi pagado | 30 |
| 🪵 para maxear mejoras | ~26.085 |
| 🔵 de logros | ~42 |
| 🔵 pájaros (total) | 120 (0+30+40+50) |
| 🔵 recolección in-run | 1–3 por partida |

**Problemas identificados:**
1. No hay recompensa extra por llegar lejos (tasa lineal)
2. Bolas de logros cubre solo 1/3 de los pájaros
3. Sin incentivo a batir récords personales
4. Progresión early se siente lenta (primeras 10 partidas)

---

## 2. Cambios Propuestos

### 2a. Palitos — Multiplicador por Bioma

La fórmula pasa a ser:

```
palitos = int(dist/10) × (1 + lv_palitos_base) × biome_mult × bird_mult
```

| Bioma | Distancia | biome_mult |
|-------|-----------|------------|
| Cordillera | 0–2200m | ×1.0 |
| Llanuras | 2200–4600m | ×1.5 |
| Puna | 4600m+ | ×2.0 |

**Impacto:** Una carrera de 5000m da ~2.7× más palitos que hoy.

---

### 2b. Bonus por Cruce de Bioma (único)

La primera vez que llegás a cada hito, al morir recibís un bonus extra:

| Hito | Bonus 🪵 |
|------|----------|
| 500m | +10 |
| 1000m | +20 |
| 2200m (Cordillera→Llanuras) | +50 |
| 4600m (Llanuras→Puna) | +100 |

---

### 2c. Bolas por Récord Personal (único)

Al superar un nuevo `max_distance`, se otorgan 🔵 automáticamente al morir:

| Récord superado | 🔵 |
|-----------------|-----|
| 500m+ | 1 |
| 1000m+ | 2 |
| 2200m+ | 3 |
| 4600m+ | 5 |

---

## 3. Progresión Estimada

| # partidas | Dist típica | 🪵/run | Acumulado 🪵 | Hito |
|-----------|-------------|--------|-------------|------|
| 1–5 | 200m | 20 | ~100 | Velocidad lv1 |
| 6–15 | 500m | 50 | ~500 | Palitos lv1–2 |
| 16–30 | 800m | 80 | ~1500 | Velocidad lv3, Kiwi lv2 |
| 30–50 | 1200m | 168 (×1.5) | ~4000 | Velocidad lv4–5, Palitos lv3 |
| 50–80 | 2000m+ | 400+ | ~12000 | Mejoras lv6–7 |
| 80–120 | 3000m+ | 675+ | ~30000 | Cerca de maxear todo |

**🔵 Acumuladas:** ~42 de logros + ~15 de récords + ~40 de recolección = ~97 → casi suficiente para todos los pájaros (~120).

---

## 4. Cambios Técnicos Necesarios

**data_manager.gd:**
- `calculate_palitos_earned()`: agregar `biome_mult` según distancia
- Nuevas variables: `first_milestones_claimed` (Array), `record_bolas_claimed` (Array)
- Nuevos métodos: `claim_distance_milestones(dist)`, `claim_record_bolas(dist)`
- Persistencia y reset de las nuevas variables

**death_screen.gd:**
- Llamar `claim_distance_milestones(distance)` y mostrar bonus
- Llamar `claim_record_bolas(distance)` y mostrar bonus de 🔵
- Mostrar en UI: "+50 palitos por llegar a Llanuras!" / "+2 bolas por récord!"

---

## 5. Preguntas

1. **¿Multiplicador de bioma te parece bien o preferís otra curva?**
2. **¿Los bonus de cruce de bioma están bien de valores?**
3. **¿El sistema de bolas por récord te cierra o preferís otra fuente de 🔵?**
4. **¿Algo que ajustar en la progresión esperada?**
