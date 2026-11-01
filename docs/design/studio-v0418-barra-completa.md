# Lumi UI 0.4.18 · Barra lateral completa

La navegación replica los tres grupos de la referencia: Principal (Inicio, Jugador, Aspecto), Espacio (Espacios, Interacción, Ajustes) y Herramientas (Registros, Notas, Ayuda). La barra de escritorio crece de 184 a 228 px; en móvil conserva el ancho completo de la navegación. Los grupos y sus separadores se desplazan dentro de su área, mientras perfil y Configuraciones permanecen al pie.

El perfil añade una flecha y abre una página con los datos del usuario. Configuraciones conserva su nombre y acceso existente, incorpora un icono en baldosa, porcentaje y barra ligada a la preferencia real de decoración. Ajustes abre la misma página de Configuraciones, sin duplicarla.

La biblioteca incorpora grupos de navegación y campos de texto con modo de solo lectura. La demostración completa los paneles: Espacios permite centrar y mostrar u ocultar el inspector; Interacción cambia el movimiento; Registros muestra actividad real de navegación; Notas permite escribir y conservar texto durante la sesión; Ayuda ofrece instrucciones y accesos funcionales.

Se preservan las páginas y controles actuales, las fuentes, PNG, colores, búsqueda, minimizar y seguimiento. La validación utiliza regresiones nativas y revisión visual en el cliente conectado autorizado por el usuario (PID 24604 durante la comprobación final).

## Carbón cálido y café

La petición adicional reduce el predominio del café mediante bases de carbón cálido: Sidebar #1E1D1B, Shell #22211F y Surface #2E2A25. Raised #3B3129 y las selecciones #57412E conservan el café; los acentos crema y la ilustración botánica aportan calidez. El cambio afecta únicamente a los colores compartidos del tema. No añade negro puro ni cambia imágenes, geometría o comportamiento.

Los contrastes calculados sobre las parejas del tema son 13,39:1 para Text/Surface, 9,82:1 para Secondary/Raised, 6,58:1 para Muted/Hover, 6,75:1 para Accent/AccentWash y 10,45:1 para Ink/Accent.

## Verificación

87/87 pruebas nativas de Roblox correctas con la paleta final, sin fallos. Generación determinista, sintaxis del generador y diferencias verificadas.

- Las seis regresiones iniciales de barra completa fallaron contra la versión anterior y pasan conservando sus expectativas.
- 216 distribuciones de controles revisadas en seis tamaños entre 320×500 y 1920×1080, incluidas las páginas nuevas y el perfil. Títulos, descripciones y campos permanecen contenidos y separados.
- Ratón nativo: los nueve accesos, perfil y Configuraciones abren su destino; el registro incluye la apertura del perfil.
- Eventos táctiles del motor en tamaños 390×844 y 320×500: desplazamiento de grupos hasta Ayuda, perfil, Configuraciones, porcentaje real, minimizar, restaurar y conservar notas. 19 eventos táctiles recibidos. No se probó un teléfono físico.
- Comprobación de español: 13.486 lecturas de textos sin expresiones pendientes del verificador.
- Se reprodujo un fallo de texto largo: TextBox no ampliaba el área desplazable. Ahora se mide con su FontFace real y se conserva el cursor visible al ir al inicio o al final. La regresión falló antes de la corrección y pasa sin cambiar sus expectativas.
- Las notas y los registros pertenecen a la sesión; no persisten al cerrar o recargar la demostración.
