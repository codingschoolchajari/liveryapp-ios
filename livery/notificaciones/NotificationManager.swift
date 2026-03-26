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
        completionHandler([.banner, .sound, .badge])
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
