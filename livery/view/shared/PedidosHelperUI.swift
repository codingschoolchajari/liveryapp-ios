//
//  PedidosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 28/12/2025.
//
import SwiftUI

struct ItemProductoDescripcion: View {
    @ObservedObject var carritoViewModel: CarritoViewModel
    let itemProducto: ItemProducto
    var eliminable: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Título y Botón Eliminar
            HStack(alignment: .top) {
                Text(itemProducto.nombreProducto)
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: -4)
                
                if eliminable {
                    Button(action: {
                        carritoViewModel.eliminarItemProducto(idInterno: itemProducto.idInterno)
                    }) {
                        Image("icono_delete")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .foregroundColor(.rojoError)
                    }
                    .offset(y: -4)
                }
            }
            
            // Descripción de seleccionables
            SeleccionablesDescripcion(seleccionables: itemProducto.seleccionables)
            
            Spacer().frame(height: 16)
            
            // Cantidad y Precio
            HStack {
                Spacer()
                Text("\(itemProducto.cantidad)  x  \(DoubleUtils.formatearPrecio(valor: itemProducto.precioUnitario))")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
            }
        }
    }
}

struct ItemPromocionDescripcion: View {
    @ObservedObject var carritoViewModel: CarritoViewModel
    let itemPromocion: ItemPromocion
    var eliminable: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Título y Botón Eliminar
            HStack(alignment: .top) {
                Text(itemPromocion.nombrePromocion)
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: -4)
                
                if eliminable {
                    Button(action: {
                        carritoViewModel.eliminarItemPromocion(idInterno: itemPromocion.idInterno)
                    }) {
                        Image("icono_delete")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .foregroundColor(.rojoError)
                    }
                    .offset(y: -4)
                }
            }
            
            // Iteración de seleccionables por producto
            let keys = itemPromocion.seleccionablesPorProducto.keys.sorted()
            let mostrarDivisor = itemPromocion.seleccionablesPorProducto.count > 1
            
            ForEach(keys, id: \.self) { key in
                if let lista = itemPromocion.seleccionablesPorProducto[key] {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 6)
                        SeleccionablesDescripcion(seleccionables: lista)
                        Spacer().frame(height: 8)
                        
                        if mostrarDivisor {
                            Divider()
                                .background(Color.grisSecundario)
                        }
                    }
                }
            }
            
            Spacer().frame(height: 16)
            
            // Cantidad y Precio
            HStack {
                Spacer()
                Text("\(itemPromocion.cantidad)  x  \(DoubleUtils.formatearPrecio(valor: itemPromocion.precioUnitario))")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
            }
        }
    }
}

struct SeleccionablesDescripcion: View {
    let seleccionables: [SeleccionableProducto]
    
    var body: some View {
        if !seleccionables.isEmpty {
            let tienenCantidades = seleccionables.contains { ($0.cantidad ?? 0) > 0 }
            
            VStack(alignment: .leading, spacing: 2) {
                if tienenCantidades {
                    // Muestra lista vertical con cantidades
                    ForEach(seleccionables) { seleccionable in
                        if let cantidad = seleccionable.cantidad, cantidad > 0 {
                            Text("\(seleccionable.nombreSeleccionable)  x  \(cantidad)")
                                .font(.custom("Barlow", size: 14))
                                .foregroundColor(.negro)
                        } else {
                            Text(seleccionable.nombreSeleccionable)
                                .font(.custom("Barlow", size: 14))
                                .foregroundColor(.negro)
                        }
                    }
                } else {
                    // Agrupa de a 2 elementos (Equivalente a chunked(2))
                    let grupos = chunked(seleccionables, size: 2)
                    
                    ForEach(0..<grupos.count, id: \.self) { index in
                        let textoFila = grupos[index]
                            .map { $0.nombreSeleccionable }
                            .joined(separator: "  -  ")
                        
                        Text(textoFila)
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(.negro)
                    }
                }
            }
        }
    }
    
    // Función auxiliar para replicar .chunked(2) de Kotlin
    private func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0 ..< Swift.min($0 + size, array.count)])
        }
    }
}
