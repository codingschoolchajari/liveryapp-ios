//
//  SeleccionableGrupo.swift
//  livery
//

import Foundation

struct SeleccionableGrupo: Codable, Identifiable {
    let idInterno: String
    var nombre: String
    var color: String = "#FFFFFF"

    var id: String { idInterno }
}
