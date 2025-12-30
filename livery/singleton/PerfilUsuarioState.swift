//
//  PerfilUsuarioState.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseMessaging
import SwiftUI
import UIKit

@MainActor
class PerfilUsuarioState: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "group.livery.app")
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var usuario: Usuario? = nil
    @Published var configuracion: Configuracion?
    
    @Published var idDireccionSeleccionada: String? = nil
    @Published var ciudadSeleccionada: String? = nil
    
    var categoriaSeleccionadaHome: String? = nil
    
    private let configuracionesService = ConfiguracionesService()
    private let coberturasService = CoberturasService()
    private let usuariosService = UsuariosService()
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    func inicializacion() async {
        iniciarAlmacenamientoLocal()
        await validarYSincronizarSesion()
        await buscarConfiguracion()
        await cargarDireccionSeleccionada()
        
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
    
    func validarYSincronizarSesion() async {
        // Capturamos el usuario de Firebase
        let firebaseUser = Auth.auth().currentUser
        self.currentUser = firebaseUser
        
        if let user = firebaseUser {
            do {
                // Intentamos obtener el token.
                // Si expiró, Firebase lo refresca automáticamente aquí.
                let token = try await user.getIDToken(forcingRefresh: false)
                print("Token validado/refrescado correctamente")
                
                // 2. Una vez que el token es seguro, buscamos al usuario en TU backend
                await buscarUsuario()
                
            } catch {
                print("Sesión de Firebase expirada o inválida: \(error.localizedDescription)")
                self.usuario = nil
                self.currentUser = nil
                // Aquí podrías marcar logueado = false si el error es de autenticación
            }
        } else {
            // No hay usuario en Firebase
            self.usuario = nil
        }
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
    
    func actualizarDatosPersonales(nombre: String, apellido: String, dni: Int) async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: self)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        do {
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let datosPersonales = UsuarioDatosPersonales(
                nombre: nombre,
                apellido: apellido,
                dni: dni
            )

            guard let email = currentUser?.email else {
                print("No hay sesión de usuario activa")
                return
            }

            try await usuariosService.actualizarDatosPersonales(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                datosPersonales: datosPersonales
            )
            
        } catch {
            print("Error al actualizar Datos Personales: \(error.localizedDescription)")
        }
    }
    
    func obtenerFirebaseIdToken() async -> String? {
        do {
            // Esperamos a que Firebase nos dé el token
            if let token = try await Auth.auth().currentUser?.getIDToken() {
                return token
            }
        } catch {
            print("❌ Error obteniendo el token: \(error.localizedDescription)")
        }
        return nil
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
                
                let ciudadResponse : CiudadResponse = try await coberturasService.buscarCiudadPorUbicacion(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    latitud: point.coordinates[0],
                    longitud: point.coordinates[1]
                )
                if ciudadResponse.ciudad.isEmpty {
                    self.ciudadSeleccionada = StringUtils.sinCobertura
                } else {
                    self.ciudadSeleccionada = ciudadResponse.ciudad
                }
            }
        } catch {
            print("Error al obtener ciudad seleccionada: \(error)")
        }
    }
    
    func eliminarDireccion(idDireccion: String) async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: self)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
    
        guard let email = currentUser?.email, !email.isEmpty else {
            return
        }

        do {
            // 3. Llamada al repositorio/servicio (Equivalente a usuariosRepository)
            // Usamos 'try await' para el concepto de 'suspend'
            try await usuariosService.eliminarDireccion(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idDireccion: idDireccion
            )
            
            await buscarUsuario()

            if self.idDireccionSeleccionada == idDireccion {
                let nuevaDireccionID = usuario?.direcciones?.first?.id ?? ""
                
                self.idDireccionSeleccionada = nuevaDireccionID
                UserDefaults.standard.set(nuevaDireccionID, forKey: ConfiguracionesUtil.ID_DIRECCION_KEY)
            }
            
        } catch {
            print("Error al eliminar dirección: \(error)")
        }
    }
    
    // Favoritos
    
    func agregarFavorito(
            idFavorito: String,
            idComercio: String,
            nombreComercio: String,
            logoComercioURL: String,
            idProducto: String?,
            idPromocion: String?,
            nombre: String,
            imagenURL: String?
    ) async {
        guard let email = currentUser?.email, !email.isEmpty else { return }
        
        // 1. CREAR EL OBJETO
        let nuevoFavorito = UsuarioFavorito(
            id: idFavorito,
            idComercio: idComercio,
            nombreComercio: nombreComercio,
            logoComercioURL: logoComercioURL,
            idProducto: idProducto,
            idPromocion: idPromocion,
            nombre: nombre,
            imagenURL: imagenURL
        )

        // 2. ACTUALIZACIÓN OPTIMISTA: Modificar localmente antes de la red
        let copiaUsuarioPrevio = self.usuario // Guardamos copia por si hay que revertir
        if var favoritos = self.usuario?.favoritos {
            favoritos.append(nuevoFavorito)
            self.usuario?.favoritos = favoritos // Reasignamos el array modificado
        }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: self)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            try await usuariosService.agregarFavorito(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                usuarioFavorito: nuevoFavorito
            )
            
            // 3. Sincronizar con el servidor para asegurar consistencia
            await buscarUsuario()
            
        } catch {
            // 4. REVERTIR si falla
            self.usuario = copiaUsuarioPrevio
            print("Error al agregar favorito: \(error.localizedDescription)")
        }
    }

    func eliminarFavorito(idFavorito: String?) async {
        guard let email = currentUser?.email, !email.isEmpty, let id = idFavorito else { return }
        
        // 1. ACTUALIZACIÓN OPTIMISTA
        let copiaUsuarioPrevio = self.usuario
        if var favoritos = self.usuario?.favoritos {
            favoritos.removeAll(where: { $0.id == id })
            self.usuario?.favoritos = favoritos // Reasignamos el array modificado
        }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: self)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            try await usuariosService.eliminarFavorito(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idFavorito: id
            )
            
            await buscarUsuario()
            
        } catch {
            // REVERTIR si falla el borrado en el servidor
            self.usuario = copiaUsuarioPrevio
            print("Error al eliminar favorito: \(error.localizedDescription)")
        }
    }
    
    // Notificaciones
    func generarTokenFCM() async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: self)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            // 1. Obtener el token de FCM (Equivalente a .token.await())
            let tokenFCM = try await Messaging.messaging().token()
            
            // 3. Obtener el email del usuario (Asumiendo que usas Firebase Auth)
            let email = currentUser?.email ?? ""
            
            // 4. Llamar a tu repositorio para actualizar en el backend
            // Nota: Asegúrate de que tu función en el repo sea 'async'
            try await usuariosService.actualizarTokenFCM(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                tokenFCM: tokenFCM
            )
            
            print("✅ Token FCM actualizado con éxito: \(tokenFCM)")
            
        } catch {
            print("❌ El tokenFCM no ha podido ser generado o enviado: \(error.localizedDescription)")
        }
    }
}

