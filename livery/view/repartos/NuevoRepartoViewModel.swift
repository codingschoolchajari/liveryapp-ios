import Foundation
import CoreLocation
import GooglePlaces

enum EstadoEnvioCodigo {
    case idle, enviando, enviado, error
}

@MainActor
class NuevoRepartoViewModel: ObservableObject {
    private let perfilUsuarioState: PerfilUsuarioState
    private let repartosService = RepartosService()
    private let enviosService = EnviosService()
    private let repartidoresService = RepartidoresService()
    private let verificacionService = VerificacionService()

    @Published var coordenadasDestino: CLLocationCoordinate2D? = nil
    @Published var direccionesUsuario: [UsuarioDireccion] = []
    @Published var idDireccionUsuarioSeleccionada: String? = nil

    @Published var calle: String = ""
    @Published var numero: String = ""
    @Published var nombreComercio: String = ""
    @Published var descripcionEnvio: String = ""
    @Published var modoManual: Bool = false

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

    @Published var celularPais: String = "+54"
    @Published var celularNumero: String = ""
    @Published var estadoEnvioCodigo: EstadoEnvioCodigo = .idle
    @Published var codigoVerificacion: String = ""
    @Published var codigoVerificado: Bool = false
    @Published var mostrarErrorTelefono: Bool = false
    @Published var mostrarErrorCodigo: Bool = false

    private var costoEnvioDebounceTask: Task<Void, Never>? = nil
    private var coordenadasOrigen: CLLocationCoordinate2D? = nil

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        inicializarDatos()
    }

    func inicializarDatos() {
        direccionesUsuario = perfilUsuarioState.usuario?.direcciones ?? []

        let direccionSeleccionada = perfilUsuarioState.obtenerUsuarioDireccion() ?? direccionesUsuario.first
        idDireccionUsuarioSeleccionada = direccionSeleccionada?.id

        if let coords = direccionSeleccionada?.coordenadas.coordinates, coords.count >= 2 {
            let origen = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
            coordenadasOrigen = origen
            coordenadasDestino = origen
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
            coordenadasOrigen = CLLocationCoordinate2D(
                latitude: direccion.coordenadas.coordinates[0],
                longitude: direccion.coordenadas.coordinates[1]
            )
        }
        calcularCostoEnvioDebounced()
    }

    func actualizarDestino(coordenada: CLLocationCoordinate2D) {
        coordenadasDestino = coordenada
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

        actualizarDestino(coordenada: place.coordinate)
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

    func onCelularPaisChange(_ codigo: String) {
        celularPais = codigo
    }

    func onCelularNumeroChange(_ texto: String) {
        celularNumero = String(texto.filter { $0.isNumber }.prefix(10))
        if estadoEnvioCodigo == .enviado {
            estadoEnvioCodigo = .idle
            codigoVerificacion = ""
            codigoVerificado = false
        }
    }

    func onCodigoVerificacionChange(_ codigo: String) {
        let soloDigitos = String(codigo.filter { $0.isNumber }.prefix(6))
        codigoVerificacion = soloDigitos
    }

    func enviarCodigoVerificacion() {
        Task {
            let telefono = "\(celularPais)\(celularNumero.trimmingCharacters(in: .whitespaces))"
            estadoEnvioCodigo = .enviando
            codigoVerificacion = ""
            codigoVerificado = false

            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                let exito = try await verificacionService.enviarCodigo(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    telefono: telefono
                )

                if exito {
                    estadoEnvioCodigo = .enviado
                } else {
                    estadoEnvioCodigo = .error
                    mostrarErrorTelefono = true
                }
            } catch {
                estadoEnvioCodigo = .error
                mostrarErrorTelefono = true
                print("Error enviando código: \(error)")
            }
        }
    }

    func validarCodigoVerificacion() async -> Bool {
        let telefono = "\(celularPais)\(celularNumero.trimmingCharacters(in: .whitespaces))"

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let valido = try await verificacionService.validarCodigo(
                token: accessToken,
                dispositivoID: dispositivoID,
                telefono: telefono,
                codigo: codigoVerificacion
            )

            if valido {
                codigoVerificado = true
            } else {
                mostrarErrorCodigo = true
            }
            return valido
        } catch {
            mostrarErrorCodigo = true
            print("Error validando código: \(error)")
            return false
        }
    }

    func descartarErrorTelefono() { mostrarErrorTelefono = false }
    func descartarErrorCodigo() { mostrarErrorCodigo = false }

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
        guard let destino = coordenadasDestino,
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

            let envio = try await enviosService.calcularCosto(
                token: accessToken,
                dispositivoID: dispositivoID,
                latitudOrigen: direccion.coordenadas.coordinates[0],
                longitudOrigen: direccion.coordenadas.coordinates[1],
                latitudDestino: destino.latitude,
                longitudDestino: destino.longitude
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

        if pagoTransferencia == false {
            let valido = await validarCodigoVerificacion()
            if !valido { return }
        }

        guard let usuario = perfilUsuarioState.usuario,
              let idDireccion = idDireccionUsuarioSeleccionada,
              let direccionUsuario = direccionesUsuario.first(where: { $0.id == idDireccion }),
              let destino = coordenadasDestino else { return }

        creandoReparto = true

        let modalidad: ModalidadPago? = {
            switch pagoTransferencia {
            case .some(true):
                return ModalidadPago(tipo: "TRANSFERENCIA")
            case .some(false):
                return ModalidadPago(
                    tipo: "EFECTIVO",
                    precioTotal: Double(precioTotalProductos) ?? 0,
                    celular: "\(celularPais)\(celularNumero.trimmingCharacters(in: .whitespaces))",
                    codigoVerificacion: codigoVerificacion
                )
            default:
                return nil
            }
        }()

        let celularReparto: String? = pagoTransferencia == false
            ? "\(celularPais)\(celularNumero.trimmingCharacters(in: .whitespaces))"
            : nil

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
                coordenadas: Point(coordinates: [destino.latitude, destino.longitude])
            ),
            localidad: perfilUsuarioState.ciudadSeleccionada ?? "",
            tarifaServicio: tarifaServicio,
            envio: Double(costoEnvio ?? 0),
            indicaciones: nil,
            descripcion: descripcionEnvio.trimmingCharacters(in: .whitespacesAndNewlines),
            celular: celularReparto,
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
        coordenadasDestino = nil
        coordenadasOrigen = nil
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
        precioTotalProductos = ""
        celularPais = "+54"
        celularNumero = ""
        estadoEnvioCodigo = .idle
        codigoVerificacion = ""
        codigoVerificado = false
        mostrarErrorTelefono = false
        mostrarErrorCodigo = false
        inicializarDatos()
    }
}

    private let perfilUsuarioState: PerfilUsuarioState
    private let repartosService = RepartosService()
    private let enviosService = EnviosService()
    private let repartidoresService = RepartidoresService()

    @Published var coordenadasDestino: CLLocationCoordinate2D? = nil
    @Published var direccionesUsuario: [UsuarioDireccion] = []
    @Published var idDireccionUsuarioSeleccionada: String? = nil

    @Published var calle: String = ""
    @Published var numero: String = ""
    @Published var nombreComercio: String = ""
    @Published var descripcionEnvio: String = ""

    @Published var calculandoCostoEnvio: Bool = false
    @Published var tarifaServicio: Double = 0
    @Published var costoEnvio: Int? = nil
    @Published var distanciaEnvio: Int? = nil

    @Published var tiempoEspera: Int? = nil
    @Published var demandaRepartidores: String? = nil

    @Published var creandoReparto: Bool = false
    @Published var repartoCreado: Bool = false

    @Published var comprobanteSeleccionado: Comprobante? = nil

    private var costoEnvioDebounceTask: Task<Void, Never>? = nil

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        inicializarDatos()
    }

    func inicializarDatos() {
        direccionesUsuario = perfilUsuarioState.usuario?.direcciones ?? []

        let direccionSeleccionada = perfilUsuarioState.obtenerUsuarioDireccion() ?? direccionesUsuario.first
        idDireccionUsuarioSeleccionada = direccionSeleccionada?.id

        if let coords = direccionSeleccionada?.coordenadas.coordinates, coords.count >= 2 {
            coordenadasDestino = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
        }

        tarifaServicio = perfilUsuarioState.configuracion?.tarifaServicio ?? 0

        Task {
            await actualizarEstadisticasRepartidores()
            await calcularCostoEnvio()
        }
    }

    func onDireccionUsuarioSeleccionadaChange(idDireccion: String) {
        idDireccionUsuarioSeleccionada = idDireccion
        calcularCostoEnvioDebounced()
    }

    func actualizarDestino(coordenada: CLLocationCoordinate2D) {
        coordenadasDestino = coordenada
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

        actualizarDestino(coordenada: place.coordinate)
    }

    private func calcularCostoEnvioDebounced() {
        costoEnvioDebounceTask?.cancel()
        costoEnvioDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await calcularCostoEnvio()
        }
    }

    func calcularCostoEnvio() async {
        guard let destino = coordenadasDestino,
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

            let envio = try await enviosService.calcularCosto(
                token: accessToken,
                dispositivoID: dispositivoID,
                latitudOrigen: direccion.coordenadas.coordinates[0],
                longitudOrigen: direccion.coordenadas.coordinates[1],
                latitudDestino: destino.latitude,
                longitudDestino: destino.longitude
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

    func formularioCompleto() -> Bool {
        !calle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !numero.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nombreComercio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !descripcionEnvio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        idDireccionUsuarioSeleccionada != nil &&
        comprobanteSeleccionado != nil &&
        costoEnvio != nil &&
        coordenadasDestino != nil
    }

    func crearReparto() async {
        guard formularioCompleto(), !creandoReparto else { return }

        guard let usuario = perfilUsuarioState.usuario,
              let idDireccion = idDireccionUsuarioSeleccionada,
              let direccionUsuario = direccionesUsuario.first(where: { $0.id == idDireccion }),
              let destino = coordenadasDestino,
              let comprobante = comprobanteSeleccionado else { return }

        creandoReparto = true

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
                coordenadas: Point(coordinates: [destino.latitude, destino.longitude])
            ),
            localidad: perfilUsuarioState.ciudadSeleccionada ?? "",
            tarifaServicio: tarifaServicio,
            envio: Double(costoEnvio ?? 0),
            indicaciones: nil,
            descripcion: descripcionEnvio.trimmingCharacters(in: .whitespacesAndNewlines),
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

            try await repartosService.cargarComprobante(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: usuario.email,
                idReparto: reparto.idInterno,
                comprobante: comprobante
            )

            repartoCreado = true
        } catch {
            print("Error creando reparto: \(error)")
        }

        creandoReparto = false
    }

    func resetearEstado() {
        repartoCreado = false
    }
}
