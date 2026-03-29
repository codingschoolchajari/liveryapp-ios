//
//  PagoTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI

struct PagoTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    let pedido: Pedido
    let estadoPedido: EstadoPedido?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                MontoAPagarView(
                    subtotal: obtenerSubtotal(
                        tipoEntrega: TipoEntrega.desdeString(pedido.tipoEntrega),
                        precioTotal: pedido.precioTotal,
                        tarifaServicio: pedido.tarifaServicio
                    ),
                    tipoEntrega: TipoEntrega.desdeString(pedido.tipoEntrega)
                )

                Spacer().frame(height: 8)

                SeccionDesplegable(
                    titulo: "Datos Bancarios",
                    expandidoInicialmente: false,
                    backgroundColor: Color.grisSurface,
                    contenido: {
                        DatosBancariosPagoView(
                            datosBancarios: pedidosViewModel.comercioSeleccionado?.datosBancarios
                        )
                    }
                )

                Spacer().frame(height: 8)

                SeccionDesplegable(
                    titulo: "Comprobante",
                    expandidoInicialmente: true,
                    backgroundColor: Color.grisSurface,
                    contenido: {
                        ComprobantePagoView(
                            estaCargando: false,
                            comprobanteEnMemoria: nil,
                            urlComprobante: API.baseURL + "/" + PedidosHelper.generarURLComprobante(pedido: pedido) + "?ts=\(Date().timeIntervalSince1970)",
                            botonHabilitado: estadoPedido == .pendienteAprobacion,
                            onCargarComprobante: { comprobante in
                                Task {
                                    await pedidosViewModel.cargarComprobante(
                                        pedido: pedido,
                                        comprobante: comprobante
                                    )
                                }
                            }
                        )
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.grisSurface)
            .cornerRadius(12)
        }
    }
}
