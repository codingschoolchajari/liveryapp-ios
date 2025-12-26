//
//  PromocionView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct PromocionTitulo: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    let promocion: Promocion
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var mostrarBottomSheet = false
    @State private var esFavorito: Bool = false
    
    var body: some View {
        let comercio = comercioViewModel.comercio
        let idFavorito = perfilUsuarioState.usuario?.obtenerIdPromocionFavorita(
            idComercio: comercio?.idInterno,
            idPromocion: promocion.idInterno
        )
        
        ZStack {
            HStack(spacing: 8) {
                PromocionDescripcion(promocion: promocion)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: API.baseURL + "/" + promocion.imagenURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.grisSurface
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Botón de Favorito
                    Button(action: {
                        toggleFavorito(comercio: comercio, idFavorito: idFavorito)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 25, height: 25)
                            
                            Image(esFavorito ? "icono_favoritos_relleno" : "icono_favoritos_vacio")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(esFavorito ? .verdePrincipal : .negro)
                        }
                    }
                    .padding(6)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(.blanco)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.grisSecundario, lineWidth: 1)
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
            if let comercio = comercio {
                
                //BottomSheetSeleccionPromocion(promocion: promocion, comercio: comercio)
            }
        }
    }
    
    // Lógica para agregar/eliminar favorito
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
                    idProducto: nil,
                    idPromocion: promocion.idInterno,
                    nombrePromocion: promocion.nombre,
                    imagenPromocion: promocion.imagenURL
                )
                 */
            } else if let idFav = idFavorito {
                //perfilUsuarioState.eliminarFavorito(id: idFav)
            }
        }
    }
}

struct PromocionDescripcion: View {
    let promocion: Promocion
    
    var fontSizeNombre: CGFloat = 16
    var fontSizePrecio: CGFloat = 18
    var fontSizeDescripcion: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(promocion.nombre)
                .font(.custom("Barlow", size: fontSizeNombre))
                .bold()
                .foregroundColor(.negro)

            if !promocion.descripcion.isEmpty {
                Text(promocion.descripcion)
                    .font(.custom("Barlow", size: fontSizeDescripcion))
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            Text(DoubleUtils.formatearPrecio(valor: promocion.precio))
                .font(.custom("Barlow", size: fontSizePrecio))
                .bold()
                .foregroundColor(.negro)
        }
    }
}
