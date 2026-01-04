//
//  PedidoChatViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/01/2026.
//
import Foundation
import Combine
import SwiftUI

@MainActor
class PedidoChatViewModel: ObservableObject {
    
    // Repositorios e Inyecciones
    private let chatsService = ChatsService()
    private let perfilUsuarioState: PerfilUsuarioState
    
    // Propiedades Publicadas (@Published equivale a StateFlow)
    @Published var chat: Chat? = nil
    @Published var mensajes: [Mensaje] = []
    @Published var errorMensaje: String? = nil
    
    // Flujos internos para la combinación (Equivalente a MutableStateFlow)
    @Published private var idPedido: String? = nil
    @Published private var emailUsuario: String? = nil
    @Published private var idComercio: String? = nil
    @Published private var idRepartidor: String? = nil
    @Published private var refreshCounter: Int = 0
    
    private var isChatTabActive = false
    private var ultimoTimestamp: Int64? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        perfilUsuarioState: PerfilUsuarioState
    ) {
        self.perfilUsuarioState = perfilUsuarioState
        
        configurarObservers()
        iniciarPolling()
    }
    
    private func configurarObservers() {
        Publishers.CombineLatest4($idPedido, $emailUsuario, $idComercio, $idRepartidor)
            .combineLatest($refreshCounter)
            .map { params, _ in
                ChatParams(idPedido: params.0, emailUsuario: params.1, idComercio: params.2, idRepartidor: params.3)
            }
            // Filtro: idPedido y email obligatorios, y al menos uno entre comercio o repartidor
            .filter { $0.idPedido != nil && $0.emailUsuario != nil && ($0.idComercio != nil || $0.idRepartidor != nil) }
            .sink { [weak self] params in
                self?.mensajes = []
                self?.ultimoTimestamp = nil
                
                self?.obtenerChat(
                    idPedido: params.idPedido!,
                    emailUsuario: params.emailUsuario!,
                    idComercio: params.idComercio,
                    idRepartidor: params.idRepartidor
                )
            }
            .store(in: &cancellables)
    }
    
    func obtenerChat(idPedido: String, emailUsuario: String, idComercio: String? = nil, idRepartidor: String? = nil) {
        
            Task {
                do {
                    await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                    let accessToken = TokenRepository.repository.accessToken ?? ""
                    
                    let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                    
                    let chatObtenido = try await chatsService.obtenerChat(
                        token: accessToken,
                        dispositivoID: dispositivoID,
                        idPedido: idPedido,
                        emailUsuario: emailUsuario,
                        idComercio: idComercio,
                        idRepartidor: idRepartidor
                    )
                    
                    self.chat = chatObtenido
                    self.mensajes = chatObtenido.mensajes
                    self.ultimoTimestamp = self.mensajes.last?.timestamp
                } catch {
                    print("Error al obtener chat: \(error)")
                }
            }
        
    }
    
    func enviarMensaje(mensaje: Mensaje) {
        
        if(idPedido == nil || emailUsuario == nil) { return }
        
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                
                try await chatsService.enviarMensaje(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    idPedido: idPedido!,
                    emailUsuario: emailUsuario!,
                    idComercio: idComercio,
                    idRepartidor: idRepartidor,
                    mensaje: mensaje
                )
            } catch {
                print("Error al enviar mensaje: \(error)")
                self.errorMensaje = error.localizedDescription
            }
        }
    }
    
    private func iniciarPolling() {
        Task {
            while !Task.isCancelled {
                guard let config = perfilUsuarioState.configuracion else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                
                let intervaloNano = UInt64(config.intervalosTiempo.intervaloBuscarMensajeChat * 1_000_000)
                try? await Task.sleep(nanoseconds: intervaloNano)
                
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                
                if isChatTabActive && idPedido != nil && emailUsuario != nil {
                    let mensajesNuevos = try await chatsService.obtenerNuevosMensajes(
                        token: accessToken,
                        dispositivoID: dispositivoID,
                        desde: ultimoTimestamp ?? 0,
                        idPedido: idPedido!,
                        emailUsuario: emailUsuario!,
                        idComercio: idComercio,
                        idRepartidor: idRepartidor
                    )
                    
                    if !mensajesNuevos.isEmpty {
                        var actuales = self.mensajes
                        actuales.append(contentsOf: mensajesNuevos)
                        actuales.sort { $0.timestamp < $1.timestamp }
                        
                        self.mensajes = actuales
                        self.ultimoTimestamp = mensajesNuevos.last?.timestamp
                    }
                }
            }
        }
    }
    
    func setChatTabActive(active: Bool) {
        self.isChatTabActive = active
    }
    
    func setChatParams(idPedido: String?, emailUsuario: String?, idComercio: String?, idRepartidor: String?) {
        self.idPedido = idPedido
        self.emailUsuario = emailUsuario
        self.idComercio = idComercio
        self.idRepartidor = idRepartidor
        self.refreshCounter += 1
    }
    
    func limpiarError() {
        self.errorMensaje = nil
    }
    
    func limpiarChat() {
        self.mensajes = []
        self.ultimoTimestamp = nil
        self.idComercio = nil
        self.idRepartidor = nil
    }
    
    struct ChatParams {
        let idPedido: String?
        let emailUsuario: String?
        let idComercio: String?
        let idRepartidor: String?
    }
}
