# Guía de assets — cómo cambiar el arte y los sonidos

**Regla de oro:** cada cosa que se ve en el juego sale de **un solo archivo**. Para
cambiarla en TODOS los niveles, se reemplaza ese archivo por otro **con el mismo
nombre** (mismo formato, idealmente la misma proporción) y listo: ningún nivel
apunta directo a una imagen, todos usan las escenas reutilizables de `scenes/`,
y esas escenas apuntan a `assets/`.

Después de reemplazar un archivo, abrir el proyecto en Godot (re-importa solo) o
correr `godot --headless --import --path .`.

> No mover ni renombrar archivos fuera de Godot: si hay que moverlos, hacerlo
> desde el FileSystem del editor (mueve también el `.import` y actualiza las rutas).

## Personajes y emboque

| Qué se ve | Archivo(s) a reemplazar | Escena que lo usa | Notas |
|---|---|---|---|
| Jugador 1 (rojo) | `assets/jugadores/p1/walk/P1_WALK_01.png`, `P1_WALK_02.png`, `throw/P1_THROW.png` | `scenes/player.tscn` (vía `p1_frames.tres`) | Dibujos **mirando a la izquierda** (el código los da vuelta). `jump`, `fall`, `swing` y `push` hoy reusan esos cuadros (provisorias): para el arte definitivo, abrir `p1_frames.tres` en Godot y cambiar los cuadros de esa animación (mismo nombre). |
| Jugador 2 (azul) | `assets/jugadores/p2/...` (mismos nombres con `P2_`) | `scenes/player.tscn` (vía `p2_frames.tres`) | Igual que J1. |
| Campana | `assets/emboque/campana.png` | `scenes/campana.tscn` | Si cambia la proporción, ajustar la escala del `Sprite` en esa escena para que calce con la colisión (~18×24 px). |
| Palito | `assets/emboque/palito.png` | `scenes/palito.tscn` | Colisión 22×6 px. |
| Cuerda (en el juego y en el mapa de niveles) | `assets/emboque/cuerda.png` | `scenes/emboque.tscn`, mapa (`level_selector.gd`) | Se repite a lo largo: tiene que ser "seamless" horizontal. |

## Terreno y fondo

| Qué se ve | Archivo(s) | Dónde | Notas |
|---|---|---|---|
| Pisos y plataformas | `assets/entorno/colision/piso.png` (tabla sola), `piso_left.png` + `piso_neutral.png` (se repite) + `piso_right.png` | `scenes/terrain_art.tscn` | TerrainArt viste **todos** los bloques de todos los niveles. Proporción 4:1. |
| Muros y el cuerpo de los bloques gruesos | `assets/entorno/colision/pared.png` | `scenes/terrain_art.tscn` | Proporción 1:4 (vertical). |
| Compuertas | `pared.png` (como un muro) + franjas del color de su canal | `scenes/gate.tscn` | Los colores de canal están en `scripts/mechanisms/channel.gd` (`COLORS`). |
| Plataformas móviles y cuencos | las piezas de piso | `scenes/moving_platform.tscn`, `scenes/bowl.tscn` | |
| Fondo de los niveles | `assets/entorno/fondo/paredazul.png` | `scenes/background.tscn` | 1280×720. |

## Peligros (animados, 3 cuadros a 9 FPS)

| Qué | Archivos | Escena |
|---|---|---|
| Púas (matan al jugador) | `assets/hazards/jugadores/spikes_1..3.png` | `scenes/player_death_zone.tscn` |
| Caca (mata al emboque) | `assets/hazards/emboques/caca_1..3.png` | `scenes/emboque_death_zone.tscn` |
| Fuego (mata a los dos) | `assets/hazards/ambos/fuego_1..3.png` | `scenes/both_death_zone.tscn` |

Los cuadros se repiten a lo ancho de la zona sin deformarse (`HazardArt`).

**Brillo y sombra de los peligros** (en el nodo `Art` de cada escena de arriba, grupos "Brillo" y "Halo" del
Inspector): el fuego tiene un **brillo rojo** que parpadea y la caca uno **verde** que respira (`glow_color`: el
alfa es la intensidad; `glow_radius`, `glow_flicker`, `glow_breathe`; `glow_front` = cuánto tiñe también al
terreno y a los jugadores cercanos; `glow_core` = degradado: la luz vale `glow_core` × alfa en el centro de la
zona y baja hasta 0 en el borde del radio, con la curva `glow_core_power`). Las púas tienen una **sombra oscura con su forma** (`halo_color`,
`halo_blur`, `halo_grow`). Se ven en el editor al abrir un nivel.

## Sombras (para que todo se despegue del fondo)

Se calculan solas a partir del dibujo: al cambiar un PNG, su sombra cambia con él.

- **Terreno:** cada bloque proyecta una sombra difusa hacia abajo a la derecha + un oscurecimiento parejo
  alrededor (oclusión ambiental). Se ajusta en `scenes/terrain_art.tscn`, grupo "Sombra".
- **Extremos, cuerda, cajas, sopaipillas, ganchos, placas:** un nodo `DropShadow` hijo del sprite copia el
  dibujo, oscuro y difuminado (`shadow_offset`, `blur`, `color`, `grow`).
- **Fondo:** se dibuja más plano, apenas desenfocado y con las esquinas más oscuras (material de
  `scenes/background.tscn`: `blur`, `contrast`, `saturation`, `brightness`, `vignette`), para que los
  personajes se lean primero. Un fondo nuevo pasa por el mismo filtro.
- **Personajes:** un poco más saturados y contrastados (material del `Sprite` en `scenes/player.tscn`) y con
  una sombra suave alrededor (`DropShadow`).
- **Jugadores:** una sombra ovalada **permanente** en el piso bajo ellos (`ContactShadow` en
  `scenes/player.tscn`): en el aire se achica y aclara, y marca dónde van a caer. Los extremos tienen una
  igual, solo cuando están cerca del piso.

## Objetos

| Qué | Archivo(s) | Escena | Notas |
|---|---|---|---|
| Caja | `assets/props/caja/caja.png` | `scenes/push_box.tscn` | 64×64 px en el juego. Se dibuja más cálida y con un contorno dorado que late (material del nodo `Sprite`: tono, saturación, brillo, contorno), para distinguirla del terreno. Si el arte nuevo ya se distingue solo, bajar esos valores. |
| Gancho | `assets/props/enganche/hoyo.png` | `scenes/hook_point.tscn` | ~36 px. |
| Sopaipilla (coleccionable; también en el mapa y la victoria) | `assets/props/puntos/sopaipilla_1..3.png` | `scenes/collectible.tscn` | |
| Placa de presión | `assets/props/placa/placa_base.png` (base) y `placa_tapa.png` (tapa) | `scenes/pressure_plate.tscn` | La **tapa se tiñe** con el color del canal: dibujarla en gris claro/blanco. |
| Rayitas de viento | `assets/props/viento/rafaga.png` | `scenes/wind_zone.tscn` | Blanca con transparencia; se tiñe y se mueve sola. |

## Celebración del emboque

Al embocar salen dos efectos de partículas, sin imágenes (formas dibujadas por shader): se ajustan abriendo la
escena y tocando cada `CPUParticles2D` en el Inspector (cantidad, velocidad, colores en `Color Ramp` /
`Color Initial Ramp`, tamaño en `Scale`).

| Qué | Escena | Notas |
|---|---|---|
| Destello y estrellitas doradas alrededor del emboque | `scenes/fx/emboque_burst.tscn` | `Flash` (destello inicial), `Burst` (estallido), `Sparkle` (destellos que quedan). La forma de estrella está en `shaders/destello.gdshader` (rayos, tamaño del centro). |
| Confetti y chispas en pantalla | `scenes/fx/win_confetti.tscn` | Salen de las esquinas de abajo (`ConfettiLeft/Right`, `SparksLeft/Right`). Colores del confetti: `Color Initial Ramp` (hoy bandera chilena + dorado). Para usar un dibujo propio de papelito o chispa, ponerlo en `Texture` (blanco: se tiñe solo). |

El "click" de zoom de la cámara y las piezas pegadas se ajustan en el Inspector del `CloseupManager` (grupo
"Click al embocar") y del `WinManager` (grupo "Celebración") de cada nivel.

## Menús

| Qué | Archivo | Escena | Notas |
|---|---|---|---|
| Portada del menú principal (título y controles dibujados) | `assets/ui/portada.png` (español) y `assets/ui/en/portada.png` (inglés) | `scenes/ui/main_menu.tscn` | La fila de lanzar ahora dice "LANZAR" (el mapa ya no tiene "niveles verdes"). |
| Menú de pausa | `assets/ui/pause_menu.webp` (español) y `assets/ui/en/pause_menu.webp` (inglés) | `scenes/ui/pause_menu.tscn` | Ver "Menú de pausa" en CLAUDE.md. Los botones pintados tienen que quedar en el mismo lugar en todos los idiomas. |
| Botones de madera, nodos del mapa | (procedurales: `shaders/madera_boton.gdshader`) | `scenes/ui/boton_madera.tscn`, `scenes/ui/level_node.tscn` | Colores de la madera en los parámetros del shader. |
| Video de intro | `video/intro.ogv` | `scenes/ui/intro.tscn` | Arrastrar el video (mp4…) sobre `tools/convertir_video.bat` y listo. Ver `video/README.md`. |

### Imágenes con texto en otros idiomas

Las imágenes que traen **texto dibujado** (portada y menú de pausa) tienen una versión
por idioma: el **mismo nombre** dentro de una subcarpeta con el código del idioma
(`assets/ui/en/portada.png`). El juego la elige sola según el idioma; si falta, usa la
original en español. Las de inglés que hay hoy son **provisorias** (el arte original
con el texto reescrito por código, con fuentes parecidas): conviene que diseño haga
las definitivas con el mismo encuadre.

Los textos del juego (botones, menús, nombres de niveles) **no** son imágenes: están
en `i18n/textos.csv` (una columna por idioma).

## Sonidos (`audio/`)

Todos los efectos están en `audio/sfx/` y registrados en `scripts/sfx.gd` (`SOUNDS`:
nombre → archivo + volumen). Reemplazar el archivo con el mismo nombre (WAV u OGG).

| Archivo | Cuándo suena |
|---|---|
| `step.wav` | Pasos al caminar |
| `jump.wav` | Salto (y al lanzarse desde la cuerda, más agudo) |
| `die.wav` | Al morir |
| `hook.wav` | Al engancharse |
| `swing.wav` | Pasada del balanceo |
| `box_push.wav` | Loop al arrastrar una caja |
| `grab.wav` / `throw.wav` | Tomar / lanzar el emboque |
| `plate.wav` | Placa de presión (al pisar y al soltar, más agudo) |
| `gate.wav` | Compuerta que se mueve |
| `wind.wav` | Loop de las corrientes de aire |
| `audio/cueca.ogg` | Música |

Los efectos actuales son placeholders sintetizados con `tools/generate_sfx.py`.

## Hacer un nivel nuevo (para diseño)

1. *Scene → New Inherited Scene* desde `scenes/levels/level_base.tscn` (ya trae
   fondo, cámara, muros laterales, jugadores, emboques, victoria, pausa, puntaje).
2. Agregar bloques (`scenes/block.tscn`, con su `size` en el Inspector), ganchos,
   peligros, cajas, placas, compuertas, plataformas, viento, cuencos y sopaipillas.
3. Mover `Player1` / `Player2` a su inicio (en el aire: el extremo nace 170 px
   debajo de la mano).
4. Agregar el nivel a `scripts/level_catalog.gd` (aparece solo en el mapa).
