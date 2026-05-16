//
//  ItemProductoViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import Foundation
import Combine

class ItemProductoViewModel: ObservableObject {
    
    @Published var productoSeleccionableState: ProductoSeleccionableState? = nil
    @Published var itemProducto: ItemProducto? = nil
    @Published var cantidad: Int = 1
    
    @Published var seleccionadosUnitarios: [String: Bool] = [:]
    @Published var seleccionadosMultiples: [String: Int] = [:]
    @Published var opcionesPersonalizablesSeleccionadas: [String: String] = [:]
    
    @Published var alternativasSeleccionadas: [ProductoAlternativa] = []

    var alternativaParaDescripcion: ProductoAlternativa? {
        guard let prod = producto else { return nil }
        let esMultiSelect = (prod.cantidadMaximaAlternativasSeleccionables ?? 1) > 1
        return esMultiSelect ? nil : alternativasSeleccionadas.first
    }
    
    private let productosService = ProductosService()
    
    private var producto: Producto?
    private var categoria: Categoria?
    private var comercio: Comercio?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $productoSeleccionableState
            .compactMap { $0 } // filterNotNull
            .flatMap { state in
                // Combinamos ambos publishers del estado hijo
                Publishers.CombineLatest(state.$seleccionadosUnitarios, state.$seleccionadosMultiples)
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] unitarios, multiples in
                self?.seleccionadosUnitarios = unitarios
                self?.seleccionadosMultiples = multiples
            }
            .store(in: &cancellables)
    }
    
    func inicializar(producto: Producto, categoria: Categoria, comercio: Comercio) {
        self.producto = producto
        self.categoria = categoria
        self.comercio = comercio
        self.cantidad = 1
        
        inicializarProductoSeleccionable(producto: producto, categoria: categoria)
        inicializarProductoConAlternativas(producto: producto)
        inicializarPersonalizables(producto: producto)
        
        let precio = obtenerPrecio()
        
        self.itemProducto = ItemProducto(
            idProducto: producto.idInterno,
            nombreProducto: producto.nombre,
            nombreAlternativaProducto: buildNombreAlternativas(),
            imagenProductoURL: producto.imagenURL ?? "",
            cantidad: self.cantidad,
            precioUnitario: precio,
            precio: precio * Double(self.cantidad),
            opcionesPersonalizables: buildOpcionesPersonalizables(),
            esPremio: producto.esPremio ?? false,
            idPremio: producto.idPremio,
            contieneAlcohol: producto.contieneAlcohol,
            disponibleParaDelivery: buildDisponibleParaDelivery(),
            horariosReducidos: producto.horariosReducidos
        )
    }
    
    func inicializarProductoSeleccionable(producto: Producto, categoria: Categoria) {
        let resultado = ProductoSeleccionableState(idProducto: producto.idInterno)
        
        if let seleccionables = categoria.seleccionables {
            resultado.seleccionadosUnitarios = Dictionary(uniqueKeysWithValues: seleccionables.map { ($0.idInterno, false) })
            resultado.seleccionadosMultiples = Dictionary(uniqueKeysWithValues: seleccionables.map { ($0.idInterno, 0) })
        }
        
        self.productoSeleccionableState = resultado
    }
    
    func inicializarProductoConAlternativas(producto: Producto) {
        if !producto.alternativas.isEmpty {
            let esMultiSelect = (producto.cantidadMaximaAlternativasSeleccionables ?? 1) > 1
            alternativasSeleccionadas = esMultiSelect ? [] : [producto.alternativas[0]]
        } else {
            alternativasSeleccionadas = []
        }
    }

    func inicializarPersonalizables(producto: Producto) {
        guard let personalizables = producto.personalizables, !personalizables.isEmpty else {
            opcionesPersonalizablesSeleccionadas = [:]
            return
        }

        opcionesPersonalizablesSeleccionadas = personalizables.reduce(into: [:]) { result, personalizable in
            guard
                let opciones = personalizable.opciones,
                let opcionDisponible = opciones.first(where: { $0.disponible })
            else {
                return
            }
            result[personalizable.idInterno] = opcionDisponible.idInterno
        }
    }

    func seleccionarOpcionPersonalizable(idPersonalizable: String, idOpcion: String) {
        opcionesPersonalizablesSeleccionadas[idPersonalizable] = idOpcion

        itemProducto?.opcionesPersonalizables = buildOpcionesPersonalizables()
    }
    
    func cambiarSeleccionadoUnitario(
        perfilUsuarioState: PerfilUsuarioState,
        id: String,
        seleccionadoUnitario: Bool
    ) {
        productoSeleccionableState?.cambiarSeleccionadoUnitario(id: id, seleccionado: seleccionadoUnitario)
        
        if(itemProducto == nil || categoria == nil) { return }
        
        let nuevaLista = productoSeleccionableState?.seleccionadosUnitarios
            .filter { $0.value }
            .compactMap { (idSeleccionable, _) -> SeleccionableProducto? in
                guard let nombre = categoria!.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre)
            }
        
        itemProducto!.seleccionables = nuevaLista ?? []
        
        if let producto = self.producto, !producto.procesosExtras.isEmpty {
            procesosExtras(perfilUsuarioState: perfilUsuarioState)
        }
    }
    
    func cambiarSeleccionadoMultiple(
        perfilUsuarioState: PerfilUsuarioState,
        id: String,
        cantidad: Int
    ) {
        productoSeleccionableState?.cambiarSeleccionadoMultiple(id: id, cantidad: cantidad)
        
        if(itemProducto == nil || categoria == nil) { return }
        
        let nuevaLista = productoSeleccionableState?.seleccionadosMultiples
            .filter { $0.value > 0 }
            .compactMap { (idSeleccionable, cant) -> SeleccionableProducto? in
                guard let nombre = categoria!.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre, cantidad: cant)
            }
        
        itemProducto!.seleccionables = nuevaLista ?? []

        if let producto = self.producto, !producto.procesosExtras.isEmpty {
            procesosExtras(perfilUsuarioState: perfilUsuarioState)
        }
    }
    
    func cambiarAlternativaSeleccionada(productoAlternativa: ProductoAlternativa) {
        guard let prod = producto else { return }
        let maxSeleccionables = prod.cantidadMaximaAlternativasSeleccionables ?? 1

        if maxSeleccionables > 1 {
            // Multi-select: toggle en la lista
            var actual = alternativasSeleccionadas
            if actual.contains(where: { $0.idInterno == productoAlternativa.idInterno }) {
                actual.removeAll { $0.idInterno == productoAlternativa.idInterno }
            } else if actual.count < maxSeleccionables {
                actual.append(productoAlternativa)
            }
            alternativasSeleccionadas = actual
            let precio = obtenerPrecio()
            itemProducto?.nombreAlternativaProducto = buildNombreAlternativas()
            itemProducto?.precioUnitario = precio
            itemProducto?.precio = precio * Double(self.cantidad)
            itemProducto?.disponibleParaDelivery = buildDisponibleParaDelivery()
        } else {
            // Single-select: reemplaza la selección y reinicia cantidad
            alternativasSeleccionadas = [productoAlternativa]
            self.cantidad = 1
            let precio = obtenerPrecio()
            self.itemProducto = ItemProducto(
                idProducto: prod.idInterno,
                nombreProducto: prod.nombre,
                nombreAlternativaProducto: buildNombreAlternativas(),
                imagenProductoURL: prod.imagenURL ?? "",
                cantidad: self.cantidad,
                precioUnitario: precio,
                precio: precio * Double(self.cantidad),
                opcionesPersonalizables: buildOpcionesPersonalizables(),
                esPremio: prod.esPremio ?? false,
                idPremio: prod.idPremio,
                contieneAlcohol: prod.contieneAlcohol,
                disponibleParaDelivery: buildDisponibleParaDelivery(),
                horariosReducidos: prod.horariosReducidos
            )
        }
    }
    
    func aumentarCantidad() {
        self.cantidad += 1
        actualizarItemPedido()
    }
    
    func disminuirCantidad() {
        if self.cantidad > 1 {
            self.cantidad -= 1
            actualizarItemPedido()
        }
    }
    
    private func actualizarItemPedido() {
        guard var item = itemProducto, let prod = producto else { return }
        item.cantidad = self.cantidad
        item.precio = obtenerPrecio() * Double(self.cantidad)
        self.itemProducto = item
    }

    private func buildOpcionesPersonalizables() -> String? {
        guard
            let producto,
            let personalizables = producto.personalizables,
            !opcionesPersonalizablesSeleccionadas.isEmpty
        else {
            return nil
        }

        let opciones = personalizables.compactMap { personalizable -> String? in
            guard
                let idOpcion = opcionesPersonalizablesSeleccionadas[personalizable.idInterno],
                let opcion = personalizable.opciones?.first(where: { $0.idInterno == idOpcion })
            else {
                return nil
            }

            return opcion.nombre
        }

        return opciones.isEmpty ? nil : opciones.joined(separator: " - ")
    }
    
    private func procesosExtras(perfilUsuarioState: PerfilUsuarioState) {
        if(producto == nil || comercio == nil || itemProducto == nil) { return }
        
        for proceso in producto!.procesosExtras {
            if proceso == "precio-producto-mas-caro" {
                let idsSeleccionados = itemProducto!.seleccionables.map { $0.idSeleccionable }.joined(separator: ",")
                
                Task {
                    do {
                        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
                        let accessToken = TokenRepository.repository.accessToken ?? ""
                        
                        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
                        
                        let precioResponse: PrecioResponse = try await productosService.calcularPrecioMasCaro(
                            token: accessToken,
                            dispositivoID: dispositivoID,
                            idComercio: comercio!.idInterno,
                            productos: idsSeleccionados
                        )
                        await MainActor.run {
                            itemProducto!.precioUnitario = precioResponse.precio
                            itemProducto!.precio = precioResponse.precio * Double(self.cantidad)
                        }
                    } catch {
                        print("Error calculando precio extra: \(error)")
                    }
                }
            }

            if proceso == "50-off-segunda-unidad" {
                let seleccionadosMultiples = productoSeleccionableState?.seleccionadosMultiples ?? [:]
                let cantidadSeleccionada = seleccionadosMultiples.values.reduce(0, +)
                let cantidadMinima = producto!.cantidadMinimaSeleccionables ?? 0
                let precioCalculado = ProcesoExtraHelper.calcularPrecio50OffSegundaUnidad(
                    seleccionadosMultiples: seleccionadosMultiples,
                    comercio: comercio!,
                    cantidadMinima: producto!.cantidadMinimaSeleccionables
                )
                if let precio = precioCalculado {
                    itemProducto!.precioUnitario = precio
                    itemProducto!.precio = precio
                } else if cantidadSeleccionada < cantidadMinima {
                    itemProducto!.precioUnitario = 0.0
                    itemProducto!.precio = 0.0
                }
            }

            if proceso == "dos-por-uno" {
                let seleccionadosMultiples = productoSeleccionableState?.seleccionadosMultiples ?? [:]
                let cantidadSeleccionada = seleccionadosMultiples.values.reduce(0, +)
                let cantidadMinima = producto!.cantidadMinimaSeleccionables ?? 0
                let precioCalculado = ProcesoExtraHelper.calcularPrecioDosPorUno(
                    seleccionadosMultiples: seleccionadosMultiples,
                    comercio: comercio!,
                    cantidadMinima: producto!.cantidadMinimaSeleccionables
                )
                if let precio = precioCalculado {
                    itemProducto!.precioUnitario = precio
                    itemProducto!.precio = precio
                } else if cantidadSeleccionada < cantidadMinima {
                    itemProducto!.precioUnitario = 0.0
                    itemProducto!.precio = 0.0
                }
            }
        }
    }
    
    private func buildNombreAlternativas() -> String? {
        let nombres = alternativasSeleccionadas.map { $0.nombreAbreviado }.joined(separator: " / ")
        return nombres.isEmpty ? nil : nombres
    }

    private func obtenerPrecio() -> Double {
        guard let prod = producto else { return 0 }
        let esPremio = prod.esPremio ?? false
        if !alternativasSeleccionadas.isEmpty && !esPremio {
            return alternativasSeleccionadas.reduce(0) { $0 + $1.precio }
        } else {
            return prod.precio
        }
    }

    private func buildDisponibleParaDelivery() -> Bool? {
        return (producto?.disponibleParaDelivery == false || alternativasSeleccionadas.contains(where: { $0.disponibleParaDelivery == false })) ? false : nil
    }
}
