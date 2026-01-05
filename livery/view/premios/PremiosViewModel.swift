//
//  PremiosViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 05/01/2026.
//
import Foundation
import Combine

@MainActor
class PremiosViewModel: ObservableObject {
    
    private let premiosService = PremiosService()
    private let comerciosService = ComerciosService()
    private let perfilUsuarioState: PerfilUsuarioState
    
    @Published var girarRuleta: Bool = false
    @Published var resultadoGirarRuleta: Premio? = nil
    @Published var premioSeleccionado: Premio? = nil
    @Published var productoSeleccionado: Producto? = nil
    
    var comercio: Comercio? = nil
    var categoria: Categoria? = nil
    
    private var refreshCounter: Int = 0
    private var cancellables = Set<AnyCancellable>()

    init(
        perfilUsuarioState: PerfilUsuarioState
    ) {
        self.perfilUsuarioState = perfilUsuarioState
    }

    func refresh() async {
        refreshCounter += 1
        
        // Reset de estados
        self.girarRuleta = false
        self.resultadoGirarRuleta = nil
        
        // Refrescar Usuario
        await perfilUsuarioState.buscarUsuario()
    }

    func obtenerResultadoGirarRuleta() async {
        self.resultadoGirarRuleta = nil
        
        guard let email = perfilUsuarioState.usuario?.email else { return }
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let ciudad = perfilUsuarioState.ciudadSeleccionada ?? ""
            
            let resultado = try await premiosService.obtenerResultadoGirarRuleta(
                token: accessToken,
                dispositivoID: dispositivoID,
                ciudad: ciudad,
                email: email
            )
            self.resultadoGirarRuleta = resultado
        } catch {
            print("Error al obtener resultado girar ruleta: \(error)")
        }
    }

    func onGirarRuletaChange(valor: Bool) {
        self.girarRuleta = valor
    }

    func seleccionarPremio(premio: Premio) {
        self.premioSeleccionado = premio
    }

    func limpiarPremioSeleccionado() {
        self.premioSeleccionado = nil
    }

    func inicializarProductoSeleccionado(idComercio: String, idProducto: String, idPremio: String) async {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let resultadoComercio = try await comerciosService.buscarComercioPorProducto(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: idComercio,
                idProducto: idProducto
            )
            
            self.comercio = resultadoComercio
            
            if let comercioActual = self.comercio {
                self.categoria = obtenerCategoria(comercio: comercioActual, idProducto: idProducto)
                var producto = obtenerProducto(comercio: comercioActual, idProducto: idProducto)
                
                // Configuración de los valores del premio
                producto?.esPremio = true
                producto?.idPremio = idPremio
                producto?.precio = 0.0
                producto?.precioSinDescuento = nil
                producto?.descuento = nil
                
                self.productoSeleccionado = producto
            }
        } catch {
            print("Error al inicializar producto: \(error)")
        }
    }

    func limpiarProductoSeleccionado() {
        self.productoSeleccionado = nil
    }
    
    // MARK: - Helpers (Implementar según lógica de negocio)
    private func obtenerCategoria(comercio: Comercio, idProducto: String) -> Categoria? {
        // Lógica para filtrar categoría dentro del objeto comercio
        return nil
    }

    private func obtenerProducto(comercio: Comercio, idProducto: String) -> Producto? {
        // Lógica para filtrar producto dentro del objeto comercio
        return nil
    }
}
