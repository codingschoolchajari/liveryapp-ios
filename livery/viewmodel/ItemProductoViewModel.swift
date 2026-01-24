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
    
    @Published var alternativaSeleccionada: ProductoAlternativa? = nil
    
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
        
        let precio = obtenerPrecio()
        
        self.itemProducto = ItemProducto(
            idProducto: producto.idInterno,
            nombreProducto: producto.nombre,
            nombreAlternativaProducto: alternativaSeleccionada != nil ? alternativaSeleccionada?.nombreAbreviado: nil,
            imagenProductoURL: producto.imagenURL ?? "",
            cantidad: self.cantidad,
            precioUnitario: precio,
            precio: precio * Double(self.cantidad),
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
    
    func inicializarProductoConAlternativas(producto: Producto) {
        if(producto.alternativas.count > 0) {
            alternativaSeleccionada = producto.alternativas.first
        }
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
    
    func cambiarSeleccionadoMultiple(id: String, cantidad: Int) {
        productoSeleccionableState?.cambiarSeleccionadoMultiple(id: id, cantidad: cantidad)
        
        if(itemProducto == nil || categoria == nil) { return }
        
        let nuevaLista = productoSeleccionableState?.seleccionadosMultiples
            .filter { $0.value > 0 }
            .compactMap { (idSeleccionable, cant) -> SeleccionableProducto? in
                guard let nombre = categoria!.seleccionables?.first(where: { $0.idInterno == idSeleccionable })?.nombre else { return nil }
                return SeleccionableProducto(idSeleccionable: idSeleccionable, nombreSeleccionable: nombre, cantidad: cant)
            }
        
        itemProducto!.seleccionables = nuevaLista ?? []
    }
    
    func cambiarAlternativaSeleccionada(productoAlternativa: ProductoAlternativa){
        if(producto == nil) { return }
        
        alternativaSeleccionada = productoAlternativa
        
        self.cantidad = 1
        
        let precio = obtenerPrecio()
        
        self.itemProducto = ItemProducto(
            idProducto: producto!.idInterno,
            nombreProducto: producto!.nombre,
            nombreAlternativaProducto: alternativaSeleccionada != nil ? alternativaSeleccionada?.nombreAbreviado: nil,
            imagenProductoURL: producto!.imagenURL ?? "",
            cantidad: self.cantidad,
            precioUnitario: precio,
            precio: precio * Double(self.cantidad),
            esPremio: producto!.esPremio ?? false,
            idPremio: producto!.idPremio
        )
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
                            //self.itemProducto = itemProducto
                        }
                    } catch {
                        print("Error calculando precio extra: \(error)")
                    }
                }
            }
        }
    }
    
    private func obtenerPrecio() -> Double {
        if(producto == nil) { return 0 }
            
        let esPremio: Bool = producto?.esPremio ?? false
        
        if(alternativaSeleccionada != nil && !esPremio){
            return alternativaSeleccionada!.precio
        } else {
            return producto!.precio
        }
    }
}
