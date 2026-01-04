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
        let emailUsuario = perfilUsuarioState.usuario?.email ?? ""
        
        VStack {
            if habilitarChat(idRepartidor: idRepartidor, estado: estadoPedido) {
                ChatView(pedidoChatViewModel: pedidoChatViewModel)
                    .id("repartidor_\(pedidoSeleccionado?.idInterno ?? "")")
                    .onDisappear {
                        pedidoChatViewModel.limpiarChat()
                    }
                    .padding(.horizontal, 16)
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
        .task(id: pedidoSeleccionado?.idInterno) {
            if let pedido = pedidoSeleccionado {
                pedidoChatViewModel.setChatParams(
                    idPedido: pedido.idInterno,
                    emailUsuario: emailUsuario,
                    idComercio: nil,
                    idRepartidor: pedido.idRepartidor
                )
            }
        }
        .onChange(of: pedidoChatViewModel.chat?.idInterno) { oldValue, newValue in
            notificacionesState.setChatVisible(idChat: newValue ?? "")
        }
        .onDisappear {
            notificacionesState.limpiarChatVisible()
        }
    }
    
    private func habilitarChat(idRepartidor: String?, estado: EstadoPedido?) -> Bool {
        if(estado == nil || idRepartidor == nil || idRepartidor!.isEmpty) { return false }
        
        let validos: [EstadoPedido] = [.enCamino, .entregado]
        return validos.contains(estado!)
    }
}
