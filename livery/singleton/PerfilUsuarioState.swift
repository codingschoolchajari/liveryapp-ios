//
//  PerfilUsuarioState.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import Foundation
import Combine
import FirebaseAuth
import SwiftUI

@MainActor
class PerfilUsuarioState: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "group.livery.app")!
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var usuario: Usuario? = nil
    
    private let usuariosService = UsuariosService()
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    func inicializacion() {
        iniciarAlmacenamientoLocal()
        iniciarListenerAuth()
    }
    
    func iniciarAlmacenamientoLocal(){
        let key = ConfiguracionesUtil.DISPOSITIVO_ID_KEY
        
        if let dispositivoID = UserDefaults.standard.object(forKey: key) {
            print("DispositivoID encontrado: \(dispositivoID)")
        } else {
            let nuevoDispositivoID = UUID().uuidString
            
            UserDefaults.standard.set(nuevoDispositivoID, forKey: key)
            print("Nuevo DispositivoID: \(nuevoDispositivoID)")
        }
    }
    func iniciarListenerAuth() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            self.currentUser = user
            
            if let user {
                Task {
                    await self.buscarUsuario()
                }
            } else {
                self.usuario = nil
            }
        }
    }
    
    func buscarUsuario() async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: self)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        do{
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
            
            self.usuario = try await usuariosService.buscarUsuario(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: currentUser?.email ?? ""
            )
        }
        catch {
            print("Error al buscar usuario: \(error)")
        }
    }
    
    func obtenerFirebaseIdToken() async -> String? {
        try? await Auth.auth().currentUser?.getIDToken()
    }
}
