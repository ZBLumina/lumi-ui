# v0.4.10 — Seguimiento y minimización

El inspector acompaña el arrastre con un retraso corto y amortiguado, sin rebote. La separación sigue siendo visible y ambas superficies permanecen dentro del área disponible. El movimiento por código y el reajuste de tamaño son inmediatos; `Animations = false` también elimina el seguimiento animado.

La cabecera incorpora un botón de minimizar junto al cierre. Al pulsarlo se cierran menús, se libera la edición y el arrastre y se ocultan ambos paneles. Una cápsula horizontal de carbón cálido y extremos redondeados queda centrada arriba, con la marca Lumi y una indicación de restaurar. Pulsarla devuelve la misma ventana, posición, página, selección y valores. Las transiciones son cortas, sin efectos elásticos.

Se conserva una sola raíz y un solo ámbito de recursos. Se usan animaciones nativas cancelables: no hay bucles permanentes para el seguimiento. La minimización, restauración, cambio de tamaño, cierre y reinyección pueden interrumpirse sin dejar cápsulas ni superficies huérfanas. Los estados minimizado y restaurado siguen siendo utilizables en pantallas compactas.

Decisión de implementación: `components/WindowPresentation.luau` reúne la presentación de la ventana y su cápsula; `Window` conserva la geometría, entrada y API. Se añaden `Minimize()`, `Restore()` e `IsMinimized()`.

## Plan

1. Añadir y ejecutar regresiones de seguimiento, límites, conservación de estado, interrupciones, modo compacto, desactivación de animaciones y limpieza.
2. Implementar el módulo de presentación e integrarlo con arrastre, cabecera y ciclo de vida.
3. Ejecutar la batería completa en Potassium, probar los botones y el arrastre mediante eventos reales e inspeccionar ambos estados.
4. Documentar evidencia, generar el piloto y actualizar la rama de desarrollo.

## Verificación — Roblox/Potassium, 30 de octubre de 2026

- Cliente 30380: **59/59 pruebas correctas**. Las siete primeras regresiones fallaron en v0.4.9 (50/57) y pasaron tras implementar seguimiento y minimización.
- Se prueban el retraso y asentamiento del inspector, sus límites, la conservación de la misma raíz, posición, página y valores, las interrupciones rápidas, el reajuste compacto, `Animations = false`, el cierre minimizado y la recarga durante la transición.
- La revisión independiente detectó dos problemas: el escudo podía interceptar el clic de restaurar durante la animación, y un selector abierto por código podía montar un menú invisible estando minimizado. Ambas regresiones fallaron (57/59) y pasaron tras elevar la cápsula y bloquear esa reapertura. La primera usa un clic real del motor durante la transición junto al borde superior.
- Los eventos nativos verificaron un arrastre de −64×16 px con retraso visible del inspector y asentamiento final a 12 px; el botón de minimizar mostró la cápsula superior; pulsarla restauró posición, página, selección y valor numérico 7.
- Los 15 controles pasan 90 comprobaciones de distribución en seis tamaños, entre 320×500 y 1920×1080. La auditoría de español revisó 3309 textos y estados.
- Generación, coherencia de archivos, sintaxis del generador y diferencias comprobadas. No hay bucles permanentes añadidos; las animaciones, conexiones y cápsulas pertenecen al ámbito de la ventana.

Se comprobaron las vistas expandida y minimizada en el cliente real. No se probaron pantalla táctil ni mando físico. La rama sigue en el PR de desarrollo; `main` conserva su versión publicada.
