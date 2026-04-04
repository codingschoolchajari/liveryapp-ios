import Foundation
import Combine

@MainActor
class RepartoChatViewModel: ObservableObject {
    private let chatsRepartosService = ChatsRepartosService()
    private let perfilUsuarioState: PerfilUsuarioState

    @Published var chat: Chat? = nil
    @Published var mensajes: [Mensaje] = []
    @Published var errorMensaje: String? = nil

    @Published private var idReparto: String? = nil
    @Published private var idRepartidor: String? = nil
    @Published private var refreshCounter: Int = 0

    private var isChatTabActive = false
    private var ultimoTimestamp: Int64? = nil
    private var cancellables = Set<AnyCancellable>()

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState

        Publishers.CombineLatest($idReparto, $idRepartidor)
            .combineLatest($refreshCounter)
            .map { params, _ in (params.0, params.1) }
            .filter { $0.0 != nil && $0.1 != nil }
            .sink { [weak self] params in
                self?.mensajes = []
                self?.ultimoTimestamp = nil
                self?.obtenerChat(idReparto: params.0!, idRepartidor: params.1!)
            }
            .store(in: &cancellables)

        iniciarPolling()
    }

    private func obtenerChat(idReparto: String, idRepartidor: String) {
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                let chatObtenido = try await chatsRepartosService.obtenerChat(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    idReparto: idReparto,
                    idRepartidor: idRepartidor
                )

                self.chat = chatObtenido
                self.mensajes = chatObtenido.mensajes
                self.ultimoTimestamp = self.mensajes.last?.timestamp
            } catch {
                print("Error al obtener chat de reparto: \(error)")
            }
        }
    }

    func enviarMensaje(mensaje: Mensaje) {
        guard let idReparto, let idRepartidor else { return }

        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                try await chatsRepartosService.enviarMensaje(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    idReparto: idReparto,
                    idRepartidor: idRepartidor,
                    mensaje: mensaje
                )
            } catch {
                self.errorMensaje = error.localizedDescription
            }
        }
    }

    private func iniciarPolling() {
        Task {
            while !Task.isCancelled {
                guard let config = perfilUsuarioState.configuracion else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }

                let intervaloNano = UInt64(config.intervalosTiempo.intervaloBuscarMensajeChat * 1_000_000)
                try? await Task.sleep(nanoseconds: intervaloNano)

                if isChatTabActive,
                   let idReparto,
                   let idRepartidor {
                    await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                    let accessToken = TokenRepository.repository.accessToken ?? ""
                    let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                    let solicitante = perfilUsuarioState.usuario?.email ?? ""

                    do {
                        let mensajesNuevos = try await chatsRepartosService.obtenerNuevosMensajes(
                            token: accessToken,
                            dispositivoID: dispositivoID,
                            desde: ultimoTimestamp ?? 0,
                            idReparto: idReparto,
                            solicitante: solicitante,
                            idRepartidor: idRepartidor
                        )

                        if !mensajesNuevos.isEmpty {
                            var actuales = mensajes
                            actuales.append(contentsOf: mensajesNuevos)
                            let agrupados = Dictionary(grouping: actuales, by: { $0.id })
                            actuales = agrupados.compactMap { $0.value.first }.sorted(by: { $0.timestamp < $1.timestamp })
                            mensajes = actuales
                            ultimoTimestamp = actuales.last?.timestamp
                        }
                    } catch {
                        print("Error polling chat reparto: \(error)")
                    }
                }
            }
        }
    }

    func setChatTabActive(active: Bool) {
        isChatTabActive = active
    }

    func setChatParams(idReparto: String?, idRepartidor: String?) {
        self.idReparto = idReparto
        self.idRepartidor = idRepartidor
        refreshCounter += 1
    }

    func limpiarError() {
        errorMensaje = nil
    }

    func limpiarChat() {
        mensajes = []
        ultimoTimestamp = nil
        idRepartidor = nil
    }
}
