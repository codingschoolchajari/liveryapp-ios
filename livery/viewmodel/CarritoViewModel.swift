//
//  CarritoViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 28/12/2025.
//
import Foundation
import Combine
import CoreLocation

enum EstadoValidacionUbicacion {
    case idle
    case clienteFrecuente
    case solicitandoPermiso
    case permisoDenegado
    case gpsApagado
    case obteniendoUbicacion
    case verificandoCobertura
    case cubierto
    case fueraDeCobertura
    case error
}

@MainActor
class CarritoViewModel: ObservableObject {
    
    private let comerciosService = ComerciosService()
    private let enviosService = EnviosService()
    private let pedidosService = PedidosService()
    private let coberturasService = CoberturasService()
    private let locationService: LocationServicing

    @Published var itemsProductos: [ItemProducto] = []
    @Published var itemsPromociones: [ItemPromocion] = []
    @Published var comercio: Comercio? = nil
    @Published var notas: String = ""
    @Published var tipoEntregaSeleccionada: TipoEntrega = TipoEntrega.retiroEnComercio
    @Published var enviosLiveryActivo: Bool = false
    @Published var envio: Double = 0.0
    @Published var tarifaServicioCalculada: Double = 0.0
    @Published var tiempoRecorridoEstimado: Int = 0
    @Published var comprobanteSeleccionado: Comprobante? = nil
    @Published var cargandoComprobante: Bool = false
    @Published var pedidoConfirmado: Bool = false
    @Published var pagoTransferencia: Bool = true

    // MARK: Efectivo – validación por ubicación
    @Published var estadoValidacionUbicacion: EstadoValidacionUbicacion = .idle
    @Published var coordenadasEfectivo: CLLocationCoordinate2D? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var esperandoUbicacionPago = false
    private var perfilUsuarioStatePago: PerfilUsuarioState?
    
    @Published var precioTotal: Double = 0.0
    @Published var aplicaTarifaServicio: Bool = true

    init(locationService: LocationServicing = LocationService()) {
        self.locationService = locationService
        bindLocationService()
        configurarSuscriptores()
    }

    private func bindLocationService() {
        locationService.onAuthorizationChange = { [weak self] status in
            Task { @MainActor in
                self?.onPermisoPagoResultado(status: status)
            }
        }

        locationService.onLocationUpdate = { [weak self] coord in
            Task { @MainActor in
                guard let self = self, self.esperandoUbicacionPago else { return }
                self.esperandoUbicacionPago = false
                self.locationService.stopUpdatingLocation()
                self.coordenadasEfectivo = coord
                await self.verificarCoberturaEnCoordenadas(coord)
            }
        }
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
        Publishers.CombineLatest3($itemsProductos, $itemsPromociones, $tipoEntregaSeleccionada)
            .map { productos, promociones, tipoEntrega in
                if tipoEntrega == .retiroEnComercio || tipoEntrega == .envioPropio {
                    return false
                }

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

    func cargarEstadoInicial(
        perfilUsuarioState: PerfilUsuarioState,
        ciudadSeleccionada: String?,
        usuarioDireccion: UsuarioDireccion?
    ) async {
        guard
            let ciudadSeleccionada,
            !ciudadSeleccionada.isEmpty,
            comercio != nil,
            (!itemsProductos.isEmpty || !itemsPromociones.isEmpty)
        else { return }

        await actualizarComercioEnvios(
            perfilUsuarioState: perfilUsuarioState,
            usuarioDireccion: usuarioDireccion
        )
        await actualizarEnviosLiveryActivo(
            perfilUsuarioState: perfilUsuarioState,
            localidad: ciudadSeleccionada
        )
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
            comprobanteSeleccionado = nil
            pagoTransferencia = true
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
            
            let booleanResponse: BooleanResponse = try await comerciosService.comercioAbierto(
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

    func validacionDisponibilidad(
        perfilUsuarioState: PerfilUsuarioState,
        email: String
    ) async -> BooleanResponse {
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""

            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            return try await pedidosService.validarDisponibilidad(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email
            )
        } catch {
            print("Error al validar disponibilidad de lanzamiento: \(error)")
            return BooleanResponse(valor: true, mensaje: "")
        }
    }

    func agregarItemProducto(
        perfilUsuarioState: PerfilUsuarioState,
        itemProducto: ItemProducto,
        direccion: UsuarioDireccion
    ) {
        if itemsProductos.isEmpty {
            refrescarCostoEnvio(
                perfilUsuarioState: perfilUsuarioState,
                usuarioDireccion: direccion
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
            refrescarCostoEnvio(
                perfilUsuarioState: perfilUsuarioState,
                usuarioDireccion: direccion
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

        let descuentosPedido = construirDescuentosPedido()
        let modalidadPago = construirModalidadPago()
        
        let pedido = Pedido(
            idInterno: UUID().uuidString.lowercased(),
            email: email,
            nombreUsuario: nombreUsuario,
            idComercio: String(comercioActual.idInterno),
            nombreComercio: comercioActual.nombre,
            logoComercioURL: comercioActual.logoURL,
            localidad: comercioActual.localidad,
            direccion: direccion,
            notas: notas,
            tipoEntrega: tipoEntregaSeleccionada.rawValue,
            tarifaServicio: tarifaServicio,
            envio: envio,
            envioGratisParaCliente: comercioActual.envios.envioGratisParaCliente ?? false,
            tiempoRecorridoEstimado: tiempoRecorridoEstimado,
            precioTotal: precioTotal,
            descuentos: descuentosPedido,
            modalidadPago: modalidadPago,
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

            if let comprobanteSeleccionado {
                try await pedidosService.cargarComprobante(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: email,
                    idPedido: pedido.idInterno,
                    comprobante: comprobanteSeleccionado
                )
            }
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
            self.tarifaServicioCalculada = 0.0
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
                
                self.envio = envioResponse.costo
                self.tarifaServicioCalculada = envioResponse.tarifaServicio
                self.tiempoRecorridoEstimado = envioResponse.tiempoEstimado
            } catch {
                self.tarifaServicioCalculada = 0.0
                print("Error calculando envío")
            }
        }
    }

    func onNotasChange(texto: String) {
        self.notas = texto.prefix(1).uppercased() + texto.dropFirst()
    }

    func onTipoEntregaChange(
        perfilUsuarioState: PerfilUsuarioState,
        tipoEntrega: TipoEntrega,
        usuarioDireccion: UsuarioDireccion?
    ) {
        
        self.tipoEntregaSeleccionada = tipoEntrega
        refrescarCostoEnvio(
            perfilUsuarioState: perfilUsuarioState,
            usuarioDireccion: usuarioDireccion
        )
    }

    func refrescarCostoEnvio(
        perfilUsuarioState: PerfilUsuarioState,
        usuarioDireccion: UsuarioDireccion?
    ) {
        switch tipoEntregaSeleccionada {
        case .retiroEnComercio:
            self.envio = 0.0
            self.tarifaServicioCalculada = 0.0
            
        case .envioPropio:
            self.tarifaServicioCalculada = 0.0
            let precios = comercio?.envios.preciosEnvioPropio ?? []
            if precios.isEmpty {
                self.envio = StringUtils.envioPropioTarifaDefault
            } else {
                let distanciaMetros = calcularDistanciaRedondeada(
                    p1: usuarioDireccion?.coordenadas,
                    p2: comercio?.direccion.coordenadas
                )
                let sorted = precios.sorted { $0.hasta < $1.hasta }
                let tramo = sorted.first { distanciaMetros <= $0.hasta } ?? sorted.last!
                self.envio = Double(tramo.precio)
            }
            
        default :
            calcularCostoEnvio(
                perfilUsuarioState: perfilUsuarioState, 
                direccion: usuarioDireccion
            )
        }
    }

    func existePremioEnCarrito(idPremio: String) -> Bool {
        return itemsProductos.contains { $0.idPremio == idPremio }
    }
    
    func onPedidoConfirmado(){
        itemsProductos = []
        itemsPromociones = []
        comercio = nil
        comprobanteSeleccionado = nil
        pagoTransferencia = true
        resetEfectivo()
    }

    func cargarComprobante(comprobante: Comprobante) {
        cargandoComprobante = true
        comprobanteSeleccionado = comprobante
        cargandoComprobante = false
    }

    func limpiarComprobante() {
        comprobanteSeleccionado = nil
    }

    func onPagoTransferenciaChange(_ esTransferencia: Bool) {
        pagoTransferencia = esTransferencia
        if !esTransferencia {
            limpiarComprobante()
        } else {
            resetEfectivo()
        }
    }

    // MARK: Efectivo – validación por ubicación
    private func esGpsActivo() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }

    func iniciarValidacionUbicacion(perfilUsuarioState: PerfilUsuarioState) {
        perfilUsuarioStatePago = perfilUsuarioState

        guard let email = perfilUsuarioState.usuario?.email, !email.isEmpty else {
            iniciarValidacionUbicacionSinClienteFrecuente(perfilUsuarioState: perfilUsuarioState)
            return
        }

        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let token = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                let esFrecuente = try await pedidosService.esClienteFrecuente(
                    token: token,
                    dispositivoID: dispositivoID,
                    email: email
                )

                if esFrecuente {
                    estadoValidacionUbicacion = .clienteFrecuente
                } else {
                    iniciarValidacionUbicacionSinClienteFrecuente(perfilUsuarioState: perfilUsuarioState)
                }
            } catch {
                print("Error al verificar cliente frecuente: \(error)")
                iniciarValidacionUbicacionSinClienteFrecuente(perfilUsuarioState: perfilUsuarioState)
            }
        }
    }

    private func iniciarValidacionUbicacionSinClienteFrecuente(perfilUsuarioState: PerfilUsuarioState) {
        switch locationService.authorizationStatus {
        case .notDetermined:
            estadoValidacionUbicacion = .solicitandoPermiso
            locationService.requestPermission()
            return
        case .restricted, .denied:
            estadoValidacionUbicacion = .permisoDenegado
            return
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            estadoValidacionUbicacion = .error
            return
        }

        guard esGpsActivo() else {
            estadoValidacionUbicacion = .gpsApagado
            return
        }

        obtenerUbicacionYVerificarSinClienteFrecuente()
    }

    private func obtenerUbicacionYVerificarSinClienteFrecuente() {
        estadoValidacionUbicacion = .obteniendoUbicacion
        esperandoUbicacionPago = true
        locationService.startUpdatingLocation()
    }

    private func verificarCoberturaEnCoordenadas(_ coord: CLLocationCoordinate2D) async {
        estadoValidacionUbicacion = .verificandoCobertura

        guard let perfilUsuarioStatePago else {
            estadoValidacionUbicacion = .error
            return
        }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioStatePago)
            let token = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let ciudadResponse = try await coberturasService.buscarCiudadPorUbicacion(
                token: token,
                dispositivoID: dispositivoID,
                latitud: coord.latitude,
                longitud: coord.longitude
            )

            estadoValidacionUbicacion = ciudadResponse.ciudad.isEmpty ? .fueraDeCobertura : .cubierto
        } catch {
            print("Error al verificar cobertura para pago en efectivo: \(error)")
            estadoValidacionUbicacion = .error
        }
    }

    private func onPermisoPagoResultado(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            guard esGpsActivo() else {
                estadoValidacionUbicacion = .gpsApagado
                return
            }
            obtenerUbicacionYVerificarSinClienteFrecuente()
        case .denied, .restricted:
            estadoValidacionUbicacion = .permisoDenegado
        case .notDetermined:
            estadoValidacionUbicacion = .solicitandoPermiso
        @unknown default:
            estadoValidacionUbicacion = .error
        }
    }

    func revalidarSiNecesario(perfilUsuarioState: PerfilUsuarioState) {
        switch estadoValidacionUbicacion {
        case .permisoDenegado:
            let status = locationService.authorizationStatus
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                iniciarValidacionUbicacion(perfilUsuarioState: perfilUsuarioState)
            }
        case .gpsApagado:
            iniciarValidacionUbicacion(perfilUsuarioState: perfilUsuarioState)
        default:
            break
        }
    }

    func resetEfectivo() {
        esperandoUbicacionPago = false
        locationService.stopUpdatingLocation()
        estadoValidacionUbicacion = .idle
        coordenadasEfectivo = nil
        perfilUsuarioStatePago = nil
    }

    func calcularMontoDescuentoEfectivo() -> Double {
        guard !pagoTransferencia else { return 0.0 }
        guard let comercioActual = comercio else { return 0.0 }

        let descuentoEfectivo = (comercioActual.descuentos ?? []).first {
            $0.palabraClave.caseInsensitiveCompare("efectivo") == .orderedSame
        }

        guard let descuentoEfectivo else { return 0.0 }
        guard descuentoEfectivo.porcentaje > 0 else { return 0.0 }

        return precioTotal * (descuentoEfectivo.porcentaje / 100.0)
    }

    func calcularTotalDescuentosSeleccionPago() -> Double {
        -calcularMontoDescuentoEfectivo()
    }

    func construirDescuentosPedido() -> [DescuentoPedido] {
        guard let comercioActual = comercio else { return [] }
        guard !pagoTransferencia else { return [] }

        let descuentoEfectivo = (comercioActual.descuentos ?? []).first {
            $0.palabraClave.caseInsensitiveCompare("efectivo") == .orderedSame
        }

        guard let descuentoEfectivo else { return [] }

        let montoDescuento = calcularMontoDescuentoEfectivo()
        guard montoDescuento > 0 else { return [] }

        return [
            DescuentoPedido(
                descripcion: descuentoEfectivo.descripcion,
                monto: -montoDescuento
            )
        ]
    }

    private func construirModalidadPago() -> ModalidadPago {
        if !pagoTransferencia {
            let point = coordenadasEfectivo.map {
                Point(coordinates: [$0.latitude, $0.longitude])
            }
            return ModalidadPago(
                tipo: "EFECTIVO",
                coordenadas: point
            )
        }
        return ModalidadPago(tipo: "TRANSFERENCIA")
    }
    
    // Premios
    func existePremioEnCarrito(idInterno: String) -> Bool {
        return itemsProductos.contains { item in
            item.idPremio == idInterno
        }
    }
    
    // Envios
    func actualizarComercioEnvios(
        perfilUsuarioState: PerfilUsuarioState,
        usuarioDireccion: UsuarioDireccion?
    ) async {
        guard let comercioActual = comercio else { return }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let nuevosEnvios = try await comerciosService.buscarComercioEnvios(
                token: accessToken,
                dispositivoID: dispositivoID,
                idInterno: comercioActual.idInterno
            )

            var comercioActualizado = comercioActual
            comercioActualizado.envios = nuevosEnvios
            comercio = comercioActualizado
            
            refrescarCostoEnvio(
                perfilUsuarioState: perfilUsuarioState,
                usuarioDireccion: usuarioDireccion
            )
        } catch {
            print("Error al actualizar Comercio Envios")
        }
    }
    
    func actualizarEnviosLiveryActivo(perfilUsuarioState: PerfilUsuarioState, localidad: String) async {
        
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let booleanResponse: BooleanResponse = try await enviosService.enviosLiveryActivo(
                token: accessToken,
                dispositivoID: dispositivoID,
                localidad: localidad
            )
            
            enviosLiveryActivo = booleanResponse.valor
        } catch {
            print("Error al actualizar Envios Livery Activo")
        }
        
        
    }

}
