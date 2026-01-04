//
//  Chat.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Mensaje: Codable, Identifiable {
    // ID calculado para garantizar unicidad en la UI
    var id: String {
        return "\(timestamp)_\(emisorId)_\(texto.hashValue)"
    }
    
    var texto: String = ""
    var emisorId: String = ""
    var emisorNombre: String = ""
    var timestamp: Int64 = 0

    enum CodingKeys: String, CodingKey {
        case texto
        case emisorId
        case emisorNombre
        case timestamp
    }
}

struct Chat: Codable {
    var idInterno: String = ""
    var idPedido: String = ""
    var emailUsuario: String = ""
    var idComercio: String? = nil
    var idRepartidor: String? = nil
    var mensajes: [Mensaje] = []
}
