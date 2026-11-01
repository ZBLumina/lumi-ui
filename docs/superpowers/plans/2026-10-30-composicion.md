# Composición y jerarquía — Implementation Plan

**Goal:** Separar el inspector y aumentar la presencia de la información principal.
**Architecture:** `Main` conserva la transformación conjunta; `Panel` y `Inspector` son superficies hermanas con sombras propias. `Fit` distribuye el ancho disponible y mantiene el modo compacto.
**Tech Stack:** Luau, GUI nativa de Roblox, Node y Potassium.
**Spec:** `docs/design/studio-v048-composicion.md`.

## Restricciones
Español completo, API de construcción compatible, animaciones interrumpibles, sin dependencias gráficas externas ni lógica de juego.

## Riesgos a revisar
Arrastre contra los bordes, modo compacto sin hueco residual, menús contenidos en la superficie principal, cierre y reinyección sin superficies huérfanas, texto largo con tamaños mayores.

## Tarea 1: Composición y tipografía
- [x] Añadir regresiones de separación, límites y cierre conjunto; observar fallo en v0.4.7.
- [x] Modificar `Window`, `Inspector`, `Tab`, `Section` y el límite del menú en `Dropdown`.
- [x] Ejecutar toda la batería real y auditorías de geometría y español.
- [x] Inspeccionar la vista real, documentar y entregar v0.4.8.

Se ejecuta directamente en esta sesión conforme a la autonomía solicitada. Una revisión independiente comprobará el cambio antes de terminar.

Ejecución: 50/50 en Roblox/Potassium, 90 distribuciones, 3473 textos en español y eventos nativos correctos. La revisión independiente detectó captura de entrada ausente en el inspector; corregida con regresión 49/50 RED → 50/50 GREEN. La revisión de pantallas estrechas añadió encabezados medidos, con regresión 48/49 RED → 49/49 GREEN. Sin hallazgos aplazados.
