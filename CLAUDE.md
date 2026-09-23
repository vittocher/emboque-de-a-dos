# CLAUDE.md — Emboque de a Dos

## Qué es

Puzzle **cooperativo local de 2 jugadores** (estilo *Fireboy & Watergirl*) en **Godot 4.7**, para **web (Newgrounds)**. Tema: amistad y tradición chilena. Concepto completo en `EmboqueDA2 Concepto.pdf`.

De cada jugador cuelga media mitad del emboque por una cuerda con física de péndulo: **J1 = campana**, **J2 = palito**. Objetivo de cada nivel: **embocar** (palito dentro de la campana).

## Setup

- **Godot 4.7.2**. Linux: `~/Godot/Godot_v4.7.2-stable_linux.x86_64`. Windows: `C:\Users\vitto\OneDrive\Desktop\Godot\Godot_v4.7.2-stable_win64(_console).exe`.
- Escena de arranque: `scenes/ui/main_menu.tscn`. Para probar gameplay, abrir un nivel y usar **F6**.
- Resolución base 1280×720, stretch `canvas_items` + `keep`. Física a **120 Hz**.

### Validación headless

```bash
GODOT=~/Godot/Godot_v4.7.2-stable_linux.x86_64
"$GODOT" --headless --editor --quit-after 2 --path .          # importar recursos
"$GODOT" --headless --path . --quit-after 150 > out.log 2>&1   # correr N frames
grep -iE "error|warning|script err" out.log
"$GODOT" --headless --path . res://scenes/level_2.tscn        # escena puntual
```

Redirigir a archivo y filtrar aparte (el pipe directo puede colgarse). Para simular input usar `Input.parse_input_event(ev)` (`action_press` no llega a `_input`); medir en un nodo que procese último en el árbol.

## Controles

| | Mover | Saltar | Abajo / desenganchar | Soltar cuerda | Tirar cuerda |
|---|---|---|---|---|---|
| **J1** (`p1`) | `A`/`D` | `W` | `S` | `R` | `T` |
| **J2** (`p2`) | `←`/`→` | `↑` | `↓` | `,` | `.` |

Acciones `<prefix>_{left,right,jump,down,release,pull}` con `physical_keycode`. Enganchado: soltar/tirar = rapel. **Esc** = pausa.

## Arquitectura

```
scenes/
  main.tscn / level_2.tscn   Niveles. level_2 agrega bloques rojos one-way, 3 ganchos y coleccionables.
  test_death.tscn            Nivel de prueba de zonas de muerte.
  player.tscn                CharacterBody2D + RopeAnchor (Marker2D, "la mano").
  emboque.tscn               Rope (Line2D); el extremo se instancia en runtime (end_scene).
  palito.tscn / campana.tscn Extremos RigidBody2D. Campana = C de 3 rects + CavitySensor + Mouth/Cavity.
  hook_point.tscn            Area2D de enganche.
  collectible.tscn           Area2D que suma puntos al tocarla un jugador.
  *_death_zone.tscn          Zonas de muerte: player (roja), emboque (morada), both (naranja).
  ui/                        main_menu, level_selector, settings, pause_menu.
scripts/
  player.gd          Plataformero parametrizado por input_prefix.
  emboque.gd         Coordina la cuerda: largo, enganche, límite del jugador, visual.
  rope_end.gd        Restricción de cuerda del extremo en _integrate_forces.
  win_manager.gd     Magnetismo (distancia + ángulo) y victoria.
  score_manager.gd   Puntaje (grupo "score_manager") + ScoreLabel. Requerido si el nivel tiene coleccionables.
  collectible.gd     Suma `points` al ScoreManager y se libera.
  *_death_zone.gd    Recargan el nivel al contacto.
  pause_menu.gd      CanvasLayer con process_mode ALWAYS; Continuar / Reiniciar.
```

**Cada nivel debe incluir:** `WinManager`, `Player1/2`, `Emboque1/2` (con `end_scene` + `end_kind`), y el menú de pausa (`ui/pause_menu.tscn`, o inline como en `main`/`level_2`). Orden en el árbol: **Players → WinManager → Emboques**, para que fuerzas y correcciones se apliquen el mismo frame.

**Flujo UI:** `main_menu` → `level_selector` (Nivel 1, Prueba: muerte, Nivel 2) → nivel. Niveles en `LEVELS` de `level_selector.gd` (a futuro: grafo conectado).

### Capas de física

| Capa (valor) | Qué | Mask |
|---|---|---|
| 1 (1) | Terreno | — |
| 2 (2) | Jugadores | 1 |
| 3 (4) | Campana | 9 (terreno + palito) |
| 4 (8) | Palito | 5 (terreno + campana) |
| 5 (16) | HookPoint | — (`HookSensor` de los extremos: mask 16) |

`CavitySensor` mask 8. Zonas de muerte: jugador mask 2, emboque mask 12 (seteado en `_ready`). Collectible mask 2. Los extremos colisionan entre sí; los jugadores no colisionan con nada salvo terreno.

### Cuerda

`emboque.gd` en `_physics_process`: ajusta `rope_length` (soltar/tirar) → desengancha con `abajo` → pasa al extremo `anchor_position`, `rope_length`, `hooked`, `hook_position` → `_limit_player` (si el extremo está a más de `rope_length`, arrastra al jugador con `_move_sliding`) → actualiza la `Line2D`.

`rope_end.gd` en `_integrate_forces`: si `hooked`, fija el extremo al gancho; si no, restricción **por velocidad** (quita la velocidad radial hacia afuera) y capa la rapidez a `max_speed` (300).

API para `WinManager`: `get_end()`, `get_end_position()`, `get_cavity_sensor()`.

### Victoria

Si la punta del palito está a menos de `magnet_radius` (70) de la boca de la campana, `win_manager.gd` los atrae (`linear_accel` 900) y los alinea (`angular_gain` 2.5). Victoria = palito dentro del `CavitySensor` (respaldo: muy cerca y alineado). Muestra `WinLabel` y reinicia tras `restart_delay`.

### Zonas de muerte

Scripts separados jugador/emboque (para mecánicas distintas a futuro); la zona "ambos" compone dos `Area2D` hijas. Exponen `signal triggered(body)` y `@export reload_on_death` (`false` en tests). Recargan con `get_tree().call_deferred("reload_current_scene")`.

## Trampas conocidas (NO repetir)

- **Nunca teletransportar** (`global_position = ...`) para corregir la cuerda: atraviesa paredes. Usar movimientos con barrido o restricción por velocidad.
- **`move_and_collide` no desliza**: se detiene en el primer contacto y descarta el resto. Usar `_move_sliding()`.
- **Medir el progreso de la restricción por reducción real de distancia**, no por cuánto se movió (deslizar por un muro no acorta la cuerda).
- **Tunneling entre cuerpos delgados:** se evita con `continuous_cd = 2` + `max_speed` + física a 120 Hz. Mantener `max_speed / ticks` bastante menor que la pared más fina (6px).
- **Formas cóncavas:** armarlas con varios `CollisionShape2D` convexos.
- **Definir `_integrate_forces` no desactiva colisiones** (salvo `custom_integrator = true`).
- **No liberar/recargar dentro de callbacks de física** (`body_entered`, etc.): usar `call_deferred`.
- **Tipado:** propiedades de un nodo tipado como `Node2D` devuelven Variant y rompen `:=`; tipar con el `class_name` real.
- **UIDs:** no inventar `uid://` a mano; en `ext_resource` basta el `path`. Que Godot re-guarde escenas al abrirlas es esperado.
- **Tests de colisión con péndulo:** medir el pico, no el frame final.

Tamaños placeholder: jugador 40×64, palito 22×6, campana ~18×24 (paredes 6px, hoyo ~12px). Todo tuneable en el Inspector.

## Estado

**Hecho:** personaje, cuerda con largo variable, colisiones de extremos y límite del jugador, enganche/rapel, victoria con magnetismo, palito/campana como RigidBody que colisionan, menús (principal, selector, ajustes, pausa), zonas de muerte, **Nivel 2 con coleccionables y puntaje**, upgrade a 4.7.2.

**Pendiente:** Fase 6 — nivel de prueba definitivo + tuning de sensación (magnetismo, masas, largos, velocidades).

**Post-prototipo:** objetos empujables, mapa de progresión, celebración estilo Peggle (zoom + cámara lenta), estética Tikitiklip, sonido, export web.

## Convenciones

- Comentarios y textos de usuario en **español**; GDScript idiomático de Godot 4.
- Placeholders geométricos (`Polygon2D`) hasta que llegue el arte.
- Cámara **fija** del tamaño de la pantalla en los primeros niveles.
