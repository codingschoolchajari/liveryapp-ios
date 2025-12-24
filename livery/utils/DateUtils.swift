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
}
