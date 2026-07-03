# ORBIT 🪐

Arcade espacial de **un solo botón** (interfaz del juego en inglés). Tu cometa gira alrededor de un planeta; toca para soltarte por la tangente y deja que la gravedad del siguiente planeta te capture. Encadena saltos, sube lo más alto que puedas y no te detengas: **toda órbita decae**.

## Cómo jugar

- **Abrir**: doble clic en `index.html` (no necesita servidor ni instalación), o sirve la carpeta con `python3 -m http.server` para probar en el celular.
- **Un solo control**: clic / tap / `ESPACIO` para soltarte de la órbita.
- `P` o `Esc` pausa · `M` silencia · el juego se pausa solo si cambias de pestaña.

## Mecánicas

| Elemento | Qué hace |
|---|---|
| **Decaimiento orbital** | Tu órbita se encoge; si acampas, te consumes en la atmósfera |
| **Combo** | Salta antes de 1,5 s en cada planeta para encadenar ×2, ×3… (multiplica estrellas, tope ×10) |
| **Estrellas ✦** | +30 pts × combo, colocadas en los corredores de vuelo |
| **Asteroides guardianes** (250 m+) | Rocas que patrullan el anillo y te cazan mientras orbitas |
| **Planetas errantes** (600 m+) | Se desplazan lateralmente mientras apuntas |
| **Estrellas inestables** (1 100 m+) | Explotan 2,4 s después de que aterrizas |
| **Agujeros negros** (1 800 m+) | Curvan tu trayectoria en vuelo; su núcleo te devora |

Puntuación = altura en metros + estrellas. El récord se guarda en el navegador.

## Técnica

- Un solo archivo `index.html`: canvas 2D, física con substeps a 120 Hz, cero dependencias.
- Sonido sintetizado en tiempo real con WebAudio (sin assets).
- Asistencia de puntería sutil en vuelo para que capturar se sienta justo sin regalar la partida.
- Responsive: columna de juego escalada, funciona en móvil (tap) y escritorio.
- API de depuración en consola: `GAME.stats()`, `GAME.start(metros)`, `GAME.setAutopilot(true)`, `GAME.setTurbo(n)`, `GAME.kill()`.
