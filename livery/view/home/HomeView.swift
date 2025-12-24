//
//  HomeView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject var homeViewModel : HomeViewModel
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            
            FranjaPrincipal()
            BusquedaModos(homeViewModel: homeViewModel)
            
            if  ( perfilUsuarioState.ciudadSeleccionada != nil
                  && perfilUsuarioState.ciudadSeleccionada == StringUtils.sinCobertura
                ) || (
                    perfilUsuarioState.usuario != nil
                    && perfilUsuarioState.usuario!.direcciones?.isEmpty ?? true
                )
            {
                DireccionFueraDeCobertura()
            } else {
                if homeViewModel.modoComercioSeleccionado {
                    SelectorCategorias(homeViewModel: homeViewModel)
                    Spacer().frame(height: 8)
                    ListaComercios(homeViewModel: homeViewModel)
                } else {
                    //FranjaBusqueda(homeViewModel: homeViewModel)
                    //ListaComerciosProductos(homeViewModel: homeViewModel)
                }
            }
        }
        .padding(.bottom, 16)
    }
}

struct FranjaPrincipal: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    //@EnvironmentObject var notificacionesState: NotificacionesState
    @EnvironmentObject var navManager: NavigationManager

    @State private var mostrarDirecciones = false
    @State private var mostrarNotificaciones = false

    var body: some View {
        HStack {

            Button {
                mostrarDirecciones = true
            } label: {
                HStack(spacing: 6) {
                    Text(
                        perfilUsuarioState.idDireccionSeleccionada?.isEmpty ?? true
                        ? "Seleccionar dirección"
                        : perfilUsuarioState.obtenerDireccionSeleccionada()
                    )
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.blanco)

                    Image("icono_flecha_abajo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {

                Button {
                    mostrarNotificaciones = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_notificaciones")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blanco)
                        /*
                        if !notificacionesState.noLeidas.isEmpty {
                            //BadgeView(count: notificacionesState.noLeidas.count)
                        }
                         */
                    }
                }

                Button {
                    //NavigationManager.shared.navigate("premios")
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_premios")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blanco)
                        
                        let giros = perfilUsuarioState.usuario?.premios?.girosRestantes
                        if let giros, giros > 0 {
                            //BadgeView(count: giros)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(.verdePrincipal)
        .sheet(isPresented: $mostrarDirecciones) {
            BottomSheetDirecciones(
                onNuevaDireccion: {
                    mostrarDirecciones = false
                    navManager.homePath.append("DireccionView")
                },
                onDireccionSeleccionada: {
                    mostrarDirecciones = false
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $mostrarNotificaciones) {
            //BottomSheetNotificaciones()
        }
    }
}

struct BusquedaModos: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        HStack {
            // Contenedor blanco
            HStack(spacing: 16) {

                Button {
                    homeViewModel.onModoComercioSeleccionadoChange(true)
                } label: {
                    Image("icono_busqueda_comercios")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(
                            homeViewModel.modoComercioSeleccionado
                            ? .verdePrincipal
                            : .grisSecundario
                        )
                }
                .buttonStyle(.plain)

                Button {
                    homeViewModel.onModoComercioSeleccionadoChange(false)
                } label: {
                    Image("icono_busqueda_productos")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(
                            !homeViewModel.modoComercioSeleccionado
                            ? .verdePrincipal
                            : .grisSecundario
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.verdePrincipal)
        .clipShape(
            RoundedCorners(radius: 32, corners: [.bottomLeft, .bottomRight])
        )
    }
}

struct SelectorCategorias: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(ListUtils.categorias, id: \.idInterno) { categoria in
                        VStack {
                            Button {
                                homeViewModel.onCategoriaSeleccionadaChange(categoria.idInterno)
                            } label: {
                                Image(categoria.imagenGenerica)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 60)
                                    .padding(.all, 2)
                                    .background(.grisSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                homeViewModel.categoriaSeleccionada == categoria.idInterno
                                                ? .verdePrincipal
                                                : .clear,
                                                lineWidth: 4
                                            )
                                    )
                            }
                            
                            Text(categoria.nombre)
                                .font(.custom("Barlow", size: 11))
                                .bold()
                        }
                        .id(categoria.idInterno)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
            .onChange(of: homeViewModel.categoriaSeleccionada) { oldValue, newValue in
                withAnimation(.spring()) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onAppear {
                if let seleccionada = homeViewModel.categoriaSeleccionada, !seleccionada.isEmpty {
                    // Damos un respiro de 0.1 o 0.2 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring()) {
                            proxy.scrollTo(seleccionada, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

struct ListaComercios: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(homeViewModel.comercios) { comercio in
                    TarjetaComercio(comercio: comercio)
                        .padding(.horizontal, 16)
                        .onAppear {
                            if comercio.idInterno == homeViewModel.comercios.last?.idInterno {
                                Task {
                                    await homeViewModel.cargarMasComercios()
                                }
                            }
                        }
                    TarjetaComercio(comercio: comercio)
                        .padding(.horizontal, 16)
                        .onAppear {
                            if comercio.idInterno == homeViewModel.comercios.last?.idInterno {
                                Task {
                                    await homeViewModel.cargarMasComercios()
                                }
                            }
                        }
                }
            }
        }
    }
}

struct TarjetaComercio: View {
    let comercio: Comercio

    var body: some View {
        VStack(spacing: 0) {
            // Mitad Superior: Imagen
            AsyncImage(url: URL(string: API.baseURL + "/" + comercio.imagenURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fondo vacío o color base mientras carga/falla
                    Color.grisSurface
                }
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .clipped()

            // Mitad Inferior:
            ComercioTitulo(comercio: comercio, mostrarHorarios: true)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .background(Color.grisSurface)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
        .onAppear {
            print("Cargando tarjeta para: \(comercio.nombre)")
            print("URL completa: \(API.baseURL + "/" + comercio.imagenURL)")
        }
    }
}

struct ComercioTitulo: View {
    let comercio: Comercio
    var mostrarPuntuacion: Bool = true
    var mostrarBotonAdd: Bool = false
    var mostrarHorarios: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Horarios (Alineado a la derecha arriba)
            if mostrarHorarios, let horarios = comercio.horarios {
                HStack {
                    Spacer()
                    Text(DateUtils.obtenerHorariosHoy(horarios: horarios))
                        .font(.custom("Barlow", size: 16))
                        .bold()
                        .foregroundColor(.grisTerciario)
                }
            }
            
            HStack(alignment: .center) {
                
                // Grupo Izquierdo: Logo + Nombre/Categorías
                HStack(spacing: 14) {
                    // Box equivalente: AsyncImage con clip
                    AsyncImage(url: URL(string: API.baseURL + "/" + comercio.logoURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.grisSurface
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comercio.nombre)
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .foregroundColor(.negro)
                        
                        if !comercio.categoriasPrincipales.isEmpty {
                            Text(comercio.categoriasPrincipalesToString())
                                .font(.custom("Barlow", size: 16))
                                .foregroundColor(.negro)
                        }
                    }
                }
                
                Spacer()
                
                // Grupo Derecho: Estrella + Puntuación o Botón Add
                HStack(spacing: 8) {
                    if mostrarPuntuacion {
                        Image("icono_estrella_relleno")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text(String(format: "%.1f", comercio.puntuacion))
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .foregroundColor(.negro)
                    }
                    
                    if mostrarBotonAdd {
                        if mostrarPuntuacion {
                            Image("icono_add_circle")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
    }
}
struct BottomSheetDirecciones: View {
    let onNuevaDireccion: () -> Void
    let onDireccionSeleccionada: () -> Void

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var direcciones: [UsuarioDireccion] {
        perfilUsuarioState.usuario?.direcciones ?? []
    }

    var body: some View {
        VStack(spacing: 8) {
            
            Text("Elegir dirección")
                .font(.custom("Barlow", size: 18))
                .bold()
            
            Button {
                onNuevaDireccion()
            } label: {
                HStack(spacing: 6) {
                    Image("icono_add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.negro)
                    
                    Text(
                        "Nueva dirección"
                    )
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(direcciones.enumerated()), id: \.offset) { _, direccion in
                        Button {
                            Task {
                                await perfilUsuarioState.actualizarDireccionSeleccionada(
                                    idDireccion: direccion.id
                                )
                                onDireccionSeleccionada()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image("icono_ubicacion")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.negro)
                                
                                Text(
                                    StringUtils.formatearDireccion(
                                        direccion.calle,
                                        direccion.numero,
                                        direccion.departamento)
                                )
                                .font(.custom("Barlow", size: 16))
                                .foregroundColor(.negro)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
            Spacer()
        }
        .padding()
    }
}

struct DireccionFueraDeCobertura: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
                .frame(height: 100)
            
            Image("icono_fuera_cobertura")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
            
            Text("Dirección inválida o fuera de nuestro rango de cobertura, por favor selecciona otra dirección.")
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
