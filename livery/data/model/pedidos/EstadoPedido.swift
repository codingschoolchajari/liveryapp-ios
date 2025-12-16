//
//  EstadoPedido.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation
import SwiftUI

enum EstadoPedido: String, CaseIterable, Codable {
    case pendienteAprobacion = "PENDIENTE_APROBACION"
    case pendientePago = "PENDIENTE_PAGO"
    case enPreparacion = "EN_PREPARACION"
    case enEsperaRepartidor = "EN_ESPERA_REPARTIDOR"
    case enEsperaCliente = "EN_ESPERA_CLIENTE"
    case enCamino = "EN_CAMINO"
    case entregado = "ENTREGADO"
    case cancelado = "CANCELADO"

    var descripcion: String {
        switch self {
        case .pendienteAprobacion:
            return "Pendiente de Aprobación"
        case .pendientePago:
            return "Pendiente de Pago"
        case .enPreparacion:
            return "En Preparación"
        case .enEsperaRepartidor:
            return "Esperando Repartidor"
        case .enEsperaCliente:
            return "Esperando Cliente"
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
        case .pendienteAprobacion:
            return "Pedido a la espera de ser aprobado por el comercio."
        case .pendientePago:
            return "Se debe realizar el pago del pedido."
        case .enPreparacion:
            return "Su pedido se encuentra en preparación."
        case .enEsperaRepartidor:
            return "Su pedido se encuentra listo, esperando ser retirado por el repartidor."
        case .enEsperaCliente:
            return "Su pedido se encuentra listo, esperando ser retirado."
        case .enCamino:
            return "Su pedido ya está en camino."
        case .entregado:
            return "Su pedido ha sido entregado con éxito."
        case .cancelado:
            return "Su pedido ha sido cancelado."
        }
    }

    var color: Color {
        switch self {
        case .pendienteAprobacion:
            return Color(hex: 0xFFFF9800)
        case .pendientePago, .cancelado:
            return Color(hex: 0xFFB3261E)
        case .enPreparacion, .enEsperaRepartidor, .enEsperaCliente:
            return Color(hex: 0xFF006064)
        case .enCamino:
            return Color(hex: 0xFF2196F3)
        case .entregado:
            return Color(hex: 0xFF30AF3E)
        }
    }

    /// Equivalente a `desdeString`
    static func desdeString(_ valor: String) -> EstadoPedido? {
        EstadoPedido.allCases.first {
            $0.rawValue.caseInsensitiveCompare(valor) == .orderedSame
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let a = Double((hex >> 24) & 0xFF) / 255
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
