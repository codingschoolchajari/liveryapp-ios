//
//  ProductoSeleccionableState.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import Foundation
import Combine

class ProductoSeleccionableState: ObservableObject, Identifiable {
    let idProducto: String
    
    @Published var seleccionadosUnitarios: [String: Bool] = [:]
    @Published var seleccionadosMultiples: [String: Int] = [:]
    
    init(idProducto: String) {
        self.idProducto = idProducto
    }
    
    func cambiarSeleccionadoUnitario(id: String, seleccionado: Bool) {
        seleccionadosUnitarios[id] = seleccionado
    }
    
    func cambiarSeleccionadoMultiple(id: String, cantidad: Int) {
        seleccionadosMultiples[id] = max(0, cantidad)
    }
}
