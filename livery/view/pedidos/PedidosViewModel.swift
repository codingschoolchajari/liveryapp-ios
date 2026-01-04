//
//  PedidosViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/01/2026.
//
import Foundation
import Combine
import SwiftUI

@MainActor
class PedidosViewModel: ObservableObject {
    
    private let pedidosService = PedidosService()
    private let comerciosService = ComerciosService()
    private let comentariosService = ComentariosService()
    private let recorridosService = RecorridosService()
    private let perfilUsuarioState: PerfilUsuarioState
    
    // Propiedades Publicadas (@Published equivale a StateFlow)
    @Published var pedidos: [Pedido] = []
    @Published var estadoSeleccionado: EstadosPedidos = .todos
    @Published var pedidoSeleccionado: Pedido? = nil
    @Published var comercioSeleccionado: Comercio? = nil
    @Published var recorridoSeleccionado: Recorrido? = nil
    @Published var comprobanteSeleccionado: Comprobante = Comprobante()
    @Published var mostrarBottomSheet: Bool = false
    @Published var recorridoTick: Int = 0 // Fuerza actualización de mapas en la UI
    
    // Variables de paginación y control
    private var paginaActual = 0
    private let tamanoPagina = 10
    private var cargando = false
    private var noHayMasPedidos = false
    private var isRecorridoTabActive = false
    
    // Para observar cambios en estadoSeleccionado (Equivale a onEach.launchIn)
    private var cancellables = Set<AnyCancellable>()
    
    init(
        perfilUsuarioState: PerfilUsuarioState
    ) {
        self.perfilUsuarioState = perfilUsuarioState
        
        configurarObservers()
        iniciarPollingRecorrido()
    }
    
    private func configurarObservers() {
        $estadoSeleccionado
            .sink { [weak self] _ in
                self?.refrescarPedidos()
            }
            .store(in: &cancellables)
    }
    
    func refrescarPedidos() {
        paginaActual = 0
        pedidos = []
        noHayMasPedidos = false
        Task {
            await cargarMasPedidos()
        }
    }
    
    func cargarMasPedidos() async {
        guard !cargando && !noHayMasPedidos else { return }
        
        cargando = true
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let email = perfilUsuarioState.usuario?.email ?? ""
            let nuevos = try await pedidosService.buscarPedidos(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                estado: estadoSeleccionado.rawValue,
                skip: paginaActual * tamanoPagina,
                limit: tamanoPagina
            )
            
            if nuevos.isEmpty {
                noHayMasPedidos = true
            } else {
                pedidos.append(contentsOf: nuevos)
                paginaActual += 1
            }
            cargando = false
            
        } catch {
            print("Error cargando más pedidos: \(error)")
            cargando = false
        }
        
    }
    
    func eliminarPedido(pedido: Pedido) async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let email = perfilUsuarioState.usuario?.email ?? ""
            
            try await pedidosService.eliminarPedido(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idPedido: pedido.idInterno
            )
            
            refrescarPedidos()
        } catch {
            print("Error el eliminar pedido: \(error)")
        }
        
    }
    
    func refrescarPedidoSeleccionado(pedido: Pedido) async {
        self.pedidoSeleccionado = nil
        self.comercioSeleccionado = nil
        self.recorridoSeleccionado = nil
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let pedidoInfo = try await pedidosService.buscarPedido(
                token: accessToken,
                dispositivoID: dispositivoID,
                idPedido: pedido.idInterno
            )
            let comercioInfo = try await comerciosService.buscarComercio(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: pedido.idComercio,
                datosPrincipales: true
            )
            let recorridoInfo = try await recorridosService.buscar(
                token: accessToken,
                dispositivoID: dispositivoID,
                idPedido: pedido.idInterno)
            
            self.pedidoSeleccionado = pedidoInfo
            self.comercioSeleccionado = comercioInfo
            self.recorridoSeleccionado = recorridoInfo
        } catch {
            print("Error al refrescar pedido seleccionado: \(error)")
        }
    }
    
    func buscarPedidoSeleccionado(idPedido: String) async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            self.pedidoSeleccionado = try await pedidosService.buscarPedido(
                token: accessToken,
                dispositivoID: dispositivoID,
                idPedido: idPedido
            )
            onMostrarBottomSheetChange(mostrar: true)
        } catch {
            print("Error al buscar pedido seleccionado: \(error)")
        }
    }
    
    func enviarComentario(
        estrellas: Int,
        texto: String,
        nombreUsuario: String
    ) {
        Task {
            let comentario = Comentario(
                fecha: "",
                texto: texto,
                nombreUsuario: nombreUsuario,
                cantidadEstrellas: estrellas
            )

            // Verificamos si hay un pedido seleccionado de forma segura
            guard let pedidoActual = self.pedidoSeleccionado else { return }

            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                
                try await comentariosService.enviarComentario(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: pedidoActual.email,
                    idPedido: pedidoActual.idInterno,
                    comentario: comentario
                )
            } catch {
                print("Error al enviar comentario: \(error.localizedDescription)")
            }
        }
    }
    
    func cargarComprobante(
        pedido: Pedido,
        comprobante: Comprobante
    ) async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let email = perfilUsuarioState.usuario?.email ?? ""
            
            try await pedidosService.cargarComprobante(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idPedido: pedido.idInterno,
                comprobante: comprobante
            )
            await refrescarPedidoSeleccionado(pedido: pedido)
            
        } catch {
            print("Error al cargar comprobante: \(error)")
        }
    }
    
    private func iniciarPollingRecorrido() {
        Task {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            while true {
                // Obtenemos intervalo de configuración
                guard let config = perfilUsuarioState.configuracion else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seg
                    continue
                }
                
                let intervaloNano = UInt64(config.intervalosTiempo.intervaloBuscarRecorrido * 1_000_000) // ms a nanos
                try? await Task.sleep(nanoseconds: intervaloNano)
                
                // Lógica de validación para actualizar mapa
                if isRecorridoTabActive,
                   let pedido = pedidoSeleccionado,
                   EstadoPedido.enCamino == EstadoPedido.desdeString(pedido.estado?.nombre ?? "") {
                    
                    self.recorridoSeleccionado = try await recorridosService.buscar(
                        token: accessToken,
                        dispositivoID: dispositivoID,
                        idPedido: pedido.idInterno
                    )
                    forceRefreshRecorrido()
                }
            }
        }
    }
    
    func forceRefreshRecorrido() {
        recorridoTick += 1
    }
    
    func setRecorridoTabActive(active: Bool) {
        self.isRecorridoTabActive = active
    }
    
    func onMostrarBottomSheetChange(mostrar: Bool) {
        self.mostrarBottomSheet = mostrar
    }
    
    func onPedidoSeleccionadoChange(pedido: Pedido?) {
        self.pedidoSeleccionado = pedido
    }
    
    func onEstadoSeleccionadoChange(estado: EstadosPedidos) {
        self.estadoSeleccionado = estado
    }
}
