//
//  AppDelegate.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI
import FirebaseCore
import GoogleMaps

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
        }

        return true
    }
}

