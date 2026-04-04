import SwiftUI

enum EstadosRepartos: String, CaseIterable, Codable {
    case todos = "TODOS"
    case pendientes = "PENDIENTES"
    case enCamino = "EN_CAMINO"
    case entregados = "ENTREGADOS"
    case cancelados = "CANCELADOS"

    var descripcion: String {
        switch self {
        case .todos:
            return "Todos"
        case .pendientes:
            return "Pendientes"
        case .enCamino:
            return "En Camino"
        case .entregados:
            return "Entregados"
        case .cancelados:
            return "Cancelados"
        }
    }

    var color: Color {
        switch self {
        case .todos, .entregados:
            return Color(hex: 0xFF30AF3E)
        case .pendientes:
            return Color(hex: 0xFFFF9800)
        case .enCamino:
            return Color(hex: 0xFF2196F3)
        case .cancelados:
            return Color(hex: 0xFFB3261E)
        }
    }
}
