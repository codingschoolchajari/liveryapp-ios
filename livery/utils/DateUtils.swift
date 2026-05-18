//
//  DateUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 24/12/2025.
//
import Foundation

struct DateUtils {

    private static let diasSemanaNormalizados: [String: String] = [
        "domingo": "Domingo",
        "lunes": "Lunes",
        "martes": "Martes",
        "miercoles": "Miércoles",
        "miércoles": "Miércoles",
        "jueves": "Jueves",
        "viernes": "Viernes",
        "sabado": "Sábado",
        "sábado": "Sábado"
    ]
    
    static func comercioEstaAbierto(horarios: [ComercioHorario]?) -> Bool {
        guard let horarios = horarios, !horarios.isEmpty else { return false }

        let nombreDia = obtenerNombreDiaActual()
        let minutosActuales = obtenerMinutosActuales()

        guard let horariosHoy = horarios.first(where: { $0.dia == nombreDia }) else { return false }

        return horariosHoy.intervalos.contains { intervalo in
            estaDentroDelIntervalo(minutosActuales: minutosActuales, inicio: intervalo.inicio, fin: intervalo.fin)
        }
    }

    static func obtenerHorariosHoy(horarios: [ComercioHorario]) -> String {
        
        let fechaActual = Date()
        let calendario = Calendar.current
        let numeroDia = calendario.component(.weekday, from: fechaActual)
        
        // Calendar.weekday devuelve: 1 para Domingo, 2 para Lunes, etc.
        let nombreDia = ListUtils.diasSemana[numeroDia - 1]

        // 2. Buscar el horario que coincida con el día de hoy
        guard let horariosHoy = horarios.first(where: { $0.dia == nombreDia }),
              !horariosHoy.intervalos.isEmpty else {
            return "\(nombreDia) cerrado"
        }

        // 3. Unir los intervalos
        return horariosHoy.intervalos
            .map { "\($0.inicio) a \($0.fin)" }
            .joined(separator: "  -  ")
    }
    
    static func tiempoRelativo(fechaString: String) -> String {
        // 1. Extraemos solo la fecha del String del servidor (ej: "2025-12-30")
        let soloFechaServidor = String(fechaString.prefix(10))
        
        // 2. Configuramos el formateador para que use la hora LOCAL del iPhone
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current // Usa la hora del usuario
        
        // 3. Convertimos el String del servidor a una fecha (a las 00:00 locales)
        guard let fechaDestino = formatter.date(from: soloFechaServidor) else {
            return "Fecha inválida"
        }
        
        // 4. Obtenemos "Hoy" a las 00:00 locales usando Calendar
        let calendar = Calendar.current
        let inicioHoy = calendar.startOfDay(for: Date())
        
        // 5. Calculamos la diferencia de días
        let componentes = calendar.dateComponents([.day], from: fechaDestino, to: inicioHoy)
        let dias = componentes.day ?? 0
        
        switch dias {
        case 0: return "Hoy"
        case 1: return "Ayer"
        case let d where d < 0: return "Hoy"
        default: return "Hace \(dias) días"
        }
    }
    
    static func fechaATexto(fechaStr: String) -> String {
        // 1. Configuramos el formateador de entrada para el String del servidor
        let formatterEntrada = DateFormatter()
        formatterEntrada.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatterEntrada.timeZone = .current // Aseguramos que interprete la hora local
        
        // 2. Intentamos convertir el String a Date
        guard let fecha = formatterEntrada.date(from: fechaStr) else {
            return fechaStr // Si falla, devolvemos el original por seguridad
        }
        
        // 3. Obtenemos el nombre del día de la semana usando Calendar
        let calendar = Calendar.current
        let numeroDia = calendar.component(.weekday, from: fecha)
        
        // Lista manual de días (domingo es 1 en Swift)
        let diasSemana = ["", "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
        let nombreDia = diasSemana[numeroDia]
        
        // 4. Configuramos el formateador de salida para la fecha y hora
        let formatterSalida = DateFormatter()
        formatterSalida.dateFormat = "dd/MM/yyyy"
        
        // 5. Obtenemos componentes de hora y minuto manualmente
        let hh = String(format: "%02d", calendar.component(.hour, from: fecha))
        let min = String(format: "%02d", calendar.component(.minute, from: fecha))
        let fechaFormateada = formatterSalida.string(from: fecha)
        
        return "\(nombreDia) \(fechaFormateada) a las \(hh):\(min)"
    }
    
    static func sumarMinutos(hora: String, minutos: Int) -> String {
        // 1. Separamos el string "HH:mm" y convertimos a Int
        let partes = hora.split(separator: ":").compactMap { Int($0) }
        
        // Validamos que tengamos exactamente hora y minuto
        guard partes.count == 2 else { return hora }
        
        let h = partes[0]
        let m = partes[1]
        
        // 2. Calculamos el total
        let totalMinutos = h * 60 + m + minutos
        let nuevaHora = (totalMinutos / 60) % 24
        let nuevoMinuto = totalMinutos % 60
        
        // 3. Formateamos el resultado con 2 dígitos (equivalente al %02d)
        return String(format: "%02d:%02d", nuevaHora, nuevoMinuto)
    }
    
    static func fechaSinSegundos(_ fecha: String) -> String {
        // Dividimos el string por el carácter ":"
        let partes = fecha.components(separatedBy: ":")
        
        // Verificamos que tengamos al menos hora y minutos (2 partes)
        if partes.count >= 2 {
            // Retornamos las primeras dos partes unidas por ":"
            return "\(partes[0]):\(partes[1])"
        } else {
            // Si el formato es distinto o falla, devolvemos el string original
            return fecha
        }
    }

    static func obtenerHorariosReducidosHoy(horarioReducido: ComercioHorarioReducido) -> String {
        let intervalos = obtenerIntervalosHoy(horarioReducido: horarioReducido)

        if intervalos.isEmpty {
            return "Cerrado"
        }

        return intervalos
            .map { "\($0.inicio) a \($0.fin)" }
            .joined(separator: "  -  ")
    }

    static func obtenerDescripcionesHorariosReducidosProducto(producto: Producto, comercio: Comercio) -> [String] {
        let ids = producto.horariosReducidos ?? []
        let horariosReducidos = comercio.horariosReducidos ?? []

        if ids.isEmpty || horariosReducidos.isEmpty {
            return []
        }

        return horariosReducidos
            .filter { ids.contains($0.idInterno) }
            .map { $0.descripcion.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func productoDisponibleEnHorarioReducido(producto: Producto, comercio: Comercio) -> Bool {
        let ids = producto.horariosReducidos ?? []
        if ids.isEmpty {
            return true
        }

        let horariosReducidos = comercio.horariosReducidos ?? []
        if horariosReducidos.isEmpty {
            return true
        }

        let horariosAplicables = horariosReducidos.filter { ids.contains($0.idInterno) }
        if horariosAplicables.isEmpty {
            return true
        }

        let minutosActuales = obtenerMinutosActuales()
        let diaActual = normalizarTextoDia(obtenerNombreDiaActual())

        for horarioReducido in horariosAplicables {
            let intervalosHoy = horarioReducido.horarios
                .filter { normalizarTextoDia($0.dia) == diaActual }
                .flatMap { $0.intervalos }

            for intervalo in intervalosHoy {
                if estaDentroDelIntervalo(minutosActuales: minutosActuales, inicio: intervalo.inicio, fin: intervalo.fin) {
                    return true
                }
            }
        }

        return false
    }

    private static func obtenerIntervalosHoy(horarioReducido: ComercioHorarioReducido) -> [ComercioIntervalo] {
        let diaActual = normalizarTextoDia(obtenerNombreDiaActual())

        return horarioReducido.horarios
            .filter { normalizarTextoDia($0.dia) == diaActual }
            .flatMap { $0.intervalos }
    }

    private static func obtenerNombreDiaActual() -> String {
        let numeroDia = Calendar.current.component(.weekday, from: Date())
        return ListUtils.diasSemana[numeroDia - 1]
    }

    private static func obtenerMinutosActuales() -> Int {
        let componentes = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (componentes.hour ?? 0) * 60 + (componentes.minute ?? 0)
    }

    private static func convertirHoraAMinutosSeguro(_ hora: String) -> Int? {
        let partes = hora.split(separator: ":").compactMap { Int($0) }
        guard partes.count == 2 else { return nil }

        let horas = partes[0]
        let minutos = partes[1]

        guard (0...23).contains(horas), (0...59).contains(minutos) else {
            return nil
        }

        return horas * 60 + minutos
    }

    private static func estaDentroDelIntervalo(minutosActuales: Int, inicio: String, fin: String) -> Bool {
        guard
            let inicioMin = convertirHoraAMinutosSeguro(inicio),
            let finMin = convertirHoraAMinutosSeguro(fin)
        else {
            return false
        }

        if inicioMin <= finMin {
            return minutosActuales >= inicioMin && minutosActuales <= finMin
        }

        return minutosActuales >= inicioMin || minutosActuales <= finMin
    }

    private static func normalizarTextoDia(_ valor: String) -> String {
        let base = valor
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return diasSemanaNormalizados[base] ?? valor
    }
}
