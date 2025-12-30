//
//  PedidoComentario.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct PedidoComentario: Codable, Identifiable {
    let idInterno: String
    let itemsProductos: [ItemProducto]
    let itemsPromociones: [ItemPromocion]
    let comentario: Comentario
    
    var id: String { idInterno }
}
