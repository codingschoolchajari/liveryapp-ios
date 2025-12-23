//
//  StringUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

struct StringUtils {
    
    static let sinCobertura = "SIN_COBERTURA"
    
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
