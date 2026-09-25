# Guía de assets — Emboque de a Dos

Paso a paso para reemplazar los placeholders geométricos por arte real, **sin tocar la física**. Todo se hace desde el editor de Godot 4.7.

- [0. Antes de empezar (vale para todo)](#0-antes-de-empezar-vale-para-todo)
- [1. Assets estáticos](#1-assets-estáticos): emboque, cuerda, fondo, plataformas, objetos reutilizables
- [2. Animaciones](#2-animaciones): cómo se crean, personajes, eventos
- [3. Checklist de prueba](#3-checklist-de-prueba)
- [4. Problemas comunes](#4-problemas-comunes)

---

## 0. Antes de empezar (vale para todo)

### Dónde va cada cosa

```
assets/
  emboque/            palito.png, campana.png, cuerda.png
  personajes/
    p1/               frames de J1 (campana)
    p2/               frames de J2 (palito)
  entorno/
    fondos/           un fondo por nivel
    plataformas/      suelo, plataformas, muros
    hazards/          zonas de muerte
  props/              ganchos, coleccionables, cajas, efectos
  ui/                 menús, botones, animación de victoria
  fonts/
audio/                música y efectos (ver sección "Sonidos" del CLAUDE.md)
```

### Reglas de archivos

- **Formato: PNG** (con transparencia). Para fondos que sean fotos, JPG también sirve.
- **Nombres en minúscula, sin espacios, tildes ni ñ:** `campana.png`, `p1_walk_003.png`. El export web distingue mayúsculas y minúsculas; Windows no, así que un error de mayúsculas funciona en el editor y falla en Newgrounds.
- **Secuencias con ceros a la izquierda:** `walk_000.png`, `walk_001.png`… (si no, `walk_10` queda antes que `walk_2`).
- **Archivos fuente** (`.psd`, `.kra`, `.clip`, `.aseprite`): no los pongas en `assets/`. Déjalos fuera del proyecto, o en una carpeta `art_source/` que tenga adentro un archivo vacío llamado `.gdignore` (así Godot no intenta importarla).

### Resolución: dibujar a ~2×

El juego no es pixel-art y se escala al tamaño de la ventana. Además, al embocar, la cámara hace **zoom hasta 2×** (closeup). Por eso, **dibuja cada cosa a unas 2 veces su tamaño en pantalla** y achícala en Godot con `Scale = 0.5`.

| Elemento | Tamaño en el juego | Tamaño sugerido del PNG |
|---|---|---|
| Jugador | 40×64 | ~80×128 (puede sobresalir: pelo, brazos) |
| Palito | 22×6 | ~44×12 a 88×24 |
| Campana | ~18×24 | ~36×48 a 72×96 |
| Fondo | 1280×720 | 2560×1440 (o 1920×1080) |

Recorta los márgenes transparentes que sobren: ocupan memoria igual.

### El archivo `.import`

Al copiar un PNG al proyecto, Godot lo importa solo y crea `archivo.png.import` al lado. Ese archivo guarda los ajustes de importación y el identificador del recurso:

- **Commitéalo** junto con el PNG.
- **Para reemplazar un asset**, sobrescribe el PNG con el **mismo nombre**: todo lo que lo usa se actualiza solo.
- **Para borrar un asset**, hazlo desde el panel **FileSystem** de Godot (clic derecho → Delete). Borra ambos archivos y avisa si algo lo usa.

### Ajustes de importación (pestaña **Import**, al lado de Scene)

| Tipo | Compress → Mode | Mipmaps |
|---|---|---|
| Personajes, emboque, objetos, UI | `Lossless` (default) | No |
| Fondos grandes / fotos | `Lossy` (calidad ~0.8) → pesa mucho menos en web | No |
| Imagen que se ve **mucho** más chica que su resolución | el que corresponda | Sí (`Mipmaps → Generate`) |

Tras cambiar algo, pulsa **Reimport**.

---

## 1. Assets estáticos

La receta es siempre la misma: **agregar un `Sprite2D` con el PNG, alinearlo con la colisión y ocultar el placeholder**. Nunca muevas ni escales el nodo raíz ni las colisiones para que calcen con el dibujo; mueve el `Sprite2D`.

> **Tip:** activa **Debug → Visible Collision Shapes** en el menú del editor. Al correr el juego verás las colisiones encima del arte y podrás comprobar que coinciden.

### 1.1 Emboque: palito y campana

Estas escenas se usan en **todos los niveles**: se cambian una vez y listo.

| | Escena | Orientación del dibujo | Marcadores que deben coincidir con el dibujo |
|---|---|---|---|
| Palito (J2) | `scenes/palito.tscn` | horizontal, **punta a la derecha** | `Tip` (en la punta) |
| Campana (J1) | `scenes/campana.tscn` | **abertura mirando a la derecha** | `Mouth` (entrada), `Cavity` y `CavitySensor` (dentro del hueco) |

La cuerda se ata al **centro (0,0)** de cada pieza. Cuando el jugador toma el emboque en la mano, el código lo pone mirando hacia donde mira el jugador, por eso el dibujo debe "mirar a la derecha".

**Palito:**
1. Copia el PNG a `assets/emboque/palito.png`.
2. Abre `scenes/palito.tscn`.
3. Clic derecho en el nodo raíz `Palito` → **Add Child Node** → `Sprite2D`. Tiene que ser hijo directo del raíz, para que rote con él.
4. Arrastra `palito.png` desde el FileSystem al campo **Texture** del Inspector.
5. Si el PNG está vertical, pon **Rotation** en `90` o `-90` hasta que la punta quede a la derecha.
6. Ajusta **Scale** (con el candado activado, para no deformarlo) hasta que el dibujo cubra el rectángulo de colisión. Si hace falta correrlo, usa **Offset**.
7. Revisa que el marcador `Tip` quede en la punta real del dibujo. El magnetismo apunta con él.
8. Oculta el nodo `Visual` (ojo del árbol de escena) y compara. Cuando esté bien, bórralo.
9. Guarda (**Ctrl+S**).

**Campana:** los mismos pasos en `scenes/campana.tscn`, con estas diferencias:
- Gírala para que la **abertura mire a la derecha**. Si la dibujaste con la boca hacia abajo: `Rotation = -90`.
- Las paredes del dibujo deben coincidir con los tres rectángulos `Spine`, `Top` y `Bottom`, y el hueco con el hueco.
- Borra `VisualSpine`, `VisualTop` y `VisualBottom`.

**Si el dibujo no calza con la forma actual**, no lo deformes: cambia las colisiones.
- Mueve o redimensiona los rectángulos. Si la campana es curva, usa más rectángulos (no polígonos cóncavos).
- Mueve `Mouth`, `Cavity` y `CavitySensor` al nuevo hueco.
- Mantén las paredes de **6 px o más** (más finas y el palito puede atravesarlas) y el hueco más ancho que el grosor del palito.
- Prueba embocar de nuevo. Si cuesta mucho o es demasiado fácil, ajusta el magnetismo en el `WinManager` de cada nivel (`magnet_radius`, `linear_accel`, `angular_gain`).

### 1.2 Cuerda (opcional)

La cuerda es un `Line2D` llamado `Rope` en `scenes/emboque.tscn`.
1. Usa una textura **horizontal y repetible** (que empalme consigo misma), por ejemplo 32×8 px.
2. En `Rope`: **Texture** → tu PNG; **Texture Mode** → `Tile`.
3. En **CanvasItem → Texture → Repeat**, elige `Enabled`.
4. Pon **Default Color** en blanco. El color se multiplica con la textura, y el café actual la oscurecería.
5. Ajusta **Width** si hace falta.

### 1.3 Fondo de un nivel

Cada nivel (`scenes/main.tscn`, `scenes/level_2.tscn`, …) tiene su propio fondo. La cámara es fija y muestra exactamente el rectángulo de **(0,0) a (1280,720)**.

1. Copia el fondo a `assets/entorno/fondos/`, por ejemplo `nivel_1.png`, idealmente de 2560×1440.
2. Si es una foto, en la pestaña **Import** pon **Compress → Mode = Lossy** y pulsa **Reimport**.
3. Abre la escena del nivel.
4. Clic derecho en el nodo raíz → **Add Child Node** → `Sprite2D`, y llámalo `Fondo`.
5. Arrástralo hasta **el primer lugar** del árbol, justo debajo del nodo raíz. Lo que está arriba se dibuja detrás.
6. Configúralo en el Inspector:
   - **Texture:** tu fondo.
   - **Centered:** desactivado.
   - **Position:** `(0, 0)`.
   - **Scale:** `0.5` si el PNG es de 2560×1440, o `0.6667` si es de 1920×1080.
   - **Ordering → Z Index:** `-10`, por seguridad.
7. Ponlo **dentro del mundo** (hijo del raíz), **no** dentro del `CanvasLayer` `UI`. Así el zoom del closeup también lo acerca.

Si el fondo ya dibuja el suelo y las plataformas, puedes **ocultar** los `Visual` de `Ground`, `PlatformLeft`, etc. **No borres los `StaticBody2D` ni sus colisiones.** El dibujo tiene que coincidir con ellas, porque los jugadores chocan contra las colisiones, no contra el dibujo.

### 1.4 Plataformas, suelo y muros

Son `StaticBody2D` dentro de cada nivel, con un `Polygon2D` llamado `Visual`. Tienes dos opciones:

**A. Textura repetible (recomendado para piso, muros, plataformas de largo variable)**
1. Selecciona el `Visual` (Polygon2D) de la plataforma.
2. **Texture:** tu PNG repetible (por ejemplo `assets/entorno/plataformas/tierra.png`).
3. **CanvasItem → Texture → Repeat:** `Enabled`.
4. **Color:** blanco `(1, 1, 1, 1)`. Si no, la textura se tiñe del color del placeholder.
5. Ajusta **Texture → Scale** / **Offset** para el tamaño y el encaje del patrón.

Así la textura se adapta sola a cualquier largo y no hay que alinear nada.

**B. Dibujo único (una plataforma con forma especial)**
Agrega un `Sprite2D` hijo del `StaticBody2D`, alinéalo con la colisión (igual que en 1.1) y oculta `Visual`.

### 1.5 Objetos reutilizables

Se cambian **una vez en su escena** y se actualizan en todos los niveles. En todos, el placeholder es un `Polygon2D` llamado `Visual`: agrega un `Sprite2D` hijo del raíz, alinéalo y oculta o borra `Visual`.

| Escena | Tamaño de la colisión | Notas |
|---|---|---|
| `scenes/hook_point.tscn` | círculo r=18 | El centro es donde se cuelga la cuerda. |
| `scenes/collectible.tscn` | círculo r=12 | |
| `scenes/push_box.tscn` | 64×64 | Borra también `Outline` y `Cross` (Line2D). |
| `scenes/player_death_zone.tscn`, `emboque_death_zone.tscn`, `both_death_zone.tscn` | 100×30 | Ojo: en los niveles se **estiran con `Scale`** (por ejemplo, el piso naranja de `level_2` tiene `Scale = (12.8, 1.6)`), así que cualquier dibujo o textura que les pongas se deforma igual. Para zonas de distinto tamaño, lo correcto es cambiar el tamaño de la colisión en vez de escalar el nodo. Pídelo antes de ponerles arte. |

---

## 2. Animaciones

### 2.1 Cómo se crea una animación en Godot

**No uses video (.mp4).** Godot no lo reproduce y su video (Ogg Theora) no soporta transparencia. Una animación es **una secuencia de PNG** dentro de un nodo **`AnimatedSprite2D`**, que las guarda en un recurso **SpriteFrames**.

1. Copia los frames a su carpeta, por ejemplo `assets/personajes/p1/walk/walk_000.png`, `walk_001.png`…
2. Agrega un nodo `AnimatedSprite2D` (en 2.2 y 2.3 se explica dónde).
3. Inspector → **Sprite Frames** → **New SpriteFrames**. Haz clic sobre el recurso: se abre el panel **SpriteFrames** abajo.
4. En la lista de animaciones de la izquierda, renombra `default` o crea nuevas (botón **Add Animation**). **El nombre importa** (ver 2.2).
5. En el FileSystem, selecciona todos los frames de esa animación (clic en el primero, Shift+clic en el último) y **arrástralos al área de frames**. Quedan en orden alfabético.
6. Ajusta:
   - **FPS:** 12 es buen punto de partida para animación tradicional; 8 si quieres un look más "cortado".
   - **Loop:** activado para ciclos (caminar, respirar); desactivado para acciones de una sola vez.
7. Si tus frames están en una sola imagen (spritesheet), usa el botón **Add frames from a Sprite Sheet** (ícono de grilla) y define filas y columnas.
8. Recomendado: en el Inspector, en el recurso SpriteFrames, usa **Save As** y guárdalo como `.tres` (por ejemplo `assets/personajes/p1/p1_frames.tres`). Así puedes reutilizarlo en otras escenas.

**Cuida el peso:** cada frame ocupa memoria de video completa. 60 frames de 1280×720 son ~220 MB, demasiado para web. Recorta cada frame al área que se mueve, usa pocos FPS y no hagas los PNG más grandes que lo sugerido en la sección 0.

### 2.2 Personajes

El código de `player.gd` ya está preparado: **si encuentra un `AnimatedSprite2D` llamado exactamente `Sprite` en `Visual/Art`, reproduce solo la animación que corresponde al estado del jugador.** No hay que programar nada.

**Estructura de `scenes/player.tscn`:**
```
Player (CharacterBody2D)
  CollisionShape2D       40×64, centrado (los pies están en y = +32)
  Visual                 ← el código lo INCLINA (balanceo) y lo aplasta/estira al saltar. No tocar.
    Art                  ← el código lo ESPEJA según hacia dónde mira. No tocar.
      Body, Eye          ← placeholders: borrar
      Sprite             ← AQUÍ va tu AnimatedSprite2D
  RopeAnchor             la mano: de aquí cuelga la cuerda, en (0, -18)
```

**Nombres de animación (en minúscula, exactos):**

| Nombre | Cuándo se reproduce | ¿Loop? |
|---|---|---|
| `idle` | Quieto en el piso | Sí |
| `walk` | Caminando | Sí |
| `jump` | En el aire, subiendo | No (se queda en el último frame) |
| `fall` | En el aire, bajando | Sí, o No |
| `swing` | Colgando de un gancho con la cuerda tensa | Sí |
| `push` | Empujando una caja | Sí |
| `aim` | Apuntando para lanzar el emboque | Sí |

Las que no existan simplemente no se reproducen. Puedes partir solo con `idle` y `walk` e ir agregando.

**Pasos:**
1. Abre `scenes/player.tscn`.
2. Selecciona `Visual/Art` → **Add Child Node** → `AnimatedSprite2D`, y renómbralo **`Sprite`**.
3. Crea las animaciones como en 2.1, con los nombres de la tabla.
4. **Dibuja al personaje mirando a la derecha.** El código lo da vuelta cuando camina a la izquierda.
5. Alinea el sprite (**Scale** y **Offset** del `Sprite`, nunca de `Visual` ni de `Art`):
   - **Los pies del dibujo tienen que quedar en y = +32** (borde inferior de la colisión). Si no, el personaje flota o se hunde en el piso.
   - La mano que sostiene la cuerda debería quedar cerca de `RopeAnchor` (0, -18). Si tu dibujo tiene la mano en otro lugar, mueve `RopeAnchor` en esta misma escena.
   - Todos los frames de una animación deben tener **el mismo tamaño y el personaje en la misma posición dentro del PNG**. Si no, "tiembla" al animar.
6. Borra `Body` y `Eye`.
7. En **Sprite → Animation**, deja `idle` y activa **Autoplay on Load**, para que no aparezca un frame suelto al iniciar.

**J1 y J2 con arte distinto:** hoy ambos jugadores usan la **misma** escena `player.tscn`. J2 se diferencia solo por un tinte (`modulate`) aplicado a `Player2` en cada nivel. Si pones el `Sprite` en `player.tscn`, los dos tendrán el mismo dibujo (J2 teñido de rojizo). Para que cada uno tenga el suyo hay dos caminos:
- **Recomendado:** un pequeño cambio en `player.gd` para que elija sus SpriteFrames según el jugador (`p1` / `p2`), y quitar el `modulate` de `Player2` en cada nivel. Pídeselo a Claude o a quien programe **antes** de este paso.
- **Sin código:** en cada nivel, clic derecho en `Player2` → **Editable Children** → en su `Visual/Art/Sprite` cambia **Sprite Frames** por el `.tres` de J2, y en `Player2` pon **Modulate** en blanco. Hay que repetirlo en cada nivel nuevo.

### 2.3 Animaciones de eventos

#### Victoria (sin código)

Al embocar, el nivel muestra un cartel y, 2,5 segundos después, cambia a la pantalla `scenes/ui/victory.tscn`. Lo más simple es poner la animación ahí, y así sale en todos los niveles:

1. Copia los frames a `assets/ui/victoria/`.
2. Abre `scenes/ui/victory.tscn`.
3. Selecciona el nodo raíz `Victory` → **Add Child Node** → `AnimatedSprite2D`.
4. Crea la animación como en 2.1 (Loop según prefieras).
5. **Position** en píxeles de pantalla. Por ejemplo `(640, 200)`: centrada, sobre el título.
6. Activa **Autoplay on Load**.

#### Eventos dentro del nivel (necesitan un poco de código)

Otras animaciones, como un destello al engancharse, algo al morir o al recoger un coleccionable, o una animación en el mismo instante del emboque, tienen que **aparecer en el momento del evento**, y eso requiere código. Tu parte:

1. Crea una escena nueva de efecto: **Scene → New Scene**, con un nodo raíz `AnimatedSprite2D`.
2. Crea su animación (Loop **desactivado**) con **Autoplay on Load** activado.
3. Guárdala como `scenes/fx/<nombre>.tscn` (por ejemplo `scenes/fx/enganche.tscn`).
4. Pide que se conecte al evento, indicando la escena y cuándo debe aparecer. Por ejemplo: *"que `fx/enganche.tscn` aparezca en el gancho cada vez que un jugador se engancha"*.

Ten en cuenta:
- **Cámara lenta al embocar:** cuando los extremos se acercan, el juego se ralentiza hasta un 35 % y **las animaciones también**. Para un efecto de emboque en el nivel hay que compensarlo por código.
- **Muerte:** hoy el nivel se reinicia al instante al tocar una zona de muerte. Para mostrar una animación de muerte hay que hacer que el reinicio espere.
- **Pausa:** con el juego en pausa (Esc), las animaciones del nivel se detienen. Es lo esperado.

---

## 3. Checklist de prueba

Después de agregar arte, corre el nivel con **F6** (con la escena abierta) y activa **Debug → Visible Collision Shapes**:

- [ ] El dibujo coincide con las colisiones: el jugador pisa el suelo **dibujado**, no flota ni se hunde.
- [ ] El emboque se ve bien al balancearse, al chocar entre sí, **en la mano** y **al lanzarlo** (`test_throw.tscn`), mirando a ambos lados.
- [ ] Se puede **embocar**, y el palito entra visualmente en la campana.
- [ ] El personaje mira hacia donde camina y todas sus animaciones cambian bien (quieto, caminar, saltar, caer, colgar, empujar, apuntar).
- [ ] Nada se ve pixelado o borroso en el closeup del emboque (zoom 2×).
- [ ] El fondo cubre toda la pantalla, también en pantalla completa.
- [ ] Commitea cada PNG **con su `.import`**.

---

## 4. Problemas comunes

| Síntoma | Causa probable | Solución |
|---|---|---|
| La animación del personaje no se reproduce | El nodo no se llama exactamente `Sprite`, no está dentro de `Visual/Art`, o los nombres de animación no coinciden (`Walk` ≠ `walk`) | Revisa nombres y ubicación (2.2) |
| El personaje o la textura se ve teñido | `Color` del Polygon2D o `Modulate` de `Player2` | Ponlos en blanco |
| El personaje flota o se hunde | Los pies no están en y = +32 | Ajusta **Offset** del `Sprite` |
| El personaje "tiembla" al animar | Los frames tienen distinto tamaño o encuadre | Exporta todos los frames con el mismo lienzo |
| Se ve borroso de cerca | PNG de poca resolución | Dibújalo a ~2× (sección 0) |
| Se ve serruchado al achicarse mucho | Faltan mipmaps | Import → Mipmaps → Generate → Reimport |
| Borde blanco o negro alrededor del dibujo | Mala transparencia en los bordes del PNG | Import → **Fix Alpha Border** activado → Reimport; o exporta el PNG sin fondo mate |
| Funciona en el editor pero falla en web | Mayúsculas distintas en el nombre del archivo | Renombra todo a minúsculas desde el FileSystem de Godot |
| El dibujo mira al revés | Se dibujó mirando a la izquierda | Dibuja mirando a la derecha, o activa **Flip H** en el `Sprite` |
| La animación va lenta en el emboque | Cámara lenta del closeup | Ver 2.3 |
| Un asset nuevo da "No loader found" en pruebas por terminal | No se importó | `godot --headless --import --path .` |
