//
//  NotificationManager.swift
//  livery
//
//  Created by Nicolas Matias Garay on 30/12/2025.
//
import FirebaseMessaging
import UserNotifications

class NotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()
    private let localGroupedFlagKey = "__local_grouped_chat"

    var perfilUsuarioState: PerfilUsuarioState?

    private override init() {
        super.init()
    }

    // MARK: - MessagingDelegate

    /// Equivalente a onNewToken en Android.
    /// Se llama cuando FCM rota o asigna un nuevo token.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard fcmToken != nil else { return }
        Task {
            await perfilUsuarioState?.generarTokenFCM()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Equivalente a onMessageReceived en Android.
    /// Se dispara cuando llega una notificación y la app está en PRIMER PLANO.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Evita reprogramar una notificacion local que ya fue agrupada.
        if (userInfo[localGroupedFlagKey] as? Bool) == true {
            completionHandler([.banner, .sound, .badge])
            return
        }

        guard let tipo = userInfo["tipo"] as? String, tipo.hasPrefix("NUEVO_MENSAJE_") else {
            completionHandler([.banner, .sound, .badge])
            return
        }

        let threadIdentifier = construirThreadIdentifier(userInfo: userInfo)
        let original = notification.request.content

        let contenidoAgrupado = UNMutableNotificationContent()
        contenidoAgrupado.title = original.title
        contenidoAgrupado.body = original.body
        contenidoAgrupado.sound = .default
        contenidoAgrupado.badge = original.badge
        contenidoAgrupado.userInfo = userInfo.merging([localGroupedFlagKey: true]) { current, _ in current }
        contenidoAgrupado.threadIdentifier = threadIdentifier
        contenidoAgrupado.summaryArgument = "chat"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: contenidoAgrupado,
            trigger: nil
        )

        center.add(request)

        // Oculta la notificacion remota original para evitar duplicados.
        completionHandler([])
        return
    }

    private func construirThreadIdentifier(userInfo: [AnyHashable: Any]) -> String {
        let tipo = (userInfo["tipo"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "GEN"
        let idPedido = (userInfo["idPedido"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let idReparto = (userInfo["idReparto"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        if let idPedido {
            return "CHAT_\(tipo)_PEDIDO_\(idPedido)"
        }

        if let idReparto {
            return "CHAT_\(tipo)_REPARTO_\(idReparto)"
        }

        return "CHAT_\(tipo)"
    }

    /// Se dispara cuando el usuario toca la notificación (foreground o background).
    /// Equivalente al PendingIntent con FLAG_ACTIVITY_CLEAR_TOP en Android.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
