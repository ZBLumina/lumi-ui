# Lumi UI 0.4.16 · Fondos y seguimiento lateral

Las ilustraciones se integran como fondo: se conservan los PNG, la composición amplia y los márgenes, reduciendo su opacidad. Los textos, controles, fuentes, paleta y logotipo L con punto conservan sus valores.

| Decoración | Opacidad anterior | Opacidad actual |
| --- | ---: | ---: |
| Cabecera | 90 % | 36 % |
| Navegación izquierda | 52 % | 22 % |
| Panel principal | 60 % | 18 % |
| Inspector | 62 % | 22 % |

Las cuatro imágenes siguen cargadas y pasivas, sin capturar entrada. No fue necesario generar ni sustituir imágenes.

Al arrastrar la cabecera, la barra izquierda y el inspector acompañan el movimiento y regresan a su posición mediante la misma transición de 140 ms. Los límites son simétricos respecto al panel central, mantienen al menos 6 px de hueco y respetan la pantalla. La izquierda conserva el efecto en escritorio compacto aunque el inspector esté oculto. El ajuste de tamaño, minimizar y la desactivación de animaciones cancelan el desplazamiento residual. En teléfono la navegación conserva su colocación estable.

## Verificación

- Las cuatro nuevas regresiones fallaron con la biblioteca anterior; sus expectativas permanecieron iguales al implementar el seguimiento.
- Suite real de Roblox: 72/72 pruebas correctas, sin fallos.
- Arrastre nativo bidireccional con entrada del motor: 20 muestras; ambas superficies respondieron, conservaron el hueco y volvieron al reposo al liberar el puntero.
- 96 distribuciones de controles en seis tamaños, sin solapamientos ni recortes de nombres y descripciones.
- Recorrido táctil 390×844: menú, navegación, desplazamiento, miniatura, deslizador, minimizar y restaurar; diez eventos táctiles.
- Imágenes integradas, locales y HTTPS comprobadas, junto al respaldo ante datos inválidos.
- Los cuatro fondos se cargaron correctamente y conservaron su opacidad después de minimizar y restaurar.
- Generación determinista, comprobación de sintaxis y diferencias correctas; captura real de la interfaz.

Una primera comprobación táctil con una espera fija de 200 ms falló al comprobar la minimización. En la repetición instrumentada, el toque y la transición finalizaron correctamente; el fixture comprueba el estado final con un límite de un segundo. No se modificó el comportamiento de minimizar.

Todas las comprobaciones del cliente se ejecutaron exclusivamente en el PID 12920 autorizado. La simulación táctil usa el motor de escritorio; no se probó en un teléfono físico.
