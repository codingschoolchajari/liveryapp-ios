//
//  ItemProducto.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct SeleccionableProducto: Codable, Identifiable {
    let idSeleccionable: String
    let nombreSeleccionable: String
    var cantidad: Int? = nil
    
    var id: String { idSeleccionable }
}

struct ItemProducto: Codable, Identifiable {
    var idInterno: String = UUID().uuidString.lowercased()
    let idProducto: String
    let nombreProducto: String
    let nombreAlternativaProducto: String?
    var imagenProductoURL: String = ""
    var cantidad: Int
    var precioUnitario: Double
    var precio: Double
    var seleccionables: [SeleccionableProducto] = []
    var esPremio: Bool = false
    var idPremio: String? = nil
    
    var id: String { idInterno }
}
