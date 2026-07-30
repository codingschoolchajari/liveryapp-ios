//
//  SplashScreenView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 17/12/2025.
//
import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @AppStorage("logueado") var logueado: Bool = false
    
    var body: some View {
        LottieView(animationName: "splash_screen", endFrame: 171) {
            Task {
                // 1. Ejecutamos TODA la inicialización
                await perfilUsuarioState.inicializacion()
                
                // 2. Si existe una sesión real, no la expulsamos por fallas transitorias
                if logueado && perfilUsuarioState.tieneSesionAutenticada {
                    await perfilUsuarioState.generarTokenFCM()

                    if perfilUsuarioState.usuario == nil {
                        navManager.replaceRoot(with: .main)
                        navManager.select(.home)
                    }
                } else {
                    // No hay sesión → awaitar configuración completa del invitado
                    // (sign-in anónimo + estado) y luego navegar.
                    logueado = false
                    carritoViewModel.limpiarCarrito()
                    await perfilUsuarioState.configurarUsuarioInvitado()

                    // Verificar nueva versión antes de navegar a main
                    if let config = perfilUsuarioState.configuracion {
                        let versionRequerida = config.plataformas.versionIOS
                        let versionApp = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                        if !versionRequerida.isEmpty && hayNuevaVersionDisponible(versionApp: versionApp, versionRequerida: versionRequerida) {
                            navManager.replaceRoot(with: .versionNueva)
                            return
                        }
                    }

                    navManager.replaceRoot(with: .main)
                    navManager.select(.home)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
