//
//  ChatComercioTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI

struct ChatRepartidorTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    @StateObject var pedidoChatViewModel: PedidoChatViewModel
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var notificacionesState: NotificacionesState
    
    var body: some View {
        let pedidoSeleccionado = pedidosViewModel.pedidoSeleccionado
        let idRepartidor = pedidoSeleccionado?.idRepartidor
        let estadoPedido = EstadoPedido.desdeString(pedidoSeleccionado?.estado?.nombre ?? "")
        let tipoEntrega = TipoEntrega.desdeString(pedidoSeleccionado?.tipoEntrega ?? "")
        let emailUsuario = perfilUsuarioState.usuario?.email ?? ""
        
        VStack {
            if tipoEntrega == .retiroEnComercio || tipoEntrega == .envioPropio {
                Text("Esta funcionalidad no está disponible para Retiro en Comercio o Envío Prioritario")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                Spacer()
            } else if let id = idRepartidor, !id.isEmpty,
                      let estado = estadoPedido,
                      [.enEsperaRepartidor, .enCamino, .entregado].contains(estado) {
                ChatView(pedidoChatViewModel: pedidoChatViewModel)
                    .id("repartidor_\(pedidoSeleccionado?.idInterno ?? "")")
                    .onDisappear {
                        pedidoChatViewModel.limpiarChat()
                    }
                    .padding(.horizontal, 16)
            } else {
                Text("Esta sección se habilitará cuando un repartidor haya sido asignado.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                Spacer()
            }
        }
        .task(id: pedidoSeleccionado?.idInterno) {
            if let pedido = pedidoSeleccionado,
               let id = pedido.idRepartidor, !id.isEmpty {
                pedidoChatViewModel.setChatParams(
                    idPedido: pedido.idInterno,
                    emailUsuario: emailUsuario,
                    idComercio: nil,
                    idRepartidor: pedido.idRepartidor
                )
            }
        }
    }
}
