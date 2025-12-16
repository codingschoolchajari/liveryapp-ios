//
//  Seleccionable.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Seleccionable: Codable {
    let idInterno: String
    let nombre: String
    var disponible: Bool = true
    var imagenURL: String? = nil
    var tipo: String = "" // unitario (check), multiple (por cantidad)
}
