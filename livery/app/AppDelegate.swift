//
//  AppDelegate.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI
import FirebaseCore
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
}

