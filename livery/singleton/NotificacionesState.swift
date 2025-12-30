//
//  NotificacionesState.swift
//  livery
//
//  Created by Nicolas Matias Garay on 30/12/2025.
//
import Foundation
import Combine

@MainActor
class NotificacionesState: ObservableObject {
    
    @Published var idChatVisible: String? = nil
    @Published var notificacionesNoLeidas: [Notificacion] = []
    @Published var notificacionesLeidas: [Notificacion] = []
    
    func agregarNotificacion(_ notificacion: Notificacion) {
        // Si la notificación pertenece a un chat
        if let idChat = notificacion.idChat {
            // No agrega si ya existe una pendiente no leída para ese chat
            if notificacionesNoLeidas.contains(where: { $0.idChat == idChat }) {
                return
            }
        }
        self.notificacionesNoLeidas.insert(notificacion, at: 0)
    }
    
    func marcarTodasComoLeidas() {
        // Combinamos las listas
        let todas = self.notificacionesNoLeidas + self.notificacionesLeidas
        
        // Tomamos las últimas 15 (Equivalente a takeLast)
        self.notificacionesLeidas = Array(todas.suffix(15))
        
        // Limpiamos las no leídas
        self.notificacionesNoLeidas = []
    }
    
    func setChatVisible(idChat: String) {
        self.idChatVisible = idChat
    }
    
    func limpiarChatVisible() {
        self.idChatVisible = nil
    }
}
