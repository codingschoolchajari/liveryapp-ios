//
//  FavoritosViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 28/12/2025.
//
import Foundation
import SwiftUI

@MainActor
class FavoritosViewModel: ObservableObject {
    
    private let comerciosService = ComerciosService()
    
    @Published var comercioSeleccionado: Comercio? = nil
    @Published var categoria: Categoria? = nil
    @Published var producto: Producto? = nil
    @Published var promocion: Promocion? = nil
        
    func inicializarProductoFavorito(
        perfilUsuarioState: PerfilUsuarioState,
        favorito: UsuarioFavorito
    ) async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            // Buscamos el comercio
            let comercio = try await comerciosService.buscarComercio(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: favorito.idComercio
            )
            self.comercioSeleccionado = comercio
            
            if(favorito.idProducto != nil){
                self.categoria = ComerciosHelper.obtenerCategoria(comercio: comercio, idProducto: favorito.idProducto!)
                self.producto = ComerciosHelper.obtenerProducto(comercio: comercio, idProducto: favorito.idProducto!)
            }
        } catch {
            print("Error iniciando producto favorito")
        }
    }
    
    func inicializarPromocionFavorita(
        perfilUsuarioState: PerfilUsuarioState,
        favorito: UsuarioFavorito
    ) async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            // Buscamos el comercio
            let comercio = try await comerciosService.buscarComercio(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: favorito.idComercio
            )
            self.comercioSeleccionado = comercio
            
            if(favorito.idPromocion != nil){
                self.promocion = ComerciosHelper.obtenerPromocion(comercio: comercio, idPromocion: favorito.idPromocion!)
            }
        } catch {
            print("Error iniciando promoción favorita")
        }
    }
}
