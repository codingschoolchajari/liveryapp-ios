//
//  CarritoViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 28/12/2025.
//
import Foundation
import Combine

@MainActor
class CarritoViewModel: ObservableObject {
    
    private let comerciosService = ComerciosService()
    private let enviosService = EnviosService()
    private let pedidosService = PedidosService()

    @Published var itemsProductos: [ItemProducto] = []
    @Published var itemsPromociones: [ItemPromocion] = []
    @Published var comercio: Comercio? = nil
    @Published var notas: String = ""
    @Published var retiroEnComercio: Bool = false
    @Published var envio: Double = 0.0
    @Published var tiempoRecorridoEstimado: Int = 0
    @Published var pedidoConfirmado: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var precioTotal: Double = 0.0
    @Published var aplicaTarifaServicio: Bool = true

    init() {
        configurarSuscriptores()
    }
    
    // Configura la lógica reactiva de 'combine'
    private func configurarSuscriptores() {
        // Cálculo del precio total
        Publishers.CombineLatest($itemsProductos, $itemsPromociones)
            .map { productos, promociones in
                let totalProductos = productos.reduce(0) { $0 + $1.precio }
                let totalPromociones = promociones.reduce(0) { $0 + $1.precio }
                return totalProductos + totalPromociones
            }
            .assign(to: &$precioTotal)
        
        // Lógica de tarifa de servicio
        Publishers.CombineLatest($itemsProductos, $itemsPromociones)
            .map { productos, promociones in
                let hayProductosConPremio = productos.contains { $0.esPremio }
                let hayProductosSinPremio = productos.contains { !$0.esPremio }
                
                if hayProductosSinPremio || !promociones.isEmpty {
                    return true
                }
                if hayProductosConPremio {
                    return false
                }
                return true
            }
            .assign(to: &$aplicaTarifaServicio)
    }

    func validacionComercio(comercio: Comercio) -> Bool {
        if itemsProductos.isEmpty && itemsPromociones.isEmpty {
            self.comercio = comercio
            return true
        }
        return comercio.idInterno == self.comercio?.idInterno
    }
    
    func validacionEstado() {
        if pedidoConfirmado {
            itemsProductos = []
            itemsPromociones = []
            comercio = nil
            pedidoConfirmado = false
        }
    }
    
    func validacionComercioAbierto(
        perfilUsuarioState: PerfilUsuarioState
    ) async -> Bool {
        if(comercio == nil) { return false }
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            var booleanResponse: BooleanResponse = try await comerciosService.comercioAbierto(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: comercio!.idInterno
            )
            
            return booleanResponse.valor
            
        } catch {
            print("Error al validar comercio abierto: \(error)")
            return false
        }
    }
    
    func validacionPendientes(
        perfilUsuarioState: PerfilUsuarioState,
        email: String
    ) async -> Bool {
        
        if(comercio == nil) { return false }
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let booleanResponse: BooleanResponse = try await pedidosService.existenPendientes(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idComercio: comercio!.idInterno
            )
            
            return booleanResponse.valor
            
        } catch {
            print("Error al validar pendientes: \(error)")
            return false
        }
    }

    func agregarItemProducto(
        perfilUsuarioState: PerfilUsuarioState,
        itemProducto: ItemProducto,
        direccion: UsuarioDireccion
    ) {
        if itemsProductos.isEmpty {
            calcularCostoEnvio(
                perfilUsuarioState: perfilUsuarioState,
                direccion: direccion
            )
        }
        itemsProductos.append(itemProducto)
    }
    
    func eliminarItemProducto(idInterno: String) {
        itemsProductos.removeAll { $0.idInterno == idInterno }
        verificarCarritoVacio()
    }
    
    func limpiarYAgregarItemProducto(
        perfilUsuarioState: PerfilUsuarioState,
        itemProducto: ItemProducto,
        comercio: Comercio,
        direccion: UsuarioDireccion
    ) {
        itemsProductos = []
        self.comercio = comercio
        agregarItemProducto(
            perfilUsuarioState: perfilUsuarioState,
            itemProducto: itemProducto,
            direccion: direccion
        )
    }

    func agregarItemPromocion(
        perfilUsuarioState: PerfilUsuarioState,
        itemPromocion: ItemPromocion,
        direccion: UsuarioDireccion
    ) {
        if itemsPromociones.isEmpty {
            calcularCostoEnvio(
                perfilUsuarioState: perfilUsuarioState,
                direccion: direccion
            )
        }
        itemsPromociones.append(itemPromocion)
    }
    
    func eliminarItemPromocion(idInterno: String) {
        itemsPromociones.removeAll { $0.idInterno == idInterno }
        verificarCarritoVacio()
    }
    
    func limpiarYAgregarItemPromocion(
        perfilUsuarioState: PerfilUsuarioState,
        itemPromocion: ItemPromocion,
        comercio: Comercio,
        direccion: UsuarioDireccion
    ) {
        itemsPromociones = []
        self.comercio = comercio
        agregarItemPromocion(
            perfilUsuarioState: perfilUsuarioState,
            itemPromocion: itemPromocion,
            direccion: direccion
        )
    }
    
    private func verificarCarritoVacio() {
        if itemsProductos.isEmpty && itemsPromociones.isEmpty {
            self.comercio = nil
        }
    }

    func crearPedido(
        perfilUsuarioState: PerfilUsuarioState,
        email: String,
        nombreUsuario: String,
        direccion: UsuarioDireccion,
        tarifaServicio: Double
    ) async {
        guard let comercioActual = comercio else { return }
        
        let pedido = Pedido(
            idInterno: UUID().uuidString,
            email: email,
            nombreUsuario: nombreUsuario,
            idComercio: String(comercioActual.idInterno),
            nombreComercio: comercioActual.nombre,
            logoComercioURL: comercioActual.logoURL,
            direccion: direccion,
            notas: notas,
            retiroEnComercio: retiroEnComercio,
            tarifaServicio: tarifaServicio,
            envio: envio,
            tiempoRecorridoEstimado: tiempoRecorridoEstimado,
            precioTotal: precioTotal,
            itemsProductos: itemsProductos,
            itemsPromociones: itemsPromociones
        )
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            try await pedidosService.crearPedido(
                token: accessToken,
                dispositivoID: dispositivoID,
                pedido: pedido
            )
        } catch {
            print("Error al crear pedido: \(error)")
        }
    }

    func calcularCostoEnvio(
        perfilUsuarioState: PerfilUsuarioState, 
        direccion: UsuarioDireccion?
    ) {
        guard let direccion = direccion, let comercioActual = comercio else {
            self.envio = 0.0
            return
        }
        
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                
                let latitudComercio = comercioActual.direccion.coordenadas.coordinates[0]
                let longitudComercio = comercioActual.direccion.coordenadas.coordinates[1]
                let latitudUsuario = direccion.coordenadas.coordinates[0]
                let longitudUsuario = direccion.coordenadas.coordinates[1]
                
                let envioResponse = try await enviosService.calcularCosto(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    latitudOrigen: Double(latitudComercio),
                    longitudOrigen: Double(longitudComercio),
                    latitudDestino: Double(latitudUsuario),
                    longitudDestino: Double(longitudUsuario)
                )
                
                self.envio = Double(envioResponse.costo)
                self.tiempoRecorridoEstimado = envioResponse.tiempoEstimado
            } catch {
                print("Error calculando envío")
            }
        }
    }

    func onNotasChange(texto: String) {
        self.notas = texto.prefix(1).uppercased() + texto.dropFirst()
    }

    func onRetiroEnComercioChange(
        perfilUsuarioState: PerfilUsuarioState,
        valor: Bool,
        usuarioDireccion: UsuarioDireccion?
    ) {
        self.retiroEnComercio = valor
        if valor {
            self.envio = 0.0
        } else {
            calcularCostoEnvio(perfilUsuarioState: perfilUsuarioState, direccion: usuarioDireccion)
        }
    }

    func existePremioEnCarrito(idPremio: String) -> Bool {
        return itemsProductos.contains { $0.idPremio == idPremio }
    }
    
    func onPedidoConfirmado(){
        itemsProductos = []
        itemsPromociones = []
        comercio = nil
    }
}
