//
//  StringUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

struct StringUtils {
    
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
        calle: String?,
        numero: String?,
        departamento: String?
    ) -> String {
        
        let calleYNumero: String
        
        if let numero = numero, !numero.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            calleYNumero = "\(calle ?? "") \(numero)"
        } else {
            calleYNumero = calle ?? ""
        }
        
        if let departamento = departamento,
           !departamento.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(calleYNumero) - \(departamento)"
        } else {
            return calleYNumero
        }
    }
}
