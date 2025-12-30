//
//  ComentariosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 29/12/2025.
//
import SwiftUI

struct BottomSheetComentarios: View {
    let comercio: Comercio
    
    @StateObject var pedidosComentariosViewModel : PedidosComentariosViewModel
    
    init(comercio: Comercio, perfilUsuarioState: PerfilUsuarioState) {
        self.comercio = comercio
        
        _pedidosComentariosViewModel = StateObject(
            wrappedValue: PedidosComentariosViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 16)
            TituloComercio(
                comercio: comercio,
                mostrarPuntuacion: true,
                mostrarBotonAdd: false
            )
            ListaPedidosComentarios(pedidosComentariosViewModel: pedidosComentariosViewModel)
        }
        .onAppear {
            pedidosComentariosViewModel.onIdComercioSeleccionadoChange(valor: comercio.id)
        }
    }
}

struct ListaPedidosComentarios: View {
    @ObservedObject var pedidosComentariosViewModel: PedidosComentariosViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(spacing: 0) {
                ForEach(pedidosComentariosViewModel.pedidosComentarios) { pedidoComentario in
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 12)
                        
                        HStack {
                            Text(pedidoComentario.comentario.nombreUsuario)
                                .font(.custom("Barlow", size: 14))
                                .bold()
                                .foregroundColor(.negro)
                            Spacer()
                            Text(DateUtils.tiempoRelativo(
                                fechaString : pedidoComentario.comentario.fecha)
                            )
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(.grisSecundario)
                        }
                        
                        Spacer().frame(height: 4)
                        
                        // Items del pedido
                        PedidoItemsView(pedidoComentario: pedidoComentario)
                        
                        Spacer().frame(height: 8)
                        
                        // Calificación
                        EstrellasView(cantidad: pedidoComentario.comentario.cantidadEstrellas)
                        
                        // Texto del comentario
                        Text(pedidoComentario.comentario.texto)
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(.negro)
                            .lineLimit(2)
                            .padding(.vertical, 4)
                        
                        Spacer().frame(height: 4)
                        
                        Divider()
                    }
                    .padding(.horizontal, 16)
                    .onAppear {
                        if pedidoComentario.idInterno == pedidosComentariosViewModel.pedidosComentarios.last?.idInterno {
                            Task {
                                await pedidosComentariosViewModel.cargarMasComentarios()
                            }
                        }
                    }
                }
            }
        }
    }
}
                        
struct PedidoItemsView: View {
    let pedidoComentario: PedidoComentario

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Promociones
                ForEach(pedidoComentario.itemsPromociones) { item in
                    itemRow(nombre: item.nombrePromocion, url: item.imagenPromocionURL)
                }
                // Productos
                ForEach(pedidoComentario.itemsProductos) { item in
                    itemRow(nombre: item.nombreProducto, url: item.imagenProductoURL)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.grisSurface)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func itemRow(nombre: String, url: String) -> some View {
        HStack(spacing: 4) {
            AsyncImage(url: URL(string: API.baseURL + "/" + url)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 40)
            .cornerRadius(12)
            
            Text(nombre)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 200, height: 40)
    }
}

struct EstrellasView: View {
    let cantidad: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Spacer()
            ForEach(1...5, id: \.self) { i in
                let seleccionada = i <= cantidad
                Image(seleccionada ? "icono_estrella_relleno" : "icono_estrella_vacio")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.negro)
            }
        }
        .padding(.leading, 16)
    }
}
