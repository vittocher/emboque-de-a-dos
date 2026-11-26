# CLAUDE.md — Emboque de a Dos

## Qué es

Puzzle **cooperativo local de 2 jugadores** (estilo *Fireboy & Watergirl*) en **Godot 4.7.2**, apuntado a **web (Newgrounds)**. Tema: amistad y tradición chilena. Concepto completo en `EmboqueDA2 Concepto.pdf`.

## Setup

- **Editor:** Godot **4.7.2** (`config/features` en `project.godot` = `4.7`). Windows: `C:\Users\vitto\Desktop\Godot\Godot_v4.7.2-stable_win64.exe` (la variante `..._console.exe` sirve para CLI headless). Linux: `~/Godot/Godot_v4.7.2-stable_linux.x86_64`.
- **Abrir:** importar el `project.godot` de esta carpeta desde el Project Manager, o **F5** para jugar.
- **Escena de arranque:** `res://scenes/ui/intro.tscn` (video de intro, se salta con cualquier tecla → menú `ui/main_menu.tscn`). Durante el desarrollo, abrir un nivel y correr con **F6** (ejecutar escena actual) para saltarse el menú.
- **Resolución base:** 1280×720 (16:9). Stretch `canvas_items` + aspect `keep` (default en Godot 4, por eso el editor lo omite del archivo). No pixel-art; se adapta a cualquier tamaño de embed sin deformar. Física a **120 Hz**.

### Validación headless (sin abrir el editor)

```bash
GODOT="/c/Users/vitto/Desktop/Godot/Godot_v4.7.2-stable_win64_console.exe"
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

Redirigir la salida a un archivo y filtrar aparte evita cuelgues del pipe. Los avisos `ObjectDB instances leaked` / `resources still in use at exit` al cerrar son normales en estas corridas. Para escribir tests, ver las trampas de tests en "Lecciones aprendidas" (input simulado, `-s` y autoloads, zonas de muerte); el registro de lo ya verificado está en `docs/REGISTRO_TESTS.md`.

## Controles (Input Map en `project.godot`)

| | Mover | Saltar | Soltar cuerda | Tirar cuerda | Lanzar* |
|---|---|---|---|---|---|
| **J1** (`input_prefix = "p1"`) | `A` / `D` | `W` | `T` | `R` | `G` |
| **J2** (`input_prefix = "p2"`) | `←` / `→` | `↑` | `.` | `,` | `L` |

\* Solo en niveles con la mecánica de lanzar activada (ver "Tomar y lanzar el emboque").

Las acciones siguen el patrón `<prefix>_<accion>`: `_left`, `_right`, `_jump`, `_down` (S / flecha abajo), `_release` (soltar = alargar), `_pull` (tirar = acortar), `_throw` (lanzar). Usan `physical_keycode` (independiente del layout del teclado).

**Esc** o **P** (acción `pause`) abre/cierra el **menú de pausa** en el nivel (ver `pause_menu.gd`). P existe porque en web, con pantalla completa, el navegador se queda con Esc para salir de ella y no llega al juego.

**Enganchado** (ver "Balanceo enganchado"): izquierda/derecha **bombean** el balanceo, `saltar` **se lanza** desde la cuerda (impulso del balanceo + salto), `abajo` (S / ↓) se **suelta** conservando la velocidad, `soltar` baja al jugador (rapel) y `tirar` lo sube.

**Lanzar** (solo en algunos niveles): `lanzar` con el extremo colgando, tirado o en vuelo lo **recoge** rápido a la mano (también se toma con la cuerda ya al mínimo y `tirar` otra vez); `lanzar` con el extremo en la mano empieza a **apuntar** (línea punteada que va y vuelve de 0° a 60° hacia arriba; el jugador queda quieto y izquierda/derecha solo lo giran); `lanzar` otra vez lo **lanza** (la cuerda pasa al máximo). Así la misma tecla hace el ciclo recoger → apuntar → lanzar. `soltar` lo deja caer (tomado o apuntando) o corta la recogida.

## Arquitectura

```
scenes/
  main.tscn            Nivel 1: cámara fija (640,360), suelo, 2 plataformas, muro central, 2 HookPoint,
                       WinManager, CloseupManager, 2×(Player+Emboque), UI/WinLabel, fondo y arte del terreno.
  level_2.tscn         "La T" (boceto del equipo; rehecho sobre level_base_large conservando la T): J1 sube en zigzag a la
                       plataforma media, se engancha a un gancho bajo su borde y se balancea hasta la T; J2 sube en
                       zigzag, cruza un puente de caca y pasa con su gancho bajo una cortina. Se emboca con los
                       extremos colgando bajo el muro, parados cada uno en su mitad de la T.
  level_3.tscn         Nivel 3: cada jugador sube por 3 escalones de su lado hasta la cima, cae y se engancha a
                       un HookPoint (2, uno por lado) para aterrizar en la plataforma central, donde se emboca.
                       Piso de fuego; 8 coleccionables.
  level_4.tscn         "Escalones" (del equipo, final de la rama de cajas; rehecho sobre level_base_large): dos pisos,
                       los dos jugadores van hacia la derecha (J1 arriba, J2 abajo) y cada uno sube una pared de 160 con
                       su caja grande; J2 pasa por un túnel bajo el hueco de la meta y sube en zigzag al otro lado.
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
  levels/level_base_large.tscn  La misma base con la cámara alejada (zoom 0,8, mundo 1600×900). Ver "Escala del nivel".
  levels/*.tscn        Los 27 niveles nuevos del mapa (heredan la base): tronco_1..4, peligro_1..3, caja_1..3,
                       placa_1..4, movil_1..4, lanzar_1..4, viento_1..4, final. Cada uno descrito en su solución
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
  wind_zone.tscn       Corriente de aire (Area2D) con rayitas de aire (CPUParticles2D) y sonido en loop; opcional en ráfagas.
  fx/emboque_burst.tscn  Celebración del emboque (ver "Animación del emboque"): destello + estrellitas doradas
                       (CPUParticles2D con destello.gdshader); el WinManager lo pega a la campana.
  fx/tension_fx.tscn     Subida de tensión al acercarse los extremos (TensionFx, la crea el CloseupManager):
                       silencio antes del golpe, viñeta (vineta.gdshader) y halo dorado en los extremos.
  fx/win_confetti.tscn   CanvasLayer con confetti (colores de la bandera + dorado, confeti.gdshader) y chispas
                       que salen de las esquinas de abajo hacia el centro y arriba.

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
  push_box.tscn        Caja empujable (RigidBody2D 64×64 o el `size` que se le ponga, capa 6, rotación bloqueada). Reutilizable en cualquier nivel.
                       Arte: Sprite con assets/props/caja/caja.png (320×320 a escala 0.2) + material resaltar.gdshader
                   (madera más cálida y saturada + contorno dorado que late: se distingue del terreno y se
                   entiende que se mueve); placeholders ocultos.
  collectible.tscn     Area2D recolectable (sopaipilla animada, assets/props/puntos, 2 frames a 6 FPS; rombo oculto):
                       lo toca un jugador o un extremo del emboque (mask 14) → suma puntos y se destruye.
                       La cuerda no recoge (es solo una Line2D).
  closeup_manager.tscn Efecto reutilizable: closeup + cámara lenta al acercarse los extremos (instanciar por nivel).
  background.tscn      Fondo del nivel: Sprite2D con assets/entorno/fondo/paredazul.png (1280×720 a escala 1,
                       centrado en (640,360), z_index -100). En el mundo, así acompaña el zoom del closeup.
                       Material fondo.gdshader: desenfoque suave, menos contraste y saturación, viñeta (para
                       que personajes y objetos se lean primero). La textura necesita mipmaps (import).
  terrain_art.tscn     Arte del terreno (TerrainArt): instanciado una vez por nivel, cubre cada StaticBody2D con
                       forma rectangular usando assets/entorno/colision/: horizontales = piso armado con piso_left +
                       piso_neutral (repetido) + piso_right, o piso.png si cabe una sola tabla; verticales =
                       pared.png. Sin deformarse. En juego oculta los Polygon2D "Visual".

  ui/intro.tscn          Intro: video de la historia (video/intro.ogv) al arrancar el juego; se salta con cualquier
                         tecla / clic / botón (mensaje abajo). Ver "Intro (video)".
  ui/main_menu.tscn      Menú: portada (assets/ui/portada.png, con el título y los controles ya dibujados) de fondo
                         + botones Jugar / Ajustes (sin Salir: el juego es para web).
  ui/boton_madera.tscn   Botón de madera reutilizable (class BotonMadera: menú principal, mapa, victoria). Tabla con
                         canto y sombra (shader madera_boton) que se hunde al apretarla; resaltada crece, se aclara,
                         halo dorado y un destello la cruza. Cara (lo visual) + Btn (Button transparente: clic y foco).
                         `press_sound` = sonido al apretarlo. Ver "Interfaz: respuesta y transiciones".
  ui/level_selector.tscn MAPA de niveles (ver "Mapa de niveles y progreso"): nodos de madera (ui/level_node.tscn)
                         unidos por cuerdas, panel con nombre/récord/sopaipillas, fondo con círculos (map_decor.gd).
  ui/settings.tscn       Ajustes (panel de madera, tema compartido ui/tema_madera.tres): volumen general / música /
                         efectos, pantalla completa, idioma, restaurar valores y borrar progreso (pide confirmar).
  ui/tema_madera.tres    Tema de madera de los paneles (Ajustes y el panel de ajustes de la pausa): botones-tabla
                         con canto (se aclaran con el mouse, se hunden al apretar, anillo dorado con foco), sliders
                         con perilla dorada (GradientTexture2D), checkbox (assets/ui/check_on|off.png), listas.
  ui/pause_menu.tscn     Menú de pausa (Esc / P), ÚNICO para todos los niveles: instanciarlo en cada nivel.
                         Diseño = imagen assets/ui/pause_menu.webp con botones invisibles encima (ver "Menú de pausa").
                       Trae también el indicador HUD de pausa (ui/hud_pause.tscn), así está en todos los niveles,
                       y un ControlsPanel por jugador a los costados del tablero (J1 izquierda, J2 derecha).
  ui/controls_panel.tscn ControlsPanel: controles de un jugador (`prefix` p1/p2) con el estilo de la portada (etiqueta
                         del color del jugador + teclas crema, KeyCap) sobre madera. Teclas leídas del Input Map; la
                         fila de lanzar solo si el nivel tiene LevelRules.throw_enabled.
  ui/hud_pause.tscn      HUD, esquina superior izquierda: placa de madera con una tecla "P" + "PAUSA" (clave
                         HUD_PAUSE). Va dentro del PauseMenu, que la oculta en pausa; con el mouse brilla y un clic pausa.
  ui/hud_score.tscn      HUD, esquina superior derecha (ScoreHud): placa de madera con la sopaipilla + "Puntos: N";
                         anclada a la derecha, crece hacia la izquierda y salta al sumar puntos (en tiempo real).
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
                   attach_to (al embocar: el palito va montado en la campana, ver "Animación del emboque").
  win_manager.gd   Magnetismo (curva de distancia + ángulo, y trabado al embocar) + victoria (palito dentro de campana)
                   + animación del emboque (piezas pegadas, click de cámara, partículas).
  closeup_manager.gd Closeup de cámara + slowdown (Engine.time_scale) al acercarse los extremos; reutilizable;
                   reinicia time_scale en _exit_tree. Cámara lenta al 0,4 (`min_time_scale`; antes 0,15, se suavizó) y la música
                   más lenta y grave a la par (`music_min_pitch` 0,85, vía SettingsManager.set_music_pitch;
                   normal en la pausa y al salir). Al embocar, end_slowdown() los devuelve a lo normal en
                   0,12 s (el encuadre sigue). punch() = "click" de zoom al embocar (grupo "closeup_manager").
  tension_fx.gd    class TensionFx: subida de tensión (ver "Animación del emboque"). update(t) cada cuadro,
                   release() al embocar.
  win_fx.gd        class WinFx: raíz de las escenas fx/: dispara sus partículas, las corre en tiempo real
                   (ignora la cámara lenta) y se borra sola.
  level_rules.gd   Nodo (class_name LevelRules, grupo "level_rules") con las mecánicas opcionales de un
                   nivel: casilla throw_enabled. Nivel sin el nodo = todo lo opcional apagado. También
                   THROW_COLOR (verde de la mecánica en los menús) y scene_throw_enabled(escena).
  level_flow.gd    class LevelFlow: estado del nivel en curso (meta en la escena): ganado (ya no se muere ni
                   junta) y reiniciándose (una sola recarga aunque se toquen varias zonas a la vez). level_size(tree) =
                   tamaño del mundo del nivel (del CloseupManager): usarlo en vez de asumir 1280×720.
  player_death_zone.gd   Al entrar un jugador (mask=2) → reinicia el nivel. Señal triggered; export reload_on_death.
  emboque_death_zone.gd  Al entrar un extremo (mask=12 = campana 4 + palito 8) → reinicia. (Scripts separados a propósito.)
  hazard_art.gd    @tool, class HazardArt: arte animado de una zona de peligro (ver both_death_zone.tscn) +
                   su brillo (fuego rojo, caca verde) o su sombra con forma (púas).
  visual_fx.gd     class VisualFx: capas de z de sombras/brillos y helpers (soft_box, silhouette_material).
  drop_shadow.gd   @tool, class DropShadow: hijo de un Sprite2D/AnimatedSprite2D/Line2D → su sombra difusa.
  contact_shadow.gd class ContactShadow: hijo de un cuerpo → mancha en el piso bajo él (rayo hacia abajo).
  terrain_art.gd   @tool, class TerrainArt: arte del terreno (ver terrain_art.tscn).
  collectible.gd   Area2D: al tocarlo un jugador o un extremo, busca el ScoreManager (grupo "score_manager"),
                   suma `points` y queue_free.
  score_manager.gd Lleva el puntaje del nivel (y coleccionables juntados/totales) y actualiza el indicador del HUD
                   (ScoreHud o un Label: le pone `text`); lo oculta si el nivel no tiene coleccionables. Está en el grupo "score_manager".
  level_catalog.gd class LevelCatalog: la ÚNICA lista de niveles (id, escena, posición en el mapa,
                   de qué niveles depende). Desbloqueo, número de nivel, coleccionables por escena.
  block.gd / bowl.gd  Bloque de terreno con `size`; cuenco con `width`/`slope` (ambos @tool).
  mechanisms/      channel.gd (canales con color), pressure_plate.gd, gate.gd, moving_platform.gd, wind_zone.gd.
  push_box.gd      Caja empujable (class_name PushBox): el Player la empuja con push(); los extremos la golpean por física.
                   Si cae fuera de la pantalla (`respawn_y`) reaparece donde partió.
                   Suena un loop de arrastre mientras se desliza por el piso.
  pause_menu.gd    Menú de pausa del nivel (acción `pause` = Esc / P): Continuar / Reiniciar / Ajustes / Menú principal. Es el
                   script de ui/pause_menu.tscn. La pausa NO es global: cada nivel debe instanciar esa escena.
  settings_manager.gd AUTOLOAD (SettingsManager): volúmenes, buses de audio, pantalla completa, idioma, música,
                   persistencia.
                   stop_music() / play_music(fade) (la intro calla la cueca mientras corre el video).
                   set_music_pitch(p): tono/velocidad de la música (lo usa la cámara lenta del closeup).
                   set_music_duck(db) / set_sfx_duck(db): bajada temporal de los buses Music / SFX sin tocar el
                   volumen de Ajustes (el silencio antes del golpe, TensionFx).
  languages.gd     class Languages: idiomas disponibles, nombre de cada uno, traducción desde código estático e
                   imagen localizada (ver "Idiomas").
  score_board.gd   AUTOLOAD (ScoreBoard): datos de la última victoria entre escenas + highscore por nivel +
                   niveles COMPLETADOS (y máximo de sopaipillas) en user://scores.cfg. De eso depende el
                   desbloqueo del mapa. `unlock_all` (solo desarrollo, F9 en el mapa) desbloquea todo.
  sfx.gd           AUTOLOAD (Sfx): registro único de efectos de sonido (SOUNDS: nombre → ruta + volumen base),
                   pool de AudioStreamPlayer, play(nombre, pitch, volumen). Sobrevive a la recarga del nivel.
  ui_fx.gd         AUTOLOAD (UiFx): respuesta de TODA la interfaz (sonido, cursor de mano, foco con el mouse de
                   cada botón/slider/lista, conectados solos) + cambios de pantalla con fundido (go_to / reload /
                   reveal). Ver "Interfaz: respuesta y transiciones".
  ui/level_hint.gd class LevelHint (escena ui/level_hint.tscn): cartel de controles DENTRO de un nivel, sobre madera,
                   uno por jugador en su mitad de la pantalla (`player` p1/p2 = etiqueta). Cada fila de `rows` es
                   "@accion texto": `@p1_release` = tecla del Input Map, `/` = barra, lo demás = clave de i18n.
                   Lo usan tronco_2 (soltar/tirar cuerda) y lanzar_1 (recoger → apuntar → lanzar).
  ui/style_bonus.gd class StyleBonus (escena ui/style_bonus.tscn): textos de los bonos de estilo al embocar (ver
                   "Bonos de estilo").
  ui/key_cap.gd    class KeyCap: tecla dibujada como en la portada; muestra la tecla de una `action` del Input Map
                   (flechas dibujadas con líneas: la fuente por defecto no trae ← → en la web).
  ui/wood_plaque.gd  class WoodPlaque: ColorRect con el shader de madera de los botones (madera_boton.gdshader):
                   le pasa su tamaño y prende el brillo (`active`). Fondo de las placas del HUD.
  ui/*.gd          Lógica de los menús (navegación con UiFx.go_to, con fundido); intro.gd (class IntroScreen) = la intro; victory.gd muestra puntaje + récord;
                   boton_madera.gd = el botón de madera; level_selector.gd = el mapa; level_node.gd = un nivel
                   del mapa; map_decor.gd = fondo del mapa y de la victoria.

assets/            TODO el arte (sprites, fondos, UI), por tema: jugadores/, emboque/, entorno/, hazards/, props/, ui/.
                   No crear otras carpetas de imágenes. jugadores/p1|p2/alternativos/ guarda poses que hoy
                   no se usan. Ojo: el export web es `all_resources`, así que igual entran al build. No dejar copias
                   `-old` de un sprite al reemplazarlo: la versión anterior ya queda en git.
shaders/           madera_boton.gdshader (madera procedural de los botones: veta, borde dorado, brillo al resaltar
                   `active`; opcionales `pad` sombra/halo afuera, `depth` canto, `press` hundido, `shine` destello;
                   en 0 queda la tabla plana de las placas del HUD); silueta.gdshader
                   (sombra/brillo con la forma de un sprite) y caja_suave.gdshader (sombra/luz difusa de un
                   rectángulo). Ver "Sombras y brillos". resaltar.gdshader: ajuste HSV (tono/saturación/brillo) +
                   contraste + contorno que late (la caja empujable; sin contorno, en los personajes). fondo.gdshader: el
                   fondo con menos protagonismo. destello.gdshader (estrella de luz para partículas) y
                   confeti.gdshader (papelito que gira en 3D fingido): los de la animación del emboque.
                   vineta.gdshader: viñeta de pantalla completa (subida de tensión).
video/             intro.ogv (Ogg Theora: el único formato de video de Godot) + README.md con cómo convertirlo.
audio/             cueca.ogg (música, la pone SettingsManager) y sfx/: efectos placeholder (WAV 22 kHz mono):
                   step, jump, die, hook, swing, box_push (loop), grab, throw, plate, gate, wind (loop) y los
                   de la animación del emboque: emboque_click, sparkle, confetti_pop.
i18n/              textos.csv: TODOS los textos del juego, una columna por idioma (ver "Idiomas").
default_bus_layout.tres  Buses de audio Master / Music / SFX (ver "Volumen y buses de audio"). Obligatorio para web.
tools/convertir_video.bat|.sh  Convierte el video de la intro a video/intro.ogv (ver "Intro (video)").
tools/generate_sfx.py  Sintetiza los placeholders de audio/sfx (numpy): `python tools/generate_sfx.py [nombres]`
                   (sin nombres, todos; con nombres, solo esos, p. ej. `plate gate wind`).
tests/             Bot de pruebas (ver "Bot de pruebas"): play_level.gd, run_all.sh, run_controls.sh, monkey.gd + run_shortcuts.sh
                   (atajos), reach.py (alcance de saltos), solutions/<nivel>.gd,
                   rec_map.gd (graba el mapa para el tráiler). Excluido del export (exclude_filter "tests/*").
trailer/           Tráiler: trailer_es.mp4 / trailer_en.mp4 + cómo rehacerlo (make_trailer.sh: el bot juega y el
                   Movie Maker de Godot graba; cards.py hace las tarjetas; edit.py monta al ritmo de la cueca).
                   Tiene .gdignore y está fuera del export. Ver trailer/README.md.
docs/REGISTRO_TESTS.md  Qué se verificó de cada feature y con qué resultado (historial).
GUIA_ASSETS.md     Guía para diseño: qué archivo reemplazar para cambiar cada sprite/sonido en TODOS los niveles.
EmboqueDA2 Concepto.pdf  Documento de concepto del juego.
```

Autoloads (en `project.godot`): **`SettingsManager`** (volumen Master/Música/Efectos, pantalla completa, persistencia; va **primero** en la lista), **`ScoreBoard`** (puntaje entre escenas + highscore por nivel) **`Sfx`** (efectos de sonido, usa el bus SFX) y **`UiFx`** (respuesta de la interfaz y transiciones; va después de `Sfx`, que usa).

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
**Arte actual:** `assets/jugadores/p1|p2/` con un `SpriteFrames` por jugador (`p1_frames.tres` / `p2_frames.tres`). `player.gd` le pone al `Sprite` el de su `input_prefix` (exports `frames_p1` / `frames_p2` en `player.tscn`). Animaciones: `idle` (WALK_01), `walk` (WALK_02 → WALK_01 en loop a **10 FPS**), `aim` (THROW, al apuntar) y, **provisorias hasta que llegue el arte** (reusan esos mismos cuadros): `jump` (WALK_02, piernas abiertas), `fall` (THROW, brazos abiertos), `swing` (WALK_02) y `push` (caminata a 6 FPS). **Ojo con `idle`:** en el arte actual de J1, WALK_01 y WALK_02 son los dos pasos de la caminata (uno por pierna) y ninguno es una pose de pie (en la versión anterior, commit `d44ea7e`, el de J1 sí lo era), así que quieto queda a medio paso; J2 también, y en la pose contraria a la de J1. Falta un cuadro propio de pie. Si falta la animación del estado se usa `ANIM_FALLBACK` (`push` → `walk`) o `idle`.
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
| `emboque_click` | `win_manager.gd` `_celebrate` | Al embocar: "cli-click" de madera (el palito entra y se asienta), saturado suave para sonar fuerte sin subir el pico (+1 dB base). |
| `sparkle` | `win_manager.gd` `_celebrate` | Al embocar, con las partículas doradas: campanitas agudas sutiles (−15 dB). |
| `confetti_pop` | `win_manager.gd` `_celebrate` | Al embocar, con el confetti: dos pops (una esquina cada uno) y papel que cruje. Suena 0,06 s después del click (se oye el click solo y la suma no satura). |
| `ui_hover` | `ui_fx.gd` | Mouse encima de un botón/slider/opción, o foco movido con flechas (no el foco que pone el código). Tic de madera suave, tono ±4 %. |
| `ui_click` | `ui_fx.gd` | Al apretar un botón (default). En un toggle (checkbox), más agudo al prender (1,12) y grave al apagar (0,88). |
| `ui_confirm` | `ui_fx.gd` (Jugar, Continuar), `level_selector.gd` | El sonido "especial": golpe de madera + dos notas de cuerda que suben (como un charango). Entrar a un nivel. |
| `ui_back` | `ui_fx.gd` (botones Volver / Menú principal), Esc en los menús | Golpe grave + dos notas que bajan. |
| `ui_locked` | `level_selector.gd` | Elegir un nivel bloqueado ("tuc-tuc" apagado, con la sacudida). |
| `ui_tick` | `ui_fx.gd` (sliders), `victory.gd` (conteo) | Tic corto; el tono sube con el valor del slider / mientras se cuenta el puntaje. |
| `ui_open` | `pause_menu.gd` | Abrir la pausa (soplo + nota); al cerrarla, el mismo más grave (0,8). |
| `ui_unlock` | `level_selector.gd`, `victory.gd` | Arpegio que sube: nivel nuevo desbloqueado en el mapa, récord nuevo en la victoria. |

`Sfx.play` ignora el mismo sonido repetido en el mismo tick de física (p. ej. las dos partes de una zona "ambos"). Emite `played(nombre)` (útil para tests).

### Zonas de muerte (`player_death_zone.gd` + `emboque_death_zone.gd`)

`Area2D` que al ser tocadas (`body_entered`) recargan el nivel. El **filtro por máscara** decide a quién matan: jugadores = `mask 2`; emboque = `mask 12`. Hay **dos scripts separados** (jugador / emboque) para poder darles mecánicas distintas a futuro; la zona "ambos" los **compone** (dos `Area2D` hijas, una con cada script) y tiene su propio arte (fuego). Cada script setea su `collision_mask` en `_ready`, expone `signal triggered(body)` y `@export reload_on_death` (ponerlo en `false` en tests para no recargar). Guard `_fired` evita disparos repetidos.

La recarga se hace con `LevelFlow.restart(tree)` (diferida: **recargar dentro de `body_entered`, un callback de física, está prohibido** en Godot, libera CollisionObjects a mitad del callback; y una sola vez aunque se toquen dos zonas en el mismo instante). **Desde que se emboca** (`LevelFlow.mark_won`, lo llama el WinManager) las zonas ya no matan ni los coleccionables suman: si no, caer al fuego en los 2,5 s del cartel de victoria recargaba el nivel en vez de ir a la pantalla de victoria.

### Interfaz: respuesta y transiciones (`UiFx` + `BotonMadera` + `tema_madera.tres`)

Todo control interactivo tiene que **verse y sentirse** como tal. El autoload **`UiFx`** (`scripts/ui_fx.gd`) se
conecta solo, con `SceneTree.node_added`, a cada `BaseButton`, `Slider` y `PopupMenu` que entra al árbol (en
cualquier escena, sin tocarla): cursor de mano, **el mouse le pasa el foco** (brilla uno solo; mouse y teclado van
juntos), `ui_hover` al pasar el mouse o mover el foco con flechas, sonido al apretar, tic con tono en los sliders,
tic/click en las listas. Al cargar una escena hay 0,3 s sin hover (el foco inicial y el mouse que ya estaba encima
no suenan). Lo **visual** es de cada control:

- **`BotonMadera`** (menú, mapa, victoria): tabla con canto (7 px) y sombra; resaltada (hover o foco) crece a 1,045,
  la madera se aclara, borde dorado + halo afuera y un destello diagonal la cruza; apretada se hunde (cara y texto
  bajan el canto). `appear(delay)` = entrada desde abajo (solo mueve la `Cara`: sirve dentro de contenedores).
- **Tema de madera** (Ajustes y ajustes de la pausa): `Style_plank*` con canto (sombra sólida corrida 5 px), hover más
  claro con borde dorado, pressed baja 4 px (expand_margin_top −4 / bottom +4, canto de 1 px), foco = anillo dorado.
- **Mapa** (`LevelNode`): fichas con canto que crecen, se aclaran y se hunden; `bump()` al entrar con Enter.
- **Pausa** (botones invisibles sobre la imagen): con foco, luz cálida encima (`Style_glow` con fondo 14 %) y el borde
  dorado respira; al abrir, el tablero baja con rebote y suena `ui_open`; Ajustes aparece con un pequeño rebote.
- **HUD de pausa**: crece y brilla con el mouse, con tic.

Por control, como **metadata** (Inspector → Metadata): `ui_fx = false` (no conectarlo), `ui_press_sound = &"ui_back"`
(otro sonido; `&""` = ninguno, cuando el script pone el suyo, como Continuar de la pausa o los niveles del mapa),
`ui_slider_sound = false` (el slider de Efectos, que ya suena con `Sfx.preview`). En `BotonMadera`, el export
`press_sound`.

**Transiciones**: `UiFx.go_to(escena)` / `UiFx.reload()` funden al azul de los menús (0,2 s), cambian (despausando el
árbol) y vuelven (0,3 s), en tiempo real (`set_ignore_time_scale`, aunque haya cámara lenta). Durante el fundido el
velo bloquea el mouse y un segundo cambio se ignora (doble clic, Enter repetido); `UiFx.is_transitioning()` para
no sonar dos veces. `UiFx.reveal()` = solo aparecer (la victoria, a la que se llega desde el WinManager sin `go_to`).
La recarga por muerte (`LevelFlow.restart`) y el paso del nivel a la victoria siguen sin fundido.

**Entradas animadas**: menú (botones uno tras otro), Ajustes (el panel sube), mapa (el panel de info se asoma al
cambiar de nivel), victoria (título que cae y rebota con estrellitas `fx/emboque_burst.tscn` detrás, puntaje y
sopaipillas que se cuentan con tic, "¡Nuevo récord!" dorado que late con `ui_unlock`, botones escalonados). Los
botones funcionan desde el primer cuadro.

### Intro (video) (`ui/intro.tscn` + `ui/intro.gd`)

Escena de arranque. Reproduce `video/intro.ogv` (export `video_path`) y luego pasa al menú; si el archivo no existe va directo al menú (nunca se traba; si hay un mp4 en `video/`, avisa cómo convertirlo). **Formato: Ogg Theora `.ogv`** (Godot 4 no lee mp4/webm): **`tools/convertir_video.bat`** (arrastrar el video encima; `.sh` en Mac/Linux) lo deja en 1280×720 máx., 30 fps, Theora q7 + Vorbis estéreo (detalles en `video/README.md`). Al agregar el video, commitear también el `intro.ogv.uid` que genera Godot; el mp4 original lo ignora `video/.gitignore`.

- **Saltar:** cualquier tecla (no repetición), clic o botón de control, salvo los primeros `skip_guard_time` (0,35 s) para no saltarla con una tecla que venía apretada. Mensaje "Presiona cualquier tecla para saltar" abajo (aparece a los 0,6 s, pulsa suave entre 70 y 100 % de opacidad, en una píldora semitransparente para leerse sobre cualquier video). La tecla que salta se consume (no llega al menú).
- **Salida:** fundido a negro + fundido del audio del video (0,5 s); el menú aparece desde negro (`IntroScreen.fade_menu_in`) y la cueca entra con fundido de 1,5 s.
- **Música:** la intro llama `SettingsManager.stop_music()` en `_ready`; `SettingsManager` arranca la cueca **diferida**, así ni un instante suena encima del video. El audio del video va al bus Master (`video_bus`).
- **Proporción:** el video va dentro de un `AspectRatioContainer` cuyo `ratio` se ajusta al tamaño real del video → franjas negras si no es 16:9, sin deformarse.
- **Web:** el navegador no deja sonar audio antes del primer gesto, así que en web primero se muestra "Presiona cualquier tecla para comenzar" (ese gesto desbloquea el audio) y recién ahí parte el video. El `.ogv` entra al export con `export_filter="all_resources"`.

### Sombras y brillos (`VisualFx`, `DropShadow`, `ContactShadow`, shaders/)

Para que terreno, objetos y peligros se despeguen del fondo, sin luces 2D (funciona igual en el renderer
Compatibility de la web). Todo va en capas de **z absolutas** entre el fondo (-100) y el terreno (0), así una
sombra solo oscurece el fondo: `Z_SHADOW` -50 (sombras), `Z_GLOW` -40 (luz de peligros), `Z_HALO` -30 (halo
con forma) y `Z_LIGHT` 10 (la parte de la luz que tiñe al terreno y a los jugadores, `glow_front`). La luz
viene de arriba a la izquierda: `VisualFx.LIGHT_OFFSET` = (5, 7).

- **Terreno** (`TerrainArt`, grupo "Sombra"): por cada pieza un `ColorRect` con `caja_suave.gdshader` (sombra
  corrida + oclusión alrededor). Sin sombra para piezas enteras fuera de la pantalla (WallLeft/WallRight).
- **Objetos** (`DropShadow`, hijo del sprite en campana/palito/push_box/collectible/hook_point/
  pressure_plate y de la cuerda en emboque): copia cada cuadro el dibujo (animación, flip) en un Sprite2D con
  `silueta.gdshader`; para la cuerda, una Line2D con una banda difusa. Hereda transformación, visibilidad y
  modulate (un extremo en la mano oculta la cuerda y su sombra). En los **jugadores** es suave a propósito
  (alfa 0,35, `grow` 0,25): una versión más fuerte (0,6 / 0,6) se sacó por recargada.
- **Personajes destacados:** el `Sprite` del jugador usa `resaltar.gdshader` sin contorno (saturación 1,2,
  contraste 1,12) y el fondo (`background.tscn`) `fondo.gdshader` (desenfoque, contraste 0,6, saturación 0,75,
  viñeta 0,3). Oscurecer el fondo empeoraba: las mangas y jeans (azul oscuro) se perdían.
- **Sombra bajo el objeto** (`ContactShadow`, en player/campana/palito): rayo hacia abajo (terreno + cajas)
  y una mancha ovalada en el primer piso que encuentra, más chica y clara con la altura (`fade_distance`).
  En los **jugadores es permanente** (`min_strength` 0,65, `max_distance` 2000), como en los plataformeros
  clásicos: en el aire marca dónde van a caer. Sin piso debajo (foso) no se dibuja. Va primero entre los hijos
  del cuerpo: encima del terreno y debajo del dibujo, **siempre que el cuerpo tenga z mayor que el terreno**
  (Player/Emboque con `z_index = 1`, como en level_base; se agregó a los niveles viejos main/level_2/level_3/
  test_*).
- **Peligros** (`HazardArt`): brillo = `caja_suave` aditivo con parpadeo/respiración; halo = cada cuadro
  repetido con `silueta.gdshader` (las púas lo usan como sombra). El fuego y la caca no usan halo: sus PNG
  tocan el borde y el halo dejaba manchas ahí.

### Coleccionables y puntaje (`collectible.gd` + `score_manager.gd`)

Opcional por nivel. El **coleccionable** es un `Area2D` (`collision_layer = 0`, `mask = 14` = jugadores 2 + campana 4 + palito 8, `monitorable = false`) que al ser tocado por un `Player` **o un extremo del emboque** (`RopeEnd`; la cuerda no, es solo visual) busca el `ScoreManager` por el **grupo `"score_manager"`**, le suma `points` (export, default 100) y se autodestruye (`queue_free`). El **ScoreManager** (`Node`) guarda `score` y refresca un `Label` (`ScoreLabel`) vía su export `score_label`. Si hay coleccionables en un nivel, **tiene que haber un `ScoreManager`** (si no, el coleccionable hace `push_warning` y no suma). Un guard `_collected` evita sumar dos veces si un jugador y su extremo lo tocan en el mismo tick (`queue_free` es diferido). Un extremo en la mano no tiene colisiones, así que no recoge por sí solo (lo hace el cuerpo del jugador).

### Caja empujable (`push_box.gd`)

Según el concepto, los objetos dinámicos se empujan "por los jugadores o por los extremos de sus cuerdas", por eso la caja es un **`RigidBody2D`** (capa 6): los extremos la golpean y mueven por física real (masa 2 vs campana 1 / palito 0.6), se puede pisar (el jugador viaja con ella), apilar y cae de los bordes. `lock_rotation` (no se vuelca) y `can_sleep = false` (dormida no corre `_integrate_forces` y no se podría empujar).

Un `CharacterBody2D` no empuja cuerpos rígidos por sí solo, así que el empuje es explícito: en `_process_platformer`, si el jugador está en el suelo con input, `_try_push_box` busca una caja justo delante con `test_move` (contacto lateral) → limita su velocidad a `push_speed` y llama `box.push(velocity.x)`; tras `move_and_slide` **restaura esa velocidad** (el deslizamiento la anula al tocar la caja y el empuje daría tirones). La caja, en `_integrate_forces`, **fija** `linear_velocity.x` a la suma de empujes del tick (dos jugadores en contra se anulan) y **compensa el roce** del paso anterior con una fuerza de un paso: así avanza exactamente a la velocidad que informa, que es la que usa quien va parado encima.

En el **aire no se empuja** (`push_box.gd`): si no, seguir apretando contra la pared de enfrente de un pozo la dejaba
pegada. Y **quien empuja no se cae tras la caja** (`Player._guard_push_edge`): al caer la caja por un borde, el jugador se
detiene ahí mientras siga con la misma dirección apretada (soltarla, o saltar, lo deja pasar).

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
    ControlsP1/P2  ControlsPanel a cada lado del tablero (en las franjas azules), centrados en vertical.
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
  siguiente), fila "Idioma" en Ajustes (lista) y en el panel de ajustes de la pausa. Los tres muestran la
  **bandera** del idioma al lado del nombre (`Languages.flag_of(código)` = `assets/ui/banderas/<código>.svg`:
  es = Chile, en = Reino Unido; sin archivo, solo el nombre). `boton_madera.gd` tiene `icon` / `icon_max_width`. Se guarda en
  `user://settings.cfg` (`general/language`); la primera vez se usa el idioma del sistema si existe.
- **Agregar un idioma**: columna nueva en el CSV (la fila `LANGUAGE_NAME` = su nombre en ese idioma) → abrir
  Godot (genera la `.translation`) → sumarla en Proyecto → Configuración → Localización → Traducciones →
  (opcional) imágenes en `assets/ui/<código>/` y su bandera en `assets/ui/banderas/<código>.svg`. Los selectores la listan solos (`Languages.available()`).

### Flujo de menús

Arranque: `ui/intro.tscn` (video; cualquier tecla lo salta) → `main_menu` (aparece desde negro; la intro solo corre al iniciar el juego, volver al menú no la repite).
`main_menu` → (Jugar) → `level_selector` (el MAPA) → (un nivel desbloqueado) → gameplay → (al ganar) → `ui/victory.tscn` → (Continuar) → mapa (anima lo recién desbloqueado) / (Reintentar) → el mismo nivel. Esc en el mapa vuelve al menú.
`main_menu` → (Ajustes) → `settings`. No hay botón Salir: el juego es para web, donde `quit()` no cierra la pestaña (solo congela el juego). Selector y Ajustes tienen botón **Volver** al menú.
Para agregar niveles: una entrada en `LEVELS` de `scripts/level_catalog.gd` (el mapa la dibuja sola).

### Mapa de niveles y progreso (`level_selector` + `LevelCatalog` + `ScoreBoard`)

Como la progresión del concepto: un árbol de niveles que se desbloquean al completar el anterior.
**`LevelCatalog.LEVELS`** es la única lista: `id`, `scene`, `pos` (lugar en el mapa, 1280×720) y `from`
(niveles de los que depende: se desbloquea al completar CUALQUIERA, o al menos `need`). Opcionales: `special`
(nodo dorado y más grande), `rope: false` (sin cuerdas en el mapa) y `hint` (texto mientras está bloqueado).
El número del nivel es su orden en la lista. `WinManager` toma el id y el nombre del catálogo.

Árbol actual (29 niveles): **tronco** 1–4 (lo básico, sin objetos: caminar, largo de cuerda, ganchos, cuenco)
→ desde el 4 se abren **peligros** (púas, caca, brasas, y "La T" = `level_2` del equipo), **cajas** (3 + "Escalones" = `level_4` del equipo) y
**lanzar** (3 + "Buzón": lanzar el extremo por una ranura a una placa). Sub-ramas de mecánicas nuevas: **placas/compuertas** (desde caja 2; la 4.ª, "Relevo", con ganchos: cada uno abre la puerta del columpio del otro), **plataformas móviles**
(desde peligro 2; la 4.ª, "Contratiempo": ascensores a contratiempo sobre el fuego) y **viento** (desde lanzar 2; la 4.ª, "Remonte": la corriente sube el extremo hasta un gancho inalcanzable y se trepa la cuerda). El **final** se abre con 4 de los 6 finales de rama. Cada
rama empieza introduciendo su mecánica en un caso simple y sube la dificultad. El mapa no nombra las
mecánicas (minimalista): se descubren jugando. Los niveles que introducen un control traen un cartel
(`LevelHint`) por jugador con sus teclas: tronco_2 (soltar / tirar cuerda) y lanzar_1 (lanzar).

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
  `Player.add_wind`). **Ráfagas** (`gust_off` > 0): sopla `gust_on` s y para `gust_off` s (`gust_offset` desfasa el ciclo);
  sube y baja en 0,3 s y las rayitas y el sonido paran con ella. Da plataformeo con ritmo: los chorros se toman cuando
  soplan (`gust_on` × `player_max_speed` ≈ cuánto sube una ráfaga: que alcance para un piso, no para dos) y los vientos
  en contra se cruzan en la calma. Se usa en viento_3. Con viento hacia arriba los extremos suben como un **volantín**: hay que soltar cuerda.
  `player_factor = 0` → solo afecta a los extremos. Sonido `wind` en loop (AudioStreamPlayer2D).

### Bot de pruebas (`tests/`)

`tests/play_level.gd` juega un nivel siguiendo un plan y termina con `RESULT WIN|DEATH|TIMEOUT` (+ sopaipillas
que faltaron). Corre headless y mucho más rápido que el tiempo real con `--fixed-fps 120`:

```bash
"$GODOT" --headless --fixed-fps 120 --path . -s tests/play_level.gd -- res://tests/solutions/tronco_1.gd --trace=0.5
GODOT="$GODOT" tests/run_all.sh          # todos los niveles; sale con 1 si alguno no se gana
```

`tests/run_controls.sh` corre los **controles**: una solución con `const CONTROLS := ["12", "1", "2"]` no se debe ganar
con esos jugadores quietos en la meta (`--still`: llegan, pero se saltan `swing` / `jiggle`).

`--start=x1,y1,x2,y2` parte desde esos puntos (para probar solo un tramo).

**Atajos (`tests/monkey.gd`, "mono tramposo"):** juega al azar y reinicia al morir, con la mecánica clave prohibida
(`--no=rope|hook|throw|box|wind`, `--remove=Nodo`), y no debe ganar. `--goal=x1,y1,x2,y2` = que nadie llegue a ese punto y
`--start` = desde dónde: para niveles largos conviene probar por tramos. `tests/run_shortcuts.sh` corre los declarados en
`const SHORTCUTS` de cada solución (~1500 s de juego cada uno, en ~1 min). Que no encuentre un atajo no prueba que no exista.

**Auditoría de peligros:** `--hazards` (qué púas y cacas podrían ser fuego). **Margen:** `--jump=V` juega con otra velocidad de salto
(465 y 475 además de 470): si solo gana con una, está muy justo. El bot mantiene la tecla de salto 0,5 s (salto completo);
`--hold=S` o el paso `["hold_jump", s]` lo cambian, para probar saltos cortos. **Alcance:** `python tests/reach.py NIVEL x0,piso0 x1,piso1`.

Cada `tests/solutions/<nivel>.gd` declara `const SCENE` y `static func plan(ctx)` con los pasos de cada jugador
(`walk_to`, `jump_to`, `leap_to` (frena en el aire para caer justo), `fly_to` (tras soltarse de un gancho), `pump_until`, `rope`, `tap`/`hold`, `sync`, `until`, `pump` (columpio), `pump_end` (balancear el
extremo), `jiggle`, `hang` (dejar el extremo colgando del borde), `swing` (balanceo al ritmo del péndulo)…; lista completa arriba de play_level.gd). `tests/solutions/moves.gd` tiene movimientos
compuestos (correr-saltar-engancharse-columpiarse-lanzarse, lanzar a un ángulo y `path`: un recorrido de saltos escrito como lista). `--var=nombre=valor` permite
barrer parámetros (`ctx.var_f`), `--shots=dir` guarda capturas (sin `--headless`, con Xvfb). **Al cambiar la
física o un nivel, correr `run_all.sh`.** Las soluciones son a la vez documentación de cómo se resuelve cada
nivel.

### Capas y máscaras de colisión

- **Capa 1:** terreno (StaticBody2D del nivel).
- **Capa 2:** jugadores. `mask = 33` (terreno 1 + cajas 32) → chocan con terreno y cajas (no entre sí, no con extremos).
- **Capa 3 (valor 4):** campana. `mask = 41` (terreno 1 + palito 8 + cajas 32).
- **Capa 4 (valor 8):** palito. `mask = 37` (terreno 1 + campana 4 + cajas 32).
- **Capa 5 (valor 16):** puntos de enganche (`HookPoint`, `monitorable`). El `HookSensor` de cada extremo tiene `mask = 16`.
- **Capa 6 (valor 32):** cajas (`PushBox`). `mask = 47` (terreno 1 + jugadores 2 + campana 4 + palito 8 + cajas 32).

En Godot 4 un cuerpo solo **es afectado** por otro si su mask incluye la capa del otro: por eso la caja tiene a los extremos en su mask (para que la empujen) y los extremos a la caja (para chocar con ella).

Sensores (`Area2D`, capa 0): `CavitySensor` de la campana `mask = 8` (solo palito; no detecta su propio cuerpo), `HookSensor` 16, coleccionables 14 (jugadores + extremos), zona de muerte del jugador 2, del emboque 12, placas y viento 46 (jugadores + extremos + cajas).

### Cuerda y extremos (`emboque.gd` + `rope_end.gd`)

J1 = **campana**, J2 = **palito** (asignados en cada nivel vía `end_scene` + `end_kind` de cada `Emboque`).

`emboque.gd` (coordinador) cada `_physics_process`:
1. `_update_length` — `soltar`/`tirar` ajustan `rope_length` (clamp).
2. Si está enganchado: desenganche con `abajo`, o le pasa al jugador el largo actual (`set_swing_length`).
3. Pasa al extremo: `anchor_position`, `anchor_velocity`, `calm_whip`, `rope_length`, `hooked`, `hook_position` (los usa en su `_integrate_forces`, que corre después el mismo frame).
4. `_limit_player` — si el extremo quedó a más de `rope_length` + `limit_stretch` (trabado, o enganchado con el jugador en el suelo), **tira del jugador** hacia el extremo con `_move_sliding`. Se salta cuando el jugador cuelga tenso (el péndulo ya es exacto).
5. `_update_rope_visual`.

`rope_end.gd` en `_integrate_forces`: si `hooked`, fija el extremo al gancho; si no, aplica la **restricción de cuerda por velocidad** (le quita al extremo la velocidad con que se aleja de la mano, RELATIVA a la de ella, + corrige el exceso), sin fijar posición → el motor resuelve colisiones y el extremo **nunca atraviesa geometría**.

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
| `REELING` (recogiendo) | `lanzar` en `NONE` o en `FLYING`, sin gancho ni emboque pegado | La cuerda se acorta a `reel_speed` (1100 px/s) **desde la distancia actual** y la restricción de la cuerda trae el extremo, con colisiones (no se teletransporta). Al llegar a `min_length + grab_tolerance` queda en `HELD`. No arrastra al jugador (sin `_limit_player`) ni engancha. `soltar` lo corta; si el extremo no se acerca en `REEL_STALL_TIME` (0,2 s, trabado tras un muro) se deja de recoger. En ambos casos la cuerda queda del largo actual (sin tirón). Va al final del enum: el bot compara el estado por número. |
| `FLYING` (lanzado) | `lanzar` en `AIMING` | Parte **desde la mano** (su forma cabe dentro del jugador, nunca empieza dentro de un muro), `rope_length = max_length`, **sin gravedad** → viaja exacto por la línea punteada. Termina (vuelve la gravedad) al tensarse la cuerda, al chocar (avance real < la mitad de lo esperado), al engancharse o por tiempo. Se puede enganchar en vuelo (es la idea). |

El extremo **en la mano no tiene colisiones** (`RopeEnd.set_held`: capa y máscara 0 + `freeze` kinematic): no empuja al otro extremo ni a cajas, no activa zonas de muerte del emboque y no engancha. Además `WinManager` y `CloseupManager` **ignoran** un extremo en la mano (`Emboque.is_held()`): embocar es con la cuerda, no metiendo el palito a mano. Enganchado, `lanzar` no hace nada (la cuerda es del gancho: se trepa con `tirar`). Tuning en el Inspector del Emboque, grupo "Lanzar": `throw_speed` (1400), `reel_speed` (1100), `aim_max_angle_deg` (60), `aim_sweep_speed_deg` (60 = 1 s por pasada), `grab_tolerance`, y color/grosor/guion de la mira.

### Victoria y magnetismo (`win_manager.gd`)

Identifica palito y campana por `end_kind`. Cada frame, si la punta del palito está a menos de `magnet_radius` de la boca de la campana, aplica magnetismo de **distancia** (fuerza que atrae la punta hacia la cavidad, y la campana hacia la punta) **y de ángulo** (alinea el eje del palito para que apunte a la cavidad, y gira la boca de la campana hacia la punta). Con la física resolviendo la colisión, el palito **entra por la boca**. La intensidad sigue una **curva** (`cercanía ^ falloff_exponent`, 3 por defecto): casi nada a distancia (a medio radio ≈12 %) y fuerte solo al final. **Trabado:** con el palito ya embocado (dentro del `CavitySensor` o su punta a menos de `lock_radius` = 18 px de la cavidad) el magnetismo pasa a un **resorte amortiguado** muy fuerte entre los dos extremos (`lock_strength`, `lock_damping`, tope `lock_max_accel`; fuerzas iguales y opuestas, así no arrastra al conjunto) + alineación rápida (`lock_angular_gain`): el emboque no se escapa ni tiembla (mediciones en `docs/REGISTRO_TESTS.md`). Con la victoria a los `capture_time` = 0,2 s de embocado, el trabado actúa solo ese instante. **Victoria** = el palito está dentro del `CavitySensor` de la campana (respaldo: muy cerca + bien alineado). Al ganar muestra `WinLabel`, registra el resultado en `ScoreBoard` (puntaje + highscore) y tras `restart_delay` salta a la **pantalla de victoria** (`victory_scene`, default `ui/victory.tscn`). **Va antes que los Emboque en el árbol** para que las fuerzas se integren el mismo frame. Exports para el resultado: `level_id` (clave estable del highscore; si queda vacío se deriva del nombre de archivo de la escena), `level_name` (nombre a mostrar).

### Animación del emboque (`WinManager._celebrate`)

Al ganar (grupo "Celebración" del Inspector del WinManager):
- **Piezas pegadas** (`stick_on_win`): `RopeEnd.attach_to` deja al palito **montado** en la campana, con la
  posición y el **ángulo relativo** exactos del momento de embocar: queda congelado y sin colisiones, y copia
  `campana.global_transform * offset` en cada tick de física y en cada cuadro dibujado. Su cuerda no se pierde:
  la campana aplica en su `_integrate_forces` también la cuerda del palito (ancla y largo que el Emboque le sigue
  pasando), en el punto donde está el palito, así el par cuelga de las dos cuerdas. Un extremo pegado no se
  puede tomar ni enganchar.
- **Subida de tensión** (`tension_scene` del CloseupManager = `fx/tension_fx.tscn`, `TensionFx`): con la misma
  cercanía del zoom (parte con el zoom-in):
  - **Silencio antes del golpe:** NO es paulatino: la música suena normal todo el acercamiento y cae de golpe
    a −60 dB (muda) en `silence_drop_time` (0,06 s) justo antes del click: lo dispara el **WinManager** cuando,
    con el palito ya adentro y corriendo `capture_time`, faltan `silence_lead` (0,2 s REALES) para ganar
    (`CloseupManager.set_impact_silence` → `TensionFx.set_silent`). Los demás efectos bajan 14 dB
    (`sfx_duck_db`), vía `SettingsManager.set_music_duck` / `set_sfx_duck` (no tocan el volumen de Ajustes). Si el
    palito se sale antes de ganar, la música vuelve en 0,3 s. Al embocar los efectos vuelven al instante (el
    click suena pleno en el silencio) y la música espera 0,4 s y vuelve rápido, en 0,3 s (`music_return_time`;
    0 = en un solo cuadro). (Se descartaron: bajar la
    música a medida que se acercan, y cortarla por distancia a 30 px: se cortaba demasiado antes.)
  - **Viñeta** que oscurece los bordes (`vignette_strength` 0,7).
  - **Halo dorado** aditivo (anillo, casi transparente al centro, 40 px) que late en el palito y la campana, más
    rápido al acercarse.

  Al embocar (`release()`, lo llama `end_slowdown`) viñeta y halo se apagan en 0,3 s. En la pausa todo suena
  normal. Se probó también un "riser" (zumbido que subía de tono) y se sacó. Todo se ajusta en esa escena.
- **Fin de la cámara lenta**: `CloseupManager.end_slowdown()` devuelve el time_scale y el tono de la música a 1
  en `slow_release_time` (0,12 s reales) y no vuelven a bajar en ese nivel; el encuadre del closeup se mantiene.
- **Click de cámara**: `CloseupManager.punch()` suma un zoom extra (`punch_zoom` 0,3) que entra en `punch_in_time`
  (0,06 s) y vuelve en `punch_out_time` (0,22 s), en tiempo real (Tween con `set_ignore_time_scale`). Se
  multiplica sobre el zoom del closeup.
- **Partículas doradas** (`burst_scene` = `fx/emboque_burst.tscn`): destello, estallido de estrellitas y
  destellos que siguen a la campana ~1,6 s. **Confetti + chispas** (`confetti_scene` = `fx/win_confetti.tscn`):
  desde las dos esquinas de abajo hacia el centro y arriba, saliendo durante ~1,5 s (confetti: 120 por esquina,
  `explosiveness` 0,45; chispas: 90, vida 1,5 s, `explosiveness` 0), antes de que a los 2,5 s se pase a la
  pantalla de victoria; va en un CanvasLayer justo antes de la `UI` (pasa
  por detrás del cartel y debajo de la pausa). Las dos escenas (`WinFx`) corren a velocidad real aunque el
  closeup tenga la cámara lenta, y se borran solas.

### Bonos de estilo (`WinManager.style_bonuses` + `StyleBonus`)

Al embocar aparece un texto por bono bajo el cartel (solo texto: no dan puntos ni se guardan; está en todos los
niveles, lo instancia el WinManager junto al `WinLabel`). Se ajustan en el grupo "Bonos de estilo" del WinManager:
- **"¡Limpio!"** (`STYLE_CLEAN`): ninguno de los dos extremos tocó terreno, cajas ni ganchos en los últimos
  `clean_time` (2,5 s) antes de embocar (`RopeEnd.untouched_time`; tocarse entre ellos no cuenta).
- **"¡Al vuelo!"** (`STYLE_FLY`): los dos llegaron a `magnet_radius` a `fly_speed` (110 px/s) o más (antes de que
  actúe el magnetismo) y embocaron a los `fly_window` (1,5 s) como máximo.

### Aprendizajes de diseño de niveles (de los playtests)

Leer antes de diseñar o cambiar un nivel.

**Que la mecánica sea necesaria**
1. **Cada nivel tiene una mecánica clave y no se gana sin ella.** Se prueba quitándola (cuerda, gancho, lanzar, caja,
   viento), no jugando la solución ideal. Pasó en peligro_2 (se ganaba sin tocar la cuerda), lanzar_3 (el foso se
   saltaba) y placa_4 (el gancho del medio sobraba).
2. **Los obstáculos se calculan contra el alcance real del jugador** (ver "El salto"): 115 px de alto y 315 de largo a la
   misma altura, con cualquier cuerda. Para EXIGIR un gancho o una caja: foso ≥ 390 px (más si se cae) o pared ≥ 150.
3. **Balancear el extremo reemplaza a acortar la cuerda, pero no a alargarla.** Un obstáculo que pide cuerda corta se
   esquiva con vaivén si hay espacio a los lados; uno que pide cuerda larga no se puede evitar.
4. **La cuerda se vuelve interesante cuando dos obstáculos seguidos piden largos opuestos**, sin espacio entre ellos para
   balancearse (~65 px).

**Que la interacción tenga decisiones**

5. **"Empujar hasta que tope" no es un puzzle.** Un objeto importa si hay que decidir dónde, cuándo o para quién va: es
   escaso, tiene dos usos o hay que pasárselo al compañero.
6. **La cooperación se nota más cuando los lados no son espejo:** cada uno necesita algo del otro antes de la meta.

**La meta**

7. **Lo que mejor funciona** (tronco_3, movil_4): los extremos cuelgan libres, los dos se mueven a la vez y hay que
   encontrar el ritmo.
8. **Despejar el espacio de balanceo:** nada macizo cerca, tampoco hacia afuera (muros bajo las repisas).
9. **Un truco nuevo en la meta tiene que ser el único camino** (si balancearse también emboca, el truco sobra).

**El ritmo**

10. **La meta no puede ser todo el nivel:** antes tiene que haber un trayecto de plataformas que use la misma mecánica.

**La separación**

11. **Nadie debe poder cruzar al lado del otro** antes de la meta (saltando una torre, una caja o un foso, o cayendo por el
    hueco): parados juntos, embocar es trivial. Se prueba con `monkey.gd --goal` apuntando al lado contrario. Muros hasta
    arriba, fosos ≥ 390 y fuego bajo el hueco de la meta.

**Que no estorbe**

12. **Escalón obligatorio ≤ 90 px** (cómodo 70–80; 100 es muy justo). Para exigir una caja: pared de 155–160 y caja grande
    (`PushBox.size` = 84: se sube de un salto).
13. **Nada irrelevante alrededor de la meta** (feedback caja_1): una plataforma o un muro que se puede ignorar, sobra.
14. **Los recorridos no pueden ser triviales:** una fila de saltos iguales o una sola caja "para subir" no alcanza.

**El recorrido** (feedback de las tandas 2 y 3)

15. **Asimétrico por defecto.** Un nivel espejo se siente trivial: cada jugador con su recorrido, sus obstáculos y su altura.
    Espejo solo si la meta lo pide (y ahí, solo la meta).
16. **Pero parejo en cantidad:** los dos tienen que tener un plataformeo de largo y dificultad parecidos (en caja_3, J2 tenía
    mucho más que J1). Se compara contando obstáculos por lado y mirando el tiempo del bot.
17. **Cada nivel es un recorrido de plataformas de verdad** (5 o más obstáculos por jugador, de 2 o más tipos) y la meta es su
    remate. Un nivel "bien" con un recorrido corto sigue quedando trivial.
18. **Cada peligro vale por a quién NO daña.** Púas: el extremo entra y sale (alcanza una placa o una sopaipilla que el jugador
    no puede; se cuelga a través). Caca: el jugador la pisa, pero solo si el extremo no la toca (en la mano, colgando por
    arriba, o enganchado). Fuego: solo lo cruzan las cajas. Usarlos así, no como simples hoyos (ver 21).
19. **Cruzarse:** los jugadores pueden pasar al lado contrario del mapa por pisos distintos mientras los extremos siguen
    separados (pisos a 200 px o más, o un techo entre medio: el imán alcanza 65 px y atraviesa paredes).
20. **Antes de dejar un objeto, preguntarse qué pasa si lo borro.** Si el nivel se gana igual (la placa rosada y la caja de la
    antigua placa_3, la repisa extra de lanzar_4), sobra. Se prueba con `monkey.gd --remove=Nodo`.

**El tipo de peligro y el largo de la cuerda** (feedback del pase de recorridos)

21. **Si al cambiar el peligro por otro el nivel se juega igual, está mal puesto.** Una caca o unas púas que se saltan como un
    fuego no aportan. Se audita con `play_level.gd --hazards`: lista las púas que ningún EXTREMO tocó y las cacas que ningún
    JUGADOR tocó al ganar (el fondo de un foso puede quedar en la lista). Piezas que funcionan:
    - **Erizo** (peligro_1): un gancho rodeado de púas. El extremo entra; el jugador se pincha si recoge la cuerda o pasa por
      encima.
    - **Púas con caca colgando** (peligro_3, lanzar_2, lanzar_4, placa_1, placa_2, movil_2, caja_1): el jugador salta A TRAVÉS de la caca
      y el extremo tiene que ir abajo, arrastrando por las púas: cuerda ≥ 150. Caca hasta 70 px sobre el piso (retraída, el
      extremo sube con el jugador y la toca); púas ALTAS (45 px, escala y 1,5) de ~60 px de ancho y despegue a ≥ 65 px. Con púas
      bajas (24), un saltito corto las pasaba con la cuerda retraída.
    - **Puente de caca** (peligro_3, placa_1, placa_2): tabla flotante tapada de caca, más larga que un salto; antes, una ranura
      de 36 px por donde baja el extremo, que cruza por DEBAJO (cuerda ~125; la cuerda atraviesa la madera).
    - **Puente largo con dos ranuras** (placa_4): el extremo baja por una y sale por la otra (acortando parado sobre ella).
    - **Botón de techo** (viento_4): una placa boca abajo (`rotation` 180°, `latch`) que solo aprieta el extremo volando en una
      corriente: hay que soltar la cuerda justa. Cada botón abre la compuerta del otro.
    - **Gancho bajo el borde** (level_2): se engancha bajando el extremo por el borde de la repisa, sin saltar.
    - **Púas que el extremo arrastra** (movil_4, movil_3): un carro sobre un piso de púas; la sopaipilla está entre ellas.
    - **Cortina baja** (level_4, placa_2, lanzar_3, movil_3, movil_4, viento_1): caca colgando hasta ~50 px del piso: se cruza caminando, con el extremo arrastrando;
      saltar o llegar con el extremo en el aire mata.
    - **Extremo en la mano** (lanzar_1, lanzar_2, lanzar_4; bajando un pozo: lanzar_3, final): caca en un pasillo de techo bajo o
      tapando islas enteras.
    - **Nicho de púas** (lanzar_4) y **botón entre púas** (placa_1): lo alcanza solo el extremo.
    - **Botón al fondo** (placa_3 entre púas, movil_1 en un pedestal en el fuego): el extremo baja con la cuerda larga desde el
      BORDE de una isla (apoyado en ella no cae) hasta una placa `latch` que abre una compuerta del mismo jugador. Placa normal
      (~60 px) con púas bajas encima (escala y 0,5) para que el jugador no se pare en ella: en una ranura de 36 px el extremo,
      que baja balanceándose, cae al lado. En movil_1, si no recoge la cuerda antes de subir a la plataforma, el extremo se quema.
    - **Escalones sobre el pasillo** (placa_3, J1): con el extremo en el pasillo de abajo, subir un escalón de 140 pide soltar
      cuerda (si no, el extremo queda contra el techo del pasillo y amarra al jugador); antes de bajar, que el extremo quede
      pasado de la caca.
    - El **fuego** queda para lo que exige cuidar a los dos (cuerda corta, saltos justos, la meta).
22. **Pensar con qué largo de cuerda llega el jugador.** Casi siempre llega con la cuerda retraída (es lo más cómodo): un tramo
    que se resuelve retraído es redundante (pasó en movil_2: plataformas sobre caca). Para que haya una decisión, el tramo
    tiene que pedir cuerda LARGA, o alternar larga y corta seguido (peligro_3: brasa corta → púas con caca larga → puente 125).
    Que algún nivel se gane sin tocar la cuerda está bien, pero a propósito.
23. **Un peligro tiene que estar en el camino:** las púas al lado de la caja de level_4 solo mataban a quien se tirara a ellas.
24. **Los dos lados usan el peligro del nivel** (en lanzar_2, J2 no tocaba la caca).
25. **Más vertical:** con el salto más bajo caben 6–8 pisos por pantalla. Subir y bajar por caminos distintos (placa_1) da más
    recorrido que una escalera sola.
26. **Nada que el jugador tenga que saber de memoria:** el salto no depende de cómo esté el emboque (antes, apoyado, pesaba
    menos y se saltaba hasta 100 px más). Si una regla así reaparece, sacarla o enseñarla.
27. **Cada relevo tiene que ser el único camino:** si al borrar el vehículo que mueve el compañero se llega igual (cayendo, por
    ejemplo), la placa sobra. Pasó en movil_3 (J2 se dejaba caer) y con el gancho de level_2 (un salto que cae 300 px avanza
    ~450: la cortina tiene que tapar toda esa caída). Se prueba con `monkey.gd --remove=...`.
28. **Las metas aprobadas no se tocan al rehacer un recorrido:** se conservan las medidas exactas y se agrega el trayecto antes
    (otra sala, un pozo, la parte alta), con una pared entre ambos.

### El salto (medidas para diseñar)

`player.gd`: `jump_velocity` -470, gravedad 980, 320 px/s; `swing_jump_velocity` -410 (desde la cuerda). **Siempre igual, con
cualquier cuerda** (antes -680 y de 139 a 239 px según la cuerda): 115 px de alto, 0,98 s, 315 px de largo a la misma altura; hasta
un piso 75 px más arriba, ~240; con techo a 146 px, ~185. A los 0,2 s lleva 75 px de alto y 64 de largo (para pasar sobre unas púas
de 24 px hay que despegar con el centro a ≥ 45 px de su borde).

**Salto variable:** al soltar la tecla mientras sube, el salto termina (`jump_cut_factor` 0,25 de la velocidad hacia arriba; señal
`jump_cut`, con la que el Emboque frena también al extremo). Esas medidas son con la tecla mantenida (~0,5 s); tecla 0,05 s → 25 px de
alto y 125 de largo; 0,1 → 44 / 163; 0,2 → 76 / 216; 0,3 → 98 / 256. No vale para el salto desde la cuerda ni dentro de un viento.

Es igual porque la cuerda ya no frena al jugador por pesar: `_limit_player` deja que se estire `limit_stretch` (10 px) antes de
tirar de él, y `RopeEnd._apply_rope` iguala la velocidad del extremo a la de la mano a lo largo de la cuerda. Si el extremo está
trabado (bajo una repisa), igual lo detiene: casi no puede saltar hasta sacarlo por un borde. `_calm_whip` evita que el extremo
salga como látigo al correr o saltar (de lado, a lo más 380 px/s en el sentido del jugador; no actúa quieto, lanzado ni recogiendo).

**El extremo va como una cola:** al saltar corriendo, cuánto sube sobre el piso según la cuerda: 60 → 106 px (sigue al jugador),
110 → 78, 170 → 57, 240 → 38. `python tests/reach.py` calcula qué repisas se alcanzan y el camino (margen < 20 px = muy justo).

### Escala del nivel (opcional: más plataformeo y objetos)

Cuando un nivel necesita **más espacio para plataformas y objetos**, se hereda de `levels/level_base_large.tscn` en vez
de `level_base.tscn`: la **cámara se aleja** (zoom 0,8) y el mundo mide **1600×900** (+56 % de área). No cambia nada de
la física: personajes, saltos, cuerdas y magnetismo miden lo mismo en px del mundo, solo se ven más chicos (el jugador,
51 px en vez de 64). El closeup compensa (`max_zoom` 2,5), así el emboque se ve igual de grande.
- **Solo en los niveles que lo necesitan**; los que introducen algo simple quedan en 1280×720. Son los dos únicos
  tamaños: con 0,7 el palito casi no se ve.
- Hoy: todos los del mapa menos tronco_1..3.
- Coordenadas: centro (800, 450); espejo = `1600 - x`; `FallZone` en (800, 1010) con escala (1.25, 1).
- El código no debe asumir 1280×720: usar `LevelFlow.level_size(get_tree())` (mundo) o el viewport (UI).

### Zonas de emboque (cómo diseñar la meta)

Feedback de jugadores: embocar en un cuenco en V (o un pozo angosto) no satisface, porque los extremos se juntan solos.
Las metas se están rehaciendo para que los extremos **cuelguen libres** y haya que acercarlos. Reglas:
- **S** = separación mínima entre las manos (hueco entre repisas − 40, o ancho de la columna + 40: la mano llega 20 px
  más allá del borde). 40: emboca solo. 50–70: zona muerta, falla. **80–90:** basta con uno. **~100: los dos a la vez.**
  120–150 errático. Con S chico, el envión de la llegada puede embocar sin balancearse.
- Los jugadores **separados por un muro o columna** (si no, se paran juntos y es trivial). El muro que cuelga termina
  ~30 px sobre el borde de la repisa: no se cruza saltando y los extremos pasan por abajo.
- **Repisas delgadas** (24 px, el cuerpo de la torre ≥ 150 px hacia afuera, o sin cuerpo): una torre maciza no deja
  balancear. Con el cuerpo a 100 px, movil_1 y peligro_1 fallaban casi siempre; flotando, ganan siempre.
- Nada debajo que junte los extremos: vacío o peligro.

| Tipo | Nivel | Cómo |
|---|---|---|
| Balanceo | tronco_3 | dos islas, hueco 130, cortina al medio |
| El alambre | peligro_2 | extremos por dentro de un pasillo: largo para el diente, corto para el fuego que está pegado a él, largo para los escalones; techo bajo para no saltar las llamas (antes caca: el jugador nunca baja al pasillo, así que es fuego) |
| Voladizo | caja_2 | hueco 215: asomar la caja por el borde (10–44 px; si se pasa, cae y reaparece). Antes, "La mudanza": tres cajas (una chica y dos grandes), J1 le bota dos a J2 (tapa un foso + escalón) y se guarda una |
| Trapecio | placa_4 | UN gancho alto al medio, sobre fuego, con un muro corto encima: los dos saltan a él y se embocan en el aire. Ganchos a escala 2 e islas a 190 px del gancho (antes 238): se engancha saltando desde la mitad de la isla, no solo del borde |
| Cortina móvil | movil_3 | `MovingPlatform` vertical de 16 px que sube y baja entre los extremos; repisas flotantes (sin muro debajo) |
| Contratiempo | movil_4 | una plataforma por jugador, al revés |
| Tiro al blanco | lanzar_3 | repisas de 260 px (dos lanzamientos a ganchos por lado); islas a distinta altura: J1 cuelga la campana (cuerda 80–110), J2 le lanza el palito |
| Volantín | viento_1 | (antes, dos saltos con chorros) columna de 74 px (antes 84: costaba; con 60–66 emboca uno solo, sin balancearse) + viento ancho (360, 1600, `player_factor` 0): péndulos al revés |
| Correo aéreo | viento_3 | (antes, chorros y vientos en contra en ráfagas) el viento sube la campana de J1; J2 baja el palito desde arriba (hay que hallar los largos) |
| Desnivel | tronco_2, caja_3 | manos a alturas distintas: igualar los extremos con el largo de la cuerda |
| Ventana | tronco_4 | muro de 60 con un agujero de 90 px; ranura de 36 entre repisa y muro (pasa el extremo, no el jugador) |
| Fácil sobre púas | peligro_1 | S ≈ 92, repisas flotantes |
| Al rojo | peligro_3 | S ≈ 100 con fuego a ~175 px de la mano |
| Tiro con poco ángulo | lanzar_1 | J1 122 px más arriba con la campana colgando (65–100); J2 lanza a 8–16° |
| Puerta en la meta | placa_1 | compuerta entre los extremos, abierta solo con los dos en la placa de su borde |
| Hueco con cortina | level_4, movil_1, caja_1, placa_2 | S ≈ 92, sin nada macizo cerca |
| Mismo gancho a distancia | lanzar_2 | un gancho en un agujero de 56 px del muro; cada uno le lanza su extremo (22–35°) |
| Por la ranura | lanzar_4 | muro con ranura de 60 px; la campana cuelga detrás (cuerda 80–95) y J2 lanza a 10–16° |
| Titiritero | placa_3 | S ≈ 90: J1 llega caminando arriba con la campana ya colgando por el hueco; J2 sube al otro lado |
| Al pasar | movil_2 | J2 en una plataforma que va y viene (más cerca: 116 px entre bordes); J1 se balancea a tiempo |
| Bandera | viento_2 | viento de costado (1700) estira la cuerda de J1 sobre 260 px hasta el palito de J2; tope en el borde, porque acortar la cuerda con viento arrastra |
| Ráfagas hacia adentro | viento_4 | S ≈ 196, dos vientos de 260 en ráfagas de 2,2/2,2 s (más cortas o fuertes: se gana sin hacer nada) |
| Trapecio con viento | final | gancho en un agujero de 60 px del muro, que solo se alcanza saltando dentro de la ráfaga |

### Recorridos (qué hace cada lado)

Metas aprobadas con gente. Los recorridos sin * también (algunos tras rehacerse dos o tres veces por "el tipo de peligro da lo
mismo", "muy fácil" o "trivial"). Los marcados con * son los últimos rehechos y **falta probarlos con gente**:

| Nivel | J1 | J2 |
|---|---|---|
| peligro_1 | baja por un pozo, cruza colgado de un ERIZO y sube | sube en zigzag y cruza con su erizo hasta la repisa |
| peligro_3 | islas sobre fuego (corta) y salto a través de una caca colgante (larga) | brasa (corta) → púas con caca colgando (larga) → puente de caca (extremo por debajo) |
| caja_1 * | púas con caca colgando (larga); ESCALERA DE CAJAS: la grande bajo la repisa contra el muro de 215 y después bota la chica encima (al revés no hay arreglo); 5 islas | pasillo de techo bajo con zanja de fuego: la caja grande la tapa y la chica pasa encima hasta el muro; 5 islas con brasa y púas |
| caja_2 | bota dos cajas y se guarda una | tapa el foso, escalón y 6 pisos |
| caja_3 | 6 islas hasta sus cajas, bota la chica, sube con la grande | piedra de paso y escalera de 8 pisos sobre púas |
| level_4 | piso de arriba: caja, islas con brasa | piso de abajo: caja, islas con púas, túnel con cortina de caca bajo la meta, zigzag |
| lanzar_1 | sube islas sobre púas y cruza un pasillo de caca con el extremo EN LA MANO | sube 5 islas (dos tapadas de caca) con el extremo en la mano |
| lanzar_2 | púas con caca colgando (larga) y brasa (corta), columpio | repisas, una tapada de caca y de techo bajo (en la mano), columpio |
| lanzar_4 | púas con caca colgando, pasillo de caca (en la mano), brasa; lanza por la ranura → puerta de J2 | repisas; lanza por un nicho de púas → puerta de J1 |
| placa_1 | sube 8 pisos hasta su botón (al final, caca colgante) y baja por otro pozo | sube 6 pisos, puente de caca, salta el foso; su botón, entre púas, lo aprieta el extremo |
| placa_2 | sube 7 pisos, púas con caca colgando; foso del peso muerto | puente de caca, púas, cortina baja; foso del peso muerto |
| placa_3 * | arriba, dos escalones (soltar cuerda para subir), lleva la campana por el pasillo del medio (caca, placas, compuerta) | abajo, púas y compuertas que le abre la campana; su placa abre la del pasillo; sube en zigzag y a media subida baja el extremo a un botón entre púas que abre su compuerta |
| movil_1 * | ascensor que termina en púas: bajarse a tiempo; segundo ascensor hasta media altura, isla con púas y salto a la repisa | baja dos islas; desde el borde de la segunda baja el extremo a un botón en el fuego (larga) que abre su compuerta; recoge la cuerda y cruza en la plataforma sobre el fuego y la caca (corta); ascensor con púas a los lados |
| movil_2 | plataforma, ascensor, y otra plataforma desde la que hay que saltar púas con caca colgando (larga) | púas con caca colgando (larga) y plataforma que pasa por dos llamas: saltarlas a tiempo (corta) |
| tronco_2 * | sube 5 islas (las primeras sobre suelo: caer no mata) | baja 3 islas anchas a un piso seguro, pasa bajo la cortina y sube 2 |
| tronco_4 | sube 5 islas en zigzag, gancho | cae por un pozo, pasa bajo el muro, sube 5, gancho |
| level_2 | zigzag con púas y caca colgando (larga), gancho bajo el borde | zigzag de 7, puente de caca, gancho bajo la cortina |
| lanzar_3 | baja un pozo con caca (en la mano), dos lanzamientos | cortina baja y púas con caca colgando (larga), dos lanzamientos |
| placa_4 * | púas con caca colgando (larga), islas sobre brasas (corta), gancho (más grande) | puente largo de caca con dos ranuras, gancho (más grande) |
| movil_3 | placa (J2 cruza); sube con la de J2; islas y cortina baja; placa | carro sobre púas (techo bajo), placa, púas con caca (larga), escalones |
| movil_4 | carro sobre púas, cortina baja, púas con caca colgando (larga), ascensores | ascensor con púas en las paredes, púas con caca (larga), brasa (corta), ascensores |
| viento_1 | chorro con púas en el techo, púas con caca (larga), chorro en ráfagas | brasa contra el viento, cortina baja, púas con caca (larga), chorro |
| viento_4 | botón de techo (abre a J2), dos ganchos con viento | pozo con botón de techo (abre a J1), dos ganchos con viento |
| final | púas con caca (larga), lanzar, columpio | pozo de caca (en la mano), brasa, chorro en ráfagas |

Se **cruzan** (uno pasa por encima del otro) en level_4 y placa_3. tronco_1 volvió a su versión original (caminar hacia el
muro): un recorrido le quitaba lo de nivel introductorio. Sin tocar: tronco_3 y viento_2 ("excelente"), peligro_2 (solo la
caca pasó a fuego), caja_2, caja_3 y viento_3. La meta de lanzar_1 es menos intuitiva que el resto.

### Pantalla de victoria y highscore (`victory.gd` + `score_board.gd`)

Al ganar, `WinManager` llama `ScoreBoard.report_win(level_id, level_name, score, collected, total)` — el puntaje y las sopaipillas salen del `ScoreManager` del nivel (0 si no tiene) — y luego `change_scene_to_file(victory_scene)`. **`ScoreBoard`** es un autoload que (a) guarda los datos de la última victoria (`last_level_id`, `last_level_name`, `last_score`, `last_is_record`, `last_collected`, `last_total`) para que `victory.gd` los muestre sin tener que pasar parámetros entre escenas, y (b) persiste el **highscore por nivel** en `user://scores.cfg` (sección `highscores`, clave = `level_id`), actualizándolo solo si el puntaje lo supera. `victory.tscn` (estilo del menú): título, número y nombre del nivel, puntaje, sopaipillas juntadas, récord (muestra "¡Nuevo récord!" si se batió) y botones **Reintentar** (solo si el nivel está en el catálogo) y **Continuar** (vuelve al mapa; Esc hace lo mismo).

## Anatomía de un nivel (checklist antes de diseñar)

**Lo más simple (y lo que usan los 27 niveles nuevos y `level_4`):** *New Inherited Scene* desde
`scenes/levels/level_base.tscn`, que ya trae todo lo obligatorio de abajo en el orden correcto; el nivel solo
agrega bloques (`block.tscn` con su `size`), objetos y la posición de los jugadores, y una entrada en
`LevelCatalog`. La lista de abajo explica qué trae la base (y sirve para niveles hechos a mano).

Un nivel es una escena `.tscn` con raíz `Node2D`. Antes de ponerse a diseñar el
trazado, todo nivel jugable necesita **estos nodos** (tomar `main.tscn` o
`level_2.tscn` como plantilla y copiar/ajustar). El **orden en el árbol importa**
(ver "Lecciones aprendidas"): `WinManager` y `CloseupManager` van **antes** que los
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
8. **`UI`** (`CanvasLayer`, sin script) con `WinLabel` (`Label`, oculto; lo muestra el WinManager al ganar) y, si hay puntaje, `ScoreHud` (instancia de `ui/hud_score.tscn`).

**Opcional (según el diseño del nivel):**

- **`HookPoint`** (instancia de `hook_point.tscn`): puntos de enganche del entorno para rapel. Poner los que pida el puzzle.
- **Zonas de muerte**: `player_death_zone` / `emboque_death_zone` / `both_death_zone`, escaladas/posicionadas. Reinician el nivel al contacto.
- **Coleccionables + puntaje**: si se ponen `collectible.tscn`, agregar **también** un `ScoreManager` (con `score_label → ScoreHud`) y un `ScoreHud` (`ui/hud_score.tscn`) en la UI. Van juntos o no van.
- **Cajas** (`push_box.tscn`): instanciar y ubicar apoyada en el piso (centro = techo del piso − 32). No necesita nada más. Para ajustar el peso ante los extremos, cambiar `mass`; para la rapidez de empuje, `push_speed`.
- **`LevelRules`** (nodo con `level_rules.gd`): mecánicas opcionales del nivel. Hoy solo `throw_enabled` (tomar y lanzar el emboque). Un nivel sin este nodo no tiene ninguna.

**Ojo con el spawn:** el extremo nace `rope_length` (170 px) **debajo de la mano**. Si un jugador arranca parado en el suelo, el extremo nacería dentro del suelo: arrancar a los jugadores **en el aire** o sobre una plataforma alta (como hacen todos los niveles; `test_throw` los pone en y=460 y caen).

**Verificación al terminar un nivel** (lo que más se olvida):
- [ ] `Background` (primer hijo) y `TerrainArt` instanciados.
- [ ] `WallLeft` / `WallRight` fuera de cámara.
- [ ] `PauseMenu` instanciado, al final del árbol.
- [ ] `WinManager` con `level_id` único y `level_name`; antes de los `Emboque`, como `CloseupManager`.
- [ ] Coleccionables ⇒ `ScoreManager` (con `score_label → ../UI/ScoreHud`) + `ScoreHud` (`ui/hud_score.tscn`) en la `UI`.
- [ ] `Player2` sin `modulate`.
- [ ] Entrada en `LevelCatalog.LEVELS` (posición en el mapa y de qué nivel depende).
- [ ] Una solución en `tests/solutions/<nivel>.gd` que el bot gane (`tests/run_all.sh`).

**Antes de diseñar el trazado conviene tener decidido:** dónde arrancan los dos jugadores, por dónde va el muro/separación que obliga a cooperar, dónde se juntan los emboques (el punto de "embocar"), qué HookPoints hacen falta para llegar, y dónde están los peligros (zonas de muerte) y recompensas (coleccionables). Recordar que la cámara es **fija 1280×720**: todo el nivel cabe en una pantalla.

## Lecciones aprendidas

- **Nunca corregir la restricción con `global_position = ...` (teletransporte):** ignora colisiones y el extremo atraviesa paredes. Usar siempre movimientos con barrido de colisión.
- **`move_and_collide` se detiene en el primer contacto y NO desliza.** Si el vector de corrección tiene componente contra una superficie (p. ej. hacia el piso), aborta *todo* el movimiento, incluida la parte útil. Por eso existe `_move_sliding()`, que proyecta el resto sobre la normal y continúa. Fue la causa de que la cuerda no limitara al jugador.
- **Medir el progreso de la restricción por reducción real de distancia**, no por cuánto se movió el extremo: si resbala tangencialmente por un muro, esa distancia recorrida no acorta la cuerda.
- **Orden en el árbol importa:** `WinManager` antes que los `Emboque`, y los `Emboque` después de los `Player` (para que las correcciones se apliquen el mismo frame).
- **UIDs:** no inventar `uid://...` a mano (Godot los rechaza como inválidos). Dejar que el editor los genere; en referencias `ext_resource` basta el `path`.
- **Inferencia de tipos:** acceder a propiedades de un nodo tipado genéricamente (`Node2D`) devuelve Variant y rompe `:=`. Tipar con el `class_name` real (p. ej. `var e: Emboque`).
- **Tunneling entre cuerpos delgados y rápidos:** un extremo veloz puede atravesar al otro. Protección actual: `continuous_cd = 2` (CCD cast-shape) + **física a 120 Hz**. **El tope de velocidad (`max_speed`) se QUITÓ** por decisión de diseño (el closeup ya frena el juego al acercarse). Si reaparece tunneling a velocidades altas, reconsiderar (subir ticks, engrosar paredes, o reintroducir un tope alto). Nota: `Engine.time_scale` NO reduce el avance por *tick* de física (solo hay menos ticks por segundo real), así que el slowdown no elimina el tunneling por sí solo.
- **Tamaños de las colisiones** (el arte se escaló para calzar con ellas; si cambia una colisión, reajustar la escala de su sprite): jugador 40×64; palito 22×6; campana ~18×24 (paredes 6px, hoyo ~12px). Las partes son ~1/3 del jugador. Magnetismo: `magnet_radius=65`, `linear_accel=750`, `angular_gain=2.1` (antes 70/900/2,5: se suavizó), `falloff_exponent=3`; trabado `lock_radius=18`, `lock_strength=400`, `lock_damping=30`, `lock_max_accel=6000`, `lock_angular_gain=15`. Todo es tuneable en el Inspector.
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
- **Diseño: un gancho con el jugador parado arriba lo arrastra** — enganchado en el suelo, al acortar la cuerda `_limit_player` lo lleva hacia el punto sobre el gancho. Si hay un peligro entre el jugador y ese punto (las púas del Nivel 2), el jugador muere al tirar. Dejar el gancho a un lado del peligro (pasaba en la primera versión de level_2).
- **Una tecla que hace una acción puntual no debe seguir con su acción continua mientras se mantiene:** `soltar` deja el extremo *y* alarga la cuerda; sin `_release_used`, al dejarlo la cuerda se alargaba unos px y había que tirar dos veces para volver a tomarlo.
- **Al cargar una escena, los controles dentro de contenedores están un cuadro en (0,0) antes del layout:** Godot calcula el hover con esos rects y un botón puede quedar "con el mouse encima" sin estarlo (pasó con el botón Ajustes del menú al venir de la intro, sobre todo en web, donde el mouse no se ha movido). `boton_madera.gd` llama `get_viewport().update_mouse_cursor_state()` tras el primer cuadro para re-sincronizar el hover.
- **El extremo que nace (o queda) DEBAJO de la plataforma donde está el jugador lo amarra:** la cuerda atraviesa
  las plataformas pero el extremo no; al saltar, el extremo choca con la cara de abajo y `_limit_player` frena al
  jugador (saltos de ~85 px). Por eso los jugadores de los niveles nuevos aparecen **en el aire, arriba de donde
  aterrizan** (el extremo cae encima de la plataforma). Pasaba en `level_3`/`level_4` del equipo (`level_4` ya se corrigió y está en el mapa).
- **La cuerda frenaba el salto** (hasta 100 px de diferencia según el largo): mover al jugador para respetar la cuerda le quita
  altura en cada tick. Solución: primero se mueve el extremo (ver "El salto"). Al probarlo, sumarle velocidad de corrección al
  extremo lo lanzaba como látigo: hay que FIJAR su velocidad relativa a la mano, no acumularla.
- **En movimiento el extremo va detrás y a la altura del jugador** (al correr y saltar no se hunde): un peligro
  "abajo" castiga la cuerda larga cuando el jugador está **quieto** (cuelga derecho) o al soltarse de un gancho.
- **Los extremos ruedan y resbalan** (roce 0,05; la campana es redonda): no se quedan quietos en una placa
  plana (usar un rebaje) ni en una plataforma que se mueve. Al bajarse de un ascensor, el extremo que quedó
  arriba se va con él y tira al jugador.
- **Un ascensor que baja hasta el borde de una repisa puede atrapar el extremo debajo** (si el extremo quedó
  colgando en el hueco del ascensor): esperar un paso atrás del borde. Sin hueco entre la repisa y el ascensor.
- **Bajar de un ascensor deja el extremo en el hueco del lado de la torre:** pegar el ascensor a la torre y dejar el hueco
  (19 px) del lado de la partida (movil_1).
- **En una corriente vertical el extremo sube derecho sobre la mano** (no hacia el gancho): un gancho que se
  alcanza con viento va justo encima de donde se para el jugador, y la corriente con margen hacia afuera (si el
  extremo sale por el borde, cae y se va lejos).
- **Las placas las pisan también los extremos**: el extremo que cuelga detrás de un jugador puede activar una
  placa sin querer (pasó en movil_3); dejar espacio alrededor de las placas.
- **Un extremo apoyado en la repisa no cae solo por el borde:** con la cuerda al mínimo (60) y la mano 50 px sobre el
  piso, le sobran ~33 px y se queda arriba. Hay que pararse en el borde y **saltar en el lugar** (paso `hang` del bot).
- **Para exigir una caja, la pared mide 155–160** (el salto da 115; con la caja de 84, ~200).
- **Un extremo que cuelga del costado de un ascensor se traba bajo la repisa de arriba:** poner un muro bajo la repisa, al
  lado del ascensor (final).
- **Tirar rápido de una cuerda cuyo extremo está trabado arrastra al jugador** (placa_2: lo sacaba por la compuerta); la
  compuerta lenta (`speed` 90) da tiempo a recoger de a poco.
- **Una placa en un rebaje de 60 px también la pisa el jugador;** en uno de 36, solo el extremo (placa con `scale.x` 0,55).
- **Una caja pasa derecho sobre un foso casi de su ancho** (66 px): para que caiga, ~84.
- **El fuego separa a los jugadores sin frenar las cajas** (las zonas de muerte no las tocan): un pozo con fuego en las
  paredes deja pasar solo cajas.
- **Islas en zigzag:** dos columnas separadas ≥ 60 px, 70–78 px entre una isla y la siguiente. Entre dos de la misma columna
  quedan ~145 (120 libres): el salto pega con la cabeza si se despega bajo la de arriba, así que la de abajo tiene que asomar
  hacia el hueco (o la de arriba ir corrida). Comprobar con `tests/reach.py`. Púas en el borde de llegada suben el escalón 24 px.
- **Enganche a un gancho saltando:** según el largo, el extremo pasa a distinta altura (ver "El salto"); un gancho 30–70 px sobre
  el piso y a 155–180 px del borde engancha con cuerda 100–160 y deja al jugador colgando de lado; a la altura del piso o más
  abajo, con 170. Si la plataforma es corta el extremo cuelga por el otro borde y queda debajo: pegarla a una pared.
- **Un peligro no puede tocar el sitio donde aparece el jugador ni el extremo** (peligro_1 moría al cargar; y la campana nace con
  ~28 px de ancho: a menos de eso de un muro, sale disparada).
- **Al aterrizar, el extremo sigue de largo ~60 px** (balanceo): dejar ≥ 80 px entre el aterrizaje y la caca o brasa siguiente,
  y ≥ 80 px de suelo antes de cada peligro para tomar impulso.
- **Pasillos de techo bajo** (130–146 px libres): el salto dura menos y cubre ~185 px; para que haya que pasar CAMINANDO (caca con el
  extremo en la mano), 90–110 px libres.
- **El extremo nace `rope_length` bajo la mano y no puede nacer dentro de un bloque** (el jugador salió disparado a 1e14, placa_3)
  ni bajo el piso de partida: con piso delgado, `rope_length` = 80 en los dos Emboque (`l.rope()`), o partir parado sobre el piso.
- **Un ascensor termina 1 px MÁS ARRIBA que la repisa y parte 2 px más abajo que la de salida:** con 2 px de escalón en
  contra, el jugador se queda pegado.
- **Un extremo apoyado donde baja un ascensor queda debajo de él:** esperarlo ~80 px atrás.
- **Al aparecer, la mano está 20 px hacia el centro de la pantalla:** con una pared a menos de ~35 px de ese lado, el extremo nace
  dentro de ella y queda al otro lado (tronco_4).
- **El extremo largo que cuelga por el borde de una isla se mete debajo y amarra al jugador:** antes de un salto "largo", que el
  extremo quede arriba (o que debajo no quepa).
- **Un extremo rueda hasta la placa aunque el jugador espere al lado:** un borde de 16 px entre los dos (movil_3).
- **Una plataforma horizontal entre dos repisas:** 2 px bajo la de salida y 1 px sobre la de llegada; quien espera en la de
  llegada no puede pisarla o se lo lleva (dejarle ≥ 45 px).
- **El péndulo al revés (extremo en una corriente) oscila ±60 px:** la corriente tiene que ser más ancha que eso (si sale, cae) y
  nada de caca al lado.
- **Un gancho en el que se entra corriendo necesita ~170 px de repisa:** con menos, el extremo aún viene colgando del otro lado y
  pasa por arriba; subir el gancho (tronco_4) o engancharlo bajando la cuerda (level_2).
- **Saltar bajo una repisa a < 180 px del piso** da un cabezazo: el salto se corta y el extremo sale disparado hacia arriba.
- **Una caja que entra a una zanja empujada por otra caja se traba** contra la pared de enfrente (la de atrás la aprieta y el
  roce la sostiene): la que tapa la zanja se empuja SOLA. Y la zanja tiene que ser ~30 px más ancha que la caja (100 en 130), o
  pasa derecho y queda montada en el borde.
- **Al caer de la punta interior de la repisa de la meta, un jugador se desvía ~350 px** antes de tocar el piso: cualquier
  superficie del otro lado a ese alcance le deja cruzar (pasaba en la caja_1 vieja). Muros guardia bajo los bordes de afuera
  del hueco (caja_1: `GuardL` / `GuardR`, de 480 hacia abajo).
- **Una isla sobre el camino de un salto corta el salto** aunque no esté justo encima del despegue: revisar el arco completo
  (caja_1: la isla de arriba frenaba el salto entre las dos de abajo).
- **Crear un nivel (en tests) dentro del paso de física deja el extremo en el origen** y arrastra al jugador: esperar un
  `process_frame`.
- **Dos extremos en el mismo `HookPoint` se embocan** (es el trapecio de placa_4). No poner un gancho al alcance de los
  dos si no es a propósito.
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
- **El UV de un sprite llega recortado (clamp) a 0..1 al `fragment()`** (Sprite2D/AnimatedSprite2D dibujan con
  `clip_uv`): un shader que agranda el cuadro en `vertex()` para dibujar afuera (sombra, halo) tiene que pasar su
  UV por un `varying` propio, o fuera del dibujo repite el borde (rayas).
- **En el `fragment()` de un shader de canvas, `COLOR` ya viene multiplicado por la textura** (en el UV
  recortado): multiplicar por `COLOR` como si fuera el modulate aplica la textura dos veces (oscurece) y una
  sombra fuera del dibujo queda recortada a su forma. El modulate se toma en `vertex()` (`varying v_modulate =
  COLOR`).
- **Godot no tiene ajuste HSV por píxel para texturas**: `modulate` solo multiplica RGB (tiñe/oscurece, no
  satura ni gira el tono); `Image.adjust_bcs()` es en CPU. Para eso, `resaltar.gdshader`.
- **No pasar `TEXTURE` como argumento a una función propia de un shader de canvas**: falla con el error
  `custom_samplers.has(...)` y dibuja mal. Usar una macro (`#define`), como `silueta.gdshader`.
- Godot re-guarda escenas/`project.godot` al abrirlos (puede cambiar `uid`/`load_steps` u omitir valores por default); es esperado.
- **Tras reimportar, muchos `.import` aparecen "modificados" en `git status` sin cambios reales** (`git diff` vacío): Godot los escribe con fin de línea LF y el repo usa `core.autocrlf`. Descartarlos con `git status --porcelain | grep '^ M .*\.import$' | cut -c4- | xargs git checkout --` (ojo: `git diff --name-only` no los lista porque el diff está vacío). Los `.import` de archivos nuevos o movidos sí hay que commitearlos.
- **Reverb y otros efectos de audio, horneados en el WAV, no como efectos de bus:** en la web el audio se
  reproduce por "samples" y los efectos de bus pueden no aplicarse (además de que los buses creados en runtime
  dejaban todo mudo).
- **Los tiempos de los planes del bot (`wait`, `hold`, `pump`, timeouts de `until`) son tiempo REAL**, como los de
  una persona: si los extremos se cruzan a mitad de camino, la cámara lenta del closeup los acorta en tiempo de
  juego. Al hacer la cámara lenta más fuerte (0,35 → 0,25) fallaron `movil_4` (la espera antes de bajar el extremo
  por la ranura ya no alcanzaba para que se asentara; se alargó) y `final` (otro punto de frenado).
  Al suavizarla (0,15 → 0,4) `level_4` dejó de ganarse: la campana quedaba apoyada en la repisa, al borde de la
  ranura. Un plan robusto espera una **condición** (`until`: que el extremo haya caído), no un tiempo.
- **`PinJoint2D` no sirve para soldar dos RigidBody2D:** con `angular_limit` 0..0 el ángulo relativo igual giraba
  hasta 180° y con los jugadores tirando se separaban 57 px. Para unir dos cuerpos de forma exacta, uno va
  montado en el otro (congelado, sin colisiones, copiando la transformación) y el que lleva aplica las fuerzas
  del otro (ver `RopeEnd.attach_to`).
- **Un `Container` le reinicia posición y ESCALA a sus hijos cada vez que se reordena** (al cambiar el texto o
  el tamaño mínimo de cualquier hijo): animar `scale`/`position` de un hijo directo de un VBox/HBox/CenterContainer
  se pierde a mitad de camino. Animar un hijo propio que no maneje el contenedor (la `Cara` de BotonMadera, el
  `Title` dentro de `TitleBox` en la victoria) o el contenedor entero desde un padre que no sea contenedor.
- **Un `Label` con `label_settings` ignora `add_theme_color_override("font_color")`**: el color va en sus
  LabelSettings (duplicarlas antes de cambiarlas: son un recurso compartido). Por eso "¡Nuevo récord!" nunca
  salía dorado.
- **Conectar los controles con `SceneTree.node_added` (UiFx) ve la metadata de la escena** (se asigna al
  instanciar, antes de entrar al árbol), pero no lo que el `_ready` de un padre le ponga después: lo que se lee
  al apretar (el sonido) puede ir en `_ready`, lo que se decide al conectar (`ui_fx = false`) tiene que estar
  en la escena.
- **Arte hecho en paralelo por dos personas se pisa en el merge sin conflicto de texto:** pasó con los jugadores (sprites `Abierto`/`Cruzado` de una rama + `Sprite` animado de otra, los dos visibles). Tras un merge, correr y mirar cada nivel; todo el arte va en `assets/` para que se note cuando alguien ya tomó un asset.

## Estado de desarrollo

Hecho (el detalle de lo verificado con tests headless está en `docs/REGISTRO_TESTS.md`):

**Mecánica**
- **Base (fases 0–5):** Input Map y capas; personaje plataformero; cuerda híbrida (extremo-péndulo + cuerda visual) con largo continuo; el extremo colisiona y la cuerda limita al jugador; enganche a `HookPoint`; victoria con magnetismo.
- **Extremos como emboque real:** palito y campana `RigidBody2D` que rotan y chocan entre sí; victoria = palito dentro de la campana. Partes a ~1/3 del jugador y física a 120 Hz contra el tunneling. Proyecto en Godot 4.7.2 (antes 4.6).
- **Balanceo estilo DKC:** enganche instantáneo, péndulo propio del jugador, bombeo, salto desde la cuerda, soltarse con abajo, rapel, inclinación + squash/stretch.
- **Animaciones** jump/fall/swing/push provisorias (cuadros existentes) + estirón al saltar, aplastón y golpe al aterrizar, inclinación al empujar.
- **Salto parejo, más bajo y variable** (115 px con cualquier cuerda; termina al soltar la tecla) y el emboque que sigue como una cola (ver "El salto").
- **Tomar y lanzar el emboque** (por nivel, `LevelRules`), con mira en ping-pong y vuelo recto; la misma tecla lo recoge rápido a la mano. Se usa en lanzar_1..4 y en el final.
- **Magnetismo con curva + trabado:** suave a distancia, resorte fuerte una vez embocado.
- **Closeup + cámara lenta** al acercarse los extremos (estilo Peggle).
- **Escala 0,8** opcional (`level_base_large`) y **ráfagas** de viento.
- **Bonos de estilo** (solo texto): "¡Limpio!" y "¡Al vuelo!".
- **Zonas de emboque nuevas** en 27 niveles (ver "Zonas de emboque").
- **Animación del emboque:** subida de tensión (silencio antes del golpe, viñeta, halo), magnetismo más sutil, piezas pegadas al embocar, click de zoom, partículas doradas y
  confetti + chispas desde las esquinas de abajo.

**Objetos y niveles**
- **Zonas de muerte** (jugador / emboque / ambos), **caja empujable**, **coleccionables + puntaje** (también los recoge el emboque).
- **Mecánicas nuevas:** placas de presión, compuertas, plataformas móviles/ascensores, corrientes de aire (volantín), cuenco/embudo como meta.
- **29 niveles en un mapa ramificado** (tronco + 6 ramas + final), todos ganados por el bot de pruebas. Escena base heredable y bloques con `size`. Todas las ramas tienen 4 niveles.
- Del equipo: `level_2` ("La T") y `level_4` ("Escalones", rehecho sobre level_base) están en el mapa (fin de las ramas de peligros y de cajas); `main`, `level_3` y las pruebas siguen en el repo pero fuera del mapa.

**Presentación visual**
- **Sombras y brillos:** sombra difusa + oclusión del terreno; sombra con la forma de extremos, cuerda,
  cajas, sopaipillas, ganchos y placas; sombra permanente bajo los jugadores (en el aire marca dónde caen); fuego con brillo rojo que
  parpadea, caca con brillo verde que respira, púas con sombra oscura. Ver "Sombras y brillos".
- **Personajes que destacan del fondo:** fondo más plano y desenfocado con viñeta, personajes un poco más
  saturados y con una sombra suave alrededor.
- **Cajas resaltadas:** madera color miel + contorno dorado que late (`resaltar.gdshader`), para que se lean
  como objetos con los que se interactúa y no como terreno.

**Menús y presentación**
- **Tráiler** en español e inglés (`trailer/`), regenerable con un comando cuando cambie el arte.
- **Intro:** video de la historia al arrancar (`video/intro.ogv`), se salta con cualquier tecla, fundidos de entrada/salida; en web pide una tecla antes para que suene.
- **Idiomas:** español e inglés (todo el texto en `i18n/textos.csv`, imágenes con texto por idioma), selector con bandera (Chile / Reino Unido) en el menú principal, Ajustes y pausa; agregar un idioma = una columna.
- **HUD de madera** (estilo de los botones del menú): indicador "P · PAUSA" arriba a la izquierda (en todos los
  niveles, vía el PauseMenu; clic = pausar) y puntaje con la sopaipilla arriba a la derecha (salta al sumar).
- **Menús:** principal (portada, botones de madera, botón de idioma; sin Salir), mapa de niveles ramificado con progreso, ajustes con el tema de madera (y borrar progreso), pausa con el diseño del equipo, pantalla de victoria (Reintentar / Continuar, sopaipillas, highscore por nivel en `user://scores.cfg`).
- **Audio:** autoload `Sfx` con 22 efectos placeholder (incluye click, brillo y pop de confetti del emboque y 8 de la interfaz), música (cueca, sigue en la pausa) y volumen por categoría (General / Música / Efectos, con muestra al mover Efectos).
- **Interfaz pulida** (autoload `UiFx`): todo botón/slider/lista con cursor de mano, foco con el mouse y sonidos de
  madera y cuerda (hover, click, confirmar, volver, bloqueado, abrir pausa, desbloquear); botones de madera con
  canto que se hunden, se aclaran, halo y destello al resaltar; perillas doradas; cambios de pantalla con fundido;
  entradas animadas (menú, Ajustes, pausa, victoria con conteo de puntaje y estrellitas).
- **Arte (`assets/`):** jugadores animados (idle / caminata a 10 FPS / THROW al apuntar), palito, campana y cuerda, cajas, zonas de muerte animadas (fuego / púas / caca), sopaipillas, ganchos, terreno (piso por piezas + pared) y fondo.

Pendiente:
- **Fase 6** — Pasada de tuning de la sensación (magnetismo, masas, largos, velocidades, radios del closeup) jugando los niveles reales.
- **Arte que falta o hay que pulir:** una pose de pie para `idle` (ver "Arte del jugador"); cuadros propios para `jump` / `fall` / `swing` / `push` (hoy son provisorias con los cuadros de caminar/lanzar); costuras entre tablas de `piso_neutral` (vienen del dibujo); alinear bien el arte del palito y la campana con su colisión; la mano (`RopeAnchor`) no coincide exactamente con la mano del dibujo.
- **Web:** el preset exporta y se probó en Chromium headless (intro, menú, idiomas, mapa, nivel, pausa); falta subirlo a Newgrounds y probarlo con gente.
- **Imágenes en inglés definitivas** (`assets/ui/en/portada.png`, `pause_menu.webp`): hoy son el arte original
  con el texto reescrito por código; diseño puede reemplazarlas con el mismo nombre.
- **Niveles del equipo fuera del mapa** (`main`, `level_3`): corregir el inicio (ver Lecciones) si se quieren sumar.
- **Recorridos:** probar con gente los marcados con * (ver "Recorridos"): caja_1, placa_3 y movil_1 rehechos, tronco_2 y
  placa_4 más fáciles. Los niveles fuera del mapa (`main`,
  `level_3`, `test_*`) no se ajustaron al salto más bajo.
- **Tráiler:** tronco_3, peligro_2, caja_2, lanzar_3, placa_4, movil_3, viento_1, viento_3 y casi todos los demás cambiaron (regrabar). Los `start` de los clips en `trailer/edit.py` son tiempos fijos del bot; al regrabar hay que revisarlos (p. ej. `level_4` ahora emboca a los ~20 s de juego; antes, ~14).
- **Sonido:** reemplazar los efectos placeholder sintetizados por los definitivos.
- **Tráiler:** los `start` de los clips en `trailer/edit.py` son tiempos fijos del bot; al regrabar hay que revisarlos (p. ej. `level_4` ahora emboca a los ~20 s de juego; antes, ~14).
- **Sonido:** reemplazar los efectos placeholder sintetizados por los definitivos (también los `ui_*` de la interfaz).

Post-prototipo (del concepto): más objetos dinámicos, más niveles.

## Convenciones

- Al terminar una feature: actualizar la sección que corresponda de este archivo, agregar una línea en "Estado de desarrollo" y anotar qué se probó y el resultado en `docs/REGISTRO_TESTS.md` (no acá).
- Comentarios y nombres de usuario en **español**; código en GDScript idiomático de Godot 4.
- Placeholders geométricos (`Polygon2D`/formas) hasta que llegue el arte; al llegar se ocultan (`visible = false`), no se borran.
- **Todo el arte va en `assets/`** (ver Arquitectura). Al mover un archivo, moverlo **junto con su `.import`** (conserva el uid) y actualizar las rutas `res://` que lo usan.
- Cámara **fija** en los primeros niveles (del tamaño de la cámara, sin scroll).
