//
//  ItemPromocionViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import Foundation
import Combine

class ItemPromocionViewModel: ObservableObject {
    
    @Published var productosSeleccionablesState: [String: ProductoSeleccionableState] = [:]
    @Published var itemPromocion: ItemPromocion? = nil
    @Published var cantidad: Int = 1
    @Published var cantidadSeleccionablesValida: Bool = false
    
    private var promocion: Promocion?
    private var comercio: Comercio?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $productosSeleccionablesState
            .flatMap { mapa -> AnyPublisher<Bool, Never> in
                if mapa.isEmpty {
                    return Just(false).eraseToAnyPublisher()
                }
                
                // 1. Escuchamos el "WillChange" de todos los hijos
                let allPublishers = mapa.values.map { state in
                    state.objectWillChange
                        // Se espera a que impacte el nuevo valor para hacer las validaciones con los valores actualizados
                        .delay(for: .zero, scheduler: RunLoop.main)
                        .eraseToAnyPublisher()
                }

                return Publishers.MergeMany(allPublishers)
                    .map { _ in
                        self.validarCantidadSeleccionables(mapa)
                    }
                    .prepend(self.validarCantidadSeleccionables(mapa))
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .assign(to: &$cantidadSeleccionablesValida)
    }
    
    func inicializar(promocion: Promocion, comercio: Comercio) {
        self.comercio = comercio
        self.promocion = promocion
        self.cantidad = 1
        
        inicializarProductosSeleccionables(promocion: promocion, comercio: comercio)
        
        self.itemPromocion = ItemPromocion(
            idPromocion: promocion.idInterno,
            nombrePromocion: promocion.nombre,
            imagenPromocionURL: promocion.imagenURL,
            cantidad: self.cantidad,
            precioUnitario: promocion.precio,
            precio: promocion.precio * Double(self.cantidad)
        )
    }
    
    func inicializarProductosSeleccionables(promocion: Promocion, comercio: Comercio) {
        var resultado: [String: ProductoSeleccionableState] = [:]
        
        for idProducto in promocion.productosSeleccionables {
            let producto = ComerciosHelper.obtenerProducto(comercio: comercio, idProducto: idProducto)
            let categoria = ComerciosHelper.obtenerCategoria(comercio: comercio, idProducto: idProducto)
            
            if let _ = producto, let cat = categoria {
                let nuevoProductosSeleccionableState = ProductoSeleccionableState(idProducto: idProducto)
                
                if let seleccionables = cat.seleccionables {
                    nuevoProductosSeleccionableState.seleccionadosUnitarios = Dictionary(uniqueKeysWithValues: seleccionables.map { ($0.idInterno, false) })
                    nuevoProductosSeleccionableState.seleccionadosMultiples = Dictionary(uniqueKeysWithValues: seleccionables.map { ($0.idInterno, 0) })
                }
                
                resultado[idProducto] = nuevoProductosSeleccionableState
            }
        }
        
        self.productosSeleccionablesState = resultado
    }
    
    func cambiarSeleccionadoUnitario(productoSeleccionableState: ProductoSeleccionableState, id: String, seleccionado: Bool) {
        productoSeleccionableState.cambiarSeleccionadoUnitario(id: id, seleccionado: seleccionado)
        
        if(itemPromocion == nil || comercio == nil) { return }
        
        let categoria = ComerciosHelper.obtenerCategoria(comercio: comercio!, idProducto: productoSeleccionableState.idProducto)
        
        let nuevaLista = productoSeleccionableState.seleccionadosUnitarios
            .filter { $0.value }
            .compactMap { (idSeleccionable, _) -> SeleccionableProducto? in
                guard let nombre = categoria?.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre)
            }
        
        actualizarSeleccionablesEnItem(idProducto: productoSeleccionableState.idProducto, nuevaLista: nuevaLista)
    }
    
    func cambiarSeleccionadoMultiple(productoState: ProductoSeleccionableState, id: String, cantidad: Int) {
        productoState.cambiarSeleccionadoMultiple(id: id, cantidad: cantidad)
        
        if(itemPromocion == nil || comercio == nil) { return }
        
        let categoria = ComerciosHelper.obtenerCategoria(comercio: comercio!, idProducto: productoState.idProducto)
        
        let nuevaLista = productoState.seleccionadosMultiples
            .filter { $0.value > 0 }
            .compactMap { (idSeleccionable, cant) -> SeleccionableProducto? in
                guard let nombre = categoria?.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre, cantidad: cant)
            }
        
        actualizarSeleccionablesEnItem(idProducto: productoState.idProducto, nuevaLista: nuevaLista)
    }
    
    private func actualizarSeleccionablesEnItem(idProducto: String, nuevaLista: [SeleccionableProducto]) {
        guard var item = itemPromocion else { return }
        item.seleccionablesPorProducto[idProducto] = nuevaLista
        self.itemPromocion = item
    }
    
    func aumentarCantidad() {
        self.cantidad += 1
        actualizarItemPromocion()
    }
    
    func disminuirCantidad() {
        if self.cantidad > 1 {
            self.cantidad -= 1
            actualizarItemPromocion()
        }
    }
    
    private func actualizarItemPromocion() {
        guard let promo = promocion else { return }
        itemPromocion?.cantidad = self.cantidad
        itemPromocion?.precio = promo.precio * Double(self.cantidad)
    }
    
    private func validarCantidadSeleccionables(_ productosSeleccionablesState: [String: ProductoSeleccionableState]) -> Bool {
        // 1. Verificación inicial de seguridad
        guard let comercio = self.comercio else { return false }
        
        // 2. Iteramos sobre el mapa de productos seleccionables
        for (idProducto, productoState) in productosSeleccionablesState {
            
            // Buscamos la definición del producto en los datos del comercio
            guard let producto = ComerciosHelper.obtenerProducto(comercio: comercio, idProducto: idProducto),
                  let min = producto.cantidadMinimaSeleccionables,
                  let max = producto.cantidadMaximaSeleccionables else {
                continue // Si no hay reglas definidas, saltamos al siguiente
            }

            // 3. Calculamos totales (Equivalente a .value.values.count y .sum())
            let totalUnitarios = productoState.seleccionadosUnitarios.values.count { $0 == true }
            let totalMultiples = productoState.seleccionadosMultiples.values.reduce(0, +)

            // 4. Aplicamos tu lógica de validación
            let condicionValida = (totalUnitarios >= min || totalMultiples == max)

            // 5. Si uno solo falla, la validación global es falsa (Short-circuit)
            if !condicionValida {
                return false
            }
        }

        // 6. Si todos pasaron la validación
        return true
    }
}
