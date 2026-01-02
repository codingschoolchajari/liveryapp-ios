//
//  Notificacion.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct Notificacion: Codable, Identifiable {
    var id = UUID()
    let titulo: String
    let mensaje: String
    let idPedido: String
    var idChat: String? = nil
}
