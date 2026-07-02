import Foundation
import CoreLocation
import GooglePlaces

enum EstadoValidacionEfectivo {
    case idle, cargandoCodigo, esperando, validado, error
}

@MainActor
class NuevoRepartoViewModel: ObservableObject {
    private let perfilUsuarioState: PerfilUsuarioState
    private let repartosService = RepartosService()
    private let enviosService = EnviosService()
    private let repartidoresService = RepartidoresService()
    private let verificacionService = VerificacionService()

    @Published var coordenadasComercio: CLLocationCoordinate2D? = nil
    @Published var direccionesUsuario: [UsuarioDireccion] = []
    @Published var idDireccionUsuarioSeleccionada: String? = nil

    @Published var calle: String = ""
    @Published var numero: String = ""
    @Published var nombreComercio: String = ""
    @Published var descripcionEnvio: String = ""
    @Published var modoManual: Bool = false
    var ciudadSeleccionada: String? = nil

    @Published var calculandoCostoEnvio: Bool = false
    @Published var tarifaServicio: Double = 0
    @Published var costoEnvio: Int? = nil
    @Published var distanciaEnvio: Int? = nil

    @Published var tiempoEspera: Int? = nil
    @Published var demandaRepartidores: String? = nil

    @Published var creandoReparto: Bool = false
    @Published var repartoCreado: Bool = false

    @Published var comprobanteSeleccionado: Comprobante? = nil
    @Published var cargandoComprobante: Bool = false

    @Published var pagoTransferencia: Bool? = nil
    @Published var precioTotalProductos: String = ""
    @Published var limitePagoEfectivo: Double = 0

    @Published var estadoValidacionEfectivo: EstadoValidacionEfectivo = .idle
    @Published var codigoEfectivo: String = ""
    @Published var urlWhatsapp: String? = nil
    @Published var mostrarErrorValidacion: Bool = false

    private var costoEnvioDebounceTask: Task<Void, Never>? = nil
    private var geocodingTask: Task<Void, Never>? = nil
    private var pollingTask: Task<Void, Never>? = nil
    private var coordenadasUsuario: CLLocationCoordinate2D? = nil

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        inicializarDatos()
    }

    func inicializarDatos() {
        direccionesUsuario = perfilUsuarioState.usuario?.direcciones ?? []

        let direccionSeleccionada = perfilUsuarioState.obtenerUsuarioDireccion() ?? direccionesUsuario.first
        idDireccionUsuarioSeleccionada = direccionSeleccionada?.id

        if let coords = direccionSeleccionada?.coordenadas.coordinates, coords.count >= 2 {
            let destinoUsuario = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
            coordenadasUsuario = destinoUsuario
            coordenadasComercio = destinoUsuario
        }

        tarifaServicio = perfilUsuarioState.configuracion?.tarifaServicio ?? 0
        limitePagoEfectivo = perfilUsuarioState.configuracion?.limitePagoEfectivo ?? 0

        Task {
            await actualizarEstadisticasRepartidores()
            await calcularCostoEnvio()
        }
    }

    func onDireccionUsuarioSeleccionadaChange(idDireccion: String) {
        idDireccionUsuarioSeleccionada = idDireccion
        if let direccion = direccionesUsuario.first(where: { $0.id == idDireccion }),
           direccion.coordenadas.coordinates.count >= 2 {
            coordenadasUsuario = CLLocationCoordinate2D(
                latitude: direccion.coordenadas.coordinates[0],
                longitude: direccion.coordenadas.coordinates[1]
            )
        }
        calcularCostoEnvioDebounced()
    }

    func actualizarCoordenadasComercio(coordenada: CLLocationCoordinate2D) {
        coordenadasComercio = coordenada
        calcularCostoEnvioDebounced()
    }

    func actualizarDesdePlace(_ place: GMSPlace) {
        if nombreComercio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nombreComercio = place.name ?? ""
        }

        if let components = place.addressComponents {
            for component in components {
                if component.types.contains("route") {
                    calle = component.name
                }
                if component.types.contains("street_number") {
                    numero = component.name
                }
            }
        }

        actualizarCoordenadasComercio(coordenada: place.coordinate)
    }

    func onNumeroChange(_ texto: String) {
        numero = texto
        guard !modoManual, !calle.isEmpty, !texto.isEmpty else { return }
        geocodingTask?.cancel()
        geocodingTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await geocodificarCalleNumero(calle: calle, numero: texto)
        }
    }

    private func geocodificarCalleNumero(calle: String, numero: String) async {
        let ciudadLegible = ciudadSeleccionada
            .map { $0.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ") }
        let query: String
        if let ciudad = ciudadLegible, !ciudad.isEmpty {
            query = "\(calle) \(numero), \(ciudad)"
        } else {
            query = "\(calle) \(numero)"
        }

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("❌ [Geocoding] API key no encontrada")
            return
        }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/geocode/json")!
        var queryItems = [
            URLQueryItem(name: "address", value: query),
            URLQueryItem(name: "region", value: "ar"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        if let centro = coordenadasComercio {
            let delta = 0.15
            let sw = "\(centro.latitude - delta),\(centro.longitude - delta)"
            let ne = "\(centro.latitude + delta),\(centro.longitude + delta)"
            queryItems.append(URLQueryItem(name: "bounds", value: "\(sw)|\(ne)"))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            print("❌ [Geocoding] URL inválida")
            return
        }

        print("🌍 [Geocoding] consultando: \(query)")

        do {
            var request = URLRequest(url: url)
            if let bundleID = Bundle.main.bundleIdentifier {
                request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ [Geocoding] JSON inválido")
                return
            }
            let status = json["status"] as? String ?? "desconocido"
            guard let results = json["results"] as? [[String: Any]], !results.isEmpty else {
                print("❌ [Geocoding] sin resultados — status: \(status)")
                return
            }
            guard let geometry = results.first?["geometry"] as? [String: Any],
                  let location = geometry["location"] as? [String: Any],
                  let lat = location["lat"] as? Double,
                  let lng = location["lng"] as? Double else {
                print("❌ [Geocoding] no se pudo extraer coordenadas")
                return
            }
            print("✅ [Geocoding] resultado: (\(lat), \(lng))")
            coordenadasComercio = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } catch {
            print("❌ [Geocoding] error de red: \(error.localizedDescription)")
        }
    }

    func seleccionarModo(manual: Bool) {
        modoManual = manual
    }

    func onPagoTransferenciaChange(_ pago: Bool) {
        pagoTransferencia = pago
    }

    func onPrecioTotalProductosChange(_ texto: String) {
        precioTotalProductos = texto.filter { $0.isNumber }
    }

    func generarCodigoEfectivo() {
        Task {
            estadoValidacionEfectivo = .cargandoCodigo

            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                guard let codigo = try await verificacionService.generarCodigoEfectivo(
                    token: accessToken,
                    dispositivoID: dispositivoID
                ) else {
                    estadoValidacionEfectivo = .error
                    mostrarErrorValidacion = true
                    return
                }

                codigoEfectivo = codigo

                let numero = (perfilUsuarioState.configuracion?.numeroWhatsappAutomatico ?? "")
                    .replacingOccurrences(of: "+", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let email = perfilUsuarioState.usuario?.email ?? ""
                let texto = "Hola Livery, mi código de validación es: \(codigo). \nMi usuario es: \(email)"
                let encoded = texto.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                urlWhatsapp = "https://wa.me/\(numero)?text=\(encoded)"

                estadoValidacionEfectivo = .esperando
                iniciarPolling()
            } catch {
                estadoValidacionEfectivo = .error
                mostrarErrorValidacion = true
                print("Error generando código efectivo: \(error)")
            }
        }
    }

    private func iniciarPolling() {
        detenerPolling()
        pollingTask = Task {
            while estadoValidacionEfectivo == .esperando {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard estadoValidacionEfectivo == .esperando else { break }

                do {
                    await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                    let accessToken = TokenRepository.repository.accessToken ?? ""
                    let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                    let validado = try await verificacionService.estadoCodigoEfectivo(
                        token: accessToken,
                        dispositivoID: dispositivoID
                    )

                    if validado {
                        estadoValidacionEfectivo = .validado
                        detenerPolling()
                        break
                    }
                } catch {
                    print("Error consultando estado código efectivo: \(error)")
                }
            }
        }
    }

    func detenerPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func limpiarUrlWhatsapp() { urlWhatsapp = nil }

    func descartarErrorValidacion() { mostrarErrorValidacion = false }

    func resetEfectivo() {
        detenerPolling()
        estadoValidacionEfectivo = .idle
        codigoEfectivo = ""
        urlWhatsapp = nil
        mostrarErrorValidacion = false
    }

    func obtenerNombreUsuario() -> String {
        return perfilUsuarioState.usuario?.obtenerNombreCompleto().trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func calcularCostoEnvioDebounced() {
        costoEnvioDebounceTask?.cancel()
        costoEnvioDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await calcularCostoEnvio()
        }
    }

    func calcularCostoEnvio() async {
        guard let origenComercio = coordenadasComercio,
            let direccion = direccionesUsuario.first(where: { $0.id == idDireccionUsuarioSeleccionada }),
            direccion.coordenadas.coordinates.count >= 2 else {
            costoEnvio = nil
            distanciaEnvio = nil
            return
        }

        calculandoCostoEnvio = true

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            // El backend espera origen=comercio y destino=usuario.
            // Aquí `direccion` es la dirección del usuario y `origenComercio` representa
            // la ubicación del comercio, por lo que invertimos los parámetros.
            let envio = try await enviosService.calcularCosto(
                token: accessToken,
                dispositivoID: dispositivoID,
                latitudOrigen: origenComercio.latitude,
                longitudOrigen: origenComercio.longitude,
                latitudDestino: direccion.coordenadas.coordinates[0],
                longitudDestino: direccion.coordenadas.coordinates[1]
            )

            costoEnvio = envio.costo
            distanciaEnvio = envio.distancia
        } catch {
            costoEnvio = nil
            distanciaEnvio = nil
            print("Error calculando costo envio de reparto: \(error)")
        }

        calculandoCostoEnvio = false
    }

    func actualizarEstadisticasRepartidores() async {
        let localidad = perfilUsuarioState.ciudadSeleccionada ?? ""
        guard !localidad.isEmpty else { return }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let estadisticas = try await repartidoresService.obtenerEstadisticas(
                token: accessToken,
                dispositivoID: dispositivoID,
                localidad: localidad
            )

            tiempoEspera = estadisticas.tiempoPromedioEspera
            demandaRepartidores = estadisticas.demanda
        } catch {
            tiempoEspera = nil
            demandaRepartidores = nil
        }
    }

    func cargarComprobante(_ comprobante: Comprobante) {
        comprobanteSeleccionado = comprobante
    }

    var superaLimitePagoEfectivo: Bool {
        limitePagoEfectivo > 0 && (Double(precioTotalProductos) ?? 0) > limitePagoEfectivo
    }

    func crearReparto() async {
        guard !creandoReparto else { return }

          guard let usuario = perfilUsuarioState.usuario,
              let idDireccion = idDireccionUsuarioSeleccionada,
              let direccionUsuario = direccionesUsuario.first(where: { $0.id == idDireccion }),
              let origenComercio = coordenadasComercio else { return }

        creandoReparto = true

        let modalidad: ModalidadPago? = {
            switch pagoTransferencia {
            case .some(true):
                return ModalidadPago(tipo: "TRANSFERENCIA")
            case .some(false):
                return ModalidadPago(
                    tipo: "EFECTIVO",
                    precioTotal: Double(precioTotalProductos) ?? 0,
                    celular: "",
                    codigoVerificacion: codigoEfectivo
                )
            default:
                return nil
            }
        }()

        let reparto = Reparto(
            idInterno: UUID().uuidString.lowercased(),
            tipo: "REPARTO_SOLICITADO_USUARIO",
            idUsuario: usuario.email,
            nombreUsuario: usuario.obtenerNombreCompleto(),
            idComercio: nil,
            nombreComercio: nombreComercio.trimmingCharacters(in: .whitespacesAndNewlines),
            logoComercioURL: nil,
            idRepartidor: nil,
            nombreRepartidor: nil,
            direccion: DireccionReparto(
                calle: direccionUsuario.calle,
                numero: direccionUsuario.numero,
                departamento: direccionUsuario.departamento,
                coordenadas: direccionUsuario.coordenadas
            ),
                direccionOrigen: DireccionReparto(
                calle: calle.trimmingCharacters(in: .whitespacesAndNewlines),
                numero: numero.trimmingCharacters(in: .whitespacesAndNewlines),
                departamento: "",
                    coordenadas: Point(coordinates: [origenComercio.latitude, origenComercio.longitude])
            ),
            localidad: perfilUsuarioState.ciudadSeleccionada ?? "",
            tarifaServicio: tarifaServicio,
            envio: Double(costoEnvio ?? 0),
            indicaciones: nil,
            descripcion: descripcionEnvio.trimmingCharacters(in: .whitespacesAndNewlines),
            celular: nil,
            modalidadPago: modalidad,
            estado: nil
        )

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            try await repartosService.crearReparto(
                token: accessToken,
                dispositivoID: dispositivoID,
                reparto: reparto
            )

            if let comprobante = comprobanteSeleccionado {
                try await repartosService.cargarComprobante(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: usuario.email,
                    idReparto: reparto.idInterno,
                    comprobante: comprobante
                )
            }

            repartoCreado = true
        } catch {
            print("Error creando reparto: \(error)")
        }

        creandoReparto = false
    }

    func resetearEstado() {
        repartoCreado = false
    }

    func reiniciarFormulario() {
        costoEnvioDebounceTask?.cancel()
        detenerPolling()
        coordenadasComercio = nil
        coordenadasUsuario = nil
        idDireccionUsuarioSeleccionada = nil
        calle = ""
        numero = ""
        nombreComercio = ""
        descripcionEnvio = ""
        modoManual = false
        calculandoCostoEnvio = false
        costoEnvio = nil
        distanciaEnvio = nil
        tiempoEspera = nil
        demandaRepartidores = nil
        creandoReparto = false
        repartoCreado = false
        comprobanteSeleccionado = nil
        cargandoComprobante = false
        pagoTransferencia = nil
        resetEfectivo()
        precioTotalProductos = ""
        inicializarDatos()
    }
}
