//
//  EstadoPremio.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import SwiftUI

enum EstadoPremio: String, Codable, CaseIterable {
    case asignado = "ASIGNADO"
    case utilizado = "UTILIZADO"

    var descripcion: String {
        switch self {
        case .asignado:
            return "Premio aún no utilizado"
        case .utilizado:
            return "Premio utilizado"
        }
    }

    var color: Color {
        switch self {
        case .asignado:
            return Color(red: 1.0, green: 0.596, blue: 0.0)   // #FF9800
        case .utilizado:
            return Color(red: 0.188, green: 0.686, blue: 0.243) // #30AF3E
        }
    }

    static func desdeString(_ valor: String) -> EstadoPremio? {
        return EstadoPremio(rawValue: valor.uppercased())
    }
}
