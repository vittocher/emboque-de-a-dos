@echo off
rem ============================================================================
rem  Convierte el video de la intro al formato que lee Godot: video\intro.ogv
rem  (Ogg Theora + Vorbis, 1280x720 como maximo, 30 fps).
rem
rem  Uso: ARRASTRAR el video (mp4, mov, webm, mkv...) sobre este archivo.
rem       o desde una consola:  tools\convertir_video.bat C:\ruta\mi_video.mp4 [calidad]
rem  calidad (opcional): 0 a 10, por defecto 7 (mas alto = se ve mejor y pesa mas).
rem
rem  Necesita ffmpeg. Si no esta:  winget install Gyan.FFmpeg   (y abrir otra consola)
rem ============================================================================
setlocal
if "%~1"=="" (
	echo Arrastra el video sobre este archivo para convertirlo.
	pause
	exit /b 1
)
where ffmpeg >nul 2>nul
if errorlevel 1 (
	echo No encuentro ffmpeg. Instalalo con:  winget install Gyan.FFmpeg
	echo y vuelve a intentarlo en una consola nueva.
	pause
	exit /b 1
)
set "QUALITY=%~2"
if "%QUALITY%"=="" set "QUALITY=7"
set "OUT=%~dp0..\video\intro.ogv"
echo Convirtiendo "%~1" a "%OUT%" ...
ffmpeg -hide_banner -loglevel warning -stats -y -i "%~1" ^
	-vf "scale=1280:720:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30" ^
	-pix_fmt yuv420p -c:v libtheora -q:v %QUALITY% -c:a libvorbis -q:a 5 -ar 44100 -ac 2 "%OUT%"
if errorlevel 1 (
	echo.
	echo Algo fallo al convertir. Revisa el mensaje de arriba.
	pause
	exit /b 1
)
echo.
echo Listo: video\intro.ogv
echo Abre el proyecto en Godot (para que genere intro.ogv.uid) y haz commit de los dos archivos.
pause
