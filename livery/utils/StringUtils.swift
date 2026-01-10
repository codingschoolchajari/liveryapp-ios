//
//  StringUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

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
