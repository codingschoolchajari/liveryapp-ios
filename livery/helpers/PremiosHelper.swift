//
//  PremiosHelper.swift
//  livery
//
//  Created by Nicolas Matias Garay on 05/01/2026.
//
import SwiftUI

struct PremiosHelper {
    
    static func obtenerEstadoPremio(_ estado: String) -> String {
        let estadoPremio = EstadoPremio.desdeString(estado)
        // Usamos nil-coalescing para devolver el string original o uno vacío si falla
        return estadoPremio?.descripcion ?? estado
    }

    static func obtenerColorEstadoPremio(_ estado: String) -> Color? {
        let estadoPremio = EstadoPremio.desdeString(estado)
        return estadoPremio?.color
    }
}
