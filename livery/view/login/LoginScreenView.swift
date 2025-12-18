//
//  LoginScreenView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct LoginScreenView: View {
    // Controla si el usuario está logueado
    @AppStorage("logueado") var logueado: Bool = false
    
    var body: some View {
        if logueado {
            //SeccionesView()
        } else {
            LoginView()
        }
    }
}

struct LoginView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(height: 60)
                
                Image("personaje")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                
                Spacer().frame(height: 40)
                
                SignInView()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct SignInView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var currentNonce: String?
    
    var body: some View {
        VStack {
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        loginViewModel.handleAuthorization(
                            authorization,
                            perfilUsuarioState,
                            currentNonce
                        )
                    case .failure(let error):
                        print("Error en la autenticación: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(width: 250, height: 40)
        }
        .padding(.bottom, 10)
    }
}
