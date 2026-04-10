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
    @StateObject var notificacionesState = NotificacionesState()
    @StateObject var carritoViewModel = CarritoViewModel()
    
    var body: some Scene {
        WindowGroup {
            // RootContainerView decidirá qué pantalla mostrar según la fase
            RootContainerView()
                .environmentObject(navManager)
                .environmentObject(perfilUsuarioState)
                .environmentObject(notificacionesState)
                .environmentObject(carritoViewModel)
                .onAppear {
                    // Inyectar la referencia de perfilUsuarioState en notificacionesState
                    notificacionesState.perfilUsuarioState = perfilUsuarioState
                    // Inyectar perfilUsuarioState en AppDelegate para renovación del token FCM
                    delegate.perfilUsuarioState = perfilUsuarioState
                    NotificationManager.shared.perfilUsuarioState = perfilUsuarioState
                }
        }
    }
}

struct RootContainerView: View {
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @AppStorage("logueado") var logueado: Bool = false

    private var formularioDatosPersonalesHabilitado: Bool {
        perfilUsuarioState
            .configuracion?
            .configuracionIOS
            .formularioDatosPersonalesHabilitado ?? true
    }

    private func navegarSegunEstadoActual() {
        guard logueado else {
            navManager.replaceRoot(with: .auth)
            return
        }

        guard let user = perfilUsuarioState.usuario else {
            return
        }

        if !formularioDatosPersonalesHabilitado {
            if navManager.currentPhase != .main {
                navManager.replaceRoot(with: .main)
            }
            navManager.select(.home)
            return
        }

        if user.tienePerfilCompleto {
            if navManager.currentPhase != .main {
                navManager.replaceRoot(with: .main)
            }
            navManager.select(.home)
        } else if navManager.currentPhase != .registration {
            navManager.replaceRoot(with: .registration)
        }
    }

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
            navegarSegunEstadoActual()
        }
        .onChange(of: logueado) { oldVal, newVal in
            navegarSegunEstadoActual()
        }
        .onReceive(perfilUsuarioState.$configuracion) { _ in
            navegarSegunEstadoActual()
        }
    }
}
