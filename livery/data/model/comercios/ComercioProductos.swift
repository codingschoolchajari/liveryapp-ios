//
//  ComercioProductos.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ComercioProductos: Codable {
    let idComercio: String
    let nombreComercio: String
    let logoComercioURL: String
    var productos: [Producto] = []
    var promociones: [Promocion] = []
}
