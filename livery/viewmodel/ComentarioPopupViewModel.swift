//
//  ComentarioPopupViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 17/10/2026.
//
import Foundation
import Combine

@MainActor
class ComentarioPopupViewModel: ObservableObject {

    private let pedidosService = PedidosService()
    private let comentariosService = ComentariosService()
    private let perfilUsuarioState: PerfilUsuarioState

    @Published var pedidoParaComentar: Pedido? = nil
    @Published var enviando: Bool = false

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
    }

    func cargarPedidoParaComentar() async {
        guard let email = perfilUsuarioState.usuario?.email, !email.isEmpty else { return }

        do {
            await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
            let accessToken = TokenRepository.repository.accessToken ?? ""
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let pedidos = try await pedidosService.buscarPedidos(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                estado: "ENTREGADOS",
                skip: 0,
                limit: 1
            )

            if let ultimo = pedidos.first,
               ultimo.comentario == nil,
               ultimo.comentarioOmitido != true {
                self.pedidoParaComentar = ultimo
            }
        } catch {
            print("Error al cargar pedido para comentar: \(error)")
        }
    }

    func enviarComentario(comentario: Comentario, comentarioRepartidor: Comentario?) {
        guard let pedido = pedidoParaComentar, !enviando else { return }
        enviando = true

        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                var comentarios = [comentario]
                if let comentarioRepartidor {
                    comentarios.append(comentarioRepartidor)
                }

                try await comentariosService.enviarComentario(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: pedido.email,
                    idPedido: pedido.idInterno,
                    comentarios: comentarios
                )

                self.pedidoParaComentar = nil
            } catch {
                print("Error al enviar comentario desde el popup: \(error)")
            }
            self.enviando = false
        }
    }

    func noDejarComentario() {
        guard let pedido = pedidoParaComentar, !enviando else { return }
        enviando = true

        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                try await comentariosService.omitirComentario(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: pedido.email,
                    idPedido: pedido.idInterno
                )

                self.pedidoParaComentar = nil
            } catch {
                print("Error al omitir comentario: \(error)")
            }
            self.enviando = false
        }
    }
}
