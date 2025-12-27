//
//  ItemProducto.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct SeleccionableProducto: Codable {
    let idSeleccionable: String
    let nombreSeleccionable: String
    var cantidad: Int? = nil
}

struct ItemProducto: Codable {
    var idInterno: String = UUID().uuidString
    let idProducto: String
    let nombreProducto: String
    var imagenProductoURL: String = ""
    var cantidad: Int
    var precioUnitario: Double
    var precio: Double
    var seleccionables: [SeleccionableProducto] = []
    var esPremio: Bool = false
    var idPremio: String? = nil
}
