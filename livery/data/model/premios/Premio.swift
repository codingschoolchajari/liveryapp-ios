//
//  Premio.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Premio: Codable, Equatable {
    var idInterno: String = ""
    var emailUsuario: String = ""
    var idComercio: String = ""
    var nombreComercio: String = ""
    var logoComercioURL: String = ""
    var localidad: String = ""
    var idProducto: String = ""
    var nombreProducto: String = ""
    var imagenProductoURL: String = ""
    var fechaAsignacion: String
    var fechaUtilizacion: String? = nil
    var estado: String = ""
}
