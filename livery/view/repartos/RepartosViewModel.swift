import Foundation
import Combine
import SwiftUI

@MainActor
class RepartosViewModel: ObservableObject {
    private let perfilUsuarioState: PerfilUsuarioState
    private let repartosService = RepartosService()
    private let recorridosService = RecorridosService()

    @Published var repartos: [Reparto] = []
    @Published var estadoSeleccionado: EstadosRepartos = .todos
    @Published var repartoSeleccionado: Reparto? = nil
    @Published var recorridoSeleccionado: Recorrido? = nil
    @Published var mostrarBottomSheet: Bool = false
    @Published var cargandoComprobante: Bool = false
    @Published var recorridoTick: Int = 0

    private var paginaActual = 0
    private let tamanoPagina = 10
    private var cargando = false
    private var noHayMasRepartos = false
    private var isRecorridoTabActive = false
    private var cancellables = Set<AnyCancellable>()

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState

        $estadoSeleccionado
            .sink { [weak self] _ in
                self?.refrescarRepartos()
            }
            .store(in: &cancellables)

        iniciarPollingRecorrido()
    }

    func refrescarRepartos() {
        paginaActual = 0
        repartos = []
        noHayMasRepartos = false
        Task {
            await cargarMasRepartos()
        }
    }

    func cargarMasRepartos() async {
        guard !cargando && !noHayMasRepartos else { return }

        let email = perfilUsuarioState.usuario?.email ?? ""
        guard !email.isEmpty else { return }

        cargando = true

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let nuevos = try await repartosService.buscarPorUsuario(
                token: accessToken,
                dispositivoID: dispositivoID,
                idUsuario: email,
                estado: estadoSeleccionado.rawValue,
                skip: paginaActual * tamanoPagina,
                limit: tamanoPagina
            )

            if nuevos.isEmpty {
                noHayMasRepartos = true
            } else {
                repartos.append(contentsOf: nuevos)
                paginaActual += 1
            }
            cargando = false
        } catch {
            print("Error cargando repartos: \(error)")
            cargando = false
        }
    }

    func refrescarRepartoSeleccionado(reparto: Reparto) async {
        repartoSeleccionado = nil
        recorridoSeleccionado = nil

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let repartoInfo = try await repartosService.buscarReparto(
                token: accessToken,
                dispositivoID: dispositivoID,
                idReparto: reparto.idInterno
            )

            let recorridoInfo = try await recorridosService.buscarRecorridoReparto(
                token: accessToken,
                dispositivoID: dispositivoID,
                idReparto: reparto.idInterno
            )

            repartoSeleccionado = repartoInfo
            recorridoSeleccionado = recorridoInfo
        } catch {
            print("Error al refrescar reparto seleccionado: \(error)")
        }
    }

    func cargarComprobante(reparto: Reparto, comprobante: Comprobante) async {
        cargandoComprobante = true
        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            let email = perfilUsuarioState.usuario?.email ?? ""

            try await repartosService.cargarComprobante(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idReparto: reparto.idInterno,
                comprobante: comprobante
            )

            await refrescarRepartoSeleccionado(reparto: reparto)
        } catch {
            print("Error al cargar comprobante reparto: \(error)")
        }
        cargandoComprobante = false
    }

    func cancelarReparto(motivoCancelacion: String) async {
        guard let reparto = repartoSeleccionado else { return }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            try await repartosService.cancelarReparto(
                token: accessToken,
                dispositivoID: dispositivoID,
                idReparto: reparto.idInterno,
                motivoCancelacion: motivoCancelacion
            )
            refrescarRepartos()
        } catch {
            print("Error al cancelar reparto: \(error)")
        }
    }

    private func iniciarPollingRecorrido() {
        Task {
            while true {
                guard let configuracion = perfilUsuarioState.configuracion else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }

                let intervaloNano = UInt64(configuracion.intervalosTiempo.intervaloBuscarRecorrido * 5_000_000)
                try? await Task.sleep(nanoseconds: intervaloNano)

                if isRecorridoTabActive,
                   let reparto = repartoSeleccionado,
                   reparto.estado?.nombre == EstadoReparto.enCamino.rawValue {
                    await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                    let accessToken = TokenRepository.repository.accessToken ?? ""
                    let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                    recorridoSeleccionado = try? await recorridosService.buscarRecorridoReparto(
                        token: accessToken,
                        dispositivoID: dispositivoID,
                        idReparto: reparto.idInterno
                    )
                    forceRefreshRecorrido()
                }
            }
        }
    }

    func forceRefreshRecorrido() {
        recorridoTick += 1
    }

    func setRecorridoTabActive(active: Bool) {
        isRecorridoTabActive = active
    }

    func onMostrarBottomSheetChange(mostrar: Bool) {
        mostrarBottomSheet = mostrar
    }

    func onRepartoSeleccionadoChange(reparto: Reparto?) {
        repartoSeleccionado = reparto
    }

    func onEstadoSeleccionadoChange(estado: EstadosRepartos) {
        estadoSeleccionado = estado
    }
}
