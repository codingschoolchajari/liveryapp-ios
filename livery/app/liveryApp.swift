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
    
    @StateObject var navManager = NavigationManager()
    @StateObject var perfilUsuarioState = PerfilUsuarioState()
    @StateObject var carritoViewModel = CarritoViewModel()

    var body: some Scene {
        WindowGroup {
            // RootContainerView decidirá qué pantalla mostrar según la fase
            RootContainerView()
                .environmentObject(navManager)
                .environmentObject(perfilUsuarioState)
                .environmentObject(carritoViewModel)
        }
    }
}

struct RootContainerView: View {
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @AppStorage("logueado") var logueado: Bool = false

    var body: some View {
        Group {
            switch navManager.currentPhase {
            case .loading:
                SplashScreenView()
            case .auth:
                LoginView()
            case .registration:
                DatosPersonalesView()
            case .main:
                SeccionesView()
            }
        }
        .onChange(of: perfilUsuarioState.usuario) { oldUser, newUser in
            // Solo navegamos si el usuario realmente cambió y estamos logueados
            guard logueado, let user = newUser else {
                if !logueado { navManager.replaceRoot(with: .auth) }
                return
            }
            
            // Decidimos la fase final (Navegación real)
            if user.tienePerfilCompleto {
                navManager.replaceRoot(with: .main)
                navManager.select(.home)
            } else {
                navManager.replaceRoot(with: .registration)
            }
        }
        .onChange(of: logueado) { oldVal, newVal in
            if newVal == true && perfilUsuarioState.usuario != nil {
                // Caso donde ya teníamos el usuario pero apenas nos enteramos que estamos logueados
                if perfilUsuarioState.usuario!.tienePerfilCompleto {
                    navManager.replaceRoot(with: .main)
                    navManager.select(.home)
                } else {
                    navManager.replaceRoot(with: .registration)
                }
            }
        }
    }
}
