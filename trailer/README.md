# trailer/

Tráiler del juego (~72 s, 1280×720, 30 fps), con la cueca del juego de fondo:

- `trailer_es.mp4` — en español.
- `trailer_en.mp4` — en inglés (mismas escenas, juego y textos en inglés).

Todo el gameplay es **del juego real**: lo juega el bot de pruebas (`tests/solutions/`)
y lo graba el *Movie Maker* de Godot cuadro a cuadro, con sus efectos de sonido. La
música se monta aparte, entera, y cada corte cae en un tiempo de la cueca (~112 por
minuto); la entrada de la banda coincide con el logo.

## Guion

| Tiempo | Escena | Texto |
|---|---|---|
| 0:00 | Tarjeta con el palito y la campana | "Un juguete chileno de toda la vida..." |
| 0:04 | Primer emboque (closeup en cámara lenta) | AHORA, DE A DOS |
| 0:10 | Logo (portada) con destello al entrar la banda | Puzzle cooperativo para 2 jugadores |
| 0:15 | Cuerda larga | LA CUERDA LO ES TODO |
| 0:19 | Colgados (columpio) | BALANCÉATE |
| 0:23 | Al aire (lanzar y trepar) | LANZA EL EMBOQUE |
| 0:28 | Púas (cuenco sobre púas) | CUIDADO ABAJO |
| 0:32 | Relevo (placas y puertas) | UNO ABRE, EL OTRO PASA |
| 0:36 | Andén (ascensores) | TODO SE MUEVE |
| 0:40 | Volantín (viento) | COMO UN VOLANTÍN |
| 0:44 | Escalones: emboque en cámara lenta | ¡EMBOQUE! |
| 0:51 | Tarjeta: la idea en 3 frases | "...que solo se resuelve de a dos" |
| 0:57 | Mapa de niveles | 28 NIVELES |
| 1:01 | Cortes rápidos (cajas, buzón, remonte, final) | — |
| 1:05 | Cierre: logo, "Cooperativo local · 2 jugadores · 1 teclado" | PRÓXIMAMENTE |

## Rehacerlo (p. ej. cuando llegue el arte definitivo)

```bash
GODOT=/ruta/a/godot trailer/make_trailer.sh es
GODOT=/ruta/a/godot trailer/make_trailer.sh en
```

Graba los niveles (unos 10 min), genera las tarjetas y monta el video. Necesita
Godot 4.7, ffmpeg y Python 3 con Pillow (en Windows, desde Git Bash o WSL). Lo
intermedio queda en `build/trailer/` (no va al repo).

- **Textos** (cada idioma): `TEXTS` en `cards.py`.
- **Escenas, orden y duración** (en tiempos de la música): `EDL` en `edit.py`.
- **Volumen** de música y efectos: `MUSIC_GAIN` / `SFX_GAIN` en `edit.py`.
- Si se cambia la música, ajustar `BEAT` (duración de un tiempo) y `DROP` (segundo
  en que entra la banda) en `edit.py`.

La carpeta tiene un `.gdignore` (Godot no la importa) y está fuera del export.
