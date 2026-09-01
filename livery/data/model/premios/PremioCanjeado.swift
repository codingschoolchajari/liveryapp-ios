//
//  PremioCanjeado.swift
//  livery
//
import Foundation

struct PremioCanjeado: Codable, Identifiable {
    var idInterno: String = ""
    var emailUsuario: String = ""
    var idComercio: String = ""
    var localidad: String = ""
    var idProducto: String = ""
    var fechaCanje: String = ""
    var fechaUtilizacion: String? = nil
    var estado: String = ""
    var tipo: String? = nil
    var nombreProducto: String? = nil
    var nombreComercio: String? = nil
    var logoComercioURL: String? = nil
    var imagenURL: String? = nil

    var id: String { idInterno }
}