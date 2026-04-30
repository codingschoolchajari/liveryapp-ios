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
    @AppStorage("logueado") var logueado: Bool = false
    
    var body: some View {
        LottieView(animationName: "splash_screen", endFrame: 171) {
            Task {
                // 1. Ejecutamos TODA la inicialización
                await perfilUsuarioState.inicializacion()
                
                // 2. Si está logueado, buscamos al usuario
                if logueado {
                    await perfilUsuarioState.buscarUsuario()
                    await perfilUsuarioState.generarTokenFCM()
                    
                    // Si el usuario se encontró, el .onChange del Root lo mandará a Main
                    // Si NO se encontró (perfilUsuarioState.usuario == nil), forzamos salida:
                    if perfilUsuarioState.usuario == nil {
                        navManager.replaceRoot(with: .auth)
                    }
                } else {
                    // No hay sesión → configurar perfil invitado y mostrar home
                    await perfilUsuarioState.configurarUsuarioInvitado()
                    navManager.replaceRoot(with: .main)
                    navManager.select(.home)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
