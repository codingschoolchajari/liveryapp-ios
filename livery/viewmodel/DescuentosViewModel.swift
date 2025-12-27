//
//  DescuentosViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 27/12/2025.
//
import Foundation
import SwiftUI
import Combine

@MainActor
class DescuentosViewModel: ObservableObject {
    private let perfilUsuarioState: PerfilUsuarioState
    
    @Published var productoSeleccionado: Producto? = nil
    @Published var comerciosDescuentos: [ComercioDescuentos] = []
    
    private let comerciosService = ComerciosService()
    
    var comercio: Comercio? = nil
    var categoria: Categoria? = nil
    
    private var paginaActual = 0
    private let tamanoPagina = 10
    private var cargando = false
    private var noHayMasComercios = false
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        
        inicio()
    }
    
    func inicio(){
        paginaActual = 0
        comerciosDescuentos = []
        noHayMasComercios = false
        Task {
            await cargarMasComercios()
        }
    }
    
    func inicializarProductoSeleccionado(idComercio: String, idProducto: String) async {
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            comercio = try await comerciosService.buscarComercioPorProducto(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: idComercio,
                idProducto: idProducto
            )
            
            if(comercio != nil) {
                categoria = ComerciosHelper.obtenerCategoria(comercio: comercio!, idProducto: idProducto)
                productoSeleccionado = ComerciosHelper.obtenerProducto(comercio: comercio!, idProducto: idProducto)
            }
        } catch {
            print("Error al iniciar producto seleccionado : \(error)")
        }
    }
    
    func limpiarProductoSeleccionado() {
        self.productoSeleccionado = nil
        self.categoria = nil
        self.comercio = nil
    }
    
    func cargarMasComercios() async {
        
        guard !cargando,
              !noHayMasComercios,
              let ciudad = perfilUsuarioState.ciudadSeleccionada,
              !ciudad.isEmpty
        else { return }
        
        cargando = true
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let nuevosComercios = try await comerciosService.buscarDescuentos(
                token: accessToken,
                dispositivoID: dispositivoID,
                localidad: ciudad,
                skip: paginaActual * tamanoPagina,
                limit: tamanoPagina
            )
            
            if nuevosComercios.isEmpty {
                noHayMasComercios = true
            } else {
                comerciosDescuentos += nuevosComercios
                paginaActual += 1
            }
            cargando = false
        } catch {
            print("Error cargando más comercios: \(error)")
            cargando = false
        }
        
    }
}
