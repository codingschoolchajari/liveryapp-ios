//
//  PremioCanjeable.swift
//  livery
//
import Foundation

struct PremioCanjeable: Codable, Identifiable {
    var idProducto: String = ""
    var idComercio: String = ""
    var localidad: String = ""
    var disponible: Bool = false
    var puntos: Int = 0
    var categoria: String = ""
    var tipo: String? = nil
    var logoComercioURL: String? = nil
    var nombreComercio: String? = nil
    var nombreProducto: String? = nil
    var imagenURL: String? = nil

    var id: String { "\(idComercio)_\(idProducto)" }
}