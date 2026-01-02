//
//  FavoritosView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 28/12/2025.
//
import SwiftUI

struct FavoritosView: View {
    @EnvironmentObject var navManager: NavigationManager // Tu controlador de rutas
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Título
                Spacer().frame(height: 8)
                Titulo(titulo: "Favoritos")
                Spacer().frame(height: 8)
                
                // Contenido principal
                Favoritos()
            }
            .background(Color.blanco)
        }
    }
}

struct Favoritos: View {
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var body: some View {
        let usuario = perfilUsuarioState.usuario
        let favoritos = usuario?.favoritos ?? []
        
        if favoritos.isEmpty {
            VStack {
                Spacer().frame(height: 100)
                Image("personaje")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                
                Spacer().frame(height: 16)
                
                Text("No hay favoritos seleccionados")
                    .font(.custom("Barlow", size: 18))
                    .bold()
                    .foregroundColor(.negro)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Agrupar favoritos por idComercio
            let agrupados = Dictionary(grouping: favoritos, by: { $0.idComercio })
            let keys = agrupados.keys.sorted()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(keys, id: \.self) { idComercio in
                        if let listaFavoritos = agrupados[idComercio],
                           let primerFav = listaFavoritos.first
                        {
                            // Título del Comercio (Sección)
                            let comercio = Comercio(
                                idInterno: idComercio,
                                nombre: primerFav.nombreComercio,
                                logoURL: primerFav.logoComercioURL
                            )
                            TituloComercio(comercio: comercio)
                                .onTapGesture {
                                    navManager.perfilPath.append(NavigationManager.PerfilDestination.comercio(idComercio: idComercio))
                                }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(listaFavoritos) { favorito in
                                        FavoritoItemCard(favorito: favorito)
                                            .frame(minHeight: 180, alignment: .top)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(Color.grisSurface)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
    }
}

struct FavoritoItemCard: View {
    let favorito: UsuarioFavorito
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @State private var mostrarBottomSheet = false
    @State private var esFavorito = true
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                // Imagen del Producto/Promo
                AsyncImage(url: URL(string: API.baseURL + "/" + (favorito.imagenURL ?? ""))) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.grisSurface
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    mostrarBottomSheet = true
                }
                
                // Botón Favorito (Círculo blanco arriba a la derecha)
                Button(action: {
                    esFavorito = false
                    Task {
                        await perfilUsuarioState.eliminarFavorito(idFavorito: favorito.id)
                    }
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
            
            Text(favorito.nombre)
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .frame(width: 120)
        }
        // Llamada a los BottomSheets
        .sheet(isPresented: $mostrarBottomSheet) {
            if favorito.idProducto != nil && !favorito.idProducto!.isEmpty {
                SeleccionProductoFavorito(
                    favorito: favorito,
                    onClose: {
                        mostrarBottomSheet = false
                    }
                )
            } else {
                SeleccionPromocionFavorita(
                    favorito: favorito,
                    onClose: {
                        mostrarBottomSheet = false
                    }
                )
            }
        }
    }
}

struct SeleccionProductoFavorito: View {
    let favorito: UsuarioFavorito
    let onClose: () -> Void
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject private var favoritosViewModel: FavoritosViewModel
    
    init(favorito: UsuarioFavorito, onClose: @escaping () -> Void) {
        self.favorito = favorito
        self.onClose = onClose
        _favoritosViewModel = StateObject(wrappedValue: FavoritosViewModel())
    }
    
    var body: some View {
        Group {
            if let comercio = favoritosViewModel.comercioSeleccionado,
               let producto = favoritosViewModel.producto,
               let categoria = favoritosViewModel.categoria {
                
                BottomSheetSeleccionProducto(
                    producto: producto,
                    categoria: categoria,
                    comercio: comercio,
                    onClose: onClose
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blanco)
            }
        }
        .onAppear {
            Task {
                await favoritosViewModel.inicializarProductoFavorito(
                    perfilUsuarioState: perfilUsuarioState,
                    favorito: favorito
                )
            }
        }
    }
}

struct SeleccionPromocionFavorita: View {
    let favorito: UsuarioFavorito
    let onClose: () -> Void
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject private var favoritosViewModel: FavoritosViewModel
    
    init(favorito: UsuarioFavorito, onClose: @escaping () -> Void) {
        self.favorito = favorito
        self.onClose = onClose
        _favoritosViewModel = StateObject(wrappedValue: FavoritosViewModel())
    }
    
    var body: some View {
        Group {
            if let comercio = favoritosViewModel.comercioSeleccionado,
               let promocion = favoritosViewModel.promocion {
                
                BottomSheetSeleccionPromocion(
                    promocion: promocion,
                    comercio: comercio,
                    onClose: onClose
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blanco)
            }
        }
        .onAppear {
            Task {
                await favoritosViewModel.inicializarPromocionFavorita(
                    perfilUsuarioState: perfilUsuarioState,
                    favorito: favorito
                )
            }
        }
    }
}
