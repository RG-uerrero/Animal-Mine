# Verificacion de la primera etapa

El cambio conserva DATA_VERSION y los almacenes existentes. No reinicia partidas.
La nueva propiedad interna _session evita que dos servidores escriban el mismo perfil.
Se renueva con cada guardado (cada 60 segundos) y se libera con el guardado de salida.
Si un servidor cae sin liberar, otro puede recuperar el perfil tras 180 segundos sin renovacion.
Durante un despliegue conviene cerrar los servidores de la version anterior: estos no conocen el bloqueo.

## Pruebas automatizadas

El ejecutor tests/run.mjs usa luau-web y no necesita Roblox ni acceso a datos reales.
Instalar luau-web en una carpeta temporal y pasar la ruta absoluta a su src/index.js:

~~~powershell
npm install --prefix "$env:TEMP/animal-mine-validation" --no-audit --no-fund luau-web
node tests/run.mjs "$env:TEMP/animal-mine-validation/node_modules/luau-web/src/index.js"
~~~

Ejecutar desde la raiz del proyecto. Verifica sintaxis de todos los archivos Luau,
el almacen de sesiones con fallos simulados, las barreras de carga/salida, las copias
independientes del estado al guardar y el protocolo de confirmacion de renacer.
Extrae las funciones del servidor para probar el codigo que usa el juego.
La suite SessionStore.spec.luau tambien se puede pegar en la barra de comandos de
Studio, en modo edicion, despues de sincronizar Rojo.

## Comprobacion en Studio pendiente

1. Conectar Rojo y ejecutar Play: la pantalla de carga desaparece al preparar la mina.
   Las compras y la recogida no deben funcionar antes de ese momento.
2. Con API desactivada: comprobar el aviso persistente de que la partida no guarda.
3. Con API activada en un lugar publicado de prueba: contratar, comprar una habilidad,
   guardar saliendo y volver a entrar; comprobar dinero, mineros y habilidad.
   Studio usa un almacen separado del juego publicado.
4. Ejecutar una prueba de servidor con varios clientes: cada jugador conserva su mina;
   al salir uno, otro puede ocuparla sin recibir animales o resultados de tiradas antiguos.
5. Al cumplir los requisitos de renacer: abrir la confirmacion y cancelar; no cambia nada.
   Abrir otra vez, esperar 15 segundos: se cierra sin reiniciar. Confirmar a tiempo:
   reinicia mineros, mineral y deposito, deja $30 y conserva gerentes, habilidades,
   slots y nivel del deposito. El servidor vuelve a comprobar requisitos y dinero.
6. Revisar la ventana en escritorio y en el emulador movil, tanto vertical como horizontal.
7. En la experiencia publicada de prueba: salir y volver a entrar rapidamente y comprobar
   que no se sobreescribe una partida mientras el servidor anterior la esta guardando.

No se han ejecutado pruebas visuales ni solicitudes a DataStore real desde el ejecutor local.
