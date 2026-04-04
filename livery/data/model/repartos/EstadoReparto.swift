import SwiftUI

enum EstadoReparto: String, CaseIterable, Codable {
    case pendienteAsignacion = "PENDIENTE_ASIGNACION"
    case enEsperaRepartidor = "EN_ESPERA_REPARTIDOR"
    case enCamino = "EN_CAMINO"
    case entregado = "ENTREGADO"
    case cancelado = "CANCELADO"

    var descripcion: String {
        switch self {
        case .pendienteAsignacion:
            return "Pendiente de Asignacion"
        case .enEsperaRepartidor:
            return "Esperando Repartidor"
        case .enCamino:
            return "En Camino"
        case .entregado:
            return "Entregado"
        case .cancelado:
            return "Cancelado"
        }
    }

    var aclaracion: String {
        switch self {
        case .pendienteAsignacion:
            return "Reparto pendiente de asignacion."
        case .enEsperaRepartidor:
            return "Esperando ser retirado por el repartidor."
        case .enCamino:
            return "Reparto en camino."
        case .entregado:
            return "Reparto entregado con exito."
        case .cancelado:
            return "Reparto cancelado."
        }
    }

    var color: Color {
        switch self {
        case .pendienteAsignacion:
            return Color(hex: 0xFFFF9800)
        case .enEsperaRepartidor:
            return Color(hex: 0xFF006064)
        case .enCamino:
            return Color(hex: 0xFF2196F3)
        case .entregado:
            return Color(hex: 0xFF30AF3E)
        case .cancelado:
            return Color(hex: 0xFFB3261E)
        }
    }

    static func desdeString(_ valor: String) -> EstadoReparto? {
        EstadoReparto.allCases.first {
            $0.rawValue.caseInsensitiveCompare(valor) == .orderedSame
        }
    }
}
