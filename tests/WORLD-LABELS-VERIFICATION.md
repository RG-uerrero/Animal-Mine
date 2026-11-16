# Carteles y textos del mundo

Implementado el 14 de noviembre de 2026.

- Nombres de minas sobre el letrero fisico, con SurfaceGui.
- Tarjetas cercanas para precios, inventario, deposito y habilidades.
- Nombre y nivel de cada minero se muestran una sola vez, sobre su boton.
- Estilo comun con letra sobria, fondo oscuro y bordes redondeados.
- Tamano acotado por distancia y pantalla. Maximo de 8 tarjetas (5 en pantallas pequenas).
- Seleccion local para evitar solapamientos entre tarjetas y con el HUD.
- Anclajes Attachment para mantener la altura correcta incluso en cilindros girados.
- Oclusion por raycast para no mostrar tarjetas a traves de muros.
- Mensajes breves mas pequenos, con movimiento y desvanecimiento.

## Comprobado en Studio

Play en el lugar existente, sincronizado con Rojo, usando modo sin guardar.
La prueba tests/StudioWorldLabels.luau paso desde tres angulos: 2, 4 y 2 tarjetas
visibles respectivamente, sin solapamientos entre ellas. Al alejarse se verifico
que todos los precios de mineros quedaran ocultos. En Habilidades se verifico
una tarjeta visible con nombre, descripcion, nivel y precio.

Se dejo Studio detenido, en modo de edicion. Los modelos de animales no se modificaron.

## Pruebas locales

Sintaxis de todos los archivos Luau, pruebas de LabelLayout y suites existentes
(SessionStore, confirmacion de renacer y ciclo de carga/guardado) correctas.
Compilacion con rojo build correcta.

Para revisar el resultado: iniciar Play, entrar a una mina y acercarse a los botones,
vagonetas, deposito, ruleta, establo y plataformas de habilidades.
