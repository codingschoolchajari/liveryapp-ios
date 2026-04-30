//
//  DireccionViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import Foundation

@MainActor
class ComercioViewModel: ObservableObject {
    @Published var comercio: Comercio? = nil
    @Published var productoSeleccionado: Producto? = nil
    @Published var promocionSeleccionada: Promocion? = nil
    
    var categoria: Categoria? = nil
    
    private let comerciosService = ComerciosService()
    private let perfilUsuarioState: PerfilUsuarioState
    private let idComercio: String
    private var _initialized = false
    
    init(perfilUsuarioState: PerfilUsuarioState, idComercio: String) {
        self.perfilUsuarioState = perfilUsuarioState
        self.idComercio = idComercio
        cargarComercio()
    }
    
    private func cargarComercio() {
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                
                self.comercio = try await comerciosService.buscarComercio(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    idInterno: idComercio
                )
                self._initialized = true
            } catch {
                print("Error al cargar el comercio: \(error)")
            }
        }
    }
    
    func refreshCategoriasYPromociones() {
        guard _initialized else { return }
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                
                if let fresco = try await comerciosService.buscarComercio(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    idInterno: idComercio
                ) {
                    self.comercio?.categorias = fresco.categorias
                    self.comercio?.promociones = fresco.promociones
                    self.comercio?.aviso = fresco.aviso
                }
            } catch {
                print("Error al refrescar categorias y promociones: \(error)")
            }
        }
    }
    
    func seleccionarProducto(producto: Producto, categoria: Categoria){
        self.productoSeleccionado = producto
        self.categoria = categoria
    }
    
    func seleccionarPromocion(promocion: Promocion){
        self.promocionSeleccionada = promocion
    }
    
    func limpiarSeleccionado(){
        self.productoSeleccionado = nil
        self.categoria = nil
        self.promocionSeleccionada = nil
    }
}


