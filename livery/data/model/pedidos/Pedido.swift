//
//  Pedido.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Estado: Codable {
    let fechaCreacion: String
    let fechaUltimaActualizacion: String
    var nombre: String = ""
    var horaEstimadaEntrega: String? = nil
    var extra: String? = nil
}

struct Pedido: Codable, Identifiable {
    let idInterno: String
    let email: String
    let nombreUsuario: String
    let idComercio: String
    let nombreComercio: String
    var logoComercioURL: String = ""
    var idRepartidor: String? = nil
    let direccion: UsuarioDireccion
    let notas: String
    var tipoEntrega: String = ""
    let tarifaServicio: Double
    let envio: Double
    var tiempoRecorridoEstimado: Int? = nil
    let precioTotal: Double
    let itemsProductos: [ItemProducto]
    let itemsPromociones: [ItemPromocion]
    var estado: Estado? = nil
    var comentario: Comentario? = nil
    
    var id: String {
        idInterno
    }
    
    // CodingKeys para evitar errores con campos extra como _id
    enum CodingKeys: String, CodingKey {
        case idInterno, email, nombreUsuario, idComercio, nombreComercio
        case logoComercioURL, idRepartidor, direccion, notas
        case tipoEntrega, tarifaServicio, envio, tiempoRecorridoEstimado
        case precioTotal, itemsProductos, itemsPromociones, estado, comentario
    }
}
