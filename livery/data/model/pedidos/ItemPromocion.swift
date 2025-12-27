//
//  ItemPromocion.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ItemPromocion: Codable {
    var idInterno: String = UUID().uuidString
    let idPromocion: String
    let nombrePromocion: String
    var imagenPromocionURL: String = ""
    var cantidad: Int
    let precioUnitario: Double
    var precio: Double
    var seleccionablesPorProducto: [String: [SeleccionableProducto]] = [:]
}
