# Lumi UI 0.4.14 · Claridad y marca

Corrección visual acotada: se sustituye la flor realista por un PNG de hojas simplificadas, se aclaran las superficies café y los textos y se restaura la marca como L con un punto circular separado. La marca se comparte entre el encabezado y la cápsula de restauración.

La cabecera se publica como recurso nuevo, sin sobrescribir las imágenes anteriores. Su prompt está en `assets/decor/MINIMAL.md`. Se mantienen fuentes, geometría, animaciones, API, valores y acciones.

Los tonos secundarios y de descripción también se aclaran para conservar contraste sobre las superficies nuevas. El mínimo calculado del texto de descripción sobre los siete colores base es 4,77:1. El fondo del panel principal mezcla más del tono café claro base con la imagen existente.

La comprobación en Roblox se realiza exclusivamente en el PID 12920 autorizado.

## Resultado verificado

- 68/68 pruebas existentes en el PID 12920, sin fallos. Los dos avisos de funciones que fallan intencionalmente pertenecen a la prueba de aislamiento.
- Punto circular separado presente en la marca del panel y en la cápsula; sin la estrella anterior.
- Nueva flor cargada al visitar las tres páginas, cabeceras sin recortes y decoración sin captura de entrada.
- Minimizar y restaurar conservan la ventana y el valor seleccionado.
- Revisión visual en Roblox de la flor plana, la paleta más clara y la marca corregida.
- No se modifican dimensiones, distribución, fuentes ni controladores de entrada.
