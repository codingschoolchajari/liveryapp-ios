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
        let emailUsuario = perfilUsuarioState.usuario?.email ?? ""
        
        VStack {
            ChatView(pedidoChatViewModel: pedidoChatViewModel)
                .id("comercio_\(pedidoSeleccionado?.idInterno ?? "")")
                .onDisappear {
                    pedidoChatViewModel.limpiarChat()
                }
                .padding(.horizontal, 16)
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
    }
}
