//
//  HomeViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 19/12/2025.
//
import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    private let perfilUsuarioState: PerfilUsuarioState
    private let comerciosService = ComerciosService()
    
    @Published private(set) var modoComercioSeleccionado: Bool = true

    // Modo Comercio
    @Published private(set) var categoriaSeleccionada: String?
    @Published private(set) var comercios: [Comercio] = []

    private var paginaActualComercios = 0
    private let tamanoPaginaComercios = 10
    private var cargandoComercios = false
    private var noHayMasComercios = false
    
    // Modo Producto
    @Published private(set) var palabraClaveSeleccionada: String?
    @Published private(set) var comerciosProductos: [ComercioProductos] = []

    @Published private(set) var productoSeleccionado: Producto?
    @Published private(set) var promocionSeleccionada: Promocion?

    private var paginaActualComerciosProductos = 0
    private let tamanoPaginaComerciosProductos = 10
    private var cargandoComerciosProductos = false
    private var noHayMasComerciosProductos = false

    // Extras
    var comercio: Comercio?
    var categoria: Categoria?

    private var cancellables = Set<AnyCancellable>()

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        
        self.categoriaSeleccionada = perfilUsuarioState.categoriaSeleccionadaHome ?? ListUtils.categorias.randomElement()?.idInterno
        
        configurarObservers()
    }

    // Observers (equivalente a combine + launchIn)
    private func configurarObservers() {

        // Categoría + ciudad → comercios
        Publishers.CombineLatest(
            $categoriaSeleccionada,
            perfilUsuarioState.$ciudadSeleccionada
        )
        .sink { [weak self] categoria, ciudad in
            guard
                let self,
                let categoria,
                let ciudad,
                !ciudad.isEmpty
            else { return }

            self.paginaActualComercios = 0
            self.comercios = []
            self.noHayMasComercios = false
            self.cargarMasComercios()
        }
        .store(in: &cancellables)

        // Palabra clave + ciudad → comerciosProductos
        Publishers.CombineLatest(
            $palabraClaveSeleccionada,
            perfilUsuarioState.$ciudadSeleccionada
        )
        .sink { [weak self] palabraClave, ciudad in
            guard
                let self,
                let palabraClave,
                let ciudad,
                !ciudad.isEmpty
            else { return }

            self.paginaActualComerciosProductos = 0
            self.comerciosProductos = []
            self.noHayMasComerciosProductos = false
            self.cargarMasComerciosProductos()
        }
        .store(in: &cancellables)
    }

    func onModoComercioSeleccionadoChange(_ valor: Bool) {
        modoComercioSeleccionado = valor
    }

    func onCategoriaSeleccionadaChange(_ valor: String) {
        categoriaSeleccionada = valor
    }

    func onPalabraClaveSeleccionadaChange(_ valor: String?) {
        palabraClaveSeleccionada = valor
    }

    func cargarMasComercios() {
        guard
            !cargandoComercios,
            !noHayMasComercios,
            let categoria = categoriaSeleccionada,
            let ciudad = perfilUsuarioState.ciudadSeleccionada,
            !ciudad.isEmpty
        else { return }

        cargandoComercios = true

        Task {
            let nuevos = try await comerciosService.buscarPorCategoria(
                perfilUsuarioState: perfilUsuarioState,
                localidad: ciudad,
                categoria: categoria,                
                skip: paginaActualComercios * tamanoPaginaComercios,
                limit: tamanoPaginaComercios
            )

            if nuevos.isEmpty {
                noHayMasComercios = true
            } else {
                comercios += nuevos
                paginaActualComercios += 1
            }

            cargandoComercios = false
        }
    }

    func cargarMasComerciosProductos() {
        guard
            !cargandoComerciosProductos,
            !noHayMasComerciosProductos,
            let palabraClave = palabraClaveSeleccionada,
            let ciudad = perfilUsuarioState.ciudadSeleccionada,
            !ciudad.isEmpty
        else { return }

        cargandoComerciosProductos = true

        Task {
            let nuevos = try await comerciosService.buscarProductosPorPalabraClave(
                perfilUsuarioState: perfilUsuarioState,
                localidad: ciudad,
                palabraClave: palabraClave,
                skip: paginaActualComerciosProductos * tamanoPaginaComerciosProductos,
                limit: tamanoPaginaComerciosProductos
            )

            if nuevos.isEmpty {
                noHayMasComerciosProductos = true
            } else {
                comerciosProductos += nuevos
                paginaActualComerciosProductos += 1
            }

            cargandoComerciosProductos = false
        }
    }

    func inicializarProductoSeleccionado(
        idComercio: String,
        idProducto: String
    ) async {
        do {
            comercio = try await comerciosService.buscarComercio(
                perfilUsuarioState: perfilUsuarioState,
                idInterno: idComercio
            )

            guard let comercio else { return }

            categoria = ComerciosHelper.obtenerCategoria(comercio: comercio, idProducto: idProducto)
            productoSeleccionado = ComerciosHelper.obtenerProducto(comercio: comercio, idProducto: idProducto)

        } catch {
            print("Error iniciando producto seleccionado: \(error)")
        }
    }

    func limpiarProductoSeleccionado() {
        productoSeleccionado = nil
        comercio = nil
        categoria = nil
    }

    func inicializarPromocionSeleccionada(
        idComercio: String,
        idPromocion: String
    ) async {
        do {
            
            comercio = try await comerciosService.buscarComercio(
                perfilUsuarioState: perfilUsuarioState,
                idInterno: idComercio)
            
            guard let comercio else { return }
            
            promocionSeleccionada = ComerciosHelper.obtenerPromocion(comercio: comercio, idPromocion: idPromocion)
            
        } catch {
            print("Error iniciando promoción seleccionada: \(error)")
        }
    }

    func limpiarPromocionSeleccionada() {
        promocionSeleccionada = nil
        comercio = nil
    }
}
