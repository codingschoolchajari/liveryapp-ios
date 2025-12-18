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
                    print("Error al autenticar con Firebase: \(error.localizedDescription)")
                    return
                }

                // Usuario autenticado correctamente
                if let uid = authResult?.user.uid {
                    print("Usuario autenticado con UID: \(uid)")
                }

                Task {
                    perfilUsuarioState.inicializacion()
                }

                self.logueado = true
            }
        }
    }
    
    // Método para desloguearse
    func signOut() {
        do {
            try Auth.auth().signOut()
            logueado = false
            print("Usuario deslogueado correctamente")
        } catch let error as NSError {
            print("Error al desloguear: \(error)")
        }
    }
}
