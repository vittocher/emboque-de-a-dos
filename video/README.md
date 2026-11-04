# video/

Videos del juego. Hoy solo la **intro** (la historia), que se reproduce cada vez que
arranca el juego (`scenes/ui/intro.tscn` + `scripts/ui/intro.gd`) y se salta con
cualquier tecla.

## Archivo esperado

`video/intro.ogv` — **Ogg Theora** (video) + **Vorbis** (audio). Es el único formato
de video que Godot 4 reproduce: un `.mp4`, `.mov` o `.webm` no sirve tal cual.
Si el archivo no está, el juego pasa directo al menú principal.

## Cómo convertir el video (ffmpeg)

```bash
ffmpeg -i mi_video.mp4 -vf "scale=1280:720:force_original_aspect_ratio=decrease" -r 30 -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 -ar 44100 video/intro.ogv
```

- `scale=1280:720` = resolución base del juego (más grande solo pesa más; en web
  el video se decodifica en el navegador y 1280×720 a 30 fps es lo razonable).
- `-q:v` va de 0 a 10 (calidad de imagen); 6–8 es buen equilibrio con el peso.
- Si el video no es 16:9 se muestra con franjas negras, sin deformarse.

En Windows, ffmpeg se instala con `winget install ffmpeg`.

## Ajustes

En la escena `scenes/ui/intro.tscn` (nodo raíz `Intro`, Inspector): ruta del video,
bus de audio (Master), tiempos de fundido y cuándo aparece el mensaje para saltar.
