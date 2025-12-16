//
//  EstadosPedidos.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation
import SwiftUI

enum EstadosPedidos: String, CaseIterable, Codable {
    case todos = "TODOS"
    case pendientes = "PENDIENTES"
    case enPreparacion = "EN_PREPARACION"
    case enCamino = "EN_CAMINO"
    case entregados = "ENTREGADOS"
    case cancelados = "CANCELADOS"

    var descripcion: String {
        switch self {
        case .todos:
            return "Todos"
        case .pendientes:
            return "Pendientes"
        case .enPreparacion:
            return "En Preparación"
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
        case .enPreparacion:
            return Color(hex: 0xFF006064)
        case .enCamino:
            return Color(hex: 0xFF2196F3)
        case .cancelados:
            return Color(hex: 0xFFB3261E)
        }
    }

    // Equivalente a companion object { desdeString(...) }
    static func desdeString(_ valor: String) -> EstadosPedidos? {
        EstadosPedidos.allCases.first {
            $0.rawValue.caseInsensitiveCompare(valor) == .orderedSame
        }
    }
}
