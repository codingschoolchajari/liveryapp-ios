//
//  ComercioPremio.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ComercioPremio: Codable {
    let idComercio: String
    let nombreComercio: String
    var logoComercioURL: String = ""
    let idProducto: String
    let localidad: String
}
