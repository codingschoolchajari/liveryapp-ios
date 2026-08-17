//
//  Categoria.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Categoria: Codable, Identifiable {
    let idInterno: String
    var nombre: String = ""
    var imagenGenerica: String? = ""
    var menuOpcion: String? = nil
    var productos: [Producto] = []
    var seleccionables: [Seleccionable]? = []
    var seleccionablesGrupos: [SeleccionableGrupo]? = []
    
    var id: String { idInterno }
}
