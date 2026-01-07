//
//  AppDelegate.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI
import FirebaseCore
import GoogleMaps
import GooglePlaces
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Firebase
        FirebaseApp.configure()

        // Google Maps
        if let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
        ) as? String {
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)
        }
        
        // Registro para el token de Apple (necesario para FCM)
        application.registerForRemoteNotifications()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            // Este es el puente: Apple le da el token a la App, y la App se lo da a Firebase
            Messaging.messaging().apnsToken = deviceToken
        }
        
        // Opcional: Para debugear si Apple falla en darte el token
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("❌ Error al registrarse en APNs (Apple): \(error.localizedDescription)")
        }
}

