//
//  Categoria.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Categoria: Codable {
    let idInterno: String
    var nombre: String = ""
    var imagenGenerica: Int = 0
    var productos: [Producto] = []
    var seleccionables: [Seleccionable]? = []
}
