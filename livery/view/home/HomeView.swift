//
//  HomeView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject var homeViewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Color.verdePrincipal.ignoresSafeArea()

            VStack(spacing: 0) {

                FranjaPrincipal()

                BusquedaModos(homeViewModel: homeViewModel)

                if perfilUsuarioState.cargaInicialFinalizada {
                    if perfilUsuarioState.ciudadSeleccionada.isEmpty {
                        DireccionFueraDeCobertura()
                    } else {
                        if homeViewModel.modoComercioSeleccionado {
                            Spacer().frame(height: 8)
                            SelectorCategorias(homeViewModel: homeViewModel)
                            Spacer().frame(height: 32)
                            ListaComercios(homeViewModel: homeViewModel)
                        } else {
                            FranjaBusqueda(homeViewModel: homeViewModel)
                            ListaComerciosProductos(homeViewModel: homeViewModel)
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
}

struct FranjaPrincipal: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    //@EnvironmentObject var notificacionesState: NotificacionesState

    @State private var mostrarDirecciones = false
    @State private var mostrarNotificaciones = false

    var body: some View {
        HStack {

            Button {
                mostrarDirecciones = true
            } label: {
                HStack(spacing: 6) {
                    Text(
                        perfilUsuarioState.idDireccionSeleccionada.isEmpty
                        ? "Seleccionar dirección"
                        : perfilUsuarioState.obtenerDireccionSeleccionada()
                    )
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                    Image("icono_flecha_abajo")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {

                Button {
                    mostrarNotificaciones = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_notificaciones")
                        if !notificacionesState.noLeidas.isEmpty {
                            BadgeView(count: notificacionesState.noLeidas.count)
                        }
                    }
                }

                Button {
                    //NavigationManager.shared.navigate("premios")
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_premios")
                        
                        let giros = perfilUsuarioState.usuario?.premios?.girosRestantes
                        if giros > 0 {
                            BadgeView(count: giros)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.themePrimary)
        .sheet(isPresented: $mostrarDirecciones) {
            BottomSheetDirecciones()
        }
        .sheet(isPresented: $mostrarNotificaciones) {
            BottomSheetNotificaciones()
        }
    }
}

struct BusquedaModos: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        HStack {
            Button {
                homeViewModel.onModoComercioSeleccionadoChange(true)
            } label: {
                Image("icono_busqueda_comercios")
                    .foregroundColor(homeViewModel.modoComercioSeleccionado ? .white : .gray)
            }

            Button {
                homeViewModel.onModoComercioSeleccionadoChange(false)
            } label: {
                Image("icono_busqueda_productos")
                    .foregroundColor(!homeViewModel.modoComercioSeleccionado ? .white : .gray)
            }
        }
        .padding()
        .background(Color.themePrimary)
    }
}

struct SelectorCategorias: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(categorias) { categoria in
                    VStack {
                        Button {
                            homeViewModel.onCategoriaSeleccionadaChange(categoria.idInterno)
                        } label: {
                            Image(categoria.imagenGenerica)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .padding()
                                .background(Color.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            homeViewModel.categoriaSeleccionada == categoria.idInterno
                                            ? Color.themePrimary
                                            : .clear,
                                            lineWidth: 3
                                        )
                                )
                        }

                        Text(categoria.nombre)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ListaComercios: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(homeViewModel.comercios.indices, id: \.self) { index in
                    let comercio = homeViewModel.comercios[index]

                    Button {
                        //NavigationManager.shared.navigate("comercio/\(comercio.idInterno)")
                    } label: {
                        VStack {
                            AsyncImage(url: URL(string: comercio.imagenURL)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(height: 100)
                            .clipped()

                            ComercioTitulo(comercio: comercio)
                        }
                        .background(Color.surface)
                        .cornerRadius(12)
                    }

                    if index == homeViewModel.comercios.count - 1 {
                        ProgressView()
                            .onAppear {
                                homeViewModel.cargarMasComercios()
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct BottomSheetDirecciones: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 12) {

            Text("Elegir dirección")
                .font(.headline)

            Button {
                dismiss()
                //NavigationManager.shared.navigate("direccion")
            } label: {
                Label("Nueva dirección", systemImage: "plus")
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(perfilUsuarioState.usuario?.direcciones ?? []) { direccion in
                        Button {
                            Task {
                                await perfilUsuarioState.actualizarDireccionSeleccionada(direccion.id)
                                carritoViewModel.calcularCostoEnvio(
                                    perfilUsuarioState.obtenerUsuarioDireccion()
                                )
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "location")
                                Text(direccion.formateada)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .presentationDetents([.medium])
    }
}
