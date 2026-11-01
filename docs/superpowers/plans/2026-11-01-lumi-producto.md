# Lumi 0.5: perfiles, feedback y acceso

> **For agentic workers:** implementar módulos delimitados y probarlos con la suite nativa de Roblox antes de integrar.

**Goal:** completar las cinco mejoras elegidas sin alterar la identidad visual ni el alcance es/pt.

**Architecture:** controles registrados por ID y con ciclo de vida propio; estado validado exportable; almacén local de perfiles con respaldo; notificaciones ligadas al runtime; tipografía por ventana y recorrido de teclado. Window integra los módulos y Configuraciones los presenta.

**Tech Stack:** Luau nativo, Potassium, JSON local, fuentes y PNG ya incluidos.

## Restricciones

- Solo español y portugués, español inicial; carbón cálido, café y crema; MingCute y marca L con punto.
- Guardado optativo mediante `Config={Key,AutoLoad=true,AutoSave=true,Storage?}`. La demostración lo habilita con IDs explícitos. Sin guardado en las ventanas de pruebas normales.
- Una operación fallida no se presenta como éxito. Se conserva respaldo válido y se comprueba la escritura leyendo el resultado.
- El estado usa `Version=1`, `Window={Position={X,Y},Page,Preferences}`, `Controls={[Id]={Kind,Value,Enabled}}`. Posición relativa al viewport, valores tipados y finitos, ID estable independiente del idioma.
- Los perfiles no guardan botones, datos de solo lectura ni controles con `Persist=false`. Al aplicar se valida todo antes de modificar y se respetan las opciones `Silent`.
- Fuentes de 100–130 %, sin encoger la interfaz completa para compensarlas; objetivos táctiles de al menos 44 px.

## Tareas

- [x] API común: `GetControl(id)`, `control:Update(patch)`, `SetEnabled(bool)`, `IsEnabled()`, `Destroy()`, estado y limpieza. El ID no cambia al renombrar; desactivar bloquea entrada, no sincronización por Set.
- [x] Perfiles: `SaveProfile(name)`, `LoadProfile(name?,options?)`, `ListProfiles()`, `GetActiveProfile()`, `Ready()`; autoguardado con espera corta y carga al terminar de construir.
- [x] Notificaciones: `Notify({Title,Message,Kind,Duration,Action})`, handle `Update`/`Dismiss`; máximo tres, cierre, acción y estado de carga, sin fugas al cerrar.
- [x] Legibilidad y teclado: `SetPreference("TextScale",factor)`, Tab/Mayús+Tab, Intro/Espacio, flechas de slider y foco visible. Respetar edición y menús existentes.
- [x] Integración en la demostración, guía y ejemplo mínimo con IDs; traducciones; pulido de espaciado, estados y transiciones.
- [x] Suite nativa con fallos previos y expectativas conservadas; persistencia entre dos ejecuciones; ratón, teclado, táctil simulado, es/pt y tamaños de letra en varios viewports; revisión independiente final.

## Casos de revisión

Errores de lectura/escritura y JSON corrupto; ID duplicado o eliminado; cerrar durante una notificación o callback; cambiar idioma/texto con valores editados; teclado y menús en teléfono estrecho.
