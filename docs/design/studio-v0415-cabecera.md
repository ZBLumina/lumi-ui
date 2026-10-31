# Lumi UI 0.4.15 · Cabecera protagonista

La composición botánica recorre la cabecera completa: cuatro hojas grandes, dos cintas anchas y un único destello. Mantiene el estilo gráfico y la paleta clara. Es un PNG original con transparencia, creado y editado con la herramienta integrada imagegen; el prompt final está en `assets/decor/CABECERA-VIVA-V2.md`.

La imagen recorre el ancho de la cabecera, con un margen interior de 8 px en horizontal y 6 px en vertical. Las cintas terminan en puntas naturales y los cuatro bordes del PNG son transparentes, sin cortes rectangulares. En escritorio, el texto ocupa el 56% izquierdo y permanece dentro del 55% superior libre del PNG. La altura se calcula con las medidas reales del título y la descripción; las descripciones largas amplían la cabecera sin pisar las cintas. La zona de texto del recurso tiene una opacidad máxima de 1/255 en el muestreo de verificación.

La cabecera parte de 180 píxeles; el tamaño habitual es 184. La ventana de escritorio puede aprovechar hasta 808 píxeles de alto cuando hay espacio. En teléfono se conserva el límite anterior de 768 píxeles; la cabecera compacta no incluye ilustración. Los paneles estrechos también ocultan el adorno. Los controles mantienen sus propias dimensiones y el contenido sigue siendo desplazable.

Se conservan la paleta clara, las fuentes, el logotipo L con punto, los fondos anteriores y todas las funciones. Verificación exclusivamente en el PID 12920 autorizado.

## Verificación

- 68/68 pruebas existentes, sin fallos; dos avisos intencionales de aislamiento.
- 96 distribuciones de controles en seis tamaños, escala 1, sin solapamientos ni recortes de nombres o descripciones.
- Cabecera comprobada en tres páginas y seis tamaños: imagen cargada y pasiva, composición de ancho completo dentro del margen interior; texto dentro del área transparente, marca L con punto conservada y vista compacta en teléfono.
- Simulación táctil 390×844: menú, navegación, desplazamiento, miniatura, deslizador, minimizar y restaurar.
- Captura real en Roblox del resultado; generación determinista y comprobación de diferencias.

La simulación táctil se realiza en el motor de escritorio, no en un teléfono físico.
