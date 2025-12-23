//
//  LoginViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import Foundation
import SwiftUI
import AuthenticationServices
import FirebaseAuth

@MainActor
class LoginViewModel: ObservableObject {
    
    @AppStorage("logueado") var logueado: Bool = false
    
    func handleAuthorization(
        _ authorization: ASAuthorization,
        _ perfilUsuarioState: PerfilUsuarioState,
        _ currentNonce: String?
    ) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }

            guard let identityToken = appleIDCredential.identityToken else {
                print("No se pudo obtener el token de identidad")
                return
            }

            guard let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("No se pudo convertir el token de identidad a string")
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                Task {
                    // 1. Preparamos el estado (Token, CurrentUser, etc)
                    await perfilUsuarioState.inicializacion()
                    await perfilUsuarioState.actualizarUsuario()
                    
                    // 2. Activamos el flag de logueado ANTES de buscar el usuario
                    // Esto permite que el RootContainer esté listo para escuchar el cambio del objeto usuario
                    await MainActor.run {
                        self.logueado = true
                    }

                    // 3. Buscamos el usuario en el backend.
                    // Al asignarse self.usuario dentro de esta función, el RootContainer reaccionará.
                    await perfilUsuarioState.buscarUsuario()
                }
            }
        }
    }
    
    // Método para desloguearse
    func signOut(
        perfilUsuarioState: PerfilUsuarioState
    ) {
        do {
            try Auth.auth().signOut()
            
            // IMPORTANTE: Limpiar el estado en memoria
            DispatchQueue.main.async {
                perfilUsuarioState.usuario = nil
                perfilUsuarioState.currentUser = nil
                // Aquí reseteamos el flag que observa el RootContainer
                UserDefaults.standard.set(false, forKey: "logueado")
            }
            
            print("Usuario deslogueado y estado limpiado")
        } catch let error as NSError {
            print("Error al desloguear: \(error)")
        }
    }
}
