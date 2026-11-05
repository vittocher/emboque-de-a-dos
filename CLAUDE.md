# CLAUDE.md — Emboque de a Dos

Guía para trabajar en este repositorio. Léela antes de tocar código.

## Qué es el juego

**Emboque de a Dos**: puzzle **cooperativo local de 2 jugadores** (estilo *Fireboy & Watergirl*), en **Godot 4.7.2**, apuntado a **web (Newgrounds)**. Tema: amistad y tradición chilena.

De cada personaje cuelga **media mitad del emboque** por una cuerda: J1 lleva la **campana**, J2 el **palito**. La física de la cuerda (balanceo tipo péndulo) es la mecánica central. El objetivo de cada nivel es **juntar palito + campana** (embocar). El concepto completo está en `EmboqueDA2 Concepto.pdf`.

## Setup / cómo correr

- **Editor:** Godot **4.7.2** (ejecutable en `C:\Users\vitto\OneDrive\Desktop\Godot\Godot_v4.7.2-stable_win64.exe`; la variante `..._console.exe` sirve para CLI headless). En esa misma carpeta también está el 4.6 (versión previa). `config/features` en `project.godot` = `4.7`.
- **Abrir:** importar el `project.godot` de esta carpeta desde el Project Manager, o **F5** para jugar.
- **Escena de arranque:** `res://scenes/ui/intro.tscn` (video de intro, se salta con cualquier tecla → menú `ui/main_menu.tscn`). Los niveles son `main.tscn` (Nivel 1), `level_2`…`level_4` y los `test_*` (ver Arquitectura). Durante el desarrollo, abrir un nivel y correr con **F6** (ejecutar escena actual) para saltarse el menú.
- **Resolución base:** 1280×720 (16:9). Stretch `canvas_items` + aspect `keep` (default en Godot 4, por eso el editor lo omite del archivo). No pixel-art; se adapta a cualquier tamaño de embed sin deformar.

### Validación headless (sin abrir el editor)

```bash
GODOT="/c/Users/vitto/OneDrive/Desktop/Godot/Godot_v4.7.2-stable_win64_console.exe"
# Importar recursos (obligatorio tras agregar/mover archivos; ponerle timeout, a veces se cuelga):
timeout 150 "$GODOT" --headless --import --path .
# Correr N frames de la escena de arranque y filtrar errores:
"$GODOT" --headless --path . --quit-after 150 > salida.txt 2>&1; grep -iE "script error|parse error" salida.txt
# Correr una escena puntual:
"$GODOT" --headless --path . res://scenes/level_2.tscn
# Test o captura con un script propio (SceneTree); sin --headless se puede guardar una captura con
# root.get_texture().get_image().save_png(...):
"$GODOT" --headless --path . -s ruta/al/test.gd
```

Redirigir la salida a un archivo y filtrar aparte evita cuelgues del pipe. Los avisos `ObjectDB instances leaked` / `resources still in use at exit` al cerrar son normales en estas corridas. Para escribir tests, ver las trampas de tests en "Lecciones aprendidas" (input simulado, `-s` y autoloads, zonas de muerte); el registro de lo ya verificado está en "Registro de tests", al final.

## Controles (Input Map en `project.godot`)

| | Mover | Saltar | Soltar cuerda | Tirar cuerda | Lanzar* |
|---|---|---|---|---|---|
| **J1** (`input_prefix = "p1"`) | `A` / `D` | `W` | `R` | `T` | `G` |
| **J2** (`input_prefix = "p2"`) | `←` / `→` | `↑` | `,` | `.` | `L` |

\* Solo en niveles con la mecánica de lanzar activada (ver "Tomar y lanzar el emboque").

Las acciones siguen el patrón `<prefix>_<accion>`: `_left`, `_right`, `_jump`, `_down` (S / flecha abajo), `_release` (soltar = alargar), `_pull` (tirar = acortar), `_throw` (lanzar). Usan `physical_keycode` (independiente del layout del teclado).

**Esc** o **P** (acción `pause`) abre/cierra el **menú de pausa** en el nivel (ver `pause_menu.gd`). P existe porque en web, con pantalla completa, el navegador se queda con Esc para salir de ella y no llega al juego.

**Enganchado** (ver "Balanceo enganchado"): izquierda/derecha **bombean** el balanceo, `saltar` **se lanza** desde la cuerda (impulso del balanceo + salto), `abajo` (S / ↓) se **suelta** conservando la velocidad, `soltar` baja al jugador (rapel) y `tirar` lo sube.

**Lanzar** (solo en algunos niveles): con la cuerda ya al mínimo, `tirar` otra vez **toma el emboque en la mano**; `lanzar` empieza a **apuntar** (línea punteada que va y vuelve de 0° a 60° hacia arriba; el jugador queda quieto y izquierda/derecha solo lo giran); `lanzar` otra vez lo **lanza** (la cuerda pasa al máximo). `soltar` lo deja caer (tomado o apuntando).

## Arquitectura

```
scenes/
  main.tscn            Nivel 1: cámara fija (640,360), suelo, 2 plataformas, muro central, 2 HookPoint,
                       WinManager, CloseupManager, 2×(Player+Emboque), UI/WinLabel, fondo y arte del terreno.
  level_2.tscn         Nivel 2, hecho según un boceto del equipo (escala x·0.64, y·0.473): J1 arriba a la
                       izquierda, J2 arriba a la derecha, muro central (hasta y=-400: no se salta por arriba) con
                       una plataforma media a la izquierda (con púas encima: matan solo al jugador) y una "T"
                       abajo que lo cruza; bloque de fuego flotante a la derecha y piso de fuego (matan a ambos);
                       2 HookPoint (bajo la plataforma media y a la izquierda de la plataforma de J2),
                       6 coleccionables + ScoreManager/ScoreLabel. Se emboca con los extremos colgando bajo el
                       muro, parados cada uno en su mitad de la T.
  level_3.tscn         Nivel 3: cada jugador sube por 3 escalones de su lado hasta la cima, cae y se engancha a
                       un HookPoint (2, uno por lado) para aterrizar en la plataforma central, donde se emboca.
                       Piso de fuego; 8 coleccionables.
  level_4.tscn         "Escalones" (del equipo, en el mapa al final de la rama de cajas; ahora hereda level_base):
                       una caja por lado DEBAJO de la primera plataforma (200 px sobre el piso): hay que pasar
                       por encima, empujarla hacia atrás (o hasta el borde del foso) y saltar desde ella. Luego
                       2 escalones de 100 px hasta la meta: dos repisas con una ranura de 36 px (no cabe un
                       jugador, sí los extremos) y un cuenco debajo. Piso de fuego en el foso; 5 coleccionables.
  test_death.tscn      "Prueba: muerte": las 3 zonas de muerte (2 jugadores + 2 emboques). Sin CloseupManager.
  test_physics.tscn    "Prueba: física": Nivel 1 SIN muro central (para probar el balanceo), plataformas más
                       afuera (x=170 / x=1110), 3 HookPoint (izq/centro/der) y 2 cajas en el suelo.
  test_throw.tscn      "Prueba: lanzar": el nivel con la mecánica de lanzar (LevelRules.throw_enabled). Una torre
                       al centro (240×270, techo y=410) que no se alcanza saltando; un HookPoint afuera de cada
                       esquina de arriba. Cada jugador lanza al gancho de su lado, sube tirando la cuerda y salta
                       arriba de la torre, donde se juntan para embocar. Label de ayuda arriba.
                       (Los main/level_3/test_* NO están en el mapa; ver "Mapa de niveles".)

  levels/level_base.tscn  Escena BASE de todo nivel nuevo (se hereda: New Inherited Scene). Trae Background,
                       Camera2D, WallLeft/WallRight, Player1/2 (z 1), WinManager, CloseupManager, Emboque1/2 (z 1),
                       ScoreManager, UI (ScoreLabel/WinLabel), TerrainArt y PauseMenu, en el orden correcto.
  levels/*.tscn        Los 23 niveles nuevos del mapa (heredan la base): tronco_1..4, peligro_1..3, caja_1..3,
                       placa_1..3, movil_1..3, lanzar_1..3, viento_1..3, final. Cada uno descrito en su solución
                       tests/solutions/<nivel>.gd. El árbol está en scripts/level_catalog.gd.
  block.tscn           Bloque de terreno (StaticBody2D, block.gd) con `size` editable: piso, plataforma o muro.
                       TerrainArt lo viste solo. Con él se traza todo nivel nuevo.
  bowl.tscn            Cuenco en V (bowl.gd: `width`, `slope`), tablas resbalosas (friction 0): la META de muchos
                       niveles; los extremos que caen adentro se deslizan al fondo y se juntan. Rotado 180° = embudo
                       (para extremos que suben con el viento).
  fall_zone.tscn       Zona invisible bajo la pantalla (PlayerDeathZone): caer a un foso sin piso reinicia.
  pressure_plate.tscn  Placa de presión (ver "Mecánicas de las ramas"). Arte: assets/props/placa.
  gate.tscn            Compuerta que se desliza (AnimatableBody2D).
  moving_platform.tscn Plataforma móvil / ascensor (AnimatableBody2D) con rieles punteados.
  wind_zone.tscn       Corriente de aire (Area2D) con rayitas de aire (CPUParticles2D) y sonido en loop.

  player.tscn          CharacterBody2D 40×64 + RopeAnchor (Marker2D, "la mano") + arte en Visual/Art: Sprite
                       (AnimatedSprite2D, ver "Arte del jugador"). Body/Eye = placeholders ocultos.
  emboque.tscn         Node2D raíz: solo Rope (Line2D con textura assets/emboque/cuerda.png, repetida). El
                       extremo se instancia en runtime.
  palito.tscn          Extremo RigidBody2D (J2): rectángulo 22×6 + Tip + HookSensor. Sprite palito.png
                       (assets/emboque, rotado); Polygon2D placeholder oculto.
  campana.tscn         Extremo RigidBody2D (J1): forma de C (Spine + Top + Bottom, rects) + Head (círculo, la
                       parte redonda de atrás) + CavitySensor + Mouth/Cavity + HookSensor. Sprite campana.png
                       (assets/emboque); placeholders ocultos.
  hook_point.tscn      Area2D (punto de enganche del entorno, radio 18) + Sprite hoyo.png (assets/props/enganche,
                       ~36 px = el círculo de enganche). Rombo placeholder oculto.
  player_death_zone.tscn  Area2D que mata al JUGADOR. Arte: púas (assets/hazards/jugadores, 9 FPS).
  emboque_death_zone.tscn Area2D que mata al EMBOQUE. Arte: caca (assets/hazards/emboques, 9 FPS).
  both_death_zone.tscn    Zona que mata a ambos; compone los dos scripts. Arte: fuego (assets/hazards/ambos, 9 FPS).
                          En las tres el arte lo pone un hijo `Art` con hazard_art.gd: repite la animación a lo
                          ancho en cuadros tan altos como la zona, sin deformarse con la escala de la instancia.
                          Los Polygon2D de color (rojo / morado / naranja) quedaron ocultos.
  push_box.tscn        Caja empujable (RigidBody2D 64×64, capa 6, rotación bloqueada). Reutilizable en cualquier nivel.
                       Arte: Sprite con assets/props/caja/caja.png (320×320 a escala 0.2); placeholders ocultos.
  collectible.tscn     Area2D recolectable (sopaipilla animada, assets/props/puntos, 2 frames a 6 FPS; rombo oculto):
                       lo toca un jugador o un extremo del emboque (mask 14) → suma puntos y se destruye.
                       La cuerda no recoge (es solo una Line2D).
  closeup_manager.tscn Efecto reutilizable: closeup + cámara lenta al acercarse los extremos (instanciar por nivel).
  background.tscn      Fondo del nivel: Sprite2D con assets/entorno/fondo/paredazul.png (1280×720 a escala 1,
                       centrado en (640,360), z_index -100). En el mundo, así acompaña el zoom del closeup.
  terrain_art.tscn     Arte del terreno (TerrainArt): instanciado una vez por nivel, cubre cada StaticBody2D con
                       forma rectangular usando assets/entorno/colision/: horizontales = piso armado con piso_left +
                       piso_neutral (repetido) + piso_right, o piso.png si cabe una sola tabla; verticales =
                       pared.png. Sin deformarse. En juego oculta los Polygon2D "Visual".

  ui/intro.tscn          Intro: video de la historia (video/intro.ogv) al arrancar el juego; se salta con cualquier
                         tecla / clic / botón (mensaje abajo). Ver "Intro (video)".
  ui/main_menu.tscn      Menú: portada (assets/ui/portada.png, con el título y los controles ya dibujados) de fondo
                         + botones Jugar / Ajustes (sin Salir: el juego es para web).
  ui/boton_madera.tscn   Botón de madera reutilizable del menú principal (boton_madera.gd + shader procedural
                         shaders/madera_boton.gdshader).
  ui/level_selector.tscn MAPA de niveles (ver "Mapa de niveles y progreso"): nodos de madera (ui/level_node.tscn)
                         unidos por cuerdas, panel con nombre/récord/sopaipillas, fondo con círculos (map_decor.gd).
  ui/settings.tscn       Ajustes (panel de madera, tema compartido ui/tema_madera.tres): volumen general / música /
                         efectos, pantalla completa, idioma, restaurar valores y borrar progreso (pide confirmar).
  ui/tema_madera.tres    Tema de madera de los paneles (Ajustes y el panel de ajustes de la pausa): botones-tabla,
                         sliders dorados, checkbox (assets/ui/check_on|off.png), listas.
  ui/pause_menu.tscn     Menú de pausa (Esc / P), ÚNICO para todos los niveles: instanciarlo en cada nivel.
                         Diseño = imagen assets/ui/pause_menu.webp con botones invisibles encima (ver "Menú de pausa").
  ui/victory.tscn        Pantalla de victoria (estilo del menú): nivel, puntaje, sopaipillas juntadas, récord,
                         botones Reintentar y Continuar (vuelve al mapa, que anima lo desbloqueado).

scripts/
  player.gd        Controlador de plataformas parametrizado por input_prefix + estado de balanceo
                   (péndulo θ/ω) cuando cuelga de un gancho; el Emboque lo maneja vía attach/detach_swing.
                   Elige el SpriteFrames de su jugador y reproduce la animación de su estado.
  emboque.gd       Coordina la media-cuerda: largo, enganche, límite del jugador, cuerda visual;
                   instancia el extremo (end_scene) y le pasa los parámetros de la cuerda. También
                   tomar / apuntar / lanzar el extremo (si el nivel lo permite) y dibuja la mira punteada.
  rope_end.gd      RigidBody2D del extremo (palito/campana): restricción de cuerda en _integrate_forces;
                   set_held (en la mano: congelado y sin colisiones) y start/end_flight (vuelo sin gravedad).
  win_manager.gd   Magnetismo (curva de distancia + ángulo, y trabado al embocar) + victoria (palito dentro de campana).
  closeup_manager.gd Closeup de cámara + slowdown (Engine.time_scale) al acercarse los extremos; reutilizable;
                   reinicia time_scale en _exit_tree.
  level_rules.gd   Nodo (class_name LevelRules, grupo "level_rules") con las mecánicas opcionales de un
                   nivel: casilla throw_enabled. Nivel sin el nodo = todo lo opcional apagado. También
                   THROW_COLOR (verde de la mecánica en los menús) y scene_throw_enabled(escena).
  level_flow.gd    class LevelFlow: estado del nivel en curso (meta en la escena): ganado (ya no se muere ni
                   junta) y reiniciándose (una sola recarga aunque se toquen varias zonas a la vez).
  player_death_zone.gd   Al entrar un jugador (mask=2) → reinicia el nivel. Señal triggered; export reload_on_death.
  emboque_death_zone.gd  Al entrar un extremo (mask=12 = campana 4 + palito 8) → reinicia. (Scripts separados a propósito.)
  hazard_art.gd    @tool, class HazardArt: arte animado de una zona de peligro (ver both_death_zone.tscn).
  terrain_art.gd   @tool, class TerrainArt: arte del terreno (ver terrain_art.tscn).
  collectible.gd   Area2D: al tocarlo un jugador o un extremo, busca el ScoreManager (grupo "score_manager"),
                   suma `points` y queue_free.
  score_manager.gd Lleva el puntaje del nivel (y coleccionables juntados/totales) y actualiza un Label; lo
                   oculta si el nivel no tiene coleccionables. Está en el grupo "score_manager".
  level_catalog.gd class LevelCatalog: la ÚNICA lista de niveles (id, escena, nombre, posición en el mapa,
                   de qué niveles depende). Desbloqueo, número de nivel, coleccionables por escena.
  block.gd / bowl.gd  Bloque de terreno con `size`; cuenco con `width`/`slope` (ambos @tool).
  mechanisms/      channel.gd (canales con color), pressure_plate.gd, gate.gd, moving_platform.gd, wind_zone.gd.
  push_box.gd      Caja empujable (class_name PushBox): el Player la empuja con push(); los extremos la golpean por física.
                   Suena un loop de arrastre mientras se desliza por el piso.
  pause_menu.gd    Menú de pausa del nivel (acción `pause` = Esc / P): Continuar / Reiniciar / Ajustes / Menú principal. Es el
                   script de ui/pause_menu.tscn. La pausa NO es global: cada nivel debe instanciar esa escena.
  settings_manager.gd AUTOLOAD (SettingsManager): volúmenes, buses de audio, pantalla completa, idioma, música,
                   persistencia.
  languages.gd     class Languages: idiomas disponibles, nombre de cada uno, traducción desde código estático e
                   imagen localizada (ver "Idiomas").
                   stop_music() / play_music(fade) (la intro calla la cueca mientras corre el video).
  score_board.gd   AUTOLOAD (ScoreBoard): datos de la última victoria entre escenas + highscore por nivel +
                   niveles COMPLETADOS (y máximo de sopaipillas) en user://scores.cfg. De eso depende el
                   desbloqueo del mapa. `unlock_all` (solo desarrollo, F9 en el mapa) desbloquea todo.
  sfx.gd           AUTOLOAD (Sfx): registro único de efectos de sonido (SOUNDS: nombre → ruta + volumen base),
                   pool de AudioStreamPlayer, play(nombre, pitch, volumen). Sobrevive a la recarga del nivel.
  ui/*.gd          Lógica de los menús (navegación con change_scene_to_file); intro.gd (class IntroScreen) = la intro; victory.gd muestra puntaje + récord;
                   boton_madera.gd = el botón de madera; level_selector.gd = el mapa; level_node.gd = un nivel
                   del mapa; map_decor.gd = fondo del mapa y de la victoria.

assets/            TODO el arte (sprites, fondos, UI), por tema: jugadores/, emboque/, entorno/, hazards/, props/, ui/.
                   No crear otras carpetas de imágenes. Las subcarpetas alternativos/ guardan arte que hoy no se usa
                   (poses y extremos de una versión anterior), por si se retoma.
shaders/           madera_boton.gdshader (madera procedural de los botones del menú principal).
video/             intro.ogv (Ogg Theora: el único formato de video de Godot) + README.md con cómo convertirlo.
audio/             cueca.ogg (música, la pone SettingsManager) y sfx/: efectos placeholder (WAV 22 kHz mono):
                   step, jump, die, hook, swing, box_push (loop), grab, throw.
i18n/              textos.csv: TODOS los textos del juego, una columna por idioma (ver "Idiomas").
default_bus_layout.tres  Buses de audio Master / Music / SFX (ver "Volumen y buses de audio"). Obligatorio para web.
tools/convertir_video.bat|.sh  Convierte el video de la intro a video/intro.ogv (ver "Intro (video)").
tools/generate_sfx.py  Sintetiza los placeholders de audio/sfx (numpy): `python tools/generate_sfx.py [nombres]`
                   (sin nombres, todos; con nombres, solo esos, p. ej. `plate gate wind`).
tests/             Bot de pruebas (ver "Bot de pruebas"): play_level.gd, run_all.sh, solutions/<nivel>.gd.
                   Excluido del export (export_presets: exclude_filter "tests/*").
GUIA_ASSETS.md     Guía para diseño: qué archivo reemplazar para cambiar cada sprite/sonido en TODOS los niveles.
EmboqueDA2 Concepto.pdf  Documento de concepto del juego.
```

Autoloads (en `project.godot`): **`SettingsManager`** (volumen Master/Música/Efectos, pantalla completa, persistencia; va **primero** en la lista), **`ScoreBoard`** (puntaje entre escenas + highscore por nivel) y **`Sfx`** (efectos de sonido, usa el bus SFX).

### Volumen y buses de audio

Los buses están en **`default_bus_layout.tres`** (raíz del proyecto; Godot lo carga solo al arrancar): "Master" + **`"Music"`** y **`"SFX"`**, ambos con `send` hacia `"Master"`. `SettingsManager._ensure_buses()` queda solo como respaldo si faltara el archivo. Así Master es un fader general (afecta a los dos) y Música/Efectos se balancean aparte. `SettingsManager._start_music()` pone la cueca en el bus Music; `Sfx.gd` pone todo su pool de `AudioStreamPlayer` en el bus SFX; `push_box.gd` hace lo mismo con su sonido de arrastre. Tres sliders independientes ("General" / "Música" / "Efectos") en `ui/settings.tscn` y en el panel de pausa de cada nivel, guardados en `user://settings.cfg` (`audio/master_volume`, `audio/music_volume`, `audio/sfx_volume`).

### Arte y sonido (para diseño)

**Arte del jugador** (`player.tscn`):
```
Visual (Node2D)      ← el código lo inclina (balanceo) y aplasta/estira (squash). No tocar.
  Art (Node2D)       ← el código lo ESPEJA: scale.x = facing (1 = derecha, -1 = izquierda).
    Body, Eye        ← placeholders (ocultos, visible = false)
    Sprite (AnimatedSprite2D) ← arte real: escala 0.21, pies en y = +32, flip_h (los PNG miran a la izquierda)
```
**Arte actual:** `assets/jugadores/p1|p2/` con un `SpriteFrames` por jugador (`p1_frames.tres` / `p2_frames.tres`). `player.gd` le pone al `Sprite` el de su `input_prefix` (exports `frames_p1` / `frames_p2` en `player.tscn`). Animaciones: `idle` (WALK_01 quieto), `walk` (WALK_02 → WALK_01 en loop a **10 FPS**, empieza con el paso abierto para que se note al instante), `aim` (THROW, al apuntar) y, **provisorias hasta que llegue el arte** (reusan esos mismos cuadros): `jump` (WALK_02, piernas abiertas), `fall` (THROW, brazos abiertos), `swing` (WALK_02) y `push` (caminata a 6 FPS). Si falta la animación del estado se usa `ANIM_FALLBACK` (`push` → `walk`) o `idle`.
**Toques por código** (valen para cualquier arte): estirón al saltar y aplastón al aterrizar (proporcional a la caída, desde 320 px/s, con un golpe sordo = `step` grave), los dos con los **pies fijos** (`_squash(amount, pivot)`: la mano al engancharse, `FEET` al saltar/aterrizar); al empujar una caja el `Sprite` se inclina 9° hacia adelante girando sobre los pies.
Para poner el arte definitivo: reemplazar los hijos de `Visual/Art` por el dibujo **mirando a la derecha** (el código lo da vuelta). Si se usa un `AnimatedSprite2D` llamado **`Sprite`** dentro de `Art`, el jugador reproduce solo las animaciones cuyos nombres coincidan con `get_anim_state()`: **`idle`, `walk`, `jump`, `fall`, `swing`, `push`, `aim`** (las que falten se ignoran; `aim` = apuntando un lanzamiento). Ya no hay `modulate` en `Player2`: cada jugador tiene su arte. `facing` es público por si otro script lo necesita. Al empezar, cada jugador mira hacia el centro de la pantalla.

**Sonidos**: todos pasan por el autoload `Sfx` (`scripts/sfx.gd`). Para cambiar uno, **reemplazar el archivo con el mismo nombre** en `audio/sfx/` (o cambiar su ruta/volumen en `Sfx.SOUNDS`); WAV u OGG sirven (el loop de la caja se activa por código para ambos). Dónde suena cada uno:

| Sonido | Dónde | Cuándo |
|---|---|---|
| `step` | `player.gd` `_update_footsteps` / `_on_landed` | Cada 40 px caminados de verdad sobre el piso (no si lo lleva una caja ni si empuja contra un muro). Tono aleatorio 0.9–1.1. Al aterrizar de una caída fuerte, más grave (0.75) como golpe sordo. |
| `jump` | `player.gd` | Salto desde el piso; al lanzarse desde la cuerda con tono 1.2. |
| `die` | `player_death_zone.gd` / `emboque_death_zone.gd` | Al tocar una zona de muerte (antes de recargar). |
| `hook` | `emboque.gd` | Al engancharse a un HookPoint. |
| `swing` | `player.gd` `_play_swing_whoosh` | Cada vez que el péndulo pasa por abajo a más de 150 px/s; volumen y tono suben con la velocidad. |
| `box_push` | `push_box.gd` | Loop mientras la caja se desliza por el piso (empujada o golpeada); volumen según velocidad. |
| `grab` | `emboque.gd` `_grab` | Al tomar el emboque en la mano. |
| `throw` | `emboque.gd` `_throw` | Al lanzar el emboque. |

`Sfx.play` ignora el mismo sonido repetido en el mismo tick de física (p. ej. las dos partes de una zona "ambos"). Emite `played(nombre)` (útil para tests).

### Zonas de muerte

`Area2D` que al ser tocadas (`body_entered`) recargan el nivel. El **filtro por máscara** decide a quién matan: jugadores = `mask 2`; emboque = `mask 12`. Hay **dos scripts separados** (jugador / emboque) para poder darles mecánicas distintas a futuro; la zona "ambos" los **compone** (dos `Area2D` hijas, una con cada script) y tiene su propio arte (fuego). Cada script setea su `collision_mask` en `_ready`, expone `signal triggered(body)` y `@export reload_on_death` (ponerlo en `false` en tests para no recargar). Guard `_fired` evita disparos repetidos.

La recarga se hace con `LevelFlow.restart(tree)` (diferida: **recargar dentro de `body_entered`, un callback de física, está prohibido** en Godot, libera CollisionObjects a mitad del callback; y una sola vez aunque se toquen dos zonas en el mismo instante). **Desde que se emboca** (`LevelFlow.mark_won`, lo llama el WinManager) las zonas ya no matan ni los coleccionables suman: si no, caer al fuego en los 2,5 s del cartel de victoria recargaba el nivel en vez de ir a la pantalla de victoria. Nota: los niveles reales instancian `WinManager` (victoria) y `ui/pause_menu.tscn` (pausa) además de las zonas; `test_death.tscn` los tiene los tres.

J1 = **campana**, J2 = **palito** (asignados en cada nivel vía `end_scene` + `end_kind` de cada `Emboque`).

### Intro (video) (`ui/intro.tscn` + `ui/intro.gd`)

Escena de arranque. Reproduce `video/intro.ogv` (export `video_path`) y luego pasa al menú; si el archivo no existe va directo al menú (nunca se traba; si hay un mp4 en `video/`, avisa cómo convertirlo). **Formato: Ogg Theora `.ogv`** (Godot 4 no lee mp4/webm): **`tools/convertir_video.bat`** (arrastrar el video encima; `.sh` en Mac/Linux) lo deja en 1280×720 máx., 30 fps, Theora q7 + Vorbis estéreo (detalles en `video/README.md`). Al agregar el video, commitear también el `intro.ogv.uid` que genera Godot; el mp4 original lo ignora `video/.gitignore`.

- **Saltar:** cualquier tecla (no repetición), clic o botón de control, salvo los primeros `skip_guard_time` (0,35 s) para no saltarla con una tecla que venía apretada. Mensaje "Presiona cualquier tecla para saltar" abajo (aparece a los 0,6 s, pulsa suave entre 70 y 100 % de opacidad, en una píldora semitransparente para leerse sobre cualquier video). La tecla que salta se consume (no llega al menú).
- **Salida:** fundido a negro + fundido del audio del video (0,5 s); el menú aparece desde negro (`IntroScreen.fade_menu_in`) y la cueca entra con fundido de 1,5 s.
- **Música:** la intro llama `SettingsManager.stop_music()` en `_ready`; `SettingsManager` arranca la cueca **diferida**, así ni un instante suena encima del video. El audio del video va al bus Master (`video_bus`).
- **Proporción:** el video va dentro de un `AspectRatioContainer` cuyo `ratio` se ajusta al tamaño real del video → franjas negras si no es 16:9, sin deformarse.
- **Web:** el navegador no deja sonar audio antes del primer gesto, así que en web primero se muestra "Presiona cualquier tecla para comenzar" (ese gesto desbloquea el audio) y recién ahí parte el video. El `.ogv` entra al export con `export_filter="all_resources"`.

### Coleccionables y puntaje (`collectible.gd` + `score_manager.gd`)

Opcional por nivel. El **coleccionable** es un `Area2D` (`collision_layer = 0`, `mask = 14` = jugadores 2 + campana 4 + palito 8, `monitorable = false`) que al ser tocado por un `Player` **o un extremo del emboque** (`RopeEnd`; la cuerda no, es solo visual) busca el `ScoreManager` por el **grupo `"score_manager"`**, le suma `points` (export, default 100) y se autodestruye (`queue_free`). El **ScoreManager** (`Node`) guarda `score` y refresca un `Label` (`ScoreLabel`) vía su export `score_label`. Si hay coleccionables en un nivel, **tiene que haber un `ScoreManager`** (si no, el coleccionable hace `push_warning` y no suma). Un guard `_collected` evita sumar dos veces si un jugador y su extremo lo tocan en el mismo tick (`queue_free` es diferido). Un extremo en la mano no tiene colisiones, así que no recoge por sí solo (lo hace el cuerpo del jugador).

### Caja empujable (`push_box.gd`)

Según el concepto, los objetos dinámicos se empujan "por los jugadores o por los extremos de sus cuerdas", por eso la caja es un **`RigidBody2D`** (capa 6): los extremos la golpean y mueven por física real (masa 2 vs campana 1 / palito 0.6), se puede pisar (el jugador viaja con ella), apilar y cae de los bordes. `lock_rotation` (no se vuelca) y `can_sleep = false` (dormida no corre `_integrate_forces` y no se podría empujar).

Un `CharacterBody2D` no empuja cuerpos rígidos por sí solo, así que el empuje es explícito: en `_process_platformer`, si el jugador está en el suelo con input, `_try_push_box` busca una caja justo delante con `test_move` (contacto lateral) → limita su velocidad a `push_speed` y llama `box.push(velocity.x)`; tras `move_and_slide` **restaura esa velocidad** (el deslizamiento la anula al tocar la caja y el empuje daría tirones). La caja, en `_integrate_forces`, **fija** `linear_velocity.x` a la suma de empujes del tick (dos jugadores en contra se anulan) y **compensa el roce** del paso anterior con una fuerza de un paso: así avanza exactamente a la velocidad que informa, que es la que usa quien va parado encima.

### Menú de pausa (`ui/pause_menu.tscn` + `pause_menu.gd`)

El diseño es una **imagen** hecha por el equipo, `assets/ui/pause_menu.webp` (1015×1024: título "PAUSA", tablero de madera con 4 botones pintados y los dos personajes con el emboque). Estructura:

```
PauseMenu (CanvasLayer, pause_menu.gd, process_mode ALWAYS)
  PausePanel (Control, pantalla completa; visible solo en pausa)
    Background   ColorRect opaco del azul de la imagen (0.039, 0.059, 0.149): tapa el nivel.
    Board        Control del tamaño de la imagen en px, en (283, 0) con scale 0.703125 (= 720/1024):
                 TODO lo de adentro usa coordenadas en PÍXELES DE LA IMAGEN.
      Art        TextureRect con la imagen.
      FadeLeft/FadeRight  Degradados de 64 px del azul de fondo: esconden la costura con los costados.
      Buttons    ContinueButton / RestartButton / SettingsButton / MainMenuButton: botones SIN texto
                 encima de los pintados. Normal = invisible; foco/hover = borde dorado (Style_glow).
    SettingsPanel  Panel de madera (tema "Theme_wood") que tapa los 4 botones pintados al abrir Ajustes:
                   sliders General/Música/Efectos + pantalla completa + "Volver a pausa".
```

El borde dorado lo dibuja el botón **con foco**; el mouse le pasa el foco (`mouse_entered → grab_focus`), así brilla uno solo. Al pausar el foco va a Continuar; al volver de Ajustes, a Ajustes. **Cambiar el arte:** reemplazar `assets/ui/pause_menu.webp` por otra con el mismo encuadre. Si los botones pintados se mueven, ajustar los `offset_*` de cada botón en píxeles de la imagen (se leen directo en un editor de imágenes); si cambia el tamaño de la imagen, ajustar el tamaño del `Board` y su `scale` (= 720 / alto) y centrarlo (x = (1280 − ancho·scale) / 2). La imagen **no debe traer un botón ya iluminado** (el brillo es del código).

### Idiomas (`i18n/textos.csv` + `Languages` + `SettingsManager.set_language`)

Español (original) e inglés. **Todos los textos** están en `i18n/textos.csv`: columna `keys` (la clave) + una
columna por idioma (`es`, `en`). Godot lo importa como `i18n/textos.<código>.translation` (registradas en
`project.godot`, `[internationalization]`, con `locale/fallback = "es"`).

- **En escenas** el `text` (o `tooltip_text`) de un Label/Button es la **clave** (`MENU_PLAY`, `SETTINGS_MUSIC`…):
  Godot la traduce solo y la retraduce al cambiar de idioma (en el editor se ven las claves).
- **En código**: `tr("CLAVE")`, con `%` para los números (`tr("HUD_POINTS") % score`); desde funciones
  estáticas, `Languages.text("CLAVE")`. Un texto armado por código que deba cambiar en vivo se rehace en
  `NOTIFICATION_TRANSLATION_CHANGED` (ver `score_manager.gd`).
- **Nombres de nivel**: clave `LEVEL_<ID>` (`LevelCatalog.name_key` / `display_name`); el catálogo ya no
  guarda nombres. `ScoreBoard.last_level_name` guarda la clave y la victoria le aplica `tr()`.
- **Imágenes con texto dibujado** (portada, menú de pausa): `LocalizedTextureRect`
  (`scripts/ui/localized_texture_rect.gd`) muestra `assets/ui/<código>/<mismo nombre>` si existe; si no, la
  original. Las de inglés (`assets/ui/en/`) se generaron reescribiendo el texto sobre el arte original (fuentes
  Bungee / Barlow Semi Condensed / Titan One): son **provisorias** hasta que diseño haga las definitivas.
- **Selector**: botón arriba a la derecha del menú principal (muestra el idioma actual, cada clic pasa al
  siguiente), fila "Idioma" en Ajustes (lista) y en el panel de ajustes de la pausa. Se guarda en
  `user://settings.cfg` (`general/language`); la primera vez se usa el idioma del sistema si existe.
- **Agregar un idioma**: columna nueva en el CSV (la fila `LANGUAGE_NAME` = su nombre en ese idioma) → abrir
  Godot (genera la `.translation`) → sumarla en Proyecto → Configuración → Localización → Traducciones →
  (opcional) imágenes en `assets/ui/<código>/`. Los selectores la listan solos (`Languages.available()`).

### Flujo de escenas (UI)

Arranque: `ui/intro.tscn` (video; cualquier tecla lo salta) → `main_menu` (aparece desde negro; la intro solo corre al iniciar el juego, volver al menú no la repite).
`main_menu` → (Jugar) → `level_selector` (el MAPA) → (un nivel desbloqueado) → gameplay → (al ganar) → `ui/victory.tscn` → (Continuar) → mapa (anima lo recién desbloqueado) / (Reintentar) → el mismo nivel. Esc en el mapa vuelve al menú.
`main_menu` → (Ajustes) → `settings`. No hay botón Salir: el juego es para web, donde `quit()` no cierra la pestaña (solo congela el juego). Selector y Ajustes tienen botón **Volver** al menú.
Para agregar niveles: una entrada en `LEVELS` de `scripts/level_catalog.gd` (el mapa la dibuja sola).

### Mapa de niveles y progreso (`level_selector` + `LevelCatalog` + `ScoreBoard`)

Como la progresión del concepto: un árbol de niveles que se desbloquean al completar el anterior.
**`LevelCatalog.LEVELS`** es la única lista: `id`, `scene`, `name`, `pos` (lugar en el mapa, 1280×720) y `from`
(niveles de los que depende: se desbloquea al completar CUALQUIERA, o al menos `need`). Opcionales: `special`
(nodo dorado y más grande), `rope: false` (sin cuerdas en el mapa) y `hint` (texto mientras está bloqueado).
El número del nivel es su orden en la lista. `WinManager` toma el id y el nombre del catálogo.

Árbol actual (25 niveles): **tronco** 1–4 (lo básico, sin objetos: caminar, largo de cuerda, ganchos, cuenco)
→ desde el 4 se abren **peligros** (púas, caca, brasas, y "La T" = `level_2` del equipo), **cajas** (3 + "Escalones" = `level_4` del equipo) y
**lanzar** (3). Sub-ramas de mecánicas nuevas: **placas/compuertas** (desde caja 2), **plataformas móviles**
(desde peligro 2) y **viento** (desde lanzar 2). El **final** se abre con 4 de los 6 finales de rama. Cada
rama empieza introduciendo su mecánica en un caso simple y sube la dificultad. El mapa no nombra las
mecánicas (minimalista): se descubren jugando. El primer nivel con lanzar trae un cartel con los controles.

Mapa: nodos con el shader de madera de los botones (bloqueado = madera oscura sin número; disponible = anillo
que late; completado = número dorado y una sopaipilla si se juntaron todas), cuerdas con la textura de la cuerda
del emboque (que cuelgan), panel abajo con nombre / récord / sopaipillas. Flechas o mouse + Enter. Tras una
victoria nueva, las cuerdas hacia lo desbloqueado se "tienden" y los nodos aparecen. **F9** (solo en builds de
desarrollo) desbloquea todo. Niveles del equipo que NO están en el mapa: `main`, `level_3` (el extremo nace bajo la plataforma
de inicio y amarra al jugador, ver Lecciones) y los `test_*`. `level_2` ("La T") y `level_4`
("Escalones") sí están, al final de las ramas de peligros y de cajas.

### Mecánicas de las ramas (`scripts/mechanisms/`)

- **Canal (`Channel`)**: un número 0–3 con un color (amarillo, celeste, rosado, morado; sin verde). Una
  compuerta o plataforma de canal N se activa mientras alguna placa de canal N esté presionada
  (`require_all` = todas). Las placas avisan con `Channel.notify` (grupo `channel_listeners`).
- **Placa (`PressurePlate`)**: Node2D apoyado en el piso (posición = centro de la base, sobre la superficie). La
  presiona cualquier cosa encima: jugador, **extremo del emboque** o caja (mask 46). `latch` = botón que queda
  trabado. La tapa se tiñe del color del canal. Sonido `plate`. Para que un extremo se quede quieto encima
  (rueda: roce 0,05) ponerla en un rebaje del suelo de ~20 px (ver placa_2).
- **Compuerta (`Gate`)**: AnimatableBody2D con `size`; se desliza `open_offset` (default: hacia arriba su alto)
  mientras el canal está activo (`inverted` al revés). **No aplasta**: al cerrarse espera si hay un jugador, un
  extremo o una caja debajo (su `collision_mask` incluye todo eso para que `test_move` los vea). Sonido `gate`.
- **Plataforma móvil (`MovingPlatform`)**: AnimatableBody2D con `size`, `travel`, `speed`, `wait_time`. Sin canal
  (`channel = -1`) va y viene sola; con canal va a la punta mientras está activo y vuelve (ascensor). Rieles
  punteados (top_level) muestran el recorrido. Lleva jugadores; los extremos apoyados resbalan. **No aplasta**:
  bajando, si hay un jugador debajo espera (su `collision_mask` = 2 solo para ese `test_move`; extremos y cajas
  los aparta la física).
- **Viento (`WindZone`)**: Area2D con `size`, `direction`, `strength` (aceleración sobre extremos y cajas, mask 46; la
  gravedad es 980) y `player_factor` (fracción para jugadores, con tope `player_max_speed`; vía
  `Player.add_wind`). Con viento hacia arriba los extremos suben como un **volantín**: hay que soltar cuerda.
  `player_factor = 0` → solo afecta a los extremos. Sonido `wind` en loop (AudioStreamPlayer2D).

### Bot de pruebas (`tests/`)

`tests/play_level.gd` juega un nivel siguiendo un plan y termina con `RESULT WIN|DEATH|TIMEOUT` (+ sopaipillas
que faltaron). Corre headless y mucho más rápido que el tiempo real con `--fixed-fps 120`:

```bash
"$GODOT" --headless --fixed-fps 120 --path . -s tests/play_level.gd -- res://tests/solutions/tronco_1.gd --trace=0.5
GODOT="$GODOT" tests/run_all.sh          # todos los niveles; sale con 1 si alguno no se gana
```

Cada `tests/solutions/<nivel>.gd` declara `const SCENE` y `static func plan(ctx)` con los pasos de cada jugador
(`walk_to`, `jump_to`, `rope`, `tap`/`hold`, `sync`, `until`, `pump` (columpio), `pump_end` (balancear el
extremo), `jiggle`…; lista completa arriba de play_level.gd). `tests/solutions/moves.gd` tiene movimientos
compuestos (correr-saltar-engancharse-columpiarse-lanzarse, lanzar a un ángulo). `--var=nombre=valor` permite
barrer parámetros (`ctx.var_f`), `--shots=dir` guarda capturas (sin `--headless`, con Xvfb). **Al cambiar la
física o un nivel, correr `run_all.sh`.** Las soluciones son a la vez documentación de cómo se resuelve cada
nivel.

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

**Color de la mecánica (verde lima, `LevelRules.THROW_COLOR`):** el mapa de niveles NO lo usa (es minimalista: las mecánicas se descubren jugando; el primer nivel con lanzar, `lanzar_1`, trae un cartel con los controles). `LevelRules.scene_throw_enabled(escena)` sigue disponible (lee el `SceneState` sin instanciar). En la portada, la fila de controles de lanzar ahora dice "LANZAR" (antes "NIVELES VERDES").

Estados en `emboque.gd` (`ThrowState`), sin tocar nada si la mecánica está apagada:

| Estado | Entra | Qué pasa |
|---|---|---|
| `NONE` | — | Cuerda normal. |
| `HELD` (en la mano) | `tirar` recién apretado con la cuerda **ya** al mínimo **antes** de esa pulsación (acortar hasta el mínimo no lo toma solo), sin gancho y con el extremo a ≤ `min_length + grab_tolerance` de la mano (no se toma a través de un muro) | El extremo llega a la mano con un tirón corto y va pegado a ella (`HOLD_OFFSET`, debajo del ojo, girado hacia donde mira). Cuerda oculta; ni largo ni `_limit_player`. Se camina y salta normal. `soltar` → vuelve a colgar al mínimo (esa pulsación no alarga la cuerda). |
| `AIMING` (apuntando) | `lanzar` en `HELD` | `player.aiming = true`: no camina ni salta, izquierda/derecha solo giran. Ángulo `pingpong(t·aim_sweep_speed_deg, aim_max_angle_deg)` hacia donde mira; `_draw()` hace la línea punteada desde la mano con largo = `max_length` (el alcance real). `soltar` lo deja caer. |
| `FLYING` (lanzado) | `lanzar` en `AIMING` | Parte **desde la mano** (su forma cabe dentro del jugador, nunca empieza dentro de un muro), `rope_length = max_length`, **sin gravedad** → viaja exacto por la línea punteada. Termina (vuelve la gravedad) al tensarse la cuerda, al chocar (avance real < la mitad de lo esperado), al engancharse o por tiempo. Se puede enganchar en vuelo (es la idea). |

El extremo **en la mano no tiene colisiones** (`RopeEnd.set_held`: capa y máscara 0 + `freeze` kinematic): no empuja al otro extremo ni a cajas, no activa zonas de muerte del emboque y no engancha. Además `WinManager` y `CloseupManager` **ignoran** un extremo en la mano (`Emboque.is_held()`): embocar es con la cuerda, no metiendo el palito a mano. Tuning en el Inspector del Emboque, grupo "Lanzar": `throw_speed` (1400), `aim_max_angle_deg` (60), `aim_sweep_speed_deg` (60 = 1 s por pasada), `grab_tolerance`, y color/grosor/guion de la mira.

### Victoria y magnetismo (`win_manager.gd`)

Identifica palito y campana por `end_kind`. Cada frame, si la punta del palito está a menos de `magnet_radius` de la boca de la campana, aplica magnetismo de **distancia** (fuerza que atrae la punta hacia la cavidad, y la campana hacia la punta) **y de ángulo** (alinea el eje del palito para que apunte a la cavidad, y gira la boca de la campana hacia la punta). Con la física resolviendo la colisión, el palito **entra por la boca**. La intensidad sigue una **curva** (`cercanía ^ falloff_exponent`, 3 por defecto): casi nada a distancia (a medio radio ≈12 %) y fuerte solo al final. **Trabado:** con el palito ya embocado (dentro del `CavitySensor` o su punta a menos de `lock_radius` = 18 px de la cavidad) el magnetismo pasa a un **resorte amortiguado** muy fuerte entre los dos extremos (`lock_strength`, `lock_damping`, tope `lock_max_accel`; fuerzas iguales y opuestas, así no arrastra al conjunto) + alineación rápida (`lock_angular_gain`): el emboque no se escapa ni tiembla (mediciones en "Registro de tests"). Con la victoria a los `capture_time` = 0,2 s de embocado, el trabado actúa solo ese instante. **Victoria** = el palito está dentro del `CavitySensor` de la campana (respaldo: muy cerca + bien alineado). Al ganar muestra `WinLabel`, registra el resultado en `ScoreBoard` (puntaje + highscore) y tras `restart_delay` salta a la **pantalla de victoria** (`victory_scene`, default `ui/victory.tscn`). **Va antes que los Emboque en el árbol** para que las fuerzas se integren el mismo frame. Exports para el resultado: `level_id` (clave estable del highscore; si queda vacío se deriva del nombre de archivo de la escena), `level_name` (nombre a mostrar).

### Pantalla de victoria y highscore (`victory.gd` + `score_board.gd`)

Al ganar, `WinManager` llama `ScoreBoard.report_win(level_id, level_name, score)` — el puntaje sale del `ScoreManager` del nivel (0 si no tiene) — y luego `change_scene_to_file(victory_scene)`. **`ScoreBoard`** es un autoload que (a) guarda los datos de la última victoria (`last_level_name`, `last_score`, `last_is_record`) para que `victory.gd` los muestre sin tener que pasar parámetros entre escenas, y (b) persiste el **highscore por nivel** en `user://scores.cfg` (sección `highscores`, clave = `level_id`), actualizándolo solo si el puntaje lo supera. `victory.tscn` es minimalista (estilo de los menús): título, nombre del nivel, puntaje, récord (muestra "¡Nuevo récord!" si se batió) y botón **Menú principal**.

## Anatomía de un nivel (checklist antes de diseñar)

**Lo más simple (y lo que usan los 23 niveles nuevos):** *New Inherited Scene* desde
`scenes/levels/level_base.tscn`, que ya trae todo lo obligatorio de abajo en el orden correcto; el nivel solo
agrega bloques (`block.tscn` con su `size`), objetos y la posición de los jugadores, y una entrada en
`LevelCatalog`. La lista de abajo explica qué trae la base (y sirve para niveles hechos a mano).

Un nivel es una escena `.tscn` con raíz `Node2D`. Antes de ponerse a diseñar el
trazado, todo nivel jugable necesita **estos nodos** (tomar `main.tscn` o
`level_2.tscn` como plantilla y copiar/ajustar). El **orden en el árbol importa**
(ver trampa más abajo): `WinManager` y `CloseupManager` van **antes** que los
`Emboque`, y los `Emboque` **después** de los `Player`.

**Obligatorio (sin esto no es un nivel jugable):**

1. **`Camera2D`** fija en `(640, 360)` — cámara del tamaño de la pantalla, sin scroll.
2. **Geometría estática** (`StaticBody2D` en **capa 1**) con su `CollisionShape2D` y un `Polygon2D` visual: suelo + plataformas + muros. Es el trazado del puzzle.
   - **Fondo:** instanciar `background.tscn` como **primer** hijo de la raíz del nivel.
   - **Arte del terreno:** instanciar `terrain_art.tscn` (nodo `TerrainArt`) en la raíz del nivel. Viste solo todos los `StaticBody2D` con forma rectangular (piso/plataformas o muro según sean más anchos o más altos); no hay que dibujar nada por cuerpo.
   - **Muros laterales `WallLeft`/`WallRight`** justo fuera de cámara: `position = Vector2(-20, 200)` / `Vector2(1300, 200)`, shape `RectangleShape2D` 40×1200 (cubre bien por arriba y por abajo). Evitan que alguien salga del nivel por los costados; son un `StaticBody2D` más, capa 1 por default. Todos los niveles los tienen — copiarlos igual en niveles nuevos (a los niveles 3 y 4 se les olvidaron y hubo que agregarlos).
3. **2 × `Player`** (instancia de `player.tscn`):
   - `Player1`: `input_prefix = "p1"`, posición de inicio.
   - `Player2`: `input_prefix = "p2"`. **Sin `modulate`**: cada jugador ya tiene su arte (un tinte lo mancharía).
4. **2 × `Emboque`** (instancia de `emboque.tscn`), **después** de los Player en el árbol:
   - `Emboque1`: `anchor_node = ../Player1/RopeAnchor`, `input_prefix = "p1"`, `end_scene = campana.tscn`, `end_kind = "campana"`.
   - `Emboque2`: `anchor_node = ../Player2/RopeAnchor`, `input_prefix = "p2"`, `end_scene = palito.tscn`, `end_kind = "palito"`.
5. **`WinManager`** (`Node2D` + `win_manager.gd`), **antes** de los Emboque: `emboque_a`, `emboque_b`, `win_label`, y `level_id`/`level_name` (para el highscore y la pantalla de victoria — poner un id estable único por nivel, ej. `"level_3"` / `"Nivel 3"`).
6. **`CloseupManager`** (instancia de `closeup_manager.tscn`): `camera_path = ../Camera2D`, `emboque_a`, `emboque_b`. Si el nivel NO es 1280×720, ajustar su `level_size` para el clamp de cámara.
7. **`PauseMenu`**: instancia de `ui/pause_menu.tscn` (*Instantiate Child Scene*), al final del árbol para que se dibuje encima. **La pausa no es global: cada nivel debe tenerla.** No copiar el panel a mano: todos los niveles comparten esa escena, así un cambio de diseño llega a todos.
8. **`UI`** (`CanvasLayer`, sin script) con `WinLabel` (`Label`, oculto; lo muestra el WinManager al ganar) y, si hay puntaje, `ScoreLabel`.

**Opcional (según el diseño del nivel):**

- **`HookPoint`** (instancia de `hook_point.tscn`): puntos de enganche del entorno para rapel. Poner los que pida el puzzle.
- **Zonas de muerte**: `player_death_zone` / `emboque_death_zone` / `both_death_zone`, escaladas/posicionadas. Reinician el nivel al contacto.
- **Coleccionables + puntaje**: si se ponen `collectible.tscn`, agregar **también** un `ScoreManager` (con `score_label → ScoreLabel`) y un `ScoreLabel` en la UI. Van juntos o no van.
- **Cajas** (`push_box.tscn`): instanciar y ubicar apoyada en el piso (centro = techo del piso − 32). No necesita nada más. Para ajustar el peso ante los extremos, cambiar `mass`; para la rapidez de empuje, `push_speed`.
- **`LevelRules`** (nodo con `level_rules.gd`): mecánicas opcionales del nivel. Hoy solo `throw_enabled` (tomar y lanzar el emboque). Un nivel sin este nodo no tiene ninguna.

**Ojo con el spawn:** el extremo nace `rope_length` (170 px) **debajo de la mano**. Si un jugador arranca parado en el suelo, el extremo nacería dentro del suelo: arrancar a los jugadores **en el aire** o sobre una plataforma alta (como hacen todos los niveles; `test_throw` los pone en y=460 y caen).

**Verificación al terminar un nivel** (lo que más se olvida):
- [ ] `Background` (primer hijo) y `TerrainArt` instanciados.
- [ ] `WallLeft` / `WallRight` fuera de cámara.
- [ ] `PauseMenu` instanciado, al final del árbol.
- [ ] `WinManager` con `level_id` único y `level_name`; antes de los `Emboque`, como `CloseupManager`.
- [ ] Coleccionables ⇒ `ScoreManager` + `ScoreLabel` (con contorno, como en `level_2`: `font_outline_color` + `outline_size = 10`).
- [ ] `Player2` sin `modulate`.
- [ ] Entrada en `LevelCatalog.LEVELS` (posición en el mapa y de qué nivel depende).
- [ ] Una solución en `tests/solutions/<nivel>.gd` que el bot gane (`tests/run_all.sh`).

**Antes de diseñar el trazado conviene tener decidido:** dónde arrancan los dos jugadores, por dónde va el muro/separación que obliga a cooperar, dónde se juntan los emboques (el punto de "embocar"), qué HookPoints hacen falta para llegar, y dónde están los peligros (zonas de muerte) y recompensas (coleccionables). Recordar que la cámara es **fija 1280×720**: todo el nivel cabe en una pantalla.

## Lecciones aprendidas / trampas (NO repetir)

- **Nunca corregir la restricción con `global_position = ...` (teletransporte):** ignora colisiones y el extremo atraviesa paredes. Usar siempre movimientos con barrido de colisión.
- **`move_and_collide` se detiene en el primer contacto y NO desliza.** Si el vector de corrección tiene componente contra una superficie (p. ej. hacia el piso), aborta *todo* el movimiento, incluida la parte útil. Por eso existe `_move_sliding()`, que proyecta el resto sobre la normal y continúa. Fue la causa de que la cuerda no limitara al jugador.
- **Medir el progreso de la restricción por reducción real de distancia**, no por cuánto se movió el extremo: si resbala tangencialmente por un muro, esa distancia recorrida no acorta la cuerda.
- **Orden en el árbol importa:** `WinManager` antes que los `Emboque`, y los `Emboque` después de los `Player` (para que las correcciones se apliquen el mismo frame).
- **UIDs:** no inventar `uid://...` a mano (Godot los rechaza como inválidos). Dejar que el editor los genere; en referencias `ext_resource` basta el `path`.
- **Inferencia de tipos:** acceder a propiedades de un nodo tipado genéricamente (`Node2D`) devuelve Variant y rompe `:=`. Tipar con el `class_name` real (p. ej. `var e: Emboque`).
- **Tunneling entre cuerpos delgados y rápidos:** un extremo veloz puede atravesar al otro. Protección actual: `continuous_cd = 2` (CCD cast-shape) + **física a 120 Hz**. **El tope de velocidad (`max_speed`) se QUITÓ** por decisión de diseño (el closeup ya frena el juego al acercarse). Si reaparece tunneling a velocidades altas, reconsiderar (subir ticks, engrosar paredes, o reintroducir un tope alto). Nota: `Engine.time_scale` NO reduce el avance por *tick* de física (solo hay menos ticks por segundo real), así que el slowdown no elimina el tunneling por sí solo.
- **Tamaños de las colisiones** (el arte se escaló para calzar con ellas; si cambia una colisión, reajustar la escala de su sprite): jugador 40×64; palito 22×6; campana ~18×24 (paredes 6px, hoyo ~12px). Las partes son ~1/3 del jugador. Magnetismo: `magnet_radius=70`, `linear_accel=900`, `angular_gain=2.5`, `falloff_exponent=3`; trabado `lock_radius=18`, `lock_strength=400`, `lock_damping=30`, `lock_max_accel=6000`, `lock_angular_gain=15`. Todo es tuneable en el Inspector.
- **Restricción de cuerda en RigidBody:** hacerla por **velocidad** en `_integrate_forces` (no fijando `transform.origin`), para no teletransportar a través de paredes. Definir `_integrate_forces` NO desactiva las colisiones (salvo `custom_integrator = true`).
- **Formas cóncavas en 2D:** no existen como shape convexa única. La campana (C) se arma con **varios `CollisionShape2D` rectangulares** (convexos), no un polígono cóncavo.
- **Al medir en tests una colisión con péndulo:** medir el **pico** (ej. máximo empuje), no el frame final — el péndulo/gravedad ya devolvió el cuerpo a su sitio y da un falso negativo.
- **No liberar/recargar dentro de un callback de física** (`body_entered`, `area_entered`, etc.): Godot prohíbe destruir CollisionObjects a mitad del paso físico. Usar `call_deferred(...)`. (Pasó con `reload_current_scene` en las zonas de muerte.)
- **En tests headless, simular input con `Input.parse_input_event(ev)`**, no `Input.action_press` — este último solo cambia el estado interno y no llega a `_input`/`_unhandled_input`.
- **`Input.action_press` cuenta como `is_action_just_pressed` recién en el tick de física siguiente.** En tests, mantener la tecla al menos 2 ticks antes de soltarla, o el "just pressed" nunca se ve.
- **No montar el balanceo como fuerzas encima del controlador de plataformas:** la fricción aérea (1300 px/s²) y el tope de 320 px/s de `player.gd` se comían el péndulo. El balanceo es un estado propio (θ, ω) que se salta el código de plataformas.
- **Un jugador parado sobre un RigidBody se mueve con la velocidad *informada* del cuerpo, no con la real:** si en `_integrate_forces` se fija la velocidad, el roce del paso la reduce después y el jugador de encima se adelanta (~8 px/s, se caía de la caja). Compensar el roce con una fuerza de un paso (`apply_central_force`), que no cambia la velocidad informada.
- **Los buses de audio van en `default_bus_layout.tres`, NO creados en runtime con `AudioServer.add_bus()`:** en el export web (reproducción por "samples") el motor JavaScript desordena los buses agregados en runtime y todo el audio sale **mudo**, aunque en escritorio funcione perfecto (pasó en Newgrounds: sin música ni efectos). Para agregar o cambiar un bus: en el editor, pestaña **Audio** (abajo) → editar y guardar el layout; o generarlo por script con `ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres")`. Nunca escribirlo a mano (mismo error que inventar un `uid://`).
- **El audio web solo arranca tras un gesto del usuario** (clic o tecla): antes, el navegador tiene el `AudioContext` suspendido; la música que ya "sonaba" empieza a escucharse en ese momento. Es normal.
- **Assets nuevos (WAV, PNG…) se importan con `"$GODOT" --headless --import --path .`**: `--editor --quit-after 2` cierra antes de escanear archivos nuevos y luego `load()` falla con "No loader found".
- **Para saber si un RigidBody *realmente* se mueve, medir el desplazamiento**, no `linear_velocity`: leída en `_physics_process` es la que fijó `_integrate_forces` (antes del solver), aunque el cuerpo esté trabado contra un muro.
- **Al soltarse de un gancho, darle al extremo la velocidad del jugador:** si queda quieto en el gancho, `_limit_player` frena el lanzamiento de golpe (se perdían ~80px de vuelo).
- **Mover un cuerpo directo (`global_position`) solo vale si no tiene colisiones:** es lo que hace el extremo en la mano (capa/máscara 0 + `freeze`). La regla de "nunca teletransportar" es por las colisiones; al devolverle las colisiones (soltar/lanzar) tiene que quedar en espacio libre — por eso parte desde dentro del cuerpo del jugador.
- **En tests, poner `reload_on_death = false` en TODAS las zonas de muerte antes de agregar el nivel** (recorrer el árbol: la zona "ambos" tiene dos hijas con script), y subir `WinManager.restart_delay`: recargar o cambiar de escena desde un nivel instanciado dentro de un test recarga/reemplaza **el test entero** (pasó: loop infinito en el test de muros).
- **Scripts de test con `-s` (extienden `SceneTree`): no nombrar clases del proyecto que dependan de autoloads** (`WinManager`, `Emboque`, `RopeEnd`, `PushBox`…, ni en tipos ni en `is`): el script se compila antes de que existan los autoloads y falla con "Identifier not found: Sfx/ScoreBoard". Tipar genérico (`Node`, `RigidBody2D`) y acceder a las propiedades por nombre; instanciar el nivel en `_initialize()` (no en `_init()`).
- **En tests, aislar los extremos de la cuerda:** `emboque.set_physics_process(false)` + `extremo.constrained = false` (+ `gravity_scale = 0`) los deja como cuerpos libres para medir fuerzas; desactivar también el `CloseupManager` (toca `Engine.time_scale`).
- **En tests, teletransportar a un jugador lejos de su extremo no sirve:** en el mismo tick `_limit_player` lo tira de vuelta hacia el extremo (antes de que la física vea el solapamiento). Mover también el extremo al lado.
- **Diseño: un gancho con el jugador parado arriba lo arrastra** — enganchado en el suelo, al acortar la cuerda `_limit_player` lo lleva hacia el punto sobre el gancho. Si hay un peligro entre el jugador y ese punto (las púas del Nivel 2), el jugador muere al tirar. Dejar el gancho a un lado del peligro (por eso el gancho izquierdo del Nivel 2 está en x=320 y no en 342 como en el boceto).
- **Una tecla que hace una acción puntual no debe seguir con su acción continua mientras se mantiene:** `soltar` deja el extremo *y* alarga la cuerda; sin `_release_used`, al dejarlo la cuerda se alargaba unos px y había que tirar dos veces para volver a tomarlo.
- **Al cargar una escena, los controles dentro de contenedores están un cuadro en (0,0) antes del layout:** Godot calcula el hover con esos rects y un botón puede quedar "con el mouse encima" sin estarlo (pasó con el botón Ajustes del menú al venir de la intro, sobre todo en web, donde el mouse no se ha movido). `boton_madera.gd` llama `get_viewport().update_mouse_cursor_state()` tras el primer cuadro para re-sincronizar el hover.
- **El extremo que nace (o queda) DEBAJO de la plataforma donde está el jugador lo amarra:** la cuerda atraviesa
  las plataformas pero el extremo no; al saltar, el extremo choca con la cara de abajo y `_limit_player` frena al
  jugador (saltos de ~85 px). Por eso los jugadores de los niveles nuevos aparecen **en el aire, arriba de donde
  aterrizan** (el extremo cae encima de la plataforma). Pasaba en `level_3`/`level_4` del equipo (`level_4` ya se corrigió y está en el mapa).
- **La cuerda corta le quita altura al salto** (hay que levantar el extremo): con el extremo apoyado, el salto
  llega a 155 px con cuerda 60, 194 con 170 y 239 con 320 (libre: 236). Saltos obligatorios ≤ 140 px; uno más
  alto exige cuerda larga (lo usa peligro_3 a propósito). Desde una caja, con el extremo en el piso 64 px más
  abajo, el salto queda en ~161 con cuerda 170.
- **En movimiento el extremo va detrás y a la altura del jugador** (al correr y saltar no se hunde): un peligro
  "abajo" castiga la cuerda larga cuando el jugador está **quieto** (cuelga derecho) o al soltarse de un gancho.
- **Los extremos ruedan y resbalan** (roce 0,05; la campana es redonda): no se quedan quietos en una placa
  plana (usar un rebaje) ni en una plataforma que se mueve. Al bajarse de un ascensor, el extremo que quedó
  arriba se va con él y tira al jugador.
- **Las placas las pisan también los extremos**: el extremo que cuelga detrás de un jugador puede activar una
  placa sin querer (pasó en movil_3); dejar espacio alrededor de las placas.
- **Muros sobre un cuenco: dejar ≥ 60 px entre el borde de abajo del muro y el cuenco**, o lo parten en dos y
  un extremo queda encajado entre la esquina del muro y la tabla.
- **Pozos de 38 px entre dos repisas** (no cabe un jugador, sí los extremos) son una meta simple, pero dos
  extremos pueden quedar encajados lado a lado sin girar si el pozo es hondo: preferir un cuenco.
- **Una caja empujada sobre un hueco se traba en la esquina de enfrente si las dos superficies están a la misma
  altura** (colisión fantasma): dejar la de llegada unos px más baja (caja_3).
- **Golpear una caja con un extremo casi no la mueve** (~8 px: extremo 1 vs caja 2 con roce): no basar puzzles
  en eso.
- **Un AnimatableBody2D que se mueve solo "ve" lo que está en su `collision_mask`**: la compuerta, con la máscara
  de fábrica (terreno), aplastaba al jugador contra el piso. Con la máscara completa espera.
- **Un `AudioStreamPlayer` se pausa con el árbol** (`get_tree().paused`): la música vive en un autoload pero igual
  se callaba en el menú de pausa (y el slider de música no se oía). La música y el pool de `Sfx` van con
  `process_mode = ALWAYS`; al mover el volumen de efectos suena una muestra (`Sfx.preview`).
- **Mostrar valores en un slider dispara `value_changed`**: al abrir Ajustes de la pausa se guardaba todo de
  nuevo (y sonaba la muestra). Para mostrar, `set_value_no_signal` / `set_pressed_no_signal`.
- **Lo que un nodo acumula por tick tiene que vaciarse en todos los estados**: el viento sobre el jugador se
  acumulaba mientras colgaba de un gancho (solo se aplicaba y vaciaba en el modo plataformas) y al soltarse
  llegaba de golpe.
- **En web la pantalla completa necesita un gesto**: al arrancar no se aplica la guardada (queda en ventana).
- Godot re-guarda escenas/`project.godot` al abrirlos (puede cambiar `uid`/`load_steps` u omitir valores por default); es esperado.
- **Tras reimportar, muchos `.import` aparecen "modificados" en `git status` sin cambios reales** (`git diff` vacío): Godot los escribe con fin de línea LF y el repo usa `core.autocrlf`. Descartarlos con `git status --porcelain | grep '^ M .*\.import$' | cut -c4- | xargs git checkout --` (ojo: `git diff --name-only` no los lista porque el diff está vacío). Los `.import` de archivos nuevos o movidos sí hay que commitearlos.
- **Arte hecho en paralelo por dos personas se pisa en el merge sin conflicto de texto:** pasó con los jugadores (sprites `Abierto`/`Cruzado` de una rama + `Sprite` animado de otra, los dos visibles). Tras un merge, correr y mirar cada nivel; todo el arte va en `assets/` para que se note cuando alguien ya tomó un asset.

## Estado de desarrollo

Hecho (el detalle de lo verificado con tests headless está en "Registro de tests", al final):

**Mecánica**
- **Base (fases 0–5):** Input Map y capas; personaje plataformero; cuerda híbrida (extremo-péndulo + cuerda visual) con largo continuo; el extremo colisiona y la cuerda limita al jugador; enganche a `HookPoint`; victoria con magnetismo.
- **Extremos como emboque real:** palito y campana `RigidBody2D` que rotan y chocan entre sí; victoria = palito dentro de la campana. Partes a ~1/3 del jugador y física a 120 Hz contra el tunneling. Proyecto en Godot 4.7.2 (antes 4.6).
- **Balanceo estilo DKC:** enganche instantáneo, péndulo propio del jugador, bombeo, salto desde la cuerda, soltarse con abajo, rapel, inclinación + squash/stretch.
- **Tomar y lanzar el emboque** (por nivel, `LevelRules`), con mira en ping-pong y vuelo recto; niveles con lanzar en verde en los menús.
- **Magnetismo con curva + trabado:** suave a distancia, resorte fuerte una vez embocado.
- **Closeup + cámara lenta** al acercarse los extremos (estilo Peggle).

**Objetos y niveles**
- **Zonas de muerte** (jugador / emboque / ambos), **caja empujable**, **coleccionables + puntaje** (también los recoge el emboque).
- **Mecánicas nuevas:** placas de presión, compuertas, plataformas móviles/ascensores, corrientes de aire (volantín), cuenco/embudo como meta.
- **25 niveles en un mapa ramificado** (tronco + 6 ramas + final), todos ganados por el bot de pruebas. Escena base heredable y bloques con `size`.
- Del equipo: `level_2` ("La T") y `level_4` ("Escalones", rehecho sobre level_base) están en el mapa (fin de las ramas de peligros y de cajas); `main`, `level_3` y las pruebas siguen en el repo pero fuera del mapa.

**Menús y presentación**
- **Intro:** video de la historia al arrancar (`video/intro.ogv`), se salta con cualquier tecla, fundidos de entrada/salida; en web pide una tecla antes para que suene.
- **Idiomas:** español e inglés (todo el texto en `i18n/textos.csv`, imágenes con texto por idioma), selector en el menú principal, Ajustes y pausa; agregar un idioma = una columna.
- **Menús:** principal (portada, botones de madera; sin Salir), mapa de niveles ramificado con progreso, ajustes, pausa con el diseño del equipo, pantalla de victoria (Reintentar / Continuar, sopaipillas, highscore por nivel en `user://scores.cfg`).
- **Audio:** autoload `Sfx` con 8 efectos placeholder, música (cueca) y volumen por categoría (General / Música / Efectos).
- **Arte (`assets/`):** jugadores animados (idle / caminata a 10 FPS / THROW al apuntar), palito, campana y cuerda, cajas, zonas de muerte animadas (fuego / púas / caca), sopaipillas, ganchos, terreno (piso por piezas + pared) y fondo.

Pendiente:
- **Fase 6** — Pasada de tuning de la sensación (magnetismo, masas, largos, velocidades, radios del closeup) jugando los niveles reales.
- **Arte que falta o hay que pulir:** cuadros propios para `jump` / `fall` / `swing` / `push` (hoy son provisorias con los cuadros de caminar/lanzar); costuras entre tablas de `piso_neutral` (vienen del dibujo); alinear bien el arte del palito y la campana con su colisión; la mano (`RopeAnchor`) no coincide exactamente con la mano del dibujo.
- **Web:** el preset existe y exporta (probado en Chromium headless con la intro); falta probar los niveles nuevos en navegador y subirlo a Newgrounds.
- **Imágenes en inglés definitivas** (`assets/ui/en/portada.png`, `pause_menu.webp`): hoy son el arte original
  con el texto reescrito por código; diseño puede reemplazarlas con el mismo nombre.
- **Niveles del equipo fuera del mapa** (`main`, `level_3`): corregir el inicio (ver Lecciones) si se quieren sumar.
- **Sonido:** reemplazar los efectos placeholder sintetizados por los definitivos.

Post-prototipo (del concepto): más objetos dinámicos, mapa de progresión de niveles (el selector como grafo conectado), más niveles.

## Convenciones

- Comentarios y nombres de usuario en **español**; código en GDScript idiomático de Godot 4.
- Placeholders geométricos (`Polygon2D`/formas) hasta que llegue el arte; al llegar se ocultan (`visible = false`), no se borran.
- **Todo el arte va en `assets/`** (ver Arquitectura). Al mover un archivo, moverlo **junto con su `.import`** (conserva el uid) y actualizar las rutas `res://` que lo usan.
- Cámara **fija** en los primeros niveles (del tamaño de la cámara, sin scroll).

## Registro de tests

Qué se verificó de cada feature con tests headless y con qué resultado. Los scripts de test eran temporales, así que esta sección es el registro de lo comprobado: al terminar una feature, agregar aquí qué se probó y el resultado (y una línea en "Estado de desarrollo").

### Mecánica base

- **Cuerda limita al jugador (Fase 4):** sobre-extensión 459 px → 0,04 px.
- **Enganche básico (Fase 4.5):** engancha al tocar, rapel con soltar/tirar, salto desengancha. PASS.
- **Extremos como emboque real:** colisión entre extremos sin atravesarse (incl. a velocidad alta), emboque por magnetismo, enganche. PASS.
- **Balanceo estilo DKC:** radio exacto, período, bombeo ≤ ángulo máx, enganche instantáneo, lanzamiento sin tirón, rapel, enganche sobre el gancho, suelo atado, sin doble salto. PASS.
- **Muros laterales:** en todos los niveles hay muro exactamente en `x=0` y `x=1280` (consulta de punto / raycast). PASS. Los niveles 3 y 4 no los tenían tras el merge de develop; agregados y verificados (muro en y −300…700 a ambos lados).

### Victoria, magnetismo y closeup

- **Closeup + slowdown:** lejos → normal; cerca → zoom ~2, time_scale 0,35 y cámara al punto medio; revierte; time_scale se reinicia al salir. PASS.
- **Magnetismo con curva + trabado** (extremos sueltos, sin cuerda ni gravedad):

  | Caso | Lineal (antes) | Curva exp 3 (ahora) |
  |---|---|---|
  | Acercamiento en 0,2 s desde 45 px de la boca | 10,5 px | 1,4 px |
  | Desde 30 px | 18,3 px | 6,0 px |
  | Desde 20 px | 21,1 px | 13,0 px |
  | Pasada rasante a 35 px, 300 px/s: desvío hacia la campana | 36,6 px | 6,3 px |

  Trabado, tirando del palito hacia afuera durante 1 s: 1500 px/s² → separación máx 2,3 px; 3000 px/s² → 4,7 px; temblor en el último 0,5 s = 0 px y sigue trabado. Victoria desde 30 px acercándose a 60 px/s: gana en 0,37 s con 0° y con 20° de error.
- **Pantalla de victoria + highscore:** récord, no-récord, independencia entre niveles, persistencia en `user://scores.cfg`. PASS.

### Objetos y zonas

- **Ajustes con el tema de madera** (Xvfb, es/en): se ve como el panel de la pausa; borrar progreso: 1 clic pide
  confirmar ("¿Seguro? Presiona otra vez"), el 2.º borra (completados 25 → 0), sin 2.º clic se desarma a los 3 s. PASS.
- **Revisión de bugs (fixes verificados):** ganado + tocar una zona de muerte → no recarga ni suena y llega a la
  victoria; dos zonas en el mismo instante → una sola recarga; música sigue en la pausa (avanza 0,65 s en 0,6 s
  reales); abrir Ajustes de la pausa no suena ni guarda; mover Efectos da una muestra; plataforma bajando sobre un
  jugador se detiene 1 px sobre su cabeza sin moverlo. PASS 9/9. `run_all.sh` 25/25 después de los cambios.
- **Zonas de muerte:** detección, aislamiento por máscara (la de jugador no mata al emboque y viceversa), zona "ambos". PASS. Tras ponerles arte (HazardArt) se volvió a verificar que siguen disparando.
- **Caja empujable:** asentarse, empuje parejo, frenar al soltar, muro, pararse encima, pasajero, golpe de campana, empujes opuestos, caída de borde, pila. PASS.

### Presentación y sonido

- **Video convertido con `tools/convertir_video.sh`** (fuente 1920×1080 a 60 fps con audio, 12 s): sale Theora 1280×720 30 fps + Vorbis 44,1 kHz estéreo; en la intro avanza a velocidad real (6,08 s a los 6 s) y al terminar (12,5 s) pasa solo al menú; resto del test de la intro igual. PASS 21/21.
- **Intro (video)** (escritorio con Xvfb + export web en Chromium headless, con un .ogv de prueba): arranca como escena principal, video sonando y cueca callada; una tecla en los primeros 0,35 s no salta; mensaje visible con el texto pedido; el video llena 1280×720 (16:9) y uno 4:3 queda centrado con franjas (960×720 en x=160); tecla → fundido → menú; la cueca vuelve con fundido (−36 dB → 0 dB); volver al menú desde otra escena no repite fundido ni reinicia la música; al terminar el video pasa solo al menú; clic también salta; sin video va directo al menú con música. PASS 20/20. En web: aviso "para comenzar" → video → menú, con salida de audio medida (AnalyserNode): aviso 0,0000, video 0,074, menú (cueca) 0,158; el .ogv entra al .pck. Botón Ajustes con brillo fantasma al llegar al menú (bug previo del layout, ver Lecciones) corregido: sin mouse encima no brilla, con el mouse encima sí, y sigue al mouse.

- **Animaciones provisorias + toques** (capturas con Xvfb en caja_1/tronco_3): estados push/jump/fall/idle con su cuadro; inclinación al empujar; aplastón al aterrizar con los pies en el piso. El bot sigue ganando igual (son solo visuales). PASS.
- **Mirada + espejo + sonidos:** mirada/espejo, estados de animación, ~8 pasos/s, pasajero sin pasos, salto, enganche, whoosh por pasada, loop de la caja on/off, muerte sin sonido duplicado. PASS.
- **Volumen por categoría:** buses creados y enviando a Master, los tres volúmenes no se pisan, persisten en `user://settings.cfg`, Sfx y la caja usan el bus SFX. PASS.
- **Audio en el export web** (build exportado, navegador Edge headless controlado por DevTools, midiendo la señal que llega a la salida con un AnalyserNode; control: un tono de prueba da RMS 0,71): con los buses creados en runtime la salida era **0,0000** aun con el AudioContext activo tras el clic (mudo, igual que en Newgrounds); con `default_bus_layout.tres` la música da RMS ~0,1–0,2 tras el primer clic y 3 saltos en el Nivel 1 disparan 3 efectos. PASS. En el mismo build web, el menú principal sin Salir deja Jugar/Ajustes centrados.
- **Menú de pausa (diseño del equipo):** cada uno de los 7 niveles tiene exactamente un PauseMenu; Esc pausa/reanuda; foco en Continuar; los 4 botones calzan con los pintados; hover mueve el foco; Ajustes muestra sliders y oculta botones; el slider cambia SettingsManager; Volver devuelve el foco a Ajustes; Continuar reanuda. PASS 43/43. Luego se agregó P como segunda tecla (acción `pause`): P pausa y reanuda, Esc también (en `level_3`). PASS.
- **Arte (jugadores, cajas, zonas, sopaipillas, terreno, fondo, ganchos):** cada nivel cargado y capturado sin errores de script; animación de caminata a la frecuencia pedida (cambio de frame cada 12 ticks a 10 FPS con física a 120 Hz).

### Lanzar el emboque (`test_throw.tscn`) — PASS 49/49

No toma al acortar hasta el mínimo; toma con pulsación nueva; en la mano va sin colisiones y pegado a la mano al caminar; apuntando no camina ni salta pero gira; la mira va de 0 a 60° y vuelve; soltar restaura todo sin alargar la cuerda; vuelo recto con desvío 0 px hasta 320 px; choca con la torre sin atravesarla; el mejor salto queda 40 px bajo el techo de la torre; cada jugador lanza a su gancho → sube → queda arriba de la torre; un extremo en la mano no emboca ni activa el closeup (con control); sin `LevelRules` no hay mecánica. Desde el mejor lugar (~150–200 px del gancho) sirve una ventana de ~10° del barrido.

### Nivel 2 (`level_2.tscn`) — PASS 27/27

Rojo mata al jugador y no al emboque; naranja mata a ambos; el muro no se salta por arriba; extremos y jugadores recogen. Rutas: J1 baja con cuidado a la izquierda del rojo, engancha el gancho de abajo (tirar al mínimo, soltar un poco y volver a tirar) y se balancea hasta la T en 10/12 combinaciones largo/ángulo; J2 acorta la cuerda, corre a la izquierda, el palito engancha el gancho derecho y salta a la T en 4/4 ángulos; con la cuerda a 170 el palito roza el bloque naranja; desde la T los extremos cuelgan bajo el muro, se juntan a 5 px y recogen los 2 coleccionables de abajo.

### Niveles del mapa (bot, `tests/run_all.sh`) — 25/25 ganados

Cada nivel se gana con el plan de `tests/solutions/<nivel>.gd` (además se barrieron parámetros: largo de cuerda,
ángulo de lanzamiento, bombeo, punto de salto; y se probaron "controles" que deben fallar). Resumen:

| Nivel | Tiempo | Controles que fallan (como debe ser) |
|---|---|---|
| tronco_1..4 | 5–15 s | T2: sin ajustar largos no se juntan; T3: el salto directo no cruza (el extremo engancha solo) |
| peligro_1 Púas | 19 s | — (sopaipillas en zanjas de púas que solo el emboque alcanza) |
| peligro_2 Cuidado abajo | 8 s | quedarse en el borde con cuerda 170, o bajar el extremo de más → caca |
| peligro_3 Brasas | 9 s | cuerda 90–170 sobre las brasas → el extremo se quema; cuerda 60–100 no sube el escalón |
| level_2 La T (equipo) | 24 s | cuerda 120 de J2 → el palito toca el bloque de fuego |
| caja_1..3 | 8–14 s | caja_3: si J2 sigue la caja al piso de J1, su extremo cae a la caca |
| level_4 Escalones (equipo) | 15 s | caja empujada a <30 px de la plataforma → el salto choca con ella (gana con largos 130–190 al bajar al cuenco) |
| placa_1..3 | 6–12 s | — |
| movil_1..3 | 8–17 s | movil_2: cuerda 170 en la plataforma → caca |
| lanzar_1..3 | 6–10 s | lanzar_3: sin acortar al soltarse, el extremo cuelga al fuego |
| viento_1..3 | 5–10 s | — |
| final | 10–13 s | frenar fuera de ~465–470 en el bot → fuego (el humano corrige en el aire) |

También: mapa (desbloqueo, foco inicial en lo recién desbloqueado, F9), flujo completo menú → mapa → nivel →
victoria → Continuar → mapa con el siguiente desbloqueado (PASS); compuerta no aplasta; capturas de cada nivel
revisadas.
