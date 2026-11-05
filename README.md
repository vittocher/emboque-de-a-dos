# emboque-de-a-dos

Repositorio del juego "Emboque de a Dos" para el curso IIC3686

Engine: Godot 4.7

Puzzle cooperativo local para 2 jugadores: cada uno lleva media mitad de un emboque colgando de una cuerda, y el objetivo de cada nivel es juntar el palito con la campana.

## Cómo jugar

1. Abrir Godot **4.7.2** e importar el `project.godot` de esta carpeta desde el Project Manager.
2. **F5** para jugar desde el menú principal, o abrir un nivel (`scenes/main.tscn`, `scenes/level_2.tscn`, …) y **F6** para probar solo ese nivel.

## Controles

| | Mover | Saltar | Soltar cuerda | Tirar cuerda | Desengancharse | Lanzar* |
|---|---|---|---|---|---|---|
| **Jugador 1** (campana) | `A` / `D` | `W` | `R` | `T` | `S` | `G` |
| **Jugador 2** (palito) | `←` / `→` | `↑` | `,` | `.` | `↓` | `L` |

\* Solo en los niveles marcados en verde en el selector. **Esc** o **P** pausa.

## Para desarrollar

- [`CLAUDE.md`](CLAUDE.md): guía técnica (arquitectura, cómo armar un nivel, lecciones aprendidas, registro de tests).
- [`GUIA_ASSETS.md`](GUIA_ASSETS.md): cómo reemplazar placeholders por arte.
- Todo el arte va en `assets/`.
