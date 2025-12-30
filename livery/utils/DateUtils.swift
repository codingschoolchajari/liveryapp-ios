//
//  DateUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 24/12/2025.
//
import Foundation

struct DateUtils {
    
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
}
