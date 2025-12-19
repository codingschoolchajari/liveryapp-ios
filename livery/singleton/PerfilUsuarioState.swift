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
    
    @Published var ciudadSeleccionada: String? = nil
    
    var categoriaSeleccionadaHome: String? = nil
    
    private let usuariosService = UsuariosService()
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    func inicializacion() {
        iniciarAlmacenamientoLocal()
        iniciarCurrentUser()
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
    
    func iniciarCurrentUser() {
        self.currentUser = Auth.auth().currentUser
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
    
    func actualizarUsuario() async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: self)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        do{
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
            
            let usuarioActualizado = Usuario (
                email: currentUser?.email ?? "",
                nombre: currentUser?.displayName ?? ""
            )
            
            try await usuariosService.actualizarUsuario(
                token: accessToken,
                dispositivoID: dispositivoID,
                usuario: usuarioActualizado
            )
        }
        catch {
            print("Error al actualizar usuario: \(error)")
        }
    }
    func obtenerFirebaseIdToken() async -> String? {
        try? await Auth.auth().currentUser?.getIDToken()
    }
}
