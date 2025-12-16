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

struct Pedido: Codable {
    let idInterno: String
    let email: String
    let nombreUsuario: String
    let idComercio: String
    let nombreComercio: String
    var logoComercioURL: String = ""
    var idRepartidor: String? = nil
    let direccion: UsuarioDireccion
    let notas: String
    var retiroEnComercio: Bool = false
    let tarifaServicio: Double
    let envio: Double
    var tiempoRecorridoEstimado: Int? = nil
    let precioTotal: Double
    let itemsProductos: [ItemProducto]
    let itemsPromociones: [ItemPromocion]
    var estado: Estado? = nil
    var comentario: Comentario? = nil
}
