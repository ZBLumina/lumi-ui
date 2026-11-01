# Lumi UI 0.4.20 · Español, portugués y atajo de ventana

La interfaz inicia en español y ofrece únicamente español y portugués desde Configuraciones. El catálogo local se incluye en el script y no envía textos a un servicio externo. La preferencia se aplica a la presentación de cada ventana: títulos, etiquetas, descripciones, ayudas, opciones y búsqueda. Las notas, los nombres de usuario, la marca, las consultas y los valores del usuario se conservan.

La búsqueda admite los nombres fuente y sus etiquetas traducidas. Los textos creados después de cambiar el idioma adoptan la preferencia activa; volver a español recupera el texto fuente. Se conserva el idioma al navegar y minimizar. Quien integra la biblioteca puede usar `Language = "pt"` al crear la ventana, `SetLanguage("es" | "pt")` o `SetPreference("Language", ...)`. Los textos personalizados sin entrada en el catálogo permanecen como se proporcionaron. Esta función traduce la interfaz mediante un catálogo; no es traducción automática de texto libre.

Mayús derecha minimiza o restaura la última ventana de Lumi. El atajo se ignora mientras hay un campo de texto enfocado o Roblox ya procesó la entrada. Se puede cambiar con `ToggleKey = Enum.KeyCode.F8` o desactivar con `ToggleKey = false`. Los controles táctiles conservan su funcionamiento.

Se eligió el catálogo local para este piloto. Google Cloud Translation requiere proyecto, autenticación y facturación habilitada; una futura integración necesitaría un servicio que gestione esas credenciales. Fuente: [configuración oficial de Cloud Translation](https://docs.cloud.google.com/translate/docs/setup).

## Posibles mejoras posteriores

- Guardar y recuperar preferencias de forma opcional.
- Favoritos para llegar a los controles más usados.
- Atajos personalizados desde la interfaz.

Estas tres mejoras quedan como propuestas; no forman parte de esta versión.

## Verificación

- 93/93 regresiones nativas pasan en Roblox, PID 24604. Las pruebas previas reprodujeron la ausencia de idioma/atajo; dos regresiones adicionales detectaron el cierre de menús durante el reajuste de textos. Se corrigió conservando las expectativas.
- 456 distribuciones de controles revisadas: 228 en español y 228 en portugués, en seis tamaños entre 320×500 y 1920×1080. Sin colisiones de campos, recortes de títulos o descripciones de filas.
- Las pruebas cubren fuente español reversible, idioma portugués inicial, ventanas independientes, protección de identidad, notas y consultas, búsqueda por etiqueta traducida y textos nuevos bajo el idioma activo.
- Mayús derecha se comprueba mediante eventos nativos: solo afecta a la última ventana, restaura y se ignora al escribir. Al cerrar esa ventana el atajo vuelve a la anterior.
- No existe catálogo ni opción de inglés. La API rechaza `en`.

- Selector de idioma verificado mediante toques nativos simulados en 390×844 y 320×500: cambiar a portugués, volver a español y conservar una nota con acentos. No se probó un teléfono físico.
- Verificador de español: 14.834 lecturas de textos correctas.
- Revisión visual en Roblox de Configurações y sus etiquetas, descripciones, estados, búsqueda y propiedades.

- Se reprodujo y corrigió una realimentación entre la traducción de campos de solo lectura y su valor: `Lino` con límite de cuatro caracteres se mostraba truncado como `Linh`. La traducción ahora muestra `Linho`, conserva `Get() == "Lino"` y no ejecuta callbacks de datos. La nueva regresión falló antes de la corrección.
