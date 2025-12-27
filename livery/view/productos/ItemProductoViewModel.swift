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
        
        self.itemProducto = ItemProducto(
            idProducto: producto.idInterno,
            nombreProducto: producto.nombre,
            imagenProductoURL: producto.imagenURL ?? "",
            cantidad: self.cantidad,
            precioUnitario: producto.precio,
            precio: producto.precio * Double(self.cantidad),
            esPremio: producto.esPremio ?? false,
            idPremio: producto.idPremio
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
    
    func cambiarSeleccionadoUnitario(id: String, seleccionadoUnitario: Bool) {
        productoSeleccionableState?.cambiarSeleccionadoUnitario(id: id, seleccionado: seleccionadoUnitario)
        
        guard var itemActual = itemProducto, let cat = categoria else { return }
        
        let nuevaLista = seleccionadosUnitarios
            .filter { $0.value }
            .compactMap { (idSeleccionable, _) -> SeleccionableProducto? in
                guard let nombre = cat.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre)
            }
        
        itemActual.seleccionables = nuevaLista
        self.itemProducto = itemActual
        
        if let producto = self.producto, !producto.procesosExtras.isEmpty {
            procesosExtras()
        }
    }
    
    func cambiarSeleccionadoMultiple(id: String, cantidad: Int) {
        productoSeleccionableState?.cambiarSeleccionadoMultiple(id: id, cantidad: cantidad)
        
        guard var itemActual = itemProducto, let cat = categoria else { return }
        
        let nuevaLista = seleccionadosMultiples
            .filter { $0.value > 0 }
            .compactMap { (idSeleccionable, cant) -> SeleccionableProducto? in
                guard let nombre = cat.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre, cantidad: cant)
            }
        
        itemActual.seleccionables = nuevaLista
        self.itemProducto = itemActual
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
        item.precio = prod.precio * Double(self.cantidad)
        self.itemProducto = item
    }
    
    private func procesosExtras() {
        guard let prod = producto, let com = comercio, var item = itemProducto else { return }
        
        for proceso in prod.procesosExtras {
            if proceso == "precio-producto-mas-caro" {
                let idsSeleccionados = item.seleccionables.map { $0.idSeleccionable }.joined(separator: ",")
                
                // Swift Concurrency (Equivalente a viewModelScope.launch)
                /*
                Task {
                    do {
                        let precio = try await productosRepository.calcularPrecioMasCaro(idComercio: com.idInterno, ids: idsSeleccionados)
                        await MainActor.run {
                            item.precioUnitario = precio
                            item.precio = precio * Double(self.cantidad)
                            self.itemProducto = item
                        }
                    } catch {
                        print("Error calculando precio extra: \(error)")
                    }
                }
                 */
            }
        }
    }
}
