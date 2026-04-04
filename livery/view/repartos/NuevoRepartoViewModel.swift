import Foundation
import CoreLocation

@MainActor
class NuevoRepartoViewModel: ObservableObject {
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
