# Verificacion en Roblox Studio — 14 de noviembre de 2026

Se uso la ventana existente Mina de animales, conectada a Rojo, y el simulador iPhone XR.
Las sesiones se ejecutaron con API desactivada; no se publico ni se modificaron permisos.
Se asigno dinero temporal y se redujo la duracion de los prompts solamente en la simulacion
para acelerar las interacciones. Al detener Play se descartaron esos cambios.

## Verificado

- DataReady=true, SaveStatus=disabled, pantalla Loading oculta y aviso de no guardado visible.
- Mejora de Conejito y Zorrito, y contratacion de Osito, Pandita, Tigre y Leon mediante prompts.
  Los descuentos y cambios de nivel se reflejaron en el HUD y los carteles.
- Recogida al tocar la vagoneta: dinero paso de 84036011 a 84036389 en la prueba.
- Hora dorada: contador visible y multiplicador actualizado.
- Confirmacion de renacer: ventana legible, cancelar mantiene dinero y Renacer=0.
  Confirmar deja dinero=30, produccion=0, Renacer=1 y conserva el gerente equipado.
- iPhone XR horizontal y vertical: se corrigio la seleccion del HUD compacto por ancho.
  Se comprobaron los rectangulos de Cash, Stat, Quest, Tut y GerBtn sin superposicion
  a resoluciones de viewport 413x814 y 801x413, despues de girar el dispositivo.
- API desactivada: se corrigio la deteccion del mensaje 403 real. La nueva sesion
  pasa al modo de prueba sin repetir tres solicitudes inutiles.

## Pendiente

- Guardado/carga persistentes y reconexion entre servidores: requieren acceso a API
  en el lugar de prueba. No se cambiaron esas opciones de seguridad.
- Varios jugadores simultaneos y dispositivos fisicos.
- Reducir y organizar los carteles 3D, que se superponen al acercarse o mirar desde lejos.
- Studio avisa que el recurso 203785492 tiene un tipo incompatible. Ese ID no aparece
  en los archivos src revisados; no se pudo atribuir su origen durante esta prueba.

Estado final: Play detenido, simulador desactivado y Studio en modo edicion.
Las correcciones quedan en los archivos locales sincronizados con Rojo.
