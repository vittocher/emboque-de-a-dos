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

| | Mover | Saltar | Soltar cuerda | Tirar cuerda |
|---|---|---|---|---|
| **J1** (`input_prefix = "p1"`) | `A` / `D` | `W` | `R` | `T` |
| **J2** (`input_prefix = "p2"`) | `←` / `→` | `↑` | `,` | `.` |

Las acciones siguen el patrón `<prefix>_<accion>`: `_left`, `_right`, `_jump`, `_down` (S / flecha abajo), `_release` (soltar = alargar), `_pull` (tirar = acortar). Usan `physical_keycode` (independiente del layout del teclado).

**Esc** (`ui_cancel`) abre/cierra el **menú de pausa** en el nivel (ver `pause_menu.gd`).

**Enganchado** (ver Fase 4.5): `soltar` baja al jugador (rapel), `tirar` lo sube, `abajo` (S / ↓) lo **desengancha** (por defecto solo se suelta y cae; `unhook_hop` permite un impulso).

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
  both_death_zone.tscn    Zona que mata a ambos (visual naranja); compone los dos scripts.
  test_death.tscn      Nivel de prueba de las zonas de muerte (2 jugadores + 2 emboques + las 3 zonas).
  closeup_manager.tscn Efecto reutilizable: closeup + cámara lenta al acercarse los extremos (instanciar por nivel).
  collectible.tscn     Area2D recolectable (rombo turquesa): el JUGADOR lo toca (mask 2) → suma puntos y se destruye.
  level_2.tscn         Segundo nivel de gameplay: plataformas, muro central, 3 HookPoint, 2 zonas de muerte "ambos",
                       4 coleccionables + ScoreManager/ScoreLabel, WinManager, CloseupManager, pausa inline.
  ui/main_menu.tscn      Menú: Jugar, Ajustes, y texto de controles.
  ui/level_selector.tscn Selector de niveles (Nivel 1 + Nivel 2; futuro: grafo conectado).
  ui/settings.tscn       Ajustes: volumen maestro + pantalla completa.
  ui/pause_menu.tscn     Menú de pausa reutilizable (Esc). Instanciar en cada nivel.
  ui/victory.tscn        Pantalla de victoria (minimalista): puntaje + récord del nivel + "Menú principal".
scripts/
  player.gd        Controlador de plataformas parametrizado por input_prefix.
  emboque.gd       Coordina la media-cuerda: largo, enganche, límite del jugador, cuerda visual;
                   instancia el extremo (end_scene) y le pasa los parámetros de la cuerda.
  rope_end.gd      RigidBody2D del extremo (palito/campana): restricción de cuerda en _integrate_forces.
  closeup_manager.gd Closeup de cámara + slowdown (Engine.time_scale) al acercarse los extremos; reutilizable; reinicia time_scale en _exit_tree.
  win_manager.gd   Magnetismo distancia+ángulo entre extremos + victoria (palito dentro de campana).
  player_death_zone.gd   Al entrar un jugador (mask=2) → reinicia el nivel. Señal triggered; export reload_on_death.
  emboque_death_zone.gd  Al entrar un extremo (mask=12 = campana 4 + palito 8) → reinicia. (Scripts separados a propósito.)
  collectible.gd   Area2D: al tocarlo un Player, busca el ScoreManager (grupo "score_manager"), suma `points` y queue_free.
  score_manager.gd Lleva el puntaje del nivel y actualiza un Label. Está en el grupo "score_manager" (lo encuentra collectible).
  score_board.gd   AUTOLOAD (ScoreBoard): lleva los datos de la última victoria entre escenas + guarda el highscore
                   por nivel en user://scores.cfg. WinManager lo usa al ganar; victory.gd lo lee.
  pause_menu.gd    Menú de pausa del nivel (Esc): Continuar / Reiniciar. Es un CanvasLayer.
                   La pausa NO es global: cada nivel debe TENER el nodo. Reutilizable vía ui/pause_menu.tscn
                   (test_death lo instancia; main.tscn lo tiene inline en su CanvasLayer "UI").
  ui/*.gd          Lógica de los menús (navegación con change_scene_to_file); victory.gd muestra puntaje + récord.
```

Autoloads (en `project.godot`): **`SettingsManager`** (audio/volumen/pantalla completa, persistencia) y **`ScoreBoard`** (puntaje entre escenas + highscore por nivel).

### Zonas de muerte

`Area2D` que al ser tocadas (`body_entered`) recargan el nivel. El **filtro por máscara** decide a quién matan: jugadores = `mask 2`; emboque = `mask 12`. Hay **dos scripts separados** (jugador / emboque) para poder darles mecánicas distintas a futuro; la zona "ambos" los **compone** (dos `Area2D` hijas, una con cada script) y tiene su propio visual. Cada script setea su `collision_mask` en `_ready`, expone `signal triggered(body)` y `@export reload_on_death` (ponerlo en `false` en tests para no recargar). Guard `_fired` evita disparos repetidos.

La recarga se hace con `get_tree().call_deferred("reload_current_scene")`: **recargar dentro de `body_entered` (callback de física) está prohibido** en Godot (libera CollisionObjects a mitad del callback) — hay que diferirlo. Nota: los niveles reales instancian `WinManager` (victoria) y `ui/pause_menu.tscn` (pausa) además de las zonas; `test_death.tscn` los tiene los tres.

J1 = **campana**, J2 = **palito** (asignados en `main.tscn` vía `end_scene` + `end_kind`).

### Coleccionables y puntaje (`collectible.gd` + `score_manager.gd`)

Opcional por nivel. El **coleccionable** es un `Area2D` (`collision_layer = 0`, `mask = 2`, `monitorable = false`) que al ser tocado por un `Player` busca el `ScoreManager` por el **grupo `"score_manager"`**, le suma `points` (export, default 100) y se autodestruye (`queue_free`). El **ScoreManager** (`Node`) guarda `score` y refresca un `Label` (`ScoreLabel`) vía su export `score_label`. Si hay coleccionables en un nivel, **tiene que haber un `ScoreManager`** (si no, el coleccionable hace `push_warning` y no suma). Solo detecta jugadores, no los extremos del emboque.

### Flujo de escenas (UI)

`main_menu` → (Jugar) → `level_selector` → (Nivel 1 / Nivel 2) → `main.tscn` / `level_2.tscn` (gameplay) → (al ganar) → `ui/victory.tscn` → (Menú principal) → `main_menu`.
`main_menu` → (Ajustes) → `settings`. Selector y Ajustes tienen botón **Volver** al menú.
Para agregar niveles: agregar la ruta a `LEVELS` en `level_selector.gd`, el botón correspondiente en `level_selector.tscn`, y conectar su `pressed` (a futuro: disponer los botones como grafo con líneas de conexión).

### Capas de física (importante)

- **Capa 1:** terreno (StaticBody2D del nivel).
- **Capa 2:** jugadores. `mask = 1` → chocan solo con el terreno (no entre sí, no con extremos).
- **Capa 3 (valor 4):** campana. `mask = 9` (terreno 1 + palito 8).
- **Capa 4 (valor 8):** palito. `mask = 5` (terreno 1 + campana 4).
- **Capa 5 (valor 16):** puntos de enganche (`HookPoint`, `monitorable`). El `HookSensor` de cada extremo tiene `mask = 16`.
- Sensores Area2D: `CavitySensor` de la campana `mask = 8` (solo palito); no detecta su propio cuerpo.

Los **dos extremos colisionan entre sí por física real** (sus masks se incluyen mutuamente). Los jugadores no colisionan con los extremos.

### Cómo funciona la cuerda (`emboque.gd` + `rope_end.gd`)

El **extremo** (palito/campana) es un `RigidBody2D` (`rope_end.gd`) con física real: se balancea como péndulo, **rota sobre sí mismo** y **colisiona con el otro extremo** y el terreno. La cuerda es una `Line2D` visual.

`emboque.gd` (coordinador) cada `_physics_process`:
1. `_update_length` — `soltar`/`tirar` ajustan `rope_length` (clamp).
2. Desenganche con `abajo` si está enganchado.
3. Pasa al extremo: `anchor_position`, `rope_length`, `hooked`, `hook_position` (los usa en su `_integrate_forces`, que corre después el mismo frame).
4. `_limit_player` — si el extremo quedó a más de `rope_length` (trabado o colgando de un gancho), **tira del jugador** hacia el extremo con `_move_sliding`.
5. `_update_rope_visual`.

`rope_end.gd` en `_integrate_forces`: si `hooked`, fija el extremo al gancho; si no, aplica la **restricción de cuerda por velocidad** (quita la velocidad radial hacia afuera + corrige el exceso), sin fijar posición → el motor resuelve colisiones y el extremo **nunca atraviesa geometría**.

API para el WinManager: `get_end()` (RigidBody), `get_end_position()`, `get_cavity_sensor()` (solo campana).

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

Pendiente:
- **Fase 6** — Nivel de prueba definitivo a medida de cámara + pasada de tuning de la sensación (magnetismo, masas, largos, velocidades, radios del closeup).

Post-prototipo (del concepto): objetos empujables, mapa de progresión de niveles, estética Tikitiklip (animación tradicional + imágenes reales chilenas), sonido, export a web.

## Convenciones

- Comentarios y nombres de usuario en **español**; código en GDScript idiomático de Godot 4.
- Placeholders geométricos (`Polygon2D`/formas) hasta que llegue el arte.
- Cámara **fija** en los primeros niveles (del tamaño de la cámara, sin scroll).
