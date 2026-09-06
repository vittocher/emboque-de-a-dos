# CLAUDE.md — Emboque de a Dos

Guía para trabajar en este repositorio. Léela antes de tocar código.

## Qué es el juego

**Emboque de a Dos**: puzzle **cooperativo local de 2 jugadores** (estilo *Fireboy & Watergirl*), en **Godot 4.6**, apuntado a **web (Newgrounds)**. Tema: amistad y tradición chilena.

De cada personaje cuelga **media mitad del emboque** por una cuerda: J1 lleva el **palito**, J2 la **campana**. La física de la cuerda (balanceo tipo péndulo) es la mecánica central. El objetivo de cada nivel es **juntar palito + campana** (embocar). El concepto completo está en `EmboqueDA2 Concepto.pdf`.

## Setup / cómo correr

- **Editor:** Godot 4.6 (ejecutable en `C:\Users\vitto\OneDrive\Desktop\Godot\Godot_v4.6-stable_win64.exe`; la variante `..._console.exe` sirve para CLI headless).
- **Abrir:** importar el `project.godot` de esta carpeta desde el Project Manager, o **F5** para jugar.
- **Escena de arranque:** `res://scenes/ui/main_menu.tscn` (menú). El **nivel de gameplay** es `res://scenes/main.tscn`. Durante el desarrollo del gameplay, abrir `main.tscn` y correr con **F6** (ejecutar escena actual) para saltarse el menú.
- **Resolución base:** 1280×720 (16:9). Stretch `canvas_items` + aspect `keep` (default en Godot 4, por eso el editor lo omite del archivo). No pixel-art; se adapta a cualquier tamaño de embed sin deformar.

### Validación headless (sin abrir el editor)

```bash
GODOT="/c/Users/vitto/OneDrive/Desktop/Godot/Godot_v4.6-stable_win64_console.exe"
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
  ui/main_menu.tscn      Menú: Jugar, Ajustes, y texto de controles.
  ui/level_selector.tscn Selector de niveles (1 nivel por ahora; futuro: grafo conectado).
  ui/settings.tscn       Ajustes: volumen maestro + pantalla completa.
scripts/
  player.gd        Controlador de plataformas parametrizado por input_prefix.
  emboque.gd       Coordina la media-cuerda: largo, enganche, límite del jugador, cuerda visual;
                   instancia el extremo (end_scene) y le pasa los parámetros de la cuerda.
  rope_end.gd      RigidBody2D del extremo (palito/campana): restricción de cuerda en _integrate_forces.
  win_manager.gd   Magnetismo distancia+ángulo entre extremos + victoria (palito dentro de campana).
  ui/*.gd          Lógica de los menús (navegación con change_scene_to_file).
```

J1 = **campana**, J2 = **palito** (asignados en `main.tscn` vía `end_scene` + `end_kind`).

### Flujo de escenas (UI)

`main_menu` → (Jugar) → `level_selector` → (Nivel 1) → `main.tscn` (gameplay).
`main_menu` → (Ajustes) → `settings`. Selector y Ajustes tienen botón **Volver** al menú.
Para agregar niveles: extender `LEVELS` en `level_selector.gd` y (a futuro) disponer los botones como grafo con líneas de conexión.

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

`rope_end.gd` en `_integrate_forces`: si `hooked`, fija el extremo al gancho; si no, aplica la **restricción de cuerda por velocidad** (quita la velocidad radial hacia afuera + corrige el exceso), sin fijar posición → el motor resuelve colisiones y el extremo **nunca atraviesa geometría**. Además **capa la rapidez** (`max_speed`) para evitar tunneling con el otro extremo.

API para el WinManager: `get_end()` (RigidBody), `get_end_position()`, `get_cavity_sensor()` (solo campana).

### Victoria y magnetismo (`win_manager.gd`)

Identifica palito y campana por `end_kind`. Cada frame, si la punta del palito está a menos de `magnet_radius` de la boca de la campana, aplica magnetismo de **distancia** (fuerza que atrae la punta hacia la cavidad, y la campana hacia la punta) **y de ángulo** (alinea el eje del palito para que apunte a la cavidad, y gira la boca de la campana hacia la punta). Con la física resolviendo la colisión, el palito **entra por la boca**. **Victoria** = el palito está dentro del `CavitySensor` de la campana (respaldo: muy cerca + bien alineado). Muestra `WinLabel` y reinicia tras `restart_delay`. **Va antes que los Emboque en el árbol** para que las fuerzas se integren el mismo frame.

## Lecciones aprendidas / trampas (NO repetir)

- **Nunca corregir la restricción con `global_position = ...` (teletransporte):** ignora colisiones y el extremo atraviesa paredes. Usar siempre movimientos con barrido de colisión.
- **`move_and_collide` se detiene en el primer contacto y NO desliza.** Si el vector de corrección tiene componente contra una superficie (p. ej. hacia el piso), aborta *todo* el movimiento, incluida la parte útil. Por eso existe `_move_sliding()`, que proyecta el resto sobre la normal y continúa. Fue la causa de que la cuerda no limitara al jugador.
- **Medir el progreso de la restricción por reducción real de distancia**, no por cuánto se movió el extremo: si resbala tangencialmente por un muro, esa distancia recorrida no acorta la cuerda.
- **Orden en el árbol importa:** `WinManager` antes que los `Emboque`, y los `Emboque` después de los `Player` (para que las correcciones se apliquen el mismo frame).
- **UIDs:** no inventar `uid://...` a mano (Godot los rechaza como inválidos). Dejar que el editor los genere; en referencias `ext_resource` basta el `path`.
- **Inferencia de tipos:** acceder a propiedades de un nodo tipado genéricamente (`Node2D`) devuelve Variant y rompe `:=`. Tipar con el `class_name` real (p. ej. `var e: Emboque`).
- **Tunneling entre cuerpos delgados y rápidos:** un extremo veloz atraviesa al otro. Mitigado con tres cosas juntas: `continuous_cd = 2` (CCD cast-shape), un tope de rapidez (`max_speed` en `rope_end.gd`, hoy 300), y **física a 120 Hz** (`physics/common/physics_ticks_per_second`) → menos avance por frame. Regla práctica: `max_speed / ticks` debe ser bastante menor que el grosor de pared más fino (hoy 6px). El CCD dinámico-vs-dinámico en 2D por sí solo no basta.
- **Tamaños actuales (placeholders):** jugador 40×64; palito 22×6; campana ~18×24 (paredes 6px, hoyo ~12px). Las partes son ~1/3 del jugador. Magnetismo suave: `magnet_radius=70`, `linear_accel=900`, `angular_gain=2.5`. Todo es tuneable en el Inspector.
- **Restricción de cuerda en RigidBody:** hacerla por **velocidad** en `_integrate_forces` (no fijando `transform.origin`), para no teletransportar a través de paredes. Definir `_integrate_forces` NO desactiva las colisiones (salvo `custom_integrator = true`).
- **Formas cóncavas en 2D:** no existen como shape convexa única. La campana (C) se arma con **varios `CollisionShape2D` rectangulares** (convexos), no un polígono cóncavo.
- **Al medir en tests una colisión con péndulo:** medir el **pico** (ej. máximo empuje), no el frame final — el péndulo/gravedad ya devolvió el cuerpo a su sitio y da un falso negativo.
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

Pendiente:
- **Fase 6** — Nivel de prueba definitivo a medida de cámara + pasada de tuning de la sensación (magnetismo, masas, largos, velocidades).

Post-prototipo (del concepto): objetos empujables, mapa de progresión de niveles, celebración estilo Peggle (zoom + cámara lenta al acercarse los extremos), estética Tikitiklip (animación tradicional + imágenes reales chilenas), sonido, export a web.

## Convenciones

- Comentarios y nombres de usuario en **español**; código en GDScript idiomático de Godot 4.
- Placeholders geométricos (`Polygon2D`/formas) hasta que llegue el arte.
- Cámara **fija** en los primeros niveles (del tamaño de la cámara, sin scroll).
