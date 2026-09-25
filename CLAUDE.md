# CLAUDE.md — Emboque de a Dos

Guía para trabajar en este repositorio. Léela antes de tocar código.

## Qué es el juego

**Emboque de a Dos**: puzzle **cooperativo local de 2 jugadores** (estilo *Fireboy & Watergirl*), en **Godot 4.7.2**, apuntado a **web (Newgrounds)**. Tema: amistad y tradición chilena.

De cada personaje cuelga **media mitad del emboque** por una cuerda: J1 lleva la **campana**, J2 el **palito**. La física de la cuerda (balanceo tipo péndulo) es la mecánica central. El objetivo de cada nivel es **juntar palito + campana** (embocar). El concepto completo está en `EmboqueDA2 Concepto.pdf`.

## Setup / cómo correr

- **Editor:** Godot **4.7.2** (ejecutable en `C:\Users\vitto\OneDrive\Desktop\Godot\Godot_v4.7.2-stable_win64.exe`; la variante `..._console.exe` sirve para CLI headless). En esa misma carpeta también está el 4.6 (versión previa). `config/features` en `project.godot` = `4.7`.
- **Abrir:** importar el `project.godot` de esta carpeta desde el Project Manager, o **F5** para jugar.
- **Escena de arranque:** `res://scenes/ui/main_menu.tscn` (menú). El **nivel de gameplay** es `res://scenes/main.tscn`. Durante el desarrollo del gameplay, abrir `main.tscn` y correr con **F6** (ejecutar escena actual) para saltarse el menú.
- **Resolución base:** 1280×720 (16:9). Stretch `canvas_items` + aspect `keep` (default en Godot 4, por eso el editor lo omite del archivo). No pixel-art; se adapta a cualquier tamaño de embed sin deformar.

### Validación headless (sin abrir el editor)

```bash
GODOT="/c/Users/vitto/OneDrive/Desktop/Godot/Godot_v4.7.2-stable_win64_console.exe"
# Importar recursos:
"$GODOT" --headless --editor --quit-after 2 --path .
# Correr N frames de la escena principal y filtrar errores:
"$GODOT" --headless --path . --quit-after 150 2>&1 | grep -iE "error|warning|script err"
```

Se puede correr una escena puntual pasándola como argumento posicional:
`"$GODOT" --headless --path . res://ruta/escena.tscn`. Para tests que simulan input, usar `Input.action_press("accion")` / `Input.action_release(...)` y medir en un nodo que procese **último** en el árbol. Redirigir la salida a un archivo y filtrar aparte evita cuelgues del pipe.

## Controles (Input Map en `project.godot`)

| | Mover | Saltar | Soltar cuerda | Tirar cuerda | Lanzar* |
|---|---|---|---|---|---|
| **J1** (`input_prefix = "p1"`) | `A` / `D` | `W` | `R` | `T` | `G` |
| **J2** (`input_prefix = "p2"`) | `←` / `→` | `↑` | `,` | `.` | `L` |

\* Solo en niveles con la mecánica de lanzar activada (ver "Tomar y lanzar el emboque").

Las acciones siguen el patrón `<prefix>_<accion>`: `_left`, `_right`, `_jump`, `_down` (S / flecha abajo), `_release` (soltar = alargar), `_pull` (tirar = acortar), `_throw` (lanzar). Usan `physical_keycode` (independiente del layout del teclado).

**Esc** (`ui_cancel`) abre/cierra el **menú de pausa** en el nivel (ver `pause_menu.gd`).

**Enganchado** (ver "Balanceo enganchado"): izquierda/derecha **bombean** el balanceo, `saltar` **se lanza** desde la cuerda (impulso del balanceo + salto), `abajo` (S / ↓) se **suelta** conservando la velocidad, `soltar` baja al jugador (rapel) y `tirar` lo sube.

**Lanzar** (solo en algunos niveles): con la cuerda ya al mínimo, `tirar` otra vez **toma el emboque en la mano**; `lanzar` empieza a **apuntar** (línea punteada que va y vuelve de 0° a 60° hacia arriba; el jugador queda quieto y izquierda/derecha solo lo giran); `lanzar` otra vez lo **lanza** (la cuerda pasa al máximo). `soltar` lo deja caer (tomado o apuntando).

## Arquitectura

```
scenes/
  main.tscn            Nivel de gameplay: cámara fija (640,360), suelo, 2 plataformas,
                       muro central, 2 HookPoint, WinManager, 2×(Player+Emboque), UI/WinLabel.
  player.tscn          CharacterBody2D + colisión + Polygon2D placeholder + RopeAnchor (Marker2D, "la mano").
  emboque.tscn         Node2D raíz: solo Rope (Line2D). El extremo se instancia en runtime.
  palito.tscn          Extremo RigidBody2D: rectángulo largo y flaco + Tip + HookSensor. (J2)
  campana.tscn         Extremo RigidBody2D: forma de C (3 rects) + CavitySensor + Mouth/Cavity + HookSensor. (J1)
  hook_point.tscn      Area2D (punto de enganche del entorno) + rombo visual.
  player_death_zone.tscn  Area2D que mata al JUGADOR al tocarlo (visual roja).
  emboque_death_zone.tscn Area2D que mata al EMBOQUE al tocarlo (visual morada).
  both_death_zone.tscn    Zona que mata a ambos; compone los dos scripts. Arte: fuego (assets/hazards/ambos, 9 FPS).
                          player_death_zone.tscn tiene púas (assets/hazards/jugadores, 9 FPS) y emboque_death_zone.tscn
                          caca (assets/hazards/emboques, 9 FPS). En las tres el arte lo
                          pone un hijo `Art` con hazard_art.gd (@tool, class HazardArt): repite la animación a lo
                          ancho en cuadros tan altos como la zona, sin deformarse con la escala de la instancia.
                          Los Polygon2D de color quedaron ocultos.
  test_death.tscn      Nivel de prueba de las zonas de muerte (2 jugadores + 2 emboques + las 3 zonas).
  test_physics.tscn    "Prueba: Física": copia del Nivel 1 SIN muro central (para probar el balanceo), plataformas
                       más afuera (x=170 / x=1110), muros laterales justo fuera de cámara (x<0 y x>1280, no se
                       puede salir del nivel), 3 HookPoint (izq/centro/der) y 2 cajas (PushBox) en el suelo.
  test_throw.tscn      "Prueba: lanzar": primer nivel con la mecánica de lanzar (LevelRules.throw_enabled). Una
                       torre al centro (240×270, techo y=410) que no se alcanza saltando; un HookPoint afuera de
                       cada esquina de arriba. Cada jugador lanza al gancho de su lado, sube tirando la cuerda y
                       salta arriba de la torre, donde se juntan para embocar. Label de ayuda arriba.
  terrain_art.tscn     Arte del terreno (TerrainArt, scripts/terrain_art.gd, @tool): instanciado una vez por nivel,
                       cubre cada StaticBody2D con assets/entorno/colision/: rectángulos horizontales = piso armado
                       con piso_left + piso_neutral (repetido) + piso_right, o piso.png si cabe una sola tabla;
                       verticales = pared.png. Sin deformarse. En juego oculta los Polygon2D "Visual".
  push_box.tscn        Caja empujable (RigidBody2D 64×64, capa 6, rotación bloqueada). Reutilizable en cualquier nivel.
                       Arte: Sprite con assets/props/caja/caja.png (320×320 a escala 0.2); placeholders ocultos.
  closeup_manager.tscn Efecto reutilizable: closeup + cámara lenta al acercarse los extremos (instanciar por nivel).
  collectible.tscn     Area2D recolectable (sopaipilla animada, assets/props/puntos, 2 frames a 6 FPS; rombo oculto): lo toca un jugador o un extremo del emboque (mask 14)
                       → suma puntos y se destruye. La cuerda no recoge (es solo una Line2D).
  level_2.tscn         Segundo nivel, hecho según un boceto del equipo (escala x·0.64, y·0.473): J1 arriba a la
                       izquierda, J2 arriba a la derecha, muro central (hasta y=-400: no se salta por arriba) con
                       una plataforma media a la izquierda (con bloque ROJO encima: mata solo al jugador) y una
                       "T" abajo que lo cruza; bloque NARANJA flotante a la derecha y PISO NARANJA (matan a ambos);
                       2 HookPoint (bajo la plataforma media y a la izquierda de la plataforma de J2),
                       6 coleccionables + ScoreManager/ScoreLabel, WinManager, CloseupManager, pausa inline.
                       Se emboca con los extremos colgando bajo el muro, parados cada uno en su mitad de la T.
  ui/main_menu.tscn      Menú: Jugar, Ajustes, y texto de controles (la línea de lanzar, ThrowControls, en verde).
  ui/level_selector.tscn Selector de niveles (Nivel 1, Prueba: muerte, Nivel 2, Prueba: física, Prueba: lanzar;
                         futuro: grafo conectado).
  ui/settings.tscn       Ajustes: volumen general / música / efectos + pantalla completa.
  ui/pause_menu.tscn     Menú de pausa reutilizable (Esc). Instanciar en cada nivel.
  ui/victory.tscn        Pantalla de victoria (minimalista): puntaje + récord del nivel + "Menú principal".
scripts/
  player.gd        Controlador de plataformas parametrizado por input_prefix + estado de balanceo
                   (péndulo θ/ω) cuando cuelga de un gancho; el Emboque lo maneja vía attach/detach_swing.
  emboque.gd       Coordina la media-cuerda: largo, enganche, límite del jugador, cuerda visual;
                   instancia el extremo (end_scene) y le pasa los parámetros de la cuerda. También
                   tomar / apuntar / lanzar el extremo (si el nivel lo permite) y dibuja la mira punteada.
  rope_end.gd      RigidBody2D del extremo (palito/campana): restricción de cuerda en _integrate_forces;
                   set_held (en la mano: congelado y sin colisiones) y start/end_flight (vuelo sin gravedad).
  level_rules.gd   Nodo (class_name LevelRules, grupo "level_rules") con las mecánicas opcionales de un
                   nivel: casilla throw_enabled. Nivel sin el nodo = todo lo opcional apagado. También
                   THROW_COLOR (verde de la mecánica en los menús) y scene_throw_enabled(escena).
  closeup_manager.gd Closeup de cámara + slowdown (Engine.time_scale) al acercarse los extremos; reutilizable; reinicia time_scale en _exit_tree.
  win_manager.gd   Magnetismo distancia+ángulo entre extremos + victoria (palito dentro de campana).
  hazard_art.gd    Arte animado de una zona de peligro (ver both_death_zone.tscn); reutilizable en cualquier zona.
  player_death_zone.gd   Al entrar un jugador (mask=2) → reinicia el nivel. Señal triggered; export reload_on_death.
  emboque_death_zone.gd  Al entrar un extremo (mask=12 = campana 4 + palito 8) → reinicia. (Scripts separados a propósito.)
  collectible.gd   Area2D: al tocarlo un Player, busca el ScoreManager (grupo "score_manager"), suma `points` y queue_free.
  push_box.gd      Caja empujable (class_name PushBox): el Player la empuja con push(); los extremos la golpean por física.
                   Suena un loop de arrastre mientras se desliza por el piso.
  sfx.gd           AUTOLOAD (Sfx): registro único de efectos de sonido (SOUNDS: nombre → ruta + volumen base),
                   pool de AudioStreamPlayer, play(nombre, pitch, volumen). Sobrevive a la recarga del nivel.
audio/sfx/         Efectos placeholder (WAV 22 kHz mono): step, jump, die, hook, swing, box_push (loop), grab, throw.
tools/generate_sfx.py  Sintetiza los placeholders de audio/sfx (numpy): `python tools/generate_sfx.py`.
  score_manager.gd Lleva el puntaje del nivel y actualiza un Label. Está en el grupo "score_manager" (lo encuentra collectible).
  score_board.gd   AUTOLOAD (ScoreBoard): lleva los datos de la última victoria entre escenas + guarda el highscore
                   por nivel en user://scores.cfg. WinManager lo usa al ganar; victory.gd lo lee.
  pause_menu.gd    Menú de pausa del nivel (Esc): Continuar / Reiniciar. Es un CanvasLayer.
                   La pausa NO es global: cada nivel debe TENER el nodo. Reutilizable vía ui/pause_menu.tscn
                   (test_death lo instancia; main.tscn lo tiene inline en su CanvasLayer "UI").
  ui/*.gd          Lógica de los menús (navegación con change_scene_to_file); victory.gd muestra puntaje + récord.
```

Autoloads (en `project.godot`): **`SettingsManager`** (volumen Master/Música/Efectos, pantalla completa, persistencia — **primero** en la lista: crea los buses de audio antes que nadie los necesite), **`ScoreBoard`** (puntaje entre escenas + highscore por nivel) y **`Sfx`** (efectos de sonido, usa el bus SFX).

### Volumen y buses de audio

`SettingsManager` crea por código dos buses además de "Master" (que ya trae el motor): **`"Music"`** y **`"SFX"`** (`_ensure_buses()`, idempotente), ambos con `send` hacia `"Master"`. Así Master es un fader general (afecta a los dos) y Música/Efectos se balancean aparte. `SettingsManager._start_music()` pone la cueca en el bus Music; `Sfx.gd` pone todo su pool de `AudioStreamPlayer` en el bus SFX; `push_box.gd` hace lo mismo con su sonido de arrastre. Tres sliders independientes ("General" / "Música" / "Efectos") en `ui/settings.tscn` y en el panel de pausa de cada nivel, guardados en `user://settings.cfg` (`audio/master_volume`, `audio/music_volume`, `audio/sfx_volume`).

### Arte y sonido (para diseño)

**Arte del jugador** (`player.tscn`):
```
Visual (Node2D)      ← el código lo inclina (balanceo) y aplasta/estira (squash). No tocar.
  Art (Node2D)       ← el código lo ESPEJA: scale.x = facing (1 = derecha, -1 = izquierda).
    Body, Eye        ← placeholders (ocultos, visible = false)
    Sprite (AnimatedSprite2D) ← arte real: escala 0.21, pies en y = +32, flip_h (los PNG miran a la izquierda)
```
**Arte actual:** `assets/jugadores/p1|p2/` con un `SpriteFrames` por jugador (`p1_frames.tres` / `p2_frames.tres`). `player.gd` le pone al `Sprite` el de su `input_prefix` (exports `frames_p1` / `frames_p2` en `player.tscn`). Animaciones: `idle` (WALK_01 quieto), `walk` (WALK_02 → WALK_01 en loop a **10 FPS**, empieza con el paso abierto para que se note al instante) y `aim` (THROW, al apuntar). Si falta la animación del estado se usa `ANIM_FALLBACK` (`push` → `walk`) o `idle` (así no camina en el aire).
Para poner el arte definitivo: reemplazar los hijos de `Visual/Art` por el dibujo **mirando a la derecha** (el código lo da vuelta). Si se usa un `AnimatedSprite2D` llamado **`Sprite`** dentro de `Art`, el jugador reproduce solo las animaciones cuyos nombres coincidan con `get_anim_state()`: **`idle`, `walk`, `jump`, `fall`, `swing`, `push`, `aim`** (las que falten se ignoran; `aim` = apuntando un lanzamiento). Ya no hay `modulate` en `Player2`: cada jugador tiene su arte. `facing` es público por si otro script lo necesita. Al empezar, cada jugador mira hacia el centro de la pantalla.

**Sonidos**: todos pasan por el autoload `Sfx` (`scripts/sfx.gd`). Para cambiar uno, **reemplazar el archivo con el mismo nombre** en `audio/sfx/` (o cambiar su ruta/volumen en `Sfx.SOUNDS`); WAV u OGG sirven (el loop de la caja se activa por código para ambos). Dónde suena cada uno:

| Sonido | Dónde | Cuándo |
|---|---|---|
| `step` | `player.gd` `_update_footsteps` | Cada 40 px caminados de verdad sobre el piso (no si lo lleva una caja ni si empuja contra un muro). Tono aleatorio 0.9–1.1. |
| `jump` | `player.gd` | Salto desde el piso; al lanzarse desde la cuerda con tono 1.2. |
| `die` | `player_death_zone.gd` / `emboque_death_zone.gd` | Al tocar una zona de muerte (antes de recargar). |
| `hook` | `emboque.gd` | Al engancharse a un HookPoint. |
| `swing` | `player.gd` `_play_swing_whoosh` | Cada vez que el péndulo pasa por abajo a más de 150 px/s; volumen y tono suben con la velocidad. |
| `box_push` | `push_box.gd` | Loop mientras la caja se desliza por el piso (empujada o golpeada); volumen según velocidad. |
| `grab` | `emboque.gd` `_grab` | Al tomar el emboque en la mano. |
| `throw` | `emboque.gd` `_throw` | Al lanzar el emboque. |

`Sfx.play` ignora el mismo sonido repetido en el mismo tick de física (p. ej. las dos partes de una zona "ambos"). Emite `played(nombre)` (útil para tests).

### Zonas de muerte

`Area2D` que al ser tocadas (`body_entered`) recargan el nivel. El **filtro por máscara** decide a quién matan: jugadores = `mask 2`; emboque = `mask 12`. Hay **dos scripts separados** (jugador / emboque) para poder darles mecánicas distintas a futuro; la zona "ambos" los **compone** (dos `Area2D` hijas, una con cada script) y tiene su propio visual. Cada script setea su `collision_mask` en `_ready`, expone `signal triggered(body)` y `@export reload_on_death` (ponerlo en `false` en tests para no recargar). Guard `_fired` evita disparos repetidos.

La recarga se hace con `get_tree().call_deferred("reload_current_scene")`: **recargar dentro de `body_entered` (callback de física) está prohibido** en Godot (libera CollisionObjects a mitad del callback) — hay que diferirlo. Nota: los niveles reales instancian `WinManager` (victoria) y `ui/pause_menu.tscn` (pausa) además de las zonas; `test_death.tscn` los tiene los tres.

J1 = **campana**, J2 = **palito** (asignados en `main.tscn` vía `end_scene` + `end_kind`).

### Coleccionables y puntaje (`collectible.gd` + `score_manager.gd`)

Opcional por nivel. El **coleccionable** es un `Area2D` (`collision_layer = 0`, `mask = 14` = jugadores 2 + campana 4 + palito 8, `monitorable = false`) que al ser tocado por un `Player` **o un extremo del emboque** (`RopeEnd`; la cuerda no, es solo visual) busca el `ScoreManager` por el **grupo `"score_manager"`**, le suma `points` (export, default 100) y se autodestruye (`queue_free`). El **ScoreManager** (`Node`) guarda `score` y refresca un `Label` (`ScoreLabel`) vía su export `score_label`. Si hay coleccionables en un nivel, **tiene que haber un `ScoreManager`** (si no, el coleccionable hace `push_warning` y no suma). Un guard `_collected` evita sumar dos veces si un jugador y su extremo lo tocan en el mismo tick (`queue_free` es diferido). Un extremo en la mano no tiene colisiones, así que no recoge por sí solo (lo hace el cuerpo del jugador).

### Caja empujable (`push_box.gd`)

Según el concepto, los objetos dinámicos se empujan "por los jugadores o por los extremos de sus cuerdas", por eso la caja es un **`RigidBody2D`** (capa 6): los extremos la golpean y mueven por física real (masa 2 vs campana 1 / palito 0.6), se puede pisar (el jugador viaja con ella), apilar y cae de los bordes. `lock_rotation` (no se vuelca) y `can_sleep = false` (dormida no corre `_integrate_forces` y no se podría empujar).

Un `CharacterBody2D` no empuja cuerpos rígidos por sí solo, así que el empuje es explícito: en `_process_platformer`, si el jugador está en el suelo con input, `_try_push_box` busca una caja justo delante con `test_move` (contacto lateral) → limita su velocidad a `push_speed` y llama `box.push(velocity.x)`; tras `move_and_slide` **restaura esa velocidad** (el deslizamiento la anula al tocar la caja y el empuje daría tirones). La caja, en `_integrate_forces`, **fija** `linear_velocity.x` a la suma de empujes del tick (dos jugadores en contra se anulan) y **compensa el roce** del paso anterior con una fuerza de un paso: así avanza exactamente a la velocidad que informa, que es la que usa quien va parado encima.

### Flujo de escenas (UI)

`main_menu` → (Jugar) → `level_selector` → (Nivel 1 / Nivel 2 / Prueba: muerte / Prueba: física / Prueba: lanzar) → `main.tscn` / `level_2.tscn` / `test_death.tscn` / `test_physics.tscn` / `test_throw.tscn` (gameplay) → (al ganar) → `ui/victory.tscn` → (Menú principal) → `main_menu`.
`main_menu` → (Ajustes) → `settings`. Selector y Ajustes tienen botón **Volver** al menú.
Para agregar niveles: agregar el botón en `level_selector.tscn` (dentro de `Center/LevelsRow`) y una línea `"NombreDelBoton": "res://scenes/nivel.tscn"` en `LEVEL_BUTTONS` de `level_selector.gd` (conecta el botón solo, y lo pinta de verde si el nivel tiene lanzar). A futuro: disponer los botones como grafo con líneas de conexión.

### Capas de física (importante)

- **Capa 1:** terreno (StaticBody2D del nivel).
- **Capa 2:** jugadores. `mask = 33` (terreno 1 + cajas 32) → chocan con terreno y cajas (no entre sí, no con extremos).
- **Capa 3 (valor 4):** campana. `mask = 41` (terreno 1 + palito 8 + cajas 32).
- **Capa 4 (valor 8):** palito. `mask = 37` (terreno 1 + campana 4 + cajas 32).
- **Capa 5 (valor 16):** puntos de enganche (`HookPoint`, `monitorable`). El `HookSensor` de cada extremo tiene `mask = 16`.
- **Capa 6 (valor 32):** cajas (`PushBox`). `mask = 47` (terreno 1 + jugadores 2 + campana 4 + palito 8 + cajas 32).

En Godot 4 un cuerpo solo **es afectado** por otro si su mask incluye la capa del otro: por eso la caja tiene a los extremos en su mask (para que la empujen) y los extremos a la caja (para chocar con ella).
- Sensores Area2D: `CavitySensor` de la campana `mask = 8` (solo palito); no detecta su propio cuerpo.

Los **dos extremos colisionan entre sí por física real** (sus masks se incluyen mutuamente). Los jugadores no colisionan con los extremos.

### Cómo funciona la cuerda (`emboque.gd` + `rope_end.gd`)

El **extremo** (palito/campana) es un `RigidBody2D` (`rope_end.gd`) con física real: se balancea como péndulo, **rota sobre sí mismo** y **colisiona con el otro extremo** y el terreno. La cuerda es una `Line2D` visual.

`emboque.gd` (coordinador) cada `_physics_process`:
1. `_update_length` — `soltar`/`tirar` ajustan `rope_length` (clamp).
2. Si está enganchado: desenganche con `abajo`, o le pasa al jugador el largo actual (`set_swing_length`).
3. Pasa al extremo: `anchor_position`, `rope_length`, `hooked`, `hook_position` (los usa en su `_integrate_forces`, que corre después el mismo frame).
4. `_limit_player` — si el extremo quedó a más de `rope_length` (trabado, o enganchado con el jugador en el suelo), **tira del jugador** hacia el extremo con `_move_sliding`. Se salta cuando el jugador cuelga tenso (el péndulo ya es exacto).
5. `_update_rope_visual`.

`rope_end.gd` en `_integrate_forces`: si `hooked`, fija el extremo al gancho; si no, aplica la **restricción de cuerda por velocidad** (quita la velocidad radial hacia afuera + corrige el exceso), sin fijar posición → el motor resuelve colisiones y el extremo **nunca atraviesa geometría**.

API para el WinManager: `get_end()` (RigidBody), `get_end_position()`, `get_cavity_sensor()` (solo campana).

### Balanceo enganchado (estilo Donkey Kong Country)

Cuando el `HookSensor` del extremo toca un `HookPoint`, el `Emboque` se engancha **al instante**: `rope_length` pasa a ser la distancia actual mano–gancho y llama `player.attach_swing(gancho, largo)`. La velocidad que traía el jugador se convierte en balanceo en ese mismo tick (sin caída libre).

El balanceo es un **estado propio del `Player`** (no fuerzas encima del controlador de plataformas). Sub-estados mientras está enganchado:

| Estado | Cuándo | Qué pasa |
|---|---|---|
| Suelo | enganchado y pisando (o a ≤2px del piso) | Movimiento normal; `_limit_player` del Emboque lo ata al gancho. Saltar = salto normal. |
| Holgura | en el aire, mano más cerca que el largo | Movimiento aéreo normal hasta que la cuerda se tensa. Saltar NO suelta (evita doble salto). |
| **Tenso (péndulo)** | en el aire con la cuerda tensa | `_process_swing`: se integra el ángulo `θ` (0 = colgando abajo) y la velocidad angular `ω`, y se mueve con `move_and_slide` hacia el punto del círculo. |

Péndulo: gravedad `g·swing_gravity_scale` (más ágil que la caída libre). **Bombeo híbrido**: empujar a favor del movimiento suma `swing_pump_accel`; en contra solo `swing_brake_factor` de eso. La energía se **limita a la de `swing_max_angle_deg`** (tope suave, sin frenazos), lo que también fija la velocidad máxima. El rapel conserva la **velocidad tangencial**. Si la cuerda quedaría empujando (sobre el gancho sin velocidad), se afloja y el jugador cae.

Soltarse: **saltar** (solo tenso) → `v_balanceo·swing_launch_multiplier` + `swing_jump_velocity` y emite `swing_jumped` (el Emboque se desengancha). **Abajo** → `Emboque._unhook()` → `detach_swing()` conserva `v_balanceo`. En ambos casos el extremo sale con la velocidad del jugador y, hasta aterrizar, el aire frena suave (`launch_air_drag`) en vez de la fricción normal. Visual: el cuerpo se inclina con la cuerda pivotando en la mano (solo el `Visual`, la colisión no rota) y hay squash/stretch al engancharse y al lanzarse.

### Tomar y lanzar el emboque (mecánica por nivel)

**Activarla en un nivel:** agregar un nodo **`LevelRules`** (*Add Child Node → LevelRules*) y marcar **`throw_enabled`** en el Inspector. Sin ese nodo (o con la casilla apagada) el nivel no tiene la mecánica: todos los niveles viejos quedan igual. `LevelRules` se mete al grupo `"level_rules"` en `_enter_tree` (antes que cualquier `_ready`, así el orden en el árbol no importa) y `Emboque._ready` lo lee con `LevelRules.of(get_tree())`. Futuras mecánicas opcionales por nivel van como otra casilla en este mismo nodo.

**Color de la mecánica (verde lima, `LevelRules.THROW_COLOR`):** el selector de niveles pinta solo (texto + borde) el botón de cada nivel que la tiene: `LevelRules.scene_throw_enabled(escena)` lee el `SceneState` de la escena sin instanciarla, así que basta marcar la casilla en el nivel. En el menú principal, solo la línea de controles de lanzar (`ThrowControls`, "Niveles verdes: …") va en ese color, puesto por `main_menu.gd` desde la misma constante. Para que el selector lo detecte, `LevelRules` tiene que estar **directo en la escena del nivel** (no dentro de una sub-escena instanciada).

Estados en `emboque.gd` (`ThrowState`), sin tocar nada si la mecánica está apagada:

| Estado | Entra | Qué pasa |
|---|---|---|
| `NONE` | — | Cuerda normal. |
| `HELD` (en la mano) | `tirar` recién apretado con la cuerda **ya** al mínimo **antes** de esa pulsación (acortar hasta el mínimo no lo toma solo), sin gancho y con el extremo a ≤ `min_length + grab_tolerance` de la mano (no se toma a través de un muro) | El extremo llega a la mano con un tirón corto y va pegado a ella (`HOLD_OFFSET`, debajo del ojo, girado hacia donde mira). Cuerda oculta; ni largo ni `_limit_player`. Se camina y salta normal. `soltar` → vuelve a colgar al mínimo (esa pulsación no alarga la cuerda). |
| `AIMING` (apuntando) | `lanzar` en `HELD` | `player.aiming = true`: no camina ni salta, izquierda/derecha solo giran. Ángulo `pingpong(t·aim_sweep_speed_deg, aim_max_angle_deg)` hacia donde mira; `_draw()` hace la línea punteada desde la mano con largo = `max_length` (el alcance real). `soltar` lo deja caer. |
| `FLYING` (lanzado) | `lanzar` en `AIMING` | Parte **desde la mano** (su forma cabe dentro del jugador, nunca empieza dentro de un muro), `rope_length = max_length`, **sin gravedad** → viaja exacto por la línea punteada. Termina (vuelve la gravedad) al tensarse la cuerda, al chocar (avance real < la mitad de lo esperado), al engancharse o por tiempo. Se puede enganchar en vuelo (es la idea). |

El extremo **en la mano no tiene colisiones** (`RopeEnd.set_held`: capa y máscara 0 + `freeze` kinematic): no empuja al otro extremo ni a cajas, no activa zonas de muerte del emboque y no engancha. Además `WinManager` y `CloseupManager` **ignoran** un extremo en la mano (`Emboque.is_held()`): embocar es con la cuerda, no metiendo el palito a mano. Tuning en el Inspector del Emboque, grupo "Lanzar": `throw_speed` (1400), `aim_max_angle_deg` (60), `aim_sweep_speed_deg` (60 = 1 s por pasada), `grab_tolerance`, y color/grosor/guion de la mira.

### Victoria y magnetismo (`win_manager.gd`)

Identifica palito y campana por `end_kind`. Cada frame, si la punta del palito está a menos de `magnet_radius` de la boca de la campana, aplica magnetismo de **distancia** (fuerza que atrae la punta hacia la cavidad, y la campana hacia la punta) **y de ángulo** (alinea el eje del palito para que apunte a la cavidad, y gira la boca de la campana hacia la punta). Con la física resolviendo la colisión, el palito **entra por la boca**. **Victoria** = el palito está dentro del `CavitySensor` de la campana (respaldo: muy cerca + bien alineado). Al ganar muestra `WinLabel`, registra el resultado en `ScoreBoard` (puntaje + highscore) y tras `restart_delay` salta a la **pantalla de victoria** (`victory_scene`, default `ui/victory.tscn`). **Va antes que los Emboque en el árbol** para que las fuerzas se integren el mismo frame. Exports para el resultado: `level_id` (clave estable del highscore; si queda vacío se deriva del nombre de archivo de la escena), `level_name` (nombre a mostrar).

### Pantalla de victoria y highscore (`victory.gd` + `score_board.gd`)

Al ganar, `WinManager` llama `ScoreBoard.report_win(level_id, level_name, score)` — el puntaje sale del `ScoreManager` del nivel (0 si no tiene) — y luego `change_scene_to_file(victory_scene)`. **`ScoreBoard`** es un autoload que (a) guarda los datos de la última victoria (`last_level_name`, `last_score`, `last_is_record`) para que `victory.gd` los muestre sin tener que pasar parámetros entre escenas, y (b) persiste el **highscore por nivel** en `user://scores.cfg` (sección `highscores`, clave = `level_id`), actualizándolo solo si el puntaje lo supera. `victory.tscn` es minimalista (estilo de los menús): título, nombre del nivel, puntaje, récord (muestra "¡Nuevo récord!" si se batió) y botón **Menú principal**.

## Anatomía de un nivel (checklist antes de diseñar)

Un nivel es una escena `.tscn` con raíz `Node2D`. Antes de ponerse a diseñar el
trazado, todo nivel jugable necesita **estos nodos** (tomar `main.tscn` o
`level_2.tscn` como plantilla y copiar/ajustar). El **orden en el árbol importa**
(ver trampa más abajo): `WinManager` y `CloseupManager` van **antes** que los
`Emboque`, y los `Emboque` **después** de los `Player`.

**Obligatorio (sin esto no es un nivel jugable):**

1. **`Camera2D`** fija en `(640, 360)` — cámara del tamaño de la pantalla, sin scroll.
2. **Geometría estática** (`StaticBody2D` en **capa 1**) con su `CollisionShape2D` y un `Polygon2D` visual: suelo + plataformas + muros. Es el trazado del puzzle.
   - **Arte del terreno:** instanciar `terrain_art.tscn` (nodo `TerrainArt`) en la raíz del nivel. Viste solo todos los `StaticBody2D` con forma rectangular (piso/plataformas o muro según sean más anchos o más altos); no hay que dibujar nada por cuerpo.
   - **Muros laterales `WallLeft`/`WallRight`** justo fuera de cámara: `position = Vector2(-20, 200)` / `Vector2(1300, 200)`, shape `RectangleShape2D` 40×1200 (cubre bien por arriba y por abajo). Evitan que alguien salga del nivel por los costados; son un `StaticBody2D` más, capa 1 por default. Todos los niveles reales los tienen (`main.tscn`, `level_2.tscn`, `test_death.tscn`, `test_physics.tscn`) — copiarlos igual en niveles nuevos.
3. **2 × `Player`** (instancia de `player.tscn`):
   - `Player1`: `input_prefix = "p1"`, posición de inicio.
   - `Player2`: `input_prefix = "p2"`, `modulate` distinto (p. ej. `Color(1, 0.5, 0.4, 1)`) para diferenciarlos.
4. **2 × `Emboque`** (instancia de `emboque.tscn`), **después** de los Player en el árbol:
   - `Emboque1`: `anchor_node = ../Player1/RopeAnchor`, `input_prefix = "p1"`, `end_scene = campana.tscn`, `end_kind = "campana"`.
   - `Emboque2`: `anchor_node = ../Player2/RopeAnchor`, `input_prefix = "p2"`, `end_scene = palito.tscn`, `end_kind = "palito"`.
5. **`WinManager`** (`Node2D` + `win_manager.gd`), **antes** de los Emboque: `emboque_a`, `emboque_b`, `win_label`, y `level_id`/`level_name` (para el highscore y la pantalla de victoria — poner un id estable único por nivel, ej. `"level_3"` / `"Nivel 3"`).
6. **`CloseupManager`** (instancia de `closeup_manager.tscn`): `camera_path = ../Camera2D`, `emboque_a`, `emboque_b`. Si el nivel NO es 1280×720, ajustar su `level_size` para el clamp de cámara.
7. **`UI`** (`CanvasLayer` + `pause_menu.gd`) con:
   - El `PausePanel` completo (estructura de `main.tscn`/`level_2.tscn`: VBox con Continuar/Reiniciar/Ajustes/MenúPrincipal + SettingsVBox). **La pausa no es global: cada nivel debe tener su propio nodo.** Copiar el panel tal cual — un panel desactualizado rompe `pause_menu.gd`.
   - `WinLabel` (`Label`, oculto; lo muestra el WinManager al ganar).

**Opcional (según el diseño del nivel):**

- **`HookPoint`** (instancia de `hook_point.tscn`): puntos de enganche del entorno para rapel. Poner los que pida el puzzle.
- **Zonas de muerte**: `player_death_zone` / `emboque_death_zone` / `both_death_zone`, escaladas/posicionadas. Reinician el nivel al contacto.
- **Coleccionables + puntaje**: si se ponen `collectible.tscn`, agregar **también** un `ScoreManager` (con `score_label → ScoreLabel`) y un `ScoreLabel` en la UI. Van juntos o no van.
- **Cajas** (`push_box.tscn`): instanciar y ubicar apoyada en el piso (centro = techo del piso − 32). No necesita nada más. Para ajustar el peso ante los extremos, cambiar `mass`; para la rapidez de empuje, `push_speed`.
- **`LevelRules`** (nodo con `level_rules.gd`): mecánicas opcionales del nivel. Hoy solo `throw_enabled` (tomar y lanzar el emboque). Un nivel sin este nodo no tiene ninguna.

**Ojo con el spawn:** el extremo nace `rope_length` (170 px) **debajo de la mano**. Si un jugador arranca parado en el suelo, el extremo nacería dentro del suelo: arrancar a los jugadores **en el aire** o sobre una plataforma alta (como hacen todos los niveles; `test_throw` los pone en y=460 y caen).

**Antes de diseñar el trazado conviene tener decidido:** dónde arrancan los dos jugadores, por dónde va el muro/separación que obliga a cooperar, dónde se juntan los emboques (el punto de "embocar"), qué HookPoints hacen falta para llegar, y dónde están los peligros (zonas de muerte) y recompensas (coleccionables). Recordar que la cámara es **fija 1280×720**: todo el nivel cabe en una pantalla.

## Lecciones aprendidas / trampas (NO repetir)

- **Nunca corregir la restricción con `global_position = ...` (teletransporte):** ignora colisiones y el extremo atraviesa paredes. Usar siempre movimientos con barrido de colisión.
- **`move_and_collide` se detiene en el primer contacto y NO desliza.** Si el vector de corrección tiene componente contra una superficie (p. ej. hacia el piso), aborta *todo* el movimiento, incluida la parte útil. Por eso existe `_move_sliding()`, que proyecta el resto sobre la normal y continúa. Fue la causa de que la cuerda no limitara al jugador.
- **Medir el progreso de la restricción por reducción real de distancia**, no por cuánto se movió el extremo: si resbala tangencialmente por un muro, esa distancia recorrida no acorta la cuerda.
- **Orden en el árbol importa:** `WinManager` antes que los `Emboque`, y los `Emboque` después de los `Player` (para que las correcciones se apliquen el mismo frame).
- **UIDs:** no inventar `uid://...` a mano (Godot los rechaza como inválidos). Dejar que el editor los genere; en referencias `ext_resource` basta el `path`.
- **Inferencia de tipos:** acceder a propiedades de un nodo tipado genéricamente (`Node2D`) devuelve Variant y rompe `:=`. Tipar con el `class_name` real (p. ej. `var e: Emboque`).
- **Tunneling entre cuerpos delgados y rápidos:** un extremo veloz puede atravesar al otro. Protección actual: `continuous_cd = 2` (CCD cast-shape) + **física a 120 Hz**. **El tope de velocidad (`max_speed`) se QUITÓ** por decisión de diseño (el closeup ya frena el juego al acercarse). Si reaparece tunneling a velocidades altas, reconsiderar (subir ticks, engrosar paredes, o reintroducir un tope alto). Nota: `Engine.time_scale` NO reduce el avance por *tick* de física (solo hay menos ticks por segundo real), así que el slowdown no elimina el tunneling por sí solo.
- **Tamaños actuales (placeholders):** jugador 40×64; palito 22×6; campana ~18×24 (paredes 6px, hoyo ~12px). Las partes son ~1/3 del jugador. Magnetismo suave: `magnet_radius=70`, `linear_accel=900`, `angular_gain=2.5`. Todo es tuneable en el Inspector.
- **Restricción de cuerda en RigidBody:** hacerla por **velocidad** en `_integrate_forces` (no fijando `transform.origin`), para no teletransportar a través de paredes. Definir `_integrate_forces` NO desactiva las colisiones (salvo `custom_integrator = true`).
- **Formas cóncavas en 2D:** no existen como shape convexa única. La campana (C) se arma con **varios `CollisionShape2D` rectangulares** (convexos), no un polígono cóncavo.
- **Al medir en tests una colisión con péndulo:** medir el **pico** (ej. máximo empuje), no el frame final — el péndulo/gravedad ya devolvió el cuerpo a su sitio y da un falso negativo.
- **No liberar/recargar dentro de un callback de física** (`body_entered`, `area_entered`, etc.): Godot prohíbe destruir CollisionObjects a mitad del paso físico. Usar `call_deferred(...)`. (Pasó con `reload_current_scene` en las zonas de muerte.)
- **En tests headless, simular input con `Input.parse_input_event(ev)`**, no `Input.action_press` — este último solo cambia el estado interno y no llega a `_input`/`_unhandled_input`.
- **`Input.action_press` cuenta como `is_action_just_pressed` recién en el tick de física siguiente.** En tests, mantener la tecla al menos 2 ticks antes de soltarla, o el "just pressed" nunca se ve.
- **No montar el balanceo como fuerzas encima del controlador de plataformas:** la fricción aérea (1300 px/s²) y el tope de 320 px/s de `player.gd` se comían el péndulo. El balanceo es un estado propio (θ, ω) que se salta el código de plataformas.
- **Un jugador parado sobre un RigidBody se mueve con la velocidad *informada* del cuerpo, no con la real:** si en `_integrate_forces` se fija la velocidad, el roce del paso la reduce después y el jugador de encima se adelanta (~8 px/s, se caía de la caja). Compensar el roce con una fuerza de un paso (`apply_central_force`), que no cambia la velocidad informada.
- **Buses de audio nuevos, por código, no con un `default_bus_layout.tres` a mano** (`AudioServer.add_bus()` + `set_bus_name` + `set_bus_send`, idempotente por nombre): el proyecto no tenía ese recurso y escribirlo a mano es el mismo tipo de error que inventar un `uid://`. Como `Sfx` y cualquier `PushBox` necesitan el bus "SFX" al crear sus `AudioStreamPlayer`, `SettingsManager` (que lo crea) tiene que ser el **primer** autoload en `project.godot` — los autoloads listados antes inicializan primero.
- **Assets nuevos (WAV, PNG…) se importan con `"$GODOT" --headless --import --path .`**: `--editor --quit-after 2` cierra antes de escanear archivos nuevos y luego `load()` falla con "No loader found".
- **Para saber si un RigidBody *realmente* se mueve, medir el desplazamiento**, no `linear_velocity`: leída en `_physics_process` es la que fijó `_integrate_forces` (antes del solver), aunque el cuerpo esté trabado contra un muro.
- **Al soltarse de un gancho, darle al extremo la velocidad del jugador:** si queda quieto en el gancho, `_limit_player` frena el lanzamiento de golpe (se perdían ~80px de vuelo).
- **Mover un cuerpo directo (`global_position`) solo vale si no tiene colisiones:** es lo que hace el extremo en la mano (capa/máscara 0 + `freeze`). La regla de "nunca teletransportar" es por las colisiones; al devolverle las colisiones (soltar/lanzar) tiene que quedar en espacio libre — por eso parte desde dentro del cuerpo del jugador.
- **En tests, poner `reload_on_death = false` en TODAS las zonas de muerte antes de agregar el nivel** (recorrer el árbol: la zona "ambos" tiene dos hijas con script), y subir `WinManager.restart_delay`: recargar o cambiar de escena desde un nivel instanciado dentro de un test recarga/reemplaza **el test entero** (pasó: loop infinito en el test de muros).
- **En tests, teletransportar a un jugador lejos de su extremo no sirve:** en el mismo tick `_limit_player` lo tira de vuelta hacia el extremo (antes de que la física vea el solapamiento). Mover también el extremo al lado.
- **Diseño: un gancho con el jugador parado arriba lo arrastra** — enganchado en el suelo, al acortar la cuerda `_limit_player` lo lleva hacia el punto sobre el gancho. Si hay un peligro entre el jugador y ese punto (el bloque rojo del Nivel 2), el jugador muere al tirar. Dejar el gancho a un lado del peligro (por eso el gancho izquierdo del Nivel 2 está en x=320 y no en 342 como en el boceto).
- **Una tecla que hace una acción puntual no debe seguir con su acción continua mientras se mantiene:** `soltar` deja el extremo *y* alarga la cuerda; sin `_release_used`, al dejarlo la cuerda se alargaba unos px y había que tirar dos veces para volver a tomarlo.
- Godot re-guarda escenas/`project.godot` al abrirlos (puede cambiar `uid`/`load_steps` u omitir valores por default); es esperado.

## Estado de desarrollo (prototipo de la mecánica)

Hecho (verificado con tests headless donde aplica):
- **Fase 0** — Andamiaje: Input Map, capas de física, escena de prueba.
- **Fase 1** — Personaje plataformero (`player.gd`).
- **Fase 2** — Cuerda híbrida (extremo-péndulo + cuerda visual).
- **Fase 3** — Control de largo continuo (soltar/tirar).
- **Fase 4** — Colisiones del extremo + la cuerda limita al jugador (test: sobre-extensión 459px → 0.04px).
- **Fase 4.5** — Enganche básico a `HookPoint`: engancha al tocar, rapel con soltar/tirar, salto desengancha (test PASS).
- **Fase 5** — Victoria con magnetismo: atracción entre extremos + captura por dwell.
- **Menú** — main_menu / level_selector / settings (navegación + ajustes funcionales).
- **Extremos como emboque real** — palito (rectángulo) y campana (C), `RigidBody2D` que rotan y **colisionan entre sí** por física; magnetismo de **distancia + ángulo**; victoria = **palito dentro de la campana** (`CavitySensor`). Tests headless: colisión sin atravesar (incl. velocidad capada) PASS; emboque por magnetismo PASS; enganche PASS.
- **Partes pequeñas + física 120 Hz** — palito/campana a ~1/3 del jugador; magnetismo más sutil; `physics_ticks_per_second=120` para evitar tunneling con paredes finas.
- **Upgrade a Godot 4.7.2** (antes 4.6) — proyecto importa y corre limpio en 4.7.
- **Menú de pausa** (`pause_menu.gd`, vía PR #1) — Esc pausa (`get_tree().paused`); botones Continuar / Reiniciar. El nodo usa `process_mode = ALWAYS` para seguir respondiendo con el juego pausado.
- **Zonas de muerte** — `player_death_zone` / `emboque_death_zone` (scripts separados) + `both_death_zone`, cada una con visual distinta; reinician el nivel al contacto. Nivel `test_death.tscn` en el selector. Test headless: detección + aislamiento por máscara + zona "ambos" PASS.
- **Closeup + slowdown estilo Peggle** (`closeup_manager.gd`, reutilizable) — al acercarse los extremos, la cámara hace zoom hacia el punto medio y `Engine.time_scale` baja; continuo y reversible; se reinicia el time_scale al salir. En `main` y `level_2`. Test headless: lejos→normal, cerca→zoom~2 + ts 0.35 + cámara al midpoint, revierte, y reset PASS. Se quitó el tope de velocidad del emboque.
- **Nivel 2** (`level_2.tscn`) — segundo nivel de gameplay en el selector, con plataformas, muro central, 3 HookPoint, 2 zonas de muerte "ambos", WinManager y CloseupManager.
- **Coleccionables + puntaje** (`collectible.gd` + `score_manager.gd`) — rombos que el jugador recoge para sumar puntos; `ScoreManager` (grupo `"score_manager"`) lleva el conteo y actualiza un `ScoreLabel`. Usado en `level_2`.
- **Pantalla de victoria + highscore** (`ui/victory.tscn` + `score_board.gd` autoload) — al ganar se salta a una pantalla minimalista con puntaje, récord del nivel ("¡Nuevo récord!" si se batió) y botón al menú principal. `ScoreBoard` persiste el highscore por nivel en `user://scores.cfg`. Test headless del tablero (récord, no-récord, independencia entre niveles, persistencia) PASS.

- **Balanceo estilo DKC** (`player.gd` + `emboque.gd`) — enganche instantáneo, péndulo propio del jugador con bombeo híbrido y tope de ángulo por energía, salto desde la cuerda con impulso, soltarse con abajo conservando velocidad, rapel sin perder rapidez, inclinación + squash/stretch. Test headless (radio exacto, período, bombeo ≤ ángulo máx, enganche instantáneo, lanzamiento sin tirón, rapel, enganche sobre el gancho, suelo atado, sin doble salto) PASS.
- **Caja empujable** (`push_box.gd` + `push_box.tscn`, capa 6) — RigidBody que los jugadores empujan caminando contra ella (velocidad fija, sin tirones) y que los extremos golpean por física; se pisa, se apila, cae de bordes, el que va encima viaja con ella. Test headless (asentarse, empuje parejo, frenar al soltar, muro, pararse encima, pasajero, golpe de campana, empujes opuestos, caída de borde, pila) PASS.
- **Nivel "Prueba: Física"** (`test_physics.tscn`) — Nivel 1 sin muro central, plataformas más afuera, muros laterales fuera de cámara, 3 ganchos y 2 cajas. En el selector.
- **Muros laterales en todos los niveles** (`WallLeft`/`WallRight`, `x<0` y `x>1280`) — se agregaron también a `main.tscn`, `level_2.tscn` y `test_death.tscn` (antes solo los tenía `test_physics.tscn`); nadie puede salirse del nivel por los costados. Test headless por raycast: en los 4 niveles hay muro exactamente en `x=0` y `x=1280` PASS.
- **Mirada + espejo + sonidos** — ojo placeholder del lado hacia el que mira; `Visual/Art` se espeja según `facing`; hook de animaciones por nombre (`get_anim_state`) listo para el arte. Autoload `Sfx` + 6 efectos placeholder sintetizados (pasos, salto, muerte, enganche, whoosh del balanceo, arrastre de caja). Test headless (mirada/espejo/ojo, estados de animación, ~8 pasos/s, pasajero sin pasos, salto, enganche, whoosh por pasada, loop de la caja on/off, muerte sin duplicar) PASS.
- **Volumen por categoría** (`SettingsManager` + buses Music/SFX) — sliders independientes de Master/Música/Efectos en Ajustes y en la pausa de cada nivel; los buses se crean por código, no con un `default_bus_layout.tres` a mano. Test headless (buses creados y enviando a Master, los tres volúmenes no se pisan entre sí, persisten en `user://settings.cfg`, Sfx y la caja usan el bus SFX) PASS.

- **Tomar y lanzar el emboque** (`emboque.gd` + `rope_end.gd` + `level_rules.gd`, teclas G / L) — mecánica por nivel (nodo `LevelRules`): tirar otra vez con la cuerda al mínimo toma el extremo, lanzar apunta (mira punteada 0°↔60° en ping-pong, jugador quieto), lanzar otra vez lo lanza en línea recta con la cuerda al máximo; soltar lo deja. Sonidos `grab`/`throw`. Nivel **"Prueba: lanzar"** (`test_throw.tscn`, torre central + 2 ganchos). Test headless (no toma al acortar hasta el mínimo, toma con pulsación nueva, sin colisiones y pegado a la mano al caminar, apuntando no camina ni salta pero gira, mira 0..60 ida y vuelta, soltar restaura todo sin alargar, vuelo recto desvío 0 px hasta 320 px, choca con la torre sin atravesarla, el mejor salto queda 40 px bajo el techo de la torre, cada jugador lanza a su gancho → sube → queda arriba de la torre, extremo en la mano no emboca ni activa closeup (con control), sin `LevelRules` no hay mecánica) PASS 49/49. Desde el mejor lugar (~150–200 px del gancho) sirve una ventana de ~10° del barrido.
- **Verde de lanzar en los menús** — el selector pinta solo (texto + borde verde lima) los niveles con `LevelRules.throw_enabled`, leyendo la escena sin instanciarla; en el menú principal solo la línea de lanzar va en verde ("Niveles verdes: …"). Un único color en `LevelRules.THROW_COLOR`. El selector pasó a un mapa `LEVEL_BUTTONS` (botón → escena).
- **El emboque recoge coleccionables** (`collectible.gd`, mask 14) — palito y campana también los recogen (la cuerda no); guard contra doble suma.
- **Nivel 2 según el boceto** (`level_2.tscn`) — plataformas, muro central que sigue sobre la pantalla, plataforma media con bloque rojo (solo jugador), T bajo el muro, bloque naranja flotante y piso naranja (ambos), 2 ganchos, 6 coleccionables; puntaje movido para no tapar a J1. Test headless 27/27 (colores = mismas zonas que "Prueba: muerte": rojo mata al jugador y no al emboque, naranja mata a ambos; el muro no se salta por arriba; extremos y jugadores recogen; rutas: J1 baja con cuidado a la izquierda del rojo, engancha el gancho de abajo — tirar al mínimo, soltar un poco y volver a tirar — y se balancea hasta la T en 10/12 combinaciones largo/ángulo; J2 acorta la cuerda, corre a la izquierda y el palito engancha el gancho derecho, y salta a la T en 4/4 ángulos; con la cuerda a 170 el palito roza el bloque naranja; desde la T los extremos cuelgan bajo el muro, se juntan a 5 px y recogen los 2 coleccionables de abajo).

Pendiente:
- **Fase 6** — Nivel de prueba definitivo a medida de cámara + pasada de tuning de la sensación (magnetismo, masas, largos, velocidades, radios del closeup).

Post-prototipo (del concepto): más objetos dinámicos (la caja ya existe), mapa de progresión de niveles, estética Tikitiklip (animación tradicional + imágenes reales chilenas), sonido, export a web.

## Convenciones

- Comentarios y nombres de usuario en **español**; código en GDScript idiomático de Godot 4.
- Placeholders geométricos (`Polygon2D`/formas) hasta que llegue el arte.
- Cámara **fija** en los primeros niveles (del tamaño de la cámara, sin scroll).
