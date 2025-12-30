//
//  PedidosComentariosViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 30/12/2025.
//
import Foundation
import Combine

@MainActor
class PedidosComentariosViewModel: ObservableObject {
    
    private let perfilUsuarioState: PerfilUsuarioState
    private let comentariosService = ComentariosService()
    
    @Published var idComercioSeleccionado: String? = nil
    @Published var pedidosComentarios: [PedidoComentario] = []
    
    private var paginaActual = 0
    private let tamanoPagina = 10
    private var cargando = false
    private var noHayMasComentarios = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        
        setupObservers()
    }
    
    private func setupObservers() {
        $idComercioSeleccionado
            .compactMap { $0 }
            .sink { [weak self] idComercio in
                guard let self = self else { return }
                self.resetPaginacion()
                Task {
                    await self.cargarMasComentarios()
                }
            }
            .store(in: &cancellables)
    }
    
    func onIdComercioSeleccionadoChange(valor: String) {
        self.idComercioSeleccionado = valor
    }
    
    private func resetPaginacion() {
        self.pedidosComentarios = []
        self.paginaActual = 0
        self.cargando = false
        self.noHayMasComentarios = false
    }
    
    func cargarMasComentarios() async {
        guard
            !cargando,
            !noHayMasComentarios,
            let id = idComercioSeleccionado
        else {
            return
        }
        
        cargando = true
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let skip = paginaActual * tamanoPagina
            let nuevos = try await comentariosService.buscar(
                token: accessToken,
                dispositivoID: dispositivoID,
                idComercio: id,
                skip: skip,
                limit: tamanoPagina
            )
            
            if nuevos.isEmpty {
                self.noHayMasComentarios = true
            } else {
                self.pedidosComentarios.append(contentsOf: nuevos)
                self.paginaActual += 1
            }
        } catch {
            print("Error cargando comentarios: \(error.localizedDescription)")
        }
        
        self.cargando = false
    }
}
