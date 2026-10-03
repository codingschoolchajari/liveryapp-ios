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
    var estadoApertura: String? = nil
    var horarios: [ComercioHorario]? = []
    var distanciaUsuario: Int? = nil
    var productos: [Producto] = []
    var promociones: [Promocion] = []
    
    var id: String {
        idComercio
    }
}
