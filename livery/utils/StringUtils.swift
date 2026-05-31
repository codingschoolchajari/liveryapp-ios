//
//  StringUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation
import SwiftUI

/// Parsea texto con marcadores **negrita** y retorna un AttributedString.
/// Las partes entre ** se renderizan en bold con la fuente Barlow.
/// Ejemplo: "Texto normal **en negrita** texto normal"
func parsearTextoFormateado(_ texto: String, fontSize: CGFloat) -> AttributedString {
    var resultado = AttributedString()
    let partes = texto.components(separatedBy: "**")

    for (index, parte) in partes.enumerated() {
        guard !parte.isEmpty else { continue }
        var segmento = AttributedString(parte)
        if index % 2 == 1 {
            segmento.font = .custom("Barlow", size: fontSize).bold()
        } else {
            segmento.font = .custom("Barlow", size: fontSize)
        }
        resultado += segmento
    }
    return resultado
}

struct StringUtils {
    
    static let plataforma = "ios"
    
    static let sinCobertura = "SIN_COBERTURA"
    
    static let tarifaServicioDefault = 500.0
    
    static let envioPropioTarifaDefault = 4000.0
    
    static let tituloPedidoPendiente = "Pedido Pendiente"
    static let textoPedidoPendiente = "Actualmente tiene un Pedido Pendiente en este comercio.\n\n" +
            "Solo es posible realizar un nuevo pedido una vez que se haya abonado o cancelado el anterior."

    static let tituloComercioCerrado = "Comercio Cerrado"
    static let textoComercioCerrado = "El comercio no se encuentra abierto en este momento.\n\n"

    static let tituloAppNoDisponible = "App no disponible"
    
    static func inferMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }
    
    static func formatearDireccion(
        _ calle: String?,
        _ numero: String?,
        _ departamento: String?
    ) -> String {

        let calleYNumero =
            !(numero?.isEmpty ?? true)
            ? "\(calle ?? "") \(numero!)"
            : (calle ?? "")

        return !(departamento?.isEmpty ?? true)
            ? "\(calleYNumero) - \(departamento!)"
            : calleYNumero
    }
}
