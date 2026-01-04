//
//  ChatComercioTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI

struct ChatComercioTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    @StateObject var pedidoChatViewModel: PedidoChatViewModel
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var notificacionesState: NotificacionesState
    
    var body: some View {
        let pedidoSeleccionado = pedidosViewModel.pedidoSeleccionado
        let estadoPedido = EstadoPedido.desdeString(pedidoSeleccionado?.estado?.nombre ?? "")
        let emailUsuario = perfilUsuarioState.usuario?.email ?? ""
        
        VStack {
            if habilitarChat(estado: estadoPedido) {
                ChatView(pedidoChatViewModel: pedidoChatViewModel)
                    .id("comercio_\(pedidoSeleccionado?.idInterno ?? "")")
                    .onDisappear {
                        pedidoChatViewModel.limpiarChat()
                    }
                    .padding(.horizontal, 16)
            } else {
                Text("Esta sección se habilitará cuando el pedido haya sido aprobado por el comercio.")
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
                    idComercio: pedido.idComercio,
                    idRepartidor: nil
                )
            }
        }
        .onChange(of: pedidoChatViewModel.chat?.idInterno) { oldId, newId in
            notificacionesState.setChatVisible(idChat: newId ?? "")
        }
        .onDisappear {
            notificacionesState.limpiarChatVisible()
        }
    }
    
    private func habilitarChat(estado: EstadoPedido?) -> Bool {
        if(estado == nil) { return false }
        
        let validos: [EstadoPedido] = [.pendientePago, .enPreparacion, .enEsperaRepartidor, .enCamino, .entregado]
        return validos.contains(estado!)
    }
}
