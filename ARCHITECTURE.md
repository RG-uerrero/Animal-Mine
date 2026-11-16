# Organizacion del juego

La separacion por componentes sigue la idea de BEM: cada bloque tiene una responsabilidad y sus elementos internos. En Luau se expresa con ModuleScripts y contexto explicito, sin introducir nombres CSS en los objetos de Roblox.

## Donde editar

| Archivo o componente | Responsabilidad |
| --- | --- |
| src/server/World.luau | Compone las zonas del mundo en orden |
| src/server/Components/Landscape.luau | Suelo, vegetacion, plaza y bienvenida |
| src/server/Components/MinePlots.luau | Base de mina, banco, gerentes, botones y tuneles |
| src/server/Components/SkillWorkshop.luau | Taller y plataformas de habilidades |
| src/server/Components/TeleportStation.luau | Botones de teletransporte |
| src/server/Components/RebirthStation.luau | Plataforma de renacimiento |
| src/server/Components/Clouds.luau | Construccion de nubes; Main actualiza su movimiento |
| src/server/Components/Fountain.luau | Fuente, agua y particulas |
| src/server/Components/SpawnPoint.luau | Punto de aparicion |
| src/server/Components/WorldLighting.luau | Iluminacion y atmosfera |
| src/server/Builders.luau | Primitivas visuales y modelo de arbol |
| src/server/AnimalModels.luau | Geometria de mineros y gerentes |
| src/server/Main.server.luau | Coordina reglas, estado, eventos y ciclo de jugadores |
| src/server/DataService.luau y SessionStore.luau | Almacenamiento y propiedad de la sesion |
| src/shared/Config.luau | Constantes y balance |
| src/shared/Formulas.luau | Calculos puros de economia |
| src/shared/WorldText.luau y LabelLayout.luau | Estilo y distribucion de etiquetas |
| src/client/Hud.client.luau | Interfaz y respuesta a datos replicados |
| src/client/WorldLabels.client.luau | Visibilidad de etiquetas y exclusion del HUD |

## Convenciones

- camelCase: variables de trabajo, parametros y funciones. Ejemplos: playerState, createPart, updateMinerLabel.
- PascalCase: servicios y modulos. Ejemplos: Players, ReplicatedStorage, MinePlots.
- LOUD_SNAKE_CASE: constantes y parametros fijos del balance. Ejemplos: MINER_COUNT, MAX_MINER_LEVEL, PRODUCTION_SCALE.
- Los comentarios explican responsabilidad, requisitos y unidades.
- Cada componente del mundo expone build(context); WorldLighting expone apply().
- context.handlers contiene las acciones del servidor. Los componentes construyen la vista y conectan esas acciones; no deciden precios ni recompensas.

## Compatibilidad

Los nombres de piezas, atributos, RemoteEvents y campos persistidos conservan su contrato. Campos historicos como sh, sk, mg, eq y pr mantienen su nombre para leer partidas anteriores. Las propiedades de Roblox conservan la escritura que exige su API. Estos nombres no se deben cambiar con una sustitucion global.

Las coordenadas y tamanos de los componentes proceden del constructor anterior. En MinePlots, cx y cz son el origen de cada parcela; los desplazamientos son relativos a ese origen. Mantener el orden de construccion conserva tambien la secuencia aleatoria de la decoracion.

Main sigue siendo el coordinador de las reglas del juego y HUD el coordinador de la interfaz. La separacion implementada extrae los bloques del mundo y la iluminacion; no convierte estos coordinadores en un sistema ECS.

La tabla tools/naming-map.json documenta las equivalencias de identificadores anteriores y actuales; no participa en la ejecucion del juego.
