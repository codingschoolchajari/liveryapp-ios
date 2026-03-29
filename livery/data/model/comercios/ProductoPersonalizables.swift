//
//  ProductoPersonalizables.swift
//  livery
//
//  Created by Nicolas Matias Garay on 29/03/2026.
//
import Foundation

struct OpcionPersonalizable: Codable, Identifiable {
    let idInterno: String
    let nombre: String
    let nombreAbreviado: String
    var disponible: Bool = true

    var id: String { idInterno }
}

struct ProductoPersonalizables: Codable, Identifiable {
    let idInterno: String
    let titulo: String
    var opciones: [OpcionPersonalizable]? = []

    var id: String { idInterno }
}