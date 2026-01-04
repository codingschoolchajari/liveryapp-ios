//
//  PedidosView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct PedidosView: View {
    var idPedido: String? = nil
    
    @StateObject var pedidosViewModel : PedidosViewModel
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    private let perfilUsuarioState: PerfilUsuarioState
    
    // Observador del ciclo de vida (Foreground/Background)
    @Environment(\.scenePhase) var scenePhase
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
        
        _pedidosViewModel = StateObject(
            wrappedValue: PedidosViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Header
                Group {
                    Spacer().frame(height: 8)
                    Titulo(titulo: "Pedidos")
                    Spacer().frame(height: 8)
                    PedidosEstadosView(pedidosViewModel: pedidosViewModel)
                    Spacer().frame(height: 12)
                }
                PedidosListView(pedidosViewModel: pedidosViewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blanco)
        }
        .onAppear {
            if idPedido != nil {
                Task {
                    await pedidosViewModel.buscarPedidoSeleccionado(idPedido: idPedido!)
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Al volver de background
                pedidosViewModel.refrescarPedidos()
            }
        }
        .sheet(isPresented: $pedidosViewModel.mostrarBottomSheet) {
            BottomSheetPedidoDescripcion(
                perfilUsuarioState: perfilUsuarioState,
                pedidosViewModel: pedidosViewModel,
                onClose: {
                    pedidosViewModel.onMostrarBottomSheetChange(mostrar: false)
                }
            )
            .onDisappear {
                pedidosViewModel.onPedidoSeleccionadoChange(pedido: nil)
                pedidosViewModel.refrescarPedidos()
                pedidosViewModel.onMostrarBottomSheetChange(mostrar: false)
            }
        }
    }
}

struct PedidosListView: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(pedidosViewModel.pedidos) { pedido in
                    VStack(spacing: 12) {
                        PedidoRow(pedidosViewModel: pedidosViewModel, pedido: pedido)
                            .onAppear {
                                if pedido.idInterno == pedidosViewModel.pedidos.last?.idInterno {
                                    Task {
                                        await pedidosViewModel.cargarMasPedidos()
                                    }
                                }
                            }
                            .onTapGesture {
                                Task {
                                    await pedidosViewModel.refrescarPedidoSeleccionado(pedido: pedido)
                                    pedidosViewModel.onMostrarBottomSheetChange(mostrar: true)
                                }
                            }
                        Divider().background(Color.grisSecundario)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .refreshable {
            pedidosViewModel.refrescarPedidos()
        }
    }
}

struct PedidoRow: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    let pedido: Pedido
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            
            AsyncImage(url: URL(string: API.baseURL + "/" + (pedido.logoComercioURL))) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 2) {
                // Fila 1: Nombre y Precio
                HStack {
                    Text(pedido.nombreComercio)
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(Color.negro)
                    Spacer()
                    Text(DoubleUtils.formatearPrecio(valor : pedido.precioTotal + pedido.tarifaServicio))
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(Color.negro)
                }
                
                // Fila 2: Estado y Envío
                HStack {
                    Text(PedidosHelper.obtenerEstadoPedido(estado: pedido.estado?.nombre ?? ""))
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(PedidosHelper.obtenerColorEstadoPedido(estado: pedido.estado?.nombre ?? ""))
                    
                    Spacer()
                    
                    if !pedido.retiroEnComercio {
                        Text("+ envío")
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(Color.negro)
                    }
                }
                
                // Fila 3: Fecha
                if let estado = pedido.estado {
                    HStack {
                        Text(DateUtils.fechaATexto(fechaStr: estado.fechaUltimaActualizacion))
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(Color.grisSecundario)
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
