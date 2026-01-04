//
//  Comprobante.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import Foundation

struct Comprobante: Codable {
    var contenido: Data = Data()
    var nombre: String = ""
    var `extension`: String = ""
}
