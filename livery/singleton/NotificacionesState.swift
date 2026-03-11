//
//  NotificacionesState.swift
//  livery
//
//  Created by Nicolas Matias Garay on 30/12/2025.
//
import Foundation
import Combine

// Constantes de tipos y estados
let TIPO_PEDIDOS = "pedidos"
let TIPO_REPARTOS = "repartos"
let ESTADO_NO_LEIDO = "NO_LEIDO"
let ESTADO_LEIDO = "LEIDO"

@MainActor
class NotificacionesState: ObservableObject {
    
    // Notificaciones obtenidas del backend
    @Published var notificaciones: [Notificaciones] = []
    
    private let notificacionesService = NotificacionesService()
    private let tokenService = TokenService()
    
    // Referencia a PerfilUsuarioState (se inyecta desde la app)
    weak var perfilUsuarioState: PerfilUsuarioState?
    
    // Refresca las notificaciones desde el backend
    func refrescarNotificaciones(receptor: String) {
        Task {
            do {
                // Obtener token y dispositivoID
                guard let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) else {
                    print("❌ No se encontró dispositivoID")
                    return
                }
                
                // Validar y obtener el token
                if let perfilState = perfilUsuarioState {
                    await TokenRepository.repository.validarToken(perfilUsuarioState: perfilState)
                }
                
                guard let token = TokenRepository.repository.accessToken else {
                    print("❌ No se encontró access token")
                    return
                }
                
                let notificacionesObtenidas = try await notificacionesService.obtenerNotificaciones(
                    token: token,
                    dispositivoID: dispositivoID,
                    receptor: receptor,
                    tipo: TIPO_PEDIDOS
                )
                
                self.notificaciones = notificacionesObtenidas
            } catch {
                print("❌ Error al refrescar notificaciones: \(error)")
            }
        }
    }
    
    // Marca las notificaciones visibles como leídas
    func marcarVisiblesComoLeidas(receptor: String) {
        let itemsLectura = construirItemsLectura(notificaciones: notificaciones)
        
        if itemsLectura.isEmpty {
            return
        }
        
        // Marcar localmente primero
        marcarLeidasLocal()
        
        // Luego enviar al backend
        Task {
            do {
                guard let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) else {
                    return
                }
                
                // Validar y obtener el token
                if let perfilState = perfilUsuarioState {
                    await TokenRepository.repository.validarToken(perfilUsuarioState: perfilState)
                }
                
                guard let token = TokenRepository.repository.accessToken else {
                    return
                }
                
                let request = MarcarNotificacionesLeidasRequest(
                    receptor: receptor,
                    tipo: TIPO_PEDIDOS,
                    items: itemsLectura
                )
                
                try await notificacionesService.marcarLeidas(
                    token: token,
                    dispositivoID: dispositivoID,
                    request: request
                )
            } catch {
                print("❌ Error al marcar notificaciones como leídas: \(error)")
            }
        }
    }
    
    // Construye los items de lectura para el backend
    private func construirItemsLectura(notificaciones: [Notificaciones]) -> [LecturaNotificacionItem] {
        return notificaciones.compactMap { notificacion in
            let mensajesNoLeidos = notificacion.mensajes.filter {
                $0.estado == ESTADO_NO_LEIDO && !$0.fechaCreacion.isEmpty
            }
            
            guard !mensajesNoLeidos.isEmpty,
                  let ultimaFecha = mensajesNoLeidos.last?.fechaCreacion else {
                return nil
            }
            
            return LecturaNotificacionItem(
                idPedido: notificacion.idPedido,
                idReparto: notificacion.idReparto,
                hastaFechaCreacion: ultimaFecha
            )
        }
    }
    
    // Marca localmente como leídas (actualiza el estado local)
    private func marcarLeidasLocal() {
        notificaciones = notificaciones.map { notificacion in
            var nuevaNotificacion = notificacion
            var nuevosMensajes = notificacion.mensajes.map { mensaje in
                var nuevoMensaje = mensaje
                if mensaje.estado == ESTADO_NO_LEIDO {
                    nuevoMensaje = NotificacionMensaje(
                        titulo: mensaje.titulo,
                        mensaje: mensaje.mensaje,
                        estado: ESTADO_LEIDO,
                        fechaCreacion: mensaje.fechaCreacion
                    )
                }
                return nuevoMensaje
            }
            
            // Crear una nueva instancia con los mensajes actualizados
            return Notificaciones(
                receptor: notificacion.receptor,
                idPedido: notificacion.idPedido,
                idReparto: notificacion.idReparto,
                fechaUltimaActualizacion: notificacion.fechaUltimaActualizacion,
                mensajes: nuevosMensajes
            )
        }
    }
}

// Helper para mapear notificaciones a UI (similar a Android)
func mapearNotificacionesParaUI(notificaciones: [Notificaciones]) -> [NotificacionUI] {
    return notificaciones.flatMap { notificacion in
        guard let idPedido = notificacion.idPedido else {
            return [NotificacionUI]()
        }
        
        return notificacion.mensajes.map { mensaje in
            NotificacionUI(
                idReferencia: idPedido,
                titulo: mensaje.titulo,
                mensaje: mensaje.mensaje,
                estado: mensaje.estado
            )
        }
    }
}
