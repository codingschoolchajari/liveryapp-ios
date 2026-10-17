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
    @Environment(\.dismiss) private var dismiss
    
    init(comercio: Comercio, perfilUsuarioState: PerfilUsuarioState) {
        self.comercio = comercio
        
        _pedidosComentariosViewModel = StateObject(
            wrappedValue: PedidosComentariosViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image("icono_cerrar")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            TituloComercio(
                comercio: comercio,
                mostrarBotonAdd: false
            )
            ListaPedidosComentarios(pedidosComentariosViewModel: pedidosComentariosViewModel)
        }
        .onAppear {
            pedidosComentariosViewModel.onIdComercioSeleccionadoChange(valor: comercio.id)
        }
        .background(Color.blanco)
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
    let itemsPromociones: [ItemPromocion]
    let itemsProductos: [ItemProducto]

    init(pedidoComentario: PedidoComentario) {
        self.itemsPromociones = pedidoComentario.itemsPromociones
        self.itemsProductos = pedidoComentario.itemsProductos
    }

    init(itemsPromociones: [ItemPromocion], itemsProductos: [ItemProducto]) {
        self.itemsPromociones = itemsPromociones
        self.itemsProductos = itemsProductos
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Promociones
                ForEach(itemsPromociones) { item in
                    ItemComentarioCard(
                        idInterno: item.idInterno,
                        imagenURL: item.imagenPromocionURL,
                        nombre: item.nombrePromocion,
                        seleccionables: item.seleccionablesPorProducto.values.flatMap { $0 }
                    )
                }
                // Productos
                ForEach(itemsProductos) { item in
                    ItemComentarioCard(
                        idInterno: item.idInterno,
                        imagenURL: item.imagenProductoURL,
                        nombre: item.nombreProducto,
                        seleccionables: item.seleccionables
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.grisSurface)
        .cornerRadius(12)
    }
}

private struct ItemComentarioCard: View {
    let idInterno: String
    let imagenURL: String
    let nombre: String
    let seleccionables: [SeleccionableProducto]

    var body: some View {
        HStack(spacing: 8) {
            RemoteImage(
                url: URL(string: API.baseURL + "/" + imagenURL),
                fallbackURL: URL(string: API.baseURL + "/" + imagenPorDefectoURL(imagenURL))
            )
            .frame(width: 60, height: 60)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(nombre)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !seleccionables.isEmpty {
                    Text(seleccionables.map { $0.nombreSeleccionable }.joined(separator: ", "))
                        .font(.custom("Barlow", size: 12))
                        .foregroundColor(.negro)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(width: 200)
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
