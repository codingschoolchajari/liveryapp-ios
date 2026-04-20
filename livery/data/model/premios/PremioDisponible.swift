//
//  PremioDisponible.swift
//  livery
//
import Foundation

struct PremioDisponible: Codable, Identifiable {
    var idInterno: String = ""
    var idProducto: String = ""
    var idComercio: String = ""
    var localidad: String = ""
    var fechaDesde: String = ""
    var logoComercioURL: String? = nil
    var nombreProducto: String? = nil

    var id: String { idInterno }
}
