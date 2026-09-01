//
//  MisPuntosViewModel.swift
//  livery
//
import Foundation
import Combine

@MainActor
class MisPuntosViewModel: ObservableObject {

    private let usuariosService = UsuariosService()
    private let premiosService = PremiosService()
    private let comerciosService = ComerciosService()
    private let perfilUsuarioState: PerfilUsuarioState

    @Published var puntos: Int? = nil

    @Published var pestaniaActiva: String = "Historial"

    @Published var historialPuntos: [HistorialPuntosItem] = []
    @Published var cargandoHistorial: Bool = false
    @Published var hayMasHistorial: Bool = true

    @Published var premiosCanjeables: [PremioCanjeable] = []
    @Published var premiosCanjeados: [PremioCanjeado] = []

    @Published var canjeadoSeleccionado: PremioCanjeado? = nil
    @Published var productoSeleccionado: Producto? = nil

    var comercio: Comercio? = nil
    var categoria: Categoria? = nil

    private var skipHistorial = 0
    private let tamanoPagina = 20

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
    }

    func cargarPuntos(email: String) {
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                let resultado = try await usuariosService.obtenerPuntos(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: email
                )
                self.puntos = resultado.total
            } catch {
                print("Error al cargar puntos: \(error)")
            }
        }
    }

    func cargarHistorial(email: String) {
        guard !cargandoHistorial, hayMasHistorial else { return }
        cargandoHistorial = true
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                let response = try await usuariosService.obtenerHistorialPuntos(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: email,
                    skip: skipHistorial,
                    limit: tamanoPagina
                )
                let nuevos = response.items
                if !nuevos.isEmpty {
                    skipHistorial += nuevos.count
                    historialPuntos = historialPuntos + nuevos
                }
                hayMasHistorial = response.hasMore
            } catch {
                print("Error al cargar historial: \(error)")
            }
            cargandoHistorial = false
        }
    }

    func resetHistorial() {
        historialPuntos = []
        skipHistorial = 0
        hayMasHistorial = true
    }

    func cargarPremiosCanjeables() {
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                let localidad = perfilUsuarioState.ciudadSeleccionada ?? ""

                let premios = try await premiosService.obtenerPremiosCanjeables(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    localidad: localidad
                )
                self.premiosCanjeables = premios
            } catch {
                print("Error al cargar premios canjeables: \(error)")
            }
        }
    }

    func cargarPremiosCanjeados(email: String) {
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

                let premios = try await premiosService.obtenerPremiosCanjeados(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    email: email
                )
                self.premiosCanjeados = premios
            } catch {
                print("Error al cargar premios canjeados: \(error)")
            }
        }
    }

    func canjearProducto(idProducto: String, idComercio: String, email: String, onResult: @escaping @MainActor (Bool) -> Void) {
        Task {
            do {
                await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                let accessToken = TokenRepository.repository.accessToken ?? ""
                let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                let localidad = perfilUsuarioState.ciudadSeleccionada ?? ""

                let request = CanjearRequest(idProducto: idProducto, idComercio: idComercio)
                _ = try await premiosService.canjearProducto(
                    token: accessToken,
                    dispositivoID: dispositivoID,
                    localidad: localidad,
                    email: email,
                    request: request
                )
                cargarPuntos(email: email)
                await onResult(true)
            } catch {
                print("Error al canjear producto: \(error)")
                await onResult(false)
            }
        }
    }

    func seleccionarCanjeado(premioCanjeado: PremioCanjeado) {
        canjeadoSeleccionado = premioCanjeado
    }

    func limpiarCanjeadoSeleccionado() {
        canjeadoSeleccionado = nil
    }

    func inicializarProductoCanjeado(idComercio: String, idProducto: String, idPremio: String) async {
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
                self.categoria = ComerciosHelper.obtenerCategoria(comercio: comercioActual, idProducto: idProducto)
                var producto = ComerciosHelper.obtenerProducto(comercio: comercioActual, idProducto: idProducto)

                producto?.esPremio = true
                producto?.idPremio = idPremio
                producto?.tipoPremio = "PREMIO_CANJEADO"
                producto?.precio = 0.0
                producto?.precioSinDescuento = nil
                producto?.descuento = nil

                self.productoSeleccionado = producto
            }
        } catch {
            print("Error al inicializar producto canjeado: \(error)")
        }
    }

    func limpiarProductoSeleccionado() {
        productoSeleccionado = nil
    }
}