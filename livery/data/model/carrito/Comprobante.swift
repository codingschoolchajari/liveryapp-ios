//
//  Comprobante.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Comprobante: Codable {
    var contenido: Data = Data()
    var nombre: String = ""
    var `extension`: String = ""
}
