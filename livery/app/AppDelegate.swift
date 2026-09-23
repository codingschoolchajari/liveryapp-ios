//
//  AppDelegate.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import FirebaseMessaging
import UserNotifications
import GoogleMaps
import GooglePlaces

class AppDelegate: NSObject, UIApplicationDelegate {

    var perfilUsuarioState: PerfilUsuarioState?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Google Maps
        if let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
        ) as? String {
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)
        }

        // FCM delegate
        Messaging.messaging().delegate = NotificationManager.shared

        // Solicitar permiso y registrar para APNs
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        return true
    }

    // Pasar el token APNs a Firebase para que FCM funcione
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs registration failed: \(error.localizedDescription)")
    }

    // Llamado cuando el sistema abre la app con un archivo compartido desde el share sheet
    // (equivalente a onNewIntent en Android)
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        NotificationCenter.default.post(name: .archivoCompartido, object: url)
        return true
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Publicado por AppDelegate cuando se recibe un archivo desde el share sheet.
    static let archivoCompartido = Notification.Name("archivoCompartido")
}

