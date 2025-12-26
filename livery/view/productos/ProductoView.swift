//
//  ProductoView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct ProductoTitulo: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    let producto: Producto
    let categoria: Categoria
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var mostrarBottomSheet = false
    @State private var esFavorito: Bool = false
    
    var body: some View {
        let comercio = comercioViewModel.comercio
        let idFavorito = perfilUsuarioState.usuario?.obtenerIdProductoFavorito(
            idComercio: comercio?.idInterno,
            idProducto: producto.idInterno
        )
        
        ZStack {
            HStack(spacing: 8) {
                ProductoDescripcion(producto: producto)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .center) {
                    AsyncImage(url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? ""))) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.grisSurface
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                toggleFavorito(comercio: comercio, idFavorito: idFavorito)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 25, height: 25)
                                    Image(esFavorito ? "icono_favoritos_relleno" : "icono_favoritos_vacio")
                                        .resizable()
                                        .renderingMode(.template)
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(esFavorito ? .verdePrincipal : .negro)
                                }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                    
                    if let descuento = producto.descuento, descuento > 0 {
                        VStack {
                            Spacer()
                            RectanguloDescuento(producto: producto, redondeado: 12)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color.blanco)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                mostrarBottomSheet = true
            }
        }
        .onAppear {
            esFavorito = (idFavorito != nil)
        }
        .sheet(isPresented: $mostrarBottomSheet) {
            if let com = comercio {
                /*
                BottomSheetSeleccionProducto(producto: producto, categoria: categoria, comercio: com)
                 */
            }
        }
    }
    
    private func toggleFavorito(comercio: Comercio?, idFavorito: String?) {
        esFavorito.toggle()
        Task {
            if esFavorito, let com = comercio {
                /*
                perfilUsuarioState.agregarFavorito(
                    id: UUID().uuidString,
                    idComercio: com.idInterno,
                    nombreComercio: com.nombre,
                    logoComercio: com.logoURL,
                    idProducto: producto.idInterno, // Aquí pasamos el producto
                    idPromocion: nil,
                    nombreProducto: producto.nombre,
                    imagenProducto: producto.imagenURL
                )
                 */
            } else if let idFav = idFavorito {
                //perfilUsuarioState.eliminarFavorito(id: idFav)
            }
        }
    }
}

struct ProductoDescripcion: View {
    let producto: Producto
    
    // Valores por defecto
    var fontSizeNombre: CGFloat = 16
    var fontSizePrecio: CGFloat = 18
    var fontSizeDescripcion: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(producto.nombre)
                .font(.custom("Barlow", size: fontSizeNombre))
                .bold()
                .foregroundColor(.negro)
            
            if !producto.descripcion.isEmpty {
                Text(producto.descripcion)
                    .font(.custom("Barlow", size: fontSizeDescripcion))
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            if producto.precio > 0 {
                HStack(alignment: .center, spacing: 8) {
                    Text(DoubleUtils.formatearPrecio(valor: producto.precio))
                        .font(.custom("Barlow", size: fontSizePrecio))
                        .bold()
                        .foregroundColor(.negro)
                    
                    if let descuento = producto.descuento,
                       let precioSinDescuento = producto.precioSinDescuento,
                       descuento > 0 {
                        
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow-Regular", size: fontSizePrecio))
                            .foregroundColor(.grisTerciario)
                            .strikethrough(true, color: .grisTerciario)
                    }
                }
            }
        }
    }
}

struct RectanguloDescuento: View {
    let producto: Producto
    var fontSizeDescuento: CGFloat = 14
    var redondeado: CGFloat = 8
    
    var body: some View {
        if let descuento = producto.descuento {
            Text("\(Int(descuento)) % OFF")
                .font(.custom("Barlow", size: fontSizeDescuento))
                .bold()
                .foregroundColor(.negro)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Color.amarilloDescuento
                        .cornerRadius(redondeado)
                )
        }
    }
}
