-- Textos propios de Lumi. El idioma de la interfaz es siempre español.
local Textos = {
    tipos = {
        Button = {nombre = "Botón", etiqueta = "BOTÓN"},
        Toggle = {nombre = "Interruptor", etiqueta = "INTERRUPTOR"},
        Slider = {nombre = "Deslizador", etiqueta = "DESLIZADOR"},
        Dropdown = {nombre = "Selector", etiqueta = "SELECTOR"},
    },
    interfaz = "INTERFAZ LUMI", biblioteca = "BIBLIOTECA", secciones = "SECCIONES",
    espacio = "Espacio", espacioMayus = "ESPACIO", inicio = "Inicio", sesionLocal = "SESIÓN LOCAL",
    descripcionPagina = "Un espacio para ajustar cada detalle.", controles = "CONTROLES", ajustes = "AJUSTES",
    listo = "Listo", detalles = "Detalles", ejecutar = "Ejecutar", completado = "Completado",
    si = "SÍ", no = "NO", activado = "Activado", desactivado = "Desactivado",
    seleccion = "SELECCIÓN", sinSeleccion = "Sin selección", sinOpciones = "SIN OPCIONES", vacio = "Vacío",
    tuEspacio = "Tu espacio", descripcionInspector = "Selecciona un control para ver sus detalles.",
    pistaInicial = "Selecciona un ajuste.", propiedades = "PROPIEDADES",
    claves = {"Página", "Sección", "Tipo", "Rango"},
    ejecucion = "EJECUCIÓN", alPulsar = "AL PULSAR", estado = "ESTADO", fijo = "FIJO",
    pistaFijo = "Este valor es fijo.", pistaDeslizador = "Arrastra o escribe un valor.",
    pistaEstado = "Pulsa para cambiar el estado.", pistaAccion = "Pulsa para ejecutar la acción.",
    opcionActual = "OPCIÓN %02d / %02d", listaVacia = "LISTA VACÍA", unaOpcion = "UNA OPCIÓN",
    pistaVacia = "Esta lista no tiene opciones.", pistaOpcion = "Elige una opción de la lista.",
    elegirOpcion = "ELIGE UNA OPCIÓN", noHayOpciones = "No hay opciones",
}

function Textos.nombreTipo(tipo)
    return Textos.tipos[tipo] and Textos.tipos[tipo].nombre or "Control"
end

function Textos.etiquetaTipo(tipo)
    return Textos.tipos[tipo] and Textos.tipos[tipo].etiqueta or "CONTROL"
end

function Textos.estadoAccion(cantidad)
    if cantidad == 0 then return Textos.listo end
    return tostring(cantidad) .. (cantidad == 1 and " ejecución" or " ejecuciones")
end

function Textos.cantidadOpciones(cantidad)
    return tostring(cantidad) .. (cantidad == 1 and " opción" or " opciones")
end

return Textos
