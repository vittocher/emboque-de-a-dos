# Registro de tests — Emboque de a Dos

Qué se verificó de cada feature con tests headless y con qué resultado. Los scripts de test eran temporales, así que este archivo es el registro de lo comprobado: al terminar una feature, agregar aquí qué se probó y el resultado (y una línea en "Estado de desarrollo" de `CLAUDE.md`). Es un historial: cada entrada vale para el momento en que se escribió.

## Mecánica base

- **Cuerda limita al jugador (Fase 4):** sobre-extensión 459 px → 0,04 px.
- **Enganche básico (Fase 4.5):** engancha al tocar, rapel con soltar/tirar, salto desengancha. PASS.
- **Extremos como emboque real:** colisión entre extremos sin atravesarse (incl. a velocidad alta), emboque por magnetismo, enganche. PASS.
- **Balanceo estilo DKC:** radio exacto, período, bombeo ≤ ángulo máx, enganche instantáneo, lanzamiento sin tirón, rapel, enganche sobre el gancho, suelo atado, sin doble salto. PASS.
- **Muros laterales:** en todos los niveles hay muro exactamente en `x=0` y `x=1280` (consulta de punto / raycast). PASS. Los niveles 3 y 4 no los tenían tras el merge de develop; agregados y verificados (muro en y −300…700 a ambos lados).

## Victoria, magnetismo y closeup

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

## Objetos y zonas

- **Export web con idiomas** (Chromium headless, Playwright): el navegador en inglés arranca el juego en inglés
  (idioma del sistema); el botón de idioma cambia todo a español (portada, botones); mapa, nivel y pausa (imagen en
  español) siguen el idioma; sin errores en consola. PASS.
- **Ajustes con el tema de madera** (Xvfb, es/en): se ve como el panel de la pausa; borrar progreso: 1 clic pide
  confirmar ("¿Seguro? Presiona otra vez"), el 2.º borra (completados 25 → 0), sin 2.º clic se desarma a los 3 s. PASS.
- **Revisión de bugs (fixes verificados):** ganado + tocar una zona de muerte → no recarga ni suena y llega a la
  victoria; dos zonas en el mismo instante → una sola recarga; música sigue en la pausa (avanza 0,65 s en 0,6 s
  reales); abrir Ajustes de la pausa no suena ni guarda; mover Efectos da una muestra; plataforma bajando sobre un
  jugador se detiene 1 px sobre su cabeza sin moverlo. PASS 9/9. `run_all.sh` 25/25 después de los cambios.
- **Zonas de muerte:** detección, aislamiento por máscara (la de jugador no mata al emboque y viceversa), zona "ambos". PASS. Tras ponerles arte (HazardArt) se volvió a verificar que siguen disparando.
- **Caja empujable:** asentarse, empuje parejo, frenar al soltar, muro, pararse encima, pasajero, golpe de campana, empujes opuestos, caída de borde, pila. PASS.

## Música instrumental (playlist de `audio/musica/`) — PASS 16/16

Test headless (macOS) sobre `SettingsManager`: encuentra las 4 cuecas de `audio/musica/` y "La Consentida"
(`audio/cueca.ogg`) no está en la rotación; al arrancar suena una cueca de la carpeta por el bus Music, con el
loop del archivo apagado; al terminar una suena la siguiente; en 12 canciones nunca se repite una seguida y cada
vuelta del mazo toca las 4 (orden de ejemplo: nortina, puerto, emboque, chilota · nortina, chilota, puerto,
emboque · puerto, emboque, chilota, nortina); con `stop_music` no arranca la siguiente y `play_music` vuelve a sonar; el tono de
la cámara lenta (0,85) se mantiene al cambiar de canción; cada pista dura 84–100 s. **El mismo test pasa contra
el `.pck` exportado con el preset Web** (`--export-pack`): `ResourceLoader.list_directory` encuentra las 4 ahí
también. Segunda versión (la primera, sintetizada a mano y con melodías al azar, sonaba "de computador" y las 4
parecidas): melodías escritas a mano e instrumentos del SoundFont GeneralUser GS. Revisado por script: cada compás
suma 6 corcheas y cada sección tiene un acorde por compás; las notas en tiempo fuerte o largas que no son del
acorde son solo la séptima del V (el acompañamiento pasa a V7) o notas de paso en la hemiola; la segunda voz toma
la nota del acorde en tiempo fuerte. Cada parte se mezcla a un volumen fijo respecto de la melodía (por RMS),
filtro de graves a 55 Hz, RMS −17 dBFS y pico ≤ −1 dB en las 4. Espectrogramas: las 4 arrancan con 2 compases de
ritmo y la melodía entra limpia. Falta escucharlas con oído humano.

## Presentación y sonido

- **Video convertido con `tools/convertir_video.sh`** (fuente 1920×1080 a 60 fps con audio, 12 s): sale Theora 1280×720 30 fps + Vorbis 44,1 kHz estéreo; en la intro avanza a velocidad real (6,08 s a los 6 s) y al terminar (12,5 s) pasa solo al menú; resto del test de la intro igual. PASS 21/21.
- **Tráiler** (`trailer/`): grabado con `--write-movie` + el bot (13 niveles + el mapa, en es y en), 72 s
  con cortes en los tiempos de la cueca (~112 BPM; la entrada de la banda en el logo), textos que entran
  deslizándose y los efectos del juego mezclados encima. Revisado cuadro a cuadro. El bot del final se pasa
  del aterrizaje grabando a 30 fps (se usan solo sus primeros segundos).
- **Intro (video)** (escritorio con Xvfb + export web en Chromium headless, con un .ogv de prueba): arranca como escena principal, video sonando y cueca callada; una tecla en los primeros 0,35 s no salta; mensaje visible con el texto pedido; el video llena 1280×720 (16:9) y uno 4:3 queda centrado con franjas (960×720 en x=160); tecla → fundido → menú; la cueca vuelve con fundido (−36 dB → 0 dB); volver al menú desde otra escena no repite fundido ni reinicia la música; al terminar el video pasa solo al menú; clic también salta; sin video va directo al menú con música. PASS 20/20. En web: aviso "para comenzar" → video → menú, con salida de audio medida (AnalyserNode): aviso 0,0000, video 0,074, menú (cueca) 0,158; el .ogv entra al .pck. Botón Ajustes con brillo fantasma al llegar al menú (bug previo del layout, ver "Lecciones aprendidas" en `CLAUDE.md`) corregido: sin mouse encima no brilla, con el mouse encima sí, y sigue al mouse.

- **Sombras y brillos** (capturas en Forward+ y en Compatibility, el renderer de la web; 12 niveles): terreno
  con sombra y oclusión, sin franja oscura en los bordes de la pantalla; jugadores con sombra (con `grow`) y
  mancha de contacto que sigue el piso; sombra probada aislada sobre fondo claro con caja y jugador a escala 0,2
  y 0,6; fuego con brillo rojo sin rayas (tras pasar el UV por un varying), caca verde, púas con sombra. Sin
  errores de shader. Cajas con `resaltar.gdshader` en caja_2 y level_4 (también en Compatibility): se
  distinguen del terreno a simple vista. Bot: 28/29 ganados; `placa_3` da TIMEOUT **también sin estos cambios** (falla previa del bot).
- **Animaciones provisorias + toques** (capturas con Xvfb en caja_1/tronco_3): estados push/jump/fall/idle con su cuadro; inclinación al empujar; aplastón al aterrizar con los pies en el piso. El bot sigue ganando igual (son solo visuales). PASS.
- **Mirada + espejo + sonidos:** mirada/espejo, estados de animación, ~8 pasos/s, pasajero sin pasos, salto, enganche, whoosh por pasada, loop de la caja on/off, muerte sin sonido duplicado. PASS.
- **Volumen por categoría:** buses creados y enviando a Master, los tres volúmenes no se pisan, persisten en `user://settings.cfg`, Sfx y la caja usan el bus SFX. PASS.
- **Audio en el export web** (build exportado, navegador Edge headless controlado por DevTools, midiendo la señal que llega a la salida con un AnalyserNode; control: un tono de prueba da RMS 0,71): con los buses creados en runtime la salida era **0,0000** aun con el AudioContext activo tras el clic (mudo, igual que en Newgrounds); con `default_bus_layout.tres` la música da RMS ~0,1–0,2 tras el primer clic y 3 saltos en el Nivel 1 disparan 3 efectos. PASS. En el mismo build web, el menú principal sin Salir deja Jugar/Ajustes centrados.
- **Menú de pausa (diseño del equipo):** cada uno de los 7 niveles tiene exactamente un PauseMenu; Esc pausa/reanuda; foco en Continuar; los 4 botones calzan con los pintados; hover mueve el foco; Ajustes muestra sliders y oculta botones; el slider cambia SettingsManager; Volver devuelve el foco a Ajustes; Continuar reanuda. PASS 43/43. Luego se agregó P como segunda tecla (acción `pause`): P pausa y reanuda, Esc también (en `level_3`). PASS.
- **Arte (jugadores, cajas, zonas, sopaipillas, terreno, fondo, ganchos):** cada nivel cargado y capturado sin errores de script; animación de caminata a la frecuencia pedida (cambio de frame cada 12 ticks a 10 FPS con física a 120 Hz).

## Banderas de idioma

Con Xvfb (es/en): bandera de Chile junto a "Español" y del Reino Unido junto a "English" en el botón del menú
principal (con margen, sin pisar el borde dorado), en la lista de Ajustes (botón y desplegable) y en el botón de
idioma de la pausa; al cambiar de idioma con el botón del menú la bandera cambia al tiro. Los SVG (con clipPath, la
Union Jack) se dibujan bien. Sin errores de script. PASS.

## Cámara lenta más sutil (0,15 → 0,4)

`min_time_scale` 0,15 → 0,4 y `music_min_pitch` 0,7 → 0,85 (con los extremos juntos se mide time_scale 0,400 y
tono 0,850). Los planes del bot usan esperas en tiempo real, así que tres se ajustaron: `peligro_1` (largo final
180 → 175; gana con 170–190 salvo 180), `peligro_3` (la campana caía parada con la boca hacia el fondo del cuenco:
espera previa 0,6 → 0,4 s, gana con 0,2–0,5; empujón final hacia el cuenco, porque hacia atrás el jugador choca con
el escalón y el paso nunca terminaba; y J1 levanta y vuelve a dejar caer la campana si no emboca) y `final` (frenado
470 → 480; gana con 465 y 473–490: ahora es más tolerante). `run_all.sh`: 28/29 (`placa_3`, falla previa).

## Controles en la portada y en la pausa

Controles de la cuerda invertidos (soltar = T / `.`, tirar = R / `,`). En la portada (`assets/ui/portada.png` y
`assets/ui/en/portada.png`) las tapitas de esas teclas se intercambiaron píxel a píxel (el resto del dibujo intacto;
ojo: si se vuelven a cambiar, la portada hay que editarla, la pausa no). Pausa (Xvfb, tronco_1 y lanzar_1, es/en,
también con Ajustes abierto): un panel por jugador en las franjas de los costados (18..266 y 1014..1262, alto 292 con
lanzar), teclas leídas del Input Map (T/R y ./, ya invertidas), fila "Lanzar / recoger" solo en lanzar_1. PASS.

Carteles de nivel (Xvfb, es/en): tronco_2 con un cartel por jugador ("T Soltar: estira la cuerda / R Tirar:
retrae la cuerda" y lo mismo con . y , para J2) arriba de cada mitad, sin tapar el muro central ni el HUD; lanzar_1
con "G/L Recoge el emboque a la mano · Otra vez: apunta · Y otra más: ¡lánzalo!" (reemplaza el texto plano
anterior). Bot: tronco_2 y lanzar_1 ganados.

## HUD (pausa y puntaje)

Con Xvfb y capturas (peligro_1, tronco_1, lanzar_1, level_2, level_3, main): indicador de pausa en (16,14) en todos
los niveles (main incluido, sin puntaje); P lo oculta al pausar y vuelve al reanudar; clic en él pausa; Esc reanuda.
Puntaje con borde derecho en x=1264 con "Puntos: 0", "100" y "2500" (crece hacia la izquierda); en inglés "PAUSE" /
"Points: 2500"; la placa salta 1,13 → 1 en 0,3 s al sumar (escalar el ícono dentro del HBox no funcionaba: el
contenedor reinicia la escala de sus hijos). PASS 24/24. Bot: tronco_1, peligro_1, level_2, lanzar_1 ganados.

## Interfaz pulida (UiFx, botones de madera, transiciones) — PASS 36/36

Test headless del flujo (macOS, Godot 4.7.2), escuchando `Sfx.played`: con el mouse ya encima de un botón al
cargar el menú no suena hover; `ui_down` da el foco y suena `ui_hover`, un `grab_focus` por código no; el mouse
suena, le pasa el foco al botón y tiene cursor de mano; Enter en Jugar suena `ui_confirm` y funde al mapa, y un
segundo `go_to` durante el fundido se ignora (llega al mapa, no a Ajustes); al terminar el velo queda en alpha 0 y
sin bloquear el mouse; Esc en el mapa suena `ui_back` y vuelve al menú; el slider General hace tic que sube de tono
(0,90 → 1,42) y el de Efectos no (suena su muestra); Volver de Ajustes suena `ui_back`; en el nivel, P pausa con
`ui_open`, el tablero termina en su lugar, P reanuda con el sonido grave; Reiniciar suena, el juego sigue pausado
durante el fundido, recarga el nivel y queda sin pausa; Menú principal desde la pausa llega al menú sin pausa; en
la victoria el puntaje termina de contar en 300 y las sopaipillas en 2 / 3; Esc va al mapa.

Capturas (ventana, retina) de menú, mapa, Ajustes, victoria y pausa, con hover y botón apretado: canto visible,
cara hundida al apretar (texto abajo), halo dorado + borde al resaltar, perillas doradas, tablas del tema que se
aclaran y bajan 4 px apretadas, luz cálida y borde en el botón de la pausa, estrellitas tras el título de la
victoria y "¡Nuevo récord!" en dorado (antes salía blanco: el LabelSettings le ganaba al override). Los WAV `ui_*`
tienen pico −3 dB, sin NaN y terminan en silencio.

Bot (`run_all.sh`, macOS): 27/29. `caja_1` y `placa_3` dan TIMEOUT **también en `develop` sin estos cambios**
(probado en un worktree limpio en el mismo Mac); el registro de abajo (29/29) se corrió en Windows.

## Animación del emboque

Con el bot (tronco_1 + script que sigue tras ganar, en Forward+ y Compatibility): las piezas quedan pegadas
con el ángulo relativo fijo (medido en cada cuadro dibujado durante 3 s, con los jugadores caminando en
direcciones opuestas, en tronco_1, tronco_4 y peligro_2: variación del ángulo relativo 0,00° y separación
punta–cavidad constante; con el PinJoint2D anterior el ángulo giraba hasta 180°); el click de cámara se ve (zoom extra y vuelta); destello y estrellitas doradas alrededor del
emboque; confetti girando (el alto del papelito varía, `INSTANCE_CUSTOM` funciona en Compatibility) y chispas
que llegan hacia el centro y arriba; todo a velocidad real con la cámara lenta. Magnetismo más suave
(65/750/2,1): con 60/650/1,8 cinco planes del bot dejaban de embocar. Se ajustaron dos soluciones del bot que
quedaban justo en el borde: `viento_2` (cuerda de J1 200 → 215; gana con 210–220) y `placa_1` (120 → 130;
gana con 100–110 y 125–140). `run_all.sh`: 28/29 (`placa_3` sigue con su TIMEOUT previo).
Cámara lenta más fuerte (0,35 → 0,25) + música: en tronco_1 el time_scale baja suave hasta 0,25 y el tono de la
música lo sigue hasta 0,70; en la pausa vuelve a 1,00 y al reanudar a 0,70; al salir del nivel, time_scale y tono
en 1,00. Sonidos (bot en tronco_1, registrando `Sfx.played`): al embocar suenan `emboque_click` y `sparkle` y, 0,06 s
después, `confetti_pop`. Los WAV sin saturar ni NaN (pico −3 dB); el click lleva saturación suave (+6 dB de
volumen percibido con el mismo pico). Se probó y se sacó una subida de tensión con tambores (bombo y tom con
reverb, ritmo según la distancia): se va a volver a iterar. Subida de tensión (TensionFx, tronco_1 y tronco_4): la música
sigue en su volumen de Ajustes mientras se acercan y se corta justo antes del click: en tronco_1, tronco_4 y
peligro_2 empieza a caer 0,192 s (reales) antes del click, está muda (−60 dB) 0,05 s después y el click suena
tras ~0,14 s de silencio; tras el click la música sigue muda 0,4 s y vuelve en 0,3 s; los efectos bajan a −14 dB a la par; viñeta 0 → 0,70; halo de 24 a 40 px latiendo.
Cámara lenta más fuerte (0,25 → 0,15): `run_all.sh` 27/29 → `final` volvió a caer al fuego con `brake` 465 (gana
con 458–462 y 468–472: se dejó 470) → 28/29 (`placa_3`, falla previa). Al embocar: efectos en 0 dB en el mismo tick del click; viñeta y halo en 0 a los 0,3 s; la música sigue
muda 0,4 s y vuelve a su volumen a los ~1,6 s. En la pausa, música y efectos sin bajada. Capturas (tronco_1,
tronco_4): bordes oscuros y halo ceñido a los extremos. Al embocar (end_slowdown): time_scale 0,25 → 0,41 → 0,61 → 0,82 → 1,00 y tono 0,70 → 1,00 en 16 ticks
(~0,13 s), con el click de zoom a la vez (2,0 → 2,6 → 2,0) y el encuadre del closeup intacto. Ajustes del bot: `movil_4` (esperas de `drop` 0,6/0,4/0,6/0,5 → 1,0/0,6/1,2/0,8; gana con largos 160–180)
y `final` (`brake` 470 → 465). `run_all.sh`: 28/29 (`placa_3`).

## Lanzar el emboque (`test_throw.tscn`) — PASS 49/49

No toma al acortar hasta el mínimo; toma con pulsación nueva; en la mano va sin colisiones y pegado a la mano al caminar; apuntando no camina ni salta pero gira; la mira va de 0 a 60° y vuelve; soltar restaura todo sin alargar la cuerda; vuelo recto con desvío 0 px hasta 320 px; choca con la torre sin atravesarla; el mejor salto queda 40 px bajo el techo de la torre; cada jugador lanza a su gancho → sube → queda arriba de la torre; un extremo en la mano no emboca ni activa el closeup (con control); sin `LevelRules` no hay mecánica. Desde el mejor lugar (~150–200 px del gancho) sirve una ventana de ~10° del barrido.

**Recoger con `lanzar`** (test_throw, headless): colgando → en la mano en 0,06 s; ciclo con la misma tecla
(recoger → apuntar → lanzar → recoger en vuelo → en la mano); tras aterrizar a 197 px → en la mano en 0,10 s; el
jugador no se mueve (0,0 px) al recoger; `soltar` corta la recogida y la cuerda queda del largo actual; extremo
trabado (congelado) → deja de recoger a los 0,23 s sin arrastrar al jugador; enganchado, `lanzar` no hace nada; sin
`LevelRules` no hace nada. PASS 20/20. Bot: lanzar_1..4 y viento_2 ganados; `final` cae al fuego (Palito@PitFire,
t=10,96) igual con el código anterior: falla previa del bot, no de esta mecánica.

## Nivel 2 (`level_2.tscn`) — PASS 27/27

Rojo mata al jugador y no al emboque; naranja mata a ambos; el muro no se salta por arriba; extremos y jugadores recogen. Rutas: J1 baja con cuidado a la izquierda del rojo, engancha el gancho de abajo (tirar al mínimo, soltar un poco y volver a tirar) y se balancea hasta la T en 10/12 combinaciones largo/ángulo; J2 acorta la cuerda, corre a la izquierda, el palito engancha el gancho derecho y salta a la T en 4/4 ángulos; con la cuerda a 170 el palito roza el bloque naranja; desde la T los extremos cuelgan bajo el muro, se juntan a 5 px y recogen los 2 coleccionables de abajo.

## Tandas 2 y 3, y arreglos de peligro_3 y caja_1

`run_all.sh` 29/29; `run_controls.sh` 42/42. Mono (700–800 s por prueba) sin atajos, salvo lo anotado.

| Nivel | Gana | Notas |
|---|---|---|
| peligro_3 | 10–32 s | escalón de 113 px, todo con cuerda 60; 8 de 8 |
| caja_1 | 12 s | caja de 120, pared de 250, todo con cuerda 60; sin caja el mono no sube en 1500 s |
| caja_3 | 27 s | sin la caja chica o sin la grande no se llega |
| lanzar_2 | 13 s | mira 22–35° |
| lanzar_4 | 17–25 s | 14 de 18; sin lanzar el mono ganó una vez en 590 s partiendo en la meta |
| placa_2 | 24 s | 6 de 6; con el extremo en la placa y a la carrera el mono cruzó una vez sin tocar la cuerda (671 s) |
| placa_3 | 17–23 s | 6 de 9; sin la placa de la meta el mono no gana |
| movil_2 | 29–48 s | cuerda 170–210 (con 140 no); con J2 quieto se gana (J2 solo viaja) |
| viento_2 | 27–36 s | J1 260–320 con J2 110–190; sin viento no |
| viento_4 | 24 s | los dos a la vez; sin balancearse no (con ráfagas de 1,3 s se ganaba solo) |
| final | 26 s | sin lanzar, sin ascensores o sin ráfaga no se pasa; nadie cruza |

## Tanda 1 de los niveles que faltaban

`run_all.sh` 29/29; `run_controls.sh` 29/29 (ningún control se gana). Mono (1000–1200 s por prueba): ningún atajo salvo
tronco_2, que sin cuerda ganó una vez en 436 s (el palito se balancea por debajo del muro hasta la campana); se dejó.

| Nivel | Gana | Notas |
|---|---|---|
| tronco_2 | 12–18 s | J1 285–320 y J2 85–100; con J2 en 120 no |
| tronco_4 | 18 s | 4 pares de largos (140/280 a 180/320); a veces basta con J2 |
| peligro_1 | 25–32 s | 5 de 6; con cuerda 150 no se juntó en 60 s |
| peligro_3 | 15–18 s | cuerda 100–155, los dos a la vez |
| caja_1 | 17–36 s | 6 de 6; paredes de 250 (con 200 se saltaban) |
| level_4 | 20–34 s | 5 de 6 |
| lanzar_1 | 20 s | mira 8–16° con cuerda 65–80; 4–12° con 100 |
| placa_1 | 11–13 s | 6 de 6; sin una de las placas de la meta el mono no gana |
| movil_1 | 25 s | 6 de 6 |

Prototipos (fuera del repo): mecedora (vaivén 80–100 px), bandera (cuerda 220–280 según J2) y ráfagas hacia adentro
(fuerza 350 + balanceo) se ganan; "al pasar" todavía no.

## Segundo pase de las zonas de emboque (tras el playtest) y escala 0,8

`run_all.sh` 29/29; `run_controls.sh` 14/14; `run_shortcuts.sh`: ningún atajo (1000–3000 s de mono por prueba).
Las pruebas de peligro_2, caja_2, lanzar_3, placa_4, movil_3, viento_1 y viento_3 de la tabla de más abajo son de la
versión anterior de esos niveles.

Antes de rehacerlos, confirmado con el bot: peligro_2 se ganaba sin tocar la cuerda en 4,7 s; lanzar_3 se cruzaba
saltando (cuerda 60); placa_4 se ganaba sin el gancho central en 7 de 9. Alcance del salto corriendo (misma altura):
380 / 339 / 314 / 410 / 401 px con cuerda 60 / 120 / 170 / 240 / 320; alto 139–151.

| Nivel | Gana | Atajos probados (no se gana / no se llega) |
|---|---|---|
| peligro_2 | 33 s; m 30–70 con cuerda 140 | sin cuerda, 3 × 3000 s |
| caja_2 | 43 s; asomar 10–44 px | sin cajas; sin dos de las tres; sin las de arriba (con 200 px de pared SÍ se saltaba: quedó en 250) |
| lanzar_3 | 29 s; mira 2–6° | sin lanzar y sin gancho, en cada repisa |
| placa_4 | 29 s; saltar entre 520 y 565 | sin gancho central, 2000 s; balanceándose desde las islas tampoco |
| movil_3 | 20 s; cuerda 140–220, vaivén 40–80 | — (sin cuerda el mono ganó 1 vez en 215 vidas, cayendo los dos) |
| viento_1 | 15 s | sin viento; sin el segundo chorro |
| viento_3 | 17 s; J1 110–150 con J2 110–145 | sin viento; un chorro sin esperar; con viento en contra el salto muere (3/3) |

Nuevo en la caja: en el aire no se empuja; quien empuja se detiene en el borde. Una caja de caja_2 empujada al hoyo de la
izquierda vuelve arriba y J2 no cae tras ella. caja_1, caja_3, level_4 y placa_3 se siguen ganando. Closeup a escala 0,8
revisado en captura (emboque del mismo tamaño).

Mono sobre los que faltan (700 s): atajos en **viento_2** (sin viento, 44 s), **lanzar_2** (sin lanzar) y **caja_1** (sin
caja); ninguno en tronco_4, peligro_3, caja_3, lanzar_1, lanzar_4 y viento_4.

## Zonas de emboque nuevas (9 niveles de muestra) y bonos de estilo

`run_all.sh` 29/29; `run_controls.sh` 13/13 (ningún control se gana). Barridos con el bot (gana = se puede ganar):

| Nivel | Gana | Quietos | Uno solo | Notas |
|---|---|---|---|---|
| tronco_3 | 14 s | no | a veces (J1 sí, J2 no) | largos 130–210; con pump 1,2 embocó de rebote al llegar |
| peligro_2 | 9 s | no | sí (9 s / 43 s) | cuerda < 185 se traba en el diente; balancear con 180 en la meta toca la caca |
| caja_2 | 25 s | no | a veces (J2 sí, J1 no) | sin asomar (0/10/20 px) no gana; 35–52 gana; 57 el jugador se cae |
| placa_4 | 25 s | no | no | gancho en y 580/600/620; balanceos de 60 px 9/9, de 30 px 4/9 |
| movil_3 | 20 s | no | no | largos 120–240 |
| movil_4 | 36 s | no | no | largos 180–240; con 120 un jugador se cae |
| lanzar_3 | 18 s | — | — | 10 de 18 combinaciones ángulo × largo; con cuerda 110 y 2–6° al primer tiro |
| viento_1 | 16 s | no | no | viento 1600: 4/4; 1800: 3/4 y más lento |
| viento_3 | 10 s | — | — | solo con J1 en 130–140 (110–120 y 155 no) y J2 en 80–125 |

Nadie cruza al lado del otro (caminando o saltando en 3 puntos) en tronco_3, lanzar_3, placa_4, movil_3, caja_2 ni
viento_1. La caja de caja_2 empujada al foso cae y reaparece en (470, 168). Bonos en las 29 soluciones: "¡Limpio!" en
6, "¡Al vuelo!" en 11; texto revisado en captura.

## Bot tras suavizar la cámara lenta: `level_4` corregido (Windows)

Con `min_time_scale` 0,4, en Windows, `placa_3` **se gana** (13,75 s; la falla previa anotada en otras entradas ya no
ocurre) y `level_4` daba TIMEOUT (siempre, en 4 corridas): cambiando solo ese valor sobre el commit `345a912` se
reproducen los dos cambios. Causa: la campana quedaba apoyada en la repisa, al borde de la ranura (603, 88). El plan
ahora la arrastra de a poco hasta que cae, y J2 espera su turno en el segundo escalón (arriba, los extremos se juntaban
en la repisa sin usar el cuenco). Gana con pasos de 9–16 px (6 y 8 no alcanzan), largos 140–180, retroceso 15–40 y
cámara lenta 0,15 / 0,25 / 0,4 / 0,6 / 1,0. `run_all.sh`: **29/29**.

## Niveles del mapa (bot, `tests/run_all.sh`) — 29/29 ganados

Cada nivel se gana con el plan de `tests/solutions/<nivel>.gd` (además se barrieron parámetros: largo de cuerda,
ángulo de lanzamiento, bombeo, punto de salto; y se probaron "controles" que deben fallar). Resumen:

| Nivel | Tiempo | Controles que fallan (como debe ser) |
|---|---|---|
| tronco_1..4 | 5–15 s | T2: sin ajustar largos no se juntan; T3: el salto directo no cruza (el extremo engancha solo) |
| peligro_1 Púas | 19 s | — (sopaipillas en zanjas de púas que solo el emboque alcanza) |
| peligro_2 Cuidado abajo | 8 s | (nivel anterior) quedarse en el borde con cuerda 170, o bajar el extremo de más → caca |
| peligro_3 Brasas | 9 s | cuerda 90–170 sobre las brasas → el extremo se quema; cuerda 60–100 no sube el escalón |
| level_2 La T (equipo) | 24 s | cuerda 120 de J2 → el palito toca el bloque de fuego |
| caja_1..3 | 8–14 s | caja_3: si J2 sigue la caja al piso de J1, su extremo cae a la caca |
| level_4 Escalones (equipo) | 20 s | caja empujada a <30 px de la plataforma → el salto choca con ella (gana con largos 140–180 al bajar al cuenco) |
| placa_1..3 | 6–12 s | — |
| placa_4 Relevo | 18 s | J2 fuera de su placa → la puerta de J1 no abre y no pasa; gana con bombeo 1,3 y 1,6 |
| movil_1..3 | 8–17 s | movil_2: cuerda 170 en la plataforma → caca |
| movil_4 Contratiempo | 25–30 s | cuerda 110 o 170 → el extremo cuelga al fuego con el ascensor abajo; cruzar al final de la pausa → al fuego |
| lanzar_1..3 | 6–10 s | lanzar_3: sin acortar al soltarse, el extremo cuelga al fuego |
| lanzar_4 Buzón | 14 s | lanzar a 12° o más (desde 250 px) pega sobre la ranura: la compuerta de J2 no abre; gana lanzando de 130 a 310 px y con 0–8° |
| viento_1..3 | 5–10 s | — |
| viento_4 Remonte | 12 s | pararse 50 px al lado del gancho → el extremo sube derecho y no engancha; gana en 8 de 9 variantes (bombeo 0,9–1,6, posición ±12 px, punto de salto) |
| final | 10–15 s | el punto de frenado del bot depende de la cámara lenta (0,35: 465–470; 0,25: 464–466; 0,15: 458–462 y 468–472; 0,4: 465 y 473–490, se usa 480) → si no, fuego (el humano corrige en el aire) |

También: mapa (desbloqueo, foco inicial en lo recién desbloqueado, F9), flujo completo menú → mapa → nivel →
victoria → Continuar → mapa con el siguiente desbloqueado (PASS); compuerta no aplasta; capturas de cada nivel
revisadas.

## Recorridos nuevos (13 niveles, tras el feedback de las tandas 2 y 3)

`run_all.sh`: **29/29**. `run_controls.sh` en los 13: 13/13 OK (ahora con 90 s: placa_3 llega a la meta a los ~50 s y con 45 s
el control no probaba nada). Mono tramposo, 900 s por opción (38 opciones): sin atajos en la versión final.

| Nivel | Tiempo del bot | Atajos encontrados y corregidos |
|---|---|---|
| peligro_1 | 32 s | — |
| peligro_3 | 20 s | — |
| caja_1 | 24 s | — |
| caja_3 | 41 s | — |
| level_4 | 30 s | — |
| lanzar_1 | 16 s | el pasillo de caca se cruza tomando el extremo con `tirar` (válido); sin tomarlo, no (600 s) |
| lanzar_2 | 18 s | — |
| lanzar_4 | 43 s | — |
| placa_1 | 20 s | — |
| placa_2 | 36 s | — |
| placa_3 | 55 s | — |
| movil_1 | 40 s | la plataforma de J2 se saltaba (foso de 300): ahora 360 y la llegada 98 px más arriba |
| movil_2 | 44 s | la primera plataforma de J1 se saltaba (foso de 290): ahora 335 y 80 px más arriba |

El bot no pasa por todas las sopaipillas (faltan 1–4 por nivel): no se comprobó una por una que se alcancen.
movil_2 se gana con 11 de 16 combinaciones de vaivén (40/55 px, cuerda 170/200, espera 0–1,2 s).

## Salto nuevo y tipo de peligro (tras el feedback de los recorridos)

- **Salto** (headless, `jump_velocity` 470, cuerda 60 / 110 / 170 / 240 / 320, parado y corriendo): 115 px de alto, 315 de largo y
  0,98 s en los 10 casos. Antes (680): 139–239 px de alto y 297–379 de largo según la cuerda.
- **Extremo al saltar corriendo** (cuánto sube sobre el piso): 60 → 106, 110 → 78, 170 → 57, 240 → 38 px. Nunca por encima del jugador.
- **Bot:** `run_all` 29/29 (470). Los niveles rehechos se ganan también con 465 y 475, salvo alguna corrida (errores del bot al
  aterrizar: peligro_1 con 465, placa_1 con 474 y 478).
- **Controles:** todos OK. Se ajustaron tronco_3 (hueco 130), viento_1 (columna 84) y viento_4 (S 196), que con la cuerda nueva se
  ganaban con alguien quieto.
- **Mono** (500 s × 65 opciones; 1000 s en 11 niveles rehechos): sin atajos en los rehechos. En viento_4, sin la segunda corriente
  se llegaba igual (se acortó la primera: ya no); sin ráfagas, una victoria en 445 s cayendo los dos al fuego (azar).
- **Auditoría `--hazards`** (púas sin extremo / cacas sin jugador): ninguna en peligro_3, lanzar_2 y movil_2; en el resto quedan
  fosos y púas que solo cuidan del jugador.
- **Largo de cuerda que pide cada tramo** (bot, barrido 60–300): peligro_3 J1 ≥ 190 y J2 ≥ 150; placa_1 ≥ 150; placa_2 J1 ≥ 150;
  movil_2 J1 ≥ 150 y J2 ≥ 180. Con 60 mueren todos.

## Salto variable (termina al soltar la tecla)

- **Alto / largo según cuánto se mantiene la tecla** (corriendo; igual con cuerda 60 y 200): 0,02 s → 11 / 93 px; 0,05 → 25 / 125;
  0,1 → 44 / 163; 0,15 → 61 / 192; 0,2 → 76 / 216; 0,3 → 98 / 256; 0,5 → 115 / 315. El extremo nunca pasa por encima del jugador.
- **Púas con caca colgando** (barrido de cuerda 60 / 110 / 220 × tecla 0,07–0,5 s, en peligro_3, lanzar_2, lanzar_4, placa_2 y los dos
  lados de movil_2): con 60 no se pasa con ninguna duración (antes de subir las púas a 45 px, un salto de 44 px pasaba); con 110,
  solo con un salto medio justo; con 220 se pasa.
- **Bot** 29/29; **controles** OK; **mono** (500 s × 65, también con saltos cortos): sin atajos, salvo viento_4 sin ráfagas (embocan
  cayendo los dos, por azar; ya pasaba).

## Recorridos de los 11 niveles que faltaban (tronco_1, 2 y 4, level_2, lanzar_3, placa_4, movil_3 y 4, viento_1 y 4, final)

- **Bot** 29/29. **Controles** con 60 s (antes 90: en movil_4, uno solo llega a ganar tras 30–40 s de balancearse sin parar).
  **Mono** 400 s por opción en los cambiados (lanzar_3 y tronco_4, 300): sin atajos, salvo viento_4 sin ráfagas
  (azar, ya pasaba). Encontró que en movil_3 J2 podía caer sin su plataforma: corregido.
- **Púas con caca colgando** (level_2, lanzar_3, placa_4, movil_3, movil_4, viento_1, final): con cuerda 60 nunca se pasa; con 110 solo
  en level_2 (según el despegue); con 190–230 se pasa.
- **Botones de techo de viento_4:** con cuerda 60 y 110 no se aprietan; con 170–235, sí.
- **Auditoría de peligros** (`--hazards`) en los cambiados: solo quedan las púas con sopaipilla (level_2, movil_4), las de las paredes del
  ascensor de movil_4 y el piso de púas bajo el carro de movil_3.
- **Margen de salto** (460–480): el bot pierde en tronco_4 a 480 (gancho), placa_4 a 475, movil_3 a 460–465, level_2 a 465 y el
  final a 460–465 (trapecio); en el resto gana.

## Iteración tras el feedback (tronco_1 y 2, peligro_2, caja_1, placa_3, placa_4, movil_1, viento_1)

- **tronco_1** vuelve a la versión original (gana; controles con un jugador quieto ganan: es a propósito, nivel introductorio).
- **tronco_2** más fácil: islas de 100 px, suelo bajo las primeras de J1 y bajo la bajada de J2. Mono `--goal` (cruzar): no.
- **placa_4:** ganchos a escala 2 e islas a 190 px del gancho del trapecio. Punto de salto que engancha el trapecio: de 40 px
  (530–570, solo el borde) a 90 px (520–610); columpio lateral de 60 a 80 px. Mono: sin atajos.
- **viento_1:** columna de la meta de 84 a 74 px. Barrido de 9 variantes de balanceo: 84 px → 6/9; 74 → 9/9. Con J2 quieto, J1
  solo emboca tras ~6 s de balancearse (control "2" sacado); con 60–66 px emboca uno solo casi sin balancearse.
- **peligro_2:** la caca del pasillo pasa a fuego (mismo comportamiento: los jugadores nunca bajan al pasillo). Gana; controles OK.
- **caja_1** rehecho. Escalera de cajas de J1: sin la caja chica, el mono no sube el muro (400 s); sin la grande de J2, tampoco.
  Cruce en la meta (`--start` en las repisas): no. Encontrado al rehacerlo: en la versión vieja un jugador que cae de la punta
  interior de su repisa podía llegar al lado del otro (muros guardia).
- **placa_3:** escalones de J1 (`--no=rope`: el mono no pasa de ellos) y botón entre púas de J2 (`--remove=PlateC`: no llega
  arriba). Gana en 63 s.
- **movil_1:** botón en el fuego de J2 (`--remove=PlateF`, `--no=rope`: no). El mono encontró que desde la nueva isla se saltaba
  a la isla B sin la plataforma: techo sobre la isla B, y ya no. Sin recoger la cuerda tras el botón, el extremo se quema bajo la
  plataforma (cuerda 140 y 215); con 100 pasa. El botón pide cuerda ≥ ~190.
- **Bot** 29/29; **controles** todos OK; auditoría: quedan la púa de isla de caja_1, la caca de la plataforma de movil_1 (el
  fuego de abajo castiga antes la cuerda larga) y las del pasillo de placa_3 (son para la campana).
