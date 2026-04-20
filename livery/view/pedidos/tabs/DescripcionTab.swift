//
//  DescripcionTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 03/01/2026.
//
import SwiftUI

struct DescripcionTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    let pedido: Pedido
    let estadoPedido: EstadoPedido?
    
    var body: some View {
        VStack(spacing: 0){
            ScrollView {
                VStack(spacing: 8) {
                    // Sección Productos
                    SeccionDesplegable(
                        titulo: "Productos",
                        expandidoInicialmente: false,
                        contenido: {
                            Spacer().frame(height: 8)

                            let tieneAlcohol = pedido.itemsProductos.contains { $0.contieneAlcohol == true }
                                || pedido.itemsPromociones.contains { $0.contieneAlcohol == true }

                            if tieneAlcohol {
                                AdvertenciaProductosConAlcohol()
                            }
                            
                            VStack(spacing: 8) {
                                ItemsProductosView(pedido: pedido)
                                ItemsPromocionesView(pedido: pedido)
                            }
                        }
                    )
                    
                    // Sección Notas
                    if !pedido.notas.isEmpty {
                        SeccionDesplegable(
                            titulo: "Notas",
                            expandidoInicialmente: false,
                            contenido: {
                                Text(pedido.notas)
                                    .font(.custom("Barlow", size: 14))
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }
                        )
                    }
                    
                    // Sección Resumen
                    SeccionDesplegable(titulo: "Resumen", expandidoInicialmente: true) {
                        ResumenPedidoView(pedido: pedido)
                    }
                    
                    // Motivo Cancelación
                    if estadoPedido == .cancelado, let extra = pedido.estado?.extra, !extra.isEmpty {
                        SeccionDesplegable(
                            titulo: "Motivo Cancelación",
                            expandidoInicialmente: true,
                            contenido: {
                                Spacer().frame(height: 8)
                                
                                Text(extra)
                                    .font(.custom("Barlow", size: 14))
                                    .bold()
                                    .foregroundColor(.rojoError)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 4)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
        }
    }
}

struct ItemsProductosView: View {
    let pedido: Pedido

    var body: some View {
        VStack(spacing: 8) {
            ForEach(pedido.itemsProductos) { itemProducto in
                FilaProducto(itemProducto: itemProducto)
            }
        }
    }
}

struct FilaProducto: View {
    let itemProducto: ItemProducto
    
    var body: some View {
        HStack(alignment: .top) {
            // Imagen
            RemoteImage(url: URL(string: API.baseURL + "/" + itemProducto.imagenProductoURL))
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer().frame(width: 12)

            // Descripción
            ItemProductoDescripcion(itemProducto: itemProducto)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(Color.grisSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(itemProducto.esPremio ? Color.oroPremio : Color.clear,
                        lineWidth: itemProducto.esPremio ? 3 : 0)
        )
    }
}

struct ItemsPromocionesView: View {
    let pedido: Pedido

    var body: some View {
        VStack(spacing: 8) {
            ForEach(pedido.itemsPromociones) { itemPromocion in
                FilaPromocion(itemPromocion: itemPromocion)
            }
        }
    }
}

struct FilaPromocion: View {
    let itemPromocion: ItemPromocion
    
    var body: some View {
        HStack(alignment: .top) {
            RemoteImage(url: URL(string: API.baseURL + "/" + itemPromocion.imagenPromocionURL))
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer().frame(width: 12)

            ItemPromocionDescripcion(itemPromocion: itemPromocion)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(Color.grisSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


struct ResumenPedidoView: View {
    let pedido: Pedido
    
    var body: some View {
        Spacer().frame(height: 8)
        
        VStack(spacing: 8) {
            row(
                label: "Productos",
                value: DoubleUtils.formatearPrecio(valor: pedido.precioTotal)
            )
            row(
                label: "Tarifa de Servicio",
                value: DoubleUtils.formatearPrecio(valor: pedido.tarifaServicio)
            )
            row(
                label: "Subtotal",
                value: DoubleUtils.formatearPrecio(
                    valor : (pedido.precioTotal + pedido.tarifaServicio)
                ),
                isBoldLabel: true,
                isBoldValue: true
            )
            
            Divider()
            
            if (TipoEntrega.desdeString(pedido.tipoEntrega) == TipoEntrega.retiroEnComercio) {
                Text("Retiro en Comercio")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.verdePrincipal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let hora = pedido.estado?.horaEstimadaEntrega, !hora.isEmpty {
                    row(
                        label: "Hora estimada de entrega",
                        value: hora
                    )
                }
            } else {
                row(
                    label: "Dirección",
                    value: StringUtils.formatearDireccion(
                        pedido.direccion.calle,
                        pedido.direccion.numero,
                        pedido.direccion.departamento
                    ),
                    isBoldValue: true
                )
                
                row(
                    label: "Envío",
                    value: DoubleUtils.formatearPrecio(valor: pedido.envio),
                    isBoldValue: true
                )
                
                if let hora = pedido.estado?.horaEstimadaEntrega, !hora.isEmpty, let tiempo = pedido.tiempoRecorridoEstimado {
                    
                    Spacer().frame(height: 8)
                    row(
                        label: "Hora estimada de entrega",
                        value: DateUtils.sumarMinutos(hora: hora, minutos: tiempo),
                        isBoldValue: true
                    )
                    Text("(Preparación + Envío)")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func row(
        label: String,
        value: String,
        isBoldLabel: Bool = false,
        isBoldValue: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(.custom("Barlow", size: 14))
                .fontWeight(isBoldLabel ? .bold : .regular)
                .foregroundColor(.negro)
            Spacer()
            Text(value)
                .font(.custom("Barlow", size: 14))
                .fontWeight(isBoldValue ? .bold : .regular)
                .foregroundColor(.negro)
        }
    }
}