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

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Firebase (solo para autenticación, no para notificaciones)
        FirebaseApp.configure()

        // Google Maps
        if let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
        ) as? String {
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)
        }
        
        // Ya no registramos para notificaciones remotas
        // application.registerForRemoteNotifications()

        return true
    }
    
    // Los métodos de notificaciones remotas ya no son necesarios
    // func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) { }
    // func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { }
}

