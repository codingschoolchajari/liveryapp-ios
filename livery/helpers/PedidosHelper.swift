//
//  PedidosHelper.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/01/2026.
//
import SwiftUI

struct PedidosHelper {

    static func obtenerEstadoPedido(estado: String) -> String {
        guard let estadoPedido = EstadoPedido.desdeString(estado) else {
            return ""
        }
        return estadoPedido.descripcion
    }

    static func obtenerColorEstadoPedido(estado: String) -> Color? {
        let estadoPedido = EstadoPedido.desdeString(estado)
        return estadoPedido?.color
    }

    static func generarURLComprobante(pedido: Pedido) -> String {
        return "images/comprobantes/\(pedido.email)/\(pedido.idInterno)/comprobante.jpg"
    }
}
