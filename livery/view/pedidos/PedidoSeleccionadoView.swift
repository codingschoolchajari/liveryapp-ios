//
//  PedidoSeleccionadoView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/01/2026.
//
import SwiftUI

struct BottomSheetPedidoDescripcion: View {
    var onClose: () -> Void
    
    @ObservedObject var pedidosViewModel: PedidosViewModel
    @StateObject var pedidoChatViewModel : PedidoChatViewModel
    
    init(perfilUsuarioState: PerfilUsuarioState,
         pedidosViewModel: PedidosViewModel,
         onClose: @escaping () -> Void
    ) {
        self.pedidosViewModel = pedidosViewModel
        self.onClose = onClose
        
        _pedidoChatViewModel = StateObject(
            wrappedValue: PedidoChatViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    @State private var selectedTabIndex = 0
    
    let tabsFila1 = ["Descripción", "Pago", "Recorrido"]
    let tabsFila2 = ["Comentario", "Chat Comercio", "Chat Repartidor"]
    
    var body: some View {
        VStack(spacing: 0) {
            if(pedidosViewModel.pedidoSeleccionado != nil){
                let estadoPedido = EstadoPedido.desdeString(pedidosViewModel.pedidoSeleccionado!.estado?.nombre ?? "")
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)
                    
                    // Header con Logo y botones
                    PortadaPedido(
                        pedidosViewModel: pedidosViewModel,
                        pedido: pedidosViewModel.pedidoSeleccionado!,
                        onClose: onClose
                    )
                    
                    Spacer().frame(height: 8)
                    EstadoPedidoView(estadoPedido: estadoPedido)
                    Spacer().frame(height: 16)
                    
                    Divider()
                    
                    // Sistema de Tabs
                    TabsConBoxes(
                        tabsFila1: tabsFila1,
                        tabsFila2: tabsFila2,
                        selectedTabIndex: $selectedTabIndex
                    )
                    
                    Divider()
                    Spacer().frame(height: 8)
                    
                    // Contenido dinámico según el Tab
                     VStack {
                         switch selectedTabIndex {
                         case 0: DescripcionTab(
                            pedidosViewModel: pedidosViewModel,
                            pedido: pedidosViewModel.pedidoSeleccionado!,
                            estadoPedido: estadoPedido,
                            onCancel: onClose
                         )
                         case 1: PagoTab(
                            pedidosViewModel: pedidosViewModel,
                            pedido: pedidosViewModel.pedidoSeleccionado!,
                            estadoPedido: estadoPedido
                         )
                         /*
                         case 2: RecorridoTab(viewModel: pedidosViewModel)
                              */
                         case 3: ComentarioTab(pedidosViewModel: pedidosViewModel)
                         case 4: ChatComercioTab(
                            pedidosViewModel: pedidosViewModel,
                            pedidoChatViewModel: pedidoChatViewModel
                         )
                         case 5: ChatRepartidorTab(
                            pedidosViewModel: pedidosViewModel,
                            pedidoChatViewModel: pedidoChatViewModel
                         )
                         default: EmptyView()
                         }
                     }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onChange(of: selectedTabIndex) { oldValue, newValue in
            let isChatTab = (newValue == 4 || newValue == 5)
            pedidoChatViewModel.setChatTabActive(active: isChatTab)
            
            let isRecorridoTab = (newValue == 2)
            pedidosViewModel.setRecorridoTabActive(active: isRecorridoTab)
        }
    }
}

// --- Componentes de Apoyo ---

struct TabsConBoxes: View {
    let tabsFila1: [String]
    let tabsFila2: [String]
    @Binding var selectedTabIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Fila 1
            HStack(spacing: 0) {
                ForEach(0..<tabsFila1.count, id: \.self) { index in
                    tabButton(title: tabsFila1[index], index: index)
                }
            }
            // Fila 2
            HStack(spacing: 0) {
                ForEach(0..<tabsFila2.count, id: \.self) { index in
                    let realIndex = index + tabsFila1.count
                    tabButton(title: tabsFila2[index], index: realIndex)
                }
            }
        }
    }
    
    func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTabIndex = index }) {
            Text(title)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(selectedTabIndex == index ? .verdePrincipal : .grisSecundario)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PortadaPedido: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    let pedido: Pedido
    var onClose: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            // Botón Reload
            Button(
                action: {
                    Task {
                        await pedidosViewModel.refrescarPedidoSeleccionado(pedido: pedido)
                    }
                }
            ) {
                Image("icono_reload")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.negro)
            }
            
            Spacer()
            
            // Logo Comercio
            AsyncImage(url: URL(string: API.baseURL + "/" + pedido.logoComercioURL)) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Botón Cerrar
            Button(action: onClose) {
                Image("icono_cerrar")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.negro)
                    .background(Color.blanco)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.negro, lineWidth: 2))
            }
        }
        .padding(.horizontal, 16)
    }
}

struct EstadoPedidoView: View {
    let estadoPedido: EstadoPedido?
    
    var body: some View {
        if let estado = estadoPedido {
            VStack(spacing: 2) {
                Text(estado.descripcion)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(estado.color)
                
                Text(estado.aclaracion)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.grisSecundario)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    }
}
