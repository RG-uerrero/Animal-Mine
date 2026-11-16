# Modelos 3D — primera version visual

Se actualizaron los 6 mineros y los 14 gerentes con geometria local de Roblox.
No hay dependencias de modelos del Marketplace, archivos de imagen ni cambios a nombres de guardado.

## Apariencia

- Proporciones compactas, cabezas grandes, ojos con reflejo, hocicos y sonrisas.
- Orejas largas de conejo, orejas redondas y bigotes de ratita, manchas de panda,
  rayas de tigre, melena de leon, pico de aves, trompa de cerdito y alas de especies fantasticas.
- Mineros: peto azul, tirantes, bolsillo, botas, casco y lampara.
- Gerentes: chaleco, camisa, corbata, libreta y detalles de rareza.
- Las formas ovaladas usan SpecialMesh Sphere incorporado para conservar sus proporciones.

## Verificacion en Studio

- Construccion de los 20 personajes: correcta, entre 39 y 54 BaseParts por personaje.
- Pivote Body conservado a 1.9 studs: correcto.
- PivotTo, accesorios, geometria sin colisiones y proporciones con malla: correctos.
- Posicion de ManoPico coincidente con ToolGrip en todos los mineros: correcta.
- Contratacion por prompts de los seis mineros: correcta; modelos y animacion funcionando.
- Agarre del pico durante la animacion: distancia de 0 a 0.000004 studs respecto a la pata.
- Ruleta real de gerentes: obtuvo Lalo Lobo, modelo nuevo y bono equipado de +80% correctos.
- Revision visual cercana del Conejito y Rita: realizada; orejas, casco, ojos y vestuario visibles.

Las pruebas se realizaron en una sesion sin guardar; los fondos y cambios temporales se descartan al parar Play.
Las suites locales existentes y rojo build tambien pasan.

## Revisar sin conseguir cada gerente

Durante Play, ejecutar tests/PreviewAnimals.luau en la barra de comandos del SERVIDOR.
Crea una galeria temporal de los veinte personajes en el cesped posterior (z=180..210).
No modifica dinero ni inventario y desaparece al detener la simulacion.

Las habilidades y el balance economico no cambiaron. Es una primera version para revisar el estilo;
no incluye un rig esqueletico nuevo ni animaciones independientes de brazos o parpados.
