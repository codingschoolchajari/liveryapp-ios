//
//  ComercioDescuentos.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ComercioDescuentos: Codable, Identifiable {
    var idComercio: String = ""
    var localidadComercio: String = ""
    var nombreComercio: String = ""
    var logoComercioURL: String = ""
    var productos: [Producto] = []
    
    var id: String {
        idComercio
    }
}
