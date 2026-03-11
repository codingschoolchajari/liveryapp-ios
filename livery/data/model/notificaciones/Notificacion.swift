//
//  Notificacion.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

// Modelo para mensajes individuales de notificación
struct NotificacionMensaje: Codable {
    let titulo: String
    let mensaje: String
    let estado: String
    let fechaCreacion: String
}

// Modelo principal de notificaciones
struct Notificaciones: Codable, Identifiable {
    var id: String { 
        return idPedido ?? idReparto ?? UUID().uuidString
    }
    let receptor: String
    let idPedido: String?
    let idReparto: String?
    let fechaUltimaActualizacion: String
    let mensajes: [NotificacionMensaje]
}

// Modelo para marcar notificaciones como leídas
struct LecturaNotificacionItem: Codable {
    let idPedido: String?
    let idReparto: String?
    let hastaFechaCreacion: String
}

struct MarcarNotificacionesLeidasRequest: Codable {
    let receptor: String
    let tipo: String
    let items: [LecturaNotificacionItem]
}

// Modelo simplificado para UI (opcional, similar a NotificacionUI de Android)
struct NotificacionUI: Identifiable {
    let id = UUID()
    let idReferencia: String
    let titulo: String
    let mensaje: String
    let estado: String
}
