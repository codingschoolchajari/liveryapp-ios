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
    static let userDefaults = UserDefaults(suiteName: "group.livery.app")
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var usuario: Usuario? = nil
    @Published var configuracion: Configuracion?
    
    @Published var idDireccionSeleccionada: String? = nil
    @Published var ciudadSeleccionada: String? = nil
    
    @Published var cargaInicialFinalizada: Bool = false
    
    var categoriaSeleccionadaHome: String? = nil
    
    private let configuracionesService = ConfiguracionesService()
    private let coberturasService = CoberturasService()
    private let usuariosService = UsuariosService()
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    func inicializacion() async {
        iniciarAlmacenamientoLocal()
        iniciarCurrentUser()
        await buscarConfiguracion()
        await cargarDireccionSeleccionada()
        await obtenerCiudadSeleccionada()
        
        cargaInicialFinalizada = true
    
        Publishers.CombineLatest(
            $idDireccionSeleccionada,
            $usuario
        )
        .sink { [weak self] _, _ in
            guard let self else { return }

            Task {
                await self.obtenerCiudadSeleccionada()
            }
        }
        .store(in: &cancellables)
    }
    
    func iniciarAlmacenamientoLocal(){
        let key = ConfiguracionesUtil.ID_DISPOSITIVO_KEY
        
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
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
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
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
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
    
    // Configuracion
    func buscarConfiguracion() async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: self)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        do {
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            self.configuracion = try await configuracionesService.buscar(
                token: accessToken,
                dispositivoID: dispositivoID
            )
        } catch {
            print("Error al buscar configuracion: \(error)")
        }
    }
    
    // Direccion
    func obtenerDireccionSeleccionada() -> String {
        let direccion = usuario?.direcciones?
            .first { $0.id == idDireccionSeleccionada }
        
        return direccion.map {
            StringUtils.formatearDireccion($0.calle, $0.numero, $0.departamento)
        } ?? ""
    }
    
    func actualizarDireccionSeleccionada(idDireccion: String) async {
        self.idDireccionSeleccionada = idDireccion
        
        UserDefaults.standard.set(
            idDireccion,
            forKey: ConfiguracionesUtil.ID_DIRECCION_KEY
        )
    }
    
    func cargarDireccionSeleccionada() async {
        let direccionGuardada = UserDefaults.standard.string(
            forKey: ConfiguracionesUtil.ID_DIRECCION_KEY
        )
        
        self.idDireccionSeleccionada = direccionGuardada
    }
    
    func obtenerUsuarioDireccion() -> UsuarioDireccion? {
        return usuario?.direcciones?.first {
            $0.id == idDireccionSeleccionada
        }
    }

    func obtenerCiudadSeleccionada() async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: self)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        do {
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let usuarioDireccion = obtenerUsuarioDireccion()
            
            if let usuarioDireccion {
                let point = usuarioDireccion.coordenadas
                
                var ciudadResponse : CiudadResponse = try await coberturasService.buscarCiudadPorUbicacion(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    latitud: point.coordinates[1],
                    longitud: point.coordinates[0]
                )
                self.ciudadSeleccionada = ciudadResponse.ciudad
            }
        } catch {
            print("Error al obtener ciudad seleccionada")
        }
    }
}

