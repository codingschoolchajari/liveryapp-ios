//
//  Producto.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ProductoComplemento: Codable, Identifiable {
    let idInterno: String
    let nombre: String
    var porProducto: Bool? = nil

    var id: String { idInterno }
}

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
    var cantidadMinimaAlternativasSeleccionables: Int? = nil
    var cantidadMaximaAlternativasSeleccionables: Int? = nil
    var procesosExtras: [String] = []
    var alternativas: [ProductoAlternativa] = []
    var personalizables: [ProductoPersonalizables]? = []
    var horariosReducidos: [String]? = []
    var complementos: [ProductoComplemento]? = []
    var esComplemento: Bool? = false
    var esPremio: Bool? = nil
    var idPremio: String? = nil
    var contieneAlcohol: Bool? = false
    var disponibleParaDelivery: Bool? = nil
    var descripcionDetallada: String? = nil
    
    var id: String { idInterno }
}
