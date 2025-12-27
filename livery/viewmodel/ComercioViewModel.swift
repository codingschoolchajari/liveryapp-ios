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
    
    init(perfilUsuarioState: PerfilUsuarioState, idComercio: String) {
        cargarComercio(perfilUsuarioState: perfilUsuarioState, idComercio: idComercio)
    }
    
    private func cargarComercio(
        perfilUsuarioState: PerfilUsuarioState,
        idComercio: String
    ) {
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
            } catch {
                print("Error al cargar el comercio: \(error)")
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


