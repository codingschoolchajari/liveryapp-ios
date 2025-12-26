//
//  Promocion.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Promocion: Codable, Identifiable {
    let idInterno: String
    var nombre: String = ""
    var descripcion: String = ""
    let precio: Double
    var disponible: Bool = true
    var imagenURL: String = ""
    var productosNoSeleccionables: [String] = []
    var productosSeleccionables: [String] = []
    
    var id: String { idInterno }
}
