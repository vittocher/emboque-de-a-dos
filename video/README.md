# video/

Videos del juego. Hoy solo la **intro** (la historia), que se reproduce cada vez que
arranca el juego (`scenes/ui/intro.tscn` + `scripts/ui/intro.gd`) y se salta con
cualquier tecla.

## Agregar el video (3 pasos)

1. **Convertirlo**: arrastrar el video terminado (mp4, mov, webm…) sobre
   **`tools/convertir_video.bat`** (Windows). Crea `video/intro.ogv` listo para Godot.
   - Si dice que falta ffmpeg: `winget install Gyan.FFmpeg` y volver a intentar.
   - Mac/Linux: `tools/convertir_video.sh mi_video.mp4`.
2. **Abrir el proyecto en Godot** (genera `video/intro.ogv.uid`) y probar con F5.
3. **Commit** de `video/intro.ogv` y `video/intro.ogv.uid` (el mp4 original no se
   sube: lo ignora `video/.gitignore`).

Nada más: la intro lo encuentra sola. Si el archivo no está, el juego pasa directo
al menú (y si hay un mp4 en esta carpeta, la consola de Godot avisa cómo convertirlo).

## Formato

`video/intro.ogv` — **Ogg Theora** (video) + **Vorbis** (audio). Es el único formato
de video que Godot 4 reproduce: un `.mp4`, `.mov` o `.webm` no sirve tal cual. El
conversor lo deja así:

- máximo **1280×720** (la resolución del juego), sin deformar: si el video no es
  16:9 se muestra con franjas negras;
- **30 fps** (en web el navegador decodifica el video; más fps solo pesa más);
- calidad de imagen **7** de 10. Se puede cambiar con un segundo argumento:
  `tools\convertir_video.bat mi_video.mp4 6` (más bajo = pesa menos). Para web
  conviene que el `.ogv` pese pocos MB (se descarga antes de jugar): un video
  de 1 minuto a calidad 6–7 queda en ~10–20 MB.
- audio Vorbis estéreo 44,1 kHz. La música del juego (cueca) se calla durante la
  intro y entra con un fundido al llegar al menú, así que el video puede traer su
  propia canción.

Probado (con un video de prueba 1920×1080 a 60 fps convertido con el script): se
reproduce a velocidad real, una tecla lo salta, al terminar pasa solo al menú.

Comando equivalente, por si se quiere convertir a mano:

```bash
ffmpeg -i mi_video.mp4 -vf "scale=1280:720:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30" -pix_fmt yuv420p -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 -ar 44100 -ac 2 video/intro.ogv
```

## Ajustes

En la escena `scenes/ui/intro.tscn` (nodo raíz `Intro`, Inspector): ruta del video,
bus de audio (Master), tiempos de fundido y cuándo aparece el mensaje para saltar.
