# Lumi UI 0.4.17 · Navegación y configuraciones

La referencia se aplica al perfil inferior, la tarjeta «Configuraciones» y la barra superior. Se conservan las tres páginas de demostración y los fondos suaves.

La tarjeta inferior abre una página propia de configuraciones, creada al usarla. Sus controles ajustan animaciones, intensidad de la decoración y visibilidad del inspector, e incluyen restablecer. El perfil se presenta en una tarjeta alineada encima. En móvil ambos accesos conservan su tamaño táctil y la navegación sigue siendo desplazable.

La barra superior incorpora Inicio, ruta, búsqueda funcional con Ctrl+K y los controles de minimizar/cerrar. En anchos pequeños la búsqueda se abre desde un botón compacto. Su lista localiza páginas y controles, admite consultas con o sin tildes y lleva a la fila correspondiente. Reutiliza el ciclo de vida de los menús existentes para cerrar y liberar el foco al mover, cambiar de página, minimizar o destruir.

Implementación: componentes Settings y Search; integración y geometría en Window; tarjeta en Profile; iconos nativos en UI y textos en Textos. Primero se añaden regresiones reales y se comprueba su fallo con la biblioteca anterior; después se ejecuta la suite, interacción nativa y revisión visual exclusivamente en el PID 12920 autorizado.

## Resultado y verificación

- 80/80 pruebas nativas de Roblox correctas. Las seis primeras regresiones fallaron en la versión anterior; otras dos reprodujeron la pérdida de la consulta al repetir Ctrl+K y el cambio de opacidad durante una transición. Todas pasan con las expectativas conservadas.
- 120 distribuciones de controles en seis tamaños, con las cuatro páginas y sin colisiones ni recortes de nombres o descripciones.
- Entrada nativa de ratón y teclado: tarjeta Configuraciones, interruptores, restablecer, Inicio, Ctrl+K, búsqueda, Intro y Escape correctos.
- Simulación táctil 390×844: navegación, Configuraciones, búsqueda compacta y apertura de una fila fuera de pantalla; se conserva el valor del selector.
- La búsqueda conserva la consulta al invocar de nuevo el atajo y libera el foco al cerrarse. Si hay varias ventanas, se dirige a la última expandida o al editor que ya tiene el foco dentro de Lumi; las ventanas destruidas abandonan el registro.
- Las preferencias de decoración se conservan aunque se apliquen durante minimizar o restaurar.
- Comprobación de español ampliada al panel y al menú de búsqueda; generación determinista, sintaxis del generador y diferencias correctas.

El perfil mantiene avatar, nombre de visualización y usuario cuando caben; cuando coinciden se muestra «En línea». La tarjeta inferior usa «Configuraciones», descripción breve y flecha de acceso. La barra superior tiene 44 px en escritorio y 56 px en móvil, con objetivos táctiles de al menos 44 px.

Verificado únicamente en el PID 12920 autorizado. La simulación móvil se realizó en el motor de escritorio; no se probó un teléfono físico.
