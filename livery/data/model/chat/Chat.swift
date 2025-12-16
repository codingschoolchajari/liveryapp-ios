//
//  Chat.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Mensaje: Codable {
    var texto: String = ""
    var emisorId: String = ""
    var emisorNombre: String = ""
    var timestamp: Int64 = 0
}

struct Chat: Codable {
    var idInterno: String = ""
    var idPedido: String = ""
    var emailUsuario: String = ""
    var idComercio: String? = nil
    var idRepartidor: String? = nil
    var mensajes: [Mensaje] = []
}
