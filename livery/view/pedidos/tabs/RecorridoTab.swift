//
//  RecorridoTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI

struct RecorridoTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    
    var body: some View {
        let pedido = pedidosViewModel.pedidoSeleccionado
        let comercio = pedidosViewModel.comercioSeleccionado
        let recorrido = pedidosViewModel.recorridoSeleccionado
        let estado = EstadoPedido.desdeString(pedido?.estado?.nombre ?? "")
        
        // Lógica de validación
        let habilitado = (estado == .enCamino || estado == .entregado) &&
                         pedido != nil && comercio != nil && recorrido != nil
        
        VStack {
            if habilitado {
                GoogleMapTrackingView(
                    recorrido: recorrido,
                    coordComercio: comercio!.direccion.coordenadas.toCoordinate(),
                    coordCliente: pedido!.direccion.coordenadas.toCoordinate(),
                    tick: pedidosViewModel.recorridoTick
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.verdePrincipal, lineWidth: 2)
                )
                .padding(4)
            } else {
                Text("Esta sección se habilitará cuando un repartidor haya sido asignado y el pedido se encuentre en camino.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                Spacer()
            }
        }
    }
}
