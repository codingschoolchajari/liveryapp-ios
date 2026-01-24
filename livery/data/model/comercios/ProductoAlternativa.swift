//
//  ProductoAlternativa.swift
//  livery
//
//  Created by Nicolas Matias Garay on 23/01/2026.
//
import Foundation

struct ProductoAlternativa: Codable, Identifiable {
    let idInterno: String
    let nombre: String
    let nombreAbreviado: String
    var precio: Double
    var precioSinDescuento: Double?
    var descuento: Int?
    var disponible: Bool = true
    
    var id: String { idInterno }
}
