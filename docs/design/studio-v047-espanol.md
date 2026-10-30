# v0.4.7 — interfaz en español

La interfaz y la demostración usan español de forma predeterminada. Se traducen navegación, títulos, descripciones, opciones, estados, inspector, listas vacías, confirmaciones, textos de reserva y mensajes propios de la biblioteca. Los nombres de producto Lumi UI, Potassium y Luau se conservan.

Los textos comunes se concentran en `src/Textos.luau`. Los tipos visibles se muestran como Botón, Interruptor, Deslizador y Selector; sus etiquetas en mayúsculas incluyen las tildes correctas. Los contadores distinguen «1 ejecución» de «2 ejecuciones» y «1 opción» de «2 opciones». Los indicadores muestran «SÍ» y «NO»; el inspector, «Activado» y «Desactivado».

Los identificadores técnicos de la API y los valores que aporta quien usa la biblioteca conservan su contrato. La demostración proporciona todos sus nombres, descripciones y opciones en español. No se añade un selector de idioma: español es el idioma de esta versión.

Se conserva la distribución medida de v0.4.6. Hay que comprobar por script que las palabras traducidas caben en la navegación, los campos y el inspector, también en tamaños pequeños; que los mensajes temporales y las listas vacías están traducidos; y que las acciones conservan sus valores y limpieza.

## Verificación

La generación y las comprobaciones de archivos pasan: `npm run build`, `npm run check`, `node --check scripts/build.mjs` y `git diff --check`. Se comprobaron 68 referencias a textos compartidos, sin claves ausentes. Los textos visibles anteriores en inglés se revisaron en las rutas de la biblioteca y la demostración. Los mensajes propios del generador y del cargador también están traducidos. La guía principal está escrita en español.

**La ejecución de esta traducción dentro de Roblox sigue pendiente.** Potassium no estaba disponible y el usuario confirmó que no podía usarlo en este momento. No se reutiliza el resultado de las 46 pruebas de la versión anterior como si verificara esta versión. Solo se adaptaron las expectativas del estado del interruptor al nuevo texto solicitado; las comprobaciones de comportamiento conservan su alcance.

Se incluye `examples/verificar-espanol.luau`, una comprobación opcional por script para ejecutar en Potassium después del piloto. Recorre las páginas, los estados, las listas y los textos de reserva, y comprueba los contadores singular y plural. Este script también está pendiente de ejecución; queda preparado para cuando se pueda conectar Roblox.
