//
//  NotificacionManager.swift
//  livery
//
//  Created by Nicolas Matias Garay on 30/12/2025.
//
import Firebase
import FirebaseMessaging
import UserNotifications

class NotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    var notificacionesState: NotificacionesState
    
    init(notificacionesState: NotificacionesState) {
        self.notificacionesState = notificacionesState
        super.init()
    }
    
    // Este método equivale al onMessageReceived de Android
    // Se dispara cuando llega una notificación y la app está en PRIMER PLANO (Foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        // Extraemos la data (FCM envía la data en el diccionario userInfo)
        let titulo = userInfo["titulo"] as? String ?? ""
        let mensaje = userInfo["mensaje"] as? String ?? ""
        let idPedido = userInfo["idPedido"] as? String ?? ""
        let idChat = userInfo["idChat"] as? String
        
        Task {
            // Extraemos el valor de forma segura
            let idChatActual = await notificacionesState.idChatVisible
            
            // Ahora hacemos la comparación con la variable local
            let esChatVisible = idChat != nil && idChatActual == idChat
            
            if !esChatVisible {
                let nuevaNotificacion = Notificacion(
                    titulo: titulo,
                    mensaje: mensaje,
                    idPedido: idPedido,
                    idChat: idChat
                )
                
                await notificacionesState.agregarNotificacion(nuevaNotificacion)
            }
        }
    }
}
