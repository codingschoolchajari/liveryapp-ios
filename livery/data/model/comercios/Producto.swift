//
//  Producto.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Producto: Codable, Identifiable {
    let idInterno: String
    let nombre: String
    var descripcion: String = ""
    var precio: Double
    var precioSinDescuento: Double?
    var descuento: Int?
    var disponible: Bool = true
    var imagenURL: String? = nil
    var cantidadMinimaSeleccionables: Int? = nil
    var cantidadMaximaSeleccionables: Int? = nil
    var nombreSeleccionable: String? = nil
    var procesosExtras: [String] = []
    var esPremio: Bool? = nil
    var idPremio: String? = nil
    
    var id: String { idInterno }
}
