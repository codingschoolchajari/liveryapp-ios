//
//  liveryApp.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/12/2025.
//
import SwiftUI

@main
struct liveryApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var perfilUsuarioState: PerfilUsuarioState

    init() {
        let perfilUsuarioState = PerfilUsuarioState()
        
        self._perfilUsuarioState = StateObject(wrappedValue: perfilUsuarioState)
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(perfilUsuarioState)
        }
    }
}
