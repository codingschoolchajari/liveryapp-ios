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
    @Environment(\.scenePhase) var scenePhase
    
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                ImageCache.shared.clearAll()
            }
        }
    }
}

struct RootContainerView: View {
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @AppStorage("logueado") var logueado: Bool = false

    private var formularioDatosPersonalesHabilitado: Bool? {
        perfilUsuarioState
            .configuracion?
            .configuracionIOS
            .formularioDatosPersonalesHabilitado
    }

    private func navegarSegunEstadoActual() {
        // Primero verificar si hay nueva versión obligatoria (independiente del estado de login)
        if let config = perfilUsuarioState.configuracion {
            let versionRequerida = config.plataformas.versionIOS
            let versionApp = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            if !versionRequerida.isEmpty && hayNuevaVersionDisponible(versionApp: versionApp, versionRequerida: versionRequerida) {
                navManager.replaceRoot(with: .versionNueva)
                return
            }
        }

        guard logueado else {
            // La navegación en modo invitado es manejada exclusivamente por
            // SplashScreenView y signOut, que awaitan configurarUsuarioInvitado()
            // antes de navegar. No navegamos aquí para evitar race conditions.
            return
        }

        // Si el estado local dice "logueado" pero Firebase no tiene usuario válido,
        // forzamos autenticación para evitar quedar en Home con estado inconsistente.
        guard let firebaseUser = perfilUsuarioState.currentUser,
              !firebaseUser.isAnonymous else {
            logueado = false
            if navManager.currentPhase != .auth {
                navManager.replaceRoot(with: .auth)
            }
            return
        }

        guard let user = perfilUsuarioState.usuario else {
            Task {
                await perfilUsuarioState.buscarUsuario()
            }
            return
        }

        // Evitamos decisiones intermedias hasta terminar la carga de configuración.
        guard perfilUsuarioState.configuracionCargada else {
            return
        }

        guard let formularioHabilitado = formularioDatosPersonalesHabilitado else {
            return
        }

        if !formularioHabilitado {
            if navManager.currentPhase != .main {
                navManager.replaceRoot(with: .main)
                navManager.select(.home)
            }
            return
        }

        if user.tienePerfilCompleto {
            if navManager.currentPhase != .main {
                navManager.replaceRoot(with: .main)
                navManager.select(.home)
            }
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
            case .versionNueva:
                VersionNuevaView()
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
        .onChange(of: perfilUsuarioState.configuracionCargada) { _, _ in
            navegarSegunEstadoActual()
        }
        .onAppear {
            navegarSegunEstadoActual()
        }
    }
}
