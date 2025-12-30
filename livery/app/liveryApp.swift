//
//  liveryApp.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/12/2025.
//
import SwiftUI
import FirebaseMessaging

@main
struct liveryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var navManager = NavigationManager()
    @StateObject var perfilUsuarioState = PerfilUsuarioState()
    @StateObject var notificacionesState = NotificacionesState()
    @StateObject var carritoViewModel = CarritoViewModel()

    @State private var notificationManager: NotificationManager?
    
    var body: some Scene {
        WindowGroup {
            // RootContainerView decidirá qué pantalla mostrar según la fase
            RootContainerView()
                .environmentObject(navManager)
                .environmentObject(perfilUsuarioState)
                .environmentObject(notificacionesState)
                .environmentObject(carritoViewModel)
                .onAppear {
                    // Inicializamos el manager pasando el estado que ya existe en SwiftUI
                    let manager = NotificationManager(notificacionesState: notificacionesState)
                    
                    // Asignamos delegados
                    UNUserNotificationCenter.current().delegate = manager
                    Messaging.messaging().delegate = manager
                    
                    // Guardamos la referencia en el @State
                    self.notificationManager = manager
                }
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
            if navManager.currentPhase != .main {
                if user.tienePerfilCompleto {
                    navManager.replaceRoot(with: .main)
                    navManager.select(.home)
                } else if navManager.currentPhase != .registration {
                    // Evitamos loops si ya estamos en registro
                    navManager.replaceRoot(with: .registration)
                }
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
